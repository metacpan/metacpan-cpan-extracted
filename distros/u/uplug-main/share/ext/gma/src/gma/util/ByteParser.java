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
import java.util.Iterator;


import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class ByteParser {

  private FileInputStream reader; //buffered reader, reads text from a character input stream
  private int nextByte = 0; //next read in line
  private List byteList;
  private ArrayList wordList;
  private ArrayList positionList;
  private ArrayList dictFrom;
  private ArrayList dictTo;    

  /**
   * Constructor.
   * @param fileName              name of the input file
   */
  public ByteParser(List inList) {
      byteList = inList; 
  }


  /**
   * Get the string representation
   * @return string
   */
  public String listToString() {
      StringBuffer outString = new StringBuffer();
      Iterator li = byteList.iterator();      
      while (li.hasNext()) {
	  outString.append( (char)((Integer)li.next()).intValue() );
      }
      return outString.toString();
  }

  /**
   * How big is the current byteList
   * 
   */
  public int getSize() {
      int ls = byteList.size();
      return ls;
  }

  /**
   * Parse the dictionary line in current byteList
   * @return  list of bytes 
   */
  public List parseDictionaryLine() {
      
      List langList1 = new ArrayList();
      List langList2 = new ArrayList();
      List outList = new ArrayList();
      int start = -1;
      int end = -1;
      boolean preSpace = true;

      for (int i = 0; i < byteList.size(); i++) {
	  int c = ((Integer)byteList.get(i)).intValue();
	  //System.err.println("c = " + c);
	  if ( (c==62) && (i>1) ) {  
	      /* check one backward */
	      //System.err.println("--------------> got a 62");
	      int cminus1 = ((Integer)byteList.get(i-1)).intValue();
	      if (cminus1==60) {
		  //System.err.println("--------------> got a 60");
		  /* found an instance of <> */
		  start = i-1;
		  end = i;
	      }
	  }
      }
      if ((start == -1) || (end == -1)) {
	  /* seperator not found */
	  System.err.println("The input file is not in the correct translation lexicon format.");
	  System.exit(1);
      }

      for (int i = 0; i < byteList.size(); i++) {
	  if (i < start) {
	      /* put in langList1 */
	      int c = ((Integer)byteList.get(i)).intValue();
	      langList1.add(new Integer(c));
	  } else if (i > end) {
	      /* put in langList2 */
	      int c = ((Integer)byteList.get(i)).intValue();
	      langList2.add(new Integer(c));
	  }
      }
      if (langList1.size() != 0) {
	  outList.add( strip(langList1) );
      }
      if (langList2.size() != 0) {
	  outList.add( strip(langList2) );
      }

      return outList;
  }

  public List strip(List inList) {
      List outList = new ArrayList();
      int start = 0;
      int end = inList.size();

      // don't let the list start or end with a space
      while ( ((Integer)inList.get(start)).intValue() == 32) {
	  start = start + 1;
	  // catch the case where there is no corresponding entry
	  if (start == end) {
	      System.err.println("The lexicon contains an invalid entry");
	      return outList;
	  }
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
   * Parse the axis line in current byteList
   * @return  list of bytes 
   */
  public List parseAxisLine() {
      List positionList = new ArrayList();
      List wordList = new ArrayList();
      List outList = new ArrayList();
      boolean preSpace = true;

      for (int i = 0; i < byteList.size(); i++) {
	  int c = ((Integer)byteList.get(i)).intValue();

	    
	  if ((c == 32) && (preSpace == true)) { /* 32 is the space character */
	      if (positionList.size() != 0) {
		  preSpace = false;
	      }
	  } else {       
	      if (preSpace == true) {
		  positionList.add(new Integer(c));
	      }
	      else {
		  wordList.add(new Integer(c));
	      }
	  }
      }
      if (positionList.size() != 0) {
	  outList.add( strip(positionList) );
      }
      if (wordList.size() != 0) {
	  outList.add( strip (wordList) );
      }
      /* System.err.println("positionList " + positionList); */
      /* System.err.println("wordList " + wordList); */
      return outList;
  }

  
}
 
