package gma.util;

/**
 * <p>Title: </p>
 * <p>Description: OutputFileHandler is a utility class for writing out to a file.</p>
 * <p>Copyright: Copyright (c) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

import java.io.BufferedOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintWriter;

public class OutputFileHandler {

  private PrintWriter writer = null;  //writer

  /**
   * Constructor.
   * @param fileName            file to write to
   */
  public OutputFileHandler(String fileName) {
    try {
      writer = new PrintWriter(new BufferedOutputStream(new FileOutputStream(fileName)));
    } catch (IOException e) {
      e.printStackTrace();
      close();
      System.exit(1);
    }
  }

  /**
   * Writes out a line.
   * @param line                a line to write out
   */
  public void write(String line) {
    writer.write(line);
    writer.flush();
  }

  /**
   * Closes output file handler.
   */
  public void close() {
    if (writer != null) {
      writer.close();
    }
  }
}
