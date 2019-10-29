=pod

=encoding utf-8

=head1 PURPOSE

Unit test that Test::FITesque::RDF transforms HTTP data correctly from RDF when retrieving external content

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2019 by Inrupt Inc.

This is free software, licensed under:

  The MIT (X11) License


=cut

use strict;
use warnings;

use Test::HTTP::LocalServer;
my $server = Test::HTTP::LocalServer->spawn(html => 'foo');
my $base_url = $server->url;

use Test::Modern;
use Test::Deep;
use FindBin qw($Bin);
use Path::Tiny qw(tempfile path);
use Data::Dumper;

use Test::FITesque::RDF;


subtest 'Invalid remote source' => sub {
  my $file = $Bin . '/data/http-external-content-invalid.ttl';
  my $t = object_ok(
						  sub { Test::FITesque::RDF->new(source => $file) }, 'RDF Fixture object',
						  isa => [qw(Test::FITesque::RDF Moo::Object)],
						  can => [qw(source suite transform_rdf)]);

  like(
		 exception { my $data = $t->transform_rdf; },
		 qr|Could not retrieve content from http://example.invalid/dahut . Got 500|,
		 'Failed to get from invalid host');
};

subtest 'Get content remotely' => sub {
  my $file = path($Bin . '/data/http-external-content.ttl');
  my $ttl = $file->slurp_utf8;
  $ttl =~ s|urn:some_content_to_put|$base_url|;
  my $tempfile = tempfile(suffix => '.ttl');
  my $fh = $tempfile->openw_utf8;
  print $fh $ttl;
  close $fh;
  my $t = object_ok(
						  sub { Test::FITesque::RDF->new(source => $tempfile) }, 'RDF Fixture object',
						  isa => [qw(Test::FITesque::RDF Moo::Object)],
						  can => [qw(source suite transform_rdf)]);

  my $data = $t->transform_rdf;

  cmp_deeply($data,
				 [
				  [
					[
					 'Internal::Fixture::HTTPList'
					],
					[
					 'http_req_res_list_unauthenticated',
					 {
					  '-special' => {
										  'http-pairs' => ignore(),
										'description' => 'Test for content on external URL that is invalid'
										 },
					 }
					]
				  ]
				 ], 'Main structure ok');
  
  my $params = $data->[0]->[1]->[1]->{'-special'};
  
  is(scalar @{$params->{'http-pairs'}}, 1, 'There is request-response pair');

  foreach my $pair (@{$params->{'http-pairs'}}) {
	 object_ok($pair->{request}, 'Checking request object',
				  isa => ['HTTP::Request'],
				  can => [qw(method uri headers content)]
				 );
	 object_ok($pair->{response}, 'Checking response object',
				  isa => ['HTTP::Response'],
				  can => [qw(code headers)]
				 );
  }
  
  is(${$params->{'http-pairs'}}[0]->{request}->method, 'PUT', 'First method is PUT');
  
  like(${$params->{'http-pairs'}}[0]->{request}->content, qr/foo/, 'First request has content');
};


subtest 'Remote source with blank node' => sub {
  my $file = $Bin . '/data/http-external-content-blank.ttl';
  my $t = object_ok(
						  sub { Test::FITesque::RDF->new(source => $file) }, 'RDF Fixture object',
						  isa => [qw(Test::FITesque::RDF Moo::Object)],
						  can => [qw(source suite transform_rdf)]);

  like(
		 exception { my $data = $t->transform_rdf; },
		 qr|Unsupported object _:foo in \S+/http-external-content-blank.ttl|,
		 'Blank node is unsupported');
};



done_testing;

