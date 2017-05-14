/* akgviz.c  -  AKB GraphViz dumper
 *
 * Copyright (c) 2006,2012 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is unpublished proprietary source code. All dissemination
 * prohibited. Contains trade secrets. NO WARRANTY. See file COPYING.
 * Special grant: akgviz.h may be used with zxid open source project under
 * same licensing terms as zxid itself.
 *
 * Dump session and PDU datastructures to a gviz (dot) graph.
 * To visualize the graph you must have graphviz as well as
 * ghostscript installed.
 *
 * See also: http://www.research.att.com/sw/tools/graphviz/download.html
 * /apps/graphviz/std/bin/dot -Tps <a.dot |gv
 */

#include <string.h>
#include <pthread.h>
#include <stdarg.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <limits.h>
#include <time.h>
#include <sys/ptrace.h>  /* see also /proc/pid */
#include <bfd.h>   /* -lbfd */

#include "errmac.h"
#include "akbox.h"

void die(char* why);
char* amap(char* x);

/* Called by: */
void ak_gviz(char* filename)
{
  FILE* dot = fopen(filename, "w");
  if (!dot) die(filename);
  
  fclose(dot);
}

/* EOF  -  akgviz.c */
