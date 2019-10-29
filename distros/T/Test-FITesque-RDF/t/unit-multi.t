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


my $file = $Bin . '/data/multi.ttl';


use_ok('Test::FITesque::RDF');
my $t = Test::FITesque::RDF->new(source => $file);

my $data = $t->transform_rdf;

my $multi = [
				 [
				  'Internal::Fixture::Multi'
				 ],
				 [
				  'multiplication',
				  {
					'-special' => { 'description' => 'Multiply two numbers' },
					'factor1' => '6',
					'product' => '42',
					'factor2' => '7'
				  }
				 ]
				];
my $simple = [
				  [
					'Internal::Fixture::Simple'
				  ],
				  [
					'string_found',
					{
                '-special' => { 'description' => 'Echo a string' },
					 'all' => 'counter-clockwise dahut'
					}
				  ]
				 ];
my $nobase = [
				  [
					'Internal::Fixture::Simple'
				  ],
				  [
					'string_found_long',
					{
                '-special' => { 'description' => 'Run with no param_base' },
					 'http://example.org/my-parameters#all' => 'counter-clockwise dahut'
					}
				  ]
				 ];

cmp_deeply($data, bag($multi, $simple, $nobase), 'Compare the data structures');


done_testing;

