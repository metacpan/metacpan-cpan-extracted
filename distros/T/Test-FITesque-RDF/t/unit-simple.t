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
use FindBin qw($Bin);


my $file = $Bin . '/data/simple.ttl';

use Test::FITesque::RDF;


my $t = object_ok(
						sub { Test::FITesque::RDF->new(source => $file) }, '$t',
						isa => [qw(Test::FITesque::RDF Moo::Object)],
						can => [qw(source suite transform_rdf)]);




my $data = $t->transform_rdf;
cmp_deeply($data, [
			  [ [ 'Internal::Fixture::Simple' ],
				 [ 'string_found',
					{
                'description' => 'Echo a string',
					 'all' => 'counter-clockwise dahut'
					}
				 ]
			  ] ]);


done_testing;

