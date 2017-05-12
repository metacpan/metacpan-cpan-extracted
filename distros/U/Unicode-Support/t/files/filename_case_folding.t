use 5.014;
use utf8;
use strict;
use warnings;
use open IO => ':utf8';

use Test::More;
foreach my $method ( qw(output failure_output) ) {
	binmode Test::More->builder->$method(), ':encoding(UTF-8)';
	}

use charnames qw( :full );

require 't/lib/file_utils.pl';

make_test_dir();

my @tests = (
	# file1    file2   message
	[    'post', uc('post'), 'Latin: simple test' ],
	[    'post', 'post' =~ s/s/\N{LATIN SMALL LETTER LONG S}/r, 'Latin: test with LATIN SMALL LETTER LONG S' ],
	[ 'ΣΤΙΓΜΑΣ', 'στιγμασ', 'Greek: check the ending sigma σ with final Σ' ],
	[ 'ΣΤΙΓΜΑΣ', 'στιγμας', 'Greek: check the final sigma ς with final Σ'  ],
	[ 'στιγμασ', 'στιγμας', 'Greek: check the ending sigma σ with final ς'  ],
	);


foreach my $tuple ( @tests ) {
	my( $first, $second, $label ) = @$tuple;

	subtest $label => sub {
		remove_files();
		is( file_count(), 0, 'There are no files at the start' );

		my $casefold_message = "$first and $second are casefolds of each other";
		( $first =~ /\A$second\z/i &&  $second =~ /\A$first\z/i ) 
				?
			pass( $casefold_message ) 
				: 
			fail(  $casefold_message )
			;
	
		my $message = "$first testing $second";
		
		if( open my $fh1, '>:utf8', $first) {
			pass( "Opened $first" );
			print $fh1 $message;
			close $fh1;

			if( open my $fh2, '<:utf8', $second ) {
				my $data = do { local $/; <$fh2> };
				is( $data, $message, "Read the same message in $second" );
				}
			else {
				fail( "Could not open $second: $!" );
				}
			}
		else {
			fail( "Could not open first file, $first" );
			}
	
		done_testing();
		};
	}

done_testing();
