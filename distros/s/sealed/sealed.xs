#include "EXTERN.h"
#include "perl.h"
#include "perlapi.h"
#include "XSUB.h"

MODULE = sealed    PACKAGE = sealed

void _padname_add(PADLIST *padlist, IV idx)
    PROTOTYPE: $$
    CODE:
            I32 old_padix              = PL_padix;
            I32 old_comppad_name_fill  = PL_comppad_name_fill;
            I32 old_min_intro_pending  = PL_min_intro_pending;
            I32 old_max_intro_pending  = PL_max_intro_pending;
            int old_cv_has_eval        = PL_cv_has_eval;
            I32 old_pad_reset_pending  = PL_pad_reset_pending;
            SV **old_curpad            = PL_curpad;
            AV *old_comppad            = PL_comppad;
            OP* old_op                 = PL_op;
#ifdef HAVE_PADNAMELIST
            PADNAMELIST *old_comppad_name = PL_comppad_name;
#else
            AV *old_comppad_name = PL_comppad_name;
#endif
            PADNAME **names;
            PL_comppad_name      = PadlistNAMES(padlist);
            PL_comppad           = PadlistARRAY(padlist)[1];
            PL_curpad            = AvARRAY(PL_comppad);
            PL_comppad_name_fill = 0;
            PL_min_intro_pending = 0;
	    PL_cv_has_eval       = 0;
            PL_pad_reset_pending = 0;
            PL_padix             = PadnamelistMAX(PL_comppad_name);
            names                = PadnamelistARRAY((PADNAMELIST *)PadlistARRAY(padlist)[0]);

            names[idx]           = newPADNAMEpvn("&", 1);

            PL_padix             = old_padix;
            PL_comppad_name_fill = old_comppad_name_fill;
            PL_min_intro_pending = old_min_intro_pending;
            PL_max_intro_pending = old_max_intro_pending;
            PL_pad_reset_pending = old_pad_reset_pending;
            PL_curpad            = old_curpad;
            PL_comppad           = old_comppad;
            PL_comppad_name      = old_comppad_name;
	    PL_cv_has_eval       = old_cv_has_eval;
            PL_op                = old_op;
