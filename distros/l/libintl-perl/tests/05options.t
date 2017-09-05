#! /usr/local/bin/perl -w

# vim: syntax=perl
# vim: tabstop=4

use strict;

use Test;

use constant NUM_TESTS => 3;

require Locale::TextDomain;

BEGIN {
	plan tests => NUM_TESTS;
}

my $keywords = Locale::TextDomain->keywords;
ok length $keywords;
my $flags = Locale::TextDomain->flags;
ok length $flags;
my $options = Locale::TextDomain->options;
ok length $options == (length $keywords) + (length $flags) + 1;

__END__

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
cperl-indent-level: 4
cperl-continued-statement-offset: 2
tab-width: 4
End:
