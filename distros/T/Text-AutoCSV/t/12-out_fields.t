#!/usr/bin/perl

# t/12-out_fields.t

#
# Written by Sébastien Millet
# September 2016
#

#
# Test script for Text::AutoCSV: write_fields (= out_fields)
#

use strict;
use warnings;

use Test::More tests => 18;

#use Test::More qw(no_plan);

my $OS_IS_PLAIN_WINDOWS = !!( $^O =~ /mswin/i );
my $ww = ( $OS_IS_PLAIN_WINDOWS ? 'ww' : '' );

# FIXME
# If the below is zero, ignore this FIX ME entry
# If the below is non zero, it'll use some hacks to ease development
my $DEVTIME = 0;

# FIXME
# Comment when not in dev
#use feature qw(say);
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;

BEGIN {
    use_ok('Text::AutoCSV');
}

use File::Temp qw(tmpnam);

if ($DEVTIME) {
    note("");
    note("***");
    note("***");
    note("***  !! WARNING !!");
    note("***");
    note("***  SET \$DEVTIME TO 0 BEFORE RELEASING THIS CODE TO PRODUCTION");
    note("***  RIGHT NOW, \$DEVTIME IS EQUAL TO $DEVTIME");
    note("***");
    note("***");
    note("");
}

can_ok( 'Text::AutoCSV', ('new') );

my $tmpf = &get_non_existent_temp_file_name();

note("");
note("[WI]thout write_fields tests");

my $csv = Text::AutoCSV->new( in_file => "t/${ww}wf.csv", out_file => $tmpf );
my $all = [ $csv->get_fields_names() ];
is_deeply(
    $all,
    [ 'MYF1', 'MYF2', '', '', 'ELEM', 'LAST' ],
    "WI01: auto: check field names"
);
$csv->write();
$all =
  [ Text::AutoCSV->new( in_file => $tmpf, fields_column_names => [ 0 .. 5 ] )
      ->get_hr_all() ];
is_deeply(
    $all,
    [
        {
            '0' => 'bla',
            '1' => 'bla2',
            '2' => 'yes',
            '3' => 'no',
            '4' => 'pi',
            '5' => ''
        },
        {
            '0' => 'BLA',
            '1' => 'BLA2',
            '2' => 'YES',
            '3' => 'NO',
            '4' => 'PI',
            '5' => ' '
        },
        {
            '0' => '',
            '1' => 'BLA2',
            '2' => 'YES or NO ?',
            '3' => '',
            '4' => 'e',
            '5' => undef
        }
    ],
    "WI02: auto: check after rewrite"
);

my $eval_failed = 0;
eval {
    local $SIG{__WARN__} = sub { };
    Text::AutoCSV->new(
        in_file      => "t/${ww}wf.csv",
        out_file     => $tmpf,
        infoh        => undef,
        write_fields => [ 'BADNAME', '', 'MYF1' ]
    )->write();
} or do {
    $eval_failed = 1;
    like( $@, qr/non existent field/i,
        "WI03: auto: check with bad field name" );
};
is( $eval_failed, 1, "WI04: check bad field name produced an error" );

$csv = Text::AutoCSV->new(
    in_file   => "t/${ww}wf.csv",
    out_file  => $tmpf,
    fields_hr => { myf1 => 'my f1', last => 'last', 'e' => 'elem' }
);
$all = [ $csv->get_fields_names() ];
is_deeply(
    $all,
    [ 'myf1', '', '', '', 'e', 'last' ],
    "WI05: fields_hr: check field names"
);
$csv->write();
$all =
  [ Text::AutoCSV->new( in_file => $tmpf, fields_column_names => [ 0 .. 5 ] )
      ->get_hr_all() ];
is_deeply(
    $all,
    [
        {
            '0' => 'bla',
            '1' => 'bla2',
            '2' => 'yes',
            '3' => 'no',
            '4' => 'pi',
            '5' => ''
        },
        {
            '0' => 'BLA',
            '1' => 'BLA2',
            '2' => 'YES',
            '3' => 'NO',
            '4' => 'PI',
            '5' => ' '
        },
        {
            '0' => '',
            '1' => 'BLA2',
            '2' => 'YES or NO ?',
            '3' => '',
            '4' => 'e',
            '5' => undef
        }
    ],
    "WI06: fields_hr: check after rewrite"
);

note("");
note("[WR]ite_fields tests");
note("  NOTE: out_fields is an alias of write_fields");

Text::AutoCSV->new(
    in_file    => "t/${ww}wf.csv",
    out_file   => $tmpf,
    out_fields => [ 'ELEM', '', 'MYF2' ]
)->write();
$all =
  [ Text::AutoCSV->new( in_file => $tmpf, fields_column_names => [ 0 .. 2 ] )
      ->get_hr_all() ];
is_deeply(
    $all,
    [
        { '0' => 'pi', '1' => '', '2' => 'bla2' },
        { '0' => 'PI', '1' => '', '2' => 'BLA2' },
        { '0' => 'e',  '1' => '', '2' => 'BLA2' }
    ],
    "WR01: auto: check rewritten result with out_fields"
);

Text::AutoCSV->new(
    in_file    => "t/${ww}wf.csv",
    out_file   => $tmpf,
    fields_hr  => { myf1 => 'my f1', last => 'last', 'e' => 'elem' },
    out_fields => ['e']
)->write();
$all =
  [ Text::AutoCSV->new( in_file => $tmpf, fields_column_names => [ 0 .. 1 ] )
      ->get_hr_all() ];
is_deeply(
    $all,
    [
        { '0' => 'pi', '1' => undef },
        { '0' => 'PI', '1' => undef },
        { '0' => 'e',  '1' => undef }
    ],
    "WR02: fields_hr: check rewritten result with out_fields"
);

Text::AutoCSV->new(
    in_file   => "t/${ww}wf.csv",
    out_file  => $tmpf,
    fields_hr => { myf1 => 'my f1', last => 'last', 'E' => 'elem' },
    write_fields => [ 'E', 'last', 'myf1' ]
)->write();
$all =
  [ Text::AutoCSV->new( in_file => $tmpf, fields_column_names => [ 0 .. 3 ] )
      ->get_hr_all() ];
is_deeply(
    $all,
    [
        { '0' => 'pi', '1' => '',  '2' => 'bla', '3' => undef },
        { '0' => 'PI', '1' => ' ', '2' => 'BLA', '3' => undef },
        { '0' => 'e',  '1' => '',  '2' => '',    '3' => undef }
    ],
    "WR03: fields_hr: check rewritten result with write_fields"
);

$eval_failed = 0;
my $wgs = 0;
eval {
    local $SIG{__WARN__} = sub { $wgs++; };
    Text::AutoCSV->new(
        in_file        => "t/${ww}wf.csv",
        out_file       => $tmpf,
        croak_if_error => 0,
        fields_hr      => { myf1 => 'my f1', last => 'last', 'E' => 'elem' },
        write_fields => [ 'BADFIELDNAME', 'last', 'BAD2' ]
    )->write();
} or $eval_failed = 1;
is( $eval_failed, 0,
    "WR04: bad field in out_fields while croak_if_error => 0" );
is( $wgs, 3, "WR05: exactly 2 warnings in WR04" );

Text::AutoCSV->new( in_file => "t/${ww}wf.csv", out_file => $tmpf )
  ->out_header( 'MYF1', '_f1' )->out_header( 'ELEM', '_Elem ' )->write();
$all = [
    Text::AutoCSV->new(
        in_file             => $tmpf,
        fields_column_names => [ 0 .. 5 ],
        has_headers         => 0
    )->get_hr_all()
];
is_deeply(
    $all,
    [
        {
            '0' => '_f1',
            '1' => 'my f2',
            '2' => '',
            '3' => '',
            '4' => '_Elem ',
            '5' => 'last'
        },
        {
            '0' => 'bla',
            '1' => 'bla2',
            '2' => 'yes',
            '3' => 'no',
            '4' => 'pi',
            '5' => ''
        },
        {
            '0' => 'BLA',
            '1' => 'BLA2',
            '2' => 'YES',
            '3' => 'NO',
            '4' => 'PI',
            '5' => ' '
        },
        {
            '0' => '',
            '1' => 'BLA2',
            '2' => 'YES or NO ?',
            '3' => '',
            '4' => 'e',
            '5' => undef
        }
    ],
    "WR06: check rewritten result with out_header"
);

Text::AutoCSV->new(
    in_file    => "t/${ww}wf.csv",
    out_file   => $tmpf,
    out_fields => [ 'ELEM', 'LAST', 'MYF1' ]
)->out_header( 'MYF1', '_f1' )->out_header( 'ELEM', '_Elem ' )->write();
$all = [
    Text::AutoCSV->new(
        in_file             => $tmpf,
        fields_column_names => [ 0 .. 3 ],
        has_headers         => 0
    )->get_hr_all()
];
is_deeply(
    $all,
    [
        { '0' => '_Elem ', '1' => 'last', '2' => '_f1', '3' => undef },
        { '0' => 'pi',     '1' => '',     '2' => 'bla', '3' => undef },
        { '0' => 'PI',     '1' => ' ',    '2' => 'BLA', '3' => undef },
        { '0' => 'e',      '1' => '',     '2' => '',    '3' => undef }
    ],
    "WR07: check rewritten result with out_header comined with out_fields"
);

$eval_failed = 0;
eval {
    Text::AutoCSV->new(
        in_file  => "t/${ww}wf.csv",
        out_file => $tmpf,
        quiet    => 1
      )->out_header( 'MYF1', '_f1' )->out_header( 'BADFNAME', '_Elem ' )
      ->write();
} or $eval_failed = 1;
is( $eval_failed, 1, "WR08: check bad field name in out_header croaks" );

$eval_failed = 0;
my $w = 0;
eval {
    local $SIG{__WARN__} = sub { $w++ };
    Text::AutoCSV->new(
        in_file        => "t/${ww}wf.csv",
        out_file       => $tmpf,
        croak_if_error => 0
      )->out_header( 'MYF1', '_f1' )->out_header( 'BADFNAME', '_Elem ' )
      ->write();
} or $eval_failed = 1;
is( $eval_failed, 0,
    "WR09: check bad field name in out_header (croak_if_error => 0)" );
is( $w, 2,
"WR10: check bad field name in out_header (croak_if_error => 0), count warnings"
);

unlink $tmpf if !$DEVTIME;

done_testing();

#
# Return the name of a temporary file name that is guaranteed NOT to exist.
#
# If ever it is not possible to return such a name (file exists and cannot be
# deleted), then stop execution.
sub get_non_existent_temp_file_name {
    my $tmpf = tmpnam();
    $tmpf = 'tmp0.csv' if $DEVTIME;

    unlink $tmpf if -f $tmpf;
    die
"File '$tmpf' already exists! Unable to delete it? Any way, tests aborted."
      if -f $tmpf;
    return $tmpf;
}

