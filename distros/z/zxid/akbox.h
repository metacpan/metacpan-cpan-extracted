/* akbox.h  -  Application Black (K) Box - an inmemory multithreaded logging system
 * Copyright (c) 2006,2012-2013 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
 * This is confidential unpublished proprietary source code of the author.
 * NO WARRANTY, not even implied warranties. Contains trade secrets.
 * Distribution prohibited unless authorized in writing. See file COPYING.
 * Special grant: akbox.h may be used with zxid open source project under
 * same licensing terms as zxid itself.
 * $Id$
 *
 * 15.4.2006, created over Easter holiday --Sampo
 * 16.8.2012, modified license grant to allow use with ZXID.org --Sampo
 * 15.4.2013, made sure ASBOX_FN returns int so %x format can be used without warnings --Sampo
 *
 * See also: ./log-pretty.pl -fn b5be:118   # decodes a FN hash
 */

#ifndef _akbox_h
#define _akbox_h

/* A macro to compute hash over function name so it can be supplied as an arg to AKBOX and err
 * functions. A better hash function should be developed. This one has collisions
 * This hash function may cause compiler preprocessor and/or constant folding to run slowly ;-)
 * but the slowness is only at compile time and not at runtime. */
#define AKBOX_FN(x) ((int)(( sizeof(x) + (x)[0]  \
		  + (sizeof(x)>2 ? 2*(x)[1] : 0)      + (sizeof(x)>3 ? 3*(x)[2] : 0) \
		  + (sizeof(x)>4 ? 5*(x)[3] : 0)      + (sizeof(x)>5 ? 7*(x)[4] : 0) \
		  + (sizeof(x)>6 ? 11*(x)[5] : 0)     + (sizeof(x)>7 ? 13*(x)[6] : 0) \
		  + (sizeof(x)>8 ? 17*(x)[7] : 0)     + (sizeof(x)>9 ? 19*(x)[8] : 0) \
                  \
		  + (sizeof(x)>10 ? 23*(x)[9] : 0)    + (sizeof(x)>11 ? 29*(x)[10] : 0) \
		  + (sizeof(x)>12 ? 31*(x)[11] : 0)   + (sizeof(x)>13 ? 37*(x)[12] : 0) \
		  + (sizeof(x)>14 ? 41*(x)[13] : 0)   + (sizeof(x)>15 ? 43*(x)[14] : 0) \
		  + (sizeof(x)>16 ? 47*(x)[15] : 0)   + (sizeof(x)>17 ? 53*(x)[16] : 0) \
		  + (sizeof(x)>18 ? 59*(x)[17] : 0)   + (sizeof(x)>19 ? 61*(x)[18] : 0) \
                  \
		  + (sizeof(x)>20 ? 67*(x)[19] : 0)   + (sizeof(x)>21 ? 71*(x)[20] : 0) \
		  + (sizeof(x)>22 ? 73*(x)[21] : 0)   + (sizeof(x)>23 ? 79*(x)[22] : 0) \
		  + (sizeof(x)>24 ? 83*(x)[23] : 0)   + (sizeof(x)>25 ? 89*(x)[24] : 0) \
		  + (sizeof(x)>26 ? 97*(x)[25] : 0)   + (sizeof(x)>27 ? 101*(x)[26] : 0) \
		  + (sizeof(x)>28 ? 103*(x)[27] : 0)  + (sizeof(x)>29 ? 107*(x)[28] : 0) \
                  \
		  + (sizeof(x)>30 ? 109*(x)[29] : 0)  + (sizeof(x)>31 ? 113*(x)[30] : 0) \
		  + (sizeof(x)>32 ? 127*(x)[31] : 0)  + (sizeof(x)>33 ? 131*(x)[32] : 0) \
		  + (sizeof(x)>34 ? 137*(x)[33] : 0)  + (sizeof(x)>35 ? 139*(x)[34] : 0) \
		  + (sizeof(x)>36 ? 149*(x)[35] : 0)  + (sizeof(x)>37 ? 151*(x)[36] : 0) \
		  + (sizeof(x)>38 ? 157*(x)[37] : 0)  + (sizeof(x)>39 ? 163*(x)[38] : 0) \
		  ) & 0x0000ffff))

int akbox_fn(const char* fn);

#define ak_init(x)
#define ak_add_thread(s,f)

#define AK_TS(r,a,...)

#endif /* _akbox_h */
