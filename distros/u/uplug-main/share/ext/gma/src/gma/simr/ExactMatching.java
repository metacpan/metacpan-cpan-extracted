package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: ExactMatching represents matching by exact byte match.</p>
 * <p>Copyright: Copyright (C) 2003 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 */

import gma.BitextSpace;
import gma.util.InputFileHandler;
import gma.util.ByteInputFileHandler;
import gma.util.ByteParser;
import java.util.ArrayList;
import java.util.Arrays;
import java.io.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.StringTokenizer;

public class ExactMatching implements MatchingPredicate {
    
  public List xStopWords = new ArrayList();
  public List yStopWords = new ArrayList();


  /**
   * Sets properties.
   * @param properties                    properties
   */
  public void setProperties(Properties properties) {

    xStopWords = loadStopWordList(properties, BitextSpace.X_STOP_WORD_FILE);
    
    yStopWords = loadStopWordList(properties, BitextSpace.Y_STOP_WORD_FILE);

  }

  /**
   * Loads stop word list.
   * @param properties                  properties
   * @param propertyName                property name for stop word file
   * @return
   */
  private List loadStopWordList(Properties properties, String propertyName) {
    String stopWordFile = properties.getProperty(propertyName);
    ByteInputFileHandler input = new ByteInputFileHandler(stopWordFile);
    return input.readWordList();
  }


  /**
   * Checks whether two words "match".
   * @param wordForMatch                word to match from
   * @param wordToMatch                 word to match to
   * @return                            true if two words match
   */
  public boolean isMatch(List inWord1, List inWord2, boolean isXAxis) {
      List wordToMatch;
      List wordForMatch;

      if (isXAxis) {
	  wordToMatch = inWord1;
	  wordForMatch = inWord2;
      } else {
	  wordForMatch = inWord1;
	  wordToMatch = inWord2;
      }
      // they may in fact be the same word, return true
      if (wordForMatch.equals(wordToMatch)) {
	  // now check to make sure that the word isn't in either stoplist
	  if ( (xStopWords.contains(wordForMatch)) || (yStopWords.contains(wordToMatch)) ) {
	      return false; 
	  } else {
	      return true;
	  }
      }
      return false; 
  } // end of isMatch



}
