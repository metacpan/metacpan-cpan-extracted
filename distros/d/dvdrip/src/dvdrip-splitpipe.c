/* $Id: dvdrip-splitpipe.c 1947 2006-03-27 20:50:00Z joern $
 *
 * Copyright (C) 2001-2006 Jörn Reder <joern@zyn.de> All Rights Reserved
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
void    usage (void);
void    fatal ( char* message );
void    split_pipe ( int chunk_size, char* base_filename, char* extension, int use_tcdemux, char* vob_nav_file );
int     open_split_file( int old_fd, int chunk_cnt, char* base_filename, char* extension );
int     open_vob_nav_file ( char* filename );
void    write_split_file ( int split_fd, char* buffer, size_t cnt );
FILE*   open_tcdemux_pipe ( char* filename );

/* print usage */
void usage (void) {
	printf ("Usage: dvdrip-splitpipe [-f vob_nav_file] size-in-mb base-filename extension\n");
	printf ("       -f   use tcdemux for progress information (transcode 0.6.0)\n");
	exit(1);
}

/* report fatal error and exite */
void fatal ( char* message ) {
	fprintf (stderr, "Fatal error: %s\n", message);
	exit(1);
}
/* main function */
int main(int argc, char *argv[]) {
	int    chunk_size;
	char*  base_filename;
	char*  extension;
	int    ok;
	int    opt;
	int    use_tcdemux = 0;
	char*  vob_nav_file;
	int    opt_cnt;
	
	opt_cnt = 0;

	while ((opt = getopt(argc, argv, "f:")) != -1) {
		++opt_cnt;
		switch (opt) {
			case 'f' :
				if ( optarg[0]=='-' ) usage();
				use_tcdemux  = 1;
				vob_nav_file = optarg;
				++opt_cnt;
				break;
		}
	}
	
/* printf ("-f=%d argc=%d optind=%d\n", use_tcdemux, argc, optind); */
	
	if ( argc - optind != 3 ) usage();
	
	ok = sscanf (argv[optind], "%d", &chunk_size);
	
	if ( ok != 1 )   usage();
	
	base_filename = argv[optind+1];
	extension     = argv[optind+2];
	
/* printf ("-f=%d nav_file=%s size=%d base=%s ext=%s\n", use_tcdemux, vob_nav_file, chunk_size, base_filename, extension); */
	
	split_pipe ( chunk_size, base_filename, extension, use_tcdemux, vob_nav_file );
	
	return 0;
}

/* split and pipe */
void split_pipe ( int chunk_size, char* base_filename, char* extension,
		  int use_tcdemux, char* vob_nav_file ) {
	char	buffer[BUFSIZE];
	int	file_cnt = 1;
	int	split_fd;
	FILE*	tcdemux_fd;
	size_t	bytes_read;
	size_t	bytes_written = 0;
	size_t	bytes_this_chunk;
	size_t	bytes_next_chunk;
	int     first = 1;

	chunk_size *= 1024*1024;

	split_fd = open_split_file (
		-1, file_cnt, base_filename, extension
	);

	if ( use_tcdemux )
		tcdemux_fd = open_tcdemux_pipe( vob_nav_file );

	while ( bytes_read = read (0, buffer, BUFSIZE) ) {
                if ( first ) {
                	fprintf (stderr, "--splitpipe-started--\n");
                        first = 0;
                }

		/* echo chunk to stdout */
		write (1, buffer, bytes_read);

		if ( use_tcdemux )
			/* echo chunk to tcdemux pipe */
			fwrite (buffer, 1, bytes_read, tcdemux_fd);
		else
			/* echo progress information to stderr */
			fprintf (stderr, "%d-%d\n", file_cnt, bytes_written);

		/* check if we need to open a new file */
		if ( bytes_written + bytes_read > chunk_size ) {
			bytes_this_chunk = chunk_size-bytes_written;
			bytes_next_chunk = bytes_read-bytes_this_chunk;

			write_split_file (split_fd, buffer, bytes_this_chunk);

			++file_cnt;
			split_fd = open_split_file (
				split_fd, file_cnt, base_filename, extension
			);

			write_split_file (split_fd, buffer+bytes_this_chunk, bytes_next_chunk);
			bytes_written = bytes_next_chunk;

		} else {
			write_split_file (split_fd, buffer, bytes_read);
			bytes_written += bytes_read;
		}
	}
	
	close (split_fd);
	
	if ( use_tcdemux )
		pclose (tcdemux_fd);


	fprintf (stderr, "--splitpipe-finished--\n");
}

/* write data to split file */
void write_split_file ( int split_fd, char* buffer, size_t cnt ) {
	if ( split_fd == -1 )
		return;
	if ( -1 == write (split_fd, buffer, cnt) )
		fatal ("Can't write to split file");
}

/* open a new split file */
int open_split_file( int old_fd, int chunk_cnt,
		     char* base_filename, char* extension ) {
	char	filename[255];
	int	new_fd;

	if ( old_fd != -1 ) {
		/* ok, first close last split file */
		close (old_fd);
	}
	
	if ( !strncmp(base_filename, "-", 1) )
		return -1;
	
	/* now open a new split file */
	sprintf (filename, "%s-%03d.%s", base_filename, chunk_cnt, extension);
	
	new_fd = creat (filename, 0644);

	if ( -1 == new_fd ) {
		fprintf (stderr, "Can't create file %s\n", filename);
		fatal ("aborting");
	}

	return new_fd;
}

/* open tcdemux pipe for progress information */
FILE* open_tcdemux_pipe ( char* filename ) {
	FILE*	fd;
	char	command[255];

	sprintf (command, "tcdemux -W 2>/dev/null | tee %s | cat 1>&2", filename);

	if ( (fd = popen(command, "w")) == NULL )
		fatal ("can't execute tcdemux -W");

	return fd;
}

/* open file for vob navigation information */
int open_vob_nav_file ( char* filename ) {
	int 	fd;

	fd = creat (filename, 0644);
	if ( -1 == fd ) {
		fprintf (stderr, "Can't create file %s\n", filename);
		fatal ("aborting");
	}
	
	return fd;
}

