package gma.gsa;

/**
 * <p>Title: </p>
 * <p>Description: Segment represents a segment in the input file that needs to be aligned.</p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

import gma.AxisTick;
import gma.MapPoint;

public class Segment implements Comparable {

  private int index;  //index of the segment
  private float startPosition;  //start position of the segment
  private float endPosition;  //end position of the segment
  private float length;  //size of contents of the segment

  /**
   * Constructor.
   * @param index               index of the segment
   * @param startPosition       start position of the segment
   * @param endPosition         end position of the segment
   * @param length              size of contents of the segment
   */
  public Segment(int index, float startPosition, float endPosition, float length) {
    this.index = index;
    this.startPosition = startPosition;
    this.endPosition = endPosition;
    this.length = length;
  }

  /**
   * Gets the index of the segment.
   * @return            index of the segment
   */
  public int getIndex() {
    return index;
  }

  /**
   * Gets the start position of the segment.
   * @return            start position of the segment
   */
  public float getStartPosition() {
    return startPosition;
  }

  /**
   * Gets the stop position of the segment.
   * @return            stop position of the segment
   */
  public float getEndPosition() {
    return endPosition;
  }

  /**
   * Gets the actual length of what is inside the segment.
   * @return             length of the insides of the segment
   */
  public float getLength() {
    return length;
  }

  /**
   * Gets the distance covered by the segment.
   * @return             distance covered by the segment
   */
  public float getDistance() {
    return endPosition - startPosition;
  }

  /**
   * Tests whether a map point is contained in the segment.
   * @param mapPoint                  map point of correspondence
   * @param isXAxis                   true to check x axis position of the map point
   * @return                          true if the map point is contained in the segment
   */
  public int contains(MapPoint mapPoint, boolean isXAxis) {
    AxisTick axisTick = null;
    if (isXAxis) {
      axisTick = mapPoint.getXAxisTick();
    } else {
      axisTick = mapPoint.getYAxisTick();
    }
    if (axisTick.getPosition() >= startPosition && axisTick.getPosition() <= endPosition) {
      return 0;
    } else if (axisTick.getPosition() < startPosition) {
      return -1;
    } else {
      return 1;
    }
  }

  /**
   * Compares the location of two segments.
   * Assumes that segments are non-overlapping and thus comparison based on start position is suffice.
   * @param segment               segment to compare with
   * @return                      -1 if the current segment is located before the compared segment
   *                              0 if the current segment is of the same location with the compared segment
   *                              1 if the current segment is located after the compared segment
   */
  public int compareTo(Object segment) {
    if (startPosition == ((Segment)segment).getStartPosition()) {
      return 0;
    } else if (startPosition < ((Segment)segment).getStartPosition()) {
      return -1;
    } else {
      return 1;
    }
  }

  /**
   * Tests whether two segments are of the same location.
   * Assumes that segments are non-overlapping and thus comparison based on start position is suffice.
   * @param segment               segment to compare with
   * @return                      true if two segments are of the same location
   */
  public boolean equals(Object segment) {
    return startPosition == ((Segment)segment).getStartPosition();
  }

  /**
   * String representation of the segment.
   * @return              string representation of the segment
   */
  public String toString() {
    return String.valueOf(index);
  }
}
