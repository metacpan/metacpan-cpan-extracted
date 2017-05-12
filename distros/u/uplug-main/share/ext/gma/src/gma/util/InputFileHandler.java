package gma.util;

/**
 * <p>Title: </p>
 * <p>Description: InputFileHandler is a utility class for reading inputs from file.</p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class InputFileHandler {

  private BufferedReader reader = null; //buffered reader, reads text from a character input stream
  private String nextLine = null; //next read in line

  /**
   * Constructor.
   * @param fileName              name of the input file
   */
  public InputFileHandler(String fileName) {
    try {
      reader = new BufferedReader(new FileReader(fileName));
    } catch (FileNotFoundException e) {
      e.printStackTrace();
      close();
      System.exit(1);
    }
  }

  /**
   * Checks if there are more lines to read from the input file.
   * @return                      true if there are more lines to read from the input file
   */
  public boolean hasLine() {

    nextLine = null;

    try {
      nextLine = reader.readLine();
    } catch (IOException e) {
      e.printStackTrace();
      close();
      System.exit(1);
    }

    if (nextLine != null) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * Gets the next read in line.
   * @return                      next read in line
   */
  public String nextLine() {
    return nextLine;
  }

  /**
   * Closes the input file.
   */
  public void close() {
    if (reader != null) {
      try {
        reader.close();
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
  }

  /**
   * Utility method to read a column of single words.
   * @return                  list of words
   */
  public List readWordList() {

    List words = new ArrayList();

    while (hasLine()) {
      String word = nextLine();
      words.add(word);
    }

    close();
    return words;
  }
}
