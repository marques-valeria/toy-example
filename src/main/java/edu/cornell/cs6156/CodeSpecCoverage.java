package edu.cornell.cs6156;

import java.util.Stack;

public class CodeSpecCoverage {

    Stack<Integer> numbers = new Stack<>();

    int count = 0;

    public CodeSpecCoverage() {
        for (int i = 0; i < 100; i++) {
            numbers.push(i);
        }
    }

    public void test(int num) {
        for (int i = 0; i < num; i++) {
            new countThread().start();
            new removeThread().start();
        }
    }

    class countThread extends Thread {
        public void run() {
            count = 0;
            for (Integer i : numbers) {
                count += i;
            }
        }
    }

    class removeThread extends Thread {
        public void run() {
            numbers.pop();
        }
    }

}
