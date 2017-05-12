package gma.simr;


/**
 * <p>Title: </p>
 * <p>Description: TestSearchRectangle tests SearchRectangle.</p>
 * <p>Copyright: Copyright (C) 2003 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 * @version 1.0
 */

import gma.AxisTick;
import gma.MapPoint;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.SortedSet;
import java.util.StringTokenizer;
import java.util.TreeSet;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

public class TestSearchRectangle extends TestCase {

    private PointDisplacementComparator pointDisplacementComparator = new PointDisplacementComparator();
    private SortedSet mapPoints = new TreeSet(pointDisplacementComparator);
    private Map xAxisAmbiguityCounter = new HashMap();
    private Map yAxisAmbiguityCounter = new HashMap();
    private Properties properties = new Properties();
    private SearchRectangle searchRectangle = null;
    private List resultMapPoints = new ArrayList(8);

    public TestSearchRectangle(String name) throws Exception {
      super(name);
    }

    protected void setUp() throws java.lang.Exception {
	
      String axisMappings = "322,324 -- 4920.5, 4404.5;" +
                            "318,324 -- 4849.5, 4404.5;" +
                            "309,324 -- 4763.5, 4404.5;" +
                            "313,328 -- 4812.5, 4464.5;" +
                            "322,340 -- 4920.5, 4626.5;" +
                            "302,326 -- 4683.5, 4440.5;" +
                            "311,334 -- 4785.5, 4549.5;" +
                            "312,335 -- 4804, 4568;" +
                            "313,336 -- 4812.5, 4576.5;" +
                            "314,337 -- 4815.5, 4579.5;" +
                            "318,340 -- 4849.5, 4626.5;" +
                            "302,331 -- 4683.5, 4486.5;" +
                            "316,342 -- 4830.5, 4644.5;" +
                            "317,343 -- 4841.5, 4655.5;" +
                            "309,340 -- 4763.5, 4626.5;";

      StringTokenizer st = new StringTokenizer(axisMappings, " ,-;\f\n");

      // the word 'word' as a list of bytes
      Integer[] wordlist = {(new Integer(101)),(new Integer(119)),(new Integer(114)),(new Integer(100))};
      ArrayList word = new ArrayList(Arrays.asList( wordlist ));

      while (st.hasMoreTokens()) {
        int xIndex = Integer.parseInt(st.nextToken());
        int yIndex = Integer.parseInt(st.nextToken());
        float xPosition = Float.parseFloat(st.nextToken());
        float yPosition = Float.parseFloat(st.nextToken());
        AxisTick xAxisTick = new AxisTick(xIndex, xPosition, word);
        AxisTick yAxisTick = new AxisTick(yIndex, yPosition, word);
        updateAmbiguityCounter(xAxisAmbiguityCounter, xAxisTick, true);
        updateAmbiguityCounter(yAxisAmbiguityCounter, yAxisTick, true);
        MapPoint mapPoint = new MapPoint(xAxisTick, yAxisTick);
        mapPoint.computeDisplacement(0.91f);
        mapPoints.add(mapPoint);
      }

      String results =  "4683.5, 4440.5;" +
                        "4785.5, 4549.5;" +
                        "4804, 4568;" +
                        "4812.5, 4576.5;" +
                        "4815.5, 4579.5;" +
                        "4830.5, 4644.5;" +
                        "4841.5, 4655.5;" +
                        "4849.5, 4626.5;";

      st = new StringTokenizer(results, " ,;\f\n");
      while (st.hasMoreTokens()) {
        float xPosition = Float.parseFloat(st.nextToken());
        float yPosition = Float.parseFloat(st.nextToken());

	

        AxisTick xAxisTick = new AxisTick(0, xPosition, word );
        AxisTick yAxisTick = new AxisTick(0, yPosition, word );
        MapPoint mapPoint = new MapPoint(xAxisTick, yAxisTick);
        mapPoint.computeDisplacement(0.91f);
        resultMapPoints.add(mapPoint);
      }

      properties.setProperty(SearchRectangle.MATCHING_PREDICATE, "gma.simr.LcsrMatching");
      properties.setProperty(MappingChain.SLOPE, "0.91");
      properties.setProperty(MappingChain.CHAIN_SIZE, "8");
      properties.setProperty(SearchRectangle.CHAIN_POINT_AMBIGUITY, "8");
      properties.setProperty(LcsrMatching.LCSR_THRESHOLD, "0.71");
      properties.setProperty(LcsrMatching.MINIMUM_WORD_LENGTH, "4");
      properties.setProperty(MappingChain.ANGLE_DEVIATION, "0.17");
      properties.setProperty(MappingChain.LINEAR_REGRESSION_ERROR, "21");
      searchRectangle = new SearchRectangle(properties);
	
    }

    protected void tearDown() throws java.lang.Exception {
        /**@todo: Override this junit.framework.TestCase method*/
        super.tearDown();
    }

    public void testFindBestChain() throws Exception {
      SortedSet noiselessMapPoints = removeNoise(mapPoints);
      List mappingChains = generateMappingChains(noiselessMapPoints);
      MappingChain bestChain = searchRectangle.findBestChain(mappingChains, noiselessMapPoints);
      boolean b = true;
      for (int index = 0; index < bestChain.getChainSize(); index++) {
        MapPoint mapPoint = bestChain.getMapPoint(index);
        Iterator iter = resultMapPoints.iterator();
        boolean bool = false;
        while (iter.hasNext()) {
          MapPoint result = (MapPoint)iter.next();
          if (result.equals(mapPoint)) {
            bool = true;
            break;
          }
        }
        if ( !bool ) {
          b = false;
          break;
        }
      }

      assertTrue(b);
    }

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

    private int getAmbiguityCounter(Map ambiguityCounter, AxisTick axisTick) {
      if (ambiguityCounter.containsKey(axisTick)) {
        return ((Integer)(ambiguityCounter.get(axisTick))).intValue();
      } else {
        return 0;
      }
    }

    private int getAmbiguityCounters(MapPoint mapPoint) {
      int counter = getAmbiguityCounter(xAxisAmbiguityCounter, mapPoint.getXAxisTick());
      counter += getAmbiguityCounter(yAxisAmbiguityCounter, mapPoint.getYAxisTick());
      return counter - 2;
    }

    private SortedSet removeNoise(Set noiseMapPoints) {
      SortedSet noiselessMapPoints = new TreeSet(pointDisplacementComparator);
      Iterator iterator = noiseMapPoints.iterator();
      while (iterator.hasNext()) {
        MapPoint mapPoint = (MapPoint)iterator.next();
        if (getAmbiguityCounters(mapPoint) <= 8) {
          noiselessMapPoints.add(mapPoint);
        }
      }

      return noiselessMapPoints;
    }

    private List generateMappingChains(Set noiselessMapPoints) {

      List mappingChains = new ArrayList();

      for (int outerIndex = 1; outerIndex <= noiselessMapPoints.size() - 8 + 1; outerIndex++) {
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
          if (innerIndex >= outerIndex + 8 - 1) {
            mappingChains.add(mappingChain);
            break;
          }
        }
      }

      return mappingChains;
    }

    public static void main(String[] args) {
        Test mySuite = new TestSuite(TestSearchRectangle.class);
        junit.textui.TestRunner.run(mySuite);
    }
}
