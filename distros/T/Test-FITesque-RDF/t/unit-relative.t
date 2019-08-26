=pod

=encoding utf-8

=head1 PURPOSE

Simple unit test that Test::FITesque::RDF transforms data correctly from RDF

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


my $file = $Bin . '/data/relative.ttl';

use Test::FITesque::RDF;


my $t = object_ok(
						sub { Test::FITesque::RDF->new(source => $file,
																 base_uri => 'http://example.org/') }, '$t',
						isa => [qw(Test::FITesque::RDF Moo::Object)],
						can => [qw(source suite transform_rdf base_uri)]);




my $data = $t->transform_rdf;
cmp_deeply($data, [
			  [ [ 'Internal::Fixture::Simple' ],
				 [ 'relative_uri',
					{
					 '-special' => { 'description' => 'Check that a relative URI resolves' },
					 'url' => all(isa('URI'), methods(as_string => 'http://example.org/foo/'))
					}
				 ]
			  ] ]);


done_testing;

