package gma.gcalign;

public class strategy
  {

       static String strat;
       static int svalue;

        public strategy()
        {
			strat = new String();
			svalue = 0;
		}

        public void setsval(int value)
        {
			if(value < 0)
			svalue = -1;
			else svalue = value;
		}

        public void setvalue(int svalue)
        {
          if(svalue == -1){
	      strat = null;
	      }
	      else if(svalue == 0){
		  strat = "SUBSTITUTION";
	      }
		  else if(svalue == 1){
		  strat = "DELETION";
	      }
	      else if(svalue == 2){
		  strat = "INSERTION";
	      }
	      else if(svalue == 3){
		  strat = "CONTRACTION";
	      }
	      else if(svalue == 4){
		  strat = "EXPANSION";
	      }
	      else if(svalue == 5){
		  strat = "MELDING";
	      }
	  }

   } //this can also be used for strategy_name//

