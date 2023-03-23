package edu.cornell.cs6156;

import java.io.IOException;

import org.junit.Test;

/**
 * This test suite demonstrates that a test suite which satisfies edge coverage for a specification but does not find
 * a violation located in uncovered code (in the method updateTextTwo)
 */
public class SpecCoverageTest
{
    @Test
    public void baosTestOne() throws IOException {
        String s = null;
        SpecCoverage a = new SpecCoverage();
        a.updateText(s);
    }

    @Test
    public void baosTestTwo() throws IOException {
        String s = "";
        SpecCoverage a = new SpecCoverage();
        a.updateText(s);
    }

    @Test
    public void baosTestThree() throws IOException {
        String s = "Hello World!";
        SpecCoverage a = new SpecCoverage();
        a.updateText(s);
    }
}
