package gma.gsa;

/**
 * <p>Title: </p>
 * <p>Description: AlignedBlock represents the aligment of segments.</p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 * @version 2.0
 */

import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

public class AlignedBlock {

  List xAxisSegments = new LinkedList();  //list of x axis segments in alignment
  List yAxisSegments = new LinkedList();  //list of y axis segments in alignemnt
  //segments in the above two lists are continuous and non-overlapping,
  //but one of them can be empty

  /**
   * Clears the aligned block.
   * 
   */
    public void clear() {
	xAxisSegments.clear();
	yAxisSegments.clear();
    }
  /**
   * Copies the aligned block.
   * 
   */
    public AlignedBlock copy() {
	AlignedBlock alignedBlock = new AlignedBlock();
	List xSegBlock = new LinkedList(this.getSegments(true, true));
	List ySegBlock = new LinkedList(this.getSegments(false, true));

	alignedBlock.xAxisSegments = xSegBlock;
	alignedBlock.yAxisSegments = ySegBlock;
	return alignedBlock;
    }

  /**
   * Adds segment to the aligned block.
   * @param segment             segment to be added
   * @param isXAxis             true for x axis segment
   */
  public void addSegment(Segment segment, boolean isXAxis) {
    if (isXAxis) {
      int index = xAxisSegments.indexOf(segment);
      if (index != -1) {
        //do nothing is the new segment already exists
      } else {
        for (int loopIndex = 0; loopIndex < xAxisSegments.size(); loopIndex++) {
          if (segment.compareTo(xAxisSegments.get(loopIndex)) == -1) {
            //add the new segment in the appropriate position
            xAxisSegments.add(loopIndex, segment);
            break;
          }
        }
        if (xAxisSegments.size() == 0 || segment.compareTo(xAxisSegments.get(xAxisSegments.size() - 1)) == 1) {
          xAxisSegments.add(segment);
        }
      }
    } else {
      int index = yAxisSegments.indexOf(segment);
      if (index != -1) {
        //do nothing is the new segment already exists
      } else {
        for (int loopIndex = 0; loopIndex < yAxisSegments.size(); loopIndex++) {
          if (segment.compareTo(yAxisSegments.get(loopIndex)) == -1) {
            //add the new segment in the appropriate position
            yAxisSegments.add(loopIndex, segment);
            break;
          }
        }
        if (yAxisSegments.size() == 0 || segment.compareTo(yAxisSegments.get(yAxisSegments.size() - 1)) == 1) {
          yAxisSegments.add(segment);
        }
      }
    }
  }

  /**
   * Tests whether the x axis segments and y axis segments are even in the aligned block.
   * @return                    -1 if there are less x axis segments than y axis segments
   *                            0 if x axis segments and y axis segments are of the same size
   *                            1 if there are more x axis segments than y axis segments
   */
  public int getBalanceStatus() {
    if ( xAxisSegments.size() == yAxisSegments.size() ) {
      return 0;
    } else if ( xAxisSegments.size() < yAxisSegments.size() ) {
      return -1;
    } else {
      return 1;
    }
  }

  /**
   * Tests whether there are segments in the aligned block.
   * @param isXAxis                   true for x axis segments
   * @return                          true if there are segments in the specified axis
   */
  public boolean hasSegments(boolean isXAxis) {
    if (isXAxis) {
      return xAxisSegments.size() > 0;
    } else {
      return yAxisSegments.size() > 0;
    }
  }

  /**
   * Gets a reference or a copy of the segment list.
   * @param isXAxis                   true for x axis segments
   * @param isClone                   true to get a copy of the segments
   * @return                          list of segments
   */
  public List getSegments(boolean isXAxis, boolean isClone) {
    if ( isXAxis && !isClone ) {
      return xAxisSegments;
    } else if ( !isXAxis && !isClone ) {
      return yAxisSegments;
    } else { // ie. isClone == true
      List sourceList = null;
      if ( isXAxis ) {
        sourceList = xAxisSegments;
      } else {
        sourceList = yAxisSegments;
      }
      List clone = new LinkedList();
      Iterator iterator = sourceList.iterator();
      while (iterator.hasNext()) {
        clone.add(iterator.next());
      }
      return clone;
    }
  }

  /**
   * Computes balance score for aligned block merge.
   * @param blockToBalance                aligned block to merge with
   * @param isPreviousBlock               true to merge with previous aligned block
   *                                      false to merge with next aligned block
   * @param isXAxis                       true for x axis balance
   * @return                              computed balance score
   */
  public double computeBalance(AlignedBlock blockToBalance, boolean isPreviousBlock, boolean isXAxis) {

    List upXSegments = null;
    List upYSegments = null;
    List alterUpXSegments = null;
    List alterUpYSegments = null;
    List downXSegments = null;
    List downYSegments = null;
    List alterDownXSegments = null;
    List alterDownYSegments = null;

    Segment balanceSegment = null;
    double alterBalanceScore;

    if (!isPreviousBlock) {
      // Balancing Down
      upXSegments = xAxisSegments;
      upYSegments = yAxisSegments;
      downXSegments = blockToBalance.getSegments(true, false);
      downYSegments = blockToBalance.getSegments(false, false);
      if (isXAxis) {

        alterUpXSegments = getSegments(true, true);
        balanceSegment = (Segment)alterUpXSegments.get(0);
        alterUpXSegments.remove(0);
        alterDownXSegments = blockToBalance.getSegments(true, true);
	
        alterDownXSegments.add(balanceSegment);
        alterBalanceScore = computeBalanceUp(alterUpXSegments, upYSegments)
                    + computeBalanceDown(alterDownXSegments, downYSegments);

      } else { // ie. isXAxis == false

        alterUpYSegments = getSegments(false, true);
        balanceSegment = (Segment)alterUpYSegments.get(0);
        alterUpYSegments.remove(0);
        alterDownYSegments = blockToBalance.getSegments(false, true);
        alterDownYSegments.add(balanceSegment);
        alterBalanceScore = computeBalanceUp(upXSegments, alterUpYSegments)
                      + computeBalanceDown(downXSegments, alterDownYSegments);

      }

    } else { // ie. isPreviousBlock == true

      downXSegments = xAxisSegments;
      downYSegments = yAxisSegments;
      upXSegments = blockToBalance.getSegments(true, false);
      upYSegments = blockToBalance.getSegments(false, false);

      if (isXAxis) {

        alterDownXSegments = getSegments(true, true);
        balanceSegment = (Segment)alterDownXSegments.get(alterDownXSegments.size() - 1);
        alterDownXSegments.remove(alterDownXSegments.size() - 1);
        alterUpXSegments = blockToBalance.getSegments(true, true);
	// make sure the segment goes at the beginning of the list
        alterUpXSegments.add(0, balanceSegment);
        alterBalanceScore = computeBalanceUp(alterUpXSegments, upYSegments)
                    + computeBalanceDown(alterDownXSegments, downYSegments);

      } else { // ie. isXAxis == false

        alterDownYSegments = getSegments(false, true);
        balanceSegment = (Segment)alterDownYSegments.get(alterDownYSegments.size() - 1);
        alterDownYSegments.remove(alterDownYSegments.size() - 1);
        alterUpYSegments = blockToBalance.getSegments(false, true);
        alterUpYSegments.add(0, balanceSegment);
        alterBalanceScore = computeBalanceUp(upXSegments, alterUpYSegments)
                    + computeBalanceDown(downXSegments, alterDownYSegments);

      }
    }
    double currentBalanceScore = computeBalanceUp(upXSegments, upYSegments)
                  + computeBalanceDown(downXSegments, downYSegments);
    return (currentBalanceScore - alterBalanceScore) / (double)(balanceSegment.getDistance());
  }

  /**
   * Computes balance score if merge with segments from next aligned block.
   * @param upXSegments                     list of x axis segments from next aligned block
   * @param upYSegments                     list of y axis segments from next aligned block
   * @return                                computed balance score
   */
  private double computeBalanceUp(List upXSegments, List upYSegments) {
    double minDiff = 9999999999d; //original value used in Perl program to represent infinity
    double sumXDistance = 0d;
    for (int xSegmentIndex = 0; xSegmentIndex < upXSegments.size(); xSegmentIndex++) {
      sumXDistance += ((Segment)upXSegments.get(xSegmentIndex)).getDistance();
      double sumYDistance = 0d;
      for (int ySegmentIndex = 0; ySegmentIndex < upYSegments.size(); ySegmentIndex++) {
        sumYDistance += ((Segment)upYSegments.get(ySegmentIndex)).getDistance();
        double diff = Math.abs(sumXDistance - sumYDistance);
        if (minDiff > diff) {
          minDiff = diff;
        }
      }
    }
    return minDiff;
  }

  /**
   * Computes balance score if merge with segments from previous aligned block.
   * @param downXSegments           list of x axis segments from previous aligned block
   * @param downYSegments           list of y axis segments from previous aligned block
   * @return                        computed balance score
   */
  private double computeBalanceDown(List downXSegments, List downYSegments) {
    double minDiff = 9999999999d; //original value used in Perl program to represent infinity
    double sumXDistance = 0d;
    for (int xSegmentIndex = downXSegments.size() - 1; xSegmentIndex >= 0; xSegmentIndex--) {
      sumXDistance += ((Segment)downXSegments.get(xSegmentIndex)).getDistance();
      double sumYDistance = 0d;
      for (int ySegmentIndex = downYSegments.size() - 1; ySegmentIndex >= 0; ySegmentIndex--) {
        sumYDistance += ((Segment)downYSegments.get(ySegmentIndex)).getDistance();
        double diff = Math.abs(sumXDistance - sumYDistance);
        if (minDiff > diff) {
          minDiff = diff;
        }
      }
    }
    return minDiff;
  }

  /**
   * Merges with aligned block.
   * @param alignedBlock          aligned block to merge with
   */
  public void merge(AlignedBlock alignedBlock) {
    Iterator xSegmentIter = alignedBlock.getSegments(true, false).iterator();
    while (xSegmentIter.hasNext()) {
      addSegment((Segment)xSegmentIter.next(), true);
    }
    Iterator ySegmentIter = alignedBlock.getSegments(false, false).iterator();
    while (ySegmentIter.hasNext()) {
      addSegment((Segment)ySegmentIter.next(), false);
    }
  }

  /**
   * String representation of the aligned block.
   * @return                  string representation of the aligned block
   */
  public String toString() {
    StringBuffer stringBuffer = new StringBuffer();
    stringBuffer.append(segmentListToString(xAxisSegments));
    stringBuffer.append(" <=> ");
    stringBuffer.append(segmentListToString(yAxisSegments));
    return stringBuffer.toString();
  }

  /**
   * String representation of a list of segments.
   * @param segments                list of segments
   * @return                        string representation of a list of segments
   */
  private String segmentListToString(List segments) {
    if (segments.size() == 0) {
      return "omitted";
    } else {
      StringBuffer stringBuffer = new StringBuffer();
      boolean isFirst = true;
      Iterator segmentIterator = segments.iterator();
      while (segmentIterator.hasNext()) {
        if ( !isFirst ) {
          stringBuffer.append(",");
        } else {
          isFirst = false;
        }
        stringBuffer.append(segmentIterator.next().toString());
      }
      return stringBuffer.toString();
    }
  }
}
