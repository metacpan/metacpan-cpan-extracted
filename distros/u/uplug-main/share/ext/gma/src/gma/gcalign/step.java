package gma.gcalign;

public class step
    {
		strategy str;
		int cost;
		int sval;
		String newstrat;

//constructor
		public step(){
			str = new strategy();
			cost = 0;
			sval = -1;
			newstrat = new String();
		}

		        public void setvalue(int sval)
		        {
		          if(sval == -1){
			      newstrat = null;
			      }
			      else if(sval == 0){
				  newstrat = "SUBSTITUTION";
			      }
				  else if(sval == 1){
				  newstrat = "DELETION";
			      }
			      else if(sval == 2){
				  newstrat = "INSERTION";
			      }
			      else if(sval == 3){
				  newstrat = "CONTRACTION";
			      }
			      else if(sval == 4){
				  newstrat = "EXPANSION";
			      }
			      else if(sval == 5){
				  newstrat = "MELDING";
			      }
			  }

	}

