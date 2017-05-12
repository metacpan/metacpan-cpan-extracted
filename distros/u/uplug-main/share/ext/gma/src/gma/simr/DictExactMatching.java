package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: DictExactMatching represents matching by translation lexicon or exact byte match.</p>
 * <p>Copyright: Copyright (C) 2003 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @version 2.0 RC 2
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

public class DictExactMatching implements MatchingPredicate {
    
  //constant in property file
  public static final String TRANSLATION_LEXICON = "translationLexicon";

    //public Map translationLexicons = new HashMap();  //map of translation lexicons
  public Map hTrans = new HashMap(); // non-english keys
  public Map vTrans = new HashMap();   // english keys
  public List xStopWords = new ArrayList();
  public List yStopWords = new ArrayList();


  /**
   * Sets properties.
   * @param properties                    properties
   */
  public void setProperties(Properties properties) {

    xStopWords = loadStopWordList(properties, BitextSpace.X_STOP_WORD_FILE);
    
    yStopWords = loadStopWordList(properties, BitextSpace.Y_STOP_WORD_FILE);

    String translationLexiconFile = properties.getProperty(TRANSLATION_LEXICON);
    //System.err.println("tlf: " + translationLexiconFile);
    // is the translationLexiconFile in text or in serial format?
    if (translationLexiconFile.endsWith(".serial")) {
	//System.err.println("tlf: ends with serial");
	// the file is in serial format
	File theFile = new File(translationLexiconFile);
	FileInputStream inStream;
	ObjectInputStream objStream; 
	if(!theFile.exists()) {
	    System.err.println("File "+ theFile.getAbsolutePath()+ " does not exist.");
	    System.exit(1);
	}
	try {
	    inStream = new FileInputStream(theFile);
	    // attach a stream capable of reading objects to the stream that is
	    // connected to the file
	    objStream = new ObjectInputStream(inStream);
	    hTrans = (Map)objStream.readObject();
	    vTrans = (Map)objStream.readObject();

	    // close down the streams
	    objStream.close();
	    inStream.close();

	} catch(IOException e) {
	    System.err.println("Serialized lexicon not in the right format.");
	    e.printStackTrace();
	} catch(ClassNotFoundException e) {
	    System.err.println("Things not going as planned.");
	    e.printStackTrace();
	} catch(ClassCastException e) {
	    // end up here if one of the objects were read wrong
	    System.err.println("Cast didn't work quite right.");
	    e.printStackTrace();
	}   // catch  

	
	//System.err.println("Done reading in the object from serial form");

	



    } else {
	//System.err.println("tlf: in text format");
	// the file is in text format
	
	ByteInputFileHandler input = new ByteInputFileHandler(translationLexiconFile);
    
	// go through each line in the dictionary
	OUTER: while (input.hasLine()) {
	    List dictLine = input.nextLine();
	    ByteParser bParser = new ByteParser(dictLine);
	    List pairList = bParser.parseDictionaryLine();
	    
	    if (pairList.size() != 2) {
		System.err.println("The input file is not in the correct translation lexicon format.");
		input.close();
		System.exit(1);
	    }
	    List from = (List)pairList.get(0);

	    //ByteParser bpf = new ByteParser(from);
	    //System.err.println("word1 = " + bpf.listToString());
	    //assumes the stopWords are all in the lower case
	    //if (xStopWords.contains(from.toLowerCase())) {
	    if (xStopWords.contains(from)) {
		continue OUTER;
	    } else {
		// put second word in 'to' as a list
		List to = (List)pairList.get(1);
		//ByteParser bpt = new ByteParser(to);
		//System.err.println("word1 = " + bpt.listToString());

		if (!yStopWords.contains(to)) {


		    //         add the pair to the dictionary
		    //         hTrans (non-english keys)
		    //         ------------------------------
		    if ((List)hTrans.get(from) ==null) {
			List toList = new ArrayList();
			toList.add(to);
			hTrans.put(from,toList);
		    } else {
			List largerList = (List)hTrans.get(from);
			if (!largerList.contains(to)) {
			    largerList.add(to);
			    hTrans.put(from,largerList);
			}
		    }
		    //         add the pair to the dictionary
		    //         vTrans  (in the other direction)
		    //         ------------------------------
		    if ((List)vTrans.get(to) ==null) {
			List fromList = new ArrayList();
			fromList.add(from);
			vTrans.put(to,fromList);
		    } else {
			List largerList = (List)vTrans.get(to);
			if (!largerList.contains(from)) {
			    //List largerList = new ArrayList();
		  
			    largerList.add(from);
			    vTrans.put(to,largerList);
			}
		    }
		} 
	    }
	
	} // Matches OUTER: while
	input.close();    

    }  // Matches else 
    

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
      
      if ((hTrans.containsKey(wordForMatch))  && (vTrans.containsKey(wordToMatch))) {
	  
	  List hmatchLex = (List)hTrans.get(wordForMatch);
	  List vmatchLex = (List)vTrans.get(wordToMatch);
	  
	  if (hmatchLex.size() > vmatchLex.size()) {
	      if (vmatchLex.contains(wordForMatch)) {
		  return true;
	      }
	  
	  } else {
	      if (hmatchLex.contains(wordToMatch)) {
		  return true;
	      }
	  }
      }
      return false; 

  }


}
