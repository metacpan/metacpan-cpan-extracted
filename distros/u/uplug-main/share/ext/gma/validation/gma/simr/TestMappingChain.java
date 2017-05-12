package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: TestMappingChain tests MappingChain.</p>
 * <p>Copyright: Copyright (C) 2003 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 * @version 1.0
 */

import gma.AxisTick;
import gma.MapPoint;

import java.util.Iterator;
import java.util.List;
import java.util.Properties;
import java.util.StringTokenizer;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

public class TestMappingChain extends TestCase {

    private MappingChain mappingChain = null;
    private Properties properties = new Properties();

    public TestMappingChain(String name) throws Exception {
      super(name);
    }

    protected void setUp() throws java.lang.Exception {
      super.setUp();
      properties.put(MappingChain.ANGLE_DEVIATION, "0.17");
      properties.put(MappingChain.CHAIN_SIZE, "8");
      properties.put(MappingChain.LINEAR_REGRESSION_ERROR, "21");
      properties.put(MappingChain.SLOPE, "0.91");
      mappingChain = new MappingChain(properties);
    }

    protected void tearDown() throws java.lang.Exception {
        /**@todo: Override this junit.framework.TestCase method*/
        super.tearDown();
    }

    public void testDisambiguateChain() throws Exception {

      final float slope = 0.91f;
      /*
      AxisTick xAxisTick = new AxisTick(100, 1553.5f, "zero");
      AxisTick yAxisTick = new AxisTick(113, 1572.5f, "zero");
      MapPoint mapPoint = new MapPoint(xAxisTick, yAxisTick);
      mapPoint.computeDisplacement(slope);
      mappingChain.addMapPoint(mapPoint, true);

      xAxisTick = new AxisTick(98, 1543.5f, "un");
      yAxisTick = new AxisTick(112, 1569.5f, "one");
      mapPoint = new MapPoint(xAxisTick, yAxisTick);
      mapPoint.computeDisplacement(slope);
      mappingChain.addMapPoint(mapPoint, true);

      xAxisTick = new AxisTick(119, 1877.5f, "doux");
      yAxisTick = new AxisTick(134, 1873.5f, "three");
      mapPoint = new MapPoint(xAxisTick, yAxisTick);
      mapPoint.computeDisplacement(slope);
      mappingChain.addMapPoint(mapPoint, true);

      xAxisTick = new AxisTick(117, 1833.5f, "un");
      yAxisTick = new AxisTick(133, 1839.5f, "three");
      mapPoint = new MapPoint(xAxisTick, yAxisTick);
      mapPoint.computeDisplacement(slope);
      mappingChain.addMapPoint(mapPoint, true);

      xAxisTick = new AxisTick(110, 1732.5f, "un");
      yAxisTick = new AxisTick(125, 1775.5f, "three");
      mapPoint = new MapPoint(xAxisTick, yAxisTick);
      mapPoint.computeDisplacement(slope);
      mappingChain.addMapPoint(mapPoint, true);

      xAxisTick = new AxisTick(111, 1735.5f, "un");
      yAxisTick = new AxisTick(126, 1778.5f, "three");
      mapPoint = new MapPoint(xAxisTick, yAxisTick);
      mapPoint.computeDisplacement(slope);
      mappingChain.addMapPoint(mapPoint, true);

      xAxisTick = new AxisTick(117, 1833.5f, "un");
      yAxisTick = new AxisTick(134, 1873.5f, "three");
      mapPoint = new MapPoint(xAxisTick, yAxisTick);
      mapPoint.computeDisplacement(slope);
      mappingChain.addMapPoint(mapPoint, true);

      xAxisTick = new AxisTick(105, 1617.5f, "un");
      yAxisTick = new AxisTick(120, 1684.5f, "three");
      mapPoint = new MapPoint(xAxisTick, yAxisTick);
      mapPoint.computeDisplacement(slope);
      mappingChain.addMapPoint(mapPoint, true);

      boolean testResult = true;

      List disambiguatedMappingChains = mappingChain.disambiguateChain();

      //this is not a thorough check
      //it only checks whether there are 4 returned disambiguated mappingChains
      //and each disambiguated mappingChains has size 5
      if (disambiguatedMappingChains.size() != 2) {
        testResult = false;

      } else {

        Iterator iterator = disambiguatedMappingChains.iterator();
        while (iterator.hasNext()) {
          MappingChain disambiguatedMappingChain = (MappingChain)iterator.next();
          int chainSize = disambiguatedMappingChain.getChainSize();

          if (chainSize != 6 && chainSize != 7) {
            testResult = false;
          }
        }
      }

      assertTrue(testResult);
      */
    }

    public void testIsConflict() throws Exception {
	/*
      String from =
                    "6208.5 5645.5;" +
                    "6121.5 5571.5;" +
                    "6198.5 5642.5;" +
                    "6078.5 5536.5;" +
                    "6163.0 5616.0;" +
                    "6093.0 5563.0;" +
                    "6111.5 5581.0;" +
                    "6070.0 5545.5;";

      MappingChain compareFrom = new MappingChain(properties);
      StringTokenizer st = new StringTokenizer(from, " ,;\f\n");
      while (st.hasMoreTokens()) {
        float xPosition = Float.parseFloat(st.nextToken());
        float yPosition = Float.parseFloat(st.nextToken());
        AxisTick xAxisTick = new AxisTick(0, xPosition, "word");
        AxisTick yAxisTick = new AxisTick(0, yPosition, "word");
        MapPoint mapPoint = new MapPoint(xAxisTick, yAxisTick);
        compareFrom.addMapPoint(mapPoint, true);
      }

      String to =
                "5943.0 5419.0;" +
                "5909.5 5389.5;" +
                "5992.5 5465.5;" +
                "5995.5 5468.5;" +
                "6015.0 5495.0;" +
                "6023.5 5503.5;" +
                "6032.0 5512.0;" +
                "6040.5 5536.5;";

      MappingChain compareTo = new MappingChain(properties);
      st = new StringTokenizer(to, " ,;\f\n");
      while (st.hasMoreTokens()) {
        float xPosition = Float.parseFloat(st.nextToken());
        float yPosition = Float.parseFloat(st.nextToken());
        AxisTick xAxisTick = new AxisTick(0, xPosition, "word");
        AxisTick yAxisTick = new AxisTick(0, yPosition, "word");
        MapPoint mapPoint = new MapPoint(xAxisTick, yAxisTick);
        compareTo.addMapPoint(mapPoint, true);
      }

      assertTrue(compareFrom.isConflict(compareTo));
	*/
    }

    public static void main(String[] args) {
        Test mySuite = new TestSuite(TestMappingChain.class);
        junit.textui.TestRunner.run(mySuite);
    }
}
