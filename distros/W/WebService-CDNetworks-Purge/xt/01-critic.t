#!/usr/bin/env perl

use strict;
use warnings;

use Test::Perl::Critic;
use Test::More tests => 1;

use FindBin;
use File::Spec;
use File::Basename qw(dirname);

my $rcfile = File::Spec -> catfile($FindBin::RealBin, 'perlcriticrc');
Test::Perl::Critic -> import('-profile' => $rcfile);
critic_ok(File::Spec -> catfile(dirname($FindBin::RealBin), 'lib/WebService/CDNetworks/Purge.pm'), 'Perl-criticize module');

