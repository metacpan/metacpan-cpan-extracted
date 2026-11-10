/*
 * tkTextData.h --
 *
 *	The data container: what the widget keeps wherever it keeps a
 *	value for the language (Perl): on a leaf of a block (TkTextLine),
 *	on a node of a block (Node in tkTextBTree.c), on the toggle-on of
 *	a run of a tag (TkTextToggle), on a mark (TkTextMark), as the
 *	instance data of a block (TkTextITree), and in the undo records
 *	and the list of values to free (TkTextValue, TkTextUndoAtom).
 *
 *	The value that "block nodedata", "mark data", "tag data", "block
 *	data", the [name, value] elements of "block list" and "dump
 *	-values" show is only one part of a container, its "Lang part".
 *	The other parts, for later use, are slots of other types: say,
 *	switches that control how the data of two tag runs is merged.
 *	All code outside this file goes through the operations below;
 *	none touches the storage of a container directly.
 *
 *	Two representations, chosen at compile time:
 *
 *	TK_TEXT_DATA_ARRAYS 0 (the default), representation A: the
 *	    container IS the Lang value (an Arg, NULL for none).  The
 *	    other types of slots are never present.  The operations
 *	    compile to what the code did on bare Args before.
 *
 *	TK_TEXT_DATA_ARRAYS 1, representation B: the container is one
 *	    pointer (NULL for an empty container) to a single malloc-ed
 *	    block holding a size, a capacity, an array of slots (a union
 *	    of an Arg, a pointer and a long) and a parallel array of
 *	    unsigned char type codes.  A block is freed as soon as its
 *	    last slot goes: a non-NULL container is never empty.  The
 *	    pointer is wrapped in a struct of its own, of the same size,
 *	    so that the compiler refuses a container compared with NULL,
 *	    assigned NULL or used as an Arg: building B checks that
 *	    nothing outside this file touches the storage.  (Build it
 *	    with "ETEXT_DATA_ARRAYS=1 perl Makefile.PL", see README.md.)
 *
 *	Both keep a container the size of one pointer: no structure
 *	grows.
 *
 *	Type codes (0 is never stored).  A container holds AT MOST ONE
 *	SLOT OF EACH TYPE, for now:
 *
 *	TK_TEXT_DATA_LANG  the Lang value (slot.lang), owned by the
 *			   container: copying the container copies it
 *			   (LangCopyArg), freeing frees it (LangFreeArg).
 *			   Only through the ...Lang operations.
 *	TK_TEXT_DATA_INT   a long (slot.i), not owned.
 *	TK_TEXT_DATA_PTR   a pointer (slot.ptr), not owned: freeing the
 *			   container does not free what it points to.
 *
 *	Ownership.  A container owns its Lang value; whoever holds the
 *	container (a node, a mark, a record...) owns the container.
 *	"Owned" below means that the receiver must eventually give it to
 *	TkTextFreeValueLater (or to TkTextDataFree from where freeing is
 *	allowed); "borrowed" means valid until the container changes.
 *
 *	TkTextDataInit(d)	   d becomes empty (it owned nothing: no
 *				   free).  A macro on an lvalue.
 *	TkTextDataIsEmpty(d)	   whether d has no slot at all (a
 *				   container with only non-Lang slots is
 *				   NOT empty).
 *	TkTextDataGetLang(d)	   the Lang part, borrowed, or NULL.
 *	TkTextDataCopyLang(d)	   a copy (LangCopyArg) of the Lang part,
 *				   owned by the caller, or NULL.
 *	TkTextDataLangSV(d)	   (Perl) a new SV, owned by the caller: a
 *				   copy (newSVsv) of the Lang part, or
 *				   undef; for the lists the widget builds
 *				   ("block list", "dump -values").
 *	TkTextDataTakeLang(&d)	   removes the Lang part and returns it,
 *				   owned by the caller (NULL if none).
 *				   In B, d stays alive while other slots
 *				   remain and becomes empty (its block
 *				   freed) when the last slot goes.
 *	TkTextDataPutLang(&d, a)   a (owned, or NULL) becomes the Lang
 *				   part of d; returns the previous Lang
 *				   part, owned by the caller, for it to
 *				   free later.  PutLang(&d, NULL) is
 *				   TakeLang(&d).
 *	TkTextDataFromLang(a)	   a new container holding only a (owned,
 *				   it moves in); empty if a is NULL.  For
 *				   handing a Lang value that left its
 *				   container to TkTextFreeValueLater.
 *	TkTextDataMove(&dst, &src) dst (which must be empty: nothing is
 *				   freed) takes all of src; src becomes
 *				   empty.
 *	TkTextDataSwap(&a, &b)	   exchanges two containers.
 *	TkTextDataCopy(d)	   a deep copy, owned by the caller
 *				   (LangCopyArg on the Lang part; the
 *				   other slots are copied as they are).
 *	TkTextDataFree(d)	   frees d and all it owns at once
 *				   (LangFreeArg on the Lang part).  Freeing
 *				   a Lang value can run Perl code (a
 *				   DESTROY method): call it only where the
 *				   widget frees values, the deferred flush
 *				   (TkTextReleaseValues) and teardown (and
 *				   the one place that has always freed at
 *				   once, "block data" replacing a value:
 *				   BlockDataParse in tkText.c).  Everywhere
 *				   else, give the container to
 *				   TkTextFreeValueLater.
 *	TkTextDataMerge(&keep, &lose)
 *				   the merge policy, see below.
 *
 *	Generic slot access, for the non-Lang types (B only; in A no
 *	such slot is ever present):
 *
 *	TkTextDataGet(d, type, &slot)
 *				   1 and *slot filled in if d has a slot of
 *				   the type (for TK_TEXT_DATA_LANG the Arg
 *				   is borrowed), else 0.  A: always 0.
 *	TkTextDataSet(&d, type, slot)
 *				   sets (adds or replaces) the slot of a
 *				   non-Lang type; returns 1, or 0 (nothing
 *				   done) for TK_TEXT_DATA_LANG or an unknown
 *				   type.  A: always 0, nothing done.
 *	TkTextDataRemove(&d, type) removes the slot of a non-Lang type
 *				   (d may become empty); returns 1 if there
 *				   was one.  A: always 0.
 *
 *	The Perl interface reads and writes only the Lang part: setting
 *	undef (or, for "block data", an empty string) removes only the
 *	Lang part, reading gives the Lang part or undef.  "block list"
 *	exports, and its import sets, only the Lang part: in B, the
 *	non-Lang slots of data exported by "block list" are NOT carried
 *	over to text re-inserted from the list.  This is the limit of the
 *	current Perl interface.  It does not apply to undo and redo,
 *	which move whole containers (the records of the values a change
 *	dropped or moved, the instance data an undo atom of block insert
 *	keeps, the list of values to free).  The undo of a deletion, and
 *	the redo of an insertion, re-create the blocks of their range
 *	from a block list, but that list leaves every value out (node,
 *	run and mark data, and the instance data of blocks): the
 *	instance data of a block the deletion deleted or dissolved is a
 *	record of the undo atom too (TK_TEXT_VALUE_BLOCK, addressed by
 *	the block's head), given back whole to the re-created block.
 *	So in B every slot survives a deletion and its undo, and a
 *	discarded undo step frees the containers it holds at the end of
 *	the widget command (BUGS 23, fixed in 2.05).
 */

#ifndef _TKTEXTDATA
#define _TKTEXTDATA

#ifndef TK_TEXT_DATA_ARRAYS
#  define TK_TEXT_DATA_ARRAYS 0
#endif

#ifdef PERL_STATIC_INLINE
#  define TK_TEXT_DATA_INLINE PERL_STATIC_INLINE
#else
#  define TK_TEXT_DATA_INLINE static
#endif

#define TK_TEXT_DATA_LANG	1	/* The Lang value (owned). */
#define TK_TEXT_DATA_INT	2	/* A long (not owned). */
#define TK_TEXT_DATA_PTR	3	/* A pointer (not owned). */

typedef union TkTextDataSlot {
    Arg lang;				/* TK_TEXT_DATA_LANG */
    void *ptr;				/* TK_TEXT_DATA_PTR */
    long i;				/* TK_TEXT_DATA_INT */
} TkTextDataSlot;

#if !TK_TEXT_DATA_ARRAYS

/*
 * Representation A: the container is the Lang value.
 */

typedef Arg TkTextData;

#define TkTextDataInit(d)	((d) = NULL)
#define TkTextDataIsEmpty(d)	((d) == NULL)
#define TkTextDataGetLang(d)	((Arg) (d))
#define TkTextDataFromLang(a)	((TkTextData) (a))
#else /* TK_TEXT_DATA_ARRAYS */

/*
 * Representation B: one pointer to a block of parallel arrays.
 */

typedef struct TkTextDataBlock {
    int size;				/* Slots in use (at least 1). */
    int capacity;			/* Slots allocated. */
    TkTextDataSlot slots[1];		/* "capacity" slots, followed by
					 * "capacity" unsigned char type
					 * codes (TkTextDataTypes).  The
					 * slots come first, so that they
					 * are aligned as the union. */
} TkTextDataBlock;

typedef struct TkTextData {
    TkTextDataBlock *blockPtr;		/* NULL: empty. */
} TkTextData;

#define TkTextDataTypes(b) \
	((unsigned char *) ((b)->slots + (b)->capacity))
#define TK_TEXT_DATA_BLOCK_SIZE(capacity) \
	((unsigned) (Tk_Offset(TkTextDataBlock, slots) \
		+ (capacity) * (sizeof(TkTextDataSlot) + 1)))

/*
 * The number of blocks allocated and not yet freed, in the whole
 * process (for the tests, which check that each is freed once).
 */

extern long eText_TkTextDataLive;

#define TkTextDataInit(d)	((d).blockPtr = NULL)
#define TkTextDataIsEmpty(d)	((d).blockPtr == NULL)
#endif /* TK_TEXT_DATA_ARRAYS */

#define TK_TEXT_DATA_MERGE_NONE		0
#define TK_TEXT_DATA_MERGE_DROP		1
#define TK_TEXT_DATA_MERGE_MOVED	2

#endif /* _TKTEXTDATA */

/*
 * The operations, once the language's function table macros are
 * defined (tkText.h includes this file again with
 * TK_TEXT_DATA_FUNCTIONS defined, after tkVMacro.h).
 */

#if defined(TK_TEXT_DATA_FUNCTIONS) && !defined(_TKTEXTDATA_FUNCTIONS)
#define _TKTEXTDATA_FUNCTIONS

#if !TK_TEXT_DATA_ARRAYS

TK_TEXT_DATA_INLINE Arg
TkTextDataCopyLang(TkTextData d)
{
    return (d != NULL) ? LangCopyArg(d) : NULL;
}

TK_TEXT_DATA_INLINE Arg
TkTextDataTakeLang(TkTextData *dPtr)
{
    Arg a = *dPtr;

    *dPtr = NULL;
    return a;
}

TK_TEXT_DATA_INLINE Arg
TkTextDataPutLang(TkTextData *dPtr, Arg a)
{
    Arg old = *dPtr;

    *dPtr = a;
    return old;
}

TK_TEXT_DATA_INLINE TkTextData
TkTextDataCopy(TkTextData d)
{
    return (d != NULL) ? LangCopyArg(d) : NULL;
}

TK_TEXT_DATA_INLINE void
TkTextDataFree(TkTextData d)
{
    if (d != NULL) {
	LangFreeArg(d, TCL_DYNAMIC);
    }
}

TK_TEXT_DATA_INLINE int
TkTextDataGet(TkTextData d, int type, TkTextDataSlot *slotPtr)
{
    if ((type == TK_TEXT_DATA_LANG) && (d != NULL)) {
	slotPtr->lang = d;
	return 1;
    }
    return 0;
}

TK_TEXT_DATA_INLINE int
TkTextDataSet(TkTextData *dPtr, int type, TkTextDataSlot slot)
{
    return 0;				/* No non-Lang slots in A. */
}

TK_TEXT_DATA_INLINE int
TkTextDataRemove(TkTextData *dPtr, int type)
{
    return 0;
}

#else /* TK_TEXT_DATA_ARRAYS */

/*
 * The index of the slot of a type, or -1.
 */

TK_TEXT_DATA_INLINE int
TkTextDataFind(TkTextData d, int type)
{
    TkTextDataBlock *b = d.blockPtr;
    unsigned char *types;
    int k;

    if (b == NULL) {
	return -1;
    }
    types = TkTextDataTypes(b);
    for (k = 0; k < b->size; k++) {
	if (types[k] == type) {
	    return k;
	}
    }
    return -1;
}

TK_TEXT_DATA_INLINE TkTextDataBlock *
TkTextDataAllocBlock(int capacity)
{
    TkTextDataBlock *b = (TkTextDataBlock *)
	    ckalloc(TK_TEXT_DATA_BLOCK_SIZE(capacity));

    b->size = 0;
    b->capacity = capacity;
    eText_TkTextDataLive++;
    return b;
}

TK_TEXT_DATA_INLINE void
TkTextDataFreeBlock(TkTextDataBlock *b)
{
    eText_TkTextDataLive--;
    ckfree((char *) b);
}

/*
 * Add a slot of a type that is not there yet.
 */

TK_TEXT_DATA_INLINE void
TkTextDataAdd(TkTextData *dPtr, int type, TkTextDataSlot slot)
{
    TkTextDataBlock *b = dPtr->blockPtr;
    int k;

    if (b == NULL) {
	b = TkTextDataAllocBlock(1);
    } else if (b->size == b->capacity) {
	TkTextDataBlock *grown = TkTextDataAllocBlock(b->capacity + 1);

	for (k = 0; k < b->size; k++) {
	    grown->slots[k] = b->slots[k];
	    TkTextDataTypes(grown)[k] = TkTextDataTypes(b)[k];
	}
	grown->size = b->size;
	TkTextDataFreeBlock(b);
	b = grown;
    }
    k = b->size++;
    b->slots[k] = slot;
    TkTextDataTypes(b)[k] = (unsigned char) type;
    dPtr->blockPtr = b;
}

/*
 * Remove the slot at an index; the block goes with its last slot.
 */

TK_TEXT_DATA_INLINE void
TkTextDataRemoveAt(TkTextData *dPtr, int k)
{
    TkTextDataBlock *b = dPtr->blockPtr;
    int last = b->size - 1;

    b->slots[k] = b->slots[last];
    TkTextDataTypes(b)[k] = TkTextDataTypes(b)[last];
    b->size = last;
    if (last == 0) {
	TkTextDataFreeBlock(b);
	dPtr->blockPtr = NULL;
    }
}

TK_TEXT_DATA_INLINE Arg
TkTextDataGetLang(TkTextData d)
{
    int k = TkTextDataFind(d, TK_TEXT_DATA_LANG);

    return (k < 0) ? NULL : d.blockPtr->slots[k].lang;
}

TK_TEXT_DATA_INLINE Arg
TkTextDataCopyLang(TkTextData d)
{
    Arg a = TkTextDataGetLang(d);

    return (a != NULL) ? LangCopyArg(a) : NULL;
}

TK_TEXT_DATA_INLINE Arg
TkTextDataTakeLang(TkTextData *dPtr)
{
    int k = TkTextDataFind(*dPtr, TK_TEXT_DATA_LANG);
    Arg a;

    if (k < 0) {
	return NULL;
    }
    a = dPtr->blockPtr->slots[k].lang;
    TkTextDataRemoveAt(dPtr, k);
    return a;
}

TK_TEXT_DATA_INLINE Arg
TkTextDataPutLang(TkTextData *dPtr, Arg a)
{
    int k;
    Arg old;
    TkTextDataSlot slot;

    if (a == NULL) {
	return TkTextDataTakeLang(dPtr);
    }
    k = TkTextDataFind(*dPtr, TK_TEXT_DATA_LANG);
    if (k >= 0) {
	old = dPtr->blockPtr->slots[k].lang;
	dPtr->blockPtr->slots[k].lang = a;
	return old;
    }
    slot.lang = a;
    TkTextDataAdd(dPtr, TK_TEXT_DATA_LANG, slot);
    return NULL;
}

TK_TEXT_DATA_INLINE TkTextData
TkTextDataFromLang(Arg a)
{
    TkTextData d;

    TkTextDataInit(d);
    TkTextDataPutLang(&d, a);
    return d;
}

TK_TEXT_DATA_INLINE TkTextData
TkTextDataCopy(TkTextData d)
{
    TkTextData copy;
    TkTextDataBlock *b = d.blockPtr, *c;
    int k;

    TkTextDataInit(copy);
    if (b == NULL) {
	return copy;
    }
    c = TkTextDataAllocBlock(b->size);
    for (k = 0; k < b->size; k++) {
	TkTextDataTypes(c)[k] = TkTextDataTypes(b)[k];
	c->slots[k] = b->slots[k];
	if (TkTextDataTypes(b)[k] == TK_TEXT_DATA_LANG) {
	    c->slots[k].lang = LangCopyArg(b->slots[k].lang);
	}
    }
    c->size = b->size;
    copy.blockPtr = c;
    return copy;
}

TK_TEXT_DATA_INLINE void
TkTextDataFree(TkTextData d)
{
    TkTextDataBlock *b = d.blockPtr;
    int k;

    if (b == NULL) {
	return;
    }
    for (k = 0; k < b->size; k++) {
	if ((TkTextDataTypes(b)[k] == TK_TEXT_DATA_LANG)
		&& (b->slots[k].lang != NULL)) {
	    LangFreeArg(b->slots[k].lang, TCL_DYNAMIC);
	}
    }
    TkTextDataFreeBlock(b);
}

TK_TEXT_DATA_INLINE int
TkTextDataGet(TkTextData d, int type, TkTextDataSlot *slotPtr)
{
    int k = TkTextDataFind(d, type);

    if (k < 0) {
	return 0;
    }
    *slotPtr = d.blockPtr->slots[k];
    return 1;
}

TK_TEXT_DATA_INLINE int
TkTextDataSet(TkTextData *dPtr, int type, TkTextDataSlot slot)
{
    int k;

    if ((type != TK_TEXT_DATA_INT) && (type != TK_TEXT_DATA_PTR)) {
	return 0;			/* The Lang part: PutLang. */
    }
    k = TkTextDataFind(*dPtr, type);
    if (k >= 0) {
	dPtr->blockPtr->slots[k] = slot;
    } else {
	TkTextDataAdd(dPtr, type, slot);
    }
    return 1;
}

TK_TEXT_DATA_INLINE int
TkTextDataRemove(TkTextData *dPtr, int type)
{
    int k;

    if ((type != TK_TEXT_DATA_INT) && (type != TK_TEXT_DATA_PTR)) {
	return 0;			/* The Lang part: TakeLang. */
    }
    k = TkTextDataFind(*dPtr, type);
    if (k < 0) {
	return 0;
    }
    TkTextDataRemoveAt(dPtr, k);
    return 1;
}

#endif /* TK_TEXT_DATA_ARRAYS */

/*
 * The operations on whole containers, the same in both.
 */

#ifdef LangIsPerl
TK_TEXT_DATA_INLINE SV *
TkTextDataLangSV(TkTextData d)
{
    Arg a = TkTextDataGetLang(d);

    return (a != NULL) ? newSVsv((SV *) a) : newSV(0);
}
#endif

TK_TEXT_DATA_INLINE void
TkTextDataMove(TkTextData *dstPtr, TkTextData *srcPtr)
{
    *dstPtr = *srcPtr;
    TkTextDataInit(*srcPtr);
}

TK_TEXT_DATA_INLINE void
TkTextDataSwap(TkTextData *aPtr, TkTextData *bPtr)
{
    TkTextData t = *aPtr;

    *aPtr = *bPtr;
    *bPtr = t;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextDataMerge --
 *
 *	The merge policy: two nodes (or lines, or runs of a tag) become
 *	one, "keep" surviving.  Every merge of values goes through here
 *	(MergeValues, ReattachRuns and TkIBTreeTrim in tkTextBTree.c),
 *	so that a later policy, say one chosen by a
 *	switch in a container, needs only this function changed (and
 *	the undo records, see below).
 *
 *	The policy today is N5, applied to whole containers: the first
 *	container present wins.  If lose is empty nothing happens; if
 *	keep is not empty it stays and lose is to be dropped (the
 *	caller drops it: into the undo atom of the change, or onto the
 *	list of values to free); else lose moves into keep (which the
 *	caller records as a move, TK_TEXT_VALUE_MOVE or _RUNMOVE, so
 *	that the undo moves it back).
 *
 *	A policy that COMBINES two containers (keep gets some slots of
 *	lose, or values computed from both) cannot be undone from a
 *	_MOVE record, which only says "the container went from here to
 *	there", nor from a dropped container alone: the undo record has
 *	to keep BOTH originals.  It would fit TkTextValue as a new kind,
 *	say TK_TEXT_VALUE_COMBINE, with the address of keep (line,
 *	byteIndex, level) and of lose (srcLine...), "value" holding the
 *	original of lose and a second container field holding the
 *	original of keep: the undo frees the combined container (later,
 *	as always), gives keep its original back and re-creates lose's;
 *	the redo combines again.  The merge would then return a fourth
 *	result, TK_TEXT_DATA_MERGE_COMBINED, with the originals handed
 *	to the caller instead of freed.
 *
 * Results:
 *	TK_TEXT_DATA_MERGE_NONE: lose was empty, nothing changed;
 *	TK_TEXT_DATA_MERGE_DROP: keep is unchanged, lose too, and the
 *	    caller must drop lose (it is still full);
 *	TK_TEXT_DATA_MERGE_MOVED: lose moved into keep (lose is empty).
 *
 * Side effects:
 *	See above; nothing is freed.
 *
 *----------------------------------------------------------------------
 */

TK_TEXT_DATA_INLINE int
TkTextDataMerge(TkTextData *keepPtr, TkTextData *losePtr)
{
    if (TkTextDataIsEmpty(*losePtr)) {
	return TK_TEXT_DATA_MERGE_NONE;
    }
    if (!TkTextDataIsEmpty(*keepPtr)) {
	return TK_TEXT_DATA_MERGE_DROP;
    }
    TkTextDataMove(keepPtr, losePtr);
    return TK_TEXT_DATA_MERGE_MOVED;
}


#endif /* TK_TEXT_DATA_FUNCTIONS */
