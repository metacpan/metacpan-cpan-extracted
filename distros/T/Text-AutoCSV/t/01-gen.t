#!/usr/bin/perl

# t/01-gen.t

#
# Written by Sébastien Millet
# May 2016
#

#
# Test script for Text::AutoCSV: general
#

use strict;
use warnings;
use Fcntl qw(SEEK_SET);

use Test::More tests => 79;

#use Test::More qw(no_plan);

my $OS_IS_PLAIN_WINDOWS = !!( $^O =~ /mswin/i );
my $ww = ( $OS_IS_PLAIN_WINDOWS ? 'ww' : '' );

if ( $ww eq '' ) {
    note("\$ww is empty, no plain Windows environment detected");
}
else {
    note("\$ww is equal to '$ww', Windows environment detected");
}

# FIXME
# Comment when not in dev
#use feature qw(say);
#use Data::Dumper;
#$Data::Dumper::Sortkeys = 1;

BEGIN {
    use_ok('Text::AutoCSV');
}

can_ok( 'Text::AutoCSV', ('new') );

my $csv = Text::AutoCSV->new( in_file => "t/${ww}test.csv" );
isa_ok( $csv, 'Text::AutoCSV' );
$csv = Text::AutoCSV->new(
    in_file        => "t/${ww}bad-file-name.csv",
    croak_if_error => 0,
    quiet          => 1
);
is( $csv, undef, "object not created if input file does not exist" );

# * *********************** *
# * Search member functions *
# * *********************** *

{
    my @memcsv;
    $memcsv[0] =
      Text::AutoCSV->new( in_file => "t/${ww}test.csv", croak_if_error => 0 );
    $memcsv[1] = Text::AutoCSV->new(
        in_file        => "t/${ww}test.csv",
        search_trim    => 0,
        croak_if_error => 0
    );
    $memcsv[2] = Text::AutoCSV->new(
        in_file        => "t/${ww}test.csv",
        search_case    => 1,
        croak_if_error => 0
    );
    $memcsv[3] = Text::AutoCSV->new(
        in_file        => "t/${ww}test.csv",
        search_case    => 1,
        search_trim    => 0,
        croak_if_error => 0
    );

    isa_ok( $_, 'Text::AutoCSV' ) foreach @memcsv;

    for my $i ( 0 .. $#memcsv ) {
        my $m = $memcsv[$i];

        my $desc;
        my @exp;
        if ( $i == 0 ) {
            $desc = '(default)';
            @exp  = (
                'Leoemeyyef, Leieq',
                undef,
                'Leoemeyyef, Leieq',
                'Leoemeyyef, Leieq',
                'Leoemeyyef, Leieq'
            );
        }
        elsif ( $i == 1 ) {
            $desc = '(search_trim => 0)';
            @exp =
              ( 'Leoemeyyef, Leieq', undef, undef, 'Leoemeyyef, Leieq', undef );
        }
        elsif ( $i == 2 ) {
            $desc = '(search_case => 1)';
            @exp =
              ( 'Leoemeyyef, Leieq', undef, 'Leoemeyyef, Leieq', undef, undef );
        }
        elsif ( $i == 3 ) {
            $desc = '(search_case => 1, search_trim => 0)';
            @exp = ( 'Leoemeyyef, Leieq', undef, undef, undef, undef );
        }

        is( $m->vlookup( 'CN', 'LeoemeyyefL', 'DISPLAYNAME' ),
            $exp[0], "$desc vlookup" );
        is( $m->vlookup( 'CN', 'ZeoemeyyefL', 'DISPLAYNAME' ),
            $exp[1], "$desc vlookup of bad key" );
        is( $m->vlookup( 'CN', 'LeoemeyyefL ', 'DISPLAYNAME' ),
            $exp[2], "$desc vlookup of key with space appended" );
        is( $m->vlookup( 'CN', 'LEOEMEYYEFL', 'DISPLAYNAME' ),
            $exp[3], "$desc vlookup of upper case'd key" );
        is( $m->vlookup( 'CN', 'LEOEMEYYEFL ', 'DISPLAYNAME' ),
            $exp[4],
            "$desc vlookup of key with space appended + upper case'd" );
    }
    is(
        $memcsv[0]->vlookup( 'CN', 'LeysLL', 'DISPLAYNAME' ),
        'Leys, Leeee-Lyeeqe',
        "vlookup (one returned out of two elements found)"
    );
    is( $memcsv[0]->vlookup( 'DISPLAYNAME', 'Oyeef, Feemep', 'CN' ),
        'LeysLL', "vlookup (by DISPLAYNAME)" );
    is(
        $memcsv[0]->vlookup(
            'CN', 'LeoemeyyefL',
            'DISPLAYNAME', { value_if_not_found => 'bla' }
        ),
        'Leoemeyyef, Leieq',
        "vlookup with default value"
    );
    is(
        $memcsv[0]->vlookup(
            'CN', 'LeysLL', 'DISPLAYNAME', { value_if_not_found => 'bla' }
        ),
        'Leys, Leeee-Lyeeqe',
        "vlookup (one returned out of two elements found) with default value"
    );
    is(
        $memcsv[0]->vlookup(
            'CN', 'ZeysLL', 'DISPLAYNAME', { value_if_not_found => 'bla' }
        ),
        'bla',
        "vlookup (bad key) with default value"
    );

    is_deeply( $memcsv[0]->search( 'CN', 'LeoemeyyefL' ),
        [17], "search (one element found)" );
    is_deeply( $memcsv[0]->search( 'CN', 'ZeoemeyyefL' ),
        [], "search (bad key)" );
    is_deeply( $memcsv[0]->search( 'CN', 'LeoemeyyefL' )->[0],
        17, "search(...)->[0] (one element found)" );
    is_deeply( $memcsv[0]->search( 'CN', 'ZeoemeyyefL' )->[0],
        undef, "search(...)->[0] (bad key)" );

    my $mm =
      Text::AutoCSV->new( in_file => "t/${ww}test2.csv", croak_if_error => 0 );

    is_deeply(
        $mm->search( 'SAMACCOUNTNAME', 'LeysLL' ),
        [ 2, 5 ],
        "search (two elements found)"
    );
    is_deeply( $mm->search( 'SAMACCOUNTNAME', 'LeysLL' )->[0],
        2, "search(...)->[0] (one returned out of two elements found)" );

    is_deeply(
        $mm->search_1hr( 'SAMACCOUNTNAME', 'LeeeekL' ),
        {
            'SAMACCOUNTNAME' => 'LeeeekL',
            'DISPLAYNAME'    => 'Leeeek, Leeeee',
            'DN'             => 'CN=LeeeekL,OU=uzzzz,OU=HFVAR,DC=company,DC=biz'
        },
        "search1_hr (one element found)"
    );
    is_deeply( scalar( $mm->search_1hr( 'SAMACCOUNTNAME', 'ZeeeekL' ) ),
        undef, "search1_hr (bad key)" );
    is_deeply(
        $mm->search_1hr( 'SAMACCOUNTNAME', 'LeysLL' ),
        {
            'SAMACCOUNTNAME' => 'LeysLL',
            'DISPLAYNAME'    => 'Leys, Leeee-Lyeeqe',
            'DN'             => 'CN=LeysLL,OU=uzzzz,OU=HFVAR,DC=company,DC=biz'
        },
        "search1_hr (one returned out of two elements found)"
    );

    is( $mm->get_cell( 2, 'SAMACCOUNTNAME' ), 'LeysLL', "get_cell" );

    my $mm_no_infoh = Text::AutoCSV->new(
        in_file        => "t/${ww}test2.csv",
        croak_if_error => 0,
        quiet          => 1
    );
    is( $mm_no_infoh->get_cell( 100, 'SAMACCOUNTNAME' ),
        undef, "get_cell (row 100 non-existent)" );

    is_deeply(
        $mm->get_row_hr(5),
        {
            'DN'             => 'CN=OyeefF,OU=uzzzz,OU=HFVAR,DC=company,DC=biz',
            'SAMACCOUNTNAME' => 'LeysLL',
            'DISPLAYNAME'    => 'Oyeef, Feemep'
        },
        "get_row_hr"
    );

    is( $mm_no_infoh->get_row_hr(100),
        undef, "get_row_hr (row 100 non-existent)" );

    my $ar = $mm->get_row_ar(5);
    is_deeply(
        $ar,
        [
            'CN=OyeefF,OU=uzzzz,OU=HFVAR,DC=company,DC=biz', 'LeysLL',
            'Oyeef, Feemep'
        ],
        "get_row_ar"
    );

    is( $mm_no_infoh->get_row_ar(100),
        undef, "get_row_ar (row 100 non-existent)" );

    my @column_names = $mm->get_fields_names();
    is_deeply( \@column_names, [ 'DN', 'SAMACCOUNTNAME', 'DISPLAYNAME' ],
        "get_fields_names" );
    my $cn = $mm->get_field_name(1);
    is_deeply( $cn, 'SAMACCOUNTNAME', "get_field_name" );

    my @r = $mm->get_keys();
    is_deeply( \@r, [ 0, 1, 2, 3, 4, 5, 6 ], "get_keys" );

    my $nb_records = () = $mm->get_keys();
    is( $nb_records, 7,
        "record count idiom: my \$nb_records = () = \$obj->get_keys();" );

    my @allkeys = $mm->get_keys();
    my $lastk   = $allkeys[-1];
    my $aarr    = $mm->get_row_ar($lastk);
    is_deeply(
        $aarr,
        [
            'CN=WeyyeeaqL,OU=uzzzz,OU=HFVAR,DC=company,DC=biz', 'WeyyeeaqL',
            'Weyyeeaq, Leeeeae'
        ],
        "get_keys then get_row_ar"
    );

    @r = $mm->get_values('SAMACCOUNTNAME');
    is_deeply(
        \@r,
        [
            'YeepuW',            'LeeeekL',
            'LeysLL',            'YeieyyeeW',
            'LnfgrypreseeeaLez', 'LeysLL',
            'WeyyeeaqL'
        ],
        "get_values"
    );
}

# * ***************************************************************** *
# * Test objects created passing inh (file handle) and/or Text::CSV   *
# * object to deal with (normally Text::AutoCSV will manage both file *
# * opening and Text::CSV creation).                                  *
# * ***************************************************************** *

{
    open( my $inh, '<', "t/${ww}test2.csv" )
      or die "Unable to open 't/${ww}test2.csv': $!";
    my $mm = Text::AutoCSV->new( inh => $inh );
    is( $mm->vlookup( 'DISPLAYNAME', 'Leys, Leeee-Lyeeqe', 'SAMACCOUNTNAME' ),
        'LeysLL', "file handle passed by caller" );
    close $inh;
}

{
    open( my $inh, '<', "t/${ww}test2.csv" ) ## no critic (InputOutput::RequireBriefOpen)
      or die "Unable to open 't/${ww}test2.csv': $!";
    my $TextCsv = Text::CSV->new(
        {
            sep_char            => "\t",
            allow_whitespace    => 1,
            binary              => 1,
            auto_diag           => 2,
            quote_char          => '\'',
            escape_char         => '\\',
            allow_loose_escapes => 1
        }
    );
    my $mm = Text::AutoCSV->new(
        inh            => $inh,
        in_csvobj      => $TextCsv,
        croak_if_error => 0
    );
    seek $inh, 0, SEEK_SET;
    my $mm_no_infoh = Text::AutoCSV->new(
        inh            => $inh,
        in_csvobj      => $TextCsv,
        croak_if_error => 0,
        quiet          => 1
    );
    my $eval_failed = 0;
    eval {
        $mm_no_infoh->vlookup( 'DISPLAYNAME', 'Lnfgrypreseeea, Lezeea',
            'SAMACCOUNTNAME' );
    }
      or $eval_failed = 1;
    is( $eval_failed, 1,
        "vlookup on input with bad sep_char fails (non existing field)" );
    close $inh;

    open( $inh, '<', "t/${ww}test2.csv" ) ## no critic (InputOutput::RequireBriefOpen)
      or die "Unable to open 't/${ww}test2.csv': $!";
    $TextCsv = Text::CSV->new(
        {
            sep_char            => ';',
            allow_whitespace    => 1,
            binary              => 1,
            auto_diag           => 2,
            quote_char          => '"',
            escape_char         => '\\',
            allow_loose_escapes => 1
        }
    );
    $mm = Text::AutoCSV->new( inh => $inh, in_csvobj => $TextCsv );
    is(
        $mm->vlookup(
            'DISPLAYNAME', 'Lnfgrypreseeea, Lezeea',
            'SAMACCOUNTNAME'
        ),
        'LnfgrypreseeeaLez',
        "file handle and Text::CSV object passed by caller (good CSV object)"
    );
    close $inh;
}

{
    my $TextCsv = Text::CSV->new(
        {
            sep_char            => "\t",
            allow_whitespace    => 1,
            binary              => 1,
            auto_diag           => 2,
            quote_char          => '\'',
            escape_char         => '\\',
            allow_loose_escapes => 1
        }
    );
    my $mm_no_infoh = Text::AutoCSV->new(
        in_file        => "t/${ww}test2.csv",
        in_csvobj      => $TextCsv,
        croak_if_error => 0,
        quiet          => 1
    );
    my $eval_failed = 0;
    eval {
        $mm_no_infoh->vlookup( 'DISPLAYNAME', 'Lnfgrypreseeea, Lezeea',
            'SAMACCOUNTNAME' );
    }
      or $eval_failed = 1;
    is( $eval_failed, 1,
        "vlookup on input with bad sep_char fails (non existing field) (2)" );

    $TextCsv = Text::CSV->new(
        {
            sep_char            => ';',
            allow_whitespace    => 1,
            binary              => 1,
            auto_diag           => 2,
            quote_char          => '"',
            escape_char         => '\\',
            allow_loose_escapes => 1
        }
    );
    my $mm = Text::AutoCSV->new(
        in_file   => "t/${ww}test2.csv",
        in_csvobj => $TextCsv
    );
    is(
        $mm->vlookup(
            'DISPLAYNAME', 'Lnfgrypreseeea, Lezeea',
            'SAMACCOUNTNAME'
        ),
        'LnfgrypreseeeaLez',
        "Text::CSV object passed by caller (good CSV object)"
    );
}

# * *********************************************************************** *
# * sep_char option (check it is well passed on at Text::CSV creation time) *
# * *********************************************************************** *

{
    my $mm =
      Text::AutoCSV->new( in_file => "t/${ww}test3.csv", sep_char => ':' );
    is(
        $mm->vlookup( 'SAMACCOUNTNAME', 'WeyyeeaqL', 'DN' ),
        'CN=WeyyeeaqL,OU=uzzzz,OU=HFVAR,DC=company,DC=biz',
        "sep_char option"
    );
}

# * ******************************* *
# * fields names and header options *
# * ******************************* *

{
    my $mm = Text::AutoCSV->new(
        in_file => "t/${ww}test.csv",
        fields_column_names =>
          [ 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8' ]
    );
    is(
        $mm->vlookup( 'F7', 'NaqeewxeiepN', 'F3' ),
        'Naqeewxeiep, Neaefe',
        "(1) fields_column_names option"
    );
    is( $mm->vlookup( 'F7', 'cn', 'F3' ),
        undef, "(2) fields_column_names option" );

    $mm = Text::AutoCSV->new(
        in_file   => "t/${ww}test.csv",
        fields_ar => [ 'SAMACCOUNTNAME', 'CN', 'DISPLAYNAME' ]
    );
    is(
        $mm->vlookup( 'CN', 'YeeqeeL', 'DISPLAYNAME' ),
        'Yeeqee, Leoeee',
        "fields_ar option"
    );

    $mm = Text::AutoCSV->new(
        in_file => "t/${ww}test.csv",
        fields_hr =>
          { 'My Cn' => 'cn', 'My Sam' => 'sam', 'My Disp' => 'display' }
    );
    is(
        $mm->vlookup( 'My Cn', 'LeszeaaN', 'My Disp' ),
        'Leszeaa, Nyekeaqee',
        "fields_hr option"
    );

    $mm = Text::AutoCSV->new(
        in_file     => "t/${ww}test.csv",
        has_headers => 0,
        fields_column_names =>
          [ 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8' ]
    );
    is(
        $mm->vlookup( 'F7', 'NaqeewxeiepN', 'F3' ),
        'Naqeewxeiep, Neaefe',
        "(1) fields_column_names option, has_heeaders => 0"
    );
    is( $mm->vlookup( 'F7', 'cn', 'F3' ),
        'displayName', "(2) fields_column_names option, has_heeaders => 0" );

# An error should be displayed by Text::AutoCSV about use of fields_ar while has_headers => 0
# We remove this error output by using infoh => 0
    $mm = Text::AutoCSV->new(
        in_file        => "t/${ww}test.csv",
        croak_if_error => 0,
        has_headers    => 0,
        quiet          => 1,
        fields_ar      => [ 'SAMACCOUNTNAME', 'CN', 'DISPLAYNAME' ]
    );
    is( $mm, undef, "incompatible use of fields_ar and has_headers => 0" );

# An error should be displayed by Text::AutoCSV about use of fields_hr while has_headers => 0
    $mm = Text::AutoCSV->new(
        in_file        => "t/${ww}test.csv",
        croak_if_error => 0,
        has_headers    => 0,
        quiet          => 1,
        fields_hr =>
          { 'My Cn' => 'cn', 'My Sam' => 'sam', 'My Disp' => 'display' }
    );
    is( $mm, undef, "incompatible use of fields_hr and has_headers => 0" );

# A warning should be displayed by Text::AutoCSV about parallel use of fields_hr,
# fields_hr and fields_column_names.
# We remove this error output by using infoh => 0
    $mm = Text::AutoCSV->new(
        in_file        => "t/${ww}test.csv",
        croak_if_error => 0,
        quiet          => 1,
        fields_ar      => [ 'SAMACCOUNTNAME', 'CN', 'DISPLAYNAME' ],
        fields_hr =>
          { 'My Cn' => 'cn', 'My Sam' => 'sam', 'My Disp' => 'display' }
    );
    isa_ok( $mm, 'Text::AutoCSV' );
}

# * ******************* *
# * ignore_empty option *
# * ******************* *

{
    my $mm = Text::AutoCSV->new(
        in_file             => "t/${ww}test4.csv",
        search_ignore_empty => 0
    );
    is( $mm->vlookup( 'DISPLAYNAME', 'Leeeek, Leeeee', 'SAMACCOUNTNAME' ),
        'LeeeekL', "(1) search_ignore_empty => 0, regular vlookup" );
    is( $mm->vlookup( 'DISPLAYNAME', '', 'SAMACCOUNTNAME' ),
        'YeepuW', "(2) search_ignore_empty => 0, lookup empty key" );
    is_deeply(
        $mm->search( 'DISPLAYNAME', '' ),
        [ 0, 4 ],
        "(3) search_ignore_empty => 0, lookup empty key"
    );
    is( $mm->_get_hash_build_count(), 1, "check _hash_build_count" );
}

{
    my $mm = Text::AutoCSV->new(
        in_file             => "t/${ww}test4.csv",
        search_ignore_empty => 1
    );
    is( $mm->vlookup( 'DISPLAYNAME', 'Leeeek, Leeeee', 'SAMACCOUNTNAME' ),
        'LeeeekL', "(1) search_ignore_empty => 1, regular vlookup" );
    is( $mm->vlookup( 'DISPLAYNAME', '', 'SAMACCOUNTNAME' ),
        undef, "(2) search_ignore_empty => 1, lookup empty key" );
    is_deeply( $mm->search( 'DISPLAYNAME', '' ),
        [], "(3) search_ignore_empty => 1, lookup empty key" );
    is( $mm->_get_hash_build_count(), 1, "check _hash_build_count" );
}

# * *************** *
# * no_undef option *
# * *************** *

{
    my $csv = Text::AutoCSV->new( in_file => "t/${ww}addresses2.csv" );
    my $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'CITY' => 'Grenoble', 'PERSON' => 'Machin' },
            { 'CITY' => '',         'PERSON' => '' },
            { 'CITY' => 'Paris',    'PERSON' => 'Truc' },
            { 'CITY' => undef,      'PERSON' => '' },
            { 'CITY' => 'New York', 'PERSON' => 'Untel' },
            { 'CITY' => undef,      'PERSON' => '' }
        ],
        "no_undef => 0"
    );

    $csv =
      Text::AutoCSV->new( in_file => "t/${ww}addresses2.csv", no_undef => 1 );
    $all = [ $csv->get_hr_all() ];
    is_deeply(
        $all,
        [
            { 'CITY' => 'Grenoble', 'PERSON' => 'Machin' },
            { 'CITY' => '',         'PERSON' => '' },
            { 'CITY' => 'Paris',    'PERSON' => 'Truc' },
            { 'CITY' => '',         'PERSON' => '' },
            { 'CITY' => 'New York', 'PERSON' => 'Untel' },
            { 'CITY' => '',         'PERSON' => '' }
        ],
        "no_undef => 1"
    );
}

done_testing();

