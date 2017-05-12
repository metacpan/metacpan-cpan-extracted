package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: MatchingPredicate defines interface for word matching.</p>
 * <p>Copyright: Copyright (C) 2003 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Ali Argyle
 */

import java.util.Properties;
import java.util.List;

public interface ByteMatchingPredicate {

  /**
   * Sets properties.
   * @param properties            properties
   */
  void setProperties(Properties properties);

  /**
   * Checks whether two words match.
   * @param wordForMatch          word to match from
   * @param wordToMatch           word to match to
   * @return                      true if two words match
   */
  
  boolean isMatch(List wordForMatch, List wordToMatch);
}
