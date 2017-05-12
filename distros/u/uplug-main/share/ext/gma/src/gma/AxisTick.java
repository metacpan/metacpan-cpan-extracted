package gma;

/**
 * <p>Title: </p>
 * <p>Description: AxisTick represents a tick on the axis.</p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

import java.util.List;

public class AxisTick {

  private int index;  //index of axis tick
  private float position; //position of axis tick
  private List word;  //word of axis tick

  /**
   * Constructor
   * @param index             index of axis tick
   * @param position          position of axis tick
   * @param word              word of axis tick
   */
  public AxisTick(int index, float position, List word) {
    this.index = index;
    this.position = position;
    this.word = word;
  }

  /**
   * Gets the index of axis tick.
   * @return              index of axis tick
   */
  public int getIndex() {
    return index;
  }

  /**
   * Gets the position of axis tick.
   * @return              position of axis tick
   */
  public float getPosition() {
    return position;
  }

  /**
   * Gets the word of axis tick.
   * @return              word of axis tick
   */
  public List getWord() {
    return word;
  }

  /**
   * Compares for higher position in the axis tick.
   * @param axisTick          axis tick for comparing
   * @return                  -1 if has lower position,
   *                          0 if has similar position,
   *                          1 if has higher position
   */
  public int isMaxAxisTick(AxisTick axisTick) {
    if (position == axisTick.getPosition()) {
      return 0;
    } else {
      return position < axisTick.getPosition() ? -1 : 1;
    }
  }

  /**
   * Compares whether two axis ticks are the same.
   * @param axisTick            axis tick for comparing
   * @return                    true if the same axis tick
   */
  public boolean equals(Object axisTick) {
    if (position == ((AxisTick)axisTick).getPosition()) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * String representation of axis tick.
   * @return                  string representation
   */
  public String toString() {
    return String.valueOf(position);
  }
}
