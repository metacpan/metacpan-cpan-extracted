package gma.util;

/**
 * <p>Title: </p>
 * <p>Description: InputFileHandler is a utility class for reading inputs from file.</p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Ali Argyle
 */


import java.io.ByteArrayInputStream;
import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.InputStream;


import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class ByteInputFileHandler {

    /*private InputStream reader = null; //buffered reader, reads text from a character input stream */
    private FileInputStream reader; // buffered reader, reads text from a character input stream 
    private int nextByte = 0; //next read in line 
    private ArrayList nextLine;

  /**
   * Constructor.
   * @param fileName              name of the input file
   */
  public ByteInputFileHandler(String fileName) {
    try {
	/* reader = new FileReader(fileName); */
      reader = new FileInputStream(fileName); 
    } catch (FileNotFoundException e) {
      e.printStackTrace();
      close();
      System.exit(1);
    }
  }

  /**
   * Checks if there are more bytes to read from the input file.
   * @return boolean, true if there are more bytes to read
   */
  public boolean hasByte() {

    nextByte = -1;
    
    try {
      nextByte = reader.read();
    } catch (IOException e) {
      e.printStackTrace();
      close();
      System.exit(1);
    }

    if (nextByte != -1) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * Gets the next read in byte.
   * @return  next read in byte
   */
  public int nextByte() {
    return nextByte;
  }


  /**
   * Gets the next line as an list of bytes
   * @return true if there is another line of bytes
   */
  public boolean hasLine() {
      nextLine = new ArrayList();
      String tempString; 
      while (hasByte()) {
	  tempString = Integer.toString(nextByte);
	  if (nextByte != 10) {
	      nextLine.add(new Integer(nextByte)); 
	  } else {
	      return true;
	  }
	  
      }
      return false;
  }


  /**
   * Gets the next line of bytes
   * @return next line of bytes
   */
  public List nextLine() {
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


  public List strip(List inList) {
      List outList = new ArrayList();
      int start = 0;
      int end = inList.size();

      // don't let the list start or end with a space
      while ( ((Integer)inList.get(start)).intValue() == 32) {
	  start = start + 1;
      }
      while ( ((Integer)inList.get(end-1)).intValue() == 32) {
	  end = end -1;
      }
	      
      for (int i=start; i< end; i++) 
	  {
	      outList.add(  (Integer)inList.get(i)  );
	  }
      return outList;
  }


  /**
   * Utility method to read a column of single words.
   * @return                  list of words
   */
  public List readWordList() {

      List words = new ArrayList();

      while (hasLine()) {
	  List wordList = nextLine();
	  words.add(strip(wordList));
      }

      close();
      return words;
  }
    
}

