#/* -*- Mode: C -*- */
#/* Author: Wilson Snyder <wsnyder@wsnyder.org> */
#/* IRIX & FreeBSD port by: Daniel Gustafson <daniel@hobbit.se> */
#/*##################################################################### */
#/* */
#/* Copyright 1999-2017 by Wilson Snyder.  This program is free software; */
#/* you can redistribute it and/or modify it under the terms of either the GNU */
#/* Lesser General Public License Version 3 or the Perl Artistic License Version 2.0. */
#/*  */
#/* This program is distributed in the hope that it will be useful, */
#/* but WITHOUT ANY WARRANTY; without even the implied warranty of */
#/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the */
#/* GNU General Public License for more details. */
#/*  */
#/*##################################################################### */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>

#if defined(_AIX)
# define AIX
#endif

#if defined(hpux) || defined(__hpux)
# define HPUX
#endif

#if defined(__osf__) && (defined(__alpha) || defined(__alpha__))
# define OSF_ALPHA
#endif

#if defined(__mips)
# define MIPS
# if defined(sgi)
#  define IRIX
# endif
#endif

#if defined(sun) || defined(__sun__)
# define SUNOS
#endif

#ifdef AIX
# ifdef HAS_PMAPI
#  include <pmapi.h>
# endif
# ifdef HAS_PERFSTAT
#  include <libperfstat.h>
# endif
#endif

#ifdef HPUX
#include <sys/param.h>
#include <sys/pstat.h>
struct pst_dynamic psd;
#endif

#ifdef OSF_ALPHA
#include <sys/sysinfo.h>
#include <machine/hal_sysinfo.h>
#endif

#if defined(MIPS) && !defined(__linux__)
#include <sys/systeminfo.h>
#endif

#ifdef IRIX
#include <dirent.h>
#include <sys/invent.h>
#include <sys/pda.h>
#include <sys/sbd.h>
#include <sys/sysmp.h>
#include <sys/iograph.h>
#include <invent.h>
#include <sys/param.h>
#endif

#ifdef SUNOS
#include <sys/processor.h>
#endif

#if defined(__FreeBSD__) || defined(__APPLE__)
#include <stdlib.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/param.h>
#endif

/* Missing in older headers */
#ifndef P_POWEROFF
#define P_POWEROFF 5
#endif

typedef int CpuNumFromRef_t;

#/**************************************************************/

#ifdef __linux__
const char* proc_cpuinfo_field (const char *field)
    /* Return string from a field of /proc/cpuinfo, NULL if not found */
    /* Comparison is case insensitive */
    /* If multiple matches, the last match is returned */
{
    FILE* fp;
    static char line[1000];
    static char result[1000];
    int len = strlen(field);
    char* resultp = NULL;
    if (NULL!=(fp = fopen ("/proc/cpuinfo", "r"))) {
	while (!feof(fp)) {
	    const char* ok = fgets (line, 990, fp);
	    if (ok && 0==strncasecmp (field, line, len)) {
		char *loc = strchr (line, ':');
		if (loc) {
		    strncpy(result,loc+2, 990);
		    resultp = result;
		    loc = strchr (result, '\n');
		    if (loc) *loc = '\0';
		    /*printf("MATCH: %s: %s\n", field, resultp);*/
		}
	    }
	}
	fclose(fp);
    }
    return (resultp);
}

int _proc_cpuinfo_clock_calc (void)
{
    const char* value;
    value = proc_cpuinfo_field ("cpu MHz");
    if (value) return (atoi(value));
    value = proc_cpuinfo_field ("clock");
    if (value) return (atoi(value));
    value = proc_cpuinfo_field ("bogomips");
    if (value) return (atoi(value));
    return (0);
}

int proc_cpuinfo_clock (void)
    /* Return clock frequency */
{
    static int cache = 0;
    if (!cache) cache = _proc_cpuinfo_clock_calc();
    return cache;
}

#endif

int _proc_nthreaders_calc (void)
{
    int num_cpus = 0;

    /* Determine how many processors are online and available */
#ifdef HPUX
    if (pstat_getdynamic(&psd, sizeof(psd), (size_t)1, 0) != -1)
        num_cpus = psd.psd_proc_cnt;
#endif

#ifdef OSF_ALPHA
    getsysinfo(GSI_CPUS_IN_BOX,&num_cpus,sizeof(num_cpus),0,0)
#endif

#if defined(MIPS) && !defined(__linux__)
    char buf[16];
    if (sysinfo(_MIPS_SI_NUM_PROCESSORS, buf, 10) != -1)
        num_cpus = atoi(buf);
#endif

    /* Generic linux defaults */
#if defined(SUNOS) || defined(AIX) || defined(__APPLE__) || defined (__linux__)
    if (num_cpus < 1)
	num_cpus = sysconf(_SC_NPROCESSORS_ONLN);
# ifdef __linux__
    if (num_cpus < 1) {
	/* SPARC Linux has a bug where SC_NPROCESSORS is set to 0. */
	const char* value = proc_cpuinfo_field("ncpus active");
	if (value) num_cpus = atoi(value);
    }
# endif
#endif

#if defined(__FreeBSD__) || defined(HW_NCPU)
    size_t len = sizeof(num_cpus);
    sysctlbyname("hw.ncpu", &num_cpus, &len, NULL, 0);
#endif

    if (num_cpus < 1)
        num_cpus=1;      /* We're running this program, after all :-) */
    return (num_cpus);
}

int proc_nthreaders (void)
    /* Return number of processor threads */
{
    static int cache = 0;
    if (!cache) cache = _proc_nthreaders_calc();
    return cache;
}

#ifdef IRIX
/* invent_cpuinfo_t irix_get_cpuinf(int cpuid);
 * Returns an invent_cpuinfo_t regarding the requested cpuid. */
invent_cpuinfo_t irix_get_cpuinf(int cpuid) {
    union {
        invent_generic_t generic;
        invent_cpuinfo_t cpu;
    } hw_inv;

    int attr_len = sizeof(hw_inv);
    DIR *hw_graph;
    struct dirent *hw_entry;
    char *hw_entry_buf = (char *)malloc(MAXPATHLEN);
    char *hw_filename = (char *)malloc(MAXPATHLEN);

    if ((hw_graph = opendir("/hw/cpunum")) != NULL) {
	while ((hw_entry = readdir(hw_graph)) != NULL) {

            if ((strcmp(hw_entry->d_name, ".") != 0) && (strcmp(hw_entry->d_name, "..") != 0)) {
                strcpy(hw_filename, "/hw/cpunum/");
                strncat(hw_filename, hw_entry->d_name, 1);

                if (realpath(hw_filename, hw_entry_buf) != NULL) {
                    if (attr_get(hw_entry_buf, INFO_LBL_DETAIL_INVENT, (char *)&hw_inv, &attr_len, 0) == 0) {
                        if (hw_inv.generic.ig_invclass == INV_PROCESSOR) {
                            if (hw_inv.cpu.ic_cpuid == cpuid) {
				break;
			    }
			}
		    }
		}
            }
        }
    }

    closedir(hw_graph);
    return(hw_inv.cpu);
}
#endif

int logical_per_physical_cpu() {
    int logical_per = 1;

#ifdef __linux__
    const char* flags = proc_cpuinfo_field ("flags");
    /* flags: ... ht ... indicates hyperthreading enabled on a cpu */
    if (flags && strstr (flags, " ht ")) {
	/* HACK: Current linux under hyperthreading always makes 2 logical CPUs per physical CPU */
	logical_per = 2;
    }
#endif
#ifdef __FreeBSD__
    int hlt_htt_cpu = 0;
    size_t len = sizeof(hlt_htt_cpu);
    if (sysctlbyname("machdep.hlt_logical_cpus",
		     &hlt_htt_cpu, &len, NULL, 0) == 0) {
	if (hlt_htt_cpu == 0) {
	    /* HACK: Current FreeBSD under hyperthreading always makes 2 logical CPUs per physical CPU */
	    logical_per = 2;
	}
    }
#endif

    return logical_per;
}

int proc_num_physical_ids() {
#ifdef __linux__
    {
	const char* value = proc_cpuinfo_field ("physical id");
	if (value) {
	    int phys = atoi(value)+1;
	    return phys;
	}
    }
#endif
    return 0;
}
int _proc_ncores_calc() {
    /* Can't have more cores than threaders */
    int num = proc_nthreaders();
#ifdef __linux__
    {
	int phys = proc_num_physical_ids();
	const char* cvalue = proc_cpuinfo_field ("cpu cores");
	if (phys && cvalue) {
	    int cores_per_phys = atoi(cvalue);
	    int cores = phys * cores_per_phys;
	    if (cores && (cores <= num)) return cores;
	}
    }
#endif
    {
	/* If hyperthreading, the threader count is too high */
	if (num > 1) {
	    num /= logical_per_physical_cpu();
	}
	return num;
    }
}

int proc_ncores() {
    /* Return number of processor cores */
    static int cache = 0;
    if (!cache) cache = _proc_ncores_calc();
    return cache;
}

int _proc_nsockets_calc() {
    int num = proc_ncores();
    /* default to core count, trim downwards if we can */
    int phys = proc_num_physical_ids();
    if (phys && ((phys <= num))) num = phys;
    return num;
}

int proc_nsockets() {
    /* Return number of processor sockets */
    static int cache = 0;
    if (!cache) cache = _proc_nsockets_calc();
    return cache;
}


MODULE = Unix::Processors  PACKAGE = Unix::Processors

#/**********************************************************************/
#/* class->max_online() */
#/* Self is a argument, but we don't need it */
#/* We use sysconf, as that is more portable */
#/* Other packages also provide sysconf, but saves downloading them... */

long
max_online(self)
SV *self;
CODE:
{
    if (self) {}  /* Prevent unused warning */
    RETVAL = proc_nthreaders();
}
OUTPUT: RETVAL

#/**********************************************************************/
#/* class->max_physical() */
#/* Self is a argument, but we don't need it */

long
max_physical(self)
SV *self;
CODE:
{
    if (self) {}  /* Prevent unused warning */
    RETVAL = proc_ncores();
}
OUTPUT: RETVAL

#/**********************************************************************/
#/* class->max_socket() */
#/* Self is a argument, but we don't need it */

long
max_socket(self)
SV *self;
CODE:
{
    if (self) {}  /* Prevent unused warning */
    RETVAL = proc_nsockets();
}
OUTPUT: RETVAL

#/**********************************************************************/
#/* class->max_clock() */
#/* Self is a argument, but we don't need it */

int
max_clock(self)
SV *self;
CODE:
{
    int clock = 0;
#ifdef AIX
# if defined(HAS_PERFSTAT)
    perfstat_cpu_total_t data;
    if (perfstat_cpu_total (0, &data, sizeof(data), 1)) {
      clock = data.processorHZ / 1000000;
    }
# elif defined(HAS_PMAPI)
    /* pm_cycles uses an approximation to arrive at cycle time
     * so we round up to the nearest Mhz */
    clock = (int)((pm_cycles() + 500000) / 1000000);
# endif
#endif
#ifdef HPUX
    /* all processors have the same clock on HP - just report the first one */
    struct pst_processor psp;
    if (pstat_getprocessor(&psp, sizeof(psp), 1, 0)) {
      clock = psp.psp_iticksperclktick / 10000;
    }
#endif
#ifdef SUNOS
    int cpu;
    int last_cpu = 0;
    processor_info_t info, *infop=&info;
    for (cpu=0; cpu < last_cpu+16; cpu++) {
	if (processor_info (cpu, infop)==0
	    && infop->pi_state == P_ONLINE) {
	    if (clock < infop->pi_clock) {
		clock = infop->pi_clock;
	    }
	    last_cpu = cpu;
	}
    }
#endif
#ifdef IRIX
    int num_cpus = proc_nthreaders();
    if ((num_cpus > 0) && (num_cpus < 3)) {
	inventory_t *sys_invent;
	if (setinvent() != -1) {
	    for (sys_invent = getinvent(); (sys_invent); sys_invent = getinvent()) {
		if ((sys_invent->inv_class == INV_PROCESSOR) && (sys_invent->inv_type == INV_CPUBOARD)) {
		    clock = sys_invent->inv_controller;
		    break;
		}
	    }
	    endinvent();
	}
    }
    else {
	invent_cpuinfo_t cpu_info;
	int i;
	for (i = 0; i < proc_nthreaders(); i++) {
	    cpu_info = irix_get_cpuinf(i);
	    if (cpu_info.ic_cpuid == i)
		if (cpu_info.ic_cpu_info.cpufq > clock)
		    clock = cpu_info.ic_cpu_info.cpufq;
	}
    }
#endif
#if (defined(__FreeBSD__) && (__FreeBSD_version >= 503105))
    int value = 0;
    size_t len = sizeof(value);
    /*
     * Even if the frequency is modified using cpu_freq(3), all cpus
     * have the same value why we can request CPU 0 for max_clock.
     */
    if (sysctlbyname("dev.cpu.0.freq", &value, &len, NULL, 0) == 0) {
	clock = value;
    }
#elif defined(HW_CPU_FREQ)
    long long value = 0;
    size_t len = sizeof(value);
    if (sysctlbyname("hw.cpufrequency", &value, &len, NULL, 0) == 0) {
	clock = value;
    }
#endif
#ifdef __linux__
    int value = proc_cpuinfo_clock();
    if (value) clock = value;
#endif

    if (self) {}  /* Prevent unused warning */
    RETVAL = clock;
}
OUTPUT: RETVAL

#/**********************************************************************/
#/**********************************************************************/
#/**********************************************************************/
#/**********************************************************************/
#/**********************************************************************/

MODULE = Unix::Processors  PACKAGE = Unix::Processors::Info

#/**********************************************************************/
#/* class->id() */

int
id (cpu)
CpuNumFromRef_t cpu
PROTOTYPE: $
CODE:
{
    RETVAL = cpu;
}
OUTPUT: RETVAL

#/**********************************************************************/
#/* class->clock() */

SV *
clock (cpu)
CpuNumFromRef_t cpu
PROTOTYPE: $
CODE:
{
    int value = 0;
#ifdef AIX
    int num_cpus = proc_nthreaders();
    if (cpu < num_cpus) {
# if defined(HAS_PERFSTAT)
      perfstat_cpu_total_t data;
      if (perfstat_cpu_total (0, &data, sizeof(data), 1)) {
	value = data.processorHZ / 1000000;
      }
# elif defined(HAS_PMAPI)
      /* pm_cycles uses an approximation to arrive at cycle time
       * so we round up to the nearest Mhz */
      clock = (int)((pm_cycles() + 500000) / 1000000);
# endif
    }
#endif
#ifdef HPUX
    int num_cpus = proc_nthreaders();
    if (cpu < num_cpus) {
      /* all processors have the same clock on HP - just report the first one */
      struct pst_processor psp;
      if (pstat_getprocessor(&psp, sizeof(psp), 1, 0)) {
	value = psp.psp_iticksperclktick / 10000;
      }
    }
#endif
#ifdef SUNOS
    processor_info_t info, *infop=&info;
    if (processor_info (cpu, infop)==0) {
      value = infop->pi_clock;
    }
#endif
#ifdef IRIX
    int num_cpus = proc_nthreaders();
    if ((num_cpus > 0) && (num_cpus < 3)) {
	inventory_t *sys_invent;
	if (setinvent() != -1) {
	    while ((sys_invent = getinvent()) != NULL) {
		if ((sys_invent->inv_class == INV_PROCESSOR) && (sys_invent->inv_type == INV_CPUBOARD)) {
		    value = sys_invent->inv_controller;
		    break;
		}
	    }
	    endinvent();
	}
    }
    else {
	invent_cpuinfo_t cpu_info;
	cpu_info = irix_get_cpuinf(cpu);
	if (cpu_info.ic_cpuid == cpu)
	    value = cpu_info.ic_cpu_info.cpufq;
    }
#endif
#if (defined(__FreeBSD__) && (__FreeBSD_version >= 503105))
    int cpu_freq = 0;
    size_t len =  sizeof(cpu_freq);
    char cpu_freq_req[16];
    snprintf(cpu_freq_req, 16, "dev.cpu.%d.freq", cpu);
    if (sysctlbyname(cpu_freq_req, &cpu_freq, &len, NULL, 0) == 0) {
	value = cpu_freq;
    }
#endif
#ifdef __linux__
    /* Cheat... Same clock for every CPU */
    value = proc_cpuinfo_clock();
#endif
    if (value) {
	ST(0) = sv_newmortal();
	sv_setiv (ST(0), value);
    } else {
	ST(0) = &PL_sv_undef;
    }
}

#/**********************************************************************/
#/* class->state() */

SV *
state (cpu)
CpuNumFromRef_t cpu
PROTOTYPE: $
CODE:
{
    char *value = NULL;
#ifdef SUNOS
    processor_info_t info, *infop=&info;
    if (processor_info (cpu, infop)==0) {
	switch (infop->pi_state) {
	case P_ONLINE:
	    value = "online";
	    break;
	case P_OFFLINE:
	    value = "offline";
	    break;
	case P_POWEROFF:
	    value = "poweroff";
	    break;
	}
    }
#endif
#ifdef IRIX
    int num_cpus;
    if ((num_cpus = sysmp(MP_NPROCS)) != -1) {
	struct pda_stat proc_info[num_cpus];
	if (sysmp(MP_STAT, proc_info) != -1) {
	    if (proc_info[cpu].p_flags == PDAF_MASTER)
		value = "MASTER";
	    else if (proc_info[cpu].p_flags == PDAF_CLOCK)
		value = "CLOCK";
	    else if (proc_info[cpu].p_flags == PDAF_ENABLED)
		value = "ENABLED";
	    else if (proc_info[cpu].p_flags == PDAF_FASTCLOCK)
		value = "FASTCLOCK";
	    else if (proc_info[cpu].p_flags == PDAF_ISOLATED)
		value = "ISOLATED";
	    else if (proc_info[cpu].p_flags == PDAF_BROADCAST_OFF)
		value = "BROADCAST_OFF";
	    else if (proc_info[cpu].p_flags == PDAF_NONPREEMPTIVE)
		value = "NONPREEMPTIVE";
	    else if (proc_info[cpu].p_flags == PDAF_NOINTR)
		value = "NOINTR";
	    else if (proc_info[cpu].p_flags == PDAF_ITHREADSOK)
		value = "ITHREADSOK";
	    else if (proc_info[cpu].p_flags == PDAF_DISABLE_CPU)
		value = "DISABLE_CPU";
	    else if (proc_info[cpu].p_flags == PDAF_EXCLUDED)
		value = "EXCLUDED";
	    else
		/*
		 * No p_flags value is specified for uniprocessor
		 * systems. Return ONLINE.
		 */
		value = "ONLINE";
	}
    }
#endif
    /* Cheat... Assume all online */
    if (value == NULL)
	value = "online";
    /* Return it */
    if (value) {
	ST(0) = sv_newmortal();
	sv_setpv (ST(0), value);
    } else {
	ST(0) = &PL_sv_undef;
    }
}

#/**********************************************************************/
#/* class->type() */

SV *
type (cpu)
CpuNumFromRef_t cpu
PROTOTYPE: $
CODE:
{
    const char* value = NULL;
#ifdef AIX
# if defined(HAS_PERFSTAT)
    int num_cpus = proc_nthreaders();
    if (cpu < num_cpus) {
      perfstat_cpu_total_t data;
      if (perfstat_cpu_total (0, &data, sizeof(data), 1)) {
	value = data.description;
      }
    }
# endif
#endif
#ifdef HPUX
    int num_cpus = proc_nthreaders();
    if (cpu < num_cpus) {
	switch(sysconf(_SC_CPU_VERSION)) {
	case CPU_PA_RISC1_0:
		value = "HP PA-RISC 1.0";
		break;
	case CPU_PA_RISC1_1:
		value = "HP PA-RISC 1.1";
		break;
	case CPU_PA_RISC1_2:
		value = "HP PA-RISC 1.2";
		break;
	case CPU_PA_RISC2_0:
		value = "HP PA-RISC 2.0";
		break;
	}
    }
#endif
#ifdef SUNOS
    processor_info_t info, *infop=&info;
    if (processor_info (cpu, infop)==0) {
	value = infop->pi_processor_type;
    }
#endif
#ifdef __linux__
    int ncpu = proc_nthreaders();
    if (cpu < ncpu) {
	value = proc_cpuinfo_field ("model name");
	if (!value) value = proc_cpuinfo_field ("machine");
	if (!value) value = proc_cpuinfo_field ("family");
    }
#endif
#if defined(MIPS) && !defined(__linux__)
    if (cpu < proc_nthreaders()) {
	if ((value = (char *)malloc(64)) != NULL) {
	    sysinfo(SI_MACHINE, value, 64);
	}
    }
#endif
#ifdef IRIX
    if (cpu < proc_nthreaders()) {
	int cpu_data = 0;
	int num_cpus = proc_nthreaders();
	if ((num_cpus > 0) && (num_cpus < 3)) {
	    inventory_t *sys_invent;
	    if (setinvent() != -1) {
		while ((sys_invent = getinvent()) != NULL) {
		    if ((sys_invent->inv_class == INV_PROCESSOR) && (sys_invent->inv_type == INV_CPUCHIP)) {
			cpu_data = sys_invent->inv_state;
			break;
		    }
		}
		endinvent();
	    }
	}
	else {
	    invent_cpuinfo_t cpu_info;
	    cpu_info = irix_get_cpuinf(cpu);
	    if (cpu_info.ic_cpuid == cpu)
		cpu_data = cpu_info.ic_cpu_info.cpuflavor;
	}
	if (cpu_data != 0) {
	    if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R2000A)
		strcat(value, " MIPS R2000A");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R2000)
		strcat(value, " MIPS R2000A");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R3000A)
		strcat(value, " MIPS R3000A");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R3000)
		strcat(value, " MIPS R3000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R4000) {
		if (((cpu_data&C0_MAJREVMASK)>>C0_MAJREVSHIFT) >= C0_MAJREVMIN_R4400)
		    strcat(value, " MIPS R4400");
		else
		    strcat(value, " MIPS R4000");
	    }
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R4650)
		strcat(value, " MIPS R4650");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R4700)
		strcat(value, " MIPS R4700");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R4600)
		strcat(value, " MIPS R4600");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R5000)
		strcat(value, " MIPS R5000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_RM5271)
		strcat(value, " MIPS RM5271");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R6000A)
		strcat(value, " MIPS R6000A");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R6000)
		strcat(value, " MIPS R6000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_RM7000)
		strcat(value, " MIPS RM7000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R8000)
		strcat(value, " MIPS R8000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R10000)
		strcat(value, " MIPS R10000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R12000)
		strcat(value, " MIPS R12000");
	    else if ((cpu_data >> C0_IMPSHIFT) == C0_IMP_R14000)
		strcat(value, " MIPS R14000");
	    else
		strcat(value, " Undefined MIPS");
	    sprintf(value, "%s Chip Rev: %x.%x", value, ((cpu_data&C0_MAJREVMASK)>>C0_MAJREVSHIFT), ((cpu_data&C0_MINREVMASK)>>C0_MINREVSHIFT));
	}
    }
#endif
#ifdef __FreeBSD__
    if (cpu < proc_nthreaders()) {
	if ((value = (char *)malloc(64)) != NULL) {
	    size_t len = 64;
	    sysctlbyname("hw.machine_arch", value, &len, NULL, 0);
	}
    }
#endif

    if (value) {
	ST(0) = sv_newmortal();
	sv_setpv (ST(0), value);
    } else {
	ST(0) = &PL_sv_undef;
    }
}
