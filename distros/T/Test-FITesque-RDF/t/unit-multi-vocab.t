=pod

=encoding utf-8

=head1 PURPOSE

Unit test that Test::FITesque::RDF transforms data correctly from RDF with multiple vocabularies

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


my $file = $Bin . '/data/multi-vocab.ttl';


use_ok('Test::FITesque::RDF');
my $t = Test::FITesque::RDF->new(source => $file);

my $data = $t->transform_rdf;

my $simple = [[
					[
					 'Internal::Fixture::Simple'
					],
					[
					 'multi_vocabs',
					 {
					  'http://example.org/other-vocab#foo' => '42',
					  'all' => 'counter-clockwise dahut',
					  'description' => 'Echo a string',
					 }
					]
				  ]];


cmp_deeply($data, $simple);


done_testing;

