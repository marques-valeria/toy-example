package edu.cornell.cs6156;

import org.junit.Test;

/**
 * This test suite demonstrates that a test suite may or may not find a violation (regardless of coverage) because
 * the violation occurs as a result of the environment. In this case, the interweaving of multiple threads.
 */
public class CodeSpecCoverageTest {

    @Test
    public void test() {
        CodeSpecCoverage csc = new CodeSpecCoverage();
        csc.test(2);
    }
}
