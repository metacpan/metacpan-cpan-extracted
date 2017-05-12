package gma.gcalign;

/*Alignment Program for Parallel sequences

  GCalign.java, v 1.1 04/27/02 18:00:00
  by Jayasree Tangirala

  Based on the article by William A. Gale, Kenneth W. Church & Michael
  D.Riley: "A Program for Aligning Sentences in Bilingual Corpora".
  Computational Linguistics (journal), 1993.

*/


 import java.lang.*;
 import java.util.*;
 import java.io.*;


 public class GCalign{


 /* Global Definitions*/

 public static final int EXIT_ERROR_CODE = 1;      /* exit() code if error */
 public static final int MAX_LINE_LENGTH = 7;      /* for inputing lines directly
				 NOTE: delimiters also limited by this */

 static String program_name;
 static int verbose = 0;
 align_core align = new align_core();


  public List gcalign(String[] args)
     {

	 String soft_delimiter = null;
	 String sInput = null;
	 String stdout = null; strategy_delta DELTA1 = new strategy_delta();
	 strategy newstrategy = new strategy();
	 String input_file = null;int hsize = 0; int vsize = 0;
	 int item1 = 0, item2 = 0;
	 align_core align = new align_core();

	 step_table alignment = new step_table();
	 VAL_TABLE valtable1 = null, valtable2 = null;

	 /* Decode the program options.  */
	 if(args.length <= 1)
	     {
		 System.out.println("Usage:");
		 System.out.println(" c: java GCalign [-v] [-V] -d <delim-string> -i <input>");
                 System.exit(1);
	     }

	 program_name = args[0];

	 int iNextArg = 0;
	 while(args.length > iNextArg+1)
	     {
		 if(args[iNextArg].equals("-d"))
		     {
			 soft_delimiter = args[++iNextArg];
			 iNextArg++;
		     }
		 else
		     if(args[iNextArg].equals("-v") ||args[iNextArg].equals("-V"))
			 {
			     verbose = 1;
			     System.out.println("setting verbose");
			     iNextArg++;
			 }
		     else
			 if(args[iNextArg].equals("-i"))
			     {
				 sInput = args[++iNextArg];
				 iNextArg++;
			     }

	     }
	 if(verbose!=0)
	     System.out.println("Parced Input parameters: soft_delimeter="+soft_delimiter+
				"; sInput="+sInput );

    StringTokenizer st = new StringTokenizer(sInput, soft_delimiter);
    if(st.countTokens() !=2 )
	{
	System.out.println("Missing soft_delimiter: " + sInput);
	System.exit(EXIT_ERROR_CODE);
	}


    //create value table from the data before the delimiter
    if(st.hasMoreTokens())
	{
	    valtable1 = new VAL_TABLE(st.nextToken());
	    if(verbose!=0)
		{
		    System.out.println("table1:");
		    valtable1.print();
		}
	}

    //create value table from the data after the delimiter
    if(st.hasMoreTokens())
	{
	    valtable2 =  new VAL_TABLE(st.nextToken());
	}

    if(verbose!=0)
	{
	    System.out.println("table1:");
	    valtable1.print();
	    System.out.println("table2:");
	    valtable2.print();
	}



    /* the alignment process */
    alignment = align.align_values (valtable1, valtable2, newstrategy, item1, item2);

    List alignments = new ArrayList();

    for (int i = alignment.length - 1 ;i >= 0; i--){
	hsize = DELTA1.item1[alignment.STEP[i].sval];
	vsize = DELTA1.item2[alignment.STEP[i].sval];
        String alignmentString = new String("" + hsize + " <=> " + vsize);
        alignments.add(alignmentString);
    }

    return alignments;
  }

  public static void main(String[] args) {
    GCalign gcalign = new GCalign();
    List alignments = gcalign.gcalign(args);
    Iterator iter = alignments.iterator();
    while (iter.hasNext()) {
      String alignmentString = (String)iter.next();
      System.out.println(alignmentString);
    }

    System.exit(0);
 }//End of main


}/*End of GCalign.java*/
