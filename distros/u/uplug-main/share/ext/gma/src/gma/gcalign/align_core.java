package gma.gcalign;

public class align_core{

/*Global Constants*/


	           public static final int NUMBER_OF_STRATEGIES = 6;
	           int verbose;
	           public static final int MEAN_RATIO = 1;
	           public static final double VARIANCE_RATIO = 6.8;
			   public static final int PENALTY_01 = 450;		/* ... when X = [prob of 0-1 match] */
			   public static final int PENALTY_21 = 230;		/* ... when X = [prob of 2-1 match] */
			   public static final int PENALTY_22 = 440;		/* ... when X = [prob of 2-2 match] */
	           public static final int BIG_DISTANCE = 2500;	/* high value for a distance */

           /* Sequence of Strings */

		   strategy_delta DELTA;
//		   Sdelta DELTA;                 /*This class seems to be redundant*/


//constructor
public align_core(){
    DELTA = new strategy_delta();

}


//Methods

/* Returns the normal cdf.  Only works for positive values. */
/* a la Gradsteyn & Rhysiz, 26.2.17, p. 932. */

public double normal_cdf (double z_score)
{
  double t, pd, temp = 0.00;

  t = 1 / (1 + 0.2316419 * z_score);
  temp = (double)((-z_score*z_score) / 2);
  pd = 1 - (0.3989423 * java.lang.Math.exp(temp)
	    * ((((1.330274429 * t - 1.821255978) * t
		 + 1.781477937) * t - 0.356563782) * t + 0.319381530) * t);

  return pd;

}


public int probability_of_match (float length1, float length2)
{
  double mean;			/* average of length1 and expected length1 */
  double z_score;		/* normalized statistic about length ratio */
  double result;		/* resulting probability (double tail) */

  if (length1 == 0 && length2 == 0)
  return 0;
  mean = (length1 + length2 / MEAN_RATIO) / 2;
  z_score = ((MEAN_RATIO * (length1 - length2)) / Math.sqrt (VARIANCE_RATIO * mean));

  /* See the body of the article quoted at the beginning of this program
     for a discussion of the following probability computation.  */

  if (z_score < 0)
  z_score = -z_score;
  result = 2 * (1 - normal_cdf (z_score));
//  assert (result >= 0);

  if (result == 0)
    return BIG_DISTANCE;
  else
    return (int) (-100 * Math.log (result));
}


public int double_sided_cost (strategy newstrategy, VAL_TABLE table1, VAL_TABLE table2, int a, int b)
{
  int cost = 0;


  if(newstrategy.strat.equals("SUBSTITUTION"))
  {
	  cost = probability_of_match (table1.get(a), table2.get(b));
	  //cost = probability_of_match (1, 1);

  }
  else if(newstrategy.strat.equals("DELETION"))
  {
	  cost = (probability_of_match (table1.get(a), 0) + PENALTY_01);

  }
  else if(newstrategy.strat.equals("INSERTION"))
  {
	  cost = (probability_of_match (0, table2.get(b))+ PENALTY_01);

  }
  else if(newstrategy.strat.equals("CONTRACTION"))
  {
	  cost = (probability_of_match (table1.get(a) + table1.get(a+1), table2.get(b))
	      + PENALTY_21);
  }
  else if(newstrategy.strat.equals("EXPANSION"))
  {
	  cost = (probability_of_match (table1.get(a), table2.get(b) + table2.get(b+1))+ PENALTY_21);
  }
  else if(newstrategy.strat.equals("MELDING"))
  {
	  cost = (probability_of_match (table1.get(a)+ table1.get(a+1), table2.get(b) + table2.get(b+1))+ PENALTY_22);
  }

  return cost;
}

/* dynamic programming.  */

public int STEP_MATRIX(int x, int y, int z){

	int tempAddress = 0;
	tempAddress = (((x)*(z+1))+(y));
	if (tempAddress < 0)
	{
		tempAddress = 0;
	}

	return tempAddress;
}

public step_table align_values(VAL_TABLE table1, VAL_TABLE table2, strategy strategy, int item1, int item2){

    int cost_function;
    int currAddress = 0, costAddress = 0;
    int MAXINT = Integer.MAX_VALUE;
    int index1 = 0, index2 = 0;int i = 0;int j = 0; /* index for table1 & table2 */
    int delta1 = 0, delta2 = 0;	                    /* backward in sequence 1 & 2 to link strategy */
    int best_cost = 0;		                    /* cost associated with best strategy */
    int cost = 0;int tj = 0;			    /* current strategy value */
    String best_strategy;int val = 0;	            /* best strategy */
    strategy currstrategy = new strategy();	    /* current strategy */
    step_table result = new step_table();	    /* resulting alignment */
    step step = new step();		/* pointer into step_matrix */
    int counter =  (table1.getlength()+1)*(table2.getlength()+1);//System.out.println("counter total is: "+counter);
    step_table step_matrix = new step_table(counter);
    step_matrix.length = counter;
    for(tj=0; tj<counter;tj++)
    {
		step_matrix.STEP[tj] = new step();
		step_matrix.STEP[tj].cost = 0;
		step_matrix.STEP[tj].str.svalue = -1;
	}

   currAddress = STEP_MATRIX(0,0,table2.getlength());               /*Gets the current address*/
   step_matrix.STEP[currAddress] = new step();
   step_matrix.STEP[currAddress].str.svalue = -1;
   step_matrix.STEP[currAddress].cost = 0;
   step_matrix.STEP[currAddress].sval = -1;
   step_matrix.STEP[currAddress].setvalue(step_matrix.STEP[currAddress].sval);


   for (index1 = 0; index1 <= table1.getlength(); index1++){
	   for (index2 = index1 == 0 ? 1:0 ; index2 <= table2.getlength(); index2++)
	       {

        	  	val = -1;
	            best_strategy = null;
	     	  	best_cost = MAXINT;

          int s = currstrategy.svalue;
          s = -1;
          for( s = 0; s < 6 ; s++)
             {
    		   currstrategy.svalue = s;
    		   currstrategy.setvalue(s);

				    delta1 = DELTA.item1[s];          //This is assuming DELTA corresponds to STRATEGY[]
				    delta2 = DELTA.item2[s];
                    if(index1 >= delta1 && index2 >= delta2)
				    {

//                      System.out.println("delta1 & delta2 are: "+delta1+" " +delta2);
//                      System.out.println("index1 & index2 are: "+index1+" " +index2);

                       int a = index1-delta1; int b = index2-delta2;


                       costAddress = STEP_MATRIX(a, b, table2.getlength());//System.out.println("costAddress is :"+costAddress);
	                   cost = (step_matrix.STEP[costAddress].cost+ (double_sided_cost(currstrategy, table1, table2, a, b)));

		                /*Retain this strategy if it improved the best cost so far*/
		                if(cost <= best_cost)
		                {
							best_strategy = currstrategy.strat;
							val = currstrategy.svalue;
							best_cost = cost;
           				}

					}
				}//End of strategy loop
			                   //s = -1;
                        currAddress = STEP_MATRIX(index1, index2, table2.getlength());
                        step_matrix.STEP[currAddress] = new step();

						step_matrix.STEP[currAddress].str.svalue = val;
						step_matrix.STEP[currAddress].cost = best_cost;
//                		System.out.println("cost at address "+currAddress+" is : "+ step_matrix.STEP[currAddress].cost);
						step_matrix.STEP[currAddress].sval = val;step_matrix.STEP[currAddress].setvalue(val);
//             			System.out.println("step_matrix.STEP["+currAddress+"].sval = "+step_matrix.STEP[currAddress].sval);
//						System.out.println("step_matrix.STEP["+currAddress+"].str.svalue is : "+step_matrix.STEP[currAddress].str.svalue);
						step_matrix.STEP[currAddress].str.setvalue(step_matrix.STEP[currAddress].str.svalue);
//						System.out.println("step_matrix.STEP["+currAddress+"].str.strat is: "+step_matrix.STEP[currAddress].str.strat);
			    }
			}
         int newvalue = -1;//System.out.println("");System.out.println("");

         /* The result array is allocated.  */

         ;int k = 0;int h = 0; int l = 0;int address = 0;
         int s = 0;//currstrategy.svalue;
         result = new step_table(java.lang.Math.max (table1.getlength(),table2.getlength()));
         String str = null; int value = -1; int scost = -1;

         for(index1 = table1.getlength(), index2 = table2.getlength();
                  index1 > 0 || index2 > 0;
                  index1 -= h /*DELTA.item1[s]*/, index2 -= l)//DELTA.item2[s])
                  {
//					System.out.println("index1 is : "+index1);System.out.println("index2 is : "+index2);
					address = STEP_MATRIX(index1, index2, table2.getlength());
//					System.out.println("address is : "+address);
                    value = step_matrix.STEP[address].sval;//System.out.println("value is: "+value);
//                    System.out.println("step_matrix.STEP["+address+"].sval = "+step_matrix.STEP[address].sval);
                    s = value;// System.out.println("s now is: "+s);
					h = DELTA.item1[s]; l = DELTA.item2[s];//    System.out.println("h is : "+h+ "  l is :"+l);
					result.length = k+1;result.STEP[k] = new step();result.STEP[k].str = new strategy();
					result.STEP[k].sval = value;
					result.STEP[k].cost = step_matrix.STEP[address].cost;
					result.STEP[k].setvalue(value);
//					System.out.println("result.STEP["+k+"].sval = "+result.STEP[k].sval);
//					System.out.println("result.STEP["+k+"].cost = "+result.STEP[k].cost);
//					System.out.println("result.STEP["+k+"].newstrat = "+result.STEP[k].newstrat);
//					System.out.println("");

      				k ++;
				  }

  result.length = k;

  return result;

    }


}//end of align_values

