#!/usr/bin/perl

# H.Merijn Brand, 23 Feb 1998 for PROCURA B.V., Heerhugowaard, The Netherlands
# Testing Text::Format for justification only.

# Running this script should yield the data after __END__
# This test does not use tabstops, hanging indents or extra indents

use strict;
use warnings;

# Should be 8.
use Test::More tests => 8;

use Text::Format;

# TEST
ok( 1, "Loaded" );

# make test uses .../bin/perl
# perl t/justify.t generates the <DATA> part

my $text =
      "gjyfg uergf au eg uyefg uayg uyger uge uvyger uvga erugf uevg ueyrgv "
    . "uaygerv uygaer uvygaervuy. aureyg aeurgv uayergv uegrv uyagr fuyg uyg"
    . " ruvyg aeruvg uevrg auygvre ayergv uyaergv uyagre vuyagervuygervuyg a"
    . "reuvg aervg eryvg revg yregv aregv ergv ugre vgerg aerug areuvg auerg"
    . " uyrgve uegr vuaguyf gaerfu ageruwf. augawfuygaweufyg rygg auydfg auy"
    . "efga uywef. auyefg uayergf uyagr yerg uger uweg g uyg uaygref uerg ae"
    . "gr uagr reg yeg ueg";

my $t = Text::Format->new(
    {
        columns     => 40,
        firstIndent => 0
    }
);

my $test = 2;

# TEST
ok( !chk_data( fmt_text( 2, $t, 1, 0, 1, $text ) ), "2,1,0,1" );

# TEST
ok( !chk_data( fmt_text( 3, $t, 1, 0, 0, $text ) ), "3,1,0,0" );

# TEST
ok( !chk_data( fmt_text( 4, $t, 0, 1, 1, $text ) ), "4,0,1,1" );

# TEST
ok( !chk_data( fmt_text( 5, $t, 0, 1, 0, $text ) ), "5,0,1,0" );

my @nat = (
    "Nederlandse",  "Duitse",
    "Tibetaanse",   "Kiribatische",
    "Kongoleesche", "Burger van Nieuw West-Vlaanderland",
    "Verweggistaneesche"
);

# TEST
ok( !chk_data( fmt_natio( 6, $t, 47, 0, 1, @nat ) ), "fmt_natio 6" );

# TEST
ok( !chk_data( fmt_natio( 7, $t, 25, 0, 1, @nat ) ), "fmt_natio 7" );

# TEST
ok( !chk_data( fmt_natio( 8, $t, 25, 1, 0, @nat ) ), "fmt_natio 8" );

### ###########################################################################

{
    my @DATA;

    sub get_data
    {
        # get what should be the result of the next test
        my @data = ();
        unless (@DATA)
        {
            while (<DATA>)
            {
                chomp;
                s/^\s*=\s// && s/\s=$//;
                push( @DATA, $_ );
            }
        }

        while ( $DATA[0] =~ m/^#/ )
        {
            shift(@DATA);
        }
        until ( $DATA[0] =~ m/^# Test/ )
        {
            push( @data, shift(@DATA) );
        }
        @data;
    }    # get_data
}

sub chk_data
{
    my @gen = @_;
    my @dat = get_data();

    scalar @gen == scalar @dat               || return (1);
    join( "\n", @gen ) eq join( "\n", @dat ) || return (1);
    return (0);
}

sub fmt_text
{
    my ( $tst, $t, $j, $f, $e, $text ) = @_;

    # $verbose &&
    # print STDERR "# Test $tst: ",
    #     $j ? "JUSTIFY"    : "justify",    ", ",
    #     $f ? "FILL"       : "fill",       ", ",
    #     $e ? "EXTRASPACE" : "extraspace", "\n";

    $t->config( { justify => $j, extraSpace => $e, rightFill => $f } );
    my @lines = split( "\n", $t->format($text) );

    # $verbose &&
    # print STDERR "= ", join (" =\n= ", @lines), " =\n";

    @lines;
}    # fmt_text

sub fmt_natio
{
    my ( $tst, $t, $c, $j, $f, @nat ) = @_;

    # $verbose &&
    # print STDERR "# Test $tst: ",
    # $j ? "JUSTIFY" : "justify",   ", ",
    # $f ? "FILL"    : "fill",  "\n";
    $t->config( { columns => $c, justify => $j, rightFill => $f } );
    my @lines = split( "\n", $t->format( join( ", ", @nat ) ) );

    # $verbose &&
    # print STDERR "= ", join (" =\n= ", @lines), " =\n";
    @lines;
}    # fmt_natio

__END__
# Test 1: Loading Text::Format [Version]
# Test 2: JUSTIFY, fill, EXTRASPACE
= gjyfg uergf au eg uyefg uayg  uyger  uge =
= uvyger uvga erugf  uevg  ueyrgv  uaygerv =
= uygaer   uvygaervuy.    aureyg    aeurgv =
= uayergv  uegrv  uyagr  fuyg  uyg   ruvyg =
= aeruvg  uevrg  auygvre  ayergv   uyaergv =
= uyagre  vuyagervuygervuyg  areuvg  aervg =
= eryvg revg yregv aregv ergv  ugre  vgerg =
= aerug areuvg auerg uyrgve  uegr  vuaguyf =
= gaerfu ageruwf.   augawfuygaweufyg  rygg =
= auydfg auyefga  uywef.   auyefg  uayergf =
= uyagr yerg uger uweg g uyg uaygref  uerg =
= aegr uagr reg yeg ueg =
# Test 3: JUSTIFY, fill, extraspace
= gjyfg uergf au eg uyefg uayg  uyger  uge =
= uvyger uvga erugf  uevg  ueyrgv  uaygerv =
= uygaer uvygaervuy. aureyg aeurgv uayergv =
= uegrv uyagr fuyg uyg ruvyg aeruvg  uevrg =
= auygvre    ayergv     uyaergv     uyagre =
= vuyagervuygervuyg  areuvg  aervg   eryvg =
= revg yregv aregv ergv ugre  vgerg  aerug =
= areuvg auerg uyrgve uegr vuaguyf  gaerfu =
= ageruwf.  augawfuygaweufyg  rygg  auydfg =
= auyefga uywef. auyefg uayergf uyagr yerg =
= uger uweg g uyg uaygref uerg  aegr  uagr =
= reg yeg ueg =
# Test 4: justify, FILL, EXTRASPACE
= gjyfg uergf au eg uyefg uayg uyger uge   =
= uvyger uvga erugf uevg ueyrgv uaygerv    =
= uygaer uvygaervuy.  aureyg aeurgv        =
= uayergv uegrv uyagr fuyg uyg ruvyg       =
= aeruvg uevrg auygvre ayergv uyaergv      =
= uyagre vuyagervuygervuyg areuvg aervg    =
= eryvg revg yregv aregv ergv ugre vgerg   =
= aerug areuvg auerg uyrgve uegr vuaguyf   =
= gaerfu ageruwf.  augawfuygaweufyg rygg   =
= auydfg auyefga uywef.  auyefg uayergf    =
= uyagr yerg uger uweg g uyg uaygref uerg  =
= aegr uagr reg yeg ueg                    =
# Test 5: justify, FILL, extraspace
= gjyfg uergf au eg uyefg uayg uyger uge   =
= uvyger uvga erugf uevg ueyrgv uaygerv    =
= uygaer uvygaervuy. aureyg aeurgv uayergv =
= uegrv uyagr fuyg uyg ruvyg aeruvg uevrg  =
= auygvre ayergv uyaergv uyagre            =
= vuyagervuygervuyg areuvg aervg eryvg     =
= revg yregv aregv ergv ugre vgerg aerug   =
= areuvg auerg uyrgve uegr vuaguyf gaerfu  =
= ageruwf. augawfuygaweufyg rygg auydfg    =
= auyefga uywef. auyefg uayergf uyagr yerg =
= uger uweg g uyg uaygref uerg aegr uagr   =
= reg yeg ueg                              =
# Test 6:
= Nederlandse, Duitse, Tibetaanse, Kiribatische,  =
= Kongoleesche, Burger van Nieuw                  =
= West-Vlaanderland, Verweggistaneesche           =
# Test 7:
= Nederlandse, Duitse,      =
= Tibetaanse, Kiribatische, =
= Kongoleesche, Burger van  =
= Nieuw West-Vlaanderland,  =
= Verweggistaneesche        =
# Test 8:
= Nederlandse,      Duitse, =
= Tibetaanse, Kiribatische, =
= Kongoleesche, Burger  van =
= Nieuw  West-Vlaanderland, =
= Verweggistaneesche =
# Test End
