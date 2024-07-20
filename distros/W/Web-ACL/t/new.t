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
				ip_auth           => 0,
				slug_auth         => 1,
				require_ip        => 1,
				require_slug      => 0,
				final             => 1,
				slugs             => ['derp'],
				slugs_regex       => [],
				allow_subnets     => [],
				deny_subnets      => [],
				ua_regex_allow    => [],
				ua_regex_deny     => [],
				paths_regex_allow => [],
				paths_regex_deny  => [],
				path_auth         => 0,
				ua_auth           => 0,

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

	my @keys_that_are_arrays = (
		'slugs',            'ua_regex_allow', 'ua_regex_deny', 'paths_regex_allow',
		'paths_regex_deny', 'slugs_regex',    'allow_subnets', 'deny_subnets',
	);
	foreach my $array_key (@keys_that_are_arrays) {
		eval { $acl = Web::ACL->new( acl => { derpderp => { $array_key => '', }, }, ); };
		if ( !$@ ) {
			die( 'new accepts acls in which ' . $array_key . ' is not a ref of ARRAY' );
		}
	}

	my @keys_that_are_boolean = (
		'ip_auth', 'require_ip', 'slug_auth', 'require_slug', 'path_auth', 'require_path',
		'ua_auth', 'require_ua', 'final',
	);
	foreach my $boolean_key (@keys_that_are_boolean) {
		eval { $acl = Web::ACL->new( acl => { derpderp => { $boolean_key => [], }, }, ); };
		if ( !$@ ) {
			die( 'new accepts acls in which ' . $boolean_key . ' is not a ref of ""' );
		}
	}

	$worked = 1;
};
ok( $worked eq '1', 'new test' ) or diag( "new test died with ... " . $@ );

done_testing(2);
