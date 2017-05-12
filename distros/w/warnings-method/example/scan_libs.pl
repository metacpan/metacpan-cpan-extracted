#!perl

use strict;

use Module::CoreList;
use Module::Load::Conditional qw(check_install requires);

use warnings::method -global;

unless(@ARGV){
	push @ARGV, '5.00503';
}

my $version = shift @ARGV;
print "CorelList for $version\n";

my $inc = join '|', map{ quotemeta } @INC;

$SIG{__WARN__} = sub{
	my $msg = join '', @_;

	$msg =~ s{^Method\s+}{};
	$msg =~ s{at (?:$inc)/(\S+\.pm) line}{at $1 line}o;

	warn $msg;
};

my %checked;
@checked{qw(O)} = ();

foreach my $mod(sort keys %{$Module::CoreList::version{$version}}){
	next if $mod =~ /^CGI::/;   # CGI::Carp
	next if $mod =~ /^thread/i; # for loading order dependency
	next if $mod =~ /^Devel/;   # DB::DB redefinition
	next if $mod =~ /DBM_File/; # possibly not installed
	next if $mod =~ /Tk/;       # possibly not installed

	next if $mod =~ /File::Spec::/; # platform specific
	next if $mod =~ /Win32/;        # platform specific
	next if $mod eq lc $mod; # skip pragmas
	next if $mod =~ /^Pod::Perldoc::/;

	next unless check_install module => $mod;
	next if exists $checked{$mod};

	print "load $mod\n";
	system $^X, '-Mwarnings::method', '-w', '-e', "require $mod"
		and exit 1;

	@checked{(requires $mod)} = ();
}
