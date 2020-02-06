=pod

=encoding utf-8

=head1 PURPOSE

Unit test that Test::FITesque::RDF transforms HTTP data correctly from RDF

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2019 by Inrupt Inc.

This is free software, licensed under:

  The MIT (X11) License


=cut

use strict;
use warnings;
use Test::Modern;
use Test::Deep;
use FindBin qw($Bin);
use Data::Dumper;

my $file = $Bin . '/data/http-regex.ttl';

use Test::FITesque::RDF;


my $t = object_ok(
						sub { Test::FITesque::RDF->new(source => $file) }, 'RDF Fixture object',
						isa => [qw(Test::FITesque::RDF Moo::Object)],
						can => [qw(source suite transform_rdf)]);




my $data = $t->transform_rdf;

#warn Dumper($data);
cmp_deeply($data,
[
          [
            [
              'Internal::Fixture::HTTPList'
            ],
            [
              'http_req_res_list_regex',
              {
					'-special' => {
										'description' => 'Test fields with regexps',
										'http-pairs' =>
										[
										 {
										  'request' => isa("HTTP::Request"),
										  'response' => isa("HTTP::Response"),
										  'regex-fields' => {
																	'Link' => 1
																  },
										 },
										 {
										  'request' => isa("HTTP::Request"),
										  'response' => isa("HTTP::Response"),
										  'regex-fields' => {'status' => 1},
										 },
										 {
										  'request' => isa("HTTP::Request"),
										  'response' => isa("HTTP::Response"),
										  'regex-fields' => {
																	'Other-Header' => 1,
																	'Location' => 1
																  }
										 }
										]
									  },
              }
            ]
          ]
        ], 'Main structure ok');

my $params = $data->[0]->[1]->[1]->{'-special'}->{'http-pairs'};

is(scalar @{$params}, 3, 'There are three pairs');

like($params->[0]->{response}->header('Link'), qr|;\\s|, 'Should be single escaped');

is($params->[1]->{response}->code, '201|204', 'Status is correct'); #TODO: This could break if underlying framework starts to enforce a format that only includes three-digit status codes

done_testing;

