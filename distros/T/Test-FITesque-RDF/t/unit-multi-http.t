=pod

=encoding utf-8

=head1 PURPOSE

Unit test that Test::FITesque::RDF transforms data correctly from RDF with multiple tests and multiple parameters

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2019 by Inrupt Inc.

This is free software, licensed under:

  The MIT (X11) License


=cut

use strict;
use warnings;
use Test::More;
use Test::Deep;
use FindBin qw($Bin);


my $file = $Bin . '/data/http-list-multi.ttl';


use_ok('Test::FITesque::RDF');
my $t = Test::FITesque::RDF->new(source => $file);

my $data = $t->transform_rdf;

my $put_expect = [
            [
              'Internal::Fixture::HTTPList'
            ],
            [
              'http_req_res_list_unauthenticated',
              {
					'-special' => {
										'description' => 'More elaborate HTTP vocab for PUT then GET test',
										'http-pairs' =>
										[
										 {
										  'regex-fields' => {},
										  'request' => methods(method => 'PUT'),
										  'response' => methods(code => '201'),
										 },
										 {
										  'regex-fields' => {},
										  'request' => methods(method => 'GET'),
										  'response' => isa('HTTP::Response')
										 }
										]
									  }
				  }
            ]
          ];
my $cors_expect = [
            [
              'Internal::Fixture::HTTPList'
            ],
            [
              'http_req_res_list_unauthenticated',
              {
					'-special' => { 'description' => 'Testing CORS header when Origin is supplied by client',
										 'http-pairs' =>
										 [
										  {
											'regex-fields' => {},
											'request' => methods(method => 'GET'),
											'response' => isa('HTTP::Response')
										  }
										 ]
									  }
				  }
				]
			  ];



cmp_deeply($data, [$put_expect, $cors_expect], 'Check basic structure');

my $cors_actual = $data->[1]->[1]->[1]->{'-special'}->{'http-pairs'}->[0];

ok(defined($cors_actual->{'request'}->header('Origin')), 'Origin header found');
ok(defined($cors_actual->{'response'}->header('Access-Control-Allow-Origin')), 'ACAO header found');

is($cors_actual->{'request'}->header('Origin'), $cors_actual->{'response'}->header('Access-Control-Allow-Origin'), 'CORS echos origin');


done_testing;

