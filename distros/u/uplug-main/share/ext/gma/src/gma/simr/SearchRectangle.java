
package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: SearchRectangle represents search rectangle in search of mapping chain.</p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Ali Argyle
 */

import gma.AxisTick;
import gma.MapPoint;
import gma.util.ByteParser;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.SortedSet;
import java.util.TreeSet;


public class SearchRectangle {

  //constants in property file

  public static final String MATCHING_PREDICATE = "matchingPredicate";
  public static final String CHAIN_POINT_AMBIGUITY = "chainPointAmbiguity";
  public static final String SIMR = "simr";
  public boolean debug  = false; 

  private double defaultSlope;   //default rectangle slope
  private int defaultChainSize; //default chain size
  private int defaultChainPointAmbiguity; //default chain point ambiguity

  private List xAxisTicks = new ArrayList();  //list of x axis ticks
  private List yAxisTicks = new ArrayList();  //list of y axis ticks

  private PointDisplacementComparator pointDisplacementComparator = new PointDisplacementComparator();
  //comparator to sort map points according to point displacement
  private SortedSet mapPoints = new TreeSet(pointDisplacementComparator); //sorted set of map points
  private SortedSet noiselessMapPoints = new TreeSet(pointDisplacementComparator); //sorted set of noiseless map points

  private List mappingChains = null;  //list of mapping chains
  private MappingChain bestChain = null;  //best mapping chain

  private boolean hasNewPoint = false;  //true if new point is found

  private Map xAxisAmbiguityCounter = new HashMap();  //map of counters to record x axis ambiguity
  private Map yAxisAmbiguityCounter = new HashMap();  //map of counters to record y axis ambiguity

  private Properties properties = null; //properties
  private MatchingPredicate matching = null;  //matching predicate

  
  /**
   * Constructor.
   * @param properties                  properties
   */
  public SearchRectangle(Properties properties) {

    this.properties = properties;
    String matchingPredicate = properties.getProperty(MATCHING_PREDICATE);
    try {
      Class matchClass = Class.forName(matchingPredicate);
      Object matchingObject = matchClass.newInstance();
      matching = (MatchingPredicate)matchingObject;
      
      matching.setProperties(properties);

    } catch (ClassNotFoundException e) {
      e.printStackTrace();
      System.exit(1);

    } catch (IllegalAccessException e) {
      e.printStackTrace();
      System.exit(1);

    } catch (InstantiationException e) {
      e.printStackTrace();
      System.exit(1);
    }
    defaultSlope = Double.parseDouble(properties.getProperty(MappingChain.SLOPE));
    defaultChainSize = Integer.parseInt(properties.getProperty(MappingChain.CHAIN_SIZE));
    defaultChainPointAmbiguity = Integer.parseInt(properties.getProperty(CHAIN_POINT_AMBIGUITY));
  }


  /**
   * Expands axis of the search rectangle.
   * @param axisTick                  axis tick to be expanded to
   * @param isXAxis                   true for expansion on x axis
   */
  public void expandSearchRectangle(AxisTick axisTick, boolean isXAxis) {
    
    //flag for hasNewPoint is reset when x axis is expanded in the original Perl program
    //so in order to generate identical results, this flag is reset here
    if (isXAxis) {
      hasNewPoint = false;
    }
    
    // true if this is the XAxis 
    if (isXAxis) {
      xAxisTicks.add(axisTick);
      matchPoints(yAxisTicks, axisTick, false);

    } else {
      yAxisTicks.add(axisTick);
      matchPoints(xAxisTicks, axisTick, true);
    }

  }

  /**
   * Reduces search rectangle after a mapping chain is found.
   * @return                                reduced search rectangle
   */
  public SearchRectangle reduceSearchRectangle() {

    reduceAxisTicks(true); //true for xAxis
    reduceAxisTicks(false); //false for yAxis
    reduceMapPoints(); //this method also update xAxisAmbiguityCounter and yAxisAmbiguityCounter
    hasNewPoint = false;
    bestChain = null;
    mappingChains = null;
    noiselessMapPoints.clear();

    return this;
  }

  /**
   * Reduces axis ticks.
   * @param isXAxis                 true for reduction on x axis
   */
  private void reduceAxisTicks(boolean isXAxis) {
    if (isXAxis) {
      AxisTick minAxisTick = bestChain.getEndMapPoint(true, true).getXAxisTick();
      doReduceAxisTicks(xAxisTicks, minAxisTick);
    } else {
      AxisTick minAxisTick = bestChain.getEndMapPoint(false, true).getYAxisTick();
      doReduceAxisTicks(yAxisTicks, minAxisTick);
    }
  }

  /**
   * Does reduce axis ticks.
   * @param axisTicks                     list of axis ticks to be reduced
   * @param minAxisTick                   threshold for axis tick reduction
   */
  private void doReduceAxisTicks(List axisTicks, AxisTick minAxisTick) {
    Iterator iterator = axisTicks.iterator();
    while (iterator.hasNext()) {
      AxisTick axisTick = (AxisTick)iterator.next();
      if (axisTick.isMaxAxisTick(minAxisTick) != 1) {
        iterator.remove();
      } else {
        break;
      }
    }
  }

  /**
   * Reduces map points.
   */
  private void reduceMapPoints() {
    //this method has a lot of side effects: it also updates ambiguous counters
    AxisTick minXAxisTick = bestChain.getEndMapPoint(true, true).getXAxisTick();
    AxisTick minYAxisTick = bestChain.getEndMapPoint(false, true).getYAxisTick();
    Iterator iterator = mapPoints.iterator();
    while (iterator.hasNext()) {
      MapPoint mapPoint = (MapPoint)iterator.next();
      if (mapPoint.getXAxisTick().isMaxAxisTick(minXAxisTick) != 1 ||
            mapPoint.getYAxisTick().isMaxAxisTick(minYAxisTick) != 1) {
        iterator.remove();
        updateAmbiguityCounters(mapPoint, false);
      }
    }
  }


  /**
   * Gets the number of instances the axis tick has in the search rectangle.
   * @param isXAxis                       true if x axis boundary
   * @param axisTick                      axis tick to look for
   * @return                              number of instances
   */
   public int getNumInstances(boolean isXAxis, AxisTick axisTick) {
       int count = 0;
     if (isXAxis) {
	 Iterator xTicks = xAxisTicks.iterator();
	 while (xTicks.hasNext()) {
	     if (((AxisTick)xTicks.next()).equals(axisTick)) {
		 count = count +1;
	     }
	 }
     } else {
	 Iterator yTicks = yAxisTicks.iterator();
	 while (yTicks.hasNext()) {
	     if (((AxisTick)yTicks.next()).equals(axisTick)) {
		 count = count +1;
	     }
	 }
     }
     return count;
   }
  /**
   * Gets axis tick on the boundary of the search rectangle.
   * @param isXAxis                       true if x axis boundary
   * @param isMinimum                     true if lower boundary
   * @return                              axis tick on the coundary
   */
  public AxisTick getBoundaryAxisTick(boolean isXAxis, boolean isMinimum) {
    if (isXAxis) {
      if (isMinimum) {
        return (AxisTick)xAxisTicks.get(0);
      } else {
        return (AxisTick)xAxisTicks.get(xAxisTicks.size() - 1);
      }
    } else {
      if (isMinimum) {
        return (AxisTick)yAxisTicks.get(0);
      } else {
        return (AxisTick)yAxisTicks.get(yAxisTicks.size() - 1);
      }
    }
  }

  /**
   * Checks whether y axis can be expanded according to the default rectangle slope.
   * @return                        true if y axis can be expanded
   */
  public boolean canExpandYAxis() {
    double currentSlope = ((double)((AxisTick)yAxisTicks.get(yAxisTicks.size() - 1)).getPosition()
                          - (double)((AxisTick)yAxisTicks.get(0)).getPosition())
	/ ((double)((AxisTick)xAxisTicks.get(xAxisTicks.size() - 1)).getPosition()  - (double)((AxisTick)xAxisTicks.get(0)).getPosition());
    return currentSlope < defaultSlope;
  }


  /**
   * Matches points.
   * @param axisTicks                 list of axis ticks
   * @param axisTick                  axis tick
   * @param listIsXAxis               true if the list is for x axis ticks
   */
  private void matchPoints(List axisTicks, AxisTick axisTick, boolean listIsXAxis) {
      //  axisTick is the new element in the direction we are expanding
      //  it will be compared to all elements in axisTicks for matches
    Iterator iterator = axisTicks.iterator();
    
    while (iterator.hasNext()) {
	
      AxisTick tick = (AxisTick)iterator.next();
      //do these two words match?
      if (matching.isMatch(axisTick.getWord(), tick.getWord(), listIsXAxis)) {

	ByteParser bp1 = new ByteParser(axisTick.getWord());
	ByteParser bp2 = new ByteParser(tick.getWord());

        MapPoint mapPoint;
        if (listIsXAxis) {
          mapPoint = new MapPoint(tick, axisTick);
        } else {
	    mapPoint = new MapPoint(axisTick, tick);
        }
       
        mapPoint.computeDisplacement(defaultSlope);
	boolean dup = false;
	Iterator iteratorTmp = mapPoints.iterator();
	while (iteratorTmp.hasNext()) {
	    MapPoint mapPointTmp = (MapPoint)iteratorTmp.next();
	    if (mapPoint.getXAxisTick().equals(mapPointTmp.getXAxisTick()) &&
		mapPoint.getYAxisTick().equals(mapPointTmp.getYAxisTick())) {
		// this exact map point has already been added
		dup = true;
		break;
	    }
	}
	if (dup == false) {
	    mapPoints.add(mapPoint);
	    int ambiguityCounter = getAmbiguityCounters(mapPoint);
	    updateAmbiguityCounters(mapPoint, true);
	    if (ambiguityCounter <= defaultChainPointAmbiguity) {
		hasNewPoint = true;
	    }
	}
	
      }
    }
  }
		
		


  /**
   * Gets sum of ambiguity counters on both axis for a map point in the search rectangle.
   * @param mapPoint              map points
   * @return                      ambiguity counter
   */
  private int getAmbiguityCounters(MapPoint mapPoint) {
    int counter = getAmbiguityCounter(xAxisAmbiguityCounter, mapPoint.getXAxisTick());
    counter += getAmbiguityCounter(yAxisAmbiguityCounter, mapPoint.getYAxisTick());
    return counter - 2;
  }

  /**
   * Gets ambiguity counter on one axis for a map point in the search rectangle.
   * @param ambiguityCounter        map of ambiguity counters
   * @param axisTick                axis tick
   * @return                        ambiguity counter
   */
  private int getAmbiguityCounter(Map ambiguityCounter, AxisTick axisTick) {
    if (ambiguityCounter.containsKey(axisTick)) {
      return ((Integer)(ambiguityCounter.get(axisTick))).intValue();
    } else {
      return 0;
    }
  }

  /**
   * Updates ambiguity counters on both axes.
   * @param mapPoint                map points
   * @param isIncrement             true for counter increment
   */
  private void updateAmbiguityCounters(MapPoint mapPoint, boolean isIncrement) {
    updateAmbiguityCounter(xAxisAmbiguityCounter, mapPoint.getXAxisTick(), isIncrement);
    updateAmbiguityCounter(yAxisAmbiguityCounter, mapPoint.getYAxisTick(), isIncrement);
  }

  /**
   * Updates ambiguity counter on one axis.
   * @param ambiguityCounter          map of ambiguity counter
   * @param axisTick                  axis tick
   * @param isIncrement               true for counter increment
   */
  private void updateAmbiguityCounter(Map ambiguityCounter, AxisTick axisTick, boolean isIncrement) {
    int counter = getAmbiguityCounter(ambiguityCounter, axisTick);
    if (isIncrement) {
      counter++;
      ambiguityCounter.put(axisTick, new Integer(counter));
    } else {
      if (counter > 0) {
        counter--;
        ambiguityCounter.put(axisTick, new Integer(counter));
      }
    }
  }

  /**
   * Checks whether there is new map point.
   * @return                    true for new map point
   */
  public boolean hasNewPoint() {
    if (hasNewPoint) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * Checks whether there is mapping chain.
   * @return                    true for having mapping chain
   */
  public boolean hasMappingChain() {

    if (xAxisAmbiguityCounter.size() < defaultChainSize ||
          yAxisAmbiguityCounter.size() < defaultChainSize) {
      return false;
    }

    noiselessMapPoints = removeNoise(mapPoints);
    mappingChains = generateMappingChains(noiselessMapPoints);
    bestChain = findBestChain(mappingChains, noiselessMapPoints);

    if (bestChain != null) {
	if (debug) {
	    System.err.println("bestChain was not null = hasMappingChain");
	    System.err.println(noiselessMapPoints);
	    System.err.println(bestChain);
	} // debug
      return true;
    } else {
      return false;
    }
  }

  /**
   * Removes noise map points.
   * @param noiseMapPoints                  set of map points with noise
   * @return                                set of map points without noise
   */
  private SortedSet removeNoise(Set noiseMapPoints) {
    SortedSet noiselessMapPoints = new TreeSet(pointDisplacementComparator);
    Iterator iterator = noiseMapPoints.iterator();
    
    while (iterator.hasNext()) {
      MapPoint mapPoint = (MapPoint)iterator.next();
      if (getAmbiguityCounters(mapPoint) <= defaultChainPointAmbiguity) {
	  
	  //noiselessMapPoints.add(mapPoint);

	  boolean match = false;
	  Iterator silentIterator = noiselessMapPoints.iterator();
	  while (silentIterator.hasNext()) {
	      MapPoint silentMapPoint = (MapPoint)silentIterator.next();
	      //check to see if this point already exists in the set
	      if (silentMapPoint.equals(mapPoint)) {
		  match = true;
		  //break;
	      }
	      
	  } // end while	
	  if (match == false) {
	      noiselessMapPoints.add(mapPoint);
	  }
	  
      } 
    }
    return noiselessMapPoints;

  }

  /**
   * Generates mapping chains from noiseless map points.
   * @param noiselessMapPoints              map points without noise
   * @return                                list of mapping chains
   */
  private List generateMappingChains(Set noiselessMapPoints) {

    List mappingChains = new ArrayList();

    for (int outerIndex = 1; outerIndex <= noiselessMapPoints.size() - defaultChainSize + 1; outerIndex++) {
      Iterator iterator = noiselessMapPoints.iterator();
      int innerIndex = 0;
      MappingChain mappingChain = new MappingChain(properties);

      while (iterator.hasNext()) {
        innerIndex++;
        if (innerIndex < outerIndex) {
          iterator.next();
        } else {
	    mappingChain.addMapPoint((MapPoint)iterator.next(), true);
	    //true to force addition when the mapPoint incurs ambiguity
        }
        if (innerIndex >= outerIndex + defaultChainSize - 1) {
          mappingChains.add(mappingChain);
          break;
        }
      }
    }
    
    return mappingChains;
  }

  /**
   * Finds best mapping chain.
   * @param mappingChains                 list of mapping chains
   * @param noiselessMapPoints            sorted set of noiseless map points
   * @return                              best mapping chain
   */
  public MappingChain findBestChain(List mappingChains, SortedSet noiselessMapPoints) {
    while (mappingChains.size() > 0) {
      Iterator iterator = mappingChains.iterator();
      MappingChain leastDisplacedChain = null;

      while (iterator.hasNext()) {
        MappingChain mappingChain = (MappingChain)iterator.next();
	// check the regression (sum squared error)
	if (!mappingChain.isQualifiedMappingChain()) {
          iterator.remove();
        } else if (leastDisplacedChain == null) {
	    leastDisplacedChain = mappingChain;
        } else {
          if (!leastDisplacedChain.isLessDisplaced(mappingChain)) {
	      leastDisplacedChain = mappingChain;
          }
        }
      }
      if (leastDisplacedChain != null) {
        boolean result = mappingChains.remove(leastDisplacedChain);
	// check for legal mappingChain added by Ali on 02/05/04
        if ((!leastDisplacedChain.isAmbiguous())  &&  (leastDisplacedChain.isLegalMappingChain())) {
          return leastDisplacedChain;
        } else {
          List newMappingChains = disambiguateChain(leastDisplacedChain, noiselessMapPoints);
          if (newMappingChains.size() != 0) {
            mappingChains.addAll(newMappingChains);
          }
        }
      } else {

        //if no leastDisplacedChain
        break;
      }
    }

    //we are here when no leastDisplacedChain so that bestChains is empty
    return null;
  }

  /**
   * Disambiguates mapping chain by pulling map points around it.
   * @param ambiguousChain            ambiguous mapping chain
   * @param noiselessMapPoints        noiseless map points
   * @return
   */
  private List disambiguateChain(MappingChain ambiguousChain, SortedSet noiselessMapPoints) {

    ArrayList noiselessArray = new ArrayList();
    Iterator pts = noiselessMapPoints.iterator();
    while (pts.hasNext()) {
	noiselessArray.add(pts.next());	
    }

    MapPoint toMapPoint = ambiguousChain.getMapPoint(0);
    int indexTo = noiselessArray.indexOf(toMapPoint);
    List headList = noiselessArray.subList(0,indexTo + 1);
    Object[] headPoints = headList.toArray();
    

    MapPoint fromMapPoint = ambiguousChain.getMapPoint(ambiguousChain.getChainSize() - 1);
    int indexFrom = noiselessArray.indexOf(fromMapPoint);
    List tailList = new ArrayList();
    if (indexFrom < (noiselessArray.size() -1)) {
	tailList = noiselessArray.subList(indexFrom+1,noiselessArray.size() -1);
	tailList.add(noiselessArray.get(noiselessArray.size() -1));
	Object[] tailPoints = tailList.toArray();
    }
    Object[] tailPoints = tailList.toArray();

    List mappingChains = new ArrayList();
    List disambiguatedChains = ambiguousChain.disambiguateChain();
    Iterator iterator = disambiguatedChains.iterator();

    while (iterator.hasNext()) {
      MappingChain disambiguatedChain = (MappingChain)iterator.next();
      int pointsNeeded = defaultChainSize - disambiguatedChain.getChainSize();
      //headPoints.length - 1 + tailPoints.length because the toMapPoint is inclusive instead of being exclusive
      if ((headPoints.length - 1 + tailPoints.length) < pointsNeeded) {
        continue;
      }

      //headPoints.length - 2 because the toMapPoint is inclusive instead of being exclusive
      int headMaxIndex = headPoints.length - 2;
      int loopIndex = pointsNeeded < headMaxIndex + 1 ? pointsNeeded : headMaxIndex + 1;

      for (; loopIndex >= 0
      && pointsNeeded - loopIndex - 1 <= tailPoints.length; loopIndex--) {

        int needed = pointsNeeded;
        int lowNeeded = loopIndex;
        MappingChain chain = (MappingChain)(disambiguatedChain.clone());

        for (int headIndex = headMaxIndex; headIndex >= 0; headIndex--) {
          if (lowNeeded == 0) {
            break;
          }
          if (chain.addMapPoint((MapPoint)headPoints[headIndex], false)) {
            //false so that mapPoint that incurs ambiguity is not forced to add to mappingChain
            needed--;
            lowNeeded--;
          }
        }

        for (int tailIndex = 0; tailIndex < tailPoints.length; tailIndex++) {
          if (needed == 0) {
            break;
          }
          if (chain.addMapPoint((MapPoint)tailPoints[tailIndex], false)) {
            //false so that mapPoint that incurs ambiguity is not forced to add to mappingChain
            needed--;
          }
        }
        if ((chain.getChainSize() == defaultChainSize && chain.isQualifiedMappingChain()) && chain.isLegalMappingChain()) {
          mappingChains.add(chain);
        }
      } //end of middle for loop
    } //end of outer while loop

    return mappingChains;
  }

  /**
   * Gets best mapping chain.
   * @return                            best mapping chain
   */
  public MappingChain getBestChain() {
    return bestChain;
  }
}
