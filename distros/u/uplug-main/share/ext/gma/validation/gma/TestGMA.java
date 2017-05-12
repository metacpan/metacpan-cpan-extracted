package gma;

/**
 * <p>Title: </p>
 * <p>Description: TestGMA tests GMA.</p>
 * <p>Copyright: Copyright (C) 2003 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 * @version 1.0
 */

import java.text.*;
import gma.gsa.GSA;
import gma.simr.SIMR;
import gma.util.InputFileHandler;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

public class TestGMA extends TestCase {

  public TestGMA(String s) {
    super(s);
  }

  protected void setUp() {
  }

  protected void tearDown() {
  }

  public void testExecute() {
      // first do a French English test
      String[] args = new String[6];
      args[0] = SIMR.DASH + SIMR.PROPERTIES;
      args[1] = "./validation/GMA.config.F.E";
      args[2] = SIMR.DASH + SIMR.X_AXIS_FILE;
      args[3] = "./validation/french-test1.axis";
      args[4] = SIMR.DASH + SIMR.Y_AXIS_FILE;
      args[5] = "./validation/english-test1.axis";
      
      GMA gma = new GMA(args);
      gma.execute();

      //this is not a thorough test
      InputFileHandler input = new InputFileHandler("./validation/temp/gsaOutput.txt");
      int counter = 0;
      while (input.hasLine()) {
        input.nextLine();
        counter++;
      }
      assertTrue(counter == 249);

      // first do a French English test
      String[] args2 = new String[6];
      args2[0] = SIMR.DASH + SIMR.PROPERTIES;
      args2[1] = "./validation/GMA.config.M.E";
      args2[2] = SIMR.DASH + SIMR.X_AXIS_FILE;
      args2[3] = "./validation/malay-test2.axis";
      args2[4] = SIMR.DASH + SIMR.Y_AXIS_FILE;
      args2[5] = "./validation/english-test2.axis";

      GMA gma2 = new GMA(args2);
      gma2.execute();

      //this is not a thorough test
      InputFileHandler input2 = new InputFileHandler("./validation/temp/gsaOutputM.txt");
      int counter2 = 0;
      while (input2.hasLine()) {
        input2.nextLine();
        counter2++;
      }
      assertTrue(counter2 == 730);

  }

    public static void main(String[] args) {
        Test mySuite = new TestSuite(TestGMA.class);
        junit.textui.TestRunner.run(mySuite);
    }
}
