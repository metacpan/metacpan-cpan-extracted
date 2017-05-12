/* We can't use PERL_{REVISION,VERSION,SUBVERSION} here because they are not
 * available yet at the time this file is included by reg{comp,exec}.c. */

#define Perl_re_compile               reh_re_compile
#define Perl_regexec_flags            reh_regexec_flags
#define Perl_re_intuit_start          reh_re_intuit_start
#define Perl_re_intuit_string         reh_re_intuit_string
#define Perl_regfree_internal         reh_regfree_internal
#define Perl_reg_numbered_buff_fetch  reh_reg_numbered_buff_fetch
#define Perl_reg_numbered_buff_store  reh_reg_numbered_buff_store
#define Perl_reg_numbered_buff_length reh_reg_numbered_buff_length
#define Perl_reg_named_buff           reh_reg_named_buff
#define Perl_reg_named_buff_iter      reh_reg_named_buff_iter
#define Perl_reg_qr_package           reh_reg_qr_package
#define Perl_regdupe_internal         reh_regdupe_internal
#define Perl_re_op_compile            reh_re_op_compile

#define Perl_regnext                  reh_regnext
#define Perl_pregcomp                 reh_pregcomp
#define Perl_regdump                  reh_regdump
#define Perl_regprop                  reh_regprop
#define Perl_save_re_context          reh_save_re_context
#define Perl_reg_temp_copy            reh_reg_temp_copy
#define Perl__invlist_contents        reh__invlist_contents

#define Perl_reg_named_buff_fetch     reh_reg_named_buff_fetch
#define Perl_reg_named_buff_exists    reh_reg_named_buff_exists
#define Perl_reg_named_buff_firstkey  reh_reg_named_buff_firstkey
#define Perl_reg_named_buff_nextkey   reh_reg_named_buff_nextkey
#define Perl_reg_named_buff_scalar    reh_reg_named_buff_scalar
#define Perl_reg_named_buff_all       reh_reg_named_buff_all

/* Do not enable debugging stuff from perl.h */

#undef PERL_EXT_RE_BUILD
