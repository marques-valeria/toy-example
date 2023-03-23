SCRIPT_DIR=$( cd $( dirname $0 ) && pwd )
DATA_DIR=${SCRIPT_DIR}/data
ENV_DIR=${DATA_DIR}/environment
mkdir -p ${ENV_DIR}
SUBJECTS_DIR=${SCRIPT_DIR}/data/subjects
WORKSPACES_DIR=${SCRIPT_DIR}/data/workspaces
REV_DIR=${SCRIPT_DIR}/data/revisions
RESULT_DIR=${DATA_DIR}/generated-data
ALGORITHMS=(greedy ge gre hgs multicriteria)
TEST_TIMES_DIRECTORY=${SCRIPT_DIR}/test-time-files

SKIPS=" -Dcheckstyle.skip -Drat.skip -Denforcer.skip -Danimal.sniffer.skip -Dmaven.javadoc.skip -Dfindbugs.skip -Dwarbucks.skip -Dmodernizer.skip -Dimpsort.skip -Dpmd.skip -Dxjc.skip -Djacoco.skip=true"

function setup_aspectj {
  if [ ! -d ${ENV_DIR}/aspectj1.8 ]; then
    (
      cd ${ENV_DIR}
      wget https://www.cs.cornell.edu/courses/cs6156/2020fa/resources/aspectj1.8.tgz
      tar -xzf aspectj1.8.tgz && rm aspectj1.8.tgz
    )
  fi
}

function make_project_dirs() {
    local project=$1
    mkdir -p ${RESULT_DIR}/${project}/logs
    mkdir -p ${RESULT_DIR}/${project}/ws
}

function setup_nemo() {
    (
        cd ${ENV_DIR}
        if [ ! -d ${ENV_DIR}/Nemo ]; then
            git clone git@github.com:ayakayorihiro/Nemo.git
        fi
        (
            cd Nemo
            git pull
        )
    )
}

function minimize_multicriteria() {
    local logs=$1
    local project_name=$2
    local matrix_name=$3
    ( setup_nemo ) &> ${logs}/gol-setup-nemo
    ( bash ${ENV_DIR}/Nemo/run-nemo.sh ${project_name} ${matrix_name} ${SCRIPT_DIR} ${logs}/multicriteria-ws ) &> ${logs}/gol-minimize-multicriteria-${matrix_name}
}

function minimize() {
    local logs=$1
    local project_results=$2
    local project_name=$3
    local matrix_dir=$4
    local run_info=$5
    local tiebreak_mode=$6
    output_start_message "minimizing" ${run_info} ${project_name}
    if [ "${tiebreak_mode}" == NONE ]; then
        tiebreak_arg="NONE"
    else
        tiebreak_arg="${TEST_TIMES_DIRECTORY}"/${project_name}-times.csv
	if [ ! -f ${tiebreak_arg} ]; then
	    echo "Tiebreak file ${tiebreak_arg} does not exist! Exiting..."
	    exit
	fi
    fi
    echo "[minimize] Matrix dir: ${matrix_dir}"
    for matrix_dirname in $( ls ${matrix_dir} | grep ^matrix | grep -v coverage | grep -v Estimate ); do # directory containing all matrix directories for project
        curr_matrix_dir=${matrix_dir}/${matrix_dirname}
        matrix_name=$( echo "${matrix_dirname}" | cut -d- -f2- )
        for algorithm in ${ALGORITHMS[@]}; do
            (
                time python3 ${SCRIPT_DIR}/reduce.py ${curr_matrix_dir}/mapping.csv ${curr_matrix_dir}/all-tests.txt ${algorithm} ${project_results}/${algorithm}@${matrix_name}-minimized-test-suite.txt ${tiebreak_arg}
            ) &> ${logs}/gol-minimize-${algorithm}-${matrix_name}
        done
        minimize_multicriteria ${logs} ${project_name} ${matrix_name}
        if [ ! -f ${project_results}/all-tests.txt ]; then
            cp ${curr_matrix_dir}/all-tests.txt ${project_results}/all-tests.txt
        fi
        cp ${curr_matrix_dir}/mapping.csv ${project_results}/${matrix_name}-mapping.csv
    done
    output_end_message "minimizing" ${run_info} ${project_name}
}

function parameterized_treat_special() {
    for parameterized_class in $( grep -rl Parameterized.class ); do
	echo "[parameterized-treat-special] Patching parameterized class ${parameterized_class}"
	if grep -q "@Parameterized.Parameters" ${parameterized_class}; then
	    sed -i 's/@Parameterized.Parameters.*/@Parameterized.Parameters(name=\"{index}\")/g' ${parameterized_class}
	else
	    sed -i 's/@Parameters.*/@Parameters(name=\"{index}\")/g' ${parameterized_class}
	fi
    done
    for dataprovider_class in $( grep -rl DataProviderRunner.class ); do # junit-dataprovider
        echo "[parameterized-treat-special] Patching class using DataProvider ${dataprovider_class}"
        sed -i 's/@DataProvider.*/@DataProvider(format = \"%m[%i]\")/g' ${dataprovider_class}
    done
}

function setup_javamop() {
    (
        cd ${ENV_DIR}
	rm -rf javamop
        git clone git@github.com:owolabileg/javamop.git javamop
	(
            cd ${ENV_DIR}/javamop
	    bash scripts/install-javaparser.sh
	    mvn install -DskipTests
	)
    )
}

# FIXME: Remove this function when we can programatically switch
# between normal H2 and normalized H2
function setup_non_normalized_javamop() {
    (
        cd ${ENV_DIR}
	rm -rf javamop
        git clone git@github.com:ayakayorihiro/javamop.git javamop
	(
            cd ${ENV_DIR}/javamop
	    bash scripts/install-javaparser.sh
	    git checkout non-normalized
	    mvn install -DskipTests
	)
    )
}

function setup_javamop_environment_variables() {
  export CLASSPATH=${ENV_DIR}/javamop/rv-monitor/target/release/rv-monitor/lib/rv-monitor-rt.jar:${ENV_DIR}/javamop/rv-monitor/target/release/rv-monitor/lib/rv-monitor.jar:$CLASSPATH
  export PATH=${ENV_DIR}/javamop/rv-monitor/target/release/rv-monitor/bin:${ENV_DIR}/javamop/javamop/target/release/javamop/javamop/bin:${ENV_DIR}/javamop/rv-monitor/target/release/rv-monitor/lib/rv-monitor-rt.jar:${ENV_DIR}/javamop/rv-monitor/target/release/rv-monitor/lib/rv-monitor.jar:${PATH}
}



function check_revs() {
    local proj_name=$1
    local rev_count=$2
    if [ ! -e ${REV_DIR}/${proj_name} ]; then
        echo "****Fetching revisions for ${proj_name}"
        tmp_list=/tmp/proj_list
        grep ${proj_name} ${PROJ_LIST} > ${tmp_list}
        ${SCRIPT_DIR}/getRevs.sh ${tmp_list}  ${rev_count}
    fi
}

function check_project_clone() {
    local url=$1
    local proj_name=$2
    local proj_dir=${SUBJECTS_DIR}/${proj_name}
    if [ ! -d  ${proj_dir} ]; then
        echo "****Cloning ${proj_name} to ${proj_dir}"
        git clone ${url} ${proj_dir}
    fi
}

function prepare_workspaces() {
    local project=$1
    local dest_dir=${WORKSPACES_DIR}/${project}
    if [ -d ${dest_dir} ]; then
        echo "${dest_dir} exists... not cloning"
    else
        cp -r ${SUBJECTS_DIR}/${project} ${WORKSPACES_DIR}/${project}
    fi
}

function rm_workspace() {
    local project=$1
    rm -rf ${WORKSPACES_DIR}/${project}
}

function write_meta_info() {
    mkdir -p ${WORKSPACES_DIR}
    local info_file=${WORKSPACES_DIR}/run.info
    touch ${info_file}
    echo "Experiment Started at: `date +%Y-%m-%d-%H-%M-%S`" | tee -a ${info_file}
    echo "Script: $0" >> ${info_file}
    echo "REPO-VERSION: "$(git rev-parse HEAD) >> ${info_file}
    echo "PROJECTS-RUN: " >> ${info_file}
    echo >> ${info_file}
    projects=$(cat ${PROJ_LIST} | cut -d' ' -f3)
    printf "%s\n" "${projects[@]}" >> ${info_file}
}

function write_end_time() {
    echo "Experiment ended at: `date +%Y-%m-%d-%H-%M-%S`" | tee -a ${WORKSPACES_DIR}/run.info
}

function output_start_message() {
    local str="$1"
    local run_info="$2"
    local project="$3"
    if [ "${project}" == "" ]; then
        project_string=
    else
        project_string="${project}: "
    fi
    echo "${project_string}${str} started at `date +%Y-%m-%d-%H-%M-%S`" | tee -a ${run_info}
}

function output_end_message() {
    local str="$1"
    local run_info="$2"
    local project="$3"
    if [ "${project}" == "" ]; then
        project_string=
    else
        project_string="${project}: "
    fi
    echo "${project_string}${str} ended at `date +%Y-%m-%d-%H-%M-%S`" | tee -a ${run_info}
}

function install_agent() {
    local agent=$1
    local agent_log=$2
    (
        set -o xtrace
        mvn install:install-file -Dmaven.repo.local=${LOCAL_M2_REPO} -Dfile=${agent} -DgroupId="javamop-agent" \
         -DartifactId="javamop-agent" -Dversion="1.0" -Dpackaging="jar"
        set +o xtrace
    ) &> ${agent_log}
}

function install_normal_agent() {
    local log_dir=$1
    local normal_mode=$2
    local agent_name=quiet-agent
    local quiet_agent=${AGENT_DIR}/${agent_name}.jar
    if [ "${normal_mode}" == "build" ]; then
        if [ ! -e ${quiet_agent} ]; then
            (bash ${SCRIPT_DIR}/make-agent.sh ${SCRIPT_DIR}/props ${AGENT_DIR}/ "quiet" "no-track" ${log_dir} ${agent_name}) &> ${log_dir}/make-quiet-agent-log
        fi
    fi
    if [ "${normal_mode}" == "install" ]; then
        install_agent ${quiet_agent} ${log_dir}/quiet-agent-install-log
    fi
}
