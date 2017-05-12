package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: MatchingPredicate defines interface for word matching.</p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

import java.util.Properties;
import java.util.List;

abstract interface MatchingPredicate {
  /**
   * Sets properties.
   * @param properties            properties
   */
  public void setProperties(Properties properties);

  /**
   * Checks whether two words match.
   * @param wordForMatch          word to match from
   * @param wordToMatch           word to match to
   * @return                      true if two words match
   */
  
  public boolean isMatch(List wordForMatch, List wordToMatch, boolean isXAxis);
}
