# -*- perl -*-
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Config;
use Data::Dumper;
use lib '.';
use t::test_server;

&setup;
plan tests => 14;

&test_01_location;         #2.
&test_01_location_mobile;  #2.
&test_02_template;         #4.
&test_03_raw_cookie;       #2.
&test_04_cookie;           #2.
&test_05_form;             #2.

# -----------------------------------------------------------------------------
# shortcut.
#
sub check_requires() { &t::test_server::check_requires; }
sub start_server()   { &t::test_server::start_server; }
sub raw_request(@)   { &t::test_server::raw_request; }

# -----------------------------------------------------------------------------
# setup.
#
sub setup
{
	my $failmsg = check_requires();
	if( $failmsg )
	{
		plan skip_all => $failmsg;
	}

	&start_server;
}

# -----------------------------------------------------------------------------
# location.
#
sub test_01_location
{
	my $res = raw_request(
		method => 'GET',
		script => q{
			$TL->startCgi(
				-main => \&main,
			);
			sub main
			{
				$TL->location('http://www.example.org/');
			}
		},
	);
	isa_ok( $res, 'HTTP::Response', '[location] request succeeded');
	is( $res->header('Location'), 'http://www.example.org/', '[location] Location header');
}

## -----------------------------------------------------------------------------
# location. (mobile)
# 
sub test_01_location_mobile
{
	my $res = raw_request(
		method => 'GET',
		script => q{
			$TL->setInputFilter('Tripletail::InputFilter::MobileHTML');
			$TL->startCgi(
				-main => \&main,
			);
			sub main
			{
				$TL->setContentFilter(
					'Tripletail::Filter::MobileHTML',
					charset => 'Shift_JIS',
				);
				$TL->location('http://www.example.org/');
			}
		},
	);
	isa_ok( $res, 'HTTP::Response', '[location] request succeeded');
	is( $res->header('Location'), 'http://www.example.org/', '[location] Location header');
}

# -----------------------------------------------------------------------------
# template.
# 
sub test_02_template
{
	{
		my $res = t::test_server::raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					my $t = $TL->newTemplate;
					$t->setTemplate(q{<&DATA>})->expand(DATA => qq{testdata});
					$TL->setContentFilter('Tripletail::Filter::TEXT');
					$t->flush;
				}
			},
		);
		isa_ok( $res, 'HTTP::Response', '[tmpl] request(1) succeeded');
		is($res->content, 'testdata', '[tmpl] expand,flush');
	}
	
	{
		my $res = t::test_server::raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					$TL->setContentFilter('Tripletail::Filter::HTML');
					my $t = $TL->newTemplate;
					$t->setTemplate(q{<!begin:foo><&TEST><!end:foo><&DATA>});
					$t->node('foo')->add(TEST => 'test')->flush;
					$t->expand(DATA => qq{testdata});
					$t->flush;
				}
			},
		);
		isa_ok( $res, 'HTTP::Response', '[tmpl] request(2) succeeded');
		is($res->content, 'testtestdata', '[tmpl] node,expand,flush');
	}
}

# -----------------------------------------------------------------------------
# raw cookie.
# 
sub test_03_raw_cookie
{
	{
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
					my $c = $TL->getRawCookie;
					
					if ($TL->CGI->get('setcookie')) {
						$c->set(foo => '111');
						
						$TL->print('[set]');
					}
					else {
						$TL->print($c->get('foo') || '[undef]');
					}
				}
			},
			env => {
				QUERY_STRING => 'setcookie=1',
			},
		);
		is $res->content, '[set]', '[raw_cookie] set';
	}
	
	{
		my $res = raw_request(
			method => 'GET',
			env => {
				QUERY_STRING => '',
			},
		);
		is $res->content, '111', '[raw_cookie] get';
	}

}

# -----------------------------------------------------------------------------
# cookie.
#
sub test_04_cookie
{
	{
		my $res = raw_request(
			method => 'GET',
			ini    => {Cookie => {format => 'modern'}},
			script => q{
				$TL->startCgi(
					-main => \&main,
				);

				sub main {
					my $c = $TL->getCookie;

					if ($TL->CGI->get('setcookie')) {
						$c->set(I_AM => $TL->newForm(COOKIE => 'MONSTER'));

						$TL->print('[set]');
					}
					else {
						$TL->print($c->get('I_AM')->get('COOKIE') || '[undef]');
					}
				}
			},
			env => {
				QUERY_STRING => 'setcookie=1',
			},
		);
		is $res->content, '[set]', '[cookie] (set)';
	}

	{
		my $res = raw_request(
			method => 'GET',
			env => {
				QUERY_STRING => '',
			},
		);
		is($res->content, 'MONSTER', '[cookie] (get)');
	}
}

# -----------------------------------------------------------------------------
# form
#
sub test_05_form {
    {
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
                    $TL->print($CGI->get('foo'));
				}
			},
			env => {
				QUERY_STRING => 'foo=bar',
			},
		);
		is $res->content, 'bar', '[form] get';
	}

    {
		my $res = raw_request(
			method => 'GET',
			script => q{
				$TL->startCgi(
					-main => \&main,
				);
				sub main {
                    $CGI->set(foo => 'baz');
                    $TL->print($CGI->get('foo'));
				}
			},
			env => {
				QUERY_STRING => 'foo=bar',
			},
		);
		is $res->status_line, '500 Internal Server Error', '[form] set';
	}
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
