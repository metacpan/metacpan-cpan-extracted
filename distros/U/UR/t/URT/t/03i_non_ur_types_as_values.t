use strict;
use warnings;
use Test::More tests=> 55;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

use IO::Handle;
use IO::File;

# A non-UR Perl class
package OtherScalar;
our @ISA = ();

package SomeScalar;
our @ISA = qw(OtherScalar);

package main;

ok(UR::Object::Type->define(
        class_name => 'URT::Person',
        id_by => [
            person_id       => { is => 'Number' },
        ],
        has => [
            name            => { is => 'Text' },
            list_thing      => { is => 'ARRAY' },
            glob_thing      => { is => 'GLOB' },
            handle_thing    => { is => 'IO::Handle' },
            scalar_thing    => { is => 'SCALAR' },
            code_thing      => { is => 'CODE' },
            hash_thing      => { is => 'HASH' },
            ref_thing       => { is => 'REF' },
        ],
    ),
    "created class for Person");


my $listref = [1,2,3];

my $blessed_listref = [1,2,3];
bless $blessed_listref,'ListRef';

my $handle = IO::Handle->new();
my $filehandle = IO::File->new();
our $FOO;
my $globref = \*FOO;

my $scalarref = \"hello";
my $blessed_scalarref;
{
    my $string = "hello";
    $blessed_scalarref = \$string;
    bless $blessed_scalarref, 'ScalarRef';
}
my $other_scalarref; # In package SomeScalar, which ISA OtherScalar
{
    my $string = "hello";
    $other_scalarref = \$string;
    bless $other_scalarref, 'SomeScalar';
}

my $coderef = sub {1;};
my $blessed_coderef = sub {1;};
bless $blessed_coderef, 'CodeRef';

my $hashref = { one => 1, two => 2 };
my $blessed_hashref = { one => 1, two => 2 };
bless $blessed_hashref, 'HashRef';

my $refref = \$listref;
my $blessed_refref = \$listref;
bless $blessed_refref, 'RefRef';


my @tests = (
    [ name => 'Bob' ],
    [ list_thing => $listref ],
    [ glob_thing => $handle ],
    [ glob_thing => $filehandle ],
    [ glob_thing => $globref ],
    [ handle_thing => $handle ],
    [ handle_thing => $filehandle ],
    [ scalar_thing => $scalarref ],
    [ scalar_thing => $blessed_scalarref ],
    [ scalar_thing => $other_scalarref ],
    [ scalar_thing => 1 ],
    [ code_thing => $coderef ],
    [ code_thing => $blessed_coderef ],
    [ hash_thing => $hashref ],
    [ hash_thing => $blessed_hashref ],
    [ ref_thing  => $refref ],
    [ ref_thing  => $blessed_refref ],
    [ ref_thing  => $hashref ],
);

foreach my $test ( @tests ) {

    my($bx,%extra) = URT::Person->define_boolexpr( @$test );
    ok($bx, 'Created BoolExpr with params '.join(',',@$test));

    is($bx->value_for($test->[0]), $test->[1], 'Value for param is correct');
    is(scalar(keys %extra), 0, 'No params were rejected by define_boolexpr()');
}
