#!/usr/bin/perl

use strict;
use warnings;

my %consts = ( enum           => [qw( PRINTER_ENUM_LOCAL
                                      PRINTER_ENUM_NAME
                                      PRINTER_ENUM_SHARED
                                      PRINTER_ENUM_CONNECTIONS
                                      PRINTER_ENUM_NETWORK
                                      PRINTER_ENUM_REMOTE
                                      PRINTER_ENUM_CATEGORY_3D
                                      PRINTER_ENUM_CATEGORY_ALL
                                      PRINTER_ENUM_EXPAND
                                      PRINTER_ENUM_CONTAINER
                                      PRINTER_ENUM_ICON1
                                      PRINTER_ENUM_ICON2
                                      PRINTER_ENUM_ICON3
                                      PRINTER_ENUM_ICON4
                                      PRINTER_ENUM_ICON5
                                      PRINTER_ENUM_ICON6
                                      PRINTER_ENUM_ICON7
                                      PRINTER_ENUM_ICON8 )],

               attribute      => [qw( PRINTER_ATTRIBUTE_DIRECT
                                      PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST
                                      PRINTER_ATTRIBUTE_ENABLE_DEVQ
                                      PRINTER_ATTRIBUTE_HIDDEN
                                      PRINTER_ATTRIBUTE_KEEPPRINTEDJOBS
                                      PRINTER_ATTRIBUTE_LOCAL
                                      PRINTER_ATTRIBUTE_NETWORK
                                      PRINTER_ATTRIBUTE_PUBLISHED
                                      PRINTER_ATTRIBUTE_QUEUED
                                      PRINTER_ATTRIBUTE_RAW_ONLY
                                      PRINTER_ATTRIBUTE_SHARED
                                      PRINTER_ATTRIBUTE_FAX
                                      PRINTER_ATTRIBUTE_FRIENDLY_NAME
                                      PRINTER_ATTRIBUTE_MACHINE
                                      PRINTER_ATTRIBUTE_PUSHED_USER
                                      PRINTER_ATTRIBUTE_PUSHED_MACHINE
                                      PRINTER_ATTRIBUTE_TS )],

               status         => [qw( PRINTER_STATUS_BUSY
                                      PRINTER_STATUS_DOOR_OPEN
                                      PRINTER_STATUS_ERROR
                                      PRINTER_STATUS_INITIALIZING
                                      PRINTER_STATUS_IO_ACTIVE
                                      PRINTER_STATUS_MANUAL_FEED
                                      PRINTER_STATUS_NO_TONER
                                      PRINTER_STATUS_NOT_AVAILABLE
                                      PRINTER_STATUS_OFFLINE
                                      PRINTER_STATUS_OUT_OF_MEMORY
                                      PRINTER_STATUS_OUTPUT_BIN_FULL
                                      PRINTER_STATUS_PAGE_PUNT
                                      PRINTER_STATUS_PAPER_JAM
                                      PRINTER_STATUS_PAPER_OUT
                                      PRINTER_STATUS_PAPER_PROBLEM
                                      PRINTER_STATUS_PAUSED
                                      PRINTER_STATUS_PENDING_DELETION
                                      PRINTER_STATUS_POWER_SAVE
                                      PRINTER_STATUS_PRINTING
                                      PRINTER_STATUS_PROCESSING
                                      PRINTER_STATUS_SERVER_UNKNOWN
                                      PRINTER_STATUS_TONER_LOW
                                      PRINTER_STATUS_USER_INTERVENTION
                                      PRINTER_STATUS_WAITING
                                      PRINTER_STATUS_WARMING_UP )],

               dmfield        => [qw( DM_ORIENTATION
                                      DM_PAPERSIZE
                                      DM_PAPERLENGTH
                                      DM_PAPERWIDTH
                                      DM_SCALE
                                      DM_COPIES
                                      DM_DEFAULTSOURCE
                                      DM_PRINTQUALITY
                                      DM_POSITION
                                      DM_DISPLAYORIENTATION
                                      DM_DISPLAYFIXEDOUTPUT
                                      DM_COLOR
                                      DM_DUPLEX
                                      DM_YRESOLUTION
                                      DM_TTOPTION
                                      DM_COLLATE
                                      DM_FORMNAME
                                      DM_LOGPIXELS
                                      DM_BITSPERPEL
                                      DM_PELSWIDTH
                                      DM_PELSHEIGHT
                                      DM_DISPLAYFLAGS
                                      DM_NUP
                                      DM_DISPLAYFREQUENCY
                                      DM_ICMMETHOD
                                      DM_ICMINTENT
                                      DM_MEDIATYPE
                                      DM_DITHERTYPE
                                      DM_PANNINGWIDTH
                                      DM_PANNINGHEIGHT )],

               dmpaper        => [qw( DMPAPER_LETTER
                                      DMPAPER_LEGAL
                                      DMPAPER_9X11
                                      DMPAPER_10X11
                                      DMPAPER_10X14
                                      DMPAPER_15X11
                                      DMPAPER_11X17
                                      DMPAPER_12X11
                                      DMPAPER_A2
                                      DMPAPER_A3
                                      DMPAPER_A3_EXTRA
                                      DMPAPER_A3_EXTRA_TRAVERSE
                                      DMPAPER_A3_ROTATED
                                      DMPAPER_A3_TRAVERSE
                                      DMPAPER_A4
                                      DMPAPER_A4_EXTRA
                                      DMPAPER_A4_PLUS
                                      DMPAPER_A4_ROTATED
                                      DMPAPER_A4SMALL
                                      DMPAPER_A4_TRANSVERSE
                                      DMPAPER_A5
                                      DMPAPER_A5_EXTRA
                                      DMPAPER_A5_ROTATED
                                      DMPAPER_A5_TRANSVERSE
                                      DMPAPER_A6
                                      DMPAPER_A6_ROTATED
                                      DMPAPER_A_PLUS
                                      DMPAPER_B4
                                      DMPAPER_B4_JIS_ROTATED
                                      DMPAPER_B5
                                      DMPAPER_B5_EXTRA
                                      DMPAPER_B5_JIS_ROTATED
                                      DMPAPER_B6_JIS
                                      DMPAPER_B6_JIS_ROTATED
                                      DMPAPER_B_PLUS
                                      DMPAPER_CSHEET
                                      DMPAPER_DBL_JAPANESE_POSTCARD
                                      DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED
                                      DMPAPER_DSHEET
                                      DMPAPER_ENV_9
                                      DMPAPER_ENV_10
                                      DMPAPER_ENV_11
                                      DMPAPER_ENV_12
                                      DMPAPER_ENV_14
                                      DMPAPER_ENV_C5
                                      DMPAPER_ENV_C3
                                      DMPAPER_ENV_C4
                                      DMPAPER_ENV_C6
                                      DMPAPER_ENV_C65
                                      DMPAPER_ENV_B4
                                      DMPAPER_ENV_B5
                                      DMPAPER_ENV_B6
                                      DMPAPER_ENV_DL
                                      DMPAPER_ENV_INVITE
                                      DMPAPER_ENV_ITALY
                                      DMPAPER_ENV_MONARCH
                                      DMPAPER_ENV_PERSONAL
                                      DMPAPER_ESHEET
                                      DMPAPER_EXECUTIVE
                                      DMPAPER_FANFOLD_US
                                      DMPAPER_FANFOLD_STD_GERMAN
                                      DMPAPER_FANFOLD_LGL_GERMAN
                                      DMPAPER_FOLIO
                                      DMPAPER_ISO_B4
                                      DMPAPER_JAPANESE_POSTCARD
                                      DMPAPER_JAPANESE_POSTCARD_ROTATED
                                      DMPAPER_JENV_CHOU3
                                      DMPAPER_JENV_CHOU3_ROTATED
                                      DMPAPER_JENV_CHOU4
                                      DMPAPER_JENV_CHOU4_ROTATED
                                      DMPAPER_JENV_KAKU2
                                      DMPAPER_JENV_KAKU2_ROTATED
                                      DMPAPER_JENV_KAKU3
                                      DMPAPER_JENV_KAKU3_ROTATED
                                      DMPAPER_JENV_YOU4
                                      DMPAPER_JENV_YOU4_ROTATED
                                      DMPAPER_LAST
                                      DMPAPER_LEDGER
                                      DMPAPER_LEGAL_EXTRA
                                      DMPAPER_LETTER_EXTRA
                                      DMPAPER_LETTER_EXTRA_TRANSVERSE
                                      DMPAPER_LETTER_ROTATED
                                      DMPAPER_LETTERSMALL
                                      DMPAPER_LETTER_TRANSVERSE
                                      DMPAPER_NOTE
                                      DMPAPER_P16K
                                      DMPAPER_P16K_ROTATED
                                      DMPAPER_P32K
                                      DMPAPER_P32K_ROTATED
                                      DMPAPER_P32KBIG
                                      DMPAPER_P32KBIG_ROTATED
                                      DMPAPER_PENV_1
                                      DMPAPER_PENV_1_ROTATED
                                      DMPAPER_PENV_2
                                      DMPAPER_PENV_2_ROTATED
                                      DMPAPER_PENV_3
                                      DMPAPER_PENV_3_ROTATED
                                      DMPAPER_PENV_4
                                      DMPAPER_PENV_4_ROTATED
                                      DMPAPER_PENV_5
                                      DMPAPER_PENV_5_ROTATED
                                      DMPAPER_PENV_6
                                      DMPAPER_PENV_6_ROTATED
                                      DMPAPER_PENV_7
                                      DMPAPER_PENV_7_ROTATED
                                      DMPAPER_PENV_8
                                      DMPAPER_PENV_8_ROTATED
                                      DMPAPER_PENV_9
                                      DMPAPER_PENV_9_ROTATED
                                      DMPAPER_PENV_10
                                      DMPAPER_PENV_10_ROTATED
                                      DMPAPER_QUARTO
                                      DMPAPER_STATEMENT
                                      DMPAPER_TABLOID
                                      DMPAPER_TABLOID_EXTRA )],

               dmbin          => [qw( DMBIN_AUTO
                                      DMBIN_CASSETTE
                                      DMBIN_ENVELOPE
                                      DMBIN_ENVMANUAL
                                      DMBIN_FIRST
                                      DMBIN_FORMSOURCE
                                      DMBIN_LARGECAPACITY
                                      DMBIN_LARGEFMT
                                      DMBIN_LAST
                                      DMBIN_LOWER
                                      DMBIN_MANUAL
                                      DMBIN_MIDDLE
                                      DMBIN_ONLYONE
                                      DMBIN_TRACTOR
                                      DMBIN_SMALLFMT
                                      DMBIN_UPPER )],

               dmres          => [qw( DMRES_HIGH
                                      DMRES_MEDIUM
                                      DMRES_LOW
                                      DMRES_DRAFT )],

               dmdo           => [qw( DMDO_DEFAULT
                                      DMDO_90
                                      DMDO_180
                                      DMDO_270 )],

               dmdfo          => [qw( DMDFO_DEFAULT
                                      DMDFO_CENTER
                                      DMDFO_STRETCH )],

               dmcolor        => [qw( DMCOLOR_COLOR
                                      DMCOLOR_MONOCHROME )],

               dmdup          => [qw( DMDUP_SIMPLEX
                                      DMDUP_HORIZONTAL
                                      DMDUP_VERTICAL )],

               dmtt           => [qw( DMTT_BITMAP
                                      DMTT_DOWNLOAD
                                      DMTT_DOWNLOAD_OUTLINE
                                      DMTT_SUBDEV )],

               dmcollate      => [qw( DMCOLLATE_TRUE
                                      DMCOLLATE_FALSE )],

               dmdisplayflags => [qw( DM_GRAYSCALE
                                      DM_INTERLACED )],

               dmnup          => [qw( DMNUP_SYSTEM
                                      DMNUP_ONEUP )],

               dmicmethod     => [qw(  DMICMMETHOD_NONE
                                       DMICMMETHOD_SYSTEM
                                       DMICMMETHOD_DRIVER
                                       DMICMMETHOD_DEVICE )],

               dmicm          => [qw( DMICM_ABS_COLORIMETRIC
                                      DMICM_COLORIMETRIC
                                      DMICM_CONTRAST
                                      DMICM_SATURATE )],

               dmmedia        => [qw( DMMEDIA_STANDARD
                                      DMMEDIA_GLOSSY
                                      DMMEDIA_TRANSPARENCY )],

               dmdither        => [qw( DMDITHER_NONE
                                       DMDITHER_COARSE
                                       DMDITHER_FINE
                                       DMDITHER_LINEART
                                       DMDITHER_GRAYSCALE)],

               formflag        => [qw( FORM_USER
                                       FORM_BUILTIN
                                       FORM_PRINTER )],

               stringtype      => [qw( STRING_NONE
                                       STRING_MUIDLL
                                       STRING_LANGPAIR )],
             );


my %dups = map { $_ => 1 } qw(DMBIN_FORMSOURCE  DMBIN_ONLYONE DMBIN_UPPER DMPAPER_PENV_10_ROTATED);

sub find_prefix {
    my $prefix = shift;
    for (@_) {
        my $name = shift;
        until (index($_, $prefix) == 0) {
            $prefix =~ s/\_[^_]*$// or 
                die "Can not find common prefix for $_, old prefix: $prefix";
        }
    }
    $prefix
}


my $boot = '';

open my $fh_c, '>', 'const-c.inc' or die "Unable to open 'const-c.inc': $!";
open my $fh_tags, '>', 'tags.txt' or die "Unable to open 'tags.txt': $!";
binmode $fh_tags;

mkdir "lib/Win32/EnumPrinters";

for my $group (sort keys %consts) {
    my @consts = @{$consts{$group}};

    my $prefix = find_prefix @consts;

    print $fh_tags "$group => ${prefix}_*\n";

    print $fh_c <<END;
static SV*
${group}_to_sv(pTHX_ IV val) {
    switch(val) {
END
    my $offset = length($prefix) + 1;
    for my $const (@consts) {
        next if $dups{$const};
        my $name = lc substr $const, $offset;
        print $fh_c <<END;
#ifdef $const
    case $const:
        return newSVdual(aTHX_ $const, "$name");
#endif
END
        $boot .= <<END;
#ifdef $const
    newCONSTSUB(stash, "$const", newSVdual(aTHX_ $const, "$name"));
#endif
END
    }
    print $fh_c <<END;
    default:
        return newSViv(val);
    }
}

static IV
sv_to_${group}(pTHX_ SV *sv) {
    if (SvPOK(sv)) {
        STRLEN len;
        const char *pv = SvPVutf8(sv, len);
        if (len > 0) {
            switch(pv[0]) {
END
    my %l;
    for my $const (@consts) {
        my $l = lc substr $const, $offset, 1;
        push @{$l{$l} //= []}, $const;
    }
    for my $l (sort keys %l) {
        print $fh_c <<END;
            case '$l':
END
        for my $const (@{$l{$l}}) {
            my $name = lc substr $const, $offset;
            my $len = length($name);
            print $fh_c <<END;
#ifdef $const
                if (len == $len && strnEQ("$name", pv, len)) {
#ifdef DEBUG
                    Perl_warn(aTHX_ "%s conversion from %s to %d", "$group", pv, $const);
#endif
                    return $const;
                }
#endif

END
        }
        print $fh_c <<END;
                break;
END
    }
    print $fh_c <<END;
            }
        }
    }
    return SvIV(sv);
}

END


}


print $fh_c <<END;
static void
boot_constants(pTHX) {
    HV *stash = gv_stashpvs("Win32::EnumPrinters", 1);
$boot
}

END

close $fh_c;

open my $fh_pm, '>', 'lib/Win32/EnumPrinters/Constants.pm' or die "Unable to open 'Constants.pm': $!";
require Data::Dumper;
print $fh_pm <<END;
package Win32::EnumPrinters;
END
print $fh_pm Data::Dumper->Dump([\%consts], ['*EXPORT_TAGS']), "\n";
close $fh_pm;
