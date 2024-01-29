#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

BEGIN {
	use_ok('Web::ACL') || print "Bail out!\n";
}

diag("Testing Web::ACL $Web::ACL::VERSION, Perl $], $^X");

my $worked = 0;
eval {
	my $acl = Web::ACL->new(
		acl => {
			fooBar => {
				ip_auth       => 1,
				slug_auth     => 0,
				require_ip    => 1,
				require_slug  => 0,
				final         => 1,
				slugs         => [],
				slugs_regex   => [],
				allow_subnets => [ '192.168.0.0/16', '127.0.0.1/32' ],
				deny_subnets  => [],
			},
			derp => {
				ip_auth       => 1,
				slug_auth     => 1,
				require_ip    => 1,
				require_slug  => 0,
				final         => 1,
				slugs         => ['derp'],
				slugs_regex   => [],
				allow_subnets => [ '192.168.0.0/16', '127.0.0.1/32' ],
				deny_subnets  => ['10.0.10.0/24'],
			},
			derpderp => {
				ip_auth       => 0,
				slug_auth     => 1,
				require_ip    => 1,
				require_slug  => 0,
				final         => 1,
				slugs         => ['derp'],
				slugs_regex   => [],
				allow_subnets => [],
				deny_subnets  => [],
			},
		}
	);

	if ( !defined( $acl->{acl}{derpderp} ) ) {
		die( '$acl->{acl}{derpderp} is undef' . Dumper($acl) );
	}

	$acl = Web::ACL->new( acl => {} );

	eval { $acl = Web::ACL->new( acl => { foo => [] } ); };
	if ( !$@ ) {
		die('new accepts acl hashes with keys that are not hashes');
	}

	eval { $acl = Web::ACL->new( acl => '' ); };
	if ( !$@ ) {
		die('new accepts acl values that are not hashes');
	}

	eval {
		$acl = Web::ACL->new(
			acl => {
				derpderp => {
					ip_auth       => 0,
					slug_auth     => 1,
					require_ip    => 1,
					require_slug  => 0,
					final         => 1,
					slugs         => '',
					slugs_regex   => [],
					allow_subnets => [],
					deny_subnets  => [],
				},
			},
		);
	};
	if ( !$@ ) {
		die('new accepts acls in which slugs is not a array');
	}

	eval {
		$acl = Web::ACL->new(
			acl => {
				derpderp => {
					ip_auth       => 0,
					slug_auth     => 1,
					require_ip    => 1,
					require_slug  => 0,
					final         => 1,
					slugs         => [],
					slugs_regex   => '',
					allow_subnets => [],
					deny_subnets  => [],
				},
			},
		);
	};
	if ( !$@ ) {
		die('new accepts acls in which slugs_regex is not a array');
	}

	eval {
		$acl = Web::ACL->new(
			acl => {
				derpderp => {
					ip_auth       => 0,
					slug_auth     => 1,
					require_ip    => 1,
					require_slug  => 0,
					final         => 1,
					slugs         => [],
					slugs_regex   => [],
					allow_subnets => '',
					deny_subnets  => [],
				},
			},
		);
	};
	if ( !$@ ) {
		die('new accepts acls in which allows_subnets is not a array');
	}

	eval {
		$acl = Web::ACL->new(
			acl => {
				derpderp => {
					ip_auth       => 0,
					slug_auth     => 1,
					require_ip    => 1,
					require_slug  => 0,
					final         => 1,
					slugs         => [],
					slugs_regex   => [],
					allow_subnets => [],
					deny_subnets  => '',
				},
			},
		);
	};
	if ( !$@ ) {
		die('new accepts acls in which deny_subnets is not a array');
	}

	$worked = 1;
};
ok( $worked eq '1', 'new test' ) or diag( "new test died with ... " . $@ );

done_testing(2);
