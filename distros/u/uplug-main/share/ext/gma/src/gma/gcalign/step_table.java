package gma.gcalign;

public class step_table
        {
			step[] STEP;             /* Array of step descriptors*/
			int length;              /* Number of steps*/

			//constructor
       public step_table()
       {
			STEP = new step[0];
			length = 0;
	   }
	   public step_table(int size)
	   {
		   STEP = new step[size];
		   length = size;
	   }

	}

