package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: MappingChain represents mapping chain in search rectangle.</p>
 * <p>Copyright: Copyright (C) 2003 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

import gma.MapPoint;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.SortedSet;
import java.util.TreeSet;

public class MappingChain implements Comparable {

  //constants in property file

  public static final String CHAIN_SIZE = "chainSize";
  public static final String SLOPE = "slope";
  public static final String ANGLE_DEVIATION = "angleDeviation";
  public static final String LINEAR_REGRESSION_ERROR = "linearRegressionError";

  private int defaultChainSize; //default chain size
  private double defaultSlope;   //default chain slope
  private float defaultAngleDeviation;  //default slope deviation
  private float defaultLinearRegressionError; //default regression error

  private Properties properties = null; //properties

  private List mapPoints = new ArrayList();   //list of map points in the mapping chain

  private boolean isAmbiguous = false;  //true if map points are in conflict

  private double slope = Double.NaN;    //mapping chain slope
  private double interception = Double.NaN; //mapping chain y axis interception
  private double sumSquareError = Double.NaN; //mapping chain sum squared error

  /**
   * Constructor.
   * @param properties            properties
   */
  public MappingChain(Properties properties) {
    this.properties = properties;
    defaultChainSize = Integer.parseInt(properties.getProperty(CHAIN_SIZE));
    defaultSlope = Double.parseDouble(properties.getProperty(SLOPE));
    defaultAngleDeviation = Float.parseFloat(properties.getProperty(ANGLE_DEVIATION));
    defaultLinearRegressionError = Float.parseFloat(properties.getProperty(LINEAR_REGRESSION_ERROR));
    defaultLinearRegressionError *= defaultLinearRegressionError;
    defaultLinearRegressionError *= defaultChainSize;
  }

  /**
   * Disambiguates mapping chain.
   * @return                        list of disambiguated mapping chain with less than default length
   */
  public List disambiguateChain() {

    List ambiguousMapPoints = groupAmbiguousMapPoints(mapPoints);
    return generateDisambiguatedMappingChains(ambiguousMapPoints);

  }

  /**
   * Groups conflictual map points.
   * @param mapPoints               list of conflictual map points
   * @return
   */
  private List groupAmbiguousMapPoints(List mapPoints) {

    List ambiguousMapPoints = new ArrayList();
    Hashtable xAxisIndexCounter = new Hashtable();
    Hashtable yAxisIndexCounter = new Hashtable();
    Hashtable xAmbiguousMapPointPointers = new Hashtable();
    Hashtable yAmbiguousMapPointPointers = new Hashtable();

    // first update the xAxisCounter and yAxisCounter Hashtables
    Iterator iterator = mapPoints.iterator();
    while (iterator.hasNext()) {
      MapPoint mapPoint = (MapPoint)iterator.next();
      Float xAxisIndex = new Float(mapPoint.getXAxisTick().getPosition());

      if (xAxisIndexCounter.containsKey(xAxisIndex)) {
        xAxisIndexCounter.put(xAxisIndex, new Integer(((Integer)xAxisIndexCounter.get(xAxisIndex)).intValue() + 1));
      } else {
        xAxisIndexCounter.put(xAxisIndex, new Integer(1));
      }
      Float yAxisIndex = new Float(mapPoint.getYAxisTick().getPosition());
      if (yAxisIndexCounter.containsKey(yAxisIndex)) {
        yAxisIndexCounter.put(yAxisIndex, new Integer(((Integer)yAxisIndexCounter.get(yAxisIndex)).intValue() + 1));
      } else {
        yAxisIndexCounter.put(yAxisIndex, new Integer(1));
      }
    }
    
    iterator = mapPoints.iterator();
    while (iterator.hasNext()) {
      MapPoint mapPoint = (MapPoint)iterator.next();

      Float xAxisIndex = new Float(mapPoint.getXAxisTick().getPosition());
      Float yAxisIndex = new Float(mapPoint.getYAxisTick().getPosition());

      if (((Integer)xAxisIndexCounter.get(xAxisIndex)).intValue() == 1 &&
      ((Integer)yAxisIndexCounter.get(yAxisIndex)).intValue() == 1) {
        List currentMapPoints = new ArrayList();
        currentMapPoints.add(mapPoint);
        ambiguousMapPoints.add(currentMapPoints);

      } else {
	  
        if (xAmbiguousMapPointPointers.containsKey(xAxisIndex) &&
            yAmbiguousMapPointPointers.containsKey(yAxisIndex)) {
	    //System.err.println("both have been seen");
	    // both the x and y values have been seen before
          Integer xAmbiguousMapPointPointer = (Integer)xAmbiguousMapPointPointers.get(xAxisIndex);
          Integer yAmbiguousMapPointPointer = (Integer)yAmbiguousMapPointPointers.get(yAxisIndex);
          if (xAmbiguousMapPointPointer.intValue() != yAmbiguousMapPointPointer.intValue()) {
            Iterator innerIterator = ((List)ambiguousMapPoints.get(xAmbiguousMapPointPointer.intValue())).iterator();
            while (innerIterator.hasNext()) {
              MapPoint ambiguousMapPoint = (MapPoint)innerIterator.next();
	      //System.err.println("ambig map point " + ambiguousMapPoint);
	      yAmbiguousMapPointPointers.put(new Float(ambiguousMapPoint.getYAxisTick().getPosition()), yAmbiguousMapPointPointers.get(yAxisIndex));
            }

            innerIterator = ((List)ambiguousMapPoints.get(xAmbiguousMapPointPointer.intValue())).iterator();
            while (innerIterator.hasNext()) {
              MapPoint currentMapPoint = (MapPoint)innerIterator.next();
              ((List)ambiguousMapPoints.get(yAmbiguousMapPointPointer.intValue())).add(currentMapPoint);
            }

            SortedSet sortedMapPoints = new TreeSet(new PointDisplacementComparator());
            Iterator iter = ((List)ambiguousMapPoints.get(yAmbiguousMapPointPointer.intValue())).iterator();
            while (iter.hasNext()) {
              sortedMapPoints.add(iter.next());
            }
            ambiguousMapPoints.remove(yAmbiguousMapPointPointer.intValue());
            ambiguousMapPoints.add(yAmbiguousMapPointPointer.intValue(), new ArrayList(sortedMapPoints));

            ((List)ambiguousMapPoints.get(xAmbiguousMapPointPointer.intValue())).clear();
            xAmbiguousMapPointPointers.put(xAxisIndex, yAmbiguousMapPointPointer);
          }

        } else if (yAmbiguousMapPointPointers.containsKey(yAxisIndex)) {
	    //System.err.println("just y has been seen yAxisIndex = " + yAxisIndex);
	    // just the y value has been seen before
          xAmbiguousMapPointPointers.put(xAxisIndex, yAmbiguousMapPointPointers.get(yAxisIndex));

	  //just the x value has been seen before
        } else if (xAmbiguousMapPointPointers.containsKey(xAxisIndex)) {
	    //System.err.println("just x has been seen  xAxisIndex = " + xAxisIndex);
          yAmbiguousMapPointPointers.put(yAxisIndex, xAmbiguousMapPointPointers.get(xAxisIndex));

        } else {
          //neither row nor col seen yet, create new hash key:value pair
	    ////System.err.println("neither has been seen");
          Integer index = new Integer(ambiguousMapPoints.size());
          xAmbiguousMapPointPointers.put(xAxisIndex, index);
          yAmbiguousMapPointPointers.put(yAxisIndex, index);
          ambiguousMapPoints.add(index.intValue(), new ArrayList());
        }

        ((List)ambiguousMapPoints.get(((Integer)xAmbiguousMapPointPointers.get(xAxisIndex)).intValue())).add(mapPoint);
      }
    }


    //remove empty list that were merged out
    Iterator iter = ambiguousMapPoints.iterator();
    while (iter.hasNext()) {
      int ambiguousMapPointSize = ((List)iter.next()).size();
      if (ambiguousMapPointSize == 0) {
        iter.remove();
      }
    }

    return ambiguousMapPoints;
  }

  /**
   * Generates disambiguated mapping chains with shorter than default length.
   * @param groupedAmbiguousMapPoints           list of grouped conflictual map points
   * @return                                    list of disambiguated mapping chains
   */
  private List generateDisambiguatedMappingChains(List groupedAmbiguousMapPoints) {

    List unambiguousMapPoints = new ArrayList();
    List ambiguousMapPoints = new ArrayList();
    Iterator splitIterator = groupedAmbiguousMapPoints.iterator();
    while (splitIterator.hasNext()) {
      List mapPoints = (List)splitIterator.next();
      if (mapPoints.size() == 1) {
        unambiguousMapPoints.add(mapPoints.get(0));
      } else {
        ambiguousMapPoints.add(mapPoints);
      }
    }

    List disambiguatedMappingChains = new ArrayList();
    int count = 1;

    Iterator outerIterator = ambiguousMapPoints.iterator();
    while (outerIterator.hasNext()) {

      Map ambiguousMappingChainMap = new HashMap();
      List ambiguousMapPointGroup = (List)outerIterator.next();
      List disambiguated = doDisambiguation(ambiguousMapPointGroup, ambiguousMappingChainMap);
      count = disambiguated.size() * count;
      disambiguatedMappingChains.add(disambiguated);
    }
    // count is the number of disambuguated chains that we will end up with
    List mappingChains = new ArrayList(count);
    for (int index = 0; index < count; index++) {
      MappingChain mappingChain = new MappingChain(properties);
      Iterator iter = unambiguousMapPoints.iterator();
      while (iter.hasNext()) {
        mappingChain.addMapPoint((MapPoint)iter.next(), true);
        //true to force addition, this is trivial because all points are unambiguous
      }
      mappingChains.add(mappingChain);
    }
    int[] sizes = new int[disambiguatedMappingChains.size()];
    int[] counters = new int[disambiguatedMappingChains.size()];
    for (int i = 0; i < counters.length; i++) {
      sizes[i] = ((List)disambiguatedMappingChains.get(i)).size();
      counters[i] = 0;
    }

    Iterator iterator = mappingChains.iterator();
    while (iterator.hasNext()) {
      MappingChain mappingChain = (MappingChain)iterator.next();
      int countersIndex = 0;
      Iterator middleIterator = disambiguatedMappingChains.iterator();

      // go through and add a single point from each set to this mappingChain
      while (middleIterator.hasNext()) {
        List middleAmbiguousMapPoints = (List)middleIterator.next();
        List innerAmbiguousMapPoints = (List)middleAmbiguousMapPoints.get(counters[countersIndex]);

	// col
        Iterator innerIterator = innerAmbiguousMapPoints.iterator();
        while (innerIterator.hasNext()) {
          mappingChain.addMapPoint((MapPoint)innerIterator.next(), true);
        }

	// have we gone through each set once?
        if (countersIndex == ambiguousMapPoints.size() - 1) {
          counters[countersIndex]++;
          int tempIndex = countersIndex;
          while (counters[tempIndex] >= sizes[tempIndex]) {
            counters[tempIndex--] = 0;
            if (tempIndex >= 0) {
              counters[tempIndex]++;
            } else {
              break;
            }
          }
        }
	// we have NOT gone through all the set elements, increase the countersIndex
        countersIndex++; //cptr
      }
    }

    return mappingChains;
  }

  /**
   * Does disambiguate map points.
   * @param ambiguousMapPointGroup        grouped conflictual map points
   * @param ambiguousMappingChainMap      map of ambiguous mapping chains
   * @return                              list of disambiguated mapping chains
   */
  private List doDisambiguation(List ambiguousMapPointGroup, Map ambiguousMappingChainMap) {
    List disambiguatedMappingChains = new LinkedList();

    if (ambiguousMapPointGroup.size() == 2) {
      MapPoint first = (MapPoint)ambiguousMapPointGroup.get(0);
      MapPoint second = (MapPoint)ambiguousMapPointGroup.get(1);
      if ( !first.getXAxisTick().equals(second.getXAxisTick()) &&
      !first.getYAxisTick().equals(second.getYAxisTick())) {
        disambiguatedMappingChains.add(ambiguousMapPointGroup);
      } else {
        Iterator innerIterator = ambiguousMapPointGroup.iterator();
        while (innerIterator.hasNext()) {
          List disambiguatedMapPointGroup = new ArrayList();
          disambiguatedMapPointGroup.add(innerIterator.next());
          disambiguatedMappingChains.add(disambiguatedMapPointGroup);
        }
      }
      return disambiguatedMappingChains;
    }

    String hashKey = "";
    boolean isFirst = true;
    Iterator hashKeyIterator = ambiguousMapPointGroup.iterator();
    while (hashKeyIterator.hasNext()) {
      if (isFirst) {
        isFirst = false;
      } else {
        hashKey += "#";
      }
      hashKey += ((MapPoint)hashKeyIterator.next()).toString();
    }
    if ( true ) { //!ambiguousMappingChainMap.containsKey(hashKey) ) {

      Iterator middleIterator = ambiguousMapPointGroup.iterator();
      while (middleIterator.hasNext()) {

        List disambiguatedMapPointGroup = new ArrayList();

        MapPoint middle = (MapPoint)middleIterator.next();
        MapPoint previous = middle;
	//System.err.println("middle " + middle);
        Iterator innerIterator = ambiguousMapPointGroup.iterator();
        while (innerIterator.hasNext()) {
          MapPoint inner = (MapPoint)innerIterator.next();
	  
	  //System.err.println("inner " + inner);
          if ( !middle.getXAxisTick().equals(inner.getXAxisTick()) &&
          !middle.getYAxisTick().equals(inner.getYAxisTick())) {
	      //System.err.println("add inner");
            disambiguatedMapPointGroup.add(inner);
            previous = inner;
          }
        }
	// i am not convienced that the following shortcut will work in all
	// cases and am commenting it out -Ali
	//************************************************************
        //if ( previous.getDisplacement() < middle.getDisplacement() ) {
	//    System.err.println("prev displace < middle displace");
        //  continue;
        //}
	//************************************************************
        if ( disambiguatedMapPointGroup.size() > 1 ) {
          List subset = doDisambiguation(disambiguatedMapPointGroup, ambiguousMappingChainMap);
          Iterator subsetIterator = subset.iterator();
          while (subsetIterator.hasNext()) {
            List mapPoints = (List)subsetIterator.next();
            MapPoint mapPoint = (MapPoint)mapPoints.get(0);
            if ( middle.getDisplacement() < mapPoint.getDisplacement() ) {
              mapPoints.add(0, middle);
              disambiguatedMappingChains.add(mapPoints);
            }
          }
        } else if ( disambiguatedMapPointGroup.size() == 1 ) {
          List mapPoints = new LinkedList();
          mapPoints.add(middle);
          mapPoints.add(previous);
          disambiguatedMappingChains.add(mapPoints);
        } else {  //dismabiguatedMapPointGroup.size() == 0
          List mapPoints = new LinkedList();
          mapPoints.add(middle);
          disambiguatedMappingChains.add(mapPoints);
        }
      } //end of for middle loop

      
      ambiguousMappingChainMap.put(hashKey, disambiguatedMappingChains);
      /** @todo skipped one line of implementation */
    }
    else {
	disambiguatedMappingChains = (List)ambiguousMappingChainMap.get(hashKey);
    }
    return disambiguatedMappingChains;
  }

  /**
   * Gets the size of mapping chain.
   * @return                      size of mapping chain
   */
  public int getChainSize() {
    return mapPoints.size();
  }

  /**
   * Adds map point to the mapping chain.
   * @param mapPoint              map point to be added
   * @forceOnAmbiguity            true if the map point needs to be added despite of ambiguity it causes
   * @return                      true if the mapping chain becomes ambiguous after addition of map point
   */
  public boolean addMapPoint(MapPoint mapPoint, boolean forceOnAmbiguity) {
    Iterator iterator = mapPoints.iterator();
    while (iterator.hasNext()) {
      if (mapPoint.isConflict((MapPoint)iterator.next())) {
        isAmbiguous = true;
        break;
      }
    }
    if (isAmbiguous && !forceOnAmbiguity) {
      isAmbiguous = false;  //reset to false because the ambiguous mapPoint is not added
      return false;
    } else {
      mapPoints.add(mapPoint);
      return true;
    }
  }

  /**
   * Checks if two mapping chains are in conflict.
   * @param compareMappingChain           mapping chain for comparison
   * @return                              true if two mapping chains are in conflict
   */
  public boolean isConflict(MappingChain compareMappingChain) {

    MappingChain lowerMappingChain = null;
    MappingChain upperMappingChain = null;
    if ( getEndMapPoint(true, true).isMaxMapPoint(compareMappingChain.getEndMapPoint(true, true), true) == -1 ) {
      lowerMappingChain = this;
      upperMappingChain = compareMappingChain;
    } else {
      lowerMappingChain = compareMappingChain;
      upperMappingChain = this;
    }
    
    //special case to determine whether there is conflict
    if ( lowerMappingChain.getEndMapPoint(true, false).isMaxMapPoint(upperMappingChain.getEndMapPoint(true, true), true) == -1
    && lowerMappingChain.getEndMapPoint(false, false).isMaxMapPoint(upperMappingChain.getEndMapPoint(false, true), false) != -1 ) {
      return true;
    }

    //mapPoints without disambiguation is originally sorted by displacement
    //now they should be sorted by axis position
    // Note that the y values may not be in order
    SortedSet lowerMapPoints = new TreeSet();
    SortedSet upperMapPoints = new TreeSet();
    
    int upperYMin = -1;
    int lowerYMax = -1;
    for (int i = 0; i < defaultChainSize; i++) {
      lowerMapPoints.add(lowerMappingChain.getMapPoint(i));
      upperMapPoints.add(upperMappingChain.getMapPoint(i));

      // retrieve the last upper Y axis position that was added
      float testYMin = ((MapPoint)upperMappingChain.getMapPoint(i)).getYAxisTick().getPosition();
      if ((upperYMin == -1) || (testYMin < ((MapPoint)upperMappingChain.getMapPoint(upperYMin)).getYAxisTick().getPosition() )) {
	  upperYMin = i;  //position of the real upperYMin
      }

    }

    boolean checkingConflict = false;
    
    Iterator lowerIterator = lowerMapPoints.iterator();
    Iterator upperIterator = upperMapPoints.iterator();
    while (lowerIterator.hasNext() && upperIterator.hasNext()) {
      MapPoint lowerMapPoint = (MapPoint)lowerIterator.next();
      MapPoint upperMapPoint = (MapPoint)upperIterator.next();
      
      

      // step through the lower map points untill we get to one that could possibly be contentuous
      while ( checkingConflict == false && 
	      lowerMapPoint.isMaxMapPoint(upperMapPoint, true) == -1 && // is lower.x in lower position than upper.x 
	      lowerMapPoint.isMaxMapPoint(upperMappingChain.getMapPoint(upperYMin), false) == -1) {  //is lower.y in lower position than REAL upperYMin
        if (lowerIterator.hasNext()) {
          lowerMapPoint = (MapPoint)lowerIterator.next();
          continue;
        } else {
          return false;
        }
      }
      
      checkingConflict = true;

      if ( lowerMapPoint.isMaxMapPoint(upperMapPoint, true) != 0 ||
	   lowerMapPoint.isMaxMapPoint(upperMapPoint, false) != 0 ) {
          return true;
      }
    } //end of outer while loop
    return false;

  }

  /**
   * Gets the end map point in the mapping chain.
   * @param xAxisCompare            true for x axis end map point
   * @param isMinIndex              true for minimum position map point
   * @return                        end map point
   */
  public MapPoint getEndMapPoint(boolean xAxisCompare, boolean isMinIndex) {
    Iterator iterator = mapPoints.iterator();
    MapPoint endMapPoint = (MapPoint)iterator.next();
    while (iterator.hasNext()) {
      MapPoint mapPoint = (MapPoint)iterator.next();
      if (isMinIndex && mapPoint.isMaxMapPoint(endMapPoint, xAxisCompare) == -1) {
        endMapPoint = mapPoint;
      } else if (!isMinIndex && endMapPoint.isMaxMapPoint(mapPoint, xAxisCompare) == -1) {
        endMapPoint = mapPoint;
      }
    }
    return endMapPoint;
  }


  /**
   * Checks whether mapping chain has multiple instances of the same point.
   * @return                        true if mapping chain is free of multiples
   */
  public boolean isLegalMappingChain() {
      
      for (int i = 0; i < defaultChainSize; i++) {

	  float XPos1 = ((MapPoint)mapPoints.get(i)).getXAxisTick().getPosition();
	  float YPos1 = ((MapPoint)mapPoints.get(i)).getYAxisTick().getPosition();

	  for (int j = i+1; j < defaultChainSize; j++) {
	      float XPos2 = ((MapPoint)mapPoints.get(j)).getXAxisTick().getPosition();
	      float YPos2 = ((MapPoint)mapPoints.get(j)).getYAxisTick().getPosition();
	      
	      // changed to  or by ali on 02/09.04
	      if ((XPos1 == XPos2) || (YPos1 == YPos2)) {
		  // a multiple point exists
		  return false;
	      }
	  } 
      }
      return true;
  }


  /**
   * Checks whether mapping chain meets thresholds.
   * @return                        true if mapping chain meets threshold
   */
  public boolean isQualifiedMappingChain() {
      // Is this a qualified mapping chain - ie. compute regression
    computeRegression();
    sumSquareError = computeSumSquareError();
    double slopeDeviation = Math.abs(Math.atan(slope) - Math.atan(defaultSlope));
    return (slopeDeviation <= defaultAngleDeviation &&
        sumSquareError <= defaultLinearRegressionError);
  }

  /**
   * Computes linear regression of mapping chain.
   */
  private void computeRegression() {

    double sumX = 0d;
    double sumY = 0d;
    double sumXY = 0d;
    double sumSquareX = 0d;

    Iterator iterator = mapPoints.iterator();
    while (iterator.hasNext()) {
      MapPoint mapPoint = (MapPoint)iterator.next();
      double x = mapPoint.getXAxisTick().getPosition();
      double y = mapPoint.getYAxisTick().getPosition();

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumSquareX += x * x;
    }

    double meanX = sumX / defaultChainSize;
    double meanY = sumY / defaultChainSize;

    double denominator = sumSquareX - defaultChainSize * meanX * meanX;

    if (denominator == 0) {
      slope = Float.MAX_VALUE;
      interception = Float.MAX_VALUE;
    } else {
      slope = (sumXY - defaultChainSize * meanX * meanY) / denominator;
      interception = meanY - slope * meanX;
    }
  }

  /**
   * Computes sum of squared error of mapping chain.
   * @return                        sum of squared error
   */
  private double computeSumSquareError() {
    double sumSquareDisplacement = 0d;

    if (slope == 0) {
      Iterator iterator = mapPoints.iterator();
      while (iterator.hasNext()) {
        MapPoint mapPoint = (MapPoint)iterator.next();
        double displacement = mapPoint.getYAxisTick().getPosition() - interception;
        sumSquareDisplacement = displacement * displacement;
      }

    } else {
      double ratio = Math.sin(Math.atan(slope));
      double squareRatio = ratio * ratio;
      Iterator iterator = mapPoints.iterator();
      while (iterator.hasNext()) {
        MapPoint mapPoint = (MapPoint)iterator.next();
        double xDisplacement = (mapPoint.getYAxisTick().getPosition() - interception)
                              / slope - mapPoint.getXAxisTick().getPosition();
        sumSquareDisplacement += (xDisplacement * xDisplacement) * squareRatio;
      }
    }
    sumSquareDisplacement = ((double)((float)sumSquareDisplacement));
    return sumSquareDisplacement;
  }

  /**
   * Gets sum of squared error of mapping chain.
   * @return                      sum of squared error
   */
  public double getSumSquareError() {
    if (sumSquareError == Double.NaN) {
      sumSquareError = computeSumSquareError();
    }
    return sumSquareError;
  }

  /**
   * Checks whether mapping chain is less displaced.
   * @param chain                   mapping chain for comparison
   * @return                        true if mapping chain is less displaced
   */
  public boolean isLessDisplaced(MappingChain chain) {
      //strictly less than ie keep first one
      double diff = chain.getSumSquareError() - sumSquareError;
      //System.err.println("diff = " + diff);
      if (Math.abs(diff) < 0.00000000000001) {
	  return true;
      }
    return sumSquareError < chain.getSumSquareError();
  }

  /**
   * Checks if mapping chain is ambiguous.
   * @return                        true if mapping chain is ambiguous
   */
  public boolean isAmbiguous() {
    return isAmbiguous;
  }

  /**
   * Gets indexed map point.
   * @param index                   index of map point
   * @return                        indexed map point
   */
  public MapPoint getMapPoint(int index) {
    /** @todo throw exception when index is out of range */
    return (MapPoint)(mapPoints.get(index));
  }

  /**
   * Clones a deep copy of mapping chain.
   * @return                    cloned mapping chain
   */
  public Object clone() {
    MappingChain mappingChain = new MappingChain(properties);
    Iterator iterator = mapPoints.iterator();
    while (iterator.hasNext()) {
      mappingChain.addMapPoint((MapPoint)iterator.next(), true);
    }
    return mappingChain;
  }

  /**
   * Checks the minimum position of two mapping chains on the x axis.
   * @param compareMappingChain           mapping chain for comparison
   * @return                              -1 if has lower minimum position on x axis
   *                                      0 if has same minimum position on x axis
   *                                      1 if has higher minimum position on x axis
   */
  public int compareTo(Object compareMappingChain) {
    // compare is based on xAxisTick and min index
    MapPoint mapPoint = getEndMapPoint(true, true);
    /** @todo check type before cast */
    MapPoint compareMapPoint = ((MappingChain)compareMappingChain).getEndMapPoint(true, true);
    return mapPoint.isMaxMapPoint(compareMapPoint, true);
  }

  /**
   * Checks if two mapping chains are the same.
   * @param compareMappingChain             mapping chain for comparison
   * @return                                true if same mapping chains
   */
  public boolean equals(Object compareMappingChain) {
    int index = 0;
    while (index < getChainSize()) {
      if (((MapPoint)mapPoints.get(index)).equals(((MappingChain)compareMappingChain).getMapPoint(index))) {
        index++;
      } else {
        return false;
      }
    }
    return true;
  }

  /**
   * String representation of mapping chain.
   * @return                        string representation of mapping chain
   */
  public String toString() {
    StringBuffer stringBuffer = new StringBuffer();
    Iterator iterator = mapPoints.iterator();
    while (iterator.hasNext()) {
      stringBuffer.append(((MapPoint)iterator.next()).toString() + "\n");
    }
    return stringBuffer.toString();
  }

  /**
   * Sort the mapping chain.
   * @return                        sorted of mapping chain
   */
  public List sort(MappingChain mapChain) {
      List sortedMC = new ArrayList();
      while (sortedMC.size() < mapChain.getChainSize()) {

	  // initialize to the highest xcord
	  float lowest = ((MapPoint)mapChain.getEndMapPoint(true,false)).getXAxisTick().getPosition();
	  MapPoint pointToAdd = (MapPoint)mapChain.getEndMapPoint(true,false);

	  // go through the mapChain
	  for (int mp = 0; mp < mapChain.getChainSize(); mp++) {

	      MapPoint point = (MapPoint)mapChain.getMapPoint(mp);
	      float xcord = point.getXAxisTick().getPosition();

	      // have we found an even lower x cordinate that is not a member of the final list?
	      if ((xcord < lowest) && (! sortedMC.contains(point))){
		  lowest = point.getXAxisTick().getPosition();
		  pointToAdd = point;
	      }
	  }
	  // found the next lowest point so add it
	  sortedMC.add(pointToAdd);
      }
      return sortedMC;
   }


}
