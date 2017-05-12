/* -*- Mode: C -*- */
/* A tied ARRAY should have those methods:
    TIEARRAY classname, LIST               | ->new
    FETCH this, key                        | ->get
    STORE this, key, value                 | ->set
    FETCHSIZE this                         | ->len
    STORESIZE this, count                  | ->grow
    DESTROY this                           | ->DESTROY
  new with perl 5.6:
    CLEAR this                             | ->
    PUSH this, LIST                        | ->
    POP this                               | ->
    SHIFT this                             | ->
    UNSHIFT this, LIST                     | ->
    SPLICE this, offset, length, LIST      | ->splice
    EXTEND this, count                     | ->grow
  Todo:
   lvalue splice (not as hard as it seems to be)
   SCALAR @array                           | ->len
   SCALAR $#array                          | ->len -1
*/

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* #include <string.h> */
#include <float.h>

#ifdef __cplusplus
}
#endif

#define RCS_STRING "$Id: CArray.xs 0.15 2000/01/11 07:39:44 rurban Exp $"
#define OLD /* with OLD don't use the new version yet, stay 0.11 compatible */

/* We need some memory optimization values here */
#define PAGEBITS  11                    /* we can also use 10 or 12, most system malloc to 12 ie 4096 */
#define MY_PAGESIZE  (1 << PAGEBITS)    /* 2048 byte is the size of a fresh carray */

char *g_classname;                      /* global classname for a typemap trick    */
                                        /* to return the correct derived class     */

/* for linux Dynaloader */
#ifndef max
#define max(aaa,bbb) ((aaa) < (bbb) ? (bbb) : (aaa))
#define min(aaa,bbb) ((aaa) < (bbb) ? (aaa) : (bbb))
#endif

#define MAXITEMSIZE max(sizeof(double3),sizeof(int4))

/* #define MYDEBUG_FREE */

#ifdef DEBUGGING
#define DBG_PRINTF(X) printf X
#else
#define DBG_PRINTF(X)
#endif

/* perl-64 compliant version */
#if defined(USE_64_BITS) && defined(HAS_QUAD)
  #if defined(_MSC_VER) && !defined(Quad_T)  /* temp msvc fix */
    #define Quad_T	__int64
    #define Uquad_T 	unsigned __int64
  #endif
#endif

/* The base and the specialized classes for type checks on args. */
/* CIntArray is derived from CArray, you just cannot do pointer
   arithmetic with void *CArray->ptr. */
#ifdef OLD
typedef struct {
    int 	  len;
    void 	  * ptr;
    int 	  freelen;
    size_t	  elsize;		/* ie itemsize */
} Tie__CArray;
typedef struct {
    int 	  len;
    IV 		  * ptr;
    int 	  freelen;
    size_t	  elsize;		/* ie itemsize */
} Tie__CIntArray;
typedef struct {
    int 	  len;
    NV	 	  * ptr;
    int 	  freelen;
    size_t	  elsize;		/* ie itemsize */
} Tie__CDoubleArray;
typedef struct {
    int 	  len;
    char 	**ptr;
    int 	  freelen;
    size_t	  elsize;		/* ie itemsize */
} Tie__CStringArray;
#endif
                                        /* Geometric interpretation: */
typedef IVTYPE int2[2];                 /* edge pairs                */
typedef IVTYPE int3[3];                 /* triangle indices          */
typedef IVTYPE int4[4];                 /* tetras or quads           */
typedef NVTYPE double2[2];              /* point2d                   */
typedef NVTYPE double3[3];              /* point3d                   */

#ifndef OLD
/* ***************************************************************** */
/* Arbitrary structures borrowed from Tie::MmapArray
 */
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
#define DEFAULT_TYPE_SIZE   sizeof(IV)

typedef struct {
    int 	  len;
    void 	  * ptr;
    int 	  freelen;
   /* new with 0.12: */
    size_t	  elsize;		/* ie itemsize */
    char	  eltype;               /* pack char or array or hash */

    int		  offset;	  	/* for displaced arrays */
    unsigned int  readonly : 1;
    int		  refcnt;
} Tie__CArray;                          /* help typemap */


typedef struct {
    int 	  len;
    void 	  * ptr;
    int 	  freelen;

    size_t	  elsize;
    char	  eltype;
    int		  offset;	  	/* for displaced arrays */
    unsigned int  readonly : 1;
    int		  refcnt;
}
ARRAY_ELEMENT_T;

typedef struct {
    int 	  len;
    void 	  * ptr;
    int 	  freelen;

    char	  eltype;
    size_t	  elsize;
    int		  offset;

    char	  *key;
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
 * array.  The descriptor structures are identical exept for
 * the type of the field pointer so they can be handled by common
 * functions.
 */

typedef struct subarray {
    Tie__CArray     *array;
    ARRAY_ELEMENT_T *fields;
    int		    nfields;
    int		    recno;
    int		    cur_index;
}
Tie__CArray__SubArray;

typedef struct {
    Tie__CArray     *array;
    HASH_ELEMENT_T  *fields;
    int		    nfields;
    int		    recno;
    int		    cur_index;
}
Tie__CArray__SubHash;


/* Subrecord structure (doesn't matter which variety as it will be
 * cast when used).
 */
typedef struct subarray  SUBRECORD_REFERENCE_T;
#endif /* OLD */

/* Allocate a new carray, len must be set explicitly */
#define NEW_CARRAY(VAR,STRUCT_TYPE,LEN,ITEMSIZE) \
    VAR  = (STRUCT_TYPE *) safemalloc(sizeof(STRUCT_TYPE)); \
    VAR->freelen = freesize (LEN,ITEMSIZE); \
    VAR->ptr = safemalloc((LEN + VAR->freelen) * ITEMSIZE); \
    VAR->len = LEN;

/* VAR must exist */
#define MAYBE_GROW_CARRAY(VAR,STRUCT_TYPE,LEN,ITEMSIZE) \
  if (VAR->len < LEN) \
    VAR = (STRUCT_TYPE *)grow((Tie__CArray *)VAR,LEN - VAR->len,ITEMSIZE);

/* This is the to-tune part:
 * The overall size should fit into a page or other malloc chunks.
 * Leave room for "some" more items, but align it to the page size.
 * Should small arrays (<100) be aligned at 2048 or smaller bounds?
 * 10 => 2048-10, 2000 => 2048-2000, 200.000 => 2048
 * len is the actual length of the array, size the itemsize in bytes.
 */
int freesize (int len, int size)
{
    len *= size;
    return max(MY_PAGESIZE-len, len - ((len >> PAGEBITS) << PAGEBITS)) / size;
}

#ifndef OLD
/* A second approach for many small arrays could be more fine tuning
 * with more boundaries (128, 256, 2048)
 *   < 128 grow to 128, < 256 grow to 256, else grow to 2048.
 */
const int PAGE_BOUNDARY[4]; // = (128, 256, 2048, INT_MAX);  /* must be exponents of 2 */
const int PAGE_BOUNDARY_N = sizeof(PAGE_BOUNDARY)/sizeof(int) - 1;

int parametrized_freesize (int len, int elsize)
{
    int i;
    int pagesize = PAGE_BOUNDARY[3];
    len *= elsize;
    for ( i=0; i < PAGE_BOUNDARY_N; i++) {
        if (len > PAGE_BOUNDARY[i]) {
  	    int pagesize = PAGE_BOUNDARY[i+1];
	    int pagebits = log2(pagesize);
	    pagesize = max( pagesize-len,
			    len - ((len >> pagebits) << pagebits)) / elsize;
	}
    }
    return pagesize;
}
#endif /* OLD */

Tie__CArray *grow (Tie__CArray *carray, int n, int itemsize)
{
    int len = carray->len;
    /* make room for n new elements */
    if (n > carray->freelen) {
        carray->freelen = freesize (len + n, itemsize);
        carray->ptr = (void *) saferealloc (carray->ptr, len + carray->freelen);
        carray->len += n;
    } else {
        carray->freelen -= n;
        carray->len += n;
    }
    return carray;
}

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

char *CBaseNAME     = "Tie::CArray";
char *CSubArrayNAME = "Tie::CArray::SubArray";
char *CSubHashNAME  = "Tie::CArray::SubHash";

char *CIntNAME   = "Tie::CIntArray";
char *CDblNAME   = "Tie::CDoubleArray";
char *CStrNAME   = "Tie::CStringArray";
char *CInt2NAME  = "Tie::CInt2Array";
char *CInt3NAME  = "Tie::CInt3Array";
char *CInt4NAME  = "Tie::CInt4Array";
char *CDbl2NAME  = "Tie::CDouble2Array";
char *CDbl3NAME  = "Tie::CDouble3Array";

char* ErrMsg_index    = "index out of range";
char* ErrMsg_itemsize = "no itemsize for CArray element defined";
char* ErrMsg_type     = "arg is not of type %s";

#define CHECK_DERIVED_FROM(i,NAME) \
  if (!SvROK(ST(i)) || !sv_derived_from(ST(i),NAME)) \
    croak(ErrMsg_type,NAME)

/* size per item ín bytes, get it dynamically from READONLY vars
 * initalized at BOOT. This way we can add derived classes in perl easily.
 * Todo: get/set itemsize in the object struct not as package var
 */
int mysv_itemsize (SV *arg)
{
  char varname[80];
  char *classname;
  HV *stash;
  SV * sv;

  if ( stash = SvSTASH(SvRV(arg)) )
  {
    classname = HvNAME(stash);
    strcpy (varname, classname);
    strcat (varname, "::itemsize");
    if (!(sv = perl_get_sv(varname, FALSE)))
      goto sizeerr;
    else
      return SvIV(sv);
  }
sizeerr:
  croak (ErrMsg_itemsize);
  return 0;
}

/* To overcome ->new and ::new problems:
 * The first regular new arg must be an IV (len).
 * This might fail on some obscure situations,
 * but walking up the optree checking for -> or :: invocation is
 * too hard for now.
 */
char * mysv_classname (SV *this)
{
    if ( SvROK(this)  ) {
        HV *stash = SvSTASH(SvRV(this));
        if ( stash ) {
            return HvNAME(stash);
        }
    } else if(  SvPOK(this) && !SvIOK(this) ) {
        return SvPVX(this);
    }
    return NULL;
}

/* create a sv var, with some flag bits set */
int mysv_ivcreate ( int value, char *name, int flag)
{
    SV* sv = perl_get_sv( name, TRUE );
    sv_setiv( sv, value );
    SvFLAGS(sv) |= flag;
    return 1;
}

/* Todo: remove this */
int myarray_init (char *classname, Tie__CArray *carray, AV *av)
{
    int avlen, i, len;
    AV *av1;

    len = carray->len;
    avlen = av_len(av);
    /* initializing section: */
    if (strEQ(classname,CIntNAME)) {
        IV* array = carray->ptr;
        for (i=0; i <= min(avlen,len-1); i++) {
            array[i] = SvIV(AvARRAY(av)[i]);
        }
        return 1;
    }
    if (strEQ(classname,CDblNAME)) {
        NV* array = carray->ptr;
        for (i=0; i <= min(avlen,len-1); i++) {
            array[i] = SvNV(AvARRAY(av)[i]);
        }
        return 1;
    }
    if (strEQ(classname,CStrNAME)) {
        char *s;
        char** array = carray->ptr;
        for (i=0; i <= min(avlen,len-1); i++) {
            if ( SvPOK(AvARRAY(av)[i]) ) {
                s = SvPVX(AvARRAY(av)[i]);
                array[i] = safemalloc(strlen(s)+1);
                strcpy(array[i],s);
            }
        }
        return 1;
    }
    if (strEQ(classname,CInt2NAME)) {
        int2* array = carray->ptr;
        for (i=0; i <= min(avlen,len-1); i++) {
	    /* dive into [[0,1][2,3]] */
            if (!SvROK(av)) return 0;
            av1 = (AV*) SvRV(AvARRAY(av)[i]);
            if (av_len(av1) >= 1) {
              array[i][0] = SvIV(AvARRAY(av1)[0]);
              array[i][1] = SvIV(AvARRAY(av1)[1]);
            }
        }
        return 1;
    }
    if (strEQ(classname,CInt3NAME)) {
        int3* array = carray->ptr;
        for (i=0; i <= min(avlen,len-1); i++) {
	    /* dive into [[0,1,2][3,4,5]] */
            if (!SvROK(av)) return 0;
            av1 = (AV*)SvRV(AvARRAY(av)[i]);
            if (av_len(av1) >= 2) {
              array[i][0] = SvIV(AvARRAY(av1)[0]);
              array[i][1] = SvIV(AvARRAY(av1)[1]);
              array[i][2] = SvIV(AvARRAY(av1)[2]);
            }
        }
        return 1;
    }
    if (strEQ(classname,CInt4NAME)) {
        int4* array = carray->ptr;
        for (i=0; i <= min(avlen,len-1); i++) {
            if (!SvROK(av)) return 0;
            av1 = (AV*)SvRV(AvARRAY(av)[i]);
            if (av_len(av1) >= 3) {
              array[i][0] = SvIV(AvARRAY(av1)[0]);
              array[i][1] = SvIV(AvARRAY(av1)[1]);
              array[i][2] = SvIV(AvARRAY(av1)[2]);
              array[i][3] = SvIV(AvARRAY(av1)[3]);
            }
        }
        return 1;
    }
    if (strEQ(classname,CDbl2NAME)) {
        double2* array = carray->ptr;
        for (i=0; i <= min(avlen,len-1); i++) {
            if (!SvROK(av)) return 0;
            av1 = (AV*)SvRV(AvARRAY(av)[i]);
            if (av_len(av1) >= 1) {
              array[i][0] = SvNV(AvARRAY(av1)[0]);
              array[i][1] = SvNV(AvARRAY(av1)[1]);
            }
        }
        return 1;
    }
    if (strEQ(classname,CDbl3NAME)) {
        double3* array = carray->ptr;
        for (i=0; i <= min(avlen,len-1); i++) {
            if (!SvROK(av)) return 0;
            av1 = (AV*)SvRV(AvARRAY(av)[i]);
            if (av_len(av1) >= 2) {
              array[i][0] = SvNV(AvARRAY(av1)[0]);
              array[i][1] = SvNV(AvARRAY(av1)[1]);
              array[i][2] = SvNV(AvARRAY(av1)[2]);
            }
        }
        return 1;
    }
    return 0;
}

#ifndef OLD

static void
free_array_field_descriptor(Tie__CArray__SubArray *afields, int nfields)
{
    DBG_PRINTF(("free_array_field_descriptor(%p, $d)", afields, nfields));

    if (afields) {
	Tie__CArray__SubArray *ap = afields + nfields;

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
    DBG_PRINTF(("free_hash_field_descriptor(%p, %d)", hfields, nfields));

    if (hfields) {
	Tie__CArray__SubHash *hp;

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
parse_field_desc_array(Tie__CArray      *array,
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

    DBG_PRINTF(("parse_field_desc_array(%p, %p, %d, %p)",
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

    DBG_PRINTF(("parse_field_desc_array  allocated %p-%p",
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

	DBG_PRINTF(("parse_field_desc_array  field %d is \"%s\"", i, name));

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

    DBG_PRINTF(("parse_field_desc_string(array=%p, field=%p, offset=%d, template=\"%s\")",
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

#if defined(USE_64_BITS) && defined(HAS_QUAD)
	    case 'q': case 'Q':
		elsize = sizeof(Quad_T);
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
fetch_subrecord_reference(Tie__CArray    *array,
			  int		    recno,
			  char	    	    eltype,
			  void              *fieldp,
			  int		    nfields)
{
    SUBRECORD_REFERENCE_T   *subrec;
    SV			    *sv;
    SV			    *rv;
    SV			    *tied;

    DBG_PRINTF(("fetch_subrecord_reference(%p, %d, '%c', %p, %d)",
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

/* Fetch a value from a specified address according
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
    NV		doubleval;
#ifdef HAVE_QUAD_INTS
    Quad_T		quadval;
    Uquad_T         uquadval;
#endif

    DBG_PRINTF(("fetch_value(%p, '%c', %d)", recaddr, isascii(eltype) ? eltype : '?', elsize));

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

#if defined(USE_64_BITS) && defined(HAS_QUAD)
    case 'q':
	GET_VAL(Quad_T, recaddr, quadval);
	return newSVnv((NV) quadval);

    case 'Q':
	GET_VAL(Uquad_T, recaddr, uquadval);
#ifdef _MSC_VER
        /* msvc <= 6 cannot coerce ulonglong to double, only signed */
	return newSVnv((NV)(Quad_T)uquadval);
#else
	return newSVnv((NV) uquadval);
#endif
#endif

    case 'f':
	GET_VAL(float, recaddr, floatval);
	return newSVnv((NV) floatval);

    case 'd':
	GET_VAL(NV, recaddr, doubleval);
	return newSVnv(doubleval);

    default:
	croak("internal error (FETCH: case %d not handled)", eltype);
    }
}

/* Store a value at a specified address according to the element type.
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
    NVTYPE		doubleval;
#if defined(USE_64_BITS) && defined(HAS_QUAD)
    Quad_T          quadval;
    Uquad_T         uquadval;
#endif

    DBG_PRINTF(("store_value(%p, %d, %d, %p)", recaddr, eltype, elsize, value));

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
                Zero((char *)recaddr + len, elsize - len, char);
	    }
	    else {
                memset((char *)recaddr + len, ' ', elsize - len);
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

#if defined(USE_64_BITS) && defined(HAS_QUAD)
    case 'q':
	quadval = (Quad_T)SvNV(value);
	SET_VAL(Quad_T, recaddr, quadval);
	return newSVnv((NV)quadval);

    case 'Q':
	uquadval = (Uquad_T)SvNV(value);
	SET_VAL(Uquad_T, recaddr, uquadval);
#ifdef _MSC_VER
        /* msvc <= 6 cannot coerce ulonglong to double, only signed */
	return newSVnv((NV)(Quad_T)uquadval);
#else
	return newSVnv((NV)uquadval);
#endif
#endif

    case 'f':
	floatval = (float)SvNV(value);
	SET_VAL(float, recaddr, floatval);
	return newSVnv(floatval);

    case 'F':
	doubleval = (NV)SvNV(value);
	SET_VAL(NV, recaddr, doubleval);
	return newSVnv(doubleval);

    case ARRAY_FIELDS:
    case HASH_FIELDS:
	croak("cannot change element structure");

    default:
	croak("internal error (STORE: case %d not handled)", eltype);
    }
}
#endif /* OLD */


/* ***************************************************************** */

MODULE = Tie::CArray     PACKAGE = Tie::CArray   PREFIX = carray_
PROTOTYPES: DISABLE

char *
carray_XS_rcs_string()
CODE:
 RETVAL = RCS_STRING;
OUTPUT:
 RETVAL

char *
carray_XS_compile_date()
CODE:
 RETVAL = __DATE__ " " __TIME__;
OUTPUT:
 RETVAL

void
carray_DESTROY (carray)
    Tie__CArray *carray
PREINIT:
    SV *this = ST(0);
    char *old;
CODE:
#ifdef MYDEBUG_FREE
    DBG_PRINTF(("XSDbg: free (%p,->%p)\n",carray, carray->ptr));
/*  DBG_PRINTF(("    => (refSV: %d, RV: %p, IVRV: %p, refRV: %d)\n",
      SvREFCNT(ST(0)), SvRV(ST(0)), SvIV(SvRV(ST(0))), SvREFCNT(SvRV(ST(0))) ));
 */
#endif
    old = (char *) carray;
    if (carray) {
      if (carray->ptr) safefree ((char *) carray->ptr);
      /* safefree ((char *) carray); */
    }
/* if (old == (char *) carray)
     carray->ptr=0;
   SvROK_off (this);
   SvREFCNT (this)--;
*/
#ifdef MYDEBUG_FREE
    DBG_PRINTF((" unref (refSV: %d, RV: %p, IVRV: %p, refRV: %d)\n",
	SvREFCNT(this), SvRV(this), SvIV(SvRV(this)), SvREFCNT(SvRV(this)) ));
#endif

int
carray_len (carray)
    Tie__CArray * carray
ALIAS:
    carray_FETCHSIZE = 1
CODE:
    /* sequential classes must divide this */
    RETVAL = carray->len;
OUTPUT:
    RETVAL

int
carray__freelen (carray)
    Tie__CArray * carray
CODE:
    /* Return the number of elements to be added without copying. (if elsize is byte)
     * Sequential classes must divide this by their resp. itemsizes */
    RETVAL = carray->freelen;
OUTPUT:
    RETVAL

void
carray_grow (carray, n)
    Tie__CArray * carray
    int n
ALIAS:
    carray_EXTEND    = 1
    carray_STORESIZE = 2
CODE:
    if (ix < 2) {			/* grow or EXTEND */
      grow (carray, n, mysv_itemsize( ST(0) ));
    } else {                            /* change size */
      if (n > carray->len)              /* EXTEND */
      	grow (carray, n-carray->len, mysv_itemsize( ST(0) ));
      else {				/* SHRINK */
	carray->freelen += carray->len - n;
	carray->len = n;
      }
    }

void
carray_delete (carray, index)
    Tie__CArray * carray
    int index
PREINIT:
    char *array;
    int itemsize;
CODE:
    if ((index < 0) || (index >= carray->len))
      croak (ErrMsg_index);
    /* deletes one item at index, there's no shrink */
    carray->freelen++;
    carray->len--;
    if (index < carray->len-1) {
        itemsize = mysv_itemsize( ST(0) );
        array = (char *) carray->ptr + (index*itemsize);
        memcpy (array, array + itemsize, itemsize*(carray->len - index));
    }

Tie__CArray *
carray_copy (carray)
    Tie__CArray * carray
PREINIT:
    SV * this = ST(0);
    int itemsize, len;
    Tie__CArray * ncarray;
CODE:
    itemsize = mysv_itemsize( this );
    len = carray->len;
    NEW_CARRAY(ncarray,Tie__CArray,len,itemsize);
    memcpy (ncarray->ptr, carray->ptr, itemsize * len);
    RETVAL = carray;
OUTPUT:
    RETVAL

void
carray_nreverse (carray)
    Tie__CArray * carray
PREINIT:
    char *up, *down, *tmp;                      /* pointers incrementable by 1 byte */
    int len, itemsize;
CODE:
    /* Generic reverse in place. Returns nothing */
    len = carray->len;
    if (!len)  XSRETURN_NO;
    tmp = (char *) safemalloc (MAXITEMSIZE);
/*  if (!carray->ptr) XSRETURN_NO; */
    /* get the itemsize to swap: there's a XSUB cv ->itemsize */
    itemsize = mysv_itemsize( ST(0) );
    if (!itemsize)  croak (ErrMsg_itemsize);
    /* */
    down = (char *)carray->ptr + ((len-1)*itemsize);
    up   = (char *)carray->ptr;
    while ( down > up )
    {
      memcpy(tmp,  up,   itemsize);
      memcpy(up,   down, itemsize);
      memcpy(down, tmp,  itemsize);
      up   += itemsize;
      down -= itemsize;
    }
    safefree(tmp);
    XSRETURN_EMPTY;

void
carray_CLEAR (carray)
    Tie__CArray *carray;
CODE:
    Zero(carray->ptr, carray->len * carray->elsize, void *);

# TODO: PUSH, POP, SHIFT, UNSHIFT

void
carray_init (carray, av)
    Tie__CArray *carray;
    AV * av;
CODE:
    if (!av) XSRETURN_EMPTY;
    myarray_init(g_classname, carray, av);


MODULE = Tie::CArray     PACKAGE = Tie::CIntArray PREFIX = int_
PROTOTYPES: DISABLE

int
int_itemsize (carray)
    Tie__CIntArray * carray
CODE:
    RETVAL = sizeof(IV);
OUTPUT:
    RETVAL

# this is the same for all derived classes
void
int_new (...)
ALIAS:
    int_TIEARRAY = 1
PPCODE:
    SV * this = ST(0);
    int  len;
    AV * av;
    Tie__CIntArray *carray;
    IV * array;
    int i, avlen;
    /* */
    if (items < 1 || items > 3)
	if (ix == 0)
            croak("Usage: new Tie::CIntArray(len, [AVPtr])");
	else
            croak("Usage: tie @array, Tie::CIntArray, len, [AVPtr]");
    {
      /* need to check for ->new invocation, we'll have 3 args then */
      g_classname = mysv_classname(this);
      if ( g_classname  ) {
          len = (int)SvIV(ST(1));
          av   = (items == 3) ? av = (AV*)SvRV(ST(2)) : NULL;
      } else {
          g_classname = CIntNAME;
          len = (int)SvIV(ST(0));
          av   = (items == 2) ? av = (AV*)SvRV(ST(1)) : NULL;
      }
      /* make room: freesize leaves room for certain more items */
      NEW_CARRAY(carray,Tie__CIntArray,len,sizeof(IV));
      if (av) {
        /* for derived classes we'll have a problem here!
        * we could either check the classname for ints,
        * or provide seperate initializers (in perl) */
/*      if (!strEQ(g_classname,CIntNAME)) {
          warn("can only initialize %s",CIntNAME);
        } else
*/
          myarray_init(g_classname, (Tie__CArray *)carray, av);
      }
      EXTEND(sp, 1);
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), g_classname, (void*)carray);
      XSRETURN(1);
    }

int
int_get(carray, index)
    Tie__CIntArray * carray
    int   index
ALIAS:
    int_FETCH = 1
CODE:
    if ((index < 0) || (index >= carray->len))
      croak (ErrMsg_index);
/*  DBG_PRINTF(("XSDbg: get (%p,%d)",array,index)); */
    RETVAL = carray->ptr[index];
/*  DBG_PRINTF((" => %d\n",array[index])); */
OUTPUT:
    RETVAL

void
int_set(carray, index, value)
  Tie__CIntArray * carray
  int index
  int value
ALIAS:
    int_STORE = 1
CODE:
{
  if ((index < 0) || (index >= carray->len))
    croak (ErrMsg_index);
/*  DBG_PRINTF(("XSDbg: set (%p,%d,%d)\n",array,index,value)); */
  carray->ptr[index] = value;
}

void
int_ToInt2 (x, y, dst=0)
  Tie__CIntArray * x
  Tie__CIntArray * y
  Tie__CIntArray * dst = (items == 3) ? dst = (Tie__CIntArray *)SvRV(ST(2)) : NULL;
PREINIT:
  int i, len;
  int2 *dstp;
CODE:
  /* convert two parallel int *x,*y to one int[2] */
  /* if dst, which must be preallocated, copy it to this location */
  len = x->len;
  if (!dst) {
    NEW_CARRAY(dst,Tie__CIntArray,len,sizeof(int2));
  } else {
    CHECK_DERIVED_FROM(2,CIntNAME);
    MAYBE_GROW_CARRAY(dst,Tie__CIntArray,len,sizeof(int2));
  }
  dstp = (int2 *)dst->ptr;
  if (min(x->len,y->len) == len)
    for (i=0; i < len; i++) {
        dstp[i][0] = x->ptr[i];
        dstp[i][1] = y->ptr[i];
    }
  else                                  /* safe init */
    for (i=0; i < len; i++) {
        dstp[i][0] = x->ptr[i];
        if (i < y->len) dstp[i][1] = y->ptr[i]; else dstp[i][1] = 0;
    }
  dst->len = len * 2;
  ST(0) = sv_newmortal();
  /* blessing makes problems: it is returned as "CIntArray" object. */
  sv_setref_pv(ST(0), CInt2NAME, (void*)dst);

Tie__CIntArray *
int_ToInt3 (x, y, z, dst=0)
  Tie__CIntArray * x
  Tie__CIntArray * y
  Tie__CIntArray * z
  Tie__CIntArray *dst = (items > 3) ? dst = (Tie__CIntArray *)SvRV(ST(3)) : NULL;
PREINIT:
  int i, len;
  int3 *dstp;
CODE:
  len = x->len;
  if (!dst) {
    NEW_CARRAY(dst,Tie__CIntArray,len,sizeof(int3));
  } else {
    CHECK_DERIVED_FROM(3,CIntNAME);
    MAYBE_GROW_CARRAY(dst,Tie__CIntArray,len,sizeof(int3));
  }
  dstp = (int3 *) dst->ptr;
  if (min(min(x->len,y->len),z->len) == len)
    for (i=0; i < len; i++) {
        dstp[i][0] = x->ptr[i];
        dstp[i][1] = y->ptr[i];
        dstp[i][2] = z->ptr[i];
    }
  else                                  /* safe init */
    for (i=0; i < len; i++) {
        dstp[i][0] = x->ptr[i];
        if (i < y->len) dstp[i][1] = y->ptr[i]; else dstp[i][1] = 0;
        if (i < z->len) dstp[i][2] = z->ptr[i]; else dstp[i][2] = 0;
    }
  dst->len = len * 3;
  g_classname = CInt3NAME;
  RETVAL = dst;
OUTPUT:
  RETVAL

Tie__CIntArray *
int_ToInt4 (x, y, z, w, dst=0)
  Tie__CIntArray * x
  Tie__CIntArray * y
  Tie__CIntArray * z
  Tie__CIntArray * w
  Tie__CIntArray * dst = (items > 4) ? dst = (Tie__CIntArray *)SvRV(ST(4)) : NULL;
PREINIT:
  int i, len;
  int4 *dstp;
CODE:
  len = x->len;
  if (!dst) {
    NEW_CARRAY(dst,Tie__CIntArray,len,sizeof(int4));
  } else {
    CHECK_DERIVED_FROM(4,CIntNAME);
    MAYBE_GROW_CARRAY(dst,Tie__CIntArray,len,sizeof(int4));
  }
  dstp = (int4 *) dst->ptr;
  if ( min (min (x->len,y->len), min (z->len,w->len)) == len)
    for (i=0; i < len; i++) {
        dstp[i][0] = x->ptr[i];
        dstp[i][1] = y->ptr[i];
        dstp[i][2] = z->ptr[i];
        dstp[i][3] = w->ptr[i];
    }
  else                                  /* safe init */
    for (i=0; i < len; i++) {
        dstp[i][0] = x->ptr[i];
        if (i < y->len) dstp[i][1] = y->ptr[i]; else dstp[i][1] = 0;
        if (i < z->len) dstp[i][2] = z->ptr[i]; else dstp[i][2] = 0;
        if (i < w->len) dstp[i][3] = w->ptr[i]; else dstp[i][3] = 0;
    }
  dst->len = len * 4;
  g_classname = CInt4NAME;
  RETVAL = dst;
OUTPUT:
  RETVAL

AV *
int_list(carray)
    Tie__CIntArray * carray
PREINIT:
    int i, len;
    IV *array;
CODE:
    RETVAL = newAV();
    len = carray->len;
    array = carray->ptr;
    for (i=0; i<len; i++ ) {
        av_push(RETVAL, sv_2mortal( newSViv( array[i] )));
    }
OUTPUT:
  RETVAL


MODULE = Tie::CArray     PACKAGE = Tie::CInt2Array PREFIX = int2_
PROTOTYPES: DISABLE

int
int2_itemsize (carray)
  Tie__CIntArray * carray
CODE:
  RETVAL = sizeof(int2);
OUTPUT:
  RETVAL

void
int2_get (carray, index)
    Tie__CIntArray *carray
    int index
ALIAS:
    int2_FETCH = 1
PREINIT:
    int2 *array;
    AV *av;
CODE:
  if ((index < 0) || (index >= carray->len/2))
    croak (ErrMsg_index);
  array = (int2 *) carray->ptr;
  if (GIMME == G_ARRAY) {
    XST_mIV(0,array[index][0]);
    XST_mIV(1,array[index][1]);
    XSRETURN(2);
  } else {
    av = newAV();
    av_push(av, newSViv( array[index][0] ));
    av_push(av, newSViv( array[index][1] ));
    ST(0) = sv_2mortal(newRV((SV*) av));
    XSRETURN(1);
  }

void
int2_set(carray, index, value)
  Tie__CIntArray * carray
  int index
  AV * value
ALIAS:
    int2_STORE = 1
PREINIT:
  int i, len;
  int2 *array;
CODE:
  if ((index < 0) || (index >= carray->len/2))
    croak (ErrMsg_index);
  array = (int2 *) carray->ptr;
  len = min(av_len(value)+1,2);
  for (i=0; i < len; i++) {
    array[index][i] = SvIV(AvARRAY(value)[i]);
  }

AV *
int2_ToPar (carray, x=0, y=0)
  Tie__CIntArray * carray
  Tie__CIntArray * x  = (items > 1)  ? x = (Tie__CIntArray *) SvRV(ST(1)) : NULL;
  Tie__CIntArray * y  = (items > 2)  ? y = (Tie__CIntArray *) SvRV(ST(2)) : NULL;
PREINIT:
  int i, len;
  int3 *array;
CODE:
  /* convert one int[3] to parallel ints *x,*y,*z */
  /* if dst, which must be preallocated, copy it to this location. */
  /* return an arrayref to the three objects */
  len = carray->len / 3;
  array = (int3 *) carray->ptr;
  if (!x) {
    NEW_CARRAY(x,Tie__CIntArray,len,sizeof(IV));
  } else {
    CHECK_DERIVED_FROM(1,CIntNAME);
    MAYBE_GROW_CARRAY(x,Tie__CIntArray,len,sizeof(IV));
  }
  if (!y) {
    NEW_CARRAY(y,Tie__CIntArray,len,sizeof(IV));
  } else {
    CHECK_DERIVED_FROM(2,CIntNAME);
    MAYBE_GROW_CARRAY(y,Tie__CIntArray,len,sizeof(IV));
  }
  for (i=0; i < len; i++) {
    x->ptr[i] = array[i][0];
    y->ptr[i] = array[i][1];
  }
  /* if (items < 3) EXTEND(sp,1);// one more */
  RETVAL = newAV();
  av_push(RETVAL, sv_setref_pv( sv_newmortal(), CIntNAME, (void*)x));
  av_push(RETVAL, sv_setref_pv( sv_newmortal(), CIntNAME, (void*)y));
OUTPUT:
  RETVAL

MODULE = Tie::CArray     PACKAGE = Tie::CInt3Array PREFIX = int3_
PROTOTYPES: DISABLE

int
int3_itemsize (carray)
  Tie__CIntArray * carray
CODE:
  RETVAL = sizeof(int3);
OUTPUT:
  RETVAL

void
int3_get (carray, index)
  Tie__CIntArray *carray
  int index
ALIAS:
    int3_FETCH = 1
PREINIT:
  int3 *array;
  AV *av;
CODE:
  if ((index < 0) || (index >= carray->len/3))
    croak (ErrMsg_index);
  array = (int3 *) carray->ptr;
  if (GIMME == G_ARRAY) {
    EXTEND(sp,1);
    XST_mIV(0,array[index][0]);
    XST_mIV(1,array[index][1]);
    XST_mIV(2,array[index][2]);
    XSRETURN(3);
  } else {
    av = newAV();
    av_push(av, newSViv( array[index][0] ));
    av_push(av, newSViv( array[index][1] ));
    av_push(av, newSViv( array[index][2] ));
    ST(0) = sv_2mortal(newRV((SV*) av));
    XSRETURN(1);
  }

void
int3_set(carray, index, value)
  Tie__CIntArray * carray
  int index
  AV * value
ALIAS:
    int3_STORE = 1
PREINIT:
  int i, len;
  int3 *array;
CODE:
  if ((index < 0) || (index >= carray->len/3))
    croak (ErrMsg_index);
  array = (int3 *) carray->ptr;
  len = min(av_len(value)+1,3);
  for (i=0; i < len; i++) {
    array[index][i] = SvIV(AvARRAY(value)[i]);
  }

AV *
int3_ToPar (carray, x=0, y=0, z=0)
  Tie__CIntArray * carray
  Tie__CIntArray * x  = (items > 1) ? x = (Tie__CIntArray *) SvRV(ST(1)) : NULL;
  Tie__CIntArray * y  = (items > 2) ? y = (Tie__CIntArray *) SvRV(ST(2)) : NULL;
  Tie__CIntArray * z  = (items > 3) ? z = (Tie__CIntArray *) SvRV(ST(3)) : NULL;
PREINIT:
  int i, len;
  int3 *array;
CODE:
  /* convert one int[3] to parallel ints *x,*y,*z */
  /* if dst, which must be preallocated, copy it to this location */
  /* return an arrayref to the three objects */
  len = carray->len / 3;
  array = (int3 *) carray->ptr;
  if (!x) {
    NEW_CARRAY(x,Tie__CIntArray,len,sizeof(IV));
  } else {
    CHECK_DERIVED_FROM(1,CIntNAME);
    MAYBE_GROW_CARRAY(x,Tie__CIntArray,len,sizeof(IV));
  }
  if (!y) {
    NEW_CARRAY(y,Tie__CIntArray,len,sizeof(IV));
  } else {
    CHECK_DERIVED_FROM(2,CIntNAME);
    MAYBE_GROW_CARRAY(y,Tie__CIntArray,len,sizeof(IV));
  }
  if (!z) {
    NEW_CARRAY(z,Tie__CIntArray,len,sizeof(IV));
  } else {
    CHECK_DERIVED_FROM(3,CIntNAME);
    MAYBE_GROW_CARRAY(z,Tie__CIntArray,len,sizeof(IV));
  }
  for (i=0; i < len; i++) {
    x->ptr[i] = array[i][0];
    y->ptr[i] = array[i][1];
    z->ptr[i] = array[i][2];
  }
  /* if (items < 3) EXTEND(sp,1);// one more */
  RETVAL = newAV();
  av_push(RETVAL, sv_setref_pv(sv_newmortal(), CIntNAME, (void*)x));
  av_push(RETVAL, sv_setref_pv(sv_newmortal(), CIntNAME, (void*)y));
  av_push(RETVAL, sv_setref_pv(sv_newmortal(), CIntNAME, (void*)z));
OUTPUT:
  RETVAL

MODULE = Tie::CArray     PACKAGE = Tie::CInt4Array PREFIX = int4_
PROTOTYPES: DISABLE

int
int4_itemsize (carray)
  Tie__CIntArray * carray
CODE:
  RETVAL = sizeof(int4);
OUTPUT:
  RETVAL

void
int4_get (carray, index)
  Tie__CIntArray *carray
  int index
ALIAS:
    int4_FETCH = 1
PREINIT:
  int4 *array;
  AV   *av;
CODE:
  if ((index < 0) || (index >= carray->len/4))
    croak (ErrMsg_index);
  array = (int4 *) carray->ptr;
  if (GIMME == G_ARRAY) {
    EXTEND(sp,2);
    XST_mIV(0,array[index][0]);
    XST_mIV(1,array[index][1]);
    XST_mIV(2,array[index][2]);
    XST_mIV(3,array[index][3]);
    XSRETURN(4);
  } else {
    av = newAV();
    av_push(av, newSViv( array[index][0] ));
    av_push(av, newSViv( array[index][1] ));
    av_push(av, newSViv( array[index][2] ));
    av_push(av, newSViv( array[index][3] ));
    ST(0) = sv_2mortal(newRV((SV*) av));
    XSRETURN(1);
  }

void
int4_set(carray, index, value)
  Tie__CIntArray * carray
  int index
  AV * value
ALIAS:
    int4_STORE = 1
PREINIT:
  int i, len;
  int4 *array;
CODE:
  if ((index < 0) || (index >= carray->len/4))
    croak (ErrMsg_index);
  array = (int4 *) carray->ptr;
  len = min(av_len(value)+1,4);
  for (i=0; i < len; i++) {
    array[index][i] = SvIV(AvARRAY(value)[i]);
  }

AV *
int4_ToPar (carray, x=0, y=0, z=0, w=0)
  Tie__CIntArray * carray
  Tie__CIntArray * x  = (items > 1) ? x = (Tie__CIntArray *) SvRV(ST(1)) : NULL;
  Tie__CIntArray * y  = (items > 2) ? y = (Tie__CIntArray *) SvRV(ST(2)) : NULL;
  Tie__CIntArray * z  = (items > 3) ? z = (Tie__CIntArray *) SvRV(ST(3)) : NULL;
  Tie__CIntArray * w  = (items > 4) ? w = (Tie__CIntArray *) SvRV(ST(4)) : NULL;
PREINIT:
  int i, len;
  int4 *array;
CODE:
  len = carray->len / 4;
  array = (int4 *) carray->ptr;
  if (!x) {
    NEW_CARRAY(x,Tie__CIntArray,len,sizeof(IV));
  } else {
    CHECK_DERIVED_FROM(1,CIntNAME);
    MAYBE_GROW_CARRAY(x,Tie__CIntArray,len,sizeof(IV));
  }
  if (!y) {
    NEW_CARRAY(y,Tie__CIntArray,len,sizeof(IV));
  } else {
    CHECK_DERIVED_FROM(2,CIntNAME);
    MAYBE_GROW_CARRAY(y,Tie__CIntArray,len,sizeof(IV));
  }
  if (!z) {
    NEW_CARRAY(z,Tie__CIntArray,len,sizeof(IV));
  } else {
    CHECK_DERIVED_FROM(3,CIntNAME);
    MAYBE_GROW_CARRAY(z,Tie__CIntArray,len,sizeof(IV));
  }
  if (!w) {
    NEW_CARRAY(w,Tie__CIntArray,len,sizeof(IV));
  } else {
    CHECK_DERIVED_FROM(4,CIntNAME);
    MAYBE_GROW_CARRAY(w,Tie__CIntArray,len,sizeof(IV));
  }
  for (i=0; i < len; i++) {
    x->ptr[i] = array[i][0];
    y->ptr[i] = array[i][1];
    z->ptr[i] = array[i][2];
    w->ptr[i] = array[i][3];
  }
  RETVAL = newAV();
  av_push(RETVAL, sv_setref_pv(sv_newmortal(), CIntNAME, (void*)x));
  av_push(RETVAL, sv_setref_pv(sv_newmortal(), CIntNAME, (void*)y));
  av_push(RETVAL, sv_setref_pv(sv_newmortal(), CIntNAME, (void*)z));
  av_push(RETVAL, sv_setref_pv(sv_newmortal(), CIntNAME, (void*)w));
OUTPUT:
  RETVAL

MODULE = Tie::CArray     PACKAGE = Tie::CDoubleArray PREFIX = double_
PROTOTYPES: DISABLE

int
double_itemsize (carray)
  Tie__CDoubleArray * carray
CODE:
  RETVAL = sizeof(NV);
OUTPUT:
  RETVAL

void
double_new (...)
ALIAS:
    double_TIEARRAY = 1
PPCODE:
    SV * this = ST(0);
    int  len;
    AV * av;
    Tie__CDoubleArray *carray;
    NV *array;
    int i, avlen;
    /* */
    if (items < 1 || items > 3)
	if (ix == 0)
            croak("Usage: new Tie::CDoubleArray(len, [AVPtr])");
	else
            croak("Usage: tie @array, 'Tie::CDoubleArray', len, [AVPtr]");
    {
    	/* need to check for ->new invocation, we'll have 3 args then */
    	g_classname = mysv_classname(this);
    	if ( g_classname  ) {
            len = (int)SvIV(ST(1));
            av   = (items == 3) ? av = (AV*)SvRV(ST(2)) : NULL;
    	} else {
	    g_classname = CDblNAME;
	    len = (int)SvIV(ST(0));
            av   = (items == 2) ? av = (AV*)SvRV(ST(1)) : NULL;
    	}
        /* make room */
        NEW_CARRAY(carray,Tie__CDoubleArray,len,sizeof(NV));
        carray->len = len;
    	if (av) {
      	    /* initializing section: */
      	    /* for derived classes we'll have a problem here! */
      	    /* we could either check the classname for ints, */
      	    /* or call seperate initializers (in perl) */
      	    if (!strEQ(g_classname,CDblNAME))
            	warn("can only initialize %s",CDblNAME);
  	    else
                myarray_init(g_classname, (Tie__CArray *)carray, av);
    	}
    	ST(0) = sv_newmortal();
    	sv_setref_pv(ST(0), g_classname, (void*)carray);
    	XSRETURN(1);
    }


NV
double_get(carray, index)
    Tie__CDoubleArray * carray
    int      index
ALIAS:
    double_FETCH = 1
CODE:
    if ((index < 0) || (index >= carray->len))
        croak (ErrMsg_index);
    RETVAL = carray->ptr[index];
OUTPUT:
    RETVAL

void
double_set(carray, index, value)
    Tie__CDoubleArray * carray
    int      index
    NV       value
ALIAS:
    double_STORE = 1
CODE:
    if ((index < 0) || (index >= carray->len))
        croak (ErrMsg_index);
    carray->ptr[index] = value;


#if 0

Tie__CDoubleArray *
double_nreverse (carray)
    Tie__CDoubleArray * carray
PREINIT:
    int len;
    NV *up, *down, tmp;
CODE:
    len = carray->len;
    if (!len)  XSRETURN_EMPTY;
    if (!carray->ptr) XSRETURN_EMPTY;
    /* fast reverse in place */
    down = &carray->ptr[len-1];
    up   = &carray->ptr[0];
    while ( down > up )
    {
    	tmp = *up;
    	*up++ = *down;
    	*down-- = tmp;
    }
    RETVAL = carray;
OUTPUT:
    RETVAL

#endif

Tie__CDoubleArray *
double_ToDouble2 (x, y, dst=0)
  Tie__CDoubleArray * x
  Tie__CDoubleArray * y
  Tie__CDoubleArray *dst = (items > 2) ? dst = (Tie__CDoubleArray *)SvRV(ST(2)) : NULL;
PREINIT:
  int i, len;
  NV *xp, *yp;
  double2 *dstp;
CODE:
  len = x->len;
  if (!dst) {
    NEW_CARRAY(dst,Tie__CDoubleArray,len,sizeof(double2));
  } else {
    CHECK_DERIVED_FROM(2,CDblNAME);
    MAYBE_GROW_CARRAY(dst,Tie__CDoubleArray,len,sizeof(double2));
  }
  dstp = (double2 *) dst->ptr;
  if (min(x->len,y->len) == len)
    for (i=0; i < len; i++) {
        dstp[i][0] = x->ptr[i];
        dstp[i][1] = y->ptr[i];
    }
  else                                  /* safe init */
    for (i=0; i < len; i++) {
        if (i < x->len) dstp[i][0] = x->ptr[i]; else dstp[i][0] = 0.0;
        if (i < y->len) dstp[i][0] = y->ptr[i]; else dstp[i][1] = 0.0;
    }
  dst->len = len * 2;
  g_classname = CDbl2NAME;
  RETVAL = dst;
OUTPUT:
  RETVAL

Tie__CDoubleArray *
double_ToDouble3 (x, y, z=0, dst=0)
  Tie__CDoubleArray * x
  Tie__CDoubleArray * y
  Tie__CDoubleArray * z = (items > 2) ? z   = (Tie__CDoubleArray *)SvRV(ST(2)) : NULL;
  Tie__CDoubleArray *dst= (items > 3) ? dst = (Tie__CDoubleArray *)SvRV(ST(3)) : NULL;
PREINIT:
  int i, len;
  double3 *dstp;
CODE:
  len = x->len;
  CHECK_DERIVED_FROM(2,CDblNAME);
  if (!dst) {
    NEW_CARRAY(dst,Tie__CDoubleArray,len,sizeof(double3));
  } else {
    CHECK_DERIVED_FROM(3,CDblNAME);
    MAYBE_GROW_CARRAY(dst,Tie__CDoubleArray,len,sizeof(double3));
  }
  dstp = (double3 *) dst->ptr;
  if (min(min(x->len,y->len),z->len) == len)
    for (i=0; i < len; i++) {
        dstp[i][0] = x->ptr[i];
        dstp[i][1] = y->ptr[i];
        dstp[i][2] = z ? z->ptr[i] : 0.0;
    }
  else                                  /* safe init */
    for (i=0; i < len; i++) {
        if (i < x->len) dstp[i][0] = x->ptr[i]; else dstp[i][0] = 0.0;
        if (i < y->len) dstp[i][0] = y->ptr[i]; else dstp[i][1] = 0.0;
        if (z && (i < z->len)) dstp[i][0] = z->ptr[i]; else dstp[i][2] = 0.0;
    }
  dst->len = len * 3;
  g_classname = CDbl3NAME;
  RETVAL = dst;
OUTPUT:
  RETVAL

AV *
double_list(carray)
  Tie__CDoubleArray * carray
PREINIT:
    int i, len;
    NV *array;
CODE:
    RETVAL = newAV();
    len = carray->len;
    array = carray->ptr;
    for (i=0; i<len; i++ ) {
        av_push(RETVAL, sv_2mortal( newSVnv( array[i] )));
    }
OUTPUT:
  RETVAL

MODULE = Tie::CArray     PACKAGE = Tie::CDouble2Array PREFIX = double2_
PROTOTYPES: DISABLE

int
double2_itemsize (carray)
  Tie__CDoubleArray * carray
CODE:
  RETVAL = sizeof(double2);
OUTPUT:
  RETVAL

void
double2_get (carray, index)
  Tie__CDoubleArray *carray
  int index
ALIAS:
    double2_FETCH = 1
PREINIT:
  double2 *array;
  AV *av;
CODE:
  if ((index < 0) || (index >= carray->len/2))
    croak (ErrMsg_index);
  array = (double2 *) carray->ptr;
  if (GIMME == G_ARRAY) {
    XST_mNV(0,array[index][0]);
    XST_mNV(1,array[index][1]);
    XSRETURN(2);
  } else {
    av = newAV();
    av_push(av, newSVnv( array[index][0] ));
    av_push(av, newSVnv( array[index][1] ));
    ST(0) = sv_2mortal(newRV((SV*) av));
    XSRETURN(1);
  }

void
double2_set(carray, index, value)
  Tie__CDoubleArray * carray
  int index
  AV * value
ALIAS:
    double2_STORE = 1
PREINIT:
  int i, len;
  double2 *array;
CODE:
  if ((index < 0) || (index >= carray->len/2))
    croak (ErrMsg_index);
  array = (double2 *) carray->ptr;
  len = min(av_len(value)+1,2);
  for (i=0; i<len; i++) {
    array[index][i] = SvNV(AvARRAY(value)[i]);
  }

AV *
double2_ToPar (carray, x=0, y=0)
  Tie__CDoubleArray * carray
  Tie__CDoubleArray * x  = (items > 1) ? x = (Tie__CDoubleArray *) SvRV(ST(1)) : NULL;
  Tie__CDoubleArray * y  = (items > 2) ? y = (Tie__CDoubleArray *) SvRV(ST(2)) : NULL;
PREINIT:
  int i, len;
  double2 *array;
CODE:
  len = carray->len / 2;
  array = (double2 *) carray->ptr;
  if (!x) {
    NEW_CARRAY(x,Tie__CDoubleArray,len,sizeof(NV));
  } else {
    CHECK_DERIVED_FROM(1,CDblNAME);
    MAYBE_GROW_CARRAY(x,Tie__CDoubleArray,len,sizeof(NV));
  }
  if (!y) {
    NEW_CARRAY(y,Tie__CDoubleArray,len,sizeof(NV));
  } else {
    CHECK_DERIVED_FROM(2,CDblNAME);
    MAYBE_GROW_CARRAY(y,Tie__CDoubleArray,len,sizeof(NV));
  }
  for (i=0; i < len; i++) {
    x->ptr[i] = array[i][0];
    y->ptr[i] = array[i][1];
  }
  RETVAL = newAV();
  av_push(RETVAL, sv_setref_pv(sv_newmortal(), CDblNAME, (void*)x));
  av_push(RETVAL, sv_setref_pv(sv_newmortal(), CDblNAME, (void*)y));
OUTPUT:
  RETVAL


MODULE = Tie::CArray     PACKAGE = Tie::CDouble3Array PREFIX = double3_
PROTOTYPES: DISABLE

int
double3_itemsize (carray)
  Tie__CDoubleArray * carray
CODE:
  RETVAL = sizeof(double3);
OUTPUT:
  RETVAL

void
double3_get (carray, index)
    Tie__CDoubleArray *carray
    int index
ALIAS:
    double3_FETCH = 1
PREINIT:
    double3 *array;
    AV *av;
CODE:
    if ((index < 0) || (index >= carray->len/3))
      croak (ErrMsg_index);
    array = (double3 *) carray->ptr;
    if (GIMME == G_ARRAY) {
      EXTEND(sp,1);
      XST_mNV(0,array[index][0]);
      XST_mNV(1,array[index][1]);
      XST_mNV(2,array[index][2]);
      XSRETURN(3);
    } else {
      av = newAV();
      av_push(av, newSVnv( array[index][0] ));
      av_push(av, newSVnv( array[index][1] ));
      av_push(av, newSVnv( array[index][2] ));
      ST(0) = sv_2mortal(newRV((SV*) av));
      XSRETURN(1);
    }

void
double3_set(carray, index, value)
  Tie__CDoubleArray * carray
  int index
  AV * value
ALIAS:
    double3_STORE = 1
PREINIT:
  int i, len;
  double3 *array;
CODE:
  if ((index < 0) || (index >= carray->len/3))
    croak (ErrMsg_index);
  array = (double3 *) carray->ptr;
  len = min(av_len(value)+1,3);
  for (i=0; i < len; i++) {
    array[index][i] = SvNV(AvARRAY(value)[i]);
  }

AV *
double3_ToPar (carray, x=0, y=0, z=0)
    Tie__CDoubleArray * carray
    Tie__CDoubleArray * x  = (items > 1) ? x = (Tie__CDoubleArray *) SvRV(ST(1)) : NULL;
    Tie__CDoubleArray * y  = (items > 2) ? y = (Tie__CDoubleArray *) SvRV(ST(2)) : NULL;
    Tie__CDoubleArray * z  = (items > 3) ? z = (Tie__CDoubleArray *) SvRV(ST(3)) : NULL;
PREINIT:
    int i, len;
    double3 *array;
CODE:
    len = carray->len / 3;
    array = (double3 *) carray->ptr;
    if (!x) {
      NEW_CARRAY(x,Tie__CDoubleArray,len,sizeof(NV));
    } else {
      CHECK_DERIVED_FROM(1,CDblNAME);
      MAYBE_GROW_CARRAY(x,Tie__CDoubleArray,len,sizeof(NV));
    }
    if (!y) {
      NEW_CARRAY(y,Tie__CDoubleArray,len,sizeof(NV));
    } else {
      CHECK_DERIVED_FROM(1,CDblNAME);
      MAYBE_GROW_CARRAY(y,Tie__CDoubleArray,len,sizeof(NV));
    }
    if (!z) {
      NEW_CARRAY(z,Tie__CDoubleArray,len,sizeof(NV));
    } else {
      CHECK_DERIVED_FROM(1,CDblNAME);
      MAYBE_GROW_CARRAY(z,Tie__CDoubleArray,len,sizeof(NV));
    }
    for (i=0; i < len; i++) {
      x->ptr[i] = array[i][0];
      y->ptr[i] = array[i][1];
      z->ptr[i] = array[i][2];
    }
    RETVAL = newAV();
    av_push(RETVAL, sv_setref_pv(sv_newmortal(), CDblNAME, (void*)x));
    av_push(RETVAL, sv_setref_pv(sv_newmortal(), CDblNAME, (void*)y));
    av_push(RETVAL, sv_setref_pv(sv_newmortal(), CDblNAME, (void*)z));
OUTPUT:
    RETVAL

MODULE = Tie::CArray     PACKAGE = Tie::CStringArray PREFIX = string_
PROTOTYPES: DISABLE

int
string_itemsize (carray, index=0)
  Tie__CStringArray * carray
  int index
CODE:
  if (!index)
    RETVAL = sizeof(char *);
  else
    if ((index < 0) || (index >= carray->len))
      croak (ErrMsg_index);
    else
      RETVAL = strlen(carray->ptr[index]);
OUTPUT:
  RETVAL

void
string_new (...)
ALIAS:
  string_TIEARRAY = 1
PPCODE:
  int len;
  AV * av;
  char **array, *s;
  Tie__CStringArray *carray;
  int i, avlen;
  /* */
  if (items < 1 || items > 3)
    croak("Usage: new Tie::CStringArray(len, [AVPtr])");
  {
    /* need to check for ->new invocation, we'll have 3 args then */
    if ( g_classname = mysv_classname(ST(0)) ) {
        len = (int)SvIV(ST(1));
        av   = (items == 3) ? av = (AV*)SvRV(ST(2)) : NULL;
    } else {
        g_classname = CStrNAME;
        len = (int)SvIV(ST(0));
        av   = (items == 2) ? av = (AV*)SvRV(ST(1)) : NULL;
    }
    NEW_CARRAY(carray,Tie__CStringArray,len,sizeof(char *));
    memset (carray->ptr, 0, len + carray->freelen);
    if (av) {
      if (!strEQ(g_classname,CStrNAME))
        warn("can only initialize %s", CStrNAME);
      else
        myarray_init(g_classname, (Tie__CArray *)carray, av);
    }
    EXTEND(sp,1); /* one more */
    ST(0) = sv_newmortal();
    sv_setref_pv(ST(0), g_classname, (void*)carray);
    XSRETURN(1);
  }


void
string_DESTROY(carray)
  Tie__CStringArray * carray
PREINIT:
  char **array, *old;
  int len, i = 0;
CODE:
#ifdef MYDEBUG_FREE
  DBG_PRINTF(("XSDbg: free (%p,->%p)\n",carray, carray->ptr));
#endif
  /* old = (char *) carray; */
  len   = carray->len;
  array = carray->ptr;
  if (array) {
      for (i=0; i<len; i++) {
        if (array[i]) safefree (array[i]);
        i++;
      }
      safefree (array);
  }
/*  SvROK_off(ST(0)); */
#ifdef MYDEBUG_FREE
  DBG_PRINTF((" unref (refSV: %d, RV: %p, IVRV: %p, refRV: %d)\n",
    SvREFCNT(ST(0)), SvRV(ST(0)), SvIV(SvRV(ST(0))), SvREFCNT(SvRV(ST(0))) ));
#endif

void
string_delete (carray, index)
  Tie__CStringArray * carray
  int index
CODE:
  /* deletes one item at index and shifts the rest */
  if ((index < 0) || (index >= carray->len))
    croak (ErrMsg_index);
  carray->freelen++;
  carray->len--;
  if (carray->ptr[index])
    safefree (carray->ptr[index]);
  memcpy (carray->ptr + index, carray->ptr + index+1,
          sizeof(char *) * (carray->len - index));

char *
string_get (carray, index)
    Tie__CStringArray * carray
    int   index
ALIAS:
    string_FETCH = 1
CODE:
  if ((index < 0) || (index >= carray->len))
    croak (ErrMsg_index);
  /* hmm, this fails the first time, but after nreverse it works okay... */
  RETVAL = strdup(carray->ptr[index]);
OUTPUT:
  RETVAL

void
string_set (carray, index, value)
    Tie__CStringArray * carray
    int index
    char *value
ALIAS:
    string_STORE = 1
PREINIT:
    char *s;
CODE:
    if ((index < 0) || (index >= carray->len))
        croak (ErrMsg_index);
    /* let the clib do that */
    s = (char *) saferealloc (carray->ptr[index], strlen(value)+1);
    carray->ptr[index] = s;
    strcpy (s, value);

Tie__CStringArray *
string_copy (carray)
  Tie__CStringArray * carray
PREINIT:
    SV * this = ST(0);
    int i, len;
    Tie__CStringArray * ncarray;
CODE:
    /* return a fresh copy
       this can only be "CStringArray" for now but maybe we derive from it later */
    len = carray->len;
    NEW_CARRAY(ncarray,Tie__CStringArray,len,sizeof(char *));
    for (i=0; i < len; i++) {
      ncarray->ptr[i] = strdup(carray->ptr[i]);
    }
    RETVAL = ncarray;
OUTPUT:
    RETVAL

AV *
string_list(carray)
  Tie__CStringArray * carray
PREINIT:
    int i, len;
    char **array;
CODE:
    RETVAL = newAV();
    len = carray->len;
    array = carray->ptr;
    for (i=0; i<len; i++ ) {
        av_push(RETVAL, sv_2mortal( newSVpv( array[i],0 )));
    }
OUTPUT:
  RETVAL

BOOT:
{   /* These are the XS provided protected itemsizes.
       You might add more in perl per class (but not readonly).
       Todo: we'll get rid of this, stored in the struct as elsize */
#ifdef OLD
    mysv_ivcreate (sizeof(IV),     "Tie::CIntArray::itemsize",    SVf_READONLY);
    mysv_ivcreate (sizeof(int2),   "Tie::CInt2Array::itemsize",   SVf_READONLY);
    mysv_ivcreate (sizeof(int3),   "Tie::CInt3Array::itemsize",   SVf_READONLY);
    mysv_ivcreate (sizeof(int4),   "Tie::CInt4Array::itemsize",   SVf_READONLY);
    mysv_ivcreate (sizeof(NV),     "Tie::CDoubleArray::itemsize", SVf_READONLY);
    mysv_ivcreate (sizeof(double2),"Tie::CDouble2Array::itemsize",SVf_READONLY);
    mysv_ivcreate (sizeof(double3),"Tie::CDouble3Array::itemsize",SVf_READONLY);
    mysv_ivcreate (sizeof(char *), "Tie::CStringArray::itemsize", SVf_READONLY);
#endif /* OLD */
    /* we could also get the stashes now, but... */
}
