#! perl

use strict;
use warnings FATAL => 'all';

use File::Spec::Functions qw/catfile/;

my %tables = (
	queue => {
		type => 'message_queue',
	},
	thread => {
		type => 'mthread',
#		destructor => 'mthread_destroy',
	},
);

my $filename = catfile(qw/src tables.h/);
open STDOUT, '>', $filename or die "Couldn't redirect open to $filename";

print <<'END';
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"

#ifdef __cplusplus
# define VOID2(T, P) static_cast<T>(P)
#else
# define VOID2(T, P) (P)
#endif

#define PTABLE_HASH(ptr) ((ptr >> 3) ^ (ptr >> (3 + 7)) ^ (ptr >> (3 + 17)))

STATIC UV generator() {
	static UV counter = 0;
	return counter++;
}

END

for my $name (keys %tables) {
	my %replacements = (
		name       => $name,
		destructor => '(void)',
		key_type   => 'UV',
		type       => 'void',
		max        => 15,
		%{$tables{$name}},
	);
	my $entry = <<'END';
typedef struct ${name}_ent {
	struct ${name}_ent* next;
	${key_type}           key;
	${type}*           val;
	int refcount;
} ${name}_ent;

typedef struct ${name}_table {
	${name}_ent** ary;
	size_t       max;
	size_t       items;
	bool         ownership;
} ${name}_table;

STATIC ${name}_table* S_${name}_db_new(pTHX_ bool ownership) {
	${name}_table* t = VOID2(${name}_table*, PerlMemShared_malloc(sizeof *t));
	t->max    = ${max};
	t->items  = 0;
	t->ary    = VOID2(${name}_ent **, PerlMemShared_calloc(t->max + 1, sizeof *t->ary));
	t->ownership = ownership;
	return t;
}
#define ${name}_db_new(ownership) S_${name}_db_new(aTHX_ ownership)

STATIC ${name}_ent* _${name}_db_find(const ${name}_table* const t, const ${key_type} key) {
	${name}_ent* ent;
	const UV hash = PTABLE_HASH(key);

	ent = t->ary[hash & t->max];
	for (; ent; ent = ent->next) {
		if (ent->key == key)
			return ent;
	}

	return NULL;
}

STATIC ${type}* ${name}_db_fetch(const ${name}_table* const t, const ${key_type} key) {
	const ${name}_ent *const ent = _${name}_db_find(t, key);
	return ent ? ent->val : NULL;
}

STATIC void _${name}_db_split(pTHX_ ${name}_table* const t) {
	${name}_ent **ary = t->ary;
	const size_t oldsize = t->max + 1;
	size_t newsize = oldsize * 2;
	size_t i;

	ary = VOID2(${name}_ent **, PerlMemShared_realloc(ary, newsize * sizeof(*ary)));
	Zero(&ary[oldsize], newsize - oldsize, sizeof(*ary));
	t->max = --newsize;
	t->ary = ary;

	for (i = 0; i < oldsize; i++, ary++) {
		${name}_ent **curentp, **entp, *ent;
		if (!*ary)
			continue;
		curentp = ary + oldsize;
		for (entp = ary, ent = *ary; ent; ent = *entp) {
			if ((newsize & PTABLE_HASH(ent->key)) != i) {
				*entp     = ent->next;
				ent->next = *curentp;
				*curentp  = ent;
				continue;
			} else
				entp = &ent->next;
		}
	}
}

STATIC void S_${name}_db_store(pTHX_ ${name}_table* const t, const ${key_type} key, ${type}* const val) {
	${name}_ent *ent = _${name}_db_find(t, key);

	if (ent) {
#if 0
		${type}* oldval = ent->val;
		${destructor}(oldval);
		ent->val = val;
#else
		Perl_croak(aTHX_ "Entry %"UVuf" already exists\n", key);
#endif
	} else if (val) {
		const size_t i = PTABLE_HASH(key) & t->max;
		ent = VOID2(${name}_ent *, PerlMemShared_malloc(sizeof *ent));
		ent->key  = key;
		ent->val  = val;
		ent->next = t->ary[i];
		t->ary[i] = ent;
		ent->refcount = 1;
		t->items++;
		if (ent->next && t->items > t->max)
			_${name}_db_split(aTHX_ t);
	}
}
#define ${name}_db_store(t, key, val) S_${name}_db_store(aTHX_ t, key, val)

STATIC void S_${name}_db_delete(pTHX_ ${name}_table * const t, const ${key_type} key) {
	${name}_ent *prev, *ent;
	const size_t i = PTABLE_HASH(key) & t->max;

	prev = NULL;
	ent  = t->ary[i];
	for (; ent; prev = ent, ent = ent->next) {
		if (ent->key == key)
			break;
	}

	if (ent) {
		if (--ent->refcount)
			return;
		if (prev)
			prev->next = ent->next;
		else
			t->ary[i]  = ent->next;
		if (t->ownership)
			${destructor}(ent->val);
		PerlMemShared_free(ent);
	}
}
#define ${name}_db_delete(t, key) S_${name}_db_delete(aTHX_ t, key)

STATIC void ${name}_db_incref(${name}_table* const t, const ${key_type} key) {
	${name}_ent* ent = _${name}_db_find(t, key);
	if (ent)
		ent->refcount++;
}

STATIC void ${name}_db_decref(${name}_table* const t, const ${key_type} key) {
	${name}_ent* ent = _${name}_db_find(t, key);
	if (ent)
		ent->refcount--;
}

STATIC void S_${name}_db_walk(pTHX_ ${name}_table* const t, void (*cb)(pTHX_ ${name}_ent* ent, void* userdata), void *userdata) {
	if (t && t->items) {
		register ${name}_ent ** const array = t->ary;
		size_t i = t->max;
		do {
			${name}_ent *entry;
			for (entry = array[i]; entry; entry = entry->next)
				if (entry->val)
					cb(aTHX_ entry, userdata);
		} while (i--);
	}
}
#define ${name}_db_walk(t, cb, data) S_${name}_db_walk(aTHX_ t, cb, data)

STATIC void S_${name}_db_clear(pTHX_ ${name}_table * const t) {
	if (t && t->items) {
		register ${name}_ent ** const array = t->ary;
		size_t i = t->max;

		do {
			${name}_ent *entry = array[i];
			while (entry) {
				${name}_ent * const oentry = entry;
				void *val = oentry->val;
				entry = entry->next;
				if(t->ownership)
					${destructor}(val);
				PerlMemShared_free(oentry);
			}
			array[i] = NULL;
		} while (i--);

		t->items = 0;
	}
}
#define ${name}_db_clear(t) S_${name}_db_clear(aTHX_ t)

STATIC void S_${name}_db_free(pTHX_ ${name}_table * const t) {
	if (!t)
		return;
	${name}_db_clear(t);
	PerlMemShared_free(t->ary);
	PerlMemShared_free(t);
}
#define ${name}_db_free(t) S_${name}_db_free(aTHX_ t)

END
	$entry =~ s/ \$ \{ (\w+) \} /$replacements{$1}/gxe;
	print $entry;
}
