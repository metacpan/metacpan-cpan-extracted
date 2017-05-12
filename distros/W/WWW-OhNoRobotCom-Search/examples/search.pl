#!/usr/bin/env perl

use strict;
use warnings;

die "Usage: perl searc.pl <xkcd_search_term>\n"
    unless @ARGV;

my $Term = shift;

use lib qw(../lib  lib);
use WWW::OhNoRobotCom::Search;
my $site = WWW::OhNoRobotCom::Search->new;

my $results_ref = $site->search( $Term, comic_id => 56 )
    or die $site->error;

print "Results:\n", map { "$results_ref->{$_} ( $_ )\n" } keys %$results_ref;


=pod

Script for searching XKCD comics.

=cut