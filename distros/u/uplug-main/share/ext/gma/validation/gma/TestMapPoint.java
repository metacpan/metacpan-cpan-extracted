package gma;

/**
 * <p>Title: </p>
 * <p>Description: TestMapPoint tests MapPoint.</p>
 * <p>Copyright: Copyright (C) 2003 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 * @version 1.0
 */

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;

public class TestMapPoint extends TestCase {

    private MapPoint mapPoint = null;

    public TestMapPoint(String name) throws Exception {
      super(name);
    }

    protected void setUp() throws java.lang.Exception {
      super.setUp();
      //AxisTick xAxisTick = new AxisTick(5, 8.9999f, "ecouter");
      Integer[] enclist = {(new Integer(101)),(new Integer(99)),(new Integer(111)),(new Integer(117)),(new Integer(116)),(new Integer(101)),(new Integer(114))};
      ArrayList encounter = new ArrayList(Arrays.asList( enclist ));

      Integer[] lislist = {(new Integer(108)),(new Integer(105)),(new Integer(115)),(new Integer(116)),(new Integer(101)),(new Integer(110))};
      ArrayList listen = new ArrayList(Arrays.asList( lislist ));
      AxisTick xAxisTick = new AxisTick(5, 8.9999f, encounter );
      AxisTick yAxisTick = new AxisTick(3, 8.9999f, listen );
      mapPoint = new MapPoint(xAxisTick, yAxisTick);
    }

    protected void tearDown() throws java.lang.Exception {
        /**@todo: Override this junit.framework.TestCase method*/
        super.tearDown();
    }

    public void testGetDisplacement() throws Exception {
        mapPoint.computeDisplacement(1f);
        assertTrue(mapPoint.getDisplacement() == 0f);

        mapPoint.computeDisplacement(0.5f);
        assertTrue(!(mapPoint.getDisplacement() == 0f));
    }

    public static void main(String[] args) {
        Test mySuite = new TestSuite(TestMapPoint.class);
        junit.textui.TestRunner.run(mySuite);
    }
}
