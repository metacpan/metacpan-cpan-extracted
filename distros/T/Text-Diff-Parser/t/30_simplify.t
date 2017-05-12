#!/usr/bin/perl -w
# $Id: 30_simplify.t 124 2006-04-13 01:58:08Z fil $
use strict;

use Test::More tests => 3;

use Text::Diff::Parser;


my $parser = Text::Diff::Parser->new();

my @tests = (
    {   file => 't/easy.diff',
        result => [
            { filename1 => 'Makefile.PL', line1 => 63,
              filename2 => 'Makefile.PL', line2 => 63,
              size      => 2,
              type      => 'REMOVE'
            },
            { filename1 => 'Makefile.PL', line1 => 65,
              filename2 => 'Makefile.PL', line2 => 63,
              size      => 3,
              type      => 'ADD'
            },
            { filename1 => 'Makefile.PL', line1 => 66,
              filename2 => 'Makefile.PL', line2 => 67,
              size      => 1,
              type      => 'MODIFY'
            },
        ],
        desc   => "Unified diff.  Only one in file"
    },
    {   file => 't/double.diff',
        result => [
            { filename1 => 'Changes', line1 => 3,
              filename2 => 'Changes', line2 => 3,
              size      => 9,
              type      => 'ADD'
            },
            { filename1 => 'README', line1 => 24,
              filename2 => 'README', line2 => 24,
              size      => 6,
              type      => 'ADD'
            },
        ],
        desc   => "Unified diff.  2 in file"
    },
    {   file => 't/tripple.diff',
        desc => "Unified diff.  3 chunks",
        result => [
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 4,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 4,
              size      => 2,
              type      => 'ADD'
            },

            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 164,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 143,
              size      => 1,
              type      => 'MODIFY'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 170,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 149,
              size      => 2,
              type      => 'MODIFY'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 284,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 263,
              size      => 1,
              type      => 'ADD'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 288,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 268,
              size      => 1,
              type      => 'MODIFY'
            },
            { filename1 => 'lib/POE/Component/Generic.pm', line1 => 290,
              filename2 => 'lib/POE/Component/Generic.pm', line2 => 270,
              size      => 1,
              type      => 'MODIFY'
            },
        ],
    
    }


);

foreach my $test ( @tests ) {
    if( $test->{file} ) {
        $parser->parse_file( $test->{file} );
    }
    else {
        die "HONK";
    }
    $parser->simplify;
    my $res = [$parser->changes];
    compare_changes($res, $test->{result}, $test->{desc} );
}


sub compare_changes
{
    my( $got, $expected, $text ) = @_;

    my $q1 = 0;
    foreach my $ch ( @$got ) {
        my $v = $ch->type;
        unless( $expected->[$q1]{type} eq $v ) {
            my_fail( $text, $ch, $expected, $q1, 'type', $v );
            return;
        }
        foreach my $f ( qw(filename1 line1 size filename2 line2) ) {
            my $v = $ch->can($f)->($ch);
            unless( $expected->[$q1]{$f} eq $v ) {
                my_fail( $text, $ch, $expected, $q1, $f, $v );
                return;
            }
        }
        $q1++;
    }
    pass( $text );
}

sub my_fail
{
    my( $text, $ch, $expected, $q1, $f, $v ) = @_;

    fail( $text );
    $expected->[$q1]{$f} ||= '';
    $v ||= '';
    diag ( "     \$got->[$q1]->$f = $v" );
    diag ( "\$expected->[$q1]{$f} = $expected->[$q1]{$f}" );
    diag ( join "\n", $ch->text );
}
