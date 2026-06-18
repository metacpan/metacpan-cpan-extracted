#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef struct timespec* Time__Spec;

#define timespec_sec(self) (self)->tv_sec
#define timespec_nsec(self) (self)->tv_nsec
#define timespec_to_float(self) (self)->tv_sec + ((self)->tv_nsec / (double)1000000000)
#define timespec__to_bool(self) TRUE

static void timespec_add(struct timespec* left, const struct timespec* right) {
	left->tv_sec += right->tv_sec;
	left->tv_nsec += right->tv_nsec;
	while (left->tv_nsec > 1000000000) {
		left->tv_nsec -= 1000000000;
		left->tv_sec++;
	}
}

static void timespec_sub(struct timespec* left, const struct timespec* right) {
	left->tv_sec -= right->tv_sec;
	left->tv_nsec -= right->tv_nsec;
	while (left->tv_nsec < 0) {
		left->tv_nsec += 1000000000;
		left->tv_sec--;
	}
}

MODULE = Time::Spec		PACKAGE = Time::Spec	PREFIX = timespec_

PROTOTYPES: DISABLE

FALLBACK: TRUE

TYPEMAP: <<END
Time::Spec T_OPAQUEOBJ
END

Time::Spec timespec_new(class, struct timespec value)
CODE:
	RETVAL = safecalloc(1, sizeof(struct timespec));
	*RETVAL = value;
OUTPUT:
	RETVAL

Time::Spec timespec_new_from_pair(class, UV secs, UV nsecs)
CODE:
	RETVAL = safecalloc(1, sizeof(struct timespec));
	RETVAL->tv_sec = secs;
	RETVAL->tv_nsec = nsecs;
OUTPUT:
	RETVAL

UV timespec_sec(Time::Spec self)

UV timespec_nsec(Time::Spec self)

NV timespec_to_float(Time::Spec self, ...)
OVERLOAD: 0+

bool timespec__to_bool(Time::Spec self, ...)
OVERLOAD: bool

void timespec_to_pair(Time::Spec self, OUTLIST UV sec, OUTLIST UV nsec)
CODE:
	sec = self->tv_sec;
	nsec = self->tv_nsec;

SV* timespec__add_to(Time::Spec self, struct timespec other, bool swap)
OVERLOAD: +=
CODE:
	if (!swap) {
		timespec_add(self, &other);
		RETVAL = ST(0);
	} else {
		timespec_add(&other, self);
		RETVAL = newSVnv(timespec_to_float(&other));
	}
OUTPUT: RETVAL

Time::Spec timespec__add(struct timespec self, struct timespec other, bool swap)
OVERLOAD: +
CODE:
	RETVAL = safecalloc(1, sizeof(struct timespec));
	*RETVAL = self;
	timespec_add(RETVAL, &other);
OUTPUT: RETVAL

SV* timespec__sub_from(Time::Spec self, struct timespec other, bool swap)
OVERLOAD: -=
CODE:
	if (!swap) {
		timespec_sub(self, &other);
		RETVAL = ST(0);
	} else {
		timespec_sub(&other, self);
		RETVAL = newSVnv(timespec_to_float(&other));
	}
OUTPUT: RETVAL

Time::Spec timespec__sub(struct timespec self, struct timespec other, bool swap)
OVERLOAD: -
CODE:
	RETVAL = safecalloc(1, sizeof(struct timespec));
	*RETVAL = self;
	timespec_sub(RETVAL, &other);
OUTPUT: RETVAL
