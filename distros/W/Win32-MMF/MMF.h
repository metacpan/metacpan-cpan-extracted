#ifndef __MMF_H
#define __MMF_H

typedef struct MMF_MANAGER {
	int    debug;
} MMF_MANAGER;


/* structure used to hold current MMF information */

typedef struct MMF_DESCRIPTOR {
    long m_mmf_size;    // size of the MMF in bytes
    long m_var_count;   // number of variables held in the MMF
    long m_heap_bot;    // offset to the bottom of the heap
    long m_heap_top;    // offset to the top of the heap
    long m_kbrk;        // offset to the watermark
} MMF_DESCRIPTOR;


/* structure used to hold definition for one variable */

typedef struct MMF_VAR {
    char v_name[32];    // variable name has to be less than 32 bytes
    long v_type;        // type of the variable held
    long v_data;        // LONG if IV, otherwise offset to variable
    long v_size;        // size of the data
} MMF_VAR;


/* structure used my malloc */

typedef struct MMF_MAP
{
    unsigned long   size;
    unsigned long   next;   // offset to the next block
    unsigned long   magic;
    unsigned long   used;
} MMF_MAP;


#define	MALLOC_MAGIC	0x6D92


#endif

