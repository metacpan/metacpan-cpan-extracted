#! /usr/local/bin/perl -w

# vim: syntax=perl
# vim: tabstop=4

use strict;

use Test;

use constant NUM_TESTS => 7;

use Locale::Messages qw (LC_MESSAGES textdomain bind_textdomain_filter
                          gettext  dgettext  dcgettext
                         ngettext dngettext dcngettext);

BEGIN {
	my $package;
	if ($0 =~ /_pp\.t$/) {
		$package = 'gettext_pp';
	} else {
		$package = 'gettext_xs';
	}
		
	my $selected = Locale::Messages->select_package ($package);
	if ($selected ne $package && 'gettext_xs' eq $package) {
		print "1..0 # Skip: Locale::$package not available here.\n";
		exit 0;
	}
	plan tests => NUM_TESTS;
}

textdomain 'bogus';

my $gettext = gettext ('foobar');
my $dgettext = dgettext (bogus => 'foobar');
my $dcgettext = dcgettext (bogus => 'foobar', LC_MESSAGES);
my $ngettext = ngettext ('foobar', 'barbaz', 1);
my $dngettext = dngettext (bogus => 'foobar', 'barbaz', 1);
my $dcngettext = dcngettext (bogus => 'foobar', 'barbaz', 1, LC_MESSAGES); 

package MyPackage;

use strict;

sub new {
	bless {}, shift;
}

sub filterMethod {
	my ($self, $string) = @_;
	
	return 'prefix - ' . $string;
};

package main;

sub wrapper {
	my ($string, $obj) = @_;

	$obj->filterMethod ($string);
}

my $obj = MyPackage->new;
ok (bind_textdomain_filter ('bogus', \&wrapper, $obj));

my $prefix = 'prefix - ';
ok "$prefix$gettext", gettext ('foobar');
ok "$prefix$dgettext", dgettext (bogus => 'foobar');
ok "$prefix$dcgettext", dcgettext (bogus => 'foobar', LC_MESSAGES);
ok "$prefix$ngettext", ngettext ('foobar', 'barbaz', 1);
ok "$prefix$dngettext", dngettext (bogus => 'foobar', 'barbaz', 1);
ok "$prefix$dcngettext", 
	dcngettext (bogus => 'foobar', 'barbaz', 1, LC_MESSAGES); 

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
