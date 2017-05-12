package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: TestLcsrMatching tests LcsrMatching.</p>
 * <p>Copyright: Copyright (C) 2003 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 * @version 1.0
 */

import gma.util.StringUtil;
import java.util.ArrayList;

import java.util.Properties;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

public class TestLcsrMatching extends TestCase {

    private LcsrMatching matching = null;

    public TestLcsrMatching(String name) throws Exception {
      super(name);
    }

    protected void setUp() throws java.lang.Exception {
      super.setUp();
      Properties properties = new Properties();
      properties.put(LcsrMatching.LCSR_THRESHOLD, "0.71");
      properties.put(LcsrMatching.MINIMUM_WORD_LENGTH, "4");
      matching = new LcsrMatching();
      matching.setProperties(properties);
    }

    protected void tearDown() throws java.lang.Exception {
        /**@todo: Override this junit.framework.TestCase method*/
        super.tearDown();
    }

    public void testComputeLcs() throws Exception {
        String wordForMatch = "olivier";
        String wordToMatch = "olive";
        Byte nextItem;
        ArrayList listForMatch = new ArrayList();
        ArrayList listToMatch = new ArrayList();
        for (int i=0; i<wordForMatch.length() ; i++){
			nextItem = new Byte((byte)wordForMatch.charAt(i));
			listForMatch.add(nextItem);
		}
		for (int i=0; i<wordToMatch.length() ; i++){
					nextItem = new Byte((byte)wordToMatch.charAt(i));
					listToMatch.add(nextItem);
		}
        int lcsLength = matching.computeLcs(listForMatch, listToMatch);
        assertEquals(lcsLength, 5);
    }

    public void testIsMatch() throws Exception {
		ArrayList listForMatch = new ArrayList();
        ArrayList listToMatch = new ArrayList();
        Byte nextItem;
        String wordForMatch = StringUtil.norm("prophètes");
        String wordToMatch = StringUtil.norm("prophets");
        for (int i=0; i<wordForMatch.length() ; i++){
	        nextItem = new Byte((byte)wordForMatch.charAt(i));
		    listForMatch.add(nextItem);
		}
		for (int i=0; i<wordToMatch.length() ; i++){
			nextItem = new Byte((byte)wordToMatch.charAt(i));
			listToMatch.add(nextItem);
		}
        boolean result = matching.isMatch(listForMatch, listToMatch, true);
        assertEquals(result, true);

        wordForMatch = StringUtil.norm("Théman");
        wordToMatch = StringUtil.norm("Teman");
        listForMatch = new ArrayList();
        listToMatch = new ArrayList();
        for (int i=0; i<wordForMatch.length() ; i++){
			nextItem = new Byte((byte)wordForMatch.charAt(i));
			listForMatch.add(nextItem);
		}
		for (int i=0; i<wordToMatch.length() ; i++){
			nextItem = new Byte((byte)wordToMatch.charAt(i));
			listToMatch.add(nextItem);
		}
        result = matching.isMatch(listForMatch, listToMatch, true);
        assertEquals(result, true);

        // This test should return false because the ratio is too low
        wordForMatch = StringUtil.norm("Nonsense");
        wordToMatch = StringUtil.norm("Noise");
        listForMatch = new ArrayList();
        listToMatch = new ArrayList();
        for (int i=0; i<wordForMatch.length() ; i++){
			nextItem = new Byte((byte)wordForMatch.charAt(i));
			listForMatch.add(nextItem);
		}
		for (int i=0; i<wordToMatch.length() ; i++){
			nextItem = new Byte((byte)wordToMatch.charAt(i));
			listToMatch.add(nextItem);
		}
        result = matching.isMatch(listForMatch, listToMatch, true);
        assertEquals(result, false);
    }

    public static void main(String[] args) {
        Test mySuite = new TestSuite(TestLcsrMatching.class);
        junit.textui.TestRunner.run(mySuite);
    }
}
