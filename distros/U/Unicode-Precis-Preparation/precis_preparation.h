/*
 * Unicode-Precis-Preparation
 *
 * Copyright (C) 2015, 2025 by Hatuka*nezumi - IKEDA Soji
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the same terms as Perl. For more details, see the full text of
 * the licenses at <http://dev.perl.org/licenses/>.
 *
 * This program is distributed in the hope that it will be
 * useful, but without any warranty; without even the implied
 * warranty of merchantability or fitness for a particular purpose.
 */

#include "EXTERN.h"
#include "perl.h"

typedef enum {
    PRECIS_IDENTIFIER_CLASS = 1,
    PRECIS_FREE_FORM_CLASS
} precis_string_class_t;

typedef enum {
    PRECIS_UNASSIGNED = 0,
    PRECIS_PVALID,
    PRECIS_ID_DIS,
    PRECIS_CONTEXTJ,
    PRECIS_CONTEXTO,
    PRECIS_DISALLOWED
} precis_prop_t;

extern int precis_prepare(U8 *, const STRLEN, int, U16, U8 **, STRLEN *,
			  STRLEN *, U32 *);
