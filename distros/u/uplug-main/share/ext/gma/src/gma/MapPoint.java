package gma;

/**
 * <p>Title: </p>
 * <p>Description: MapPoint represents map points in bitext space.</p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

public class MapPoint implements Comparable {

  private AxisTick xAxisTick = null;  //x axis tick of map point
  private AxisTick yAxisTick = null;  //y axis tick of map point

  private double displacement = Double.NaN; //displacement of map point

  /**
   * Constructor.
   * @param xAxisTick               x axis tick
   * @param yAxisTick               y axis tick
   */
  public MapPoint(AxisTick xAxisTick, AxisTick yAxisTick) {
    this.xAxisTick = xAxisTick;
    this.yAxisTick = yAxisTick;
  }

  /**
   * Gets x axis tick.
   * @return                x axis tick
   */
  public AxisTick getXAxisTick() {
    return xAxisTick;
  }

  /**
   * Gets y axis tick.
   * @return                y axis tick
   */
  public AxisTick getYAxisTick() {
    return yAxisTick;
  }

  /**
   * Checks whether two map points are in conflict.
   * @param pointToCompare              map point for comparison
   * @return                            true if two map points are in conflict
   */
  public boolean isConflict(MapPoint pointToCompare) {
    if (xAxisTick.equals(pointToCompare.getXAxisTick()) &&
              yAxisTick.equals(pointToCompare.getYAxisTick())) {
      return false;
    } else if (!xAxisTick.equals(pointToCompare.getXAxisTick()) &&
              !yAxisTick.equals(pointToCompare.getYAxisTick())) {
      return false;
    } else {
      return true;
    }
  }

  /**
   * Checks the position of map points.
   * @param mapPoint              map point for comparison
   * @param xAxisCompare          true for x axis based position comparison
   * @return                      -1 if lower position on axis
   *                              0 if same position on axis
   *                              1 if higher position on axis
   */
  public int isMaxMapPoint(MapPoint mapPoint, boolean xAxisCompare) {
    if (xAxisCompare) {
      return xAxisTick.isMaxAxisTick(mapPoint.getXAxisTick());
      
    } else {
      return yAxisTick.isMaxAxisTick(mapPoint.getYAxisTick());
    }
  }

  /**
   * Computes map point displacement.
   * @param slope               slope for map point displacement
   */
  public void computeDisplacement(double slope) {
    /** @todo improve for efficiency,  because trigonometric computation is repeated in each call*/
    double ratio = Math.sin(Math.atan(slope));
    // changed displacement type to double  -Ali
    displacement = (double)((yAxisTick.getPosition() / slope - xAxisTick.getPosition()) * ratio);
  }

  /**
   * Gets map point displacement.
   * @return              map point displacement
   */
  public double getDisplacement() {
    return displacement;
  }

  /**
   * Checks x axis position of map points.
   * @param mapPoint              map point for comparison
   * @return                      -1 if lower x axis position
   *                              0 if same x axis position
   *                              1 if higher axis position
   */
  public int compareTo(Object mapPoint) {
    /** @todo type check before cast */
    return isMaxMapPoint((MapPoint)mapPoint, true);
  }

  /**
   * Checks whether two map points are the same.
   * @param compareMapPoint           map points for comparison
   * @return                          true if same map points
   */
  public boolean equals(Object compareMapPoint) {
    if (xAxisTick.equals(((MapPoint)compareMapPoint).getXAxisTick())
    && yAxisTick.equals(((MapPoint)compareMapPoint).getYAxisTick())) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * String representation of map point.
   * @return                string representation of map point
   */
  public String toString() {
    return xAxisTick.toString() + " " + yAxisTick.toString();
  }
}
