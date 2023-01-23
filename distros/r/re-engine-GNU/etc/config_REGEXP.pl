#!perl
use strict;
use diagnostics;
use Config::AutoConf 0.311;
use POSIX qw/EXIT_SUCCESS/;
use File::Spec;

my $DATA = do { local $/; <DATA>; };
$DATA //= '';
do_config_REGEXP();

exit(EXIT_SUCCESS);

sub do_config_REGEXP {
    my $config_wrapped = File::Spec->catfile('config_REGEXP_wrapped.h');
    my $log_wrapped = File::Spec->catfile('config_REGEXP_wrapped.log');
    my $config = File::Spec->catfile('config_REGEXP.h');

    my $ac = Config::AutoConf->new(logfile => $log_wrapped);

    print STDERR "...\n";
    print STDERR "... regexp structure configuration\n";
    print STDERR "... ------------------------------\n";
    $ac->check_cc;
    my @regexpMembers = qw/engine mother_re paren_names extflags minlen minlenret gofs substrs nparens intflags pprivate lastparen lastcloseparen logical_nparens swap offs subbeg saved_copy sublen suboffset subcoffset maxlen pre_prefix compflags prelen precomp wrapped wraplen seen_evals refcnt/;
    foreach (@regexpMembers) {
        $ac->check_member("regexp.$_", { prologue => "#include \"EXTERN.h\"
#include \"perl.h\"
#include \"XSUB.h\"

/* We are checking a structure member: it should never be a #define */
#undef $_

" });
    }
    print STDERR "...\n";
    print STDERR "... regexp_engine structure configuration\n";
    print STDERR "...\n";
    foreach (qw/comp exec intuit checkstr free rxfree numbered_buff_FETCH numbered_buff_STORE numbered_buff_LENGTH named_buff named_buff_iter qr_package dupe op_comp/) {
        $ac->check_member("regexp_engine.$_", { prologue => "#include \"EXTERN.h\"
#include \"perl.h\"
#include \"XSUB.h\"

/* We are checking a structure member: it should never be a #define */
#undef $_

" });
    }
    print STDERR "...\n";
    print STDERR "... regexp_engine perl functions\n";
    print STDERR "...\n";
    foreach (qw/Perl_reg_numbered_buff_fetch Perl_reg_numbered_buff_store Perl_reg_numbered_buff_length Perl_reg_named_buff Perl_reg_named_buff_iter/) {
        my $func = $_;
        $ac->check_decl($func, { action_on_true => sub {
            $ac->define_var('HAVE_' . uc($func), 1);
                                 },
                                 prologue => "#include \"EXTERN.h\"
#include \"perl.h\"
#include \"XSUB.h\"" });
    }
    print STDERR "...\n";
    print STDERR "... portability\n";
    print STDERR "...\n";
    foreach (qw/sv_pos_b2u_flags/) {
        my $func = $_;
        $ac->check_decl($func, { action_on_true => sub {
            $ac->define_var('HAVE_' . uc($func), 1);
                                 },
                                 prologue => "#include \"EXTERN.h\"
#include \"perl.h\"
#include \"XSUB.h\"" });
    }
    #
    # Generate structure wrappers
    #
    my $fh;
    open($fh, '>', $config) || die "Cannot open $config, $!";
    print $fh "#ifndef __CONFIG_REGEXP_H\n";
    print $fh "\n";
    print $fh "#define __CONFIG_REGEXP_H\n";
    print $fh "#include \"$config_wrapped\"\n";
    foreach (@regexpMembers) {
      my $can = "REGEXP_" . uc($_) . "_CAN";
      my $get = "REGEXP_" . uc($_) . "_GET";
      my $set = "REGEXP_" . uc($_) . "_SET";
      print $fh "\n";
      print $fh "#undef $can\n";
      print $fh "#undef $get\n";
      print $fh "#undef $set\n";
      print $fh "#ifdef HAVE_REGEXP_" . uc($_) . "\n";
      print $fh "#  define $can 1\n";
      print $fh "#  define $get(r) ((r))->$_\n";
      print $fh "#  define $set(r, x) ((r))->$_ = (x)\n";
      print $fh "#else\n";
      print $fh "#  define $can 0\n";
      print $fh "#  define $get(r)\n";
      print $fh "#  define $set(r, x)\n";
      print $fh "#endif\n";
    }
    #
    # Any eventual hardcoded stuff
    #
    print $fh "$DATA\n";
    print $fh "#endif /* __CONFIG_REGEXP_H */\n";
    close($fh) || warn "Cannot close $fh, $!";
    #
    # Generate wrapped config
    #
    $ac->write_config_h($config_wrapped);
}

__DATA__
/* Few compatibility issues */
#if PERL_VERSION > 10
#  define _RegSV(p) SvANY(p)
#else
#  define _RegSV(p) (p)
#endif

#ifndef PM_GETRE
#  define PM_GETRE(o) ((o)->op_pmregexp)
#endif

#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(x) ((void)x)
#endif

#ifndef PERL_UNUSED_ARG
#  define PERL_UNUSED_ARG(x) PERL_UNUSED_VAR(x)
#endif

#ifndef sv_setsv_cow
#  define sv_setsv_cow(a,b) Perl_sv_setsv_cow(aTHX_ a,b)
#endif

#ifndef RX_MATCH_TAINTED_off
#  ifdef RXf_TAINTED_SEEN
#    ifdef NO_TAINT_SUPPORT
#      define RX_MATCH_TAINTED_off(x)
#    else
#      define RX_MATCH_TAINTED_off(x) (RX_EXTFLAGS_SET(x, RX_EXTFLAGS_GET(x) & ~RXf_TAINTED_SEEN))
#    endif
#  else
#    define RX_MATCH_TAINTED_off(x)
#  endif
#endif

#ifndef RX_MATCH_UTF8_set
#  ifdef RXf_MATCH_UTF8
#    define RX_MATCH_UTF8_set(x, t) ((t) ? (RX_EXTFLAGS_SET(x, RX_EXTFLAGS_GET(x) |= RXf_MATCH_UTF8)) :(RX_EXTFLAGS_SET(x, RX_EXTFLAGS_GET(x) &= ~RXf_MATCH_UTF8)))
#  else
#    define RX_MATCH_UTF8_set(x, t)
#  endif
#endif

#ifdef PERL_STATIC_INLINE
#  define GNU_STATIC PERL_STATIC_INLINE
#else
# define GNU_STATIC static
#endif
