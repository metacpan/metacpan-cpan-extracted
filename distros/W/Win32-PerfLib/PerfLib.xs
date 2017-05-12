#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winreg.h>
#include <winperf.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#if !defined(PERL_OBJECT)
#  ifndef CPERLarg_
#    define CPERLarg_
#  endif /* CPERLarg_ */
#  ifndef PERL_OBJECT_THIS_
#    define PERL_OBJECT_THIS_
#  endif /* PERL_OBJECT_THIS_ */
#endif

#if (defined (PERL_OBJECT) && defined (NT_BUILD_NUMBER))
#  define PERL_OBJECT_THIS_ pPerl,
#  define PL_na na
#  define boolSV(b) ((b) ? &sv_yes : &sv_no)
#endif

#define SUCCESS(x)	(x == ERROR_SUCCESS)

#define SETIV(index,value) sv_setiv(ST(index), value)
#define SETNV(index,value) sv_setnv(ST(index), value)
#define SETPV(index,string) sv_setpv(ST(index), string)
#define SETPVN(index, buffer, length) sv_setpvn(ST(index), (char*)buffer, length)

#define TEMPBUFSZ      1024
#define LARGEBUF       0xffff
#define SIZE_MASK      0x00000300
#define TYPE_MASK      0x00000C00
#define SUB_TYPE_MASK  0x000F0000
#define TIME_BASE_MASK 0x00300000
#define CALC_MOD_MASK  0x0FC00000
#define DISPLAY_MASK   0xF0000000


DWORD
constant(CPERLarg_ char *name)
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	if (strEQ(name, "PERF_100NSEC_MULTI_TIMER"))
#ifdef PERF_100NSEC_MULTI_TIMER
	    return PERF_100NSEC_MULTI_TIMER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_100NSEC_MULTI_TIMER_INV"))
#ifdef PERF_100NSEC_MULTI_TIMER_INV
	    return PERF_100NSEC_MULTI_TIMER_INV;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_100NSEC_TIMER"))
#ifdef PERF_100NSEC_TIMER
	    return PERF_100NSEC_TIMER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_100NSEC_TIMER_INV"))
#ifdef PERF_100NSEC_TIMER_INV
	    return PERF_100NSEC_TIMER_INV;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_AVERAGE_BASE"))
#ifdef PERF_AVERAGE_BASE
	    return PERF_AVERAGE_BASE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_AVERAGE_BULK"))
#ifdef PERF_AVERAGE_BULK
	    return PERF_AVERAGE_BULK;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_AVERAGE_TIMER"))
#ifdef PERF_AVERAGE_TIMER
	    return PERF_AVERAGE_TIMER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_BASE"))
#ifdef PERF_COUNTER_BASE
	    return PERF_COUNTER_BASE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_BULK_COUNT"))
#ifdef PERF_COUNTER_BULK_COUNT
	    return PERF_COUNTER_BULK_COUNT;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_COUNTER"))
#ifdef PERF_COUNTER_COUNTER
	    return PERF_COUNTER_COUNTER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_DELTA"))
#ifdef PERF_COUNTER_DELTA
	    return PERF_COUNTER_DELTA;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_ELAPSED"))
#ifdef PERF_COUNTER_ELAPSED
	    return PERF_COUNTER_ELAPSED;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_FRACTION"))
#ifdef PERF_COUNTER_FRACTION
	    return PERF_COUNTER_FRACTION;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_HISTOGRAM"))
#ifdef PERF_COUNTER_HISTOGRAM
	    return PERF_COUNTER_HISTOGRAM;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_HISTOGRAM_TYPE"))
#ifdef PERF_COUNTER_HISTOGRAM_TYPE
	    return PERF_COUNTER_HISTOGRAM_TYPE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_LARGE_DELTA"))
#ifdef PERF_COUNTER_LARGE_DELTA
	    return PERF_COUNTER_LARGE_DELTA;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_LARGE_QUEUELEN_TYPE"))
#ifdef PERF_COUNTER_LARGE_QUEUELEN_TYPE
	    return PERF_COUNTER_LARGE_QUEUELEN_TYPE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_LARGE_RAWCOUNT"))
#ifdef PERF_COUNTER_LARGE_RAWCOUNT
	    return PERF_COUNTER_LARGE_RAWCOUNT;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_LARGE_RAWCOUNT_HEX"))
#ifdef PERF_COUNTER_LARGE_RAWCOUNT_HEX
	    return PERF_COUNTER_LARGE_RAWCOUNT_HEX;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_MULTI_BASE"))
#ifdef PERF_COUNTER_MULTI_BASE
	    return PERF_COUNTER_MULTI_BASE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_MULTI_TIMER"))
#ifdef PERF_COUNTER_MULTI_TIMER
	    return PERF_COUNTER_MULTI_TIMER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_MULTI_TIMER_INV"))
#ifdef PERF_COUNTER_MULTI_TIMER_INV
	    return PERF_COUNTER_MULTI_TIMER_INV;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_NODATA"))
#ifdef PERF_COUNTER_NODATA
	    return PERF_COUNTER_NODATA;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_QUEUELEN"))
#ifdef PERF_COUNTER_QUEUELEN
	    return PERF_COUNTER_QUEUELEN;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_QUEUELEN_TYPE"))
#ifdef PERF_COUNTER_QUEUELEN_TYPE
	    return PERF_COUNTER_QUEUELEN_TYPE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_RATE"))
#ifdef PERF_COUNTER_RATE
	    return PERF_COUNTER_RATE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_RAWCOUNT"))
#ifdef PERF_COUNTER_RAWCOUNT
	    return PERF_COUNTER_RAWCOUNT;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_RAWCOUNT_HEX"))
#ifdef PERF_COUNTER_RAWCOUNT_HEX
	    return PERF_COUNTER_RAWCOUNT_HEX;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_TEXT"))
#ifdef PERF_COUNTER_TEXT
	    return PERF_COUNTER_TEXT;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_TIMER"))
#ifdef PERF_COUNTER_TIMER
	    return PERF_COUNTER_TIMER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_TIMER_INV"))
#ifdef PERF_COUNTER_TIMER_INV
	    return PERF_COUNTER_TIMER_INV;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_COUNTER_VALUE"))
#ifdef PERF_COUNTER_VALUE
	    return PERF_COUNTER_VALUE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DATA_REVISION"))
#ifdef PERF_DATA_REVISION
	    return PERF_DATA_REVISION;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DATA_VERSION"))
#ifdef PERF_DATA_VERSION
	    return PERF_DATA_VERSION;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DELTA_BASE"))
#ifdef PERF_DELTA_BASE
	    return PERF_DELTA_BASE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DELTA_COUNTER"))
#ifdef PERF_DELTA_COUNTER
	    return PERF_DELTA_COUNTER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DETAIL_ADVANCED"))
#ifdef PERF_DETAIL_ADVANCED
	    return PERF_DETAIL_ADVANCED;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DETAIL_EXPERT"))
#ifdef PERF_DETAIL_EXPERT
	    return PERF_DETAIL_EXPERT;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DETAIL_NOVICE"))
#ifdef PERF_DETAIL_NOVICE
	    return PERF_DETAIL_NOVICE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DETAIL_WIZARD"))
#ifdef PERF_DETAIL_WIZARD
	    return PERF_DETAIL_WIZARD;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DISPLAY_NOSHOW"))
#ifdef PERF_DISPLAY_NOSHOW
	    return PERF_DISPLAY_NOSHOW;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DISPLAY_NO_SUFFIX"))
#ifdef PERF_DISPLAY_NO_SUFFIX
	    return PERF_DISPLAY_NO_SUFFIX;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DISPLAY_PERCENT"))
#ifdef PERF_DISPLAY_PERCENT
	    return PERF_DISPLAY_PERCENT;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DISPLAY_PER_SEC"))
#ifdef PERF_DISPLAY_PER_SEC
	    return PERF_DISPLAY_PER_SEC;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_DISPLAY_SECONDS"))
#ifdef PERF_DISPLAY_SECONDS
	    return PERF_DISPLAY_SECONDS;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_ELAPSED_TIME"))
#ifdef PERF_ELAPSED_TIME
	    return PERF_ELAPSED_TIME;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_INVERSE_COUNTER"))
#ifdef PERF_INVERSE_COUNTER
	    return PERF_INVERSE_COUNTER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_MULTI_COUNTER"))
#ifdef PERF_MULTI_COUNTER
	    return PERF_MULTI_COUNTER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_NO_INSTANCES"))
#ifdef PERF_NO_INSTANCES
	    return PERF_NO_INSTANCES;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_NO_UNIQUE_ID"))
#ifdef PERF_NO_UNIQUE_ID
	    return PERF_NO_UNIQUE_ID;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_NUMBER_DECIMAL"))
#ifdef PERF_NUMBER_DECIMAL
	    return PERF_NUMBER_DECIMAL;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_NUMBER_DEC_1000"))
#ifdef PERF_NUMBER_DEC_1000
	    return PERF_NUMBER_DEC_1000;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_NUMBER_HEX"))
#ifdef PERF_NUMBER_HEX
	    return PERF_NUMBER_HEX;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_OBJECT_TIMER"))
#ifdef PERF_OBJECT_TIMER
	    return PERF_OBJECT_TIMER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_RAW_BASE"))
#ifdef PERF_RAW_BASE
	    return PERF_RAW_BASE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_RAW_FRACTION"))
#ifdef PERF_RAW_FRACTION
	    return PERF_RAW_FRACTION;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_SAMPLE_BASE"))
#ifdef PERF_SAMPLE_BASE
	    return PERF_SAMPLE_BASE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_SAMPLE_COUNTER"))
#ifdef PERF_SAMPLE_COUNTER
	    return PERF_SAMPLE_COUNTER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_SAMPLE_FRACTION"))
#ifdef PERF_SAMPLE_FRACTION
	    return PERF_SAMPLE_FRACTION;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_SIZE_DWORD"))
#ifdef PERF_SIZE_DWORD
	    return PERF_SIZE_DWORD;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_SIZE_LARGE"))
#ifdef PERF_SIZE_LARGE
	    return PERF_SIZE_LARGE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_SIZE_VARIABLE_LEN"))
#ifdef PERF_SIZE_VARIABLE_LEN
	    return PERF_SIZE_VARIABLE_LEN;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_SIZE_ZERO"))
#ifdef PERF_SIZE_ZERO
	    return PERF_SIZE_ZERO;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_TEXT_ASCII"))
#ifdef PERF_TEXT_ASCII
	    return PERF_TEXT_ASCII;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_TEXT_UNICODE"))
#ifdef PERF_TEXT_UNICODE
	    return PERF_TEXT_UNICODE;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_TIMER_100NS"))
#ifdef PERF_TIMER_100NS
	    return PERF_TIMER_100NS;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_TIMER_TICK"))
#ifdef PERF_TIMER_TICK
	    return PERF_TIMER_TICK;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_TYPE_COUNTER"))
#ifdef PERF_TYPE_COUNTER
	    return PERF_TYPE_COUNTER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_TYPE_NUMBER"))
#ifdef PERF_TYPE_NUMBER
	    return PERF_TYPE_NUMBER;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_TYPE_TEXT"))
#ifdef PERF_TYPE_TEXT
	    return PERF_TYPE_TEXT;
#else
	goto not_there;
#endif
	if (strEQ(name, "PERF_TYPE_ZERO"))
#ifdef PERF_TYPE_ZERO
	    return PERF_TYPE_ZERO;
#else
	goto not_there;
#endif
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

int WCTMB(LPWSTR lpwStr, LPSTR lpStr, int size)
{
    *lpStr = '\0';
    return WideCharToMultiByte(CP_ACP,0,lpwStr,-1,lpStr,size,NULL,NULL);
}


PPERF_OBJECT_TYPE FirstObject( PPERF_DATA_BLOCK PerfData )
{
    return ((PPERF_OBJECT_TYPE)((PBYTE)PerfData + 
				PerfData->HeaderLength));
}

PPERF_OBJECT_TYPE NextObject( PPERF_OBJECT_TYPE PerfObj )
{
    return ((PPERF_OBJECT_TYPE)((PBYTE)PerfObj + 
				PerfObj->TotalByteLength));
}


PPERF_INSTANCE_DEFINITION FirstInstance( PPERF_OBJECT_TYPE PerfObj )
{
    return ((PPERF_INSTANCE_DEFINITION)((PBYTE)PerfObj + 
					PerfObj->DefinitionLength));
}

PPERF_INSTANCE_DEFINITION NextInstance( PPERF_INSTANCE_DEFINITION PerfInst )
{
    PPERF_COUNTER_BLOCK PerfCntrBlk;
    
    PerfCntrBlk = (PPERF_COUNTER_BLOCK)((PBYTE)PerfInst + 
					PerfInst->ByteLength);
    
    return ((PPERF_INSTANCE_DEFINITION)((PBYTE)PerfCntrBlk + 
					PerfCntrBlk->ByteLength));
}


PPERF_COUNTER_DEFINITION FirstCounter( PPERF_OBJECT_TYPE PerfObj )
{
    return ((PPERF_COUNTER_DEFINITION) ((PBYTE)PerfObj + 
					PerfObj->HeaderLength));
}

PPERF_COUNTER_DEFINITION NextCounter( PPERF_COUNTER_DEFINITION PerfCntr )
{
    return ((PPERF_COUNTER_DEFINITION)((PBYTE)PerfCntr +
				       PerfCntr->ByteLength));
}

HV *GetCounters(CPERLarg_ PPERF_OBJECT_TYPE PerfObj,
		PPERF_INSTANCE_DEFINITION PerfInst)
{
    PPERF_COUNTER_DEFINITION PerfCntr, CurCntr;
    BYTE *lpCounterData;
    LARGE_INTEGER *lpLargeInt;
    DWORD *lpDWord;
    DWORD k,size,type,subtype, display, calc_mod, time_base;
    char buffer[TEMPBUFSZ];
    HV *hvCounter;
    HV *hvCounterNum;
    DWORD PerfLib_debug = 0;
    dTHX;
    
    PerfCntr = FirstCounter(PerfObj);
    hvCounterNum = newHV();
    CurCntr = PerfCntr;
    for (k=0;k<PerfObj->NumCounters;k++)
    {
	hvCounter = newHV();
	if (PerfLib_debug) printf("\tCounter: %d\n\tCounterType: 0x%08x\n",
			 CurCntr->CounterNameTitleIndex,
			 CurCntr->CounterType);
	size = CurCntr->CounterType & SIZE_MASK;
#//	hv_store(hvCounter, "Size", (I32)strlen("Size"),
#//		 newSViv(size), 0);
	type = CurCntr->CounterType & TYPE_MASK;
#//	hv_store(hvCounter, "Type", (I32)strlen("Type"),
#//		 newSViv(type), 0);
	subtype = CurCntr->CounterType & SUB_TYPE_MASK;
#//	hv_store(hvCounter, "SubType", (I32)strlen("SubType"),
#//		 newSViv(subtype), 0);
	display = CurCntr->CounterType & DISPLAY_MASK;
	calc_mod = CurCntr->CounterType & CALC_MOD_MASK;
#//	hv_store(hvCounter, "CalculationModifiers", (I32)strlen("CalculationModifiers"),
#//		 newSViv(calc_mod), 0);
	time_base = CurCntr->CounterType & TIME_BASE_MASK;
#//	hv_store(hvCounter, "TimeBase", (I32)strlen("TimeBase"),
#//		 newSViv(time_base), 0);
	hv_store(hvCounter, "CounterNameTitleIndex",
		 (I32)strlen("CounterNameTitleIndex"),
		 newSViv(CurCntr->CounterNameTitleIndex), 0);
	hv_store(hvCounter, "CounterHelpTitleIndex",
		 (I32)strlen("CounterHelpTitleIndex"),
		 newSViv(CurCntr->CounterHelpTitleIndex), 0);
	hv_store(hvCounter, "CounterSize", (I32)strlen("CounterSize"),
		 newSViv(CurCntr->CounterSize), 0);
	hv_store(hvCounter, "CounterType", (I32)strlen("CounterType"),
		 newSViv(CurCntr->CounterType), 0);
	hv_store(hvCounter, "DefaultScale", (I32)strlen("DefaultScale"),
		 newSViv(CurCntr->DefaultScale), 0);
	hv_store(hvCounter, "DetailLevel", (I32)strlen("DetailLevel"),
		 newSViv(CurCntr->DetailLevel), 0);
 	if ( PerfObj->NumInstances > 0 )
 	{
 		lpCounterData = ((BYTE*)PerfInst
  			 + PerfInst->ByteLength
  			 + CurCntr->CounterOffset);
 	}
 	else 
 	{
 		lpCounterData = ((BYTE*)PerfInst
 			 + CurCntr->CounterOffset);
 	}
	switch(size)
	{
	case PERF_SIZE_DWORD:
	    lpDWord = (DWORD*)lpCounterData;
	    hv_store(hvCounter, "Counter", (I32)strlen("Counter"),
		     newSViv(*lpDWord), 0);
	    if (PerfLib_debug)
	    {
		printf("\t\tdword: %ld", *lpDWord);
	    }
	    break;
	case PERF_SIZE_LARGE:
	    lpLargeInt = (LARGE_INTEGER*)lpCounterData;
	    sprintf(buffer, "%I64d", lpLargeInt->QuadPart );
	    hv_store(hvCounter, "Counter", (I32)strlen("Counter"),
		     newSVpv(buffer, strlen(buffer)), 0);
#//         hv_store(hvCounter, "Counter", (I32)strlen("Counter"),
#//		     newSVnv((double)lpLargeInt->QuadPart), 0);
	    if (PerfLib_debug)
	    {
		printf("\t\tlarge integer: 0x%016I64x (%I64u)",
		       lpLargeInt->QuadPart,
		       lpLargeInt->QuadPart);
	    }
	    break;
	case PERF_SIZE_ZERO:
	    if (PerfLib_debug) printf("\t\tzero");
	    break;
	case PERF_SIZE_VARIABLE_LEN:
	    if (PerfLib_debug) printf("\t\tvariable length");
	    break;
	default:
	    if (PerfLib_debug) printf("\t\tunknown");
	    break;
	}
	if (PerfLib_debug) printf("\n\t\tsize: %d\n", CurCntr->CounterSize );
	switch(type)
	{
	case PERF_TYPE_NUMBER:
	    if (PerfLib_debug)
	    {
		printf("\t\tnumber: ");
		if (PERF_NUMBER_HEX == subtype)
		    printf("hex\n");
		else if (PERF_NUMBER_DECIMAL == subtype )
		    printf("decimal\n");
		else if (PERF_NUMBER_DEC_1000 == subtype )
		    printf("decimal/1000\n");
	    }
	    break;
	case PERF_TYPE_COUNTER:
	    if (PerfLib_debug)
	    {
		printf("\t\tcounter: ");
		if (PERF_COUNTER_VALUE == subtype)
		    printf("value");
		else if (PERF_COUNTER_RATE == subtype )
		    printf("rate");
		else if (PERF_COUNTER_FRACTION == subtype)
		    printf("fraction");
		else if (PERF_COUNTER_BASE == subtype)
		    printf("base");
		else if (PERF_COUNTER_ELAPSED == subtype )
		    printf("elapsed");
		else if (PERF_COUNTER_QUEUELEN == subtype )
		    printf("queuelen");
		else if (PERF_COUNTER_HISTOGRAM == subtype )
		    printf("histogram");
		printf( "\n\t\t");
		if (PERF_TIMER_TICK == time_base)
		    printf("tick");
		else if (PERF_TIMER_100NS == time_base)
		    printf("100ns");
		else if (PERF_OBJECT_TIMER == time_base)
		    printf("object timer freq");
		printf("\n");
	    }
	    break;
	case PERF_TYPE_TEXT:
	    if (PerfLib_debug) printf("\t\ttext (%s)\n",
			     PERF_TEXT_ASCII == subtype ? "ASCII" : "UNICODE");
	    break;
	    
	}
	switch(display)
	{
	case PERF_DISPLAY_NO_SUFFIX:
	    if (PerfLib_debug) printf("\t\tno suffix\n");
	    break;
	case PERF_DISPLAY_PER_SEC:
	    hv_store(hvCounter, "Display", (I32)strlen("Display"),
		     newSVpv("/sec", strlen("/sec")),0);
	    if (PerfLib_debug) printf("\t\t/sec\n");
	    break;
	case PERF_DISPLAY_PERCENT:
	    hv_store(hvCounter, "Display", (I32)strlen("Display"),
		     newSVpv("%", strlen("%")),0);
	    if (PerfLib_debug) printf("\t\t%%\n");
	    break;
	case PERF_DISPLAY_SECONDS:
	    hv_store(hvCounter, "Display", (I32)strlen("Display"),
		     newSVpv("sec", strlen("sec")),0);
	    if (PerfLib_debug) printf("\t\tsecs\n");
	    break;
	case PERF_DISPLAY_NOSHOW:
	    if (PerfLib_debug) printf("\t\tnot displayed\n"); 
	    break;
	}
	if (PerfLib_debug)
	{
	    if (calc_mod & PERF_DELTA_COUNTER)
		printf("\t\tcompute difference\n");
	    if (calc_mod & PERF_DELTA_BASE )
		printf("\t\tcompute base difference\n");
	    if (calc_mod & PERF_INVERSE_COUNTER )
		printf("\t\tinvert counter\n");
	    if (calc_mod & PERF_MULTI_COUNTER )
		printf("\t\tmulti counter\n");
	}
	sprintf(buffer, "%d", k );
	hv_store(hvCounterNum, buffer, (I32)strlen(buffer),
		 (SV*)newRV_noinc((SV*)hvCounter),0);
	CurCntr = NextCounter(CurCntr);
    }
    return hvCounterNum;
}

MODULE = Win32::PerfLib		PACKAGE = Win32::PerfLib		

PROTOTYPES: DISABLE

long
constant(name)
	char *name
    CODE:
	RETVAL = constant(PERL_OBJECT_THIS_ name);
    OUTPUT:
	RETVAL


bool
PerfLibOpen(machine,ohandle)
	char *machine
	HKEY ohandle = NO_INIT
    CODE:
        RETVAL = SUCCESS(RegConnectRegistryA(machine, HKEY_PERFORMANCE_DATA, &ohandle));
    OUTPUT:
	RETVAL
	ohandle

bool
PerfLibClose(handle)
	HKEY handle
    CODE:
	RETVAL = SUCCESS(RegCloseKey(handle));
    OUTPUT:
	RETVAL

bool
PerfLibGetNames(machine,counter)
	char *machine
	SV *counter
    PREINIT:
	HKEY remote_lmkey;
	HKEY remote_perfkey;
	char akey[256] = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Perflib\\009";
	WCHAR wkey[256] = L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Perflib\\009";
	BYTE *nameArray;
	DWORD value_len;
	DWORD type;
    CODE:
        RETVAL = SUCCESS(RegConnectRegistryA(machine, HKEY_LOCAL_MACHINE, &remote_lmkey));
	if (!RETVAL)
	    XSRETURN_NO;

	RETVAL = SUCCESS(RegOpenKeyExA(remote_lmkey, akey, 0, KEY_READ, &remote_perfkey));
	if (!RETVAL)
	{
	    RegCloseKey(remote_lmkey);
	    XSRETURN_NO;
	}

        RETVAL = SUCCESS(RegQueryValueExA(remote_perfkey, "Counter", NULL, NULL,
                                          NULL, &value_len));
	if (!RETVAL)
	{
	    RegCloseKey(remote_lmkey);
	    RegCloseKey(remote_perfkey);
	    XSRETURN_NO;
	}

	Newz(0, nameArray, value_len, BYTE);
	if (!nameArray)
	{
	    RegCloseKey(remote_lmkey);
	    RegCloseKey(remote_perfkey);
	    XSRETURN_NO;
	}
        RETVAL = SUCCESS(RegQueryValueExA(remote_perfkey, "Counter", NULL, &type,
                                          (LPBYTE)nameArray, &value_len));
	if (RETVAL)
	{
	    switch(type)
	    {
	    case REG_SZ:
	    case REG_MULTI_SZ:
	    case REG_EXPAND_SZ:
		if (value_len)
		    --value_len;
		break;
	    default:
		break;
	    }
	}
	RegCloseKey(remote_lmkey);
	RegCloseKey(remote_perfkey);
    OUTPUT:
	RETVAL
	counter		if (RETVAL) { SETPVN(1, nameArray, value_len); } Safefree(nameArray);

bool
PerfLibGetHelp(machine,help)
	char *machine
	SV *help
    PREINIT:
	HKEY remote_lmkey;
	HKEY remote_perfkey;
	char akey[256] = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Perflib\\009";
	WCHAR wkey[256] = L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Perflib\\009";
	BYTE *helpArray;
	DWORD value_len;
	DWORD type;
    CODE:
        RETVAL = SUCCESS(RegConnectRegistryA(machine, HKEY_LOCAL_MACHINE,
                                             &remote_lmkey));
	if (!RETVAL) {
	    XSRETURN_NO;
	}

        RETVAL = SUCCESS(RegOpenKeyExA(remote_lmkey, akey, 0, KEY_READ, &remote_perfkey));
	if (!RETVAL) {
	    RegCloseKey(remote_lmkey);
	    XSRETURN_NO;
	}

        RETVAL = SUCCESS(RegQueryInfoKeyA(remote_perfkey, NULL, NULL, NULL, NULL,
                                          NULL, NULL, NULL, NULL, &value_len, NULL, NULL));
	if (!RETVAL) {
	    RegCloseKey(remote_lmkey);
	    RegCloseKey(remote_perfkey);
	    XSRETURN_NO;
	}

	Newz(0, helpArray, value_len, BYTE);
	if (!helpArray)
	{
	    RegCloseKey(remote_lmkey);
	    RegCloseKey(remote_perfkey);
	    XSRETURN_NO;
	}
        RETVAL = SUCCESS(RegQueryValueExA(remote_perfkey, "Help", NULL, &type,
                                          (LPBYTE)helpArray, &value_len));
	if (RETVAL)
	{
	    switch(type)
	    {
	    case REG_SZ:
	    case REG_MULTI_SZ:
	    case REG_EXPAND_SZ:
		if (value_len)
		    --value_len;
		break;
	    default:
		break;
	    }
	}
	RegCloseKey(remote_lmkey);
	RegCloseKey(remote_perfkey);
    OUTPUT:
	RETVAL
	help		if (RETVAL) { SETPVN(1, helpArray, value_len); } Safefree(helpArray);



bool
PerfLibGetObjects(handle,counter,data)
	HKEY handle
	char *counter
	SV *data
    PREINIT:
	BYTE databuf[TEMPBUFSZ];
	SV *bufsv = Nullsv;
	DWORD cbData = TEMPBUFSZ;
	BYTE *lpData = databuf;
	PPERF_DATA_BLOCK PerfData = NULL;
	PPERF_OBJECT_TYPE PerfObj;
	PPERF_INSTANCE_DEFINITION PerfInst;
	PPERF_COUNTER_DEFINITION PerfCntr, CurCntr;
	BYTE *lpCounterData;
	DWORD i,j,type;
	char buffer[TEMPBUFSZ];
	HV *hvInstance;
	HV *hvObject;
	HV *hvCounterNum;
	HV *hvInstanceNum;
	HV *hvObjectNum;
	FILETIME ft;
	LARGE_INTEGER lft;
	DWORD PerfLib_debug = 0;
	DWORD result;
	DWORD count = 0; // AS
    CODE:
	if (SvROK(data))
	    data = SvRV(data);

	while (count < 500) {
            result = RegQueryValueExA(handle,counter,NULL,&type,lpData, &cbData);
	    if (ERROR_MORE_DATA == result) {
		cbData += TEMPBUFSZ;
		if (lpData == databuf)
		    bufsv = sv_newmortal();	/* perl cleans this up */
		lpData = (BYTE*)sv_grow(bufsv, cbData * sizeof(BYTE));
	    }
	    else {
		if (ERROR_SUCCESS == result) {
		    count++; // AS
		    break;
		}
		else {
		    XSRETURN_NO;
		}
	    }
	}
	PerfData = (PERF_DATA_BLOCK *)lpData;
	if (PerfLib_debug) {
	    printf("cbData: %d\n", cbData );
	    printf("NumObjectTypes: %d\n", PerfData->NumObjectTypes );
	}
	hv_store((HV*)data, "NumObjectTypes", (I32)strlen("NumObjectTypes"),
		 newSViv(PerfData->NumObjectTypes),0);
	SystemTimeToFileTime(&(PerfData->SystemTime), &ft);
	lft.u.LowPart = (DWORD)ft.dwLowDateTime;
	lft.u.HighPart = (LONG)ft.dwHighDateTime;
	sprintf(buffer, "%I64d", lft.QuadPart);
#//	hv_store((HV*)data, "SystemTime", (I32)strlen("SystemTime"),
#//		 newSVpv(buffer, strlen(buffer)), 0);
	hv_store((HV*)data, "SystemTime", (I32)strlen("SystemTime"),
		 newSVnv((double)lft.QuadPart), 0);
	hv_store((HV*)data, "PerfTime", (I32)strlen("PerfTime"),
		 newSVnv((double)PerfData->PerfTime.QuadPart),0);
	hv_store((HV*)data, "PerfFreq", (I32)strlen("PerfFreq"),
		 newSVnv((double)PerfData->PerfFreq.QuadPart),0);
	hv_store((HV*)data, "PerfTime100nSec", (I32)strlen("PerfTime100nSec"),
		 newSVnv((double)PerfData->PerfTime100nSec.QuadPart),0);
	WCTMB((LPWSTR)((PBYTE)PerfData + PerfData->SystemNameOffset), buffer,
	      PerfData->SystemNameLength);
	hv_store((HV*)data, "SystemName", (I32)strlen("SystemName"),
		 newSVpv(buffer, strlen(buffer)),0);
	PerfObj = FirstObject(PerfData);
	if (PerfLib_debug)
	{
	    printf("NumCounters: %d\n", PerfObj->NumCounters );
	    printf("NumInstances: %d\n", PerfObj->NumInstances );
	}
	hvObjectNum = newHV();
	for (i=1;i<=PerfData->NumObjectTypes;i++)
	{
	    hvObject = newHV();
	    hv_store(hvObject, "ObjectNameTitleIndex", (I32)strlen("ObjectNameTitleIndex"),
		     newSViv(PerfObj->ObjectNameTitleIndex), 0);
	    hv_store(hvObject, "ObjectHelpTitleIndex", (I32)strlen("ObjectHelpTitleIndex"),
		     newSViv(PerfObj->ObjectHelpTitleIndex), 0);
	    hv_store(hvObject, "NumCounters", (I32)strlen("NumCounters"),
		     newSViv(PerfObj->NumCounters), 0);
	    hv_store(hvObject, "NumInstances", (I32)strlen("NumInstances"),
		     newSViv(PerfObj->NumInstances), 0);
	    hv_store(hvObject, "DetailLevel", (I32)strlen("DetailLevel"),
		     newSViv(PerfObj->DetailLevel), 0);
#//		sprintf(buffer, "%I64d", PerfObj->PerfTime.QuadPart);
#//		hv_store(hvObject, "PerfTime", (I32)strlen("PerfTime"),
#//				 newSVpv(buffer, strlen(buffer)), 0);
	    hv_store(hvObject, "PerfTime", (I32)strlen("PerfTime"),
		     newSVnv((double)PerfObj->PerfTime.QuadPart), 0);
	    hv_store(hvObject, "PerfFreq", (I32)strlen("PerfFreq"),
		     newSVnv((double)PerfObj->PerfFreq.QuadPart), 0);
	    PerfCntr = FirstCounter(PerfObj);
	    PerfInst = FirstInstance(PerfObj);
	    if (PerfObj->NumInstances > 0 )
	    {
		hvInstanceNum = newHV();
		for (j=1;j<=(DWORD)PerfObj->NumInstances;j++)
		{
		    if (PerfLib_debug)
			printf("Instance %S\n",
			       (char *)((PBYTE)PerfInst + PerfInst->NameOffset));
		    CurCntr = PerfCntr;
		    lpCounterData = ((PBYTE)PerfInst + PerfInst->ByteLength +
				     CurCntr->CounterOffset);
		    hvInstance = newHV();
		    WCTMB((LPWSTR)((PBYTE)PerfInst + PerfInst->NameOffset), buffer,
			  PerfInst->NameLength);
		    hv_store(hvInstance, "Name", (I32)strlen("Name"),
			     newSVpv(buffer, strlen(buffer)), 0);
		    hv_store(hvInstance, "ParentObjectTitleIndex",
			     (I32)strlen("ParentObjectTitleIndex"),
			     newSViv(PerfInst->ParentObjectTitleIndex), 0);
		    hv_store(hvInstance, "ParentObjectInstance",
			     (I32)strlen("ParentObjectInstance"),
			     newSViv(PerfInst->ParentObjectInstance), 0);
		    hvCounterNum = GetCounters(PERL_OBJECT_THIS_ PerfObj, PerfInst);
		    hv_store(hvInstance, "Counters", (I32)strlen("Counters"),
			     (SV*)newRV_noinc((SV*)hvCounterNum), 0);
		    sprintf(buffer, "%d", j);
		    hv_store(hvInstanceNum, buffer, (I32)strlen(buffer),
			     (SV*)newRV_noinc((SV*)hvInstance),0);
		    PerfInst = NextInstance(PerfInst);
		}
		hv_store(hvObject, "Instances", (I32)strlen("Instances"),
			 (SV*)newRV_noinc((SV*)hvInstanceNum),0);
	    }
	    else
	    {
		hvCounterNum = GetCounters(PERL_OBJECT_THIS_ PerfObj, PerfInst);
		hv_store(hvObject, "Counters", (I32)strlen("Counters"),
			 (SV*)newRV_noinc((SV*)hvCounterNum),0);
	    }
	    sprintf(buffer, "%d", PerfObj->ObjectNameTitleIndex);
	    hv_store(hvObjectNum, buffer, (I32)strlen(buffer),
		     (SV*)newRV_noinc((SV*)hvObject),0);
	    PerfObj = NextObject(PerfObj);
		
	}
	hv_store((HV*)data, "Objects", (I32)strlen("Objects"),
		 (SV*)newRV_noinc((SV*)hvObjectNum),0); // AS
	RETVAL = 1;
    OUTPUT:
	RETVAL
