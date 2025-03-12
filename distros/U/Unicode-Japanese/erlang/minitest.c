#include "unijp.h"
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/resource.h>

#define DEBUG(cmd) ((void)0)

/* ----------------------------------------------------------------------------
 * unijp allocator.
 * ------------------------------------------------------------------------- */
void* uja_alloc(void* baton, uj_size_t size)
{
  return malloc(size);
}
void* uja_realloc(void* baton, void* ptr, uj_size_t size)
{
  return realloc(ptr, size);
}
void uja_free(void* baton, void* ptr)
{
  return free(ptr);
}

/* ----------------------------------------------------------------------------
 * init @ lid handler.
 * ------------------------------------------------------------------------- */
static int init()
{
	DEBUG(printf("erl_init...\r\n"));

	static const uj_alloc_t my_uj_alloc = {
		UJ_ALLOC_MAGIC,
		NULL, /* baton. */
		&uja_alloc,
		&uja_realloc,
		&uja_free,
	};
	_uj_default_alloc = &my_uj_alloc;

	return 0;
}


char buf[200*1024];

int main(int argc, const char* argv[])
{
	const char* path;
	int fd;
	struct stat st;

	init();
	
	path = argc >= 2 ? argv[1] : "b.bin";
	fd = open(path, O_RDONLY);
	if( fd < 0 )
	{
		perror("open");
		return 1;
	}
	if( fstat(fd, &st) < 0 )
	{
		perror("fstat");
		return 1;
	}
	if( read(fd, buf, st.st_size) != st.st_size )
	{
		perror("read");
		return 1;
	}
	close(fd);

	{
		struct rusage ru_1, ru_2;
		int secs, usecs;
		uj_charcode_t icode = ujc_utf8;
		uj_charcode_t ocode = ujc_jis;
		unijp_t* uj;
		uj_uint8* ret;
		uj_size_t ret_len;

		if( getrusage(RUSAGE_SELF, &ru_1) != 0 )
		{
			perror("getrusage");
			return 1;
		}

		uj = uj_new((uj_uint8*)buf, st.st_size, icode);
		ret = uj_conv(uj, ocode, &ret_len);
		uj_delete(uj);

		if( getrusage(RUSAGE_SELF, &ru_2) != 0 )
		{
			perror("getrusage");
			return 1;
		}
		secs  = ru_2.ru_utime.tv_sec  - ru_1.ru_utime.tv_sec;
		usecs = ru_2.ru_utime.tv_usec - ru_1.ru_utime.tv_usec;
		if( usecs < 0 )
		{
			usecs += 1000*1000;
			secs  -= 1;
		}
		fprintf(stderr, "%d.%06d\n", secs, usecs);
		write(1, ret, ret_len);
		uja_free(NULL, ret);
	};
	return 0;
}
