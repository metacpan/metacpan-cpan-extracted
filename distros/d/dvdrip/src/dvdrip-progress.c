/* $Id: dvdrip-progress.c 1863 2005-10-30 12:42:58Z joern $
 *
 * Copyright (C) 2001-2002 Jörn Reder <joern@zyn.de> All Rights Reserved
 * 
 * This program is part of Video::DVDRip, which is free software; you can
 * redistribute it and/or modify it under the same terms as Perl itself.
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define BUFSIZE 1024*1024

/* function prototypes */
void    usage ( void );
void	progress ( int max_size, int interval_size );

/* print usage */
void usage ( void ) {
	printf ("usage: dvdrip-progress -m max-size-mbytes -i report-interval-mbytes\n");
	printf ("       -m   expected maximum size in mbytes\n");
	printf ("       -i   interval for reporting progress in mbytes\n");
	exit(1);
}

/* main function */
int main( int argc, char *argv[] ) {
	int	max_size      = 0;
	int	interval_size = 0;

	int    	ok;
	int    	opt;
	int    	opt_cnt;
	
	opt_cnt = 0;

	while ((opt = getopt(argc, argv, "m:i:")) != -1) {
		++opt_cnt;
		switch (opt) {
			case 'm' :
				if ( optarg[0]=='-' ) usage();
				if ( 1 != sscanf (optarg, "%d", &max_size) )
					usage();
				++opt_cnt;
				break;
			case 'i' :
				if ( optarg[0]=='-' ) usage();
				if ( 1 != sscanf (optarg, "%d", &interval_size) )
					usage();
				++opt_cnt;
				break;
		}
	}
	
	if ( argc - optind != 0 ) usage();
	if ( max_size == 0 || interval_size == 0 )
		usage();
	
	progress ( max_size, interval_size );
	
	return 0;
}

void progress ( int max_size, int interval_size ) {
	char	buffer[BUFSIZE];
	int	mbytes_sum;
	size_t	bytes_read;
	int	mbbuf = 0;

	while ( bytes_read = read (0, buffer, BUFSIZE) ) {
		/* echo chunk to stdout */
		write (1, buffer, bytes_read);

		mbbuf += bytes_read;
		
		if ( mbbuf > BUFSIZE ) {
			while ( mbbuf > BUFSIZE ) {
				++mbytes_sum;
				mbbuf -= BUFSIZE;
			}
		
			if ( 0 == mbytes_sum % interval_size )
				fprintf (stderr, "dvdrip-progress: %d/%d\n", mbytes_sum, max_size);
		}
	}

	fprintf (stderr, "%d/%d\n", max_size, max_size);
}

