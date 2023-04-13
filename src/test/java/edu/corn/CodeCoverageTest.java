package edu.corn;

import org.junit.Before;
import org.junit.Test;

import java.io.IOException;

import static org.junit.Assert.assertTrue;

/**
 * This test suite demonstrates that a test suite which satisfies line coverage for a class but does not find a
 * violation caused by taking a particular transition in the specification automaton.
 */
public class CodeCoverageTest {
    CodeCoverage b;

    @Before
    public void setup() throws IOException {
        b = new CodeCoverage();
    }

    @Test
    public void lineCoverage() throws IOException {
        b.write("Hello World!");
        assertTrue(b.getCurrentContents().contains("Hello World!"));
    }

    @Test
    public void moreLineCoverage() throws IOException {
        b.write("Hello");
        b.write(" World");
        assertTrue(b.getCurrentContents().contains("Hello") && b.getCurrentContents().contains("World"));
    }

    @Test
    public void violation() throws IOException {
        b.getCurrentContents();
    }
}
