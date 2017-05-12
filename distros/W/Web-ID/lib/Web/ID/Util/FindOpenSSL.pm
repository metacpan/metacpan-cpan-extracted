package Web::ID::Util::FindOpenSSL;

our $AUTHORITY = "cpan:TOBYINK";
our $VERSION   = "1.927";

use strict;
use File::ShareDir qw/dist_dir/;
use File::Spec;

my @possible = (
	'c:\\openssl\\bin\\openssl.exe',
	'/usr/bin/openssl',
	'/usr/local/bin/openssl',
);
push @possible, $ENV{OPENSSL_PATH} if exists $ENV{OPENSSL_PATH};
push @possible, File::Spec->catfile(
	dist_dir("Alien-OpenSSL"),
	"bin",
	"openssl",
) if eval { dist_dir("Alien-OpenSSL") };

my $openssl;
sub find_openssl
{
	return $openssl
		if defined $openssl && -f $openssl;
	
	for my $try (@possible)
	{
		return ($openssl = $try) if -f $try;
	}
	
	return;
}

1;
