#!/usr/bin/perl

# t/02-field.t

#
# Written by Sébastien Millet
# June 2016
#

#
# Test script for Text::AutoCSV: links
#

use strict;
use warnings;

use Test::More tests => 61;

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

{
    my $csv = Text::AutoCSV->new( in_file => "t/${ww}test.csv" );
    isa_ok( $csv, 'Text::AutoCSV' );
    $csv = Text::AutoCSV->new(
        in_file        => "t/${ww}bad-file-name.csv",
        croak_if_error => 0,
        quiet          => 1
    );
    is( $csv, undef, "object not created if input file does not exist" );
}

# * ***** *
# * write *
# * ***** *

{
    note("");
    note("[WR]ite() tests and walker_hr, walker_ar");

    my $tmpf = &get_non_existent_temp_file_name();
    my $csv  = Text::AutoCSV->new(
        in_file        => "t/${ww}l01a.csv",
        croak_if_error => 0,
        out_file       => $tmpf,
        quiet          => 1
    )->write();

    my $csvcopy = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    my $nbrows = $csvcopy->get_keys();
    is( $nbrows, 6, "WR01 - Copy CSV -> correct number of lines" );
    my $all = [ $csvcopy->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'C' => '',    'B' => '' },
            { 'A' => 'k1', 'B' => '',    'C' => 'v' },
            { 'A' => '',   'C' => '',    'B' => '' },
            { 'C' => 'v2', 'B' => 'foo', 'A' => 'k2' },
            { 'A' => 'k3', 'B' => 'bar', 'C' => 'v3' },
            { 'A' => '',   'C' => 'v4',  'B' => 'foobar' }
        ],
        "WR02 - Copy CSV -> check each line value"
    );
    unlink $tmpf;

    $csv->set_walker_hr( \&walker );
    my @l;

    sub walker {
        my ( $hr, $stats ) = @_;

    # We create it in reverse order to make sure there is no confusion with $all
        unshift @l, $hr;
    }
    $csv->read();
    is_deeply(
        \@l,
        [
            { 'A' => '',   'B' => 'foobar', 'C' => 'v4' },
            { 'A' => 'k3', 'B' => 'bar',    'C' => 'v3' },
            { 'A' => 'k2', 'B' => 'foo',    'C' => 'v2' },
            { 'A' => '',   'B' => '',       'C' => '' },
            { 'A' => 'k1', 'B' => '',       'C' => 'v' },
            { 'A' => '',   'B' => '',       'C' => '' }
        ],
        "WR03 - walker_hr() function and second read of CSV input"
    );

    my @columns = $csv->get_fields_names();
    $csv->set_walker_hr();
    $csv->set_walker_ar( \&walker_ar );
    @l = ();
    my @l2;

    sub walker_ar {
        my ( $ar, $stats ) = @_;

        my %tmp;
        for my $i ( 0 .. $#{$ar} ) {
            $tmp{ ":" . lc( $columns[$i] ) } = $ar->[$i];
        }

        unshift @l2, {%tmp};
    }
    $csv->read();
    is_deeply( \@l, [], "WR04 - check set_walker_hr(undef) removes callback" );

    is_deeply(
        \@l2,
        [
            { ':a' => '',   ':b' => 'foobar', ':c' => 'v4' },
            { ':a' => 'k3', ':b' => 'bar',    ':c' => 'v3' },
            { ':a' => 'k2', ':b' => 'foo',    ':c' => 'v2' },
            { ':a' => '',   ':b' => '',       ':c' => '' },
            { ':a' => 'k1', ':b' => '',       ':c' => 'v' },
            { ':a' => '',   ':b' => '',       ':c' => '' }
        ],
        "WR05 - walker_ar() function along with get_fields_names()"
    );

    @l2 = ();
    $csv->read();
    is_deeply(
        \@l2,
        [
            { ':a' => '',   ':b' => 'foobar', ':c' => 'v4' },
            { ':a' => 'k3', ':b' => 'bar',    ':c' => 'v3' },
            { ':a' => 'k2', ':b' => 'foo',    ':c' => 'v2' },
            { ':a' => '',   ':b' => '',       ':c' => '' },
            { ':a' => 'k1', ':b' => '',       ':c' => 'v' },
            { ':a' => '',   ':b' => '',       ':c' => '' }
        ],
        "WR06 - check set_walker_ar(undef) removes callback (1)"
    );

    $csv->set_walker_ar();
    @l2 = ();
    $csv->read();
    is_deeply( \@l2, [],
        "WR07 - check set_walker_ar(undef) removes callback (2)" );

    @l2  = ();
    $csv = Text::AutoCSV->new(
        in_file        => "t/${ww}l01a.csv",
        croak_if_error => 0,
        walker_ar      => \&walker_ar,
        quiet          => 1
    )->read();
    is_deeply(
        \@l2,
        [
            { ':a' => '',   ':b' => 'foobar', ':c' => 'v4' },
            { ':a' => 'k3', ':b' => 'bar',    ':c' => 'v3' },
            { ':a' => 'k2', ':b' => 'foo',    ':c' => 'v2' },
            { ':a' => '',   ':b' => '',       ':c' => '' },
            { ':a' => 'k1', ':b' => '',       ':c' => 'v' },
            { ':a' => '',   ':b' => '',       ':c' => '' }
        ],
        "WR08 - walker_ar set at object creation time"
    );
    $csv->read();
    is_deeply(
        \@l2,
        [
            { ':a' => '',   ':b' => 'foobar', ':c' => 'v4' },
            { ':a' => 'k3', ':b' => 'bar',    ':c' => 'v3' },
            { ':a' => 'k2', ':b' => 'foo',    ':c' => 'v2' },
            { ':a' => '',   ':b' => '',       ':c' => '' },
            { ':a' => 'k1', ':b' => '',       ':c' => 'v' },
            { ':a' => '',   ':b' => '',       ':c' => '' },
            { ':a' => '',   ':b' => 'foobar', ':c' => 'v4' },
            { ':a' => 'k3', ':b' => 'bar',    ':c' => 'v3' },
            { ':a' => 'k2', ':b' => 'foo',    ':c' => 'v2' },
            { ':a' => '',   ':b' => '',       ':c' => '' },
            { ':a' => 'k1', ':b' => '',       ':c' => 'v' },
            { ':a' => '',   ':b' => '',       ':c' => '' }
        ],
        "WR09 - walker_ar set at object creation time, second read"
    );

    $csv = Text::AutoCSV->new(
        in_file  => "t/${ww}l01a.csv",
        out_file => $tmpf,
        one_pass => 1
    )->_read_all_in_mem();
    $csv->write();
    $csv->write()->write();
    is( $csv->get_pass_count(), 1,
"WR10 - check multiple write are ok if all in-memory while one_pass => 1"
    );

    $csv = Text::AutoCSV->new(
        in_file  => "t/${ww}l01a.csv",
        out_file => $tmpf,
        one_pass => 1
    )->read_all_in_mem();
    $csv->write();
    $csv->write()->write();
    is( $csv->get_pass_count(), 1,
"WR11 - check read_all_in_mem() is available not only _read_all_in_mem()"
    );

    $csv = Text::AutoCSV->new(
        in_file  => "t/${ww}l01a.csv",
        out_file => $tmpf,
        one_pass => 1
    )->read();
    my $e = 0;
    eval { $csv->write(); 1; } or $e = 1;
    is( $e, 1, "WR12 - check an error is trigeered if not all in-memory" );
    is( $csv->get_pass_count(), 1, "WR12 - check pass count after WR11" );

    unlink $tmpf;
}

# * ************ *
# * [CO]py_field *
# * ************ *

{
    note("");
    note("[CO]py_field() tests");

    my $tmpf = &get_non_existent_temp_file_name();
    my $csv  = Text::AutoCSV->new(
        in_file        => "t/${ww}l01a.csv",
        croak_if_error => 0,
        out_file       => $tmpf,
        quiet          => 1
    );

    my $obj = $csv->field_add_copy( 'copy', 'BB' )->write();
    my $all = [ $obj->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',       'C' => '' },
            { 'A' => 'k1', 'B' => '',       'C' => 'v' },
            { 'A' => '',   'B' => '',       'C' => '' },
            { 'A' => 'k2', 'B' => 'foo',    'C' => 'v2' },
            { 'A' => 'k3', 'B' => 'bar',    'C' => 'v3' },
            { 'A' => '',   'B' => 'foobar', 'C' => 'v4' }
        ],
        "CO01 - field_add_copy with wrong source field name"
    );

    $obj = $csv->field_add_copy( 'A', 'B' )->write();
    $all = [ $obj->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',       'C' => '' },
            { 'A' => 'k1', 'B' => '',       'C' => 'v' },
            { 'A' => '',   'B' => '',       'C' => '' },
            { 'A' => 'k2', 'B' => 'foo',    'C' => 'v2' },
            { 'A' => 'k3', 'B' => 'bar',    'C' => 'v3' },
            { 'A' => '',   'B' => 'foobar', 'C' => 'v4' }
        ],
        "CO02 - field_add_copy with duplicate target field name"
    );

    $obj = $csv->field_add_copy( 'BCOPY', 'B' )->write();
    $all = [ $obj->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',       'BCOPY' => '',       'C' => '' },
            { 'A' => 'k1', 'B' => '',       'BCOPY' => '',       'C' => 'v' },
            { 'A' => '',   'B' => '',       'BCOPY' => '',       'C' => '' },
            { 'A' => 'k2', 'B' => 'foo',    'BCOPY' => 'foo',    'C' => 'v2' },
            { 'A' => 'k3', 'B' => 'bar',    'BCOPY' => 'bar',    'C' => 'v3' },
            { 'A' => '',   'B' => 'foobar', 'BCOPY' => 'foobar', 'C' => 'v4' }
        ],
        "CO03 - field_add_copy without transform function"
    );

    $obj = $csv->field_add_copy( 'BCOPYZ', 'B', \&myfunc )->write();
    $all = [ $obj->get_hr_all() ];
    is_deeply(
        $all,
        [
            {
                'A'      => '',
                'B'      => '',
                'BCOPY'  => '',
                'BCOPYZ' => '<>',
                'C'      => ''
            },
            {
                'A'      => 'k1',
                'B'      => '',
                'BCOPY'  => '',
                'BCOPYZ' => '<>',
                'C'      => 'v'
            },
            {
                'A'      => '',
                'B'      => '',
                'BCOPY'  => '',
                'BCOPYZ' => '<>',
                'C'      => ''
            },
            {
                'A'      => 'k2',
                'B'      => 'foo',
                'BCOPY'  => 'foo',
                'BCOPYZ' => '<FOO>',
                'C'      => 'v2'
            },
            {
                'A'      => 'k3',
                'B'      => 'bar',
                'BCOPY'  => 'bar',
                'BCOPYZ' => '<BAR>',
                'C'      => 'v3'
            },
            {
                'A'      => '',
                'B'      => 'foobar',
                'BCOPY'  => 'foobar',
                'BCOPYZ' => '<FOOBAR>',
                'C'      => 'v4'
            }
        ],
        "CO04 - field_add_copy with transform function"
    );
    sub myfunc { s/^.*$/\U<$&>/; $_; }

    my $csvcopy = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    my $allcopy = [ $csvcopy->get_hr_all() ];
    is_deeply(
        $allcopy,
        [
            {
                'A'      => '',
                'B'      => '',
                'BCOPY'  => '',
                'BCOPYZ' => '<>',
                'C'      => ''
            },
            {
                'A'      => 'k1',
                'B'      => '',
                'BCOPY'  => '',
                'BCOPYZ' => '<>',
                'C'      => 'v'
            },
            {
                'A'      => '',
                'B'      => '',
                'BCOPY'  => '',
                'BCOPYZ' => '<>',
                'C'      => ''
            },
            {
                'A'      => 'k2',
                'B'      => 'foo',
                'BCOPY'  => 'foo',
                'BCOPYZ' => '<FOO>',
                'C'      => 'v2'
            },
            {
                'A'      => 'k3',
                'B'      => 'bar',
                'BCOPY'  => 'bar',
                'BCOPYZ' => '<BAR>',
                'C'      => 'v3'
            },
            {
                'A'      => '',
                'B'      => 'foobar',
                'BCOPY'  => 'foobar',
                'BCOPYZ' => '<FOOBAR>',
                'C'      => 'v4'
            }
        ],
"CO05 - field_add_copy with transform function, read previous object output file"
    );
    unlink $tmpf;
}

# * ************** *
# * [CR]eate_field *
# * ************** *

{
    note("");
    note("[CR]eate_field() tests");

    my $tmpf = &get_non_existent_temp_file_name();
    my $csv  = Text::AutoCSV->new(
        in_file        => "t/${ww}l01a.csv",
        croak_if_error => 0,
        out_file       => $tmpf
    )->field_add_computed( 'BCOPY2', \&mycrfunc )->write();

    sub mycrfunc {
        my ( $field, $hr, $stats ) = @_;
        $stats->{'field value calculation'}++;
        return $hr->{'A'} . '--<' . uc( $hr->{'C'} ) . '>';
    }

    my $csvcopy = Text::AutoCSV->new( in_file => $tmpf, croak_if_error => 0 );
    my $all = [ $csvcopy->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',    'BCOPY2' => '--<>',     'C' => '' },
            { 'A' => 'k1', 'B' => '',    'BCOPY2' => 'k1--<V>',  'C' => 'v' },
            { 'A' => '',   'B' => '',    'BCOPY2' => '--<>',     'C' => '' },
            { 'A' => 'k2', 'B' => 'foo', 'BCOPY2' => 'k2--<V2>', 'C' => 'v2' },
            { 'A' => 'k3', 'B' => 'bar', 'BCOPY2' => 'k3--<V3>', 'C' => 'v3' },
            { 'A' => '', 'B' => 'foobar', 'BCOPY2' => '--<V4>', 'C' => 'v4' }
        ],
        "CR01 - field_add_computed"
    );
    unlink $tmpf;

    $csv = Text::AutoCSV->new(
        in_file                 => "t/${ww}l01a.csv",
        croak_if_error          => 0,
        quiet                   => 1,
        search_ignore_ambiguous => 0
    );
    my @cols0 = $csv->get_fields_names();
    is_deeply( \@cols0, [ 'A', 'B', 'C' ], "CR02 - check column names" );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',       'C' => '' },
            { 'A' => 'k1', 'B' => '',       'C' => 'v' },
            { 'A' => '',   'B' => '',       'C' => '' },
            { 'A' => 'k2', 'B' => 'foo',    'C' => 'v2' },
            { 'A' => 'k3', 'B' => 'bar',    'C' => 'v3' },
            { 'A' => '',   'B' => 'foobar', 'C' => 'v4' }
        ],
        "CR03 - check fields after get_fields_names"
    );

    my @cols1 = $csv->get_fields_names();
    is_deeply( \@cols1, [ 'A', 'B', 'C' ], "CR04 - check column names (1)" );

    sub mycrfunc2 {
        my ( $field, $hr, $stats ) = @_;
        $stats->{'field value calculation'}++;
        return $hr->{'A'} . '--<' . uc( $hr->{'C'} ) . '>';
    }
    $csv->field_add_computed( 'CREATED', \&mycrfunc2 );
    my @cols2 = $csv->get_fields_names();
    is_deeply(
        \@cols2,
        [ 'A', 'B', 'C', 'CREATED' ],
        "CR05 - check column names (2)"
    );

    $csv->field_add_copy( 'COPIED', 'A' );
    my @cols3 = $csv->get_fields_names();
    is_deeply(
        \@cols3,
        [ 'A', 'B', 'C', 'CREATED', 'COPIED' ],
        "CR06 - check column names (3)"
    );

    $csv->field_add_link( 'LINKED', 'A->B->SITE', "t/${ww}l01b.csv" );
    my @cols4 = $csv->get_fields_names();
    is_deeply(
        \@cols4,
        [ 'A', 'B', 'C', 'CREATED', 'COPIED', 'LINKED' ],
        "CR07 - check column names (4)"
    );

    $csv->read();
    my @cols5 = $csv->get_fields_names();
    is_deeply(
        \@cols5,
        [ 'A', 'B', 'C', 'CREATED', 'COPIED', 'LINKED' ],
        "CR08 - check column names (5)"
    );

    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            {
                'A'       => '',
                'B'       => '',
                'C'       => '',
                'COPIED'  => '',
                'CREATED' => '--<>',
                'LINKED'  => undef
            },
            {
                'A'       => 'k1',
                'B'       => '',
                'C'       => 'v',
                'COPIED'  => 'k1',
                'CREATED' => 'k1--<V>',
                'LINKED'  => 'ici'
            },
            {
                'A'       => '',
                'B'       => '',
                'C'       => '',
                'COPIED'  => '',
                'CREATED' => '--<>',
                'LINKED'  => undef
            },
            {
                'A'       => 'k2',
                'B'       => 'foo',
                'C'       => 'v2',
                'COPIED'  => 'k2',
                'CREATED' => 'k2--<V2>',
                'LINKED'  => 'ici'
            },
            {
                'A'       => 'k3',
                'B'       => 'bar',
                'C'       => 'v3',
                'COPIED'  => 'k3',
                'CREATED' => 'k3--<V3>',
                'LINKED'  => undef
            },
            {
                'A'       => '',
                'B'       => 'foobar',
                'C'       => 'v4',
                'COPIED'  => '',
                'CREATED' => '--<V4>',
                'LINKED'  => undef
            }
        ],
        "CR09 - field_add_computed (and get_fields_names in-between)"
    );

    $csv->field_add_copy( 'COPY_OF_A', 'A' );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            {
                'A'         => '',
                'B'         => '',
                'C'         => '',
                'COPIED'    => '',
                'COPY_OF_A' => '',
                'CREATED'   => '--<>',
                'LINKED'    => undef
            },
            {
                'A'         => 'k1',
                'B'         => '',
                'C'         => 'v',
                'COPIED'    => 'k1',
                'COPY_OF_A' => 'k1',
                'CREATED'   => 'k1--<V>',
                'LINKED'    => 'ici'
            },
            {
                'A'         => '',
                'B'         => '',
                'C'         => '',
                'COPIED'    => '',
                'COPY_OF_A' => '',
                'CREATED'   => '--<>',
                'LINKED'    => undef
            },
            {
                'A'         => 'k2',
                'B'         => 'foo',
                'C'         => 'v2',
                'COPIED'    => 'k2',
                'COPY_OF_A' => 'k2',
                'CREATED'   => 'k2--<V2>',
                'LINKED'    => 'ici'
            },
            {
                'A'         => 'k3',
                'B'         => 'bar',
                'C'         => 'v3',
                'COPIED'    => 'k3',
                'COPY_OF_A' => 'k3',
                'CREATED'   => 'k3--<V3>',
                'LINKED'    => undef
            },
            {
                'A'         => '',
                'B'         => 'foobar',
                'C'         => 'v4',
                'COPIED'    => '',
                'COPY_OF_A' => '',
                'CREATED'   => '--<V4>',
                'LINKED'    => undef
            }
        ],
        "CR10 - keep extra fields after field_add_copy"
    );
}

# * ************ *
# * [LI]nk_field *
# * ************ *

{
    note("");
    note("[LI]nk_field() tests");

    my $tmpf            = &get_non_existent_temp_file_name();
    my $csv_link_target = Text::AutoCSV->new(
        in_file                 => "t/${ww}l01b.csv",
        croak_if_error          => 0,
        search_ignore_ambiguous => 0
    );
    my $csv = Text::AutoCSV->new(
        in_file        => "t/${ww}l01a.csv",
        croak_if_error => 0,
        out_file       => $tmpf
    )->field_add_link( 'S', 'A->B->SITE', $csv_link_target )->write();

    my $csvcopy = Text::AutoCSV->new( in_file => $tmpf );
    my $all = [ $csvcopy->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',       'C' => '',   'S' => '' },
            { 'A' => 'k1', 'B' => '',       'C' => 'v',  'S' => 'ici' },
            { 'A' => '',   'B' => '',       'C' => '',   'S' => '' },
            { 'A' => 'k2', 'B' => 'foo',    'C' => 'v2', 'S' => 'ici' },
            { 'A' => 'k3', 'B' => 'bar',    'C' => 'v3', 'S' => '' },
            { 'A' => '',   'B' => 'foobar', 'C' => 'v4', 'S' => '' }
        ],
        "LI01 - field_add_link with object and no option"
    );

    $csv =
      Text::AutoCSV->new( in_file => "t/${ww}l01a.csv", croak_if_error => 0 )
      ->field_add_link( 'T', 'A->B->SITE', "t/${ww}l01b.csv",
        { ignore_ambiguous => 0 } );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',       'C' => '',   'T' => undef },
            { 'A' => 'k1', 'B' => '',       'C' => 'v',  'T' => 'ici' },
            { 'A' => '',   'B' => '',       'C' => '',   'T' => undef },
            { 'A' => 'k2', 'B' => 'foo',    'C' => 'v2', 'T' => 'ici' },
            { 'A' => 'k3', 'B' => 'bar',    'C' => 'v3', 'T' => undef },
            { 'A' => '',   'B' => 'foobar', 'C' => 'v4', 'T' => undef }
        ],
        "LI02 - field_add_link with filename and no option"
    );

    $csv = Text::AutoCSV->new(
        in_file                 => "t/${ww}l01a.csv",
        croak_if_error          => 0,
        search_ignore_ambiguous => 0
      )
      ->field_add_link( 'T', 'A->B->SITE', "t/${ww}l01b.csv",
        { value_if_not_found => '<not found>' } );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',       'C' => '',   'T' => '<not found>' },
            { 'A' => 'k1', 'B' => '',       'C' => 'v',  'T' => 'ici' },
            { 'A' => '',   'B' => '',       'C' => '',   'T' => '<not found>' },
            { 'A' => 'k2', 'B' => 'foo',    'C' => 'v2', 'T' => 'ici' },
            { 'A' => 'k3', 'B' => 'bar',    'C' => 'v3', 'T' => undef },
            { 'A' => '',   'B' => 'foobar', 'C' => 'v4', 'T' => '<not found>' }
        ],
        "LI03 - field_add_link with filename and option value_if_not_found"
    );

    $csv =
      Text::AutoCSV->new( in_file => "t/${ww}l01a.csv", croak_if_error => 0 )
      ->field_add_link( 'T', 'A->B->SITE', "t/${ww}l01b.csv",
        { value_if_ambiguous => '<ambiguous>', ignore_ambiguous => 0 } );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',       'C' => '',   'T' => undef },
            { 'A' => 'k1', 'B' => '',       'C' => 'v',  'T' => 'ici' },
            { 'A' => '',   'B' => '',       'C' => '',   'T' => undef },
            { 'A' => 'k2', 'B' => 'foo',    'C' => 'v2', 'T' => 'ici' },
            { 'A' => 'k3', 'B' => 'bar',    'C' => 'v3', 'T' => '<ambiguous>' },
            { 'A' => '',   'B' => 'foobar', 'C' => 'v4', 'T' => undef }
        ],
        "LI04 - field_add_link with filename and option value_if_ambiguous"
    );

    $csv = Text::AutoCSV->new(
        in_file                 => "t/${ww}l01a.csv",
        croak_if_error          => 0,
        search_ignore_ambiguous => 0
      )->field_add_link(
        undef,
        'A->B->SITE',
        "t/${ww}l01b.csv",
        {
            value_if_not_found => '<not found>',
            value_if_ambiguous => '<ambiguous>'
        }
      );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',    'C' => '',   'SITE' => '<not found>' },
            { 'A' => 'k1', 'B' => '',    'C' => 'v',  'SITE' => 'ici' },
            { 'A' => '',   'B' => '',    'C' => '',   'SITE' => '<not found>' },
            { 'A' => 'k2', 'B' => 'foo', 'C' => 'v2', 'SITE' => 'ici' },
            { 'A' => 'k3', 'B' => 'bar', 'C' => 'v3', 'SITE' => '<ambiguous>' },
            {
                'A'    => '',
                'B'    => 'foobar',
                'C'    => 'v4',
                'SITE' => '<not found>'
            }
        ],
"LI05 - field_add_link with filename and options value_if_not_found + value_if_ambiguous"
    );

    $csv = Text::AutoCSV->new(
        in_file                 => "t/${ww}l01a.csv",
        croak_if_error          => 0,
        search_ignore_ambiguous => 0
      )
      ->field_add_link( 'T', 'A->B->SITE', "t/${ww}l01b.csv",
        { ignore_ambiguous => 1 } );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',       'C' => '',   'T' => undef },
            { 'A' => 'k1', 'B' => '',       'C' => 'v',  'T' => 'ici' },
            { 'A' => '',   'B' => '',       'C' => '',   'T' => undef },
            { 'A' => 'k2', 'B' => 'foo',    'C' => 'v2', 'T' => 'ici' },
            { 'A' => 'k3', 'B' => 'bar',    'C' => 'v3', 'T' => 'labas' },
            { 'A' => '',   'B' => 'foobar', 'C' => 'v4', 'T' => undef }
        ],
        "LI06 - field_add_link with filename and option ignore_ambiguous"
    );

    $csv =
      Text::AutoCSV->new( in_file => "t/${ww}l01a.csv", croak_if_error => 0 )
      ->field_add_link( 'T', 'A->B->SITE', "t/${ww}l01b.csv",
        { value_if_not_found => '<not found>', ignore_ambiguous => 1 } );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',       'C' => '',   'T' => '<not found>' },
            { 'A' => 'k1', 'B' => '',       'C' => 'v',  'T' => 'ici' },
            { 'A' => '',   'B' => '',       'C' => '',   'T' => '<not found>' },
            { 'A' => 'k2', 'B' => 'foo',    'C' => 'v2', 'T' => 'ici' },
            { 'A' => 'k3', 'B' => 'bar',    'C' => 'v3', 'T' => 'labas' },
            { 'A' => '',   'B' => 'foobar', 'C' => 'v4', 'T' => '<not found>' }
        ],
"LI07 - field_add_link with filename and options value_if_not_found + ignore_ambiguous"
    );

    $csv =
      Text::AutoCSV->new( in_file => "t/${ww}l01a.csv", croak_if_error => 0 )
      ->field_add_link(
        'T',
        'A->B->SITE',
        "t/${ww}l01b.csv",
        {
            value_if_not_found => '<not found>',
            value_if_found     => '<found>',
            ignore_ambiguous   => 1
        }
      );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '',   'B' => '',       'C' => '',   'T' => '<not found>' },
            { 'A' => 'k1', 'B' => '',       'C' => 'v',  'T' => '<found>' },
            { 'A' => '',   'B' => '',       'C' => '',   'T' => '<not found>' },
            { 'A' => 'k2', 'B' => 'foo',    'C' => 'v2', 'T' => '<found>' },
            { 'A' => 'k3', 'B' => 'bar',    'C' => 'v3', 'T' => '<found>' },
            { 'A' => '',   'B' => 'foobar', 'C' => 'v4', 'T' => '<not found>' }
        ],
"LI08 - field_add_link with filename and options value_if_not_found + ignore_ambiguous"
    );

    unlink $tmpf if !$DEVTIME;
}

# * ****** *
# * [JO]in *
# * ****** *

{
    note("");
    note("[JO]in tests");

    my $tmpf = &get_non_existent_temp_file_name();

    my $csv =
      Text::AutoCSV->new( in_file => "t/${ww}l01a.csv", out_file => $tmpf )
      ->links( '1:', 'A->B', "t/${ww}l01b.csv" );
    my $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            {
                '1:B'    => undef,
                '1:SITE' => undef,
                'A'      => '',
                'B'      => '',
                'C'      => ''
            },
            {
                '1:B'    => 'k1',
                '1:SITE' => 'ici',
                'A'      => 'k1',
                'B'      => '',
                'C'      => 'v'
            },
            {
                '1:B'    => undef,
                '1:SITE' => undef,
                'A'      => '',
                'B'      => '',
                'C'      => ''
            },
            {
                '1:B'    => 'k2',
                '1:SITE' => 'ici',
                'A'      => 'k2',
                'B'      => 'foo',
                'C'      => 'v2'
            },
            {
                '1:B'    => 'k3',
                '1:SITE' => 'labas',
                'A'      => 'k3',
                'B'      => 'bar',
                'C'      => 'v3'
            },
            {
                '1:B'    => undef,
                '1:SITE' => undef,
                'A'      => '',
                'B'      => 'foobar',
                'C'      => 'v4'
            }
        ],
        "JO01 - check links (1)"
    );
    $csv->write();
    $all = [ Text::AutoCSV->new( in_file => $tmpf )->get_hr_all() ];
    is_deeply(
        $all,
        [
            { '1B' => '', '1SITE' => '', 'A' => '', 'B' => '', 'C' => '' },
            {
                '1B'    => 'k1',
                '1SITE' => 'ici',
                'A'     => 'k1',
                'B'     => '',
                'C'     => 'v'
            },
            { '1B' => '', '1SITE' => '', 'A' => '', 'B' => '', 'C' => '' },
            {
                '1B'    => 'k2',
                '1SITE' => 'ici',
                'A'     => 'k2',
                'B'     => 'foo',
                'C'     => 'v2'
            },
            {
                '1B'    => 'k3',
                '1SITE' => 'labas',
                'A'     => 'k3',
                'B'     => 'bar',
                'C'     => 'v3'
            },
            {
                '1B'    => '',
                '1SITE' => '',
                'A'     => '',
                'B'     => 'foobar',
                'C'     => 'v4'
            }
        ],
        "JO02 - check links, write and read just written file"
    );

    $csv = Text::AutoCSV->new( in_file => "t/${ww}l01a.csv", out_file => $tmpf )
      ->links( undef, 'A->B', "t/${ww}l01b.csv" );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            {
                'A'    => '',
                'B'    => '',
                'B_2'  => undef,
                'C'    => '',
                'SITE' => undef
            },
            {
                'A'    => 'k1',
                'B'    => '',
                'B_2'  => 'k1',
                'C'    => 'v',
                'SITE' => 'ici'
            },
            {
                'A'    => '',
                'B'    => '',
                'B_2'  => undef,
                'C'    => '',
                'SITE' => undef
            },
            {
                'A'    => 'k2',
                'B'    => 'foo',
                'B_2'  => 'k2',
                'C'    => 'v2',
                'SITE' => 'ici'
            },
            {
                'A'    => 'k3',
                'B'    => 'bar',
                'B_2'  => 'k3',
                'C'    => 'v3',
                'SITE' => 'labas'
            },
            {
                'A'    => '',
                'B'    => 'foobar',
                'B_2'  => undef,
                'C'    => 'v4',
                'SITE' => undef
            }
        ],
        "JO03 - check links with duplicate field names"
    );
    $csv->write();
    $all = [ Text::AutoCSV->new( in_file => $tmpf )->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '', 'B' => '', 'B_2' => '', 'C' => '', 'SITE' => '' },
            {
                'A'    => 'k1',
                'B'    => '',
                'B_2'  => 'k1',
                'C'    => 'v',
                'SITE' => 'ici'
            },
            { 'A' => '', 'B' => '', 'B_2' => '', 'C' => '', 'SITE' => '' },
            {
                'A'    => 'k2',
                'B'    => 'foo',
                'B_2'  => 'k2',
                'C'    => 'v2',
                'SITE' => 'ici'
            },
            {
                'A'    => 'k3',
                'B'    => 'bar',
                'B_2'  => 'k3',
                'C'    => 'v3',
                'SITE' => 'labas'
            },
            {
                'A'    => '',
                'B'    => 'foobar',
                'B_2'  => '',
                'C'    => 'v4',
                'SITE' => ''
            }
        ],
        "JO04 - check links with duplicate field names"
    );

    unlink $tmpf if !$DEVTIME;
}

# * ****************** *
# * [MU]ltiple updates *
# * ****************** *

{
    note("");
    note(
"[MU]ltiple - combination of field_add_copy(), field_add_computed() and field_add_link()"
    );

    my $csv = Text::AutoCSV->new(
        in_file                 => "t/${ww}l01a.csv",
        croak_if_error          => 0,
        walker_hr               => \&f,
        quiet                   => 1,
        search_ignore_ambiguous => 0,
        no_undef                => 1
      )->field_add_link( 'S', 'A->B->SITE', "t/${ww}l01b.csv" )
      ->field_add_link( 'T', 'A->B->SITE', "t/${ww}l01b.csv",
        { ignore_ambiguous => 1 } )
      ->field_add_link( 'U', 'A->B->SITE', "t/${ww}l01b.csv",
        { value_if_ambiguous => '<ambiguous>' } )
      ->field_add_link( 'V', 'A->B->SITE', "t/${ww}l01b.csv",
        { value_if_not_found => '<not found>' } )
      ->field_add_link( 'W', 'A->ALPHA->S', "t/${ww}l01c.csv",
        { ignore_ambiguous => 1 } )->field_add_copy( 'Y1', 'B' )
      ->field_add_copy( 'Y2', 'W' )->field_add_copy( 'Y3', 'W', \&t )
      ->field_add_link( 'Y4', 'A->ALPHA->S', "t/${ww}l01c.csv",
        { value_if_not_found => '314', value_if_ambiguous => '315' } )
      ->field_add_computed( 'Y5', \&c )->read();
    my @recs;
    sub f { push @recs, $_[0] }
    sub t { s/^.*$/<<\U$&>>/; $_; }

    sub c {
        return
            uc( $_[1]->{A} )
          . lc( $_[1]->{'Y3'} ) . '['
          . uc( $_[1]->{'Y4'} ) . ']';
    }
    is_deeply(
        [@recs],
        [
            {
                'A'  => '',
                'B'  => '',
                'C'  => '',
                'S'  => '',
                'T'  => '',
                'U'  => '',
                'V'  => '<not found>',
                'W'  => '',
                'Y1' => '',
                'Y2' => '',
                'Y3' => '<<>>',
                'Y4' => '314',
                'Y5' => '<<>>[314]'
            },
            {
                'A'  => 'k1',
                'B'  => '',
                'C'  => 'v',
                'S'  => 'ici',
                'T'  => 'ici',
                'U'  => 'ici',
                'V'  => 'ici',
                'W'  => '(ici)',
                'Y1' => '',
                'Y2' => '(ici)',
                'Y3' => '<<(ICI)>>',
                'Y4' => '315',
                'Y5' => 'K1<<(ici)>>[315]'
            },
            {
                'A'  => '',
                'B'  => '',
                'C'  => '',
                'S'  => '',
                'T'  => '',
                'U'  => '',
                'V'  => '<not found>',
                'W'  => '',
                'Y1' => '',
                'Y2' => '',
                'Y3' => '<<>>',
                'Y4' => '314',
                'Y5' => '<<>>[314]'
            },
            {
                'A'  => 'k2',
                'B'  => 'foo',
                'C'  => 'v2',
                'S'  => 'ici',
                'T'  => 'ici',
                'U'  => 'ici',
                'V'  => 'ici',
                'W'  => '(encore)',
                'Y1' => 'foo',
                'Y2' => '(encore)',
                'Y3' => '<<(ENCORE)>>',
                'Y4' => '(encore)',
                'Y5' => 'K2<<(encore)>>[(ENCORE)]'
            },
            {
                'A'  => 'k3',
                'B'  => 'bar',
                'C'  => 'v3',
                'S'  => '',
                'T'  => 'labas',
                'U'  => '<ambiguous>',
                'V'  => '',
                'W'  => '(labas)',
                'Y1' => 'bar',
                'Y2' => '(labas)',
                'Y3' => '<<(LABAS)>>',
                'Y4' => '(labas)',
                'Y5' => 'K3<<(labas)>>[(LABAS)]'
            },
            {
                'A'  => '',
                'B'  => 'foobar',
                'C'  => 'v4',
                'S'  => '',
                'T'  => '',
                'U'  => '',
                'V'  => '<not found>',
                'W'  => '',
                'Y1' => 'foobar',
                'Y2' => '',
                'Y3' => '<<>>',
                'Y4' => '314',
                'Y5' => '<<>>[314]'
            }
        ],
"MU01 - combination of field_add_computed(), field_add_copy() and field_add_link()"
    );

    # 1- write and that's it (see below "2-")
    my $fields_hr = {
        'A'  => 'A',
        'B'  => 'B',
        'C'  => 'C',
        'S'  => 'S',
        'T'  => 'T',
        'U'  => 'U',
        'V'  => 'V',
        'W'  => 'W',
        'Y1' => 'Y1',
        'Y2' => 'Y2',
        'Y3' => 'Y3',
        'Y4' => 'Y4',
        'Y5' => 'Y5'
    };
    my $tmpf = &get_non_existent_temp_file_name();
    $csv->set_out_file($tmpf)->write();
    my $csvcopy = Text::AutoCSV->new(
        in_file        => $tmpf,
        croak_if_error => 0,
        fields_hr      => $fields_hr
    );
    my $all = [ $csvcopy->get_hr_all() ];
    is_deeply(
        $all,
        [
            {
                'A'  => '',
                'B'  => '',
                'C'  => '',
                'S'  => '',
                'T'  => '',
                'U'  => '',
                'V'  => '<not found>',
                'W'  => '',
                'Y1' => '',
                'Y2' => '',
                'Y3' => '<<>>',
                'Y4' => '314',
                'Y5' => '<<>>[314]'
            },
            {
                'A'  => 'k1',
                'B'  => '',
                'C'  => 'v',
                'S'  => 'ici',
                'T'  => 'ici',
                'U'  => 'ici',
                'V'  => 'ici',
                'W'  => '(ici)',
                'Y1' => '',
                'Y2' => '(ici)',
                'Y3' => '<<(ICI)>>',
                'Y4' => '315',
                'Y5' => 'K1<<(ici)>>[315]'
            },
            {
                'A'  => '',
                'B'  => '',
                'C'  => '',
                'S'  => '',
                'T'  => '',
                'U'  => '',
                'V'  => '<not found>',
                'W'  => '',
                'Y1' => '',
                'Y2' => '',
                'Y3' => '<<>>',
                'Y4' => '314',
                'Y5' => '<<>>[314]'
            },
            {
                'A'  => 'k2',
                'B'  => 'foo',
                'C'  => 'v2',
                'S'  => 'ici',
                'T'  => 'ici',
                'U'  => 'ici',
                'V'  => 'ici',
                'W'  => '(encore)',
                'Y1' => 'foo',
                'Y2' => '(encore)',
                'Y3' => '<<(ENCORE)>>',
                'Y4' => '(encore)',
                'Y5' => 'K2<<(encore)>>[(ENCORE)]'
            },
            {
                'A'  => 'k3',
                'B'  => 'bar',
                'C'  => 'v3',
                'S'  => '',
                'T'  => 'labas',
                'U'  => '<ambiguous>',
                'V'  => '',
                'W'  => '(labas)',
                'Y1' => 'bar',
                'Y2' => '(labas)',
                'Y3' => '<<(LABAS)>>',
                'Y4' => '(labas)',
                'Y5' => 'K3<<(labas)>>[(LABAS)]'
            },
            {
                'A'  => '',
                'B'  => 'foobar',
                'C'  => 'v4',
                'S'  => '',
                'T'  => '',
                'U'  => '',
                'V'  => '<not found>',
                'W'  => '',
                'Y1' => 'foobar',
                'Y2' => '',
                'Y3' => '<<>>',
                'Y4' => '314',
                'Y5' => '<<>>[314]'
            }
        ],
"MU02 - combination of field_add_computed(), field_add_copy() and field_add_link() (2)"
    );

    # 2- write after re-reading
    $csv->set_out_file($tmpf)->read()->write();
    my $csvcopy2 = Text::AutoCSV->new(
        in_file        => $tmpf,
        croak_if_error => 0,
        fields_hr      => $fields_hr
    );
    my $all2 = [ $csvcopy2->get_hr_all() ];
    is_deeply(
        $all2,
        [
            {
                'A'  => '',
                'B'  => '',
                'C'  => '',
                'S'  => '',
                'T'  => '',
                'U'  => '',
                'V'  => '<not found>',
                'W'  => '',
                'Y1' => '',
                'Y2' => '',
                'Y3' => '<<>>',
                'Y4' => '314',
                'Y5' => '<<>>[314]'
            },
            {
                'A'  => 'k1',
                'B'  => '',
                'C'  => 'v',
                'S'  => 'ici',
                'T'  => 'ici',
                'U'  => 'ici',
                'V'  => 'ici',
                'W'  => '(ici)',
                'Y1' => '',
                'Y2' => '(ici)',
                'Y3' => '<<(ICI)>>',
                'Y4' => '315',
                'Y5' => 'K1<<(ici)>>[315]'
            },
            {
                'A'  => '',
                'B'  => '',
                'C'  => '',
                'S'  => '',
                'T'  => '',
                'U'  => '',
                'V'  => '<not found>',
                'W'  => '',
                'Y1' => '',
                'Y2' => '',
                'Y3' => '<<>>',
                'Y4' => '314',
                'Y5' => '<<>>[314]'
            },
            {
                'A'  => 'k2',
                'B'  => 'foo',
                'C'  => 'v2',
                'S'  => 'ici',
                'T'  => 'ici',
                'U'  => 'ici',
                'V'  => 'ici',
                'W'  => '(encore)',
                'Y1' => 'foo',
                'Y2' => '(encore)',
                'Y3' => '<<(ENCORE)>>',
                'Y4' => '(encore)',
                'Y5' => 'K2<<(encore)>>[(ENCORE)]'
            },
            {
                'A'  => 'k3',
                'B'  => 'bar',
                'C'  => 'v3',
                'S'  => '',
                'T'  => 'labas',
                'U'  => '<ambiguous>',
                'V'  => '',
                'W'  => '(labas)',
                'Y1' => 'bar',
                'Y2' => '(labas)',
                'Y3' => '<<(LABAS)>>',
                'Y4' => '(labas)',
                'Y5' => 'K3<<(labas)>>[(LABAS)]'
            },
            {
                'A'  => '',
                'B'  => 'foobar',
                'C'  => 'v4',
                'S'  => '',
                'T'  => '',
                'U'  => '',
                'V'  => '<not found>',
                'W'  => '',
                'Y1' => 'foobar',
                'Y2' => '',
                'Y3' => '<<>>',
                'Y4' => '314',
                'Y5' => '<<>>[314]'
            }
        ],
"MU03 - combination of field_add_computed(), field_add_copy() and field_add_link() (3)"
    );

    unlink $tmpf;
}

# * ******************************* *
# * [UP]date: read_post_update_hr() *
# * ******************************* *

{
    note("");
    note("[UP]date: read_post_update_hr()");
    note("  NOTE: out_filter is an alias of write_filter_hr");

    my $csv =
      Text::AutoCSV->new( in_file => "t/${ww}u1.csv", croak_if_error => 0 );
    my $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '2',  'B' => '4' },
            { 'A' => '7',  'B' => '49' },
            { 'A' => '0',  'B' => '0' },
            { 'A' => '1',  'B' => '0' },
            { 'A' => '1',  'B' => '1' },
            { 'A' => '',   'B' => '10' },
            { 'A' => '-9', 'B' => '81' },
            { 'A' => '5',  'B' => '' },
            { 'A' => '',   'B' => '' },
            { 'A' => '-1', 'B' => '1' },
            { 'A' => '5',  'B' => '24' },
            { 'A' => '4',  'B' => '-16' },
            { 'A' => '-3', 'B' => '9' }
        ],
        "UP01 - t/u1.csv: check file is as expected"
    );

    sub wf {
        my $hr = shift;
        my $n  = ( $hr->{'A'} eq '' ? 0 : $hr->{'A'} );
        my $t  = ( $hr->{'B'} eq '' ? 0 : $hr->{'B'} );
        return ( $n**2 == $t );
    }

    my $tmpf = &get_non_existent_temp_file_name();
    Text::AutoCSV->new(
        in_file         => "t/${ww}u1.csv",
        croak_if_error  => 0,
        write_filter_hr => \&wf,
        out_file        => $tmpf
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '2',  'B' => '4' },
            { 'A' => '7',  'B' => '49' },
            { 'A' => '0',  'B' => '0' },
            { 'A' => '1',  'B' => '1' },
            { 'A' => '-9', 'B' => '81' },
            { 'A' => '',   'B' => '' },
            { 'A' => '-1', 'B' => '1' },
            { 'A' => '-3', 'B' => '9' }
        ],
        "UP02 - t/u1.csv: check write with write_filter_hr sub"
    );

    sub up {
        my $hr = shift;
        $hr->{'B'} = abs( $hr->{'B'} ) if $hr->{'B'} ne '';
    }

    Text::AutoCSV->new(
        in_file             => "t/${ww}u1.csv",
        croak_if_error      => 0,
        out_filter          => \&wf,
        read_post_update_hr => \&up,
        out_file            => $tmpf
    )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '2',  'B' => '4' },
            { 'A' => '7',  'B' => '49' },
            { 'A' => '0',  'B' => '0' },
            { 'A' => '1',  'B' => '1' },
            { 'A' => '-9', 'B' => '81' },
            { 'A' => '',   'B' => '' },
            { 'A' => '-1', 'B' => '1' },
            { 'A' => '4',  'B' => '16' },
            { 'A' => '-3', 'B' => '9' }
        ],
"UP03 - t/u1.csv: check write with read_post_update_hr() and out_filter sub"
    );

    sub wf2 {
        my $n = ( $_[0]->{'A'} eq '' ? 0 : $_[0]->{'A'} );
        my $t = ( $_[0]->{'C'} eq '' ? 0 : $_[0]->{'C'} );
        return ( $n**2 == $t );
    }

    sub ccalc { $_ = 0 if $_ eq ''; $_ + 1; }

    Text::AutoCSV->new(
        in_file             => "t/${ww}u1.csv",
        croak_if_error      => 0,
        out_filter          => \&wf2,
        read_post_update_hr => \&up,
        out_file            => $tmpf
    )->field_add_copy( 'C', 'B', \&ccalc )->write();
    $csv = Text::AutoCSV->new( in_file => $tmpf );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'A' => '1', 'B' => '0',  'C' => '1' },
            { 'A' => '5', 'B' => '24', 'C' => '25' }
        ],
        "UP04 - t/u1.csv: check write with read_post_update_hr() and "
          . "out_filter based on a copied field"
    );
    is( $csv->get_max_in_mem_record_count(),
        2, "UP05 - t/u1.csv: check record count in-memory" );

    unlink $tmpf;

    my $c = 0;
    $csv = Text::AutoCSV->new(
        in_file   => "t/${ww}u1.csv",
        walker_hr => sub { $c++; $_[1]->{'my ev'}++; }
    );
    is( $csv->get_max_in_mem_record_count(),
        0, "UP06 - t/u1.csv: check in-memory record count" );
    $csv->read();
    is( $csv->get_max_in_mem_record_count(),
        0, "UP07 - t/u1.csv: check in-memory record count after read()" );
    is( $c, 13,
        "UP08 - t/u1.csv: check in-memory record count after read() (2)" );
}

# * ********** *
# * get_values *
# * ********** *

{
    note("");
    note("[GE]t_values");

    my $csv = Text::AutoCSV->new( in_file => "t/${ww}l01a.csv" );
    my $all = [ $csv->get_values('A') ];
    is_deeply(
        $all,
        [ '', 'k1', '', 'k2', 'k3', '' ],
        "GE01 - t/l01a.csv: get_values('A')"
    );
    $all = [ $csv->get_values('B') ];
    is_deeply(
        $all,
        [ '', '', '', 'foo', 'bar', 'foobar' ],
        "GE02 - t/l01a.csv: get_values('B')"
    );
    $all = [ $csv->get_values('C') ];
    is_deeply(
        $all,
        [ '', 'v', '', 'v2', 'v3', 'v4' ],
        "GE03 - t/l01a.csv: get_values('C')"
    );

    $all = [ $csv->get_values( 'A', sub { /^k[13]$|^$/ } ) ];
    is_deeply(
        $all,
        [ '', 'k1', '', 'k3', '' ],
        "GE04 - t/l01a.csv: get_values('A', sub { ... } )"
    );
    $all = [ $csv->get_values( 'B', sub { m/oo/ } ) ];
    is_deeply(
        $all,
        [ 'foo', 'foobar' ],
        "GE05 - t/l01a.csv: get_values('B', sub { ... } )"
    );
    $all = [ $csv->get_values( 'C', sub { length($_) <= 1 } ) ];
    is_deeply(
        $all,
        [ '', 'v', '' ],
        "GE06 - t/l01a.csv: get_values('C', sub { ... } )"
    );
}

done_testing();

#
# Return the name of a temporary file name that is guaranteed NOT to exist.
#
# If ever it is not possible to return such a name (file exists and cannot be
# deleted), then stop execution.
sub get_non_existent_temp_file_name {
    my $tmpf = tmpnam();
    $tmpf = 'tmp0.csv' if $DEVTIME;

    if ( -f $tmpf ) {
        note("* WARNING *");
        note(
"Deleting file '$tmpf' before starting test. Strange this file already exists!"
        );
        unlink $tmpf;
    }
    die
"File '$tmpf' already exists! Unable to delete it? Any way, tests aborted."
      if -f $tmpf;

    return $tmpf;
}

