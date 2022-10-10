# Test suite for GHCN

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin qw($Bin);
use lib $Bin . '/../lib';

use Weather::GHCN::Measures;

use Test::More tests => 21;
use Test::Exception;

use Const::Fast;
use Getopt::Long        qw( GetOptionsFromString );

const my $TRUE   => 1;          # perl's usual TRUE
const my $FALSE  => not $TRUE;  # a dual-var consisting of '' and 0
const my $EMPTY  => '';
const my $SPACE  => q( );

# note that the test profile file does not start with a '.' because
# Dist::Zilla would ignore it when gathering files for the installation
# package.
const my $CONFIG_TEST_FILE => $Bin . '/ghcn_fetch.yaml';

use_ok 'Weather::GHCN::Options';

my $opt;
my @expected;
my @got;
my $href;
my $count;
my $profile_href = {};
my %profile_opt;
my @all_options = Weather::GHCN::Options->get_getopt_list();
my @errors;

$opt = new_ok 'Weather::GHCN::Options';

subtest 'can_ok methods' => sub {
    can_ok $opt, 'combine_options';
    can_ok $opt, 'get_tk_options_table';
    can_ok $opt, 'get_getopt_list';
    can_ok $opt, 'get_option_choices';
    can_ok $opt, 'get_option_defaults';
    can_ok $opt, 'options_as_string';
    can_ok $opt, 'validate';
    can_ok $opt, '_get_boolean_options';
};

subtest 'get methods' => sub {

    @got = Weather::GHCN::Options->get_tk_options_table();

    # nested loop because Devel::Cover complains about condition with mutiple conjunctions
    # uncoverable branch false
    if (@got > 0) {
        # uncoverable branch false
        if (ref $got[0] eq $EMPTY) {
            # uncoverable branch false
            if (ref $got[1] eq 'ARRAY') {
                ok $TRUE, 'get_tk_options_table() returned a list of strings and lists';
            }
        }
    }
    # this is simpler, but is flagged by Devel::Cover Condition Coverage
    # ok @got > 0 && ref $got[0] eq '' && ref $got[1] eq 'ARRAY',
    #     'get_tk_options_table() returned a list of strings and lists';

    @got = Weather::GHCN::Options->get_getopt_list();
    my @options = grep { m{ \A \w+ [=!] }xms } @got;
    ok @options > 20, 'get_getopt_list returned a GetOpt list';

    $href = Weather::GHCN::Options->get_option_choices();
    ok ref $href eq 'HASH', 'get_option_choices returned a hash';
    ok $href->{'report'}, 'get_option_choices hash has a report key';
    ok $href->{'refresh'}, 'get_option_choices hash has a refresh key';

    $href = Weather::GHCN::Options->get_option_defaults();
    ok ref $href eq 'HASH', 'get_option_defaults returned a hash';
    $count = keys $href->%*;
    ok $count > 0, 'get_option_defaults hash is not empty';
};

# at this point we know the options and config methods work well
# enough that we can start testing the functions that rely on data

subtest 'combine_options and validate: -fmonth and -quality' => sub {
    my %user_opt;

    my $user_options = '-fmonth 6';
    GetOptionsFromString($user_options, \%user_opt, @all_options);

    my ($opt_href, $opt_obj) = $opt->combine_options( \%user_opt );

    ok $opt_href->{fmonth} == 6, 'combine_options opt_href fmonth';
    ok $opt_obj->fmonth    == 6, 'combine_options opt_obj fmonth';

    ok $opt_href->{quality} == 90, 'combine_options quality is 90 before validate';

    @errors = $opt->validate();
    ok !@errors, 'validate returned no errors';

    ok $opt_href->quality == 0, 'combine_options quality is 0 after validate';
};

subtest 'combine_options and validate: -fday and -quality' => sub {
    my %user_opt;

    my $user_options = '-fday 15';
    GetOptionsFromString($user_options, \%user_opt, @all_options);

    my ($opt_href, $opt_obj) = $opt->combine_options( \%user_opt );

    ok $opt_href->{fday} == 15, 'combine_options opt_href fday';
    ok $opt_obj->fday    == 15, 'combine_options opt_obj fday';

    ok $opt_href->{quality} == 90, 'combine_options quality is 90 before validate';

    @errors = $opt->validate();
    ok !@errors, 'validate returned no errors';

    ok $opt_href->{quality} == 0, 'combine_options quality is 0 after validate';

};

subtest 'combine_options and validate: -active and -range' => sub {
    my %user_opt;

    my $user_options = '-range 1950-2000 -active ""';
    GetOptionsFromString($user_options, \%user_opt, @all_options);

    my ($opt_href, $opt_obj) = $opt->combine_options( \%user_opt );

    ok $opt_href->{range} eq '1950-2000', 'combine_options range';

    @errors = $opt->validate();
    ok !@errors, 'validate returned no errors';

    # uncoverable branch false
    if ($opt_href->{active}) {
        ok $opt_href->{active} eq $opt_href->{range}, 'active "" defaults to range';
    }
};

subtest 'country validation' => sub {
    my %user_opt;

    my $user_options = '-country CA';
    GetOptionsFromString($user_options, \%user_opt, @all_options);

    my ($opt_href, $opt_obj) = $opt->combine_options( \%user_opt );

    @errors = $opt->validate();
    ok !@errors, 'validate returned no errors';

    $user_options = '-country ZZ';
    GetOptionsFromString($user_options, \%user_opt, @all_options);

    ($opt_href, $opt_obj) = $opt->combine_options( \%user_opt );

    @errors = $opt->validate();
    ok @errors == 1, 'validate returned an error as expected';
    like $errors[0], qr{unrecognized}, 'unrecognized country code (GEC) search';

    $user_options = '-country Canada';
    GetOptionsFromString($user_options, \%user_opt, @all_options);

    ($opt_href, $opt_obj) = $opt->combine_options( \%user_opt );

    @errors = $opt->validate();
    ok !@errors, 'validate returned no errors';
};

subtest 'options_as_string' => sub {
    my %user_opt;

    my $user_options = '-location Ottawa -country CA -state ON -range 2000-2010 -gsn -kml ""';
    GetOptionsFromString($user_options, \%user_opt, @all_options);

    my ($opt_href, $opt_obj) = $opt->combine_options( \%user_opt );
    # using the $profile_href obtained from the test yaml ealier
    @errors = $opt->validate();
    ok !@errors, 'validate returned no errors';

    my $opt_string = $opt->options_as_string;

    my @opt_list = split m{ \s\s }xms, $opt_string;

    $count = grep { $_ =~ m{ -baseline \s \d{4}-\d{4} }xms } @opt_list;
    is $count, 1, , '-baseline found';

    $count = grep { $_ =~ m{-color \s red }xms } @opt_list;
    is $count, 1, , '-color found';

    $count = grep { $_ =~ m{-country \s CA }xms } @opt_list;
    is $count, 1, , '-country found';

    $count = grep { $_ =~ m{ -location \s Ottawa }xms } @opt_list;
    is $count, 1, , '-location found';

    $count = grep { $_ =~ m{ -refresh \s (\w+|\d+) }xms } @opt_list;
    is $count, 1, , '-refresh found';

    $count = grep { $_ =~ m{ -quality \s \d+ }xms } @opt_list;
    is $count, 1, , '-quality found';

    $count = grep { $_ =~ m{ -radius \s \d+ }xms } @opt_list;
    is $count, 1, , '-radius found';

    $count = grep { $_ =~ m{ -range \s \d+[-]\d+ }xms } @opt_list;
    is $count, 1, , '-range found';

    $count = grep { $_ =~ m{ -state \s [[:alpha:]]{2} }xms } @opt_list;
    is $count, 1, , '-state found';

    my @r = grep { $_ =~ m{ -gsn }xms } @opt_list;
    is @r, 1, , "-gsn found (boolean option)";
    is $r[0], '-gsn', '-gsn formatted without a value';

    @r = grep { $_ =~ m{ -kml \s "" }xms } @opt_list;
    is @r, 1, '-kml found (with empty string)';
    is $r[0], '-kml ""', '-kml value formatted as ""';
};

subtest 'validate - values for range and active' => sub {

    my @valid_ranges = qw(
        1800-1899 1900-2099 1976-2000
    );

    my @invalid_ranges = qw(
        2000 10 69-83 12345-54321 zzz -1990 1700-1899
    );

    foreach my $testopt ('-range', '-active') {
        foreach my $r (@valid_ranges) {
            @errors = init_and_validate ($profile_href, $opt, "$testopt $r");
            ok !@errors, "validate good $testopt $r";
            # uncoverable branch true
            diag @errors if @errors;
        }
        note ''; # visual separation
    }

    foreach my $testopt ('-range', '-active') {
        foreach my $r (@invalid_ranges) {
            @errors = init_and_validate ($profile_href, $opt, "$testopt $r");
            # ok @errors, "testing $testopt $r - validate found errors";
            like $errors[0], qr/invalid/, "validate bad $testopt $r";
        }
        note ''; # visual separation
    }
};

subtest 'validate - range a subset of active' => sub {
    my @combos = (
        [ '-active 2000-2010 -range 2000-2010', 1 ],
        [ '-active 2000-2010 -range 2009-2010', 1 ],
        [ '-active 2000-2010 -range 2001-2010', 1 ],
        [ '-active 2000-2010 -range 2001-2009', 1 ],
        [ '-active 2000-2010 -range 1999-2010', 0 ],
        [ '-active 2000-2010 -range 2000-2011', 0 ],
        [ '-active 2000-2010 -range 1999-2011', 0 ],
        [ '-active 2000-2010 -range 1900-1920', 0 ],
        [ '-active 2000-2010 -range 2010-2020', 0 ],
    );

    foreach my $aref (@combos) {
        my ($rng, $is_valid) = $aref->@*;

        @errors = init_and_validate ($profile_href, $opt, $rng);

        if ( $is_valid ) {
            ok !@errors, "validate is_subset $rng";
        } else {
            like $errors[0], qr/subset/, "validate not_a_subset $rng"
        }
    }
};


subtest 'validate - state' => sub {
    my @testopts = (
        [ '-state ON',  1 ],
        [ '-state NY',  1 ],
        [ '-state oh',  1 ],
        [ '-state ABC', 0 ],
        [ '-state X',   0 ],
        [ '-state 1',   0 ],
        [ '-state 12',  0 ],
        [ '-state 0',   0 ],
    );

    foreach my $aref (@testopts) {
        my ($uo, $is_valid) = $aref->@*;

        @errors = init_and_validate ($profile_href, $opt, $uo);
        if ( $is_valid ) {
            ok !@errors, "validate state $uo";
        } else {
            like $errors[0], qr/invalid .*? state/, "validate invalid state $uo";
        }
    }
};

subtest 'validate - partial' => sub {
    my @testopts = (
        [ '-active 2010-2020 -partial',  1 ],
        [ '-partial',                    0 ],
    );

    foreach my $aref (@testopts) {
        my ($uo, $is_valid) = $aref->@*;

        @errors = init_and_validate ($profile_href, $opt, $uo);
        if ( $is_valid ) {
            ok !@errors, "validate partial $uo";
        } else {
            like $errors[0], qr/-partial only allowed if -active/, "validate partial w/o active $uo";
        }
    }
};

subtest 'validate - gps' => sub {
    my @testopts = (
        [ q/ -gps "45.0000 -75.0000"     /, 1 ],
        [ q/ -gps "45.0 -75.0"           /, 1 ],
        [ q/ -gps "45.0,-75.0"           /, 1 ],
        [ q/ -gps "45.0;-75.0"           /, 1 ],
        [ q/ -gps 45.0,-75.0             /, 1 ],
        [ q/ -gps 45.0;-75.0             /, 1 ],
        [ q/ -gps "45 -75"               /, 0 ],
        [ q/ -gps "45    -75"            /, 0 ],
        [ q/ -gps "45 N 75 W"            /, 0 ],
    );

    foreach my $aref (@testopts) {
        my ($uo, $is_valid) = $aref->@*;

        @errors = init_and_validate ($profile_href, $opt, $uo);
        if ( $is_valid ) {
            ok !@errors, "validate gps $uo";
        } else {
            like $errors[0], qr/-gps argument must be/, "validate invalid gps $uo";
        }
    }
};

subtest 'validate - report' => sub {
    my @testopts = (
        [ q/                 /, 1 ],
        [ q/ -report ""      /, 1 ],
        [ q/ -report detail  /, 1 ],
        [ q/ -report daily   /, 1 ],
        [ q/ -report monthly /, 1 ],
        [ q/ -report yearly  /, 1 ],
        [ q/ -report XXX     /, 0 ],
    );

    foreach my $aref (@testopts) {
        my ($uo, $is_valid) = $aref->@*;

        @errors = init_and_validate ($profile_href, $opt, $uo);
        if ( $is_valid ) {
            ok !@errors, "validate report $uo";
        } else {
            like $errors[0], qr/invalid report option/, "validate invalid report $uo";
        }
    }
};

subtest 'validate - color' => sub {
    my @testopts = (
        [ q/ -color blue     /, 1 ],
        [ q/ -color green    /, 1 ],
        [ q/ -color azure    /, 1 ],
        [ q/ -color purple   /, 1 ],
        [ q/ -color red      /, 1 ],
        [ q/ -color white    /, 1 ],
        [ q/ -color yellow   /, 1 ],
        [ q/ -color orange   /, 0 ],
        [ q/ -color zzz      /, 0 ],
        [ q/ -color ""       /, 0 ],
    );

    foreach my $aref (@testopts) {
        my ($uo, $is_valid) = $aref->@*;

        @errors = init_and_validate ($profile_href, $opt, $uo);
        if ( $is_valid ) {
            ok !@errors, "validate color $uo";
        } else {
            my $err = shift @errors;
            # uncoverable branch false
            $err = $err ? $err : $EMPTY;
            like $err, qr/invalid -color value/, "validate invalid color $uo";
        }
    }
};

subtest 'validate - label with kml' => sub {
    my @testopts = (
        [ q/ -kml "myfilespec" -label   /, 1 ],
        [ q/ -kml "myfilespec" -nolabel /, 1 ],
        [ q/ -kml "myfilespec"          /, 1 ],
        [ q/ -label                     /, 0 ],
        [ q/ -nolabel                   /, 0 ],
    );

    foreach my $aref (@testopts) {
        my ($uo, $is_valid) = $aref->@*;

        @errors = init_and_validate ($profile_href, $opt, $uo);
        if ( $is_valid ) {
            ok !@errors, "validate label $uo";
        } else {
            like $errors[0], qr|-label/-nolabel only allowed if -kml|, "validate invalid label $uo";
        }
    }
};

subtest 'validate - fmonth' => sub {
    my @testopts = (
        [ q/ -fmonth 1      /, 1 ],
        [ q/ -fmonth 01     /, 1 ],
        [ q/ -fmonth 12     /, 1 ],
        [ q/ -fmonth 2-6    /, 1 ],
        [ q/ -fmonth 3,7,9  /, 1 ],
        [ q/ -fmonth 4,5-8  /, 1 ],

        [ q/ -fmonth 0      /, 0 ], # only range 1..12 permitted
        [ q/ -fmonth 00     /, 0 ], # only range 1..12 permitted
        [ q/ -fmonth 13     /, 0 ], # only range 1..12 permitted
        [ q/ -fmonth 999    /, 0 ], # only range 1..12 permitted
        [ q/ -fmonth Jan    /, 0 ], # alpha month not allowed
    );

    foreach my $aref (@testopts) {
        my ($uo, $is_valid) = $aref->@*;

        @errors = init_and_validate ($profile_href, $opt, $uo);
        if ( $is_valid ) {
            ok !@errors, "validate fmonth $uo";
        } else {
            like $errors[0], qr/-fmonth must be/, "validate invalid fmonth range spec $uo";
        }
    }
};

subtest 'validate - fday' => sub {
    my @testopts = (
        [ q/ -fday 1      /, 1 ],
        [ q/ -fday 01     /, 1 ],
        [ q/ -fday 30     /, 1 ],
        [ q/ -fday 31     /, 1 ],
        [ q/ -fday 2-6    /, 1 ],
        [ q/ -fday 3,7,9  /, 1 ],
        [ q/ -fday 4,5-8  /, 1 ],

        [ q/ -fday 0      /, 0 ], # only range 1..31 permitted
        [ q/ -fday 00     /, 0 ], # only range 1..31 permitted
        [ q/ -fday 33     /, 0 ], # only range 1..31 permitted
        [ q/ -fday 999    /, 0 ], # only range 1..31 permitted
        [ q/ -fday Tue    /, 0 ], # alpha day not allowed
    );

    foreach my $aref (@testopts) {
        my ($uo, $is_valid) = $aref->@*;

        @errors = init_and_validate ($profile_href, $opt, $uo);
        if ( $is_valid ) {
            ok !@errors, "validate fday $uo";
        } else {
            like $errors[0], qr/-fday must be/, "validate invalid fday range spec $uo";
        }
    }
};

subtest 'validate - _get_boolean_options' => sub {
    my @bool_opts = qw(
        anomalies gsn label nogaps partial performance precip tavg
    );

    my $tk_opt_table = Weather::GHCN::Options->get_tk_options_table();

    my $is_bool_href = Weather::GHCN::Options::_get_boolean_options($tk_opt_table);

    foreach my $o (@bool_opts) {
        ok $is_bool_href->{$o}, "option $o is boolean";
    }

    note '     *I* update this test when new boolean options are added';
};

subtest 'for test coverage' => sub {
    can_ok $opt, 'opt_href';
    can_ok $opt, 'opt_obj';
    can_ok $opt, 'profile_href';

    is $opt->opt_href->{'locationXXX'}, undef, 'opt_href access via mispelled key returns undef';
    throws_ok
        { $opt->opt_obj->locationXXX }
        qr/Can't locate object method "locationXXX"/,
        'opt_obj access via mispelled key throws exception';



    my $user_options = '-country West';
    @errors = init_and_validate ($profile_href, $opt, $user_options);
    ok @errors, 'country West is ambiguous';

    $profile_href = {
        aliases => {
            InvalidAlias => 'USC00326365',
        }
    };
    $user_options = '-location InvalidAlias';
    @errors = init_and_validate ($profile_href, $opt, $user_options);
    ok @errors, "alias 'InvalidAlias' caused error";
};

TODO: { local $TODO = 'TODO: _get_boolean_options'; note $TODO };

######################################################################
# Subroutines for this test script
######################################################################

sub init_and_validate ($profile_href, $opt, $user_options) {
    my %user_opt;
    my @all_options = Weather::GHCN::Options->get_getopt_list;

    # HACK:  Options->profile_href is set by StationTable set_options
    #        but we need it here so Options->initialize (which is
    #        called by Options->validate) will have it for this
    #        test case, the only one involving aliases
    my $save_profile_href = $opt->profile_href;
    $opt->profile_href = $profile_href;

    GetOptionsFromString($user_options, \%user_opt, @all_options);

    my ($opt_href, $opt_obj) = $opt->combine_options( \%user_opt, $profile_href );

    @errors = $opt->validate();

    $opt->profile_href = $save_profile_href;

    return @errors;
}



