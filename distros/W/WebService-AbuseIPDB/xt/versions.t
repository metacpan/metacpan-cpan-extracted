#
#===============================================================================
#
#         FILE: versions.t
#
#  DESCRIPTION: Release test: Check ALL versions metch
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 23/01/20 11:55:47
#===============================================================================

use strict;
use warnings;

use Test::More;

plan skip_all => 'Author tests not required for installation'
	unless $ENV{RELEASE_TESTING};
plan tests => 7;

# Get version from main module source
use WebService::AbuseIPDB;
my $ver = $WebService::AbuseIPDB::VERSION;

for my $submod (qw/Category Response CheckResponse ReportResponse/) {
	my $mod = 'WebService::AbuseIPDB::' . $submod;
	eval "require $mod";
	is $mod->VERSION, $ver, "Version in $mod matches"
}

open my $in, '<', 'Changes';
<$in> for 1 .. 2;
my $line = <$in>;
my @fields = split / /, $line, 2;
is $fields[0], $ver, 'First entry in Changes matches';
close $in;

open $in, '<', 'README';
$line = <$in>;
chomp $line;
@fields = split / /, $line, 2;
is $fields[1], $ver, 'First line in README matches';
close $in;

open $in, '<', 'Makefile.PL';
($line) = grep { /^my .release/ } <$in>;
my ($rel) = ($line =~ /[0-9._]{4,7}/g);
is $rel, $ver, 'Makefile.PL release matches';
