#!/usr/bin/perl

=encoding UTF-8
=cut

=head1 DESCRIPTION

Thit example has a lot of dependencies that Time::ETA does not need.

But if you have all that modules, you can see nice visualisation of how
Time::ETA works.

=cut

# common modules
use strict;
use warnings FATAL => 'all';
use 5.010;
use Carp;
use Term::ANSIColor;
use Time::HiRes qw(
    usleep
);
use Perl6::Form;
use Time::ETA;

# global vars
my $true = 1;
my $false = '';

# subs
sub sleep_some_time {
    my $sec = 1;
    usleep $sec * 1000000;
    return $false;
}

sub output_object_info {
    my (%params) = @_;

    my $methods = [
        {
            name => 'get_elapsed_seconds',
            type => 'number',
        },
        {
            name => 'get_elapsed_time',
            type => 'string',
        },
        {
            name => 'get_remaining_seconds',
            type => 'number',
        },
        {
            name => 'get_remaining_time',
            type => 'string',
        },
        {
            name => 'sum',
            type => 'number',
        },
        {
            name => 'get_completed_percent',
            type => 'string',
        },
        {
            name => 'is_completed',
            type => 'bool',
        },
        {
            name => 'can_calculate_eta',
            type => 'bool',
        },
    ];

    system('clear');
    say "\n";
    my $spacer = " "x2;
    my $all_results;
    foreach my $m (@{$methods}) {
        my $result = '';

        my $method_name = $m->{name};

        eval {
            $result = $params{eta}->$method_name();
        };

        $all_results->{$method_name} = $result;
        if ($method_name eq "sum" ) {
            my $one = $all_results->{get_elapsed_seconds};
            my $two = $all_results->{get_remaining_seconds} || 0;
            $result = $one + $two;
            $method_name = "get_elapsed_seconds() + get_remaining_seconds";
        }

        my $formated_result;
        if ($m->{type} eq 'bool') {
            if ($result) {
                $formated_result = colored ['bright_green'], 'true';
            } else {
                $formated_result = colored ['bright_red'], 'false';
            }
        } else {
            $formated_result = $result;
        }

        my $format_for_result;
        if ($m->{type} eq 'number' and defined $formated_result) {
            $format_for_result = "    {>>.<<<<<<<<<<<}";
        } elsif ($m->{type} eq 'number' and not defined $formated_result) {
            $format_for_result = "   {<<<<<<<<<<<<<<}";
        } elsif ($m->{type} eq 'bool') {
            $format_for_result = "{>>>>>>>>>>>>>>}";
        } elsif ($m->{type} eq 'string') {
            $format_for_result = "{>>>>>}";
        } else {
            croak "Unknown format";
        }

        print form "  {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<} {<<} $format_for_result",
            "$spacer$method_name()",
            "=",
            $formated_result
            ;
    }

    say "\n";

    my $milestones_visualisation = $spacer;
    foreach (0..$params{milestones}) {
        $milestones_visualisation .= "x";
        $milestones_visualisation .= " " x ($params{sections_in_milestone} - 1);
    }

    say $milestones_visualisation;
    say $milestones_visualisation;

    # timeline
    say $spacer . "-" x 78 . "> t";

    # marker
    my $skip = $params{position};
    say $spacer . " " x $skip . "^";
    say $spacer . " " x $skip . "|";

    say "\n\n";

    return $false;
}

# main
sub main {

    my $milestones = 4;
    my $sections_in_milestone = 4;

    my $eta = Time::ETA->new(
        milestones => $milestones,
    );

    my $current_position = 0;

    foreach my $i (1 .. $milestones) {
        foreach (1 .. $sections_in_milestone) {
            sleep_some_time();

            output_object_info(
                eta => $eta,
                milestones => $milestones,
                sections_in_milestone => $sections_in_milestone,
                position => $current_position,
            );
            $current_position++;
        }
        $eta->pass_milestone();
    }

    foreach my $i (1 .. 20) {
        sleep_some_time();

        output_object_info(
            eta => $eta,
            milestones => $milestones,
            sections_in_milestone => $sections_in_milestone,
            position => $current_position,
        );
        $current_position++;
    }

    say '#END';
}

main();
__END__
