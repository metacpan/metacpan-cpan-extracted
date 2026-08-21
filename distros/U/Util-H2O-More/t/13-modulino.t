#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin qw/$Bin/;
use lib qq{$Bin/lib};
use ModulinoH2O;

can_ok q{ModulinoH2O}, qw/new new_with_options time_of_day run/;

my $water = ModulinoH2O->new( name => q{Aquarius} );

isa_ok $water, q{ModulinoH2O}, q{programmatic constructor returns an object inheriting from the modulino package};
can_ok $water, qw/time_of_day name water/;
is $water->name, q{Aquarius}, q{name set by programmatic constructor};
is $water->name(q{Bob}), q{Bob}, q{name accessor remains writable};

is $water->time_of_day(0),  q{night},     q{before 05:00 is night};
is $water->time_of_day(5),  q{morning},   q{05:00 begins morning};
is $water->time_of_day(12), q{afternoon}, q{12:00 begins afternoon};
is $water->time_of_day(17), q{evening},   q{17:00 begins evening};
is $water->time_of_day(21), q{night},     q{21:00 begins night};
like $water->time_of_day, qr/\A(?:morning|afternoon|evening|night)\z/, q{time_of_day works with the current local hour};

my @argv = qw/--name Aquarius --water sparkling --water still/;
my $cli = ModulinoH2O->new_with_options(\@argv);

isa_ok $cli, q{ModulinoH2O}, q{CLI constructor returns an object inheriting from the modulino package};
is $cli->name, q{Aquarius}, q{CLI constructor parses scalar option};
is_deeply $cli->water, [qw/sparkling still/], q{CLI constructor parses repeated array option};
is_deeply \@argv, [], q{GetOptionsFromArray consumes parsed options from the supplied argv array};

# A new parse receives a new object.  In particular, water from the first
# invocation must not survive into the second invocation.
my @first_argv  = qw/--name First --water sparkling/;
my @second_argv = qw/--name Second/;
my $first  = ModulinoH2O->new_with_options(\@first_argv);
my $second = ModulinoH2O->new_with_options(\@second_argv);

is_deeply $first->water, [q{sparkling}], q{first constructor call has its own water value};
is $second->water, undef, q{second constructor call does not retain water from the first call};
isnt ref($first), ref($second), q{baptise creates distinct implementation classes for fresh modulino objects};

# Required-option validation is based on definedness, not truth.  "0" is a
# valid supplied string and must not be mistaken for a missing option.
my @zero_argv = qw/--name 0/;
my $zero = ModulinoH2O->new_with_options(\@zero_argv);
is $zero->name, q{0}, q{false-looking but defined required option is accepted};

my @missing_argv = qw/--water still/;
throws_ok { ModulinoH2O->new_with_options(\@missing_argv) }
    qr/\AMissing --name\n/, q{missing required name is rejected by application validation};

{
    my $stderr = q{};

    {
        local *STDERR;
        open STDERR, q{>}, \$stderr
            or die qq{Could not redirect STDERR: $!};

        my @argv = qw/--definitely-not-an-option/;

        dies_ok {
            ModulinoH2O->new_with_options(\@argv);
        } q{bad command-line options are rejected};
    }

    like $stderr,
        qr/Unknown option: definitely-not-an-option/,
        q{Getopt::Long reports the unknown option};
}

{
    local @ARGV = qw/--name LocalARGV/;
    my $from_global_argv = ModulinoH2O->new_with_options;
    is $from_global_argv->name, q{LocalARGV}, q{new_with_options defaults to parsing global ARGV};
}

{
    my $stdout = q{};
    local *STDOUT;
    open STDOUT, q{>}, \$stdout;
    $cli->run(12);

    is $stdout,
        qq{Good afternoon, Aquarius!\nWhat kind of water would you like?\n- sparkling\n- still\n},
        q{run prints greeting and repeated water selections};
}

{
    my $dry = ModulinoH2O->new( name => q{Dry} );
    my $stdout = q{};
    local *STDOUT;
    open STDOUT, q{>}, \$stdout;
    $dry->run(5);

    is $stdout, qq{Good morning, Dry!\n}, q{run omits water menu when water is undefined};
}

{
    my $empty = ModulinoH2O->new( name => q{Empty}, water => [] );
    my $stdout = q{};
    local *STDOUT;
    open STDOUT, q{>}, \$stdout;
    $empty->run(17);

    is $stdout, qq{Good evening, Empty!\n}, q{run omits water menu when water is an empty array};
}

done_testing;
