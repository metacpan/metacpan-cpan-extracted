=pod

=encoding utf-8

=head1 PURPOSE

Run the official JSON Schema test suite.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use v5.36;
use Test2::V0;

use JSON::PP qw( decode_json encode_json );
use Path::Tiny qw( path );
use Types::JSONSchema qw( schema_to_type is_JTrue is_JFalse );

use constant TESTS => path( 't/share/JSON-Schema-Test-Suite/tests/draft7' );
use constant SKIP => {
	# Skip entire files
	'refRemote'                           => 'Remote references not implemented',
	'definitions'                         => 'Remote references not implemented',
	'infinite-loop-detection'             => 'Not currently detected',
	
	# Skip particular groups of tests
	'ref/relative pointer ref to object'                                         => 'Complicated references not supported',
	'ref/$ref prevents a sibling $id from changing the base uri'                 => 'Complicated references not supported',
	'ref/remote ref, containing refs itself'                                     => 'Complicated references not supported',
	'ref/Recursive references between schemas'                                   => 'Complicated references not supported',
	'ref/Reference an anchor with a non-relative URI'                            => 'Complicated references not supported',
	'ref/Location-independent identifier with base URI change in subschema'      => 'Complicated references not supported',
	'ref/refs with relative uris and defs'                                       => 'Complicated references not supported',
	'ref/relative refs with absolute uris and defs'                              => 'Complicated references not supported',
	'ref/$id must be resolved against nearest parent, not just immediate parent' => 'Complicated references not supported',
	'ref/URN base URI with URN and JSON pointer ref'                             => 'Complicated references not supported',
	'ref/URN base URI with URN and anchor ref'                                   => 'Complicated references not supported',
	'ref/ref to if'                                                              => 'Complicated references not supported',
	'ref/ref to then'                                                            => 'Complicated references not supported',
	'ref/ref to else'                                                            => 'Complicated references not supported',
	'ref/ref with absolute-path-reference'                                       => 'Complicated references not supported',
	'additionalItems/additionalItems does not look in applicators, valid case'   => 'Not worth worrying about this deprecated case',
};

my @names;
FILE: for my $file ( sort { $a cmp $b } TESTS->children ) {
	next unless $file->is_file;
	
	my $basename = $file->basename('.json');
	( diag( "SKIP [$basename]: " . SKIP->{$basename} ), next FILE ) if SKIP->{$basename};
	
	subtest $basename => sub {
		my $test_data = decode_json( $file->slurp );
		push @names, $basename;
		
		GROUP: for my $test_group ( $test_data->@* ) {
			
			my $key = sprintf( '%s/%s', $basename, $test_group->{description} );
			( diag( "SKIP [$key]: " . SKIP->{$key} ), next GROUP ) if SKIP->{$key};
			
			subtest $test_group->{description} => sub {
				
				my $type;
				{
					my ( $w, $e );
					$w = warnings {
						$e = dies {
							$type = schema_to_type( $test_group->{schema} );
						};
					};
					is( $e, undef, 'Compiling schema into type does not throw an exception' ) or diag( $e );
					is( $w, in_set( [], [ match qr/^Conflicting/ ] ), 'Only expected warnings when compiling schema into type' );
				}
				
				isa_ok( $type, 'Type::Tiny' );
				ok( $type->can_be_inlined, '... which can be inlined' );
				note( $type->display_name );
				
				TEST: for my $test ( $test_group->{tests}->@* ) {
					
					my $key = sprintf( '%s/%s/%s', $basename, $test_group->{description}, $test->{description} );
					( diag( "SKIP [$key]: " . SKIP->{$key} ), next TEST ) if SKIP->{$key};
					
					subtest $test->{description} => sub {
						
						my $expected = is_JTrue( $test->{valid} ) ? T() : F();
						
						my ( $w, $e, $valid ) = @_;
						$w = warnings {
							$e = dies {
								$valid = $type->check( $test->{data} );
							};
						};
						
						is( $e, undef, 'No exception thrown checking data' );
						is( $w, [], 'No warnings spewed checking data' );
						is( $valid, $expected, 'Check worked' )
							or do {
								diag "SCHEMA: @{[ encode_json($test_group->{schema}) ]}";
								diag "DATA  : @{[ encode_json($test->{data}) ]}";
								diag "EXPECT: @{[ $test->{valid} ? 'valid' : 'invalid' ]}";
								diag( $type->inline_check('$DATA') );
							};
					};
				}
			};
		}
	};
}

done_testing;

