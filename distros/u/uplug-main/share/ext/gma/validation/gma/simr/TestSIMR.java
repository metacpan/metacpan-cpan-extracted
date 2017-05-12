package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: TestSIMR tests SIMR.</p>
 * <p>Copyright: Copyright (C) 2003 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 * @version 1.0
 */

import java.util.SortedSet;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

public class TestSIMR extends TestCase {

    public TestSIMR(String name) throws Exception {
      super(name);
    }

    protected void setUp() throws java.lang.Exception {
      super.setUp();
    }

    protected void tearDown() throws java.lang.Exception {
        /**@todo: Override this junit.framework.TestCase method*/
        super.tearDown();
    }

    public void testGenerateBitextCorrespondence() throws Exception {

      String[] args = new String[6];
      args[0] = SIMR.DASH + SIMR.PROPERTIES;
      args[1] = "./validation/GMA.config.F.E";
      args[2] = SIMR.DASH + SIMR.X_AXIS_FILE;
      args[3] = "./validation/french-test1.axis";
      args[4] = SIMR.DASH + SIMR.Y_AXIS_FILE;
      args[5] = "./validation/english-test1.axis";

      SIMR simr = new SIMR(args);
      SortedSet mapPoints = simr.generateBitextCorrespondence();
      //this is not a thorough test
      assertTrue(mapPoints.size() == 1350);
      assertTrue(mapPoints.first().toString().equals("0.0 0.0"));
      assertTrue(mapPoints.last().toString().equals("66081.5 60603.5"));
    }

    public static void main(String[] args) {
        Test mySuite = new TestSuite(TestSIMR.class);
        junit.textui.TestRunner.run(mySuite);
    }
}
