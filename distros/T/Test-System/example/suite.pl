#!/usr/bin/perl
# 
# suite.pl
# 
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/08/2009 15:31:37 PST 15:31:37

use strict;
use warnings;
use Getopt::Awesome qw(:all);
use Test::System;
use Test::System::Output::Factory;
use Data::Dumper;
require "example/MyFactory.pm";

define_option('test_groups=s', 'Test groups');
define_option('node=s@', 'Test nodes');
define_option('test_plan=s', 'Test plan');
define_option('test=s@', 'Test, can be a name or a file');
define_option('param=s%', 'Parameters we want to send');
define_option('no-warnings', 'Show warnings?');

my $suite = Test::System->new;
$suite->format_factory_class('MyFactory');

my @formats = keys(%{$suite->available_formats});
define_option('format=s', 'A valid format (' . join(', ', @formats) . ')');
parse_opts();

$suite->show_warnings(!get_opt('no-warnings'));

# Any nodes?
if (get_opt('node')) {
    $suite->nodes(get_opt('node'));
}

if (get_opt('test_groups')) {
    $suite->test_groups(get_opt('test_groups'));
}

my @tests;
if (get_opt('test')) {
    # An array ref!
    my $tmp_tests = get_opt('test');
    foreach (@$tmp_tests) {
        if (m/(.+?)#(.+?)$/) {
            push(@tests, [$1, $2]);
        } else {
            push(@tests, $_);
        }
    }
}

my $plan;
if (get_opt('test_plan')) {
    if (@tests) {
        warn "Hm, you provide a test_plan but also a test?!";
    } else {
        $plan = get_opt('test_plan');
    }
}

if (get_opt('format')) {
    $suite->format(get_opt('format'));
}

if (get_opt('param')) {
    $suite->parameters(get_opt('param'));
}

my %options;
$options{'merge'} = 'foo';
if ($plan) {
    $suite->run_test_plan($plan, \%options);
} else {
    $suite->runtests(\@tests, \%options);
}


# Results?
#print Dumper($suite);
