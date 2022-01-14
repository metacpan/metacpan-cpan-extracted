BEGIN {
	@good_uri_pairs = (
	[qw( http://www.example.com       http    www.example.com      80) ],
	[qw( http://www.example.com:8080  http    www.example.com    8080) ],
	[qw( http://www.example.com       HTTP    www.example.com      80) ],
	[qw( https://www.example.com      https   www.example.com     443) ],
	[qw( ftp://ftp.example.com        ftp     ftp.example.com      21) ],
	[qw( ftp://ftp.example.com        fTp     ftp.example.com      21) ],
	[qw( gopher://gopher.example.com/ gopher  gopher.example.com   70) ],
	[qw( file://localhost/Otters      file    localhost          PASS) ],
	[qw( nntp://nntp.perl.org         nntp    nntp.perl.org       119) ],
	[qw( mailto:bdfoy@example.com     mailto  PASS               PASS) ],
	);

	@bad_uri_pairs = (
	[qw( http://www.example.com           NULL  NULL            NULL)],
	[qw( ftp://ftp.example.org            http  www.example.com   80)],
	[qw( gopher://gopher.example.com/     1     www.example.com NULL)],
	[qw( file://localhost/Otters       file://  PASS               9)],
	[qw( nntp://nntp.perl.org          nntp:    NULL            NULL)],
	[qw( mailto:bdfoy@example.com      mail     example.com       25)],
	);
}

use Test::Builder::Tester;
use Test::More;
use Test::URI;

foreach my $pair ( @good_uri_pairs )
	{
	test_out( map "ok $_", 1 .. 3 );
	uri_scheme_ok( $pair->[0], $pair->[1] );
	$pair->[2] eq 'PASS' ? ok(1) : uri_host_ok( $pair->[0], $pair->[2] );
	$pair->[3] eq 'PASS' ? ok(1) : uri_port_ok( $pair->[0], $pair->[3] );
	test_test("uri_scheme_ok, uri_host_ok, uri_port_ok with string");

	my $uri = URI->new( $$pair[0] );

	if( UNIVERSAL::isa( $uri, 'URI' ) )
		{
		test_out( map "ok $_", 1 .. 3 );
		$pair->[1] eq 'PASS' ? ok(1) : uri_scheme_ok( $uri, $pair->[1] );
		$pair->[2] eq 'PASS' ? ok(1) : uri_host_ok( $uri, $pair->[2] );
		$pair->[3] eq 'PASS' ? ok(1) : uri_port_ok( $uri, $pair->[3] );
		test_test("uri_scheme_ok, uri_host_ok, uri_port_ok with object");
		}
	else
		{
		ok(0, 'URI did not like good URI');
		}
	}

foreach my $pair ( @bad_uri_pairs )
	{
	my @array = map { $_ eq NULL ? '' : $_ } @$pair;

	my $uri = URI->new( $array[0] );

	my $scheme = $uri->can('scheme') ? $uri->scheme : '';
	my $host   = $uri->can('host')   ? $uri->host   : '';
	my $port   = $uri->can('port')   ? $uri->port   : '';

	test_out( "not ok 1" );
	if( $array[1] eq 'PASS' )
		{
		ok(0);
		}
	else
		{
		uri_scheme_ok( $array[0], $array[1] );
		test_diag("    Failed test ($0 at line " . line_num(-1) . ")",
			"URI [$array[0]] does not have the right scheme",
			"\tExpected [$array[1]]",
			"\tGot [$scheme]");
		}
	test_test(
		title    => 'uri_host_ok scheme errors',
		skip_err => 1,
		);

	test_out( "not ok 1" );
	if( $array[2] eq 'PASS' )
		{
		ok(0);
		test_diag("    Failed test ($0 at line " . line_num(-1) . ")" );
		}
	else
		{
		uri_host_ok( $array[0], $array[2] );
		if( $host )
			{
			test_diag("    Failed test ($0 at line " . line_num(-1) . ")",
				"URI [$array[0]] does not have the right host",
				"\tExpected [$array[2]]",
				"\tGot [$host]");
			}
		else
			{
			test_diag("    Failed test ($0 at line " . line_num(-10) . ")",
				"$scheme schemes do not have a host" );
			}
		}
	test_test(
		title    => 'uri_host_ok catches errors',
		skip_err => 1,
		);

	test_out( "not ok 1" );
	if( $array[3] eq 'PASS' )
		{
		ok(0);
		}
	else
		{
		uri_port_ok( $array[0], $array[3] );
		if( $port )
			{
			test_diag("    Failed test ($0 at line " . line_num(-1) . ")",
				"URI [$array[0]] does not have the right port",
				"\tExpected [$array[3]]",
				"\tGot [$port]");
			}
		else
			{
			test_diag("    Failed test ($0 at line " . line_num(-10) . ")",
				"$scheme schemes do not have a port" );
			}
		}
	test_test(
		title    => 'uri_port_ok catches errors',
		skip_err => 1,
		);

	}

done_testing();
