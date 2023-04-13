package edu.corn;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;

public class SpecCoverage
{
    String text = null;
    byte[] barray;

    public void updateText(String newText) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ObjectOutputStream oos = new ObjectOutputStream(baos);
        if (newText == null) {
            oos.close();
            text = baos.toString();
            barray = baos.toByteArray();
        }
        else if (newText.isEmpty()) {
            oos.flush();
            oos.flush();
            text = baos.toString();
            barray = baos.toByteArray();
            oos.close();
        }
        else {
            oos.writeObject(newText);
            oos.flush();
            oos.writeObject(newText);
            oos.close();
            text = baos.toString();
            barray = baos.toByteArray();
        }
    }

    public void updateTextTwo(String newText) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ObjectOutputStream oos = new ObjectOutputStream(baos);
        oos.writeObject(newText);
        text = baos.toString();
    }
}
