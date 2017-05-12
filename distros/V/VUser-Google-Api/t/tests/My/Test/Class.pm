package My::Test::Class;
use warnings;
use strict;

use Test::Most;
use base qw(Test::Class Class::Data::Inheritable);

use vars qw($gapps_domain $gapps_admin $gapps_passwd);

BEGIN {

    $gapps_domain = $ENV{GAPPS_DOMAIN};
    $gapps_admin  = $ENV{GAPPS_ADMIN};
    $gapps_passwd = $ENV{GAPPS_PASSWD};

    print STDERR "Domain: $gapps_domain\n";

    if (not $gapps_domain
	    and not $gapps_admin
		and not $gapps_passwd
	    ) {
	plan skip_all => 
	    "Set the GAPPS_DOMAIN, GAPPS_ADMIN or GAPPS_PASSWD environment variables to run tests.";
	exit;
    }

    if (defined $ENV{GAPPS_SKIP_LONG_TESTS}) {
	$Test::VUser::Google::SKIP_LONG_TESTS = $ENV{GAPPS_SKIP_LONG_TESTS}?1:0;
    }

    if (not defined $Test::VUser::Google::SKIP_LONG_TESTS) {
	$Test::VUser::Google::SKIP_LONG_TESTS = 0;
	print STDERR "\nSome of the tests can take a long time to complete.";
	print STDERR " (20 minutes or more)\n";
	print STDERR "Would you like to skip these tests? [y/N]: ";
	my $response = <STDIN>;
	$Test::VUser::Google::SKIP_LONG_TESTS = 1 if $response =~ /^y/i;
    }

    __PACKAGE__->mk_classdata('class');
}

INIT {
    Test::Class->runtests;
}

sub startup : Tests( startup => 1 ) {
    my $test = shift;
    ( my $class = ref $test ) =~ s/^Test:://;
    return ok 1, "$class loaded" if $class eq __PACKAGE__;
    use_ok $class or die;
    $test->class($class);
}

sub create_google {
    use VUser::Google::ApiProtocol::V2_0;
    my $google = VUser::Google::ApiProtocol::V2_0->new(
	domain   => $ENV{GAPPS_DOMAIN},
	admin    => $ENV{GAPPS_ADMIN},
	password => $ENV{GAPPS_PASSWD},
	debug    => $ENV{GAPPS_DEBUG} || 0,
    );

    return $google;
}

1;
