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
			uaTest => {
				ua_auth        => 1,
				require_ua     => 1,
				final          => 1,
				ua_regex_allow => ['^allow test$'],
				ua_regex_deny  => ['^deny test$'],
			},
			pathTest => {
				path_auth        => 1,
				require_path     => 1,
				final            => 1,
				path_regex_allow => ['^allow test$'],
				path_regex_deny  => ['^deny test$'],
			},
		}
	);

	my $return = $acl->check(
		apikey => 'derpderp',
		ip     => '192.168.1.2',
		slugs  => ['derp'],
	);
	if ( !$return ) {
		die( 'Slug check for the slugs "derp" for apikey "derpderp" failed... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'derpderp',
		ip     => '192.168.1.2',
		slugs  => ['derp_foo'],
	);
	if ($return) {
		die( 'Slug check for the slugs "derp_foo" for apikey "derpderp" did not fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'fooBar',
		ip     => '192.168.1.2',
		slugs  => ['derp_foo'],
	);
	if ( !$return ) {
		die( 'Slug check for the ip "192.168.1.2" for apikey "fooBar" did fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'fooBar',
		ip     => '1.168.1.2',
		slugs  => ['derp_foo'],
	);
	if ($return) {
		die( 'Slug check for the ip "1.168.1.2" for apikey "fooBar" did not fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'derp',
		ip     => '192.168.1.2',
		slugs  => ['derp'],
	);
	if ( !$return ) {
		die( 'Slug check for the ip "192.168.1.2" and slug "derp" for apikey "derp" did fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'derp',
		ip     => '192.168.1.2',
		slugs  => ['derp2'],
	);
	if ($return) {
		die( 'Slug check for the ip "192.168.1.2" and slug "derp2" for apikey "derp" did not fail... '
				. Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'derp',
		ip     => '1.168.1.2',
		slugs  => ['derp'],
	);
	if ($return) {
		die(
			'Slug check for the ip "1.168.1.2" and slug "derp" for apikey "derp" did not fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => undef,
		ip     => '1.168.1.2',
		slugs  => ['derp'],
	);
	if ($return) {
		die( 'Slug check for the ip "1.168.1.2" and slug "derp" for apikey undef did not fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'doof',
		ip     => '1.168.1.2',
		slugs  => ['derp'],
	);
	if ($return) {
		die(
			'Slug check for the ip "1.168.1.2" and slug "derp" for apikey "doof" did not fail... ' . Dumper($acl) );
	}

	$return = $acl->check( apikey => 'uaTest', );
	if ($return) {
		die( 'UA check for the ua undef for apikey "uaTest" did not fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'uaTest',
		ua     => 'derp',
	);
	if ($return) {
		die( 'UA check for the ua "derp" and for apikey "uaTest" did not fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'uaTest',
		ua     => 'deny test',
	);
	if ($return) {
		die( 'UA check for the ua "deny test" and for apikey "uaTest" did not fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'uaTest',
		ua     => 'allow test',
	);
	if ( !$return ) {
		die( 'UA check for the ua "allow test" and for apikey "uaTest" did not fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'pathTest',
		path   => 'derp',
	);
	if ($return) {
		die( 'path check for the path "derp" and for apikey "pathTest" did not fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'pathTest',
		path   => 'deny test',
	);
	if ($return) {
		die( 'path check for the ua "deny test" and for apikey "pathTest" did not fail... ' . Dumper($acl) );
	}

	$return = $acl->check(
		apikey => 'pathTest',
		path   => 'allow test',
	);
	if ( !$return ) {
		die( 'path check for the ua "allow test" and for apikey "pathTest" did not fail... ' . Dumper($acl) );
	}

	$worked = 1;
};
ok( $worked eq '1', 'new test' ) or diag( "new test died with ... " . $@ );

done_testing(2);
