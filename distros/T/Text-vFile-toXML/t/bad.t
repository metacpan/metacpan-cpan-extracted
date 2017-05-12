#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 3;

use Text::vFile::toXML;

# This file should not be found
eval { my $a = Text::vFile::toXML->new(filename => 1 + rand(10000000))->to_xml; };
ok($@, "Reading from non-existent file fails");

# Two inputs cannot be specified at the same time
eval { my $a = Text::vFile::toXML->new(data => undef, filename => undef)->to_xml; };
ok($@, "Specifying more than one input fails");

# Must specify one input
eval { my $a = Text::vFile::toXML->new->to_xml; };
ok($@, "Specifying less than one input fails");

__END__


