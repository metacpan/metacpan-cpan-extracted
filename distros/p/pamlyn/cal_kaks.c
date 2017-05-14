/* ---------------------------------------------------------
 * ---------------------------------------------------------
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

extern double *start(char *, int , int , int);

double *cal_kaks(int argc, char *argv[])
{
	int i;
	char seq_file[96];
	int ch_icode, ch_ite, ch_f;
        double *v;

	/* PASS */
	/* the order should be preserved */	  
   	strcpy(seq_file, argv[0]);
	ch_icode = atoi(argv[1]); 
	ch_ite = atoi(argv[2]);	
	ch_f = atoi(argv[3]); 
	
	/* START */
	v = start(seq_file, ch_icode, ch_ite, ch_f);
	
	/* RETURN */
        return v;
}

