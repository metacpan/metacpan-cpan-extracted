//
// (C) Copyright 2011-2018 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// Test of the performace of the unaligned reading.
// By default it's configured to run fast at the cost of precision. To increase
// the precision increase the number of iterations by setting the environment
// variable:
//   TRICEPS_PERF_COUNT=0x100000000 t_value_perf
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <utest/Utest.h>

#include <common/Value.h>

#define DEFAULT_COUNT 1000

#define ARRAYSZ 16
static int64_t data[ARRAYSZ+1];
int64_t *apdata; // initialized in warmup()
int64_t *updata; // initialized in warmup()

static double now()
{
	timespec tm;
	clock_gettime(CLOCK_REALTIME, &tm);
	return (double)tm.tv_sec + (double)tm.tv_nsec / 1000000000.;
}

int64_t findRunCount()
{
	char *v = getenv("TRICEPS_PERF_COUNT");
	if (v != NULL) {
		long long n;
		if (sscanf(v, "%lli", &n) == 1) {
			return n;
		}
	}
	return DEFAULT_COUNT;
}

UTESTCASE warmup(Utest *utest)
{
	apdata = data;
	updata = (int64_t*)((char *)data + 1);

	int64_t n = findRunCount();
	int64_t x = 0;

	double tstart = now();
	for (int64_t i = 0; i < n; i++) {
		x += apdata[i % ARRAYSZ];
	}
	double tend = now();
	printf("        [%lld] %lld iterations, %f seconds, %f iter per second\n", (long long) x, (long long)n, (tend-tstart), (double)n / (tend-tstart));
}

UTESTCASE readAlignedDirect(Utest *utest)
{
	int64_t n = findRunCount();
	int64_t x = 0;

	double tstart = now();
	for (int64_t i = 0; i < n; i++) {
		x += apdata[i % ARRAYSZ];
	}
	double tend = now();
	printf("        [%lld] %lld iterations, %f seconds, %f iter per second\n", (long long) x, (long long)n, (tend-tstart), (double)n / (tend-tstart));
}

UTESTCASE readAlignedMemcpy(Utest *utest)
{
	int64_t n = findRunCount();
	int64_t x = 0;

	double tstart = now();
	for (int64_t i = 0; i < n; i++) {
		int64_t inter;
		memcpy(&inter, (char *)(apdata + i%ARRAYSZ), sizeof(int64_t));
		x += inter;
	}
	double tend = now();
	printf("        [%lld] %lld iterations, %f seconds, %f iter per second\n", (long long) x, (long long)n, (tend-tstart), (double)n / (tend-tstart));
}

UTESTCASE readUnalignedMemcpy(Utest *utest)
{
	int64_t n = findRunCount();
	int64_t x = 0;

	double tstart = now();
	for (int64_t i = 0; i < n; i++) {
		int64_t inter;
		memcpy(&inter, (char *)(updata + i%ARRAYSZ), sizeof(int64_t));
		x += inter;
	}
	double tend = now();
	printf("        [%lld] %lld iterations, %f seconds, %f iter per second\n", (long long) x, (long long)n, (tend-tstart), (double)n / (tend-tstart));
}

UTESTCASE readAlignedTemplate(Utest *utest)
{
	int64_t n = findRunCount();
	int64_t x = 0;

	double tstart = now();
	for (int64_t i = 0; i < n; i++) {
		x += getUnaligned<int64_t>(apdata + i%ARRAYSZ);
	}
	double tend = now();
	printf("        [%lld] %lld iterations, %f seconds, %f iter per second\n", (long long) x, (long long)n, (tend-tstart), (double)n / (tend-tstart));
}

UTESTCASE readUnalignedTemplate(Utest *utest)
{
	int64_t n = findRunCount();
	int64_t x = 0;

	double tstart = now();
	for (int64_t i = 0; i < n; i++) {
		x += getUnaligned<int64_t>(updata + i%ARRAYSZ);
	}
	double tend = now();
	printf("        [%lld] %lld iterations, %f seconds, %f iter per second\n", (long long) x, (long long)n, (tend-tstart), (double)n / (tend-tstart));
}

