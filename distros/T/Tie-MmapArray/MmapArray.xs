/* $Id: MmapArray.xs,v 1.6 1999/12/28 10:13:32 andrew Exp $
 *
 * Copyright 1999, Ford & Mason Ltd
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 *
 * Note: the initial Windows code was supplied by Reini Urban
 * <rurban@x-ray.at>.  I do not have the facilities to test the module
 * under Windows, but I am willing to include #ifdef'ed code for that
 * platform.  (Andrew)
 */


/* Uncomment the following line, or define the symbol on the compiler
 * command line, for copious debugging trace messages
 */

/* #define DEBUG_TRACING  */


/*
 * Standard XS greeting.
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <sys/stat.h>

#ifndef _WIN32
#include <sys/mman.h>
#include <unistd.h>
#else
#include <winbase.h>
#endif

#include <fcntl.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>


#ifndef MMAP_RETTYPE
#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 199309
#endif
#ifdef _POSIX_VERSION
#if _POSIX_VERSION >= 199309
#define MMAP_RETTYPE void *
#endif
#endif
#endif


#ifndef MMAP_RETTYPE
#define MMAP_RETTYPE caddr_t
#endif

#ifndef MAP_FAILED
#define MAP_FAILED ((caddr_t)-1)
#endif


#define INLINE inline


/* Determine whether 64 bit integers are supported */

#if (defined(HAVE_LONGLONG) ||                        \
    (defined(_MSC_VER) && defined(MAXLONGLONG) ) ||   \
    (!defined(__STRICT_ANSI__) &&                     \
       (__GNUC__ == 2) && (__GNUC_MINOR__ >= 8) ))
  #define HAVE_QUAD_INTS
#endif
 
#ifdef HAVE_QUAD_INTS
  #ifdef _MSC_VER
    typedef __int64 		QUAD_INT_T;
    typedef unsigned __int64 	UQUAD_INT_T;
  #else
    typedef long long 		QUAD_INT_T;
    typedef unsigned long long  UQUAD_INT_T;
  #endif
#endif



/* Some machines require integers and floating point numbers to be
 * properly aligned when accessed, however if there are odd-sized
 * fields in a structured record then the numbers may not be aligned
 * correctly.  Memcpy'ing the value into an auto variable will ensure
 * alignment, and given the subroutine call and other overheads, the
 * extra overhead should be negligable.
 */

#if !defined(i386)  /* Intel x86 processors do not require strict alignment */
#define FORCE_ALIGNMENTS
#endif


#if defined(FORCE_ALIGNMENTS)
#define SET_VAL(type, ptr, val)   do { memcpy((void *)ptr, (void *)&val, sizeof (type) } while (0)
#define SET_VAL(type, ptr, val)   do { memcpy((void *)&val, (void *)ptr, sizeof (type) } while (0)
#else
#define SET_VAL(type, ptr, val)   do { *(type *)ptr = val; } while (0)
#define GET_VAL(type, ptr, val)   do { val = *(type *)ptr; } while (0)
#endif


#if defined(DEBUG_TRACING)
static void
__trace_fn(char *fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    if (fmt[strlen(fmt)-1] != '\n') {
	fputc('\n', stderr);
    }
    va_end(ap);
}
#define TRACE(s)	do { __trace_fn s; } while (0)
#define ASSERT(l, e)	if (!e) { croak("%s: assertion failed: %s", l, #e); } else 
#else
#define TRACE(s)
#define ASSERT(l, s)
#endif



#define ABORT_CONSTRUCTOR(a, m)	do { free_mmaparray_resources(a); croak m; } while (0)




#define SUBARRAY_PTR_CLASS	"Tie::MmapArray::SubArrayPtr"
#define SUBHASH_PTR_CLASS	"Tie::MmapArray::SubHashPtr"





/* Descriptor structures for the main mmap'ed array and sub-array or
 * sub-hash fields.  The sub-fields are described by an array of these
 * fields pointed to in the parent structure.  
 *
 * Note that the first five fields are identical in all three
 * structures, so they can be used interchangably when dealing with an
 * arbitraty element.  The fifth field (offset) is not actually used
 * in the top-level structure (by definition it will always be zero).
 */

#define ARRAY_FIELDS        '['
#define HASH_FIELDS         '{'
#define DEFAULT_TYPE	    'i'
#define DEFAULT_TYPE_SIZE   sizeof(int)


typedef struct {
    char	    eltype;
    size_t	    elsize;
    int		    nfields;
    void	    *fields;
    int		    offset;

    int		    nels;

    MMAP_RETTYPE    addr;

    char	    *filename;
    int		    fd;
    unsigned int    readonly   : 1;
    unsigned int    extendable : 1;
    off_t	    file_offset;
    struct stat     stat_buf;
    int		    refcnt;
} 
Tie__MmapArray;

typedef struct {
    char	    eltype;
    size_t	    elsize;
    int		    nfields;
    void	    *fields;
    int		    offset;
}
ARRAY_ELEMENT_T;

typedef struct {
    char	    eltype;
    size_t	    elsize;
    int		    nfields;
    void	    *fields;
    int		    offset;
    char	    *key;
}
HASH_ELEMENT_T;

typedef ARRAY_ELEMENT_T  ELEMENT_T;



/* Descriptor structures for sub-array and sub-hash references, passed
 * back to perl when asked for $array[$n] in code like
 * $array[$n]->[$m] or $array[$n]->{$key} (or more nested structures). 
 *
 * The descriptors are converted to a Perl reference and passed to the
 * FETCH/STORE/DELETE subroutines.  They contain sufficient
 * information to access both a sub-structure element and the main
 * mmap'ed array.  The descriptor structures are identical exept for
 * the type of the field pointer so they can be handled by common
 * functions. 
 */

typedef struct subarray {
    Tie__MmapArray  *array;
    ARRAY_ELEMENT_T *fields;
    int		    nfields;
    int		    recno;
    int		    cur_index;
}
Tie__MmapArray__SubArray;

typedef struct {
    Tie__MmapArray  *array;
    HASH_ELEMENT_T  *fields;
    int		    nfields;
    int		    recno;
    int		    cur_index;
}
Tie__MmapArray__SubHash;
    

/* Subrecord structure (doesn't matter which variety as it will be
 * cast when used).
 */
typedef struct subarray  SUBRECORD_REFERENCE_T;


/* Forward declarations */

static void	free_mmaparray_resources(Tie__MmapArray *);
static void	free_array_field_descriptor(ARRAY_ELEMENT_T *, int);
static void	free_hash_field_descriptor(HASH_ELEMENT_T *, int);
static HASH_ELEMENT_T *lookup_key(HASH_ELEMENT_T *, int, char *);
static int	parse_field_desc_array(Tie__MmapArray *, ELEMENT_T *, int, AV *);
static int	parse_field_desc_string(Tie__MmapArray *, ELEMENT_T *, int, char *);


#if defined(DEBUG_TRACING)
static void     print_array_field_structure(ARRAY_ELEMENT_T *, int, int);
static void     print_hash_field_structure(HASH_ELEMENT_T *, int, int);


static void
print_mmaparray_structure(Tie__MmapArray *array)
{
    TRACE(("filename: \"%s\" [%p]", array->filename, array->filename));
    TRACE(("addr:     %p", array->addr));
    TRACE(("nels:     %d", array->nels));
    TRACE(("refcnt:   %d", array->refcnt));
    TRACE(("elsize:   %d", array->elsize));
    TRACE(("eltype:   '%c' [%d]", array->eltype, array->eltype));
    TRACE(("nfields:  %d", array->nfields));
    TRACE(("fields:   %p", array->fields));
    if (array->eltype == ARRAY_FIELDS) {
        print_array_field_structure(array->fields, array->nfields, 1);
    }
    else if (array->eltype == HASH_FIELDS) {
        print_hash_field_structure(array->fields, array->nfields, 1);
    }
}

static void
print_array_field_structure(ARRAY_ELEMENT_T *fields, int nfields, int level)
{
    int		i;

    for (i = 0; i < nfields; i++) {
	TRACE(("%*s%i: %4d '%c' %4d %p %2d", level * 2, "", i, 
	       fields[i].offset,
	       fields[i].eltype,
	       fields[i].elsize,
	       fields[i].fields,
	       fields[i].nfields));
	if (fields[i].eltype == ARRAY_FIELDS) {
	    print_array_field_structure(fields[i].fields, fields[i].nfields, level+1);
	}
	else if (fields[i].eltype == HASH_FIELDS) {
	    print_hash_field_structure(fields[i].fields, fields[i].nfields, level+1);
	}
    }	
}
static void
print_hash_field_structure(HASH_ELEMENT_T *fields, int nfields, int level)
{
    int		i;

    for (i = 0; i < nfields; i++) {
	TRACE(("%*s%i: %4d '%c' %4d %p %2d [%p] \"%s\"", level * 2, "", i, 
	       fields[i].offset,
	       fields[i].eltype,
	       fields[i].elsize,
	       fields[i].fields,
	       fields[i].nfields,
	       fields[i].key,
	       fields[i].key));
	if (fields[i].eltype == ARRAY_FIELDS) {
	    print_array_field_structure(fields[i].fields, fields[i].nfields, level+1);
	}
	else if (fields[i].eltype == HASH_FIELDS) {
	    print_hash_field_structure(fields[i].fields, fields[i].nfields, level+1);
	}
    }	
}
#endif


/* TIEARRAY constructor (included as a separate function to avoid
 * confusing xsubpp with #ifdefs)
 */
INLINE Tie__MmapArray *
tie_mmaparray(SV *file, SV *href)
{
    Tie__MmapArray 	*array;
    char		*filename;
    HV			*href_hv;
    SV			**hent_sv_ptr;
    char		*template;
    STRLEN		len;

    TRACE(("Tie::MmapArrray::TIEARRAY(file=%p, href=%p)", file, href));

    Newz(0, array, 1, Tie__MmapArray);
    if (!array) {
        ABORT_CONSTRUCTOR(array, ("out of memory\n"));
    }
    
    /* Check out the filename */
    
    if (!SvPOK(file)) {
        ABORT_CONSTRUCTOR(array, ("$file must be a string"));
    }

    SvGROW(file, SvCUR(file) + 1);
    filename = SvPV(file, len);
    filename[len] = '\0';

    if (len == 0) {
	ABORT_CONSTRUCTOR(array, ("$file must not be an empty string"));
    }


    New(0, array->filename, len + 1, char);
    strncpy(array->filename, filename, len+1);

    TRACE(("Tie::MmapArrray::TIEARRAY filename=\"%s\"", array->filename));


    /* Check out the parameter href.  This may be null, a "pack"
     * template string, or a hash of options (which may contain a pack
     * template in the "template" element.
     */

    if (href == &PL_sv_undef) {
	array->eltype = DEFAULT_TYPE;
	array->elsize = DEFAULT_TYPE_SIZE;
    }
    else if (!SvROK(href)) {
	if (SvPOK(href)) {
	    /* ensure that the field description is nul-terminated */
	    SvGROW(href, SvCUR(href) + 1);	
	    template = SvPV(href, len);
	    template[len] = '\0';
	    array->elsize = parse_field_desc_string(array, (ELEMENT_T *)array, 0, template);
	}
	else {
	    ABORT_CONSTRUCTOR(array, ("$href must be a hash reference"));
	}
    }
    else {
	if (SvTYPE(href_hv = (HV *)SvRV(href)) != SVt_PVHV) {
	    ABORT_CONSTRUCTOR(array, ("$href must be a hash reference"));
	}


	/* Check the hash entries */
	
	if ((hent_sv_ptr = hv_fetch(href_hv, "template", 8, 0))) {
	    if (SvROK(*hent_sv_ptr) && SvTYPE(SvRV(*hent_sv_ptr)) == SVt_PVAV) {
		array->elsize = parse_field_desc_array(array, (ELEMENT_T *)array, 0,
						       (AV*)(SvRV(*hent_sv_ptr)));
	    }
	    else if (SvPOK(*hent_sv_ptr)) {
		SvGROW(*hent_sv_ptr, SvCUR(*hent_sv_ptr) + 1);
		template = SvPV(*hent_sv_ptr, len);
		template[len] = '\0';
		array->elsize = parse_field_desc_string(array, (ELEMENT_T *)array, 0, template);
	    }
	    else {
		ABORT_CONSTRUCTOR(array, ("$href->{eltype} not a string"));
	    }
	}
	else {
	    array->eltype = DEFAULT_TYPE;
	    array->elsize = DEFAULT_TYPE_SIZE;
	}

	if ((hent_sv_ptr = hv_fetch(href_hv, "nels", 4, 0))) {
	    if (!SvIOK(*hent_sv_ptr)) {
		ABORT_CONSTRUCTOR(array, ("$href->{nels} not an integer"));
	    }
	    array->nels = SvIV(*hent_sv_ptr);
	    TRACE(("Tie::MmapArrray::TIEARRAY nels=%d", array->nels));
	}
	
	if ((hent_sv_ptr = hv_fetch(href_hv, "offset", 4, 0))) {
	    if (!SvIOK(*hent_sv_ptr)) {
	    ABORT_CONSTRUCTOR(array, ("$href->{offset} not an integer"));
	    }
	    array->file_offset = SvIV(*hent_sv_ptr);
	    TRACE(("Tie::MmapArrray::TIEARRAY offset=%d", array->file_offset));
	}
	
	if ((hent_sv_ptr = hv_fetch(href_hv, "mode", 4, 0))) {
	    if (!SvPOK(*hent_sv_ptr)) {
		ABORT_CONSTRUCTOR(array, ("$href->{mode} not a string"));
	    }
	    SvGROW(*hent_sv_ptr, SvCUR(*hent_sv_ptr) + 1);
	    if (strEQ(SvPV(*hent_sv_ptr, len), "ro")) {
		array->readonly = 1;
	    }
	}

	if ((hent_sv_ptr = hv_fetch(href_hv, "extendable", 4, 0))) {
	    if (!SvPOK(*hent_sv_ptr)) {
		ABORT_CONSTRUCTOR(array, ("$href->{mode} not a string"));
	    }
	    SvGROW(*hent_sv_ptr, SvCUR(*hent_sv_ptr) + 1);
	    if (strEQ(SvPV(*hent_sv_ptr, len), "ro")) {
		array->extendable = 1;
	    }
	}
    }


    if (array->elsize == 0) {
	ABORT_CONSTRUCTOR(array, ("invalid zero length element size"));
    }

    /* open the file */

    if ((array->fd = open(filename, array->readonly ? O_RDONLY : O_RDWR, 0644)) < 0) {
	ABORT_CONSTRUCTOR(array, ("cannot open \"%s\"", filename));
    }
    if (fstat(array->fd, &array->stat_buf) < 0) {
	ABORT_CONSTRUCTOR(array, ("cannot stat \"%s\"", filename));
    }
    if (!S_ISREG(array->stat_buf.st_mode)) {
	ABORT_CONSTRUCTOR(array, ("\"%s\" is not a regular file", filename));
    }



    /* Determine the size of the array (extending the file if necessary)
       (use ftruncate if available)   */

    if (array->nels == 0) {
	array->nels = (array->stat_buf.st_size - array->file_offset) / array->elsize;
    }
    else if (array->nels * array->elsize + array->file_offset
	     > array->stat_buf.st_size) {
	if (lseek(array->fd,
		  array->nels * array->elsize + array->file_offset - 1,
		  SEEK_SET) < 0 ||
	    write(array->fd, "\000", 1) < 1) {
	    ABORT_CONSTRUCTOR(array, ("cannot extend file"));
	}
	array->stat_buf.st_size = array->nels * array->elsize;
    }


    /* Mmap the file (or perform similar gyrations under Windows) */

 #ifndef _WIN32
    array->addr = mmap(0, array->stat_buf.st_size,
		       array->readonly ? PROT_READ : PROT_READ|PROT_WRITE,
		       MAP_SHARED,
		       array->fd, array->file_offset);
    if (array->addr == MAP_FAILED) {
	ABORT_CONSTRUCTOR(array, ("mmap failed"));
    }
 #else
    array->addr = (HANDLE) CreateFileMapping(
                        (HANDLE) array->fd,
                        NULL,                   /* lpSecurityDescriptor */
                        PAGE_READWRITE,
			0,                      /* where to start, hi+low words */
			0,
			NULL                    /* lpName */
                    );

    /* check duplicate handles */

    if (array->addr != NULL && GetLastError() == ERROR_ALREADY_EXISTS) {
        CloseHandle(array->addr);
        array->addr = NULL;
    }
    if (array->addr == NULL) {
         ABORT_CONSTRUCTOR(array, ("mmap failed"));
    }
    array->addr = (LPVOID) MapViewOfFile(
                        array->addr,
			FILE_MAP_ALL_ACCESS,
			0,                          /* dwMaximumSizeHigh */
			0,                          /* dwMaximumSizeLow */
			array->stat_buf.st_size    /* wNumberOfBytesToMap */
    );
    if (array->addr == NULL) {
         ABORT_CONSTRUCTOR(array, ("mmap failed"));
    }
 #endif
     

    TRACE(("Tie::MmapArrray::TIEARRAY addr=%p", array->addr));
 #if defined(DEBUG_TRACING)
    print_mmaparray_structure(array);
 #endif

    /* Initialize the reference count */

    array->refcnt = 1;

    TRACE(("Tie::MmapArrray::TIEARRAY returns %p", array));

    return array;
}

/* Destructor for MmapArray.
 * Only frees resources if the reference count reaches zero.
 * Frees any sub-record structures, unmaps and closes the file, frees
 * the filename and then the descriptor itself.
 */
static void
free_mmaparray_resources(Tie__MmapArray *array)
{
    TRACE(("free_mmaparray_resources(%p) refcnt = %d", array, array->refcnt));

    if (array && --array->refcnt <= 0) {

	TRACE(("free_mmaparray_resources() freeing resources"));

	if (array->eltype == ARRAY_FIELDS) {
	    free_array_field_descriptor(array->fields, array->nfields);
	}
	else if (array->eltype == HASH_FIELDS) {
	    free_hash_field_descriptor(array->fields, array->nfields);
	}
	if (array->addr) {
#ifndef _WIN32
	    munmap(array->addr, array->stat_buf.st_size);
#else
	    UnmapViewOfFile(array->addr);
#endif
	}
	if (array->fd > 0) {
	    close(array->fd);
	}
	if (array->filename) {
	    Safefree(array->filename);
	}
	Safefree(array);
    }
}


static void
free_array_field_descriptor(ARRAY_ELEMENT_T *afields, int nfields)
{
    TRACE(("free_array_field_descriptor(%p, $d)", afields, nfields));

    if (afields) {
	ARRAY_ELEMENT_T *ap = afields + nfields;

	while (--ap >= afields) {
	    if (ap->eltype == HASH_FIELDS) {
		free_hash_field_descriptor(ap->fields, ap->nfields);
	    }
	    else if (ap->eltype == ARRAY_FIELDS) {
		free_array_field_descriptor(ap->fields, ap->nfields);
	    }
	}
	Safefree(afields);
    }
}


static void
free_hash_field_descriptor(HASH_ELEMENT_T *hfields, int nfields)
{
    TRACE(("free_hash_field_descriptor(%p, %d)", hfields, nfields));

    if (hfields) {
	HASH_ELEMENT_T *hp;

	for (hp = hfields; nfields-- > 0; hp++) {
	    if (hp->key) {
		Safefree(hp->key);
	    }
	    if (hp->eltype == HASH_FIELDS) {
		free_hash_field_descriptor(hp->fields, hp->nfields);
	    }
	    else if (hp->eltype == ARRAY_FIELDS) {
		free_array_field_descriptor(hp->fields, hp->nfields);
	    }
	}
	Safefree(hfields);
    }
}


/* Parse field descriptor.
 */
static int
parse_field_desc_array(Tie__MmapArray   *array,
		       ELEMENT_T        *field,
		       int	        offset,
		       AV               *desc_array)
{
    HASH_ELEMENT_T  *subfields;
    int	   	    nfields;
    int    	    i, j;
    SV              **p_name;
    SV              **p_template;
    char	    *name;
    char	    *template;
    STRLEN	    len;
    int		    elsize = 0;

    TRACE(("parse_field_desc_array(%p, %p, %d, %p)",
	 array, field, offset, desc_array));
    ASSERT("parse_field_desc_array", SvTYPE(desc_array) == SVt_PVAV);

    /* Get the array length and ensure it is a non-zero multiple of two */

    nfields = 1 + av_len(desc_array);
    if (nfields == 0) {
	ABORT_CONSTRUCTOR(array, ("zero length array of fields"));
    }
    if (nfields % 2) {
	ABORT_CONSTRUCTOR(array, ("odd length array of fields (%d)", nfields));	
    }
    nfields /= 2;


    /* Allocate the subfield array and fill in the pointers in the current field */

    Newz(0, subfields, nfields, HASH_ELEMENT_T);
    if (!subfields) {
        ABORT_CONSTRUCTOR(array, ("out of memory\n"));
    }

    TRACE(("parse_field_desc_array  allocated %p-%p",
	   subfields, subfields + nfields));

    field->eltype  = HASH_FIELDS;
    field->fields  = subfields;
    field->nfields = nfields;

    /* Parse the names and descriptions of the individual fields */

    for (i = 0, j = 0; i < nfields; i++) {
	p_name = av_fetch(desc_array, j++, 0);
	p_template = av_fetch(desc_array, j++, 0);
	if (p_name == NULL || p_template == NULL || !SvPOK(*p_name)) {
	    ABORT_CONSTRUCTOR(array, ("invalid field description array element"));
	}
	SvGROW(*p_name, SvCUR(*p_name) + 1);
	name = SvPV(*p_name, len);
	name[len] = '\0';

	Newz(0, subfields[i].key, len + 1, char);
	strncpy(subfields[i].key, name, len+1);
	subfields[i].key[len] = '\0';
	subfields[i].offset   = offset + elsize;
	
	if (lookup_key(subfields, i, name)) {
	    ABORT_CONSTRUCTOR(array, ("duplicate field name"));
	}	    

	TRACE(("parse_field_desc_array  field %d is \"%s\"", i, name));

	if (SvPOK(*p_template)) {
	    SvGROW(*p_template, SvCUR(*p_template) + 1);
	    template = SvPV(*p_template, len);
	    template[len] = '\0';
	    elsize += parse_field_desc_string(array, (ELEMENT_T *)&subfields[i], 
					      offset + elsize, template);
	}
	else if (SvROK(*p_template) && SvTYPE(SvRV(*p_template)) == SVt_PVAV) {
	    elsize += parse_field_desc_array(array, (ELEMENT_T *)&subfields[i],
					     offset + elsize, (AV*)SvRV(*p_template));
	}
	else {
	    ABORT_CONSTRUCTOR(array, ("invalid field description array element"));
	}
    }
    field->elsize = elsize;

    return elsize;
}



static int
parse_field_desc_string(Tie__MmapArray  *array,
			ELEMENT_T       *field,
			int	   	offset,
			char            *template)
{
    ARRAY_ELEMENT_T	*subfields;
    int			elsize    = 0;
    int			totalsize = 0;
    int			nfields   = 0;
    char		*p;
    char 		*endp = template + strlen(template);
    char		ch;
    int			val;

    TRACE(("parse_field_desc_string(array=%p, field=%p, offset=%d, template=\"%s\")",
	   array, field, offset, template));


    /* Determine the number of fields described by the string */

    for (p = template; p < endp; nfields++) {
	ch = *p++;
	if (p < endp && isdigit(*p)) {
	    val = strtol(p, &p, 10);
	    if (toupper(ch) != 'A' && ch != 'Z') {
		nfields += val - 1;
	    }
	}
    }


    /* If the pack string describes more than one field create an array field */

    if (nfields == 0) {
	ABORT_CONSTRUCTOR(array, ("invalid pack string \"%s\"", template));
    }
    else if (nfields == 1) {
	subfields = field;
    }
    else {
	Newz(0, subfields, nfields, ARRAY_ELEMENT_T);
	if (!subfields) {
	    ABORT_CONSTRUCTOR(array, ("out of memory\n"));
	}
	field->eltype  = ARRAY_FIELDS;
	field->fields  = subfields;
	field->nfields = nfields;
    }


    /* Process the field descriptors */

    for (p = template; p < endp; ) {
	ch = *p++;
	if (p < endp && isdigit(*p)) {
	    nfields = strtol(p, &p, 10);
	}
	else {
	    nfields = 1;
	}
    
	/* Check out the element type */
    
	if (toupper(ch) == 'A' || ch == 'Z') {
	    elsize  = nfields;
	    nfields = 1;
	}
	else {
	    switch (ch) {
	    case 'c': case 'C': 
		elsize = sizeof(char);
		break;

	    case 's': case 'S': case 'n': case 'v':
		elsize = sizeof(short);
		break;

	    case 'i': case 'I':
		elsize = sizeof(int);
		break;
		
	    case 'l': case 'L': case 'N': case 'V':
		elsize = sizeof(long);
		break;
		
#if defined(HAVE_QUAD_INTS)	
	    case 'q': case 'Q':
		elsize = sizeof(QUAD_INT_T);
		break;
#endif
		
	    default:
		ABORT_CONSTRUCTOR(array, ("unknown element type '%c'", ch));
	    }
	}
	while (nfields--) {
	    subfields->eltype = ch;
	    subfields->elsize = elsize;
	    subfields->offset = offset + totalsize;
	    totalsize += elsize;
	    subfields++;
	}
    }    
    return totalsize;
}

/* Look-up a key in a sub-hash.
 * Currently performs a simple linear lookup.
 */
static HASH_ELEMENT_T *
lookup_key(HASH_ELEMENT_T   *fields,
	   int		    nfields,
	   char		    *key)
{
    if (nfields) {
	while (nfields--) {
	    if (strEQ(fields->key, key)) {
		return fields;
	    }
	    fields++;
	}
    }
    return NULL;
}

/* Fetch a subrecord reference. 
 * Allocates and initializes a subrecord structure.
 * Increments the reference count of the main array
 * Blesses the subrecord to the appropriate type.
 * Creates and returns a tied hash or array.
 */
SV *
fetch_subrecord_reference(Tie__MmapArray    *array,
			  int		    recno, 
			  char	    	    eltype,
			  void              *fieldp,
			  int		    nfields)
{
    SUBRECORD_REFERENCE_T   *subrec;
    SV			    *sv;
    SV			    *rv;
    SV			    *tied;
    
    TRACE(("fetch_subrecord_reference(%p, %d, '%c', %p, %d)",
	   array, recno, isascii(eltype) ? eltype : '?', fieldp, nfields));

    /* Allocate a subrecord structure */

    New(0, subrec, 1, SUBRECORD_REFERENCE_T);
    if (!subrec) {
	croak("out of memory");
    }

    /* Initialize the subrecord structure */

    subrec->array   = array;
    subrec->recno   = recno;
    subrec->fields  = fieldp;
    subrec->nfields = nfields;

    /* Increment the reference count of the main array */

    array->refcnt++;

    /* Create and return a tied hash or array */
    /* Bless the subrecord to the appropriate type */

    sv = newSViv((int)subrec);
    rv = newRV_noinc(sv);
	    
    if (eltype == ARRAY_FIELDS) {
	sv_bless(rv, gv_stashpv(SUBARRAY_PTR_CLASS, TRUE));
	tied = (SV *)newAV();
    }
    else {
	sv_bless(rv, gv_stashpv(SUBHASH_PTR_CLASS, TRUE));
	tied = (SV *)newHV();
	subrec->cur_index = 0;
    }

    hv_magic((HV*)tied, (GV*)rv, 'P');
    return newRV_noinc((SV*)tied);
}

/* Fetch a value from a specified address in the mmaped file according
 * to the element type (sub-arrays and sub-hashes are handled
 * elsewhere).
 */
SV *
fetch_value(void *recaddr, char eltype, int elsize) 
{
    SV			*sv;
    STRLEN		len;
    char        	*strval;
    char		*endp;
    int			intval;        
    unsigned int	uintval;        
    short		shortval;
    unsigned short	ushortval;
    long		longval;
    unsigned long       ulongval;
    float		floatval;
    double		doubleval;
#ifdef HAVE_QUAD_INTS
    QUAD_INT_T		quadval;
    UQUAD_INT_T         uquadval;
#endif
	
    TRACE(("fetch_value(%p, '%c', %d)", recaddr, isascii(eltype) ? eltype : '?', elsize));

    switch (eltype) {
    case 'A':
	for (strval = (char *)recaddr + elsize - 1; strval >= (char *)recaddr; strval--) {
	    if (*strval && *strval != ' ') {
		elsize = 1 + strval - (char *)recaddr;
		break;
	    }
	}
	sv = newSVpvn(recaddr, elsize);
	SvGROW(sv, elsize + 1);
	strval = SvPV(sv, len);
	strval[len] = '\0';
	return sv;
	
    case 'Z':
	for (strval = (char *)recaddr, endp = (char *)recaddr + elsize; strval < endp; strval++) {
	    if (*strval == '\0') {
		elsize = strval - (char *)recaddr;
		break;
	    }
	}
	sv = newSVpvn(recaddr, elsize);
	SvGROW(sv, elsize + 1);
	strval = SvPV(sv, len);
	strval[len] = '\0';
	return sv;

    case 'a':
	return newSVpvn(recaddr, elsize);
	    
    case 'c':
	return newSViv((int) *(signed char *) recaddr);
	    
    case 'C':
	return newSViv((unsigned int) *(unsigned char *)  recaddr);
	
    case 'n':
	GET_VAL(unsigned short, recaddr, ushortval);
	return newSViv((unsigned int)ntohs(ushortval));
	
    case 's':
	GET_VAL(short, recaddr, shortval);
	return newSViv((int)shortval);
	
    case 'S':
	GET_VAL(unsigned short, recaddr, ushortval);
	return newSViv((unsigned int)ushortval);
	
    case 'i':
	GET_VAL(int, recaddr, intval);
	return newSViv(intval);
	
    case 'I':
	GET_VAL(unsigned int, recaddr, uintval);
	return newSViv(uintval);
	
    case 'l':
	GET_VAL(long, recaddr, longval);
	return newSViv(longval);
	
    case 'L':
	GET_VAL(unsigned long, recaddr, ulongval);
	return newSViv(ulongval);
	
    case 'N':
	GET_VAL(unsigned long, recaddr, ulongval);
	return newSViv((unsigned long)ntohl(ulongval));

#if defined(HAVE_QUAD_INTS)	
    case 'q':
	GET_VAL(QUAD_INT_T, recaddr, quadval);
	return newSVnv((double) quadval);
	
    case 'Q':
	GET_VAL(UQUAD_INT_T, recaddr, uquadval);
#ifdef _MSC_VER
        /* msvc <= 6 cannot coerce ulonglong to double, only signed */
	return newSVnv((double)(QUAD_INT_T)uquadval);
#else
	return newSVnv((double) uquadval);
#endif
#endif
	
    case 'f':
	GET_VAL(float, recaddr, floatval);
	return newSVnv((double) floatval);
	
    case 'd':
	GET_VAL(double, recaddr, doubleval);
	return newSVnv(doubleval);
	
    default:
	croak("internal error (FETCH: case %d not handled)", eltype);
    }
}

/* Store a value at a specified address in the mmaped file according
 * to the element type.
 */
SV *
store_value(void *recaddr, char eltype, int elsize, SV *value) 
{
    STRLEN		len;
    char        	*strval;
    signed char		charval;
    unsigned char	ucharval;
    int			intval;        
    unsigned int	uintval;        
    short		shortval;
    unsigned short	ushortval;
    long		longval;
    unsigned long       ulongval;
    float		floatval;
    double		doubleval;
#ifdef HAVE_QUAD_INTS
    long long		quadval;
    unsigned long long  uquadval;
#endif

    TRACE(("store_value(%p, %d, %d, %p)", recaddr, eltype, elsize, value));

    switch (eltype) {
    case 'a':
    case 'A':
    case 'Z':
	strval = SvPV(value, len);
	if (len > elsize) {
	    len = elsize;
	}
	Copy(strval, recaddr, len, char);
	if (len < elsize) {
	    if (eltype == 'a') {
		Zero(recaddr + len, elsize - len, char);
	    }
	    else {
		memset(recaddr + len, ' ', elsize - len);
	    }
	}
	return newSVpvn(recaddr, elsize);

    case 'c':
	charval = (signed char)SvIV(value);
	*(signed char *)recaddr = charval;
	return newSViv((int) charval);

    case 'C':
	ucharval = (unsigned char)SvIV(value);
	*(unsigned char *)recaddr = ucharval;
	return newSViv((unsigned int) ucharval);

    case 's':
	shortval = (short)SvIV(value);
	SET_VAL(short, recaddr, shortval);
	return newSViv((int) shortval);
	
    case 'S':
	ushortval = (unsigned short)SvIV(value);
	SET_VAL(unsigned short, recaddr, ushortval);
	return newSViv((unsigned int) ushortval);
	
    case 'i':
	intval = (int)SvIV(value);
	SET_VAL(int, recaddr, intval);
	return newSViv((int) intval);

    case 'I':
	uintval = (unsigned int)SvIV(value);
	SET_VAL(unsigned int, recaddr, uintval);
	return newSViv((unsigned int) uintval);

    case 'l':
	longval = (long)SvIV(value);
	SET_VAL(long, recaddr, intval);
	return newSViv(longval);

    case 'L':
	ulongval = (unsigned long)SvIV(value);
	SET_VAL(unsigned long, recaddr, ulongval);
	return newSViv(ulongval);
	
#if defined(HAVE_QUAD_INTS)	
    case 'q':
	quadval = (QUAD_INT_T)SvNV(value);
	SET_VAL(QUAD_INT_T, recaddr, quadval);
	return newSVnv((double)quadval);
	
    case 'Q':
	uquadval = (UQUAD_INT_T)SvNV(value);
	SET_VAL(UQUAD_INT_T, recaddr, uquadval);
#ifdef _MSC_VER
        /* msvc <= 6 cannot coerce ulonglong to double, only signed */
	return newSVnv((double)(QUAD_INT_T)uquadval);
#else
	return newSVnv((double)uquadval);
#endif
#endif
	
    case 'f':
	floatval = (float)SvNV(value);
	SET_VAL(float, recaddr, floatval);
	return newSVnv(floatval);
	
    case 'F':
	doubleval = (double)SvNV(value);
	SET_VAL(double, recaddr, doubleval);
	return newSVnv(doubleval);
	
    case ARRAY_FIELDS:
    case HASH_FIELDS:
	croak("cannot change element structure");

    default:
	croak("internal error (STORE: case %d not handled)", eltype);
    }
}


/* START OF XSUBS */

MODULE = Tie::MmapArray		PACKAGE = Tie::MmapArray


#   tie @array, 'Tie::MmapArray', $filename, { eltype => "i",
#                                              nels   => 0,
#				               mode   => "rw",
#					       shared => 1,
#					       offset => 0 };

Tie::MmapArray *
TIEARRAY(class, file, href = &PL_sv_undef)
    char *          class
    SV *            file
    SV *            href

 CODE:
    RETVAL = tie_mmaparray(file, href);

 OUTPUT:
    RETVAL



# Module for the tied array and its elements


MODULE = Tie::MmapArray		PACKAGE = Tie::MmapArrayPtr

void
FETCH(array, index, ...)
    Tie::MmapArray *	array
    int  		index

 PROTOTYPE: $$;$

 ALIAS:
    STORE = 1

 PREINIT:
    void 		    *recaddr;
    char	    	    eltype;
    int			    elsize;

 PPCODE:
    if (index  < 0 || index >= array->nels) {
	croak("invalid index");
    }
    eltype = array->eltype;
    elsize = array->elsize;

    recaddr = array->addr + (index * elsize);

    /* FETCH */

    if (ix == 0) {
	TRACE(("Tie::MmapArrray::FETCH(array=%p, index==%d)", array, index));

	switch (eltype) {
	case ARRAY_FIELDS:
	case HASH_FIELDS:
	    ST(0) = fetch_subrecord_reference(array, index, eltype,
					      array->fields, array->nfields);
	    break;

	default:
	    ST(0) = fetch_value(recaddr, eltype, elsize);
	}
    }

    /* STORE */

    else {
	TRACE(("Tie::MmapArrray::STORE(array=%p, index==%d, value=%p)", array, index, ST(3)));

	if (array->readonly) {
	    croak("array is read-only");
	}

	ST(0) = store_value(recaddr, eltype, elsize, ST(3));
    }

    sv_2mortal(ST(0));
    XSRETURN(1);



long
FETCHSIZE(array)
	Tie::MmapArray *	array

 PROTOTYPE: $

 CODE:
    RETVAL = array->nels;

 OUTPUT:
    RETVAL


long
record_size(array)
	Tie::MmapArray *	array

 PROTOTYPE: $

 CODE:
    RETVAL = array->elsize;

 OUTPUT:
    RETVAL




void
STORESIZE(array, newsize)
	Tie::MmapArray *	array
	long			newsize

 PROTOTYPE: $$

 PPCODE:
    croak("not yet implemented\n");



void
EXTEND(array, newsize)
	Tie::MmapArray *	array
	long			newsize

 PROTOTYPE: $$

 PPCODE:
    if (!array->extendable) {
        croak("not allowed\n");
    }
    else {
        croak("not yet implemented\n");
    }


void
DESTROY(var)
	Tie::MmapArray *	var

 PROTOTYPE: $

 CODE:
    free_mmaparray_resources(var);


########################################################################
#
# SUB ARRAYS
#
########################################################################

MODULE = Tie::MmapArray		PACKAGE = Tie::MmapArray::SubArrayPtr


void
FETCH(subarray, index, ...)
    Tie::MmapArray::SubArray *	subarray
    int  		        index

 PROTOTYPE: $$;$

 ALIAS:
    STORE = 1

 PREINIT:
    Tie__MmapArray  *array;
    ARRAY_ELEMENT_T *afield;
    void 	    *recaddr;
    int		     recno;
    int		     offset;
    char	     eltype;
    int              elsize;

 PPCODE:
    if (index < 0 || index >= subarray->nfields) {
	croak("invalid index");
    }
    afield = subarray->fields + index;
    eltype = afield->eltype;
    elsize = afield->elsize;
    offset = afield->offset;
    recno  = subarray->recno;
    array  = subarray->array;

    recaddr = array->addr + (recno * array->elsize) + offset;

    /* FETCH */

    if (ix == 0) {
	switch (eltype) {
	case ARRAY_FIELDS:
	case HASH_FIELDS:
	    ST(0) = fetch_subrecord_reference(array, recno, eltype, 
					      afield->fields, afield->nfields);
	    break;

	default:
	    ST(0) = fetch_value(recaddr, eltype, elsize);
	}
    }

    /* STORE */

    else {
	if (array->readonly) {
	    croak("array is read-only");
	}

	ST(0) = store_value(recaddr, eltype, elsize, ST(3));
    }

    sv_2mortal(ST(0));
    XSRETURN(1);


# needed for $#{$array->[$n]}

long
FETCHSIZE(subarray)
	Tie::MmapArray::SubArray *	subarray

 PROTOTYPE: $

 CODE:
    RETVAL = subarray->nfields;

 OUTPUT:
    RETVAL


void
STORESIZE(subarray, newsize)
    Tie::MmapArray::SubArray *	subarray
    long			newsize

 PROTOTYPE: $$

 CODE:
    if (newsize != subarray->nfields) {
	croak("cannot alter size of subarray");
    }


void
DESTROY(subarray)
    Tie::MmapArray::SubHash *	subarray

 CODE:
    free_mmaparray_resources(subarray->array);
    Safefree(subarray);



########################################################################
#
# SUB HASHS
#
########################################################################

MODULE = Tie::MmapArray		PACKAGE = Tie::MmapArray::SubHashPtr


# FETCH subhash, key
#   Retrieve the datum in key for the tied hash subhash.
# STORE subhash, key, value
#   Store datum value into key for the tied hash subhash.
#

void
FETCH(subhash, key, ...)
    Tie::MmapArray::SubHash *	subhash
    char *		        key

 PROTOTYPE: $$;$

 ALIAS:
    STORE = 1

 PREINIT:
    Tie__MmapArray  *array;
    HASH_ELEMENT_T  *hfield;
    void 	    *recaddr;
    int		    recno;
    int		    offset;
    char	    eltype;
    int             elsize;

 PPCODE:
    if (!(hfield = lookup_key(subhash->fields, subhash->nfields, key))) {
	croak("invalid key");
    }
    eltype = hfield->eltype;
    elsize = hfield->elsize;
    offset = hfield->offset;
    array  = subhash->array;
    recno  = subhash->recno;

    recaddr = array->addr + (recno * array->elsize) + offset;

    /* FETCH */

    if (ix == 0) {
	switch (eltype) {
	case ARRAY_FIELDS:
	case HASH_FIELDS:
	    ST(0) = fetch_subrecord_reference(array, recno, eltype, 
					      hfield->fields, hfield->nfields);
	    break;

	default:
	    ST(0) = fetch_value(recaddr, eltype, elsize);
	    break;
	}
    }

    /* STORE */

    else {
	if (array->readonly) {
	    croak("array is read-only");
	}

	ST(0) = store_value(recaddr, eltype, elsize, ST(3));
    }

    sv_2mortal(ST(0));
    XSRETURN(1);


# FIRSTKEY subhash
#   Return the (key, value) pair for the first key in the hash.

char *
FIRSTKEY(subhash)
    Tie::MmapArray::SubHash *	subhash

 CODE:
    subhash->cur_index = 1;
    RETVAL = subhash->fields[0].key;

 OUTPUT:
    RETVAL


# NEXTKEY subhash, lastkey
#   Return the next key for the hash.

char *
NEXTKEY(subhash, lastkey)
    Tie::MmapArray::SubHash *	subhash
    char *                      lastkey

 PREINIT:
    int     cur_index;

 CODE:
    if ((cur_index = subhash->cur_index++) >= subhash->nfields) {
        XSRETURN_UNDEF;
    }

    RETVAL = subhash->fields[cur_index].key;

 OUTPUT:
    RETVAL


# EXISTS subhash, key
#   Verify that key exists with the tied hash subhash.

void
EXISTS(subhash, key)
    Tie::MmapArray::SubHash *	subhash
    char *                      key

 PPCODE:
    if (lookup_key(subhash->fields, subhash->nfields, key)) {
	XSRETURN_YES;
    } 
    else {
	XSRETURN_NO;
    }


# DELETE subhash, key
#   Delete the key key from the tied hash subhash.
#   FORBIDDEN as the sub-hash structure is fixed!

void
DELETE()

 PPCODE:
    croak("you cannot change the structure of Tie::MmapArray sub-hashes");


# CLEAR subhash
#   Clear all values from the tied hash subhash.
#   FORBIDDEN as the sub-hash structure is fixed!

void
CLEAR()

 PPCODE:
    croak("you cannot change the structure of Tie::MmapArray sub-hashes");


# DESTROY subhash
#   Destructor for the tied hash subhash 
#   Only explicitly deletes the subhash descriptor.
#   The main array's destructor is called but that implements its own
#   reference counting.

void
DESTROY(subhash)
    Tie::MmapArray::SubHash *	subhash

 CODE:
    free_mmaparray_resources(subhash->array);
    Safefree(subhash);


# END OF FILE
