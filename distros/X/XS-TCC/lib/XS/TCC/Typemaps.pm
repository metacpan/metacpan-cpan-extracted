package XS::TCC::Typemaps;
use 5.012;
use warnings;

use ExtUtils::Typemaps;
our $Typemap = ExtUtils::Typemaps->new(string => <<'END_TYPEMAP_SECTION');
TYPEMAP


INPUT
T_SVREF
    STMT_START {
        $var = tm_input_svref(aTHX_ $arg);
        if (!$var) {
            Perl_croak(aTHX_ \"%s: %s is not a reference\",
                       ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                       \"$var\");
        }
    } STMT_END

T_SVREF_REFCOUNT_FIXED
    STMT_START {
        $var = tm_input_svref(aTHX_ $arg);
        if (!$var) {
            Perl_croak(aTHX_ \"%s: %s is not a reference\",
                       ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                       \"$var\");
        }
    } STMT_END

T_AVREF
    STMT_START {
        $var = tm_input_avref(aTHX_ $arg);
        if (!$var) {
            Perl_croak(aTHX_ \"%s: %s is not an ARRAY reference\",
                       ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                       \"$var\");
        }
    } STMT_END

T_AVREF_REFCOUNT_FIXED
    STMT_START {
        $var = tm_input_avref(aTHX_ $arg);
        if (!$var) {
            Perl_croak(aTHX_ \"%s: %s is not an ARRAY reference\",
                       ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                       \"$var\");
        }
    } STMT_END

T_HVREF
    STMT_START {
        $var = tm_input_hvref(aTHX_ $arg);
        if (!$var) {
            Perl_croak(aTHX_ \"%s: %s is not a HASH reference\",
                       ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                       \"$var\");
        }
    } STMT_END

T_HVREF_REFCOUNT_FIXED
    STMT_START {
        $var = tm_input_hvref(aTHX_ $arg);
        if (!$var) {
            Perl_croak(aTHX_ \"%s: %s is not a HASH reference\",
                       ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                       \"$var\");
        }
    } STMT_END

T_CVREF
    STMT_START {
        $var = tm_input_cvref(aTHX_ $arg);
        if (!$var) {
            Perl_croak(aTHX_ "%s: %s is not a CODE reference\",
                       ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                       \"$var\");
        }
    } STMT_END

T_CVREF_REFCOUNT_FIXED
    STMT_START {
        $var = tm_input_cvref(aTHX_ $arg);
        if (!$var) {
            Perl_croak(aTHX_ "%s: %s is not a CODE reference\",
                       ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                       \"$var\");
        }
    } STMT_END

T_PTRREF
    STMT_START {
        $var = ($type)tm_input_ptrref(aTHX_ $arg);
        if (!$var)
            Perl_croak(aTHX_ \"%s: %s is not a reference\",
                       ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                       \"$var\");
    } STMT_END


O_OBJECT
    STMT_START {
        var = ($type)tm_input_o_object(aTHX_ $arg);
        if (var == NULL)
            XSRETURN_UNDEF;
    } STMT_END


OUTPUT
T_SVREF
    $arg = newRV_noinc((SV *)$var);

T_SVREF_REFCOUNT_FIXED
    $arg = newRV_noinc((SV *)$var);

T_AVREF
    $arg = newRV_noinc((SV *)$var);

T_AVREF_REFCOUNT_FIXED
    $arg = newRV_noinc((SV *)$var);

T_HVREF
    $arg = newRV_noinc((SV *)$var);

T_HVREF_REFCOUNT_FIXED
    $arg = newRV_noinc((SV *)$var);

T_SYSRET
    tm_output_sysret(aTHX_ (IV)$var, &arg);

O_OBJECT
    sv_setref_pv( $arg, CLASS, (void*)$var );

END_TYPEMAP_SECTION

1;
