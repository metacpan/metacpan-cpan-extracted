#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 51_tags_all.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# Check that the :all export tag actually exports all the tags

use Test::More tests => 2;

require Win32::GUI::Constants::Tags;
require Win32::GUI::Constants;

my @TAGS = @{Win32::GUI::Constants::Tags::tag('all')};
my @ALL = @{Win32::GUI::Constants::_export_ok()};

#both lists the same size?
ok(@TAGS == @ALL, ":all is correct size");

#both lists contain the same items?
my %h;
for my $item (@TAGS, @ALL) {
	$h{$item}++;
}
my @errors;
for my $item (keys %h) {
	next if $h{$item} == 2;
	push @errors, $item;
}
ok(!@errors, "Lists have no differing items (@errors)");
