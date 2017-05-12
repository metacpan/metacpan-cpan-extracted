package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: LcsrMatching represents longest common string matching.</p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Ali Argyle
 */

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Properties;

public class LcsrLexMatching implements MatchingPredicate {

  public Map hTrans = new HashMap(); // non-english keys
  public Map vTrans = new HashMap();   // english keys
  public List xStopWords = new ArrayList();
  public List yStopWords = new ArrayList();
  public DictExactMatching tralexMatching = new DictExactMatching();
  public LcsrMatching lcsrMatching = new LcsrMatching();
  public Properties myproperties = null;

  /**
   * Sets properties.
   * @param properties            properties
   */
  public void setProperties(Properties properties) {
      tralexMatching.setProperties(properties);
      hTrans = tralexMatching.hTrans;
      vTrans = tralexMatching.vTrans;
      lcsrMatching.setProperties(properties);
  }

  /**
   * Checks whether two words matches.
   * @param wordForMatch          word to match from
   * @param wordToMatch           word to match to
   * @return                      true if two words match
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

      // if either word is in the tralex, 
      // then only accept if the other is a valid translation
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
	  return false;
      } else if ((hTrans.containsKey(wordForMatch)) || (vTrans.containsKey(wordToMatch))) {
	  //System.err.println("Only one is in the dictionary");
	  return false;
      }



      return (lcsrMatching.isMatch(inWord1, inWord2, isXAxis));
  }
}
