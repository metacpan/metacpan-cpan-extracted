package gma.gcalign;

import java.lang.*;
import java.util.*;


public class VAL_TABLE
{
    protected float[] vtable;                            /*Array of value_tables */
    protected int length;

    //constructor
    public VAL_TABLE(String inputstr)
    {
	StringTokenizer st = new StringTokenizer(inputstr, ",");
	length = st.countTokens();
	//actually both string1 and string2 together are of length
	vtable = new float[length];

	//fill  vtable
	int line = 0;
	while (st.hasMoreTokens())
	    {
		String strval = st.nextToken();
		vtable[line] = (Float.valueOf(strval)).floatValue();
		line++;

	    }

	length = line;
    }

    public int getlength()
    {
	return length;
    }

    /**
     * gets a string of index
     */
    public float get(int index)
    {
	return vtable[index];
    }

    /**
     * print the sequence
     */
    public void print()
    {
        System.out.println("length = "+length);
	for(int i = 0; i < length; i++)
	    {
		System.out.println(vtable[i]);
	    }
    }

}

