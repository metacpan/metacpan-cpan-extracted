/*
 Copyright (C) 2008, 2010, 2011, 2012 Thomas Pfau tfpfau@gmail.com

 This module is free software.  You can redistribute it and/or modify
 it under the terms of the Artistic License 2.0.

 This module is distributed in the hope that it will be useful but it
 is provided "as is"and without any express or implied warranties.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <lib$routines.h>
#include <str$routines.h>
#include <starlet.h>
#include <descrip.h>
#include "cms$routines.h"

#include "const-c.inc"

#if !defined(__VAX)
#pragma __required_pointer_size 64
typedef unsigned int timeptr;
typedef int *string_id;
#pragma __required_pointer_size 32
#endif

/*
 * Arguments to CMS routines are passed by reference with unused optional
 * arguments specified as 0 (NULL).  The interface routines here will
 * use variables to hold pointers to the arguments to the routines.  These
 * variables will be initialized to NULL so that CMS will think they were
 * not specified.
 * 
 * Routines are provided to pull variables from the options hash passed in
 * the argument list.  These routines return either a pointer to the value
 * found in the hash or a NULL pointer to indicate that the option wasn't
 * specified.
 * 
 * The macros below should help make coding of interface routines quite
 * straightforward.  Declare variables to hold arguments using the DECL_*
 * macros.  Initialize string variables using STRING.  Use OPTIONS macro
 * to start processing the options hash (no semicolon after this macro).
 * The argument to this is the number of fixed arguments to the routine.
 * Get values for options using OPT_*  macros.  Finish options processing
 * with OPTIONS_END (no semicolon after this macro).  Call the CMS routine.
 * Then, release storage for varables using REL_* macros.  There should be
 * a one-to-one match between DECL_* and REL_* calls.
 */

/* Declare a variable to hold an argument to a CMS routine */
#define DECL_STRING(x) struct dsc$descriptor *x = NULL
#define DECL_INT(x) int *x = NULL
#define DECL_TIME(x) long long *x = NULL

/* Allocate a string descriptor for a character string */
#define STRING(v,a) v = string_desc(a)

/* Initialize for getting optional arguments from the hash */
#define OPTIONS(n) \
    if (items > n) \
    { \
        HV *opt; \
	if (!SvROK(ST(n)) || (SvTYPE(SvRV(ST(n))) != SVt_PVHV)) \
	   croak(sNotHash); \
        opt = (HV *) SvRV(ST(n));

/* Get values for optional arguments */
#define OPT_STRING(v,n) v = get_hash_string_desc(opt, n)
#define OPT_INT(v,n) v = get_hash_int(opt,n)
#define OPT_TIME(v, n) v = get_hash_time(opt, n)

/* End options processing */
#define OPTIONS_END }

/* Free dynamic space used by options variables */
#define REL_STRING(v) if (v) free_desc(v)
#define REL_INT(v) if (v) free(v)
#define REL_TIME(v) if (v) free(v)

/* Store a value in a hash */
#define PUT_HASH(h,k,v) hv_store(h, k, strlen(k), v, 0)

/* Strings collected here */
static const char
    *sAbsolute = "ABSOLUTE",
    *sAccept = "ACCEPT",
    *sAccess = "ACCESS",
    *sAfter = "AFTER",
    *sAfterGeneration = "AFTER_GENERATION",
    *sAlways = "ALWAYS",
    *sAncestors = "ANCESTORS",
    *sAppend = "APPEND",
    *sArchiveFile = "ARCHIVE_FILE",
    *sAttributes = "ATTRIBUTES",
    *sBefore = "BEFORE",
    *sBeforeGeneration = "BEFORE_GENERATION",
    *sBeginSentinal = "BEGIN_SENTINAL",
    *sBrief = "BRIEF",
    *sCancel = "CANCEL",
    *sClass = "CLASS",
    *sClasses = "CLASSES",
    *sClassList = "CLASS_LIST",
    *sCommand = "COMMAND",
    *sConcurrent = "CONCURRENT",
    *sContents = "CONTENTS",
    *sCopy = "COPY",
    *sCreate = "CREATE",
    *sCreationTime = "CREATION_TIME",
    *sDelete = "DELETE",
    *sDeleteFile = "DELETE_FILE",
    *sDescendants = "DESCENDANTS",
    *sElement = "ELEMENT",
    *sElements = "ELEMENTS",
    *sEndSentinal = "END_SENTINAL",
    *sEOF = "EOF",
    *sExtendedNames = "EXTENDED_NAMES",
    *sFetch = "FETCH",
    *sFilename = "FILENAME",
    *sFilename1 = "FILENAME1",
    *sFilename2 = "FILENAME2",
    *sFirstCall = "FIRST_CALL",
    *sFormat = "FORMAT",
    *sFromGeneration = "FROM_GENERATION",
    *sFull = "FULL",
    *sGeneration = "GENERATION",
    *sGeneration1 = "GENERATION1",
    *sGeneration2 = "GENERATION2",
    *sGroup = "GROUP",
    *sGroupList = "GROUP_LIST",
    *sGroups = "GROUPS",
    *sHistory = "HISTORY",
    *sIdentification = "IDENTIFICATION",
    *sIfAbsent = "IF_ABSENT",
    *sIfChanged = "IF_CHANGED",
    *sIfPresent = "IF_PRESENT",
    *sIgnore = "IGNORE",
    *sInputFile = "INPUT_FILE",
    *sInsert = "INSERT",
    *sLevel = "LEVEL",
    *sKeep = "KEEP",
    *sMark = "MARK",
    *sMembers = "MEMBERS",
    *sMergeGeneration = "MERGE_GENERATION",
    *sModify = "MODIFY",
    *sNewName = "NEW_NAME",
    *sNewRemark = "NEW_REMARK",
    *sNoHistory = "NOHISTORY",
    *sNoNotes = "NONOTES",
    *sNoOutput = "NOOUTPUT",
    *sNotes = "NOTES",
    *sNotHash = "Options argument should be a hash ref",
    *sObject = "OBJECT",
    *sObjectName = "OBJECT_NAME",
    *sOutputFile = "OUTPUT_FILE",
    *sOutputRecord = "OUTPUT_RECORD",
    *sOutputRoutine = "OUTPUT_ROUTINE",
    *sPageBreak = "PAGE_BREAK",
    *sParallel = "PARALLEL",
    *sPath = "PATH",
    *sPosition = "POSITION",
    *sReadOnly = "READ_ONLY",
    *sRecordSize = "RECORD_SIZE",
    *sRecover = "RECOVER",
    *sReferenceCopy = "REFERENCE_COPY",
    *sReject = "REJECT",
    *sRemark = "REMARK",
    *sRemove = "REMOVE",
    *sRepair = "REPAIR",
    *sReplace = "REPLACE",
    *sReserve = "RESERVE",
    *sReservation = "RESERVATION",
    *sReservations = "RESERVATIONS",
    *sReview = "REVIEW",
    *sReviewer = "REVIEWER",
    *sReviewsPending = "REVIEWS_PENDING",
    *sReviewRemark = "REVIEW_REMARK",
    *sReviewStatus = "REVIEW_STATUS",
    *sReviewTime = "REVIEW_TIME",
    *sRevision = "REVISION",
    *sRevisionTime = "REVISION_TIME",
    *sSetAcl = "SET ACL",
    *sSince = "SINCE",
    *sSkipLines = "SKIP_LINES",
    *sSourceLdb = "SOURCE_LDB",
    *sSupersede = "SUPERSEDE",
    *sTime = "TIME",
    *sToGeneration = "TO_GENERATION",
    *sTransactionMask = "TRANSACTION_MASK",
    *sTransactionTime = "TRANSACTION_TIME",
    *sUnreserve = "UNRESERVE",
    *sUnusual = "UNUSUAL",
    *sUser = "USER",
    *sUserArg = "USER_ARG",
    *sVariant = "VARIANT",
    *sVerify = "VERIFY",
    *sWidth = "WIDTH";

/* allocate a dynamic string descriptor */
struct dsc$descriptor *alloc_desc(short len)
{
    struct dsc$descriptor *desc;
    desc = (struct dsc$descriptor *)calloc(1,sizeof(struct dsc$descriptor));
    desc->dsc$a_pointer = 0;
    desc->dsc$b_class = DSC$K_CLASS_D;
    desc->dsc$b_dtype = DSC$K_DTYPE_VT;
    desc->dsc$w_length = 0;
    str$get1_dx(&len, desc);
    return desc;
}

/* free a string descriptor */
void free_desc(struct dsc$descriptor *desc)
{
    if (desc->dsc$b_class == DSC$K_CLASS_D)
        str$free1_dx(desc);
    free(desc);
}

/* convert string by descriptor to SV */
SV *desc_to_sv(struct dsc$descriptor *desc)
{
    short len;
    char *str;
    lib$analyze_sdesc(desc, &len, &str);
    return newSVpvn(str, len);
}

/* return a descriptor for a static string */
struct dsc$descriptor *string_desc(char *str)
{
    struct dsc$descriptor *desc;
    desc = (struct dsc$descriptor *)calloc(1,sizeof(struct dsc$descriptor));
    desc->dsc$b_class = DSC$K_CLASS_S;
    desc->dsc$b_dtype = DSC$K_DTYPE_T;
    desc->dsc$a_pointer = str;
    desc->dsc$w_length = strlen(str);
    return desc;
}

/* get an entry from a hash and return as descriptor */
struct dsc$descriptor *get_hash_string_desc(HV *hv, const char *key)
{
    SV **sv;
    struct dsc$descriptor *desc;
    sv = hv_fetch(hv, key, strlen(key), 0);
    if (sv == 0) return 0;
    desc = (struct dsc$descriptor *)calloc(1,sizeof(struct dsc$descriptor));
    desc->dsc$b_class = DSC$K_CLASS_S;
    desc->dsc$b_dtype = DSC$K_DTYPE_T;
    desc->dsc$a_pointer = SvPV_nolen(*sv);
    desc->dsc$w_length = SvCUR(*sv);
    return desc;
}

/* get an entry from a hash and return as integer */
int *get_hash_int(HV *hv, const char *key)
{
    SV **sv;
    int *i;
    sv = hv_fetch(hv, key, strlen(key), 0);
    if (sv == 0) return 0;
    if (!SvIOK(*sv)) return 0;
    i = malloc(sizeof(int));
    *i = SvIV(*sv);
    return i;
}

long long *get_hash_time(HV *hv, const char *key)
{
    struct dsc$descriptor *time_desc = NULL;
    long long *time_bin = NULL;
    time_desc = get_hash_string_desc(hv, key);
    if (time_desc)
    {
	time_bin = malloc(sizeof(long long));
	sys$bintim(time_desc, time_bin);
	free_desc(time_desc);
    }
    return time_bin;
}

SV *get_string_sv(string_addr id)
{
    SV *sv;
    struct dsc$descriptor *dsc = (struct dsc$descriptor *)*id;
    if ( ( dsc->dsc$w_length == 1 ) && ( (int)dsc->dsc$a_pointer == -1 ) )
    {
	long long llen;
	long long lptr;
	struct dsc$descriptor *desc;
	str$analyze_sdesc_64(*id, &llen, &lptr);
	desc = alloc_desc(llen);
	str$copy_r_64(desc, &llen, lptr);
	sv = desc_to_sv(desc);
	free_desc(desc);
    }
    else
    {
	short len;
	char *loc;
	str$analyze_sdesc(*id, &len, &loc);
	sv = newSVpvn(loc, len);
    }
    return sv;
}

static AV *msg_av;
static AV *msg_struct_av;

/* Convert a signal array into a message and its arguments */
void process_message(int *signal_array)
{
    char buf[132];
    $DESCRIPTOR(bufadr, buf);
    char *cp;
    unsigned short msglen;
    int *argp = &signal_array[3];
    HV *hash = newHV();		/* this will hold the message and arguments */
    AV *args = newAV();		/* list of arguments */
    int sts;

    /* first, get the message text */
    sts = sys$getmsg( signal_array[1], &msglen, &bufadr, 15, 0 );
    if (!(sts & 1))
    {
	fprintf( stderr, "error %d from getmsg\n", sts );
	return;
    }
    buf[msglen] = 0;
    /* start building the hash */
    PUT_HASH(hash, "MessageId", newSViv(signal_array[1]));
    PUT_HASH(hash, "Message", newSVpvn(buf,msglen));
    PUT_HASH(hash, "Args", newRV_noinc((SV *)args));
    cp = buf;
    /* locate FAO descriptors in message */
    while ( (cp = strchr(cp, '!')) != NULL )
    {
	int ctrstr[2];
	char tran[255];
	$DESCRIPTOR(trandsc, tran);
	unsigned short retlen;

	/* skip plurals, no argument */
	if (strncmp(cp, "!%S", 3) == 0)
	{
	    cp += 3;
	    continue;
	}
	ctrstr[0] = 3;
	ctrstr[1] = (int)cp;
	/* call fao to translate argument to string */
	sts = sys$fao( ctrstr, &retlen, &trandsc, *argp++ );
	if (!(sts & 1))
	    fprintf( stderr, "error %d from fao\n", sts );
	tran[retlen] = 0;

	/* push translated argument onto list */
	av_push(args, newSVpvn(tran, retlen));
	cp += 3;
    }
    /* save result */
    av_push(msg_struct_av,newRV_noinc((SV *)hash));
}

/* save formatted status messages */
int put_routine(struct dsc$descriptor *str, void *userarg)
{
    SV *sv;
    sv = newSVpvn(str->dsc$a_pointer, str->dsc$w_length);
    av_push(msg_av, sv);
    return 0;
}

/*
 * Message output routine
 */
int msg_routine(int *signal_array, int *mech_array, ldb_cntrlblk *ldb)
{
    int x;
    /* save details */
    process_message(signal_array);
    signal_array[0] -= 2;
    /* save formatted messages */
    sys$putmsg(signal_array, put_routine, 0, 0);
    signal_array[0] += 2;
    return 1;
}

/* clear saved messages for a new cms call */
void clear_messages()
{
    if (msg_av == NULL)
        msg_av = newAV();
    else
        av_clear(msg_av);
    if (msg_struct_av == NULL)
        msg_struct_av = newAV();
    else
        av_clear(msg_struct_av);
}

/*
 show reservations callback:
   (new_element, ldb, userarg, element_id, generation_id, time, user_id,
    remark_id, concurrent, merge_generation_id, nonotes, nohistory, access)
  new_element: 0 = info about next element matching element expression
               1 = first call to output routine
               2 = info about same element as previous call
  access: 0 = concurrent allowed, 1 = concurrent not allowed, 2 = existing
           reservation does not allow other reservations
*/
static int
    show_reservations_callback(int *new_element, ldb_cntrlblk *ldb,
			       AV *userarg, int *element_id,
			       int *generation_id, timeptr trans_time,
			       int *user_id, int *remark_id, int *concurrent,
			       int *merge_gen_id, int *nonotes,
			       int *nohistory, int *access, int *reservation_id)
{
    char timbuf[24];
    $DESCRIPTOR(timdsc,timbuf);
    HV *hv = newHV();
    PUT_HASH(hv, sElement, get_string_sv(element_id));
    PUT_HASH(hv, sGeneration, get_string_sv(generation_id));

    unsigned long long ll = trans_time;
    sys$asctim(0, &timdsc, ll, 0);
    PUT_HASH(hv, sTime, newSVpvn(timbuf, 23));

    PUT_HASH(hv, sUser, get_string_sv(user_id));
    PUT_HASH(hv, sRemark, get_string_sv(remark_id));
    PUT_HASH(hv, sConcurrent, newSViv(*concurrent));
    PUT_HASH(hv, sMergeGeneration, get_string_sv(merge_gen_id));
    PUT_HASH(hv, sNoNotes, newSViv(*nonotes));
    PUT_HASH(hv, sNoHistory, newSViv(*nohistory));
    PUT_HASH(hv, sAccess, newSViv(*access));
    PUT_HASH(hv, sReservation, newSViv(*reservation_id));
    av_push(userarg, (SV *) newRV_noinc((SV *) hv));
    return CMS$_NORMAL;
}

/*
 show element callback: (firstcall, ldb, userarg, element_id, remark_id,
                         history_id, notes_id, position, concurrent,
                         reference_copy, group_list_id, review)
*/
static int
    show_element_callback(int *firstcall, ldb_cntrlblk *ldb, AV *userarg,
			  int *element_id, int *remark_id, int *history_id,
			  int *notes_id, int *position, int *concurrent,
			  int *reference_copy, int *group_list_id, int *review)
{
    HV *hv = newHV();
    PUT_HASH(hv, sElement, get_string_sv(element_id));
    PUT_HASH(hv, sRemark, get_string_sv(remark_id));
    PUT_HASH(hv, sHistory, get_string_sv(history_id));
    PUT_HASH(hv, sNotes, get_string_sv(notes_id));
    PUT_HASH(hv, sPosition, newSViv(*position));
    PUT_HASH(hv, sConcurrent, newSViv(*concurrent));
    PUT_HASH(hv, sReferenceCopy, newSViv(*reference_copy));
    PUT_HASH(hv, sGroupList, get_string_sv(group_list_id));
    PUT_HASH(hv, sReview, newSViv(*review));
    av_push(userarg, (SV *) newRV_noinc((SV *) hv));
    return CMS$_NORMAL;
}

/*
 show_class
  callback: (firstcall, ldb, userarg, class_id, remark_id, readonly)
*/
static int
    show_class_callback(int *firstcall, ldb_cntrlblk *ldb, AV *userarg,
			int *class_id, int *remark_id, int *read_only)
{
    HV *hv = newHV();
    PUT_HASH(hv, sClass, get_string_sv(class_id));
    PUT_HASH(hv, sRemark, get_string_sv(remark_id));
    PUT_HASH(hv, sReadOnly, newSViv(*read_only));
    av_push(userarg, (SV *) newRV_noinc((SV *) hv));
    return CMS$_NORMAL;
}
			    
/*
 show_generation
  callback: (new_element, ldb, userarg, element_id, generation_id,
             user_id, trans_time, creation_time, revision_time, remark_id,
             class_list_id, format, attributes, revision_number,
             reservations, recordsize, review_status)
*/
static int
    show_generation_callback(int new_elem, ldb_cntrlblk *ldb, AV *userarg,
			     int *element_id, int *generation_id,
			     int *user_id, timeptr trans_time,
			     timeptr creation_time,
			     timeptr revision_time, int *remark_id,
			     int *class_list_id, int *format,
			     int *attributes, int *revision,
			     int *reservations, int *recordsize,
			     int *review_status)
{
    char timbuf[24];
    $DESCRIPTOR(timdsc,timbuf);
    HV *hv = newHV();
    PUT_HASH(hv, sElement, get_string_sv(element_id));
    PUT_HASH(hv, sGeneration, get_string_sv(generation_id));
    PUT_HASH(hv, sUser, get_string_sv(user_id));
    PUT_HASH(hv, sRemark, get_string_sv(remark_id));
    PUT_HASH(hv, sClassList, get_string_sv(class_list_id));
    PUT_HASH(hv, sFormat, newSViv(*format));
    PUT_HASH(hv, sAttributes, newSViv(*attributes));
    PUT_HASH(hv, sRevision, newSViv(*revision));
    PUT_HASH(hv, sReservations, newSViv(*reservations));
    PUT_HASH(hv, sRecordSize, newSViv(*recordsize));
    PUT_HASH(hv, sReviewStatus, newSViv(*review_status));

    unsigned long long ll = trans_time;
    sys$asctim(0, &timdsc, ll, 0);
    PUT_HASH(hv, sTransactionTime, newSVpvn(timbuf, 23));

    ll = creation_time;
    sys$asctim(0, &timdsc, ll, 0);
    PUT_HASH(hv, sCreationTime, newSVpvn(timbuf, 23));

    ll = revision_time;
    sys$asctim(0, &timdsc, ll, 0);
    PUT_HASH(hv, sRevisionTime, newSVpvn(timbuf, 23));

    av_push(userarg, (SV *) newRV_noinc((SV *) hv));
    return CMS$_NORMAL;
}

/*
 show_group
  callback: (firstcall, ldb, userarg, group_id, remark_id,
             readonly, level, contents_id)
*/
static int
    show_group_callback(int firstcall, ldb_cntrlblk *ldb, AV *userarg,
			int *group_id, int *remark_id, int *read_only,
			int *level, int *contents_id)
{
    HV *hv = newHV();
    PUT_HASH(hv, sGroup, get_string_sv(group_id));
    PUT_HASH(hv, sRemark, get_string_sv(remark_id));
    PUT_HASH(hv, sReadOnly, newSViv(*read_only));
    PUT_HASH(hv, sLevel, newSViv(*level));
    PUT_HASH(hv, sContents, get_string_sv(contents_id));
    av_push(userarg, (SV *) newRV_noinc((SV *) hv));
    return CMS$_NORMAL;
}

static int
    show_history_callback(int firstcall, ldb_cntrlblk *ldb, AV *userarg,
			  timeptr timep, int *user_id, int *command_id,
			  int *object_id, int *remark_id, int *unusual)
{
    char timbuf[24];
    $DESCRIPTOR(timdsc,timbuf);
    HV *hv = newHV();

    unsigned long long ll = timep;
    sys$asctim(0, &timdsc, ll, 0);
    PUT_HASH(hv, sTransactionTime, newSVpvn(timbuf, 23));

    PUT_HASH(hv, sUser, get_string_sv(user_id));
    PUT_HASH(hv, sCommand, get_string_sv(command_id));
    PUT_HASH(hv, sObject, get_string_sv(object_id));
    PUT_HASH(hv, sRemark, get_string_sv(remark_id));
    PUT_HASH(hv, sUnusual, newSViv(*unusual));
    av_push(userarg, (SV *) newRV_noinc((SV *) hv));
    return CMS$_NORMAL;
}

static int
    show_reviews_pending_callback(int new_element, ldb_cntrlblk *ldb,
				  AV *userarg, int *element_id,
				  int *generation_id, timeptr gen_time,
				  int *gen_user_id, int *gen_remark_id,
				  timeptr review_time, int *review_user_id,
				  int *review_remark_id)
{
    char timbuf[24];
    $DESCRIPTOR(timdsc, timbuf);
    HV *hv = newHV();
    PUT_HASH(hv, sElement, get_string_sv(element_id));
    PUT_HASH(hv, sGeneration, get_string_sv(generation_id));

    unsigned long long ll = gen_time;
    sys$asctim(0, &timdsc, ll, 0);
    PUT_HASH(hv, sTransactionTime, newSVpvn(timbuf, 23));

    PUT_HASH(hv, sUser, get_string_sv(gen_user_id));
    PUT_HASH(hv, sRemark, get_string_sv(gen_remark_id));

    ll = review_time;
    sys$asctim(0, &timdsc, ll, 0);
    PUT_HASH(hv, sReviewTime, newSVpvn(timbuf, 23));

    PUT_HASH(hv, sReviewer, get_string_sv(review_user_id));
    PUT_HASH(hv, sReviewRemark, get_string_sv(review_remark_id));
    av_push(userarg, (SV *) newRV_noinc((SV *) hv));
    return CMS$_NORMAL;
}

/*
 * if the user provides an input or output routine, this structure
 * will be used to hold the reference to the sub and the user
 * argument.  the C callback routine will be passed a reference to it
 * and will use its contents to call the user's code.
 */
struct callback_args {
    SV *routine;
    SV *user_arg;
};

int output_callback( int *first_call, void *ldb, struct callback_args *args,
		     int *outrec, int *eof, int *filename, int *action )
{
    int count, retval;
    HV *hv = newHV();
    PUT_HASH(hv, sFirstCall, newSViv(*first_call));
    PUT_HASH(hv, sOutputRecord, get_string_sv(outrec));
    PUT_HASH(hv, sEOF, newSViv(*eof));
    if (*filename)
    	PUT_HASH(hv, sFilename, get_string_sv(filename));
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_noinc((SV *)hv)));
    if (args->user_arg)
	XPUSHs(args->user_arg);
    PUTBACK;
    count = call_sv( args->routine, G_SCALAR );
    SPAGAIN;
    if ( count != 1 )
        croak("expected one return value");
    retval = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return retval;
}

/* callback (first_call, ldb, userarg, element_id, output_record_id, eof) */
/*
static int
    annotate_callback(int first_call, ldb_cntrlblk *ldb, AV *userarg,
		      int *element_id, int *record_id, int *eof)
{
    
}
*/

/************************************************************************/

MODULE = VMS::CMS		PACKAGE = VMS::CMS		

INCLUDE: const-xs.inc

##CMS Version

########################################################################
# show_version (doc)
SV *
show_version()
  CODE:
    HV *hv;
    struct dsc$descriptor *brief, *full;
    int bin;
    brief = alloc_desc(16);
    full = alloc_desc(64);
    cms$show_version(full, brief, &bin);
    hv = newHV();
    PUT_HASH(hv, sBrief, desc_to_sv(brief));
    PUT_HASH(hv, sFull, desc_to_sv(full));
    PUT_HASH(hv, sAbsolute, newSViv(bin));
    free_desc(brief);
    free_desc(full);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

########################################################################
# new (doc)
ldb_cntrlblk *
new()
  CODE:
    RETVAL = (ldb_cntrlblk *) calloc(1, sizeof(ldb_cntrlblk));
  OUTPUT:
    RETVAL

########################################################################
# get_messages (doc)
SV *
get_messages()
  CODE:
    RETVAL = newRV((SV *)msg_av);
  OUTPUT:
    RETVAL

# get_message_details
SV *
get_message_details()
  CODE:
    RETVAL = newRV((SV *)msg_struct_av);
  OUTPUT:
    RETVAL

########################################################################
# transaction_mask (doc)
int
transaction_mask(...)
  CODE:
    int i, l=items,mask=0;
    for (i=0; i<l; i++)
    {
	char *str = SvPV_nolen(ST(i));
        if (strcmp(str, sCopy) == 0)
	    mask |= 1;
	else if (strcmp(str, sCreate) == 0)
	    mask |= 2;
	else if (strcmp(str, sDelete) == 0)
	    mask |= 4;
	else if (strcmp(str, sFetch) == 0)
	    mask |= 8;
	else if (strcmp(str, sInsert) == 0)
	    mask |= 16;
	else if (strcmp(str, sModify) == 0)
	    mask |= 32;
	else if (strcmp(str, sRemark) == 0)
	    mask |= 64;
	else if (strcmp(str, sRemove) == 0)
	    mask |= 128;
	else if (strcmp(str, sReplace) == 0)
	    mask |= 256;
	else if (strcmp(str, sReserve) == 0)
	    mask |= 512;
	else if (strcmp(str, sUnreserve) == 0)
	    mask |= 1024;
	else if (strcmp(str, sVerify) == 0)
	    mask |= 2048;
	else if (strcmp(str, sSetAcl) == 0)
	    mask |= 16384;
	else if (strcmp(str, sAccept) == 0)
	    mask |= 65536;
	else if (strcmp(str, sCancel) == 0)
	    mask |= 131072;
	else if (strcmp(str, sMark) == 0)
	    mask |= 262144;
	else if (strcmp(str, sReject) == 0)
	    mask |= 524288;
	else if (strcmp(str, sReview) == 0)
	    mask |= 1048576;
    }
    RETVAL = mask;
  OUTPUT:
    RETVAL

########################################################################
void
DESTROY(ldb)
    ldb_cntrlblk *ldb
  CODE:
    free(ldb);

########################################################################
##Library Routines
########################################################################

########################################################################
# create_library (doc)
SV *
create_library(ldb, path, ...)
    ldb_cntrlblk *ldb;
    char *path;
  CODE:
    int sts;
    SV **SVpos;
    int *position = NULL;
    DECL_STRING(pathd);
    DECL_STRING(remarkd);
    DECL_STRING(refcopyd);
    DECL_STRING(refpathd);
    DECL_INT(cre);
    DECL_INT(keep);
    DECL_INT(revtime);
    DECL_INT(concurrent);
    DECL_INT(extnames);
    STRING(pathd, path);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(refcopyd, sReferenceCopy);
    OPT_STRING(refpathd, sPath);
    OPT_INT(cre, sCreate);
    OPT_INT(keep, sKeep);
    OPT_INT(revtime, sRevisionTime);
    OPT_INT(concurrent, sConcurrent);
    OPT_INT(extnames, sExtendedNames);
        SVpos = hv_fetch(opt, sPosition, strlen(sPosition), 0);
        if (SVpos != NULL)
        {
            static int v[] = { 0, 1, 2 };
            if (strcmp(SvPV_nolen(*SVpos), sSupersede))
                position = &v[0];
            else if (strcmp(SvPV_nolen(*SVpos), sAfter))
                position = &v[1];
            else if (strcmp(SvPV_nolen(*SVpos), sBefore))
                position = &v[2];
        }
    OPTIONS_END
    clear_messages();
    sts = cms$create_library(ldb, pathd, remarkd, refcopyd, msg_routine,
                                0, 0, 0, position, refpathd, revtime, cre,
                                concurrent, 0, keep, extnames);
    REL_STRING(pathd);
    REL_STRING(remarkd);
    REL_STRING(refcopyd);
    REL_STRING(refpathd);
    REL_INT(cre);
    REL_INT(keep);
    REL_INT(revtime);
    REL_INT(concurrent);
    REL_INT(extnames);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# set_library (doc)
SV *
set_library(ldb,path,...)
    ldb_cntrlblk *ldb
    char *path
  CODE:
    int sts;
    SV **SVpos;
    int *position = NULL;
    DECL_STRING(pathd);
    DECL_STRING(refpathd);
    DECL_INT(verify);
    STRING(pathd, path);
    OPTIONS(2)
    OPT_STRING(refpathd, sPath);
    OPT_INT(verify, sVerify);
        SVpos = hv_fetch(opt, sPosition, strlen(sPosition), 0);
        if (SVpos != NULL)
        {
            static int v[] = { 0, 1, 2 };
            if (strcmp(SvPV_nolen(*SVpos), sSupersede))
                position = &v[0];
            else if (strcmp(SvPV_nolen(*SVpos), sAfter))
                position = &v[1];
            else if (strcmp(SvPV_nolen(*SVpos), sBefore))
                position = &v[2];
        }
    OPTIONS_END
    clear_messages();
    sts = cms$set_library(ldb, pathd, msg_routine, verify, 0, 0, 0,
                             position, refpathd);
    REL_STRING(pathd);
    REL_STRING(refpathd);
    REL_INT(pathd);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# set_nolibrary (doc)
SV *
set_nolibrary(ldb,...)
    ldb_cntrlblk *ldb
  CODE:
    int sts;
    DECL_STRING(pathd);
    if (items > 1)
    {
        pathd = string_desc(SvPV_nolen(ST(1)));
    }
    sts = cms$set_nolibrary(ldb,pathd);
    REL_STRING(pathd);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# modify_library (doc)
SV *
modify_library(ldb,...)
    ldb_cntrlblk *ldb
  CODE:
    int sts;
    DECL_STRING(remarkd);
    DECL_STRING(refpathd);
    DECL_INT(keep);
    DECL_INT(revtime);
    DECL_INT(concurrent);
    DECL_INT(extnames);
    OPTIONS(1)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(refpathd, sReferenceCopy);
    OPT_INT(keep, sKeep);
    OPT_INT(revtime, sRevisionTime);
    OPT_INT(concurrent, sConcurrent);
    OPT_INT(extnames, sExtendedNames);
    OPTIONS_END
    clear_messages();
    sts = cms$modify_library(ldb, remarkd, refpathd, msg_routine, revtime,
                                concurrent, 0, keep, extnames);
    REL_STRING(remarkd);
    REL_STRING(refpathd);
    REL_INT(keep);
    REL_INT(revtime);
    REL_INT(concurrent);
    REL_INT(extnames);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# remark (doc)
SV *
remark(ldb,remark,...)
    ldb_cntrlblk *ldb
    char *remark
  CODE:
    int sts;
    DECL_STRING(remarkd);
    DECL_INT(unusual);
    STRING(remarkd, remark);
    OPTIONS(2)
    OPT_INT(unusual, sUnusual);
    OPTIONS_END
    clear_messages();
    sts = cms$remark(ldb, remarkd, msg_routine, unusual);
    REL_STRING(remarkd);
    REL_INT(unusual);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# show_library (doc)
SV *
show_library(ldb,...)
    ldb_cntrlblk *ldb
  CODE:
    HV *hv;
    int sts;
    int stats[10];
    struct dsc$descriptor *refcopyd;
    DECL_INT(verify);
    OPTIONS(1)
    OPT_INT(verify, sVerify);
    OPTIONS_END
    refcopyd = alloc_desc(256);
    clear_messages();
    sts = cms$show_library(ldb, refcopyd, stats, msg_routine, verify, 0, 0);
    if (!(sts & 1))
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
    else
    {
        hv = newHV();
        PUT_HASH(hv, sReferenceCopy, desc_to_sv(refcopyd));
        PUT_HASH(hv, sElements, newSViv(stats[0]));
        PUT_HASH(hv, sGroups, newSViv(stats[1]));
        PUT_HASH(hv, sClasses, newSViv(stats[2]));
        PUT_HASH(hv, sReservations, newSViv(stats[3]));
        PUT_HASH(hv, sConcurrent, newSViv(stats[4]));
        PUT_HASH(hv, sReviewsPending, newSViv(stats[5]));
        RETVAL = newRV_noinc((SV *)hv);
	SETERRNO(0, sts);
    }
    free_desc(refcopyd);
    REL_INT(verify);
  OUTPUT:
    RETVAL

########################################################################
# delete_history
SV *
delete_history(ldb, ...)
    ldb_cntrlblk *ldb
  CODE:
    int sts;
    DECL_STRING(remarkd);
    DECL_INT(mask);
    DECL_TIME(before);
    OPTIONS(1)
    OPT_STRING(remarkd, sRemark);
    OPT_INT(mask, sTransactionMask);
    OPT_TIME(before, sBefore);
    OPTIONS_END
    clear_messages;
    sts = cms$delete_history(ldb,remarkd,before,mask,0,0,msg_routine);
    REL_STRING(remarkd);
    REL_INT(mask);
    REL_TIME(before);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# show_history (doc)
SV *
show_history(ldb,...)
    ldb_cntrlblk *ldb
  CODE:
    AV *av;
    int sts;
    DECL_STRING(objectd);
    DECL_STRING(userd);
    DECL_TIME(beforep);
    DECL_TIME(sincep);
    DECL_INT(mask);
    OPTIONS(1)
    OPT_STRING(objectd, sObjectName);
    OPT_STRING(userd, sUser);
    OPT_TIME(beforep, sBefore);
    OPT_TIME(sincep, sSince);
    OPT_INT(mask, sTransactionMask);
    OPTIONS_END
    av = newAV();
    clear_messages();
    sts = cms$show_history(ldb, show_history_callback, av, objectd, userd,
			   beforep, sincep, mask, msg_routine);
    REL_STRING(objectd);
    REL_STRING(userd);
    REL_TIME(beforep);
    REL_TIME(sincep);
    REL_INT(mask);
    if (sts & 1)
    {
        RETVAL = newRV_noinc((SV *) av);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# show_reservations (doc)
#  @elements = $libobj->show_reservations({ELEMENT=>$element,
#                                          USER=>$user,
#					   GENERATION=>$generation,
#					   IDENTIFICATION=>$id})
SV *
show_reservations(ldb,...)
    ldb_cntrlblk *ldb
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(generationd);
    DECL_STRING(userd);
    DECL_INT(ident);
    AV *av = newAV();
    OPTIONS(1)
    OPT_STRING(elementd, sElement);
    OPT_STRING(generationd, sGeneration);
    OPT_STRING(userd, sUser);
    OPT_INT(ident, sIdentification);
    OPTIONS_END
    clear_messages();
    sts = cms$show_reservations(ldb, show_reservations_callback, av,
		    	        elementd, generationd, userd, msg_routine,
			        ident);
    REL_STRING(elementd);
    REL_STRING(generationd);
    REL_STRING(userd);
    REL_INT(ident);
    if (sts & 1)
    {
        RETVAL = newRV_noinc((SV *) av);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# verify
SV *
verify(ldb, ...)
    ldb_cntrlblk *ldb
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(remarkd);
    DECL_INT(recover);
    DECL_INT(repair);
    OPTIONS(1)
    OPT_STRING(elementd, sElement);
    OPT_STRING(remarkd, sRemark);
    OPT_INT(recover, sRecover);
    OPT_INT(repair, sRepair);
    OPTIONS_END
    clear_messages();
    sts = cms$verify(ldb, elementd, remarkd, recover, repair, msg_routine);
    REL_STRING(elementd);
    REL_STRING(remarkd);
    REL_INT(recover);
    REL_INT(repair);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
#Element Routines
########################################################################

########################################################################
# annotate
# cms$annotate(ldb, elem, gen, merge_gen, append, full, outfile, outrtn,
#              userarg, msg_routine, format)
# format = ASCII(1), DECIMAL(2), HEX(4), OCTAL(8)
# 	   BYTE(65536), LONGWORD(131072), RECORDS(262144), WORD(524288)
# callback (first_call, ldb, userarg, element_id, output_record_id, eof)
SV *
annotate(ldb, elem, ...)
    ldb_cntrlblk *ldb
    char *elem
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(generationd);
    DECL_STRING(merge_gend);
    DECL_STRING(outfiled);
    DECL_INT(append);
    DECL_INT(full);
    DECL_INT(format);
    STRING(elementd, elem);
    OPTIONS(2)
    OPT_STRING(generationd, sGeneration);
    OPT_STRING(merge_gend, sMergeGeneration);
    OPT_STRING(outfiled, sOutputFile);
    OPT_INT(append, sAppend);
    OPT_INT(full, sFull);
    OPT_INT(format, sFormat);
    OPTIONS_END
    clear_messages();
    sts = cms$annotate(ldb, elementd, generationd, merge_gend, append,
			  full, outfiled, 0, 0, msg_routine, format);
    REL_STRING(elementd);
    REL_STRING(generationd);
    REL_STRING(merge_gend);
    REL_STRING(outfiled);
    REL_INT(append);
    REL_INT(full);
    REL_INT(format);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# copy_element
# cms$copy_element(ldb, input_elem, output_elem, remark, source_ldb,
# 		   msg_routine)
SV *
copy_element(ldb, in_elem, out_elem, ...)
    ldb_cntrlblk *ldb
    char *in_elem
    char *out_elem
  CODE:
    int sts;
    SV **SVildb;
    ldb_cntrlblk *ildb = NULL;
    DECL_STRING(inelemd);
    DECL_STRING(outelemd);
    DECL_STRING(remarkd);
    STRING(inelemd, in_elem);
    STRING(outelemd, out_elem);
    OPTIONS(3)
    OPT_STRING(remarkd, sRemark);
    SVildb = hv_fetch(opt, sSourceLdb, strlen(sSourceLdb), 0);
    if (SVildb)
    {
        if (!sv_isa(*SVildb, "VMS::CMS"))
	    croak("SOURCE_LDB argument is not of type VMS::CMS");
	ildb = (ldb_cntrlblk *) SvIV((SV*)SvRV(*SVildb));
    }
    OPTIONS_END
    clear_messages();
    sts = cms$copy_element(ldb, inelemd, outelemd, remarkd, ildb,
			      msg_routine);
    REL_STRING(inelemd);
    REL_STRING(outelemd);
    REL_STRING(remarkd);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# create_element
SV *
create_element(ldb,elem,...)
    ldb_cntrlblk *ldb
    char *elem
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(remarkd);
    DECL_STRING(historyd);
    DECL_STRING(notesd);
    DECL_STRING(infiled);
    DECL_INT(position);
    DECL_INT(keep);
    DECL_INT(reserve);
    DECL_INT(concurrent);
    DECL_INT(refcopy);
    DECL_INT(review);
    STRING(elementd, elem);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(historyd, sHistory);
    OPT_STRING(notesd, sNotes);
    OPT_STRING(infiled, sInputFile);
    OPT_INT(position, sPosition);
    OPT_INT(keep, sKeep);
    OPT_INT(reserve, sReserve);
    OPT_INT(concurrent, sConcurrent);
    OPT_INT(refcopy, sReferenceCopy);
    OPT_INT(review, sReview);
    }
    clear_messages();
    sts = cms$create_element(ldb,elementd,remarkd,historyd,notesd,
			     position,keep,reserve,concurrent,refcopy,
			     infiled,0,0,msg_routine,review);
    REL_STRING(elementd);
    REL_STRING(remarkd);
    REL_STRING(historyd);
    REL_STRING(notesd);
    REL_STRING(infiled);
    REL_INT(position);
    REL_INT(keep);
    REL_INT(reserve);
    REL_INT(concurrent);
    REL_INT(refcopy);
    REL_INT(review);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# delete_element
SV *
delete_element(ldb, elem, ...)
    ldb_cntrlblk *ldb
    char *elem
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(remarkd);
    STRING(elementd, elem);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPTIONS_END
    clear_messages();
    sts = cms$delete_element(ldb, elementd, remarkd, msg_routine);
    REL_STRING(elementd);
    REL_STRING(remarkd);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# differences
SV *
differences(ldb,opt)
    ldb_cntrlblk *ldb
    HV *opt
  CODE:
    int sts;
    struct callback_args output_rtn, *out_rtn = NULL;
    SV **sv;
    DECL_STRING(infile1d);
    DECL_STRING(ingen1d);
    DECL_STRING(infile2d);
    DECL_STRING(ingen2d);
    DECL_STRING(begsentd);
    DECL_STRING(endsentd);
    DECL_STRING(outfiled);
    DECL_INT(nooutput);
    DECL_INT(parallel);
    DECL_INT(full);
    DECL_INT(width);
    DECL_INT(pagebrk);
    DECL_INT(skip);
    DECL_INT(append);
    DECL_INT(format);
    DECL_INT(ignore);
    OPT_STRING(infile1d, sFilename1);
    OPT_STRING(ingen1d, sGeneration1);
    OPT_STRING(infile2d, sFilename2);
    OPT_STRING(ingen2d, sGeneration2);
    OPT_STRING(outfiled, sOutputFile);
    OPT_INT(nooutput, sNoOutput);
    OPT_INT(parallel, sParallel);
    OPT_INT(full, sFull);
    OPT_INT(width, sWidth);
    OPT_INT(pagebrk, sPageBreak);
    OPT_INT(append, sAppend);
    // format=(ascii,decimal,hexadecimal,octal,byte,longword,records,word,generation)
    OPT_INT(format, sFormat);
    // ignore=(form,lead,trail,space,case,history,notes)
    OPT_INT(ignore, sIgnore);
    OPT_INT(skip, sSkipLines);
    OPT_STRING(begsentd, sBeginSentinal);
    OPT_STRING(endsentd, sEndSentinal);
    sv = hv_fetch(opt, sOutputRoutine, strlen(sOutputRoutine), 0);
    if (sv != 0)
    {
	output_rtn.routine = *sv;
	sv = hv_fetch(opt, sUserArg, strlen(sUserArg), 0);
	if ( sv == 0 )
	    output_rtn.user_arg = 0;
	else
	    output_rtn.user_arg = *sv;
	out_rtn = &output_rtn;
    }
    clear_messages();
    sts = cms$differences(ldb, out_rtn, infile1d, 0, ingen1d, infile2d, 0,
			  ingen2d, outfiled, (out_rtn) ? output_callback : 0,
			  append, ignore, nooutput, parallel, full, format,
			  width, msg_routine, pagebrk, skip, begsentd, endsentd);
    REL_STRING(infile1d);
    REL_STRING(infile2d);
    REL_STRING(ingen1d);
    REL_STRING(ingen2d);
    REL_STRING(begsentd);
    REL_STRING(endsentd);
    REL_STRING(outfiled);
    REL_INT(nooutput);
    REL_INT(parallel);
    REL_INT(full);
    REL_INT(width);
    REL_INT(pagebrk);
    REL_INT(skip);
    REL_INT(append);
    REL_INT(format);
    REL_INT(ignore);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# fetch (doc)
SV *
fetch(ldb,elem,...)
    ldb_cntrlblk *ldb;
    char *elem;
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(remarkd);
    DECL_STRING(generationd);
    DECL_STRING(merge_gend);
    DECL_STRING(outfiled);
    DECL_STRING(historyd);
    DECL_STRING(notesd);
    DECL_INT(reserve);
    DECL_INT(nohistory);
    DECL_INT(nonotes);
    DECL_INT(concurrent);
    DECL_INT(nooutput);
    DECL_INT(position);
    STRING(elementd, elem);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(generationd, sGeneration);
    OPT_STRING(merge_gend, sMergeGeneration);
    OPT_STRING(outfiled, sOutputFile);
    OPT_STRING(historyd, sHistory);
    OPT_STRING(notesd, sNotes);
    OPT_INT(reserve, sReserve);
    OPT_INT(nohistory, sNoHistory);
    OPT_INT(nonotes, sNoNotes);
    OPT_INT(concurrent, sConcurrent);
    OPT_INT(nooutput, sNoOutput);
    OPT_INT(position, sPosition);
    OPTIONS_END
    clear_messages();
    sts = cms$fetch(ldb, elementd, remarkd, generationd, merge_gend,
                    reserve, nohistory, nonotes, concurrent, outfiled,
                    msg_routine, nooutput, historyd, notesd, position);
    REL_STRING(elementd);
    REL_STRING(remarkd);
    REL_STRING(generationd);
    REL_STRING(merge_gend);
    REL_STRING(outfiled);
    REL_STRING(historyd);
    REL_STRING(notesd);
    REL_INT(reserve);
    REL_INT(nohistory);
    REL_INT(nonotes);
    REL_INT(concurrent);
    REL_INT(nooutput);
    REL_INT(position);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# fetch_close NYI

########################################################################
# fetch_get NYI

########################################################################
# fetch_open NYI

########################################################################
# modify_element
SV *
modify_element(ldb, elem, ...)
    ldb_cntrlblk *ldb
    char *elem
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(remarkd);
    DECL_STRING(newnamed);
    DECL_STRING(newremarkd);
    DECL_STRING(historyd);
    DECL_STRING(notesd);
    DECL_INT(position);
    DECL_INT(concurrent);
    DECL_INT(refcopy);
    DECL_INT(review);
    STRING(elementd, elem);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(newnamed, sNewName);
    OPT_STRING(newremarkd, sNewRemark);
    OPT_STRING(historyd, sHistory);
    OPT_STRING(notesd, sNotes);
    OPT_INT(position, sPosition);
    OPT_INT(concurrent, sConcurrent);
    OPT_INT(refcopy, sReferenceCopy);
    OPT_INT(review, sReview);
    OPTIONS_END
    clear_messages();
    sts = cms$modify_element(ldb, elementd, remarkd, newnamed, newremarkd,
			     historyd, notesd, position, concurrent,
			     refcopy, msg_routine, review);
    REL_STRING(elementd);
    REL_STRING(remarkd);
    REL_STRING(newnamed);
    REL_STRING(newremarkd);
    REL_STRING(historyd);
    REL_STRING(notesd);
    REL_INT(position);
    REL_INT(concurrent);
    REL_INT(refcopy);
    REL_INT(review);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# replace
SV *
replace(ldb,elem,...)
    ldb_cntrlblk *ldb
    char *elem
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(remarkd);
    DECL_STRING(variantd);
    DECL_STRING(infiled);
    DECL_STRING(generationd);
    DECL_INT(reserve);
    DECL_INT(keep);
    DECL_INT(if_changed);
    DECL_INT(ident);
    STRING(elementd, elem);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(variantd, sVariant);
    OPT_STRING(infiled, sInputFile);
    OPT_STRING(generationd, sGeneration);
    OPT_INT(reserve, sReserve);
    OPT_INT(keep, sKeep);
    OPT_INT(if_changed, sIfChanged);
    OPT_INT(ident, sIdentification);
    OPTIONS_END
    clear_messages();
    sts = cms$replace(ldb, elementd, remarkd, variantd, reserve, keep,
		      infiled, 0, 0, msg_routine, if_changed, generationd,
                      ident);
    REL_STRING(elementd);
    REL_STRING(remarkd);
    REL_STRING(variantd);
    REL_STRING(infiled);
    REL_STRING(generationd);
    REL_INT(reserve);
    REL_INT(keep);
    REL_INT(if_changed);
    REL_INT(ident);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL


########################################################################
# show_element (doc)
#  callback: (firstcall, ldb, userarg, element_id, remark_id,
#             history_id, notes_id, position, concurrent,
#             reference_copy, group_list_id, review)
SV *
show_element(ldb,...)
    ldb_cntrlblk *ldb
  CODE:
    int sts;
    AV *av = newAV();
    DECL_STRING(elementd);
    DECL_INT(members);
    OPTIONS(1)
    OPT_STRING(elementd, sElement);
    OPT_INT(members, sMembers);
    OPTIONS_END
    clear_messages();
    sts = cms$show_element(ldb, show_element_callback, av,
                           elementd, members, msg_routine);
    REL_STRING(elementd);
    REL_INT(members);
    if (sts & 1)
    {
        RETVAL = newRV_noinc((SV *) av);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# unreserve
SV *
unreserve(ldb, elem, ...)
    ldb_cntrlblk *ldb
    char *elem
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(remarkd);
    DECL_STRING(generationd);
    DECL_STRING(deletefile);
    DECL_INT(dodelete);
    DECL_INT(ident);
    STRING(elementd, elem);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(generationd, sGeneration);
    OPT_STRING(deletefile, sDeleteFile);
    OPT_INT(dodelete, sDelete);
    OPT_INT(ident, sIdentification);
    OPTIONS_END
    clear_messages();
    sts = cms$unreserve(ldb, elementd, remarkd, 0, dodelete, msg_routine,
			   generationd, ident, deletefile);
    REL_STRING(elementd);
    REL_STRING(remarkd);
    REL_STRING(generationd);
    REL_STRING(deletefile);
    REL_INT(dodelete);
    REL_INT(ident);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
#Class Routines
########################################################################

########################################################################
# create_class
SV *
create_class(ldb, cls, ...)
    ldb_cntrlblk *ldb
    char *cls
  CODE:
    int sts;
    DECL_STRING(classd);
    DECL_STRING(remarkd);
    STRING(classd, cls);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPTIONS_END
    clear_messages();
    sts = cms$create_class(ldb, classd, remarkd, msg_routine);
    REL_STRING(classd);
    REL_STRING(remarkd);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# delete_class
SV *
delete_class(ldb, cls, ...)
    ldb_cntrlblk *ldb
    char *cls
  CODE:
    int sts;
    DECL_STRING(classd);
    DECL_STRING(remarkd);
    STRING(classd, cls);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPTIONS_END
    clear_messages();
    sts = cms$delete_class(ldb, classd, remarkd, msg_routine);
    REL_STRING(classd);
    REL_STRING(remarkd);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# insert_generation
SV *
insert_generation(ldb, elem, cls, ...)
    ldb_cntrlblk *ldb
    char *elem
    char *cls
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(classd);
    DECL_STRING(remarkd);
    DECL_STRING(generationd);
    DECL_INT(always);
    DECL_INT(supersede);
    DECL_INT(if_absent);
    STRING(elementd, elem);
    STRING(classd, cls);
    OPTIONS(3)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(generationd, sGeneration);
    OPT_INT(always, sAlways);
    OPT_INT(supersede, sSupersede);
    OPT_INT(if_absent, sIfAbsent);
    OPTIONS_END
    clear_messages();
    sts = cms$insert_generation(ldb, elementd, classd, remarkd,
				   generationd, always, supersede,
				   if_absent, msg_routine);
    REL_STRING(elementd);
    REL_STRING(classd);
    REL_STRING(remarkd);
    REL_STRING(generationd);
    REL_INT(always);
    REL_INT(supersede);
    REL_INT(if_absent);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# modify_class
SV *
modify_class(ldb, cls, ...)
    ldb_cntrlblk *ldb
    char *cls
  CODE:
    int sts;
    DECL_STRING(classd);
    DECL_STRING(remarkd);
    DECL_STRING(newnamed);
    DECL_STRING(newremarkd);
    DECL_INT(read_only);
    STRING(classd, cls);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(newnamed, sNewName);
    OPT_STRING(newremarkd, sNewRemark);
    OPT_INT(read_only, sReadOnly);
    OPTIONS_END
    clear_messages();
    sts = cms$modify_class(ldb, classd, remarkd, newnamed, newremarkd,
			      read_only, msg_routine);
    REL_STRING(classd);
    REL_STRING(remarkd);
    REL_STRING(newnamed);
    REL_STRING(newremarkd);
    REL_INT(read_only);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# remove_generation
SV *
remove_generation(ldb, elem, cls, ...)
    ldb_cntrlblk *ldb
    char *elem
    char *cls
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(classd);
    DECL_STRING(remarkd);
    DECL_STRING(generationd);
    DECL_INT(if_present);
    STRING(elementd, elem);
    STRING(classd, cls);
    OPTIONS(3)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(generationd, sGeneration);
    OPT_INT(if_present, sIfPresent);
    OPTIONS_END
    clear_messages();
    sts = cms$remove_generation(ldb, elementd, classd, remarkd,
				   if_present, msg_routine, generationd);
    REL_STRING(elementd);
    REL_STRING(classd);
    REL_STRING(remarkd);
    REL_STRING(generationd);
    REL_INT(if_present);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# show_class
#  callback: (firstcall, ldb, userarg, class_id, remark_id, readonly)
SV *
show_class(ldb, ...)
    ldb_cntrlblk *ldb
  CODE:
    int sts;
    DECL_STRING(classd);
    AV *av = newAV();
    OPTIONS(1)
    OPT_STRING(classd, sClass);
    OPTIONS_END
    clear_messages();
    sts = cms$show_class(ldb, show_class_callback, av, classd, msg_routine);
    REL_STRING(classd);
    if (sts & 1)
    {
        RETVAL = newRV_noinc((SV *) av);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
#Group Routines
########################################################################

########################################################################
# create_group
SV *
create_group(ldb, grp, ...)
    ldb_cntrlblk *ldb
    char *grp
  CODE:
    int sts;
    DECL_STRING(groupd);
    DECL_STRING(remarkd);
    STRING(groupd, grp);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPTIONS_END
    clear_messages();
    sts = cms$create_group(ldb, groupd, remarkd, msg_routine);
    REL_STRING(groupd);
    REL_STRING(remarkd);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# delete_group
SV *
delete_group(ldb, grp, ...)
    ldb_cntrlblk *ldb
    char *grp
  CODE:
    int sts;
    DECL_STRING(groupd);
    DECL_STRING(remarkd);
    STRING(groupd, grp);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPTIONS_END
    clear_messages();
    sts = cms$delete_group(ldb, groupd, remarkd, msg_routine);
    REL_STRING(groupd);
    REL_STRING(remarkd);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# insert_element
SV *
insert_element(ldb, elem, grp, ...)
    ldb_cntrlblk *ldb
    char *elem
    char *grp
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(groupd);
    DECL_STRING(remarkd);
    DECL_INT(if_absent);
    STRING(elementd, elem);
    STRING(groupd, grp);
    OPTIONS(3)
    OPT_STRING(remarkd, sRemark);
    OPT_INT(if_absent, sIfAbsent);
    OPTIONS_END
    clear_messages();
    sts = cms$insert_element(ldb, elementd, groupd, remarkd, if_absent,
                                msg_routine);
    REL_STRING(elementd);
    REL_STRING(groupd);
    REL_STRING(remarkd);
    REL_INT(if_absent);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# insert_group
SV *
insert_group(ldb, grp1, grp2, ...)
    ldb_cntrlblk *ldb
    char *grp1
    char *grp2
  CODE:
    int sts;
    DECL_STRING(grp1d);
    DECL_STRING(grp2d);
    DECL_STRING(remarkd);
    DECL_INT(if_absent);
    STRING(grp1d, grp1);
    STRING(grp2d, grp2);
    OPTIONS(3)
    OPT_STRING(remarkd, sRemark);
    OPT_INT(if_absent, sIfAbsent);
    OPTIONS_END
    clear_messages();
    sts = cms$insert_group(ldb, grp1d, grp2d, remarkd, if_absent,
                              msg_routine);
    REL_STRING(grp1d);
    REL_STRING(grp2d);
    REL_STRING(remarkd);
    REL_INT(if_absent);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# modify_group
SV *
modify_group(ldb, grp, ...)
    ldb_cntrlblk *ldb
    char *grp
  CODE:
    int sts;
    DECL_STRING(groupd);
    DECL_STRING(remarkd);
    DECL_STRING(newnamed);
    DECL_STRING(newremarkd);
    DECL_INT(read_only);
    STRING(groupd, grp);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(newnamed, sNewName);
    OPT_STRING(newremarkd, sNewRemark);
    OPT_INT(read_only, sReadOnly);
    OPTIONS_END
    clear_messages();
    sts = cms$modify_group(ldb, groupd, remarkd, newnamed, newremarkd,
			      read_only, msg_routine);
    REL_STRING(groupd);
    REL_STRING(remarkd);
    REL_STRING(newnamed);
    REL_STRING(newremarkd);
    REL_INT(read_only);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# remove_element
SV *
remove_element(ldb, elem, grp, ...)
    ldb_cntrlblk *ldb
    char *elem
    char *grp
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(groupd);
    DECL_STRING(remarkd);
    DECL_INT(if_present);
    STRING(elementd, elem);
    STRING(groupd, grp);
    OPTIONS(3)
    OPT_STRING(remarkd, sRemark);
    OPT_INT(if_present, sIfPresent);
    OPTIONS_END
    clear_messages();
    sts = cms$remove_element(ldb, elementd, groupd, remarkd, if_present,
				msg_routine);
    REL_STRING(elementd);
    REL_STRING(groupd);
    REL_STRING(remarkd);
    REL_INT(if_present);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# remove_group
SV *
remove_group(ldb, subg, grp, ...)
    ldb_cntrlblk *ldb
    char *subg
    char *grp
  CODE:
    int sts;
    DECL_STRING(subgd);
    DECL_STRING(groupd);
    DECL_STRING(remarkd);
    DECL_INT(if_present);
    STRING(subgd, subg);
    STRING(groupd, grp);
    OPTIONS(3)
    OPT_STRING(remarkd, sRemark);
    OPT_INT(if_present, sIfPresent);
    OPTIONS_END
    clear_messages();
    sts = cms$remove_group(ldb, subgd, groupd, remarkd, if_present,
			   msg_routine);
    REL_STRING(subgd);
    REL_STRING(groupd);
    REL_STRING(remarkd);
    REL_INT(if_present);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# show_group
SV *
show_group(ldb, ...)
    ldb_cntrlblk *ldb
  CODE:
    int sts;
    DECL_STRING(groupd);
    DECL_INT(contents);
    AV *av;
    OPTIONS(1)
    OPT_STRING(groupd, sGroup);
    OPT_INT(contents, sContents);
    OPTIONS_END
    av = newAV();
    clear_messages();
    sts = cms$show_group(ldb, show_group_callback, av, groupd,
		         msg_routine, contents);
    REL_STRING(groupd);
    REL_INT(contents);
    if (sts & 1)
    {
        RETVAL = newRV_noinc((SV *)av);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
#Generation Routines
########################################################################

########################################################################
# delete_generation
SV *
delete_generation(ldb, elem, ...)
    ldb_cntrlblk *ldb
    char *elem
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(remarkd);
    DECL_STRING(gend);
    DECL_STRING(afterd);
    DECL_STRING(befored);
    DECL_STRING(fromd);
    DECL_STRING(tod);
    DECL_STRING(archived);
    STRING(elementd, elem);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(gend, sGeneration);
    OPT_STRING(afterd, sAfterGeneration);
    OPT_STRING(befored, sBeforeGeneration);
    OPT_STRING(fromd, sFromGeneration);
    OPT_STRING(tod, sToGeneration);
    OPT_STRING(archived, sArchiveFile);
    OPTIONS_END
    clear_messages();
    sts = cms$delete_generation(ldb, elementd, remarkd, gend, afterd,
				befored, fromd, tod, archived, msg_routine);
    REL_STRING(elementd);
    REL_STRING(remarkd);
    REL_STRING(gend);
    REL_STRING(afterd);
    REL_STRING(befored);
    REL_STRING(fromd);
    REL_STRING(tod);
    REL_STRING(archived);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# modify_generation
SV *
modify_generation(ldb, elem, ...)
    ldb_cntrlblk *ldb
    char *elem
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(remarkd);
    DECL_STRING(generationd);
    DECL_STRING(newremarkd);
    STRING(elementd, elem);
    OPTIONS(2)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(generationd, sGeneration);
    OPT_STRING(newremarkd, sNewRemark);
    OPTIONS_END
    clear_messages();
    sts = cms$modify_generation(ldb, elementd, remarkd, generationd,
				newremarkd, msg_routine);
    REL_STRING(elementd);
    REL_STRING(remarkd);
    REL_STRING(generationd);
    REL_STRING(newremarkd);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# review_generation
SV *
review_generation(ldb, elem, action, ...)
    ldb_cntrlblk *ldb
    char *elem
    char *action
  CODE:
    int sts;
    int act;
    DECL_STRING(elementd);
    DECL_STRING(remarkd);
    DECL_STRING(generationd);
    STRING(elementd, elem);
    OPTIONS(3)
    OPT_STRING(remarkd, sRemark);
    OPT_STRING(generationd, sGeneration);
    OPTIONS_END
    if (strcmp(action, sAccept) == 0)
	act = CMS$K_ACCEPT;
    else if (strcmp(action, sCancel) == 0)
        act = CMS$K_CANCEL;
    else if (strcmp(action, sMark) == 0)
        act = CMS$K_MARK;
    else if (strcmp(action, sReject) == 0)
        act = CMS$K_REJECT;
    else if (strcmp(action, sReview) == 0)
        act = CMS$K_REVIEW;
    else
        croak("Invalid ACTION argument for review_generation");
    clear_messages();
    sts = cms$review_generation(ldb, elementd, act, remarkd, generationd,
				   msg_routine);
    REL_STRING(elementd);
    REL_STRING(remarkd);
    REL_STRING(generationd);
    if (sts & 1)
    {
        RETVAL = newSViv(sts);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# show_generation
#  callback: (new_element, ldb, userarg, element_id, generation_id,
#             user_id, trans_time, creation_time, revision_time,
#             revision_number, reservations, record_size,
#             review_status)
SV *
show_generation(ldb,...)
    ldb_cntrlblk *ldb
  CODE:
    int sts;
    DECL_STRING(elementd);
    DECL_STRING(generationd);
    DECL_STRING(fromgend);
    DECL_INT(ancestors);
    DECL_INT(descendants);
    DECL_INT(members);
    DECL_TIME(beforep);
    DECL_TIME(sincep);
    AV *av = newAV();
    OPTIONS(1)
    OPT_STRING(elementd, sElement);
    OPT_STRING(generationd, sGeneration);
    OPT_STRING(fromgend, sFromGeneration);
    OPT_INT(ancestors, sAncestors);
    OPT_INT(descendants, sDescendants);
    OPT_INT(members, sMembers);
    OPT_TIME(beforep, sBefore);
    OPT_TIME(sincep, sSince);
    OPTIONS_END
    clear_messages();
    sts = cms$show_generation(ldb, show_generation_callback, av, elementd,
                              generationd, fromgend, ancestors, descendants,
                              members, msg_routine, beforep, sincep);
    REL_STRING(elementd);
    REL_STRING(generationd);
    REL_STRING(fromgend);
    REL_INT(ancestors);
    REL_INT(descendants);
    REL_INT(members);
    REL_TIME(beforep);
    REL_TIME(sincep);
    if (sts & 1)
    {
        RETVAL = newRV_noinc((SV *) av);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
# show_reviews_pending
SV *
show_reviews_pending(ldb, ...)
    ldb_cntrlblk *ldb
  CODE:
    int sts;
    AV *av = newAV();
    DECL_STRING(elementd);
    DECL_STRING(generationd);
    DECL_STRING(userd);
    OPTIONS(1)
    OPT_STRING(elementd, sElement);
    OPT_STRING(generationd, sGeneration);
    OPT_STRING(userd, sUser);
    OPTIONS_END
    clear_messages();
    sts = cms$show_reviews_pending(ldb, show_reviews_pending_callback, av,
			           elementd, generationd, userd, msg_routine);
    REL_STRING(elementd);
    REL_STRING(generationd);
    REL_STRING(userd);
    if (sts & 1)
    {
        RETVAL = newRV_noinc((SV *) av);
	SETERRNO(0, sts);
    }
    else
    {
        RETVAL = &PL_sv_undef;
	SETERRNO(EVMSERR, sts);
    }
  OUTPUT:
    RETVAL

########################################################################
#Archive Routines
########################################################################

########################################################################
# retrieve_archive NYI

########################################################################
# show_archive NYI

########################################################################
#ACL Routines
########################################################################

########################################################################
# set_acl NYI

########################################################################
# show_acl NYI
