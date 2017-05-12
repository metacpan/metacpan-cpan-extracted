package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: PointDisplacementComparator is a comparator used to sort map points according to their displacement.</p>
 * <p>Copyright: Copyright (c) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

import gma.MapPoint;

import java.util.Comparator;

public class PointDisplacementComparator implements Comparator {

  /**
   * Checks the displacement of map points.
   * @param mapPointComparer          map point to compare from
   * @param mapPointComparee          map point to compare to
   * @return                          -1 if less displaced
   *                                  1 if more displaced or same displaced
   */
  public int compare(Object mapPointComparer, Object mapPointComparee) {
    /** @todo check type before cast */
      // note that this does not properly implement comparator since
      // there is no 0 return value but it works for our purposes
    if (((MapPoint)mapPointComparer).getDisplacement() < ((MapPoint)mapPointComparee).getDisplacement()) {
      return -1;
    } else {
      return 1;
    }
  }
}
