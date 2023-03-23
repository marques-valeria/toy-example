package edu.cornell.cs6156;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;

public class CodeCoverage {

    ObjectOutputStream oos;
    ByteArrayOutputStream baos;

    public CodeCoverage() throws IOException {
        baos = new ByteArrayOutputStream();
        oos = new ObjectOutputStream(baos);
    }

    public boolean write (String s) {
        try {
            oos.write(s.getBytes());
            oos.flush();
        } catch (IOException e) {
            return false;
        }
        return true;
    }

    public String getCurrentContents() {
        return baos.toString();
    }
}
