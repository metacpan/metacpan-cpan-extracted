package gma.gcalign;

public class strategy_delta{
	static int[] item1;
	static int[] item2;
	int ivalue = 0;

	//contructor
	public strategy_delta(){
	item1 = new int[6];
	item2 = new int[6];

	item1[0] = 1; item2[0] = 1;
	item1[1] = 1; item2[1] = 0;
	item1[2] = 0; item2[2] = 1;
    item1[3] = 2; item2[3] = 1;
    item1[4] = 1; item2[4] = 2;
    item1[5] = 2; item2[5] = 2;

  }
}

