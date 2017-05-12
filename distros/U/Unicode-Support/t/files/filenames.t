use 5.014;
use utf8;
use warnings;
use strict;
use open IO => ':utf8';

require 't/lib/file_utils.pl';

=encoding utf8

=head1 NAME

filenames - do you get the file if the filename normalizes

=head1 SYNOPISIS

	perl5.14 -CS filenames.t

=head1 DESCRIPTION

This tests what happens when you create a file, but then check for it with
a different normalization forms. If your file system messes with the string
you give it for a filename and something later changes the normalization of
that string, you might not be able to get back to the file.

The best practice is to always convert to the right normalization form before
you do anything with the filename and the system.

=head1 AUTHOR

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright 2011, brian d foy.

=head1 LICENSE

You can use this code under the same terms as Perl itself.

=cut

use Test::More;
use Unicode::Normalize;

foreach my $method ( qw(output failure_output) ) {
	binmode Test::More->builder->$method(), ':encoding(UTF-8)';
	}

my @names = qw( é ü å π ﬀ Ⅷ );

my %nf_types = (
	NFC  => [ map { NFC($_)  } @names ],
	NFD  => [ map { NFD($_)  } @names ],
	NFKD => [ map { NFKD($_) } @names ],
	NFKC => [ map { NFKC($_) } @names ],
	);

my %checks = (
	NFC  => \&Unicode::Normalize::checkNFC,
	NFD  => \&Unicode::Normalize::checkNFD,
	NFKD => \&Unicode::Normalize::checkNFKD,
	NFKC => \&Unicode::Normalize::checkNFKC,
	);

make_test_dir();

foreach my $nf_type ( keys %nf_types ) {
	my $check = "check$nf_type";
	
	subtest "Testing $nf_type" => sub {	
		foreach my $filename ( @{ $nf_types{$nf_type} } ) {
			my $code_numbers = get_code_numbers( $filename );
			my $label = "Tested $nf_type with filename [$filename] ($code_numbers)";
	
			subtest $label => sub {
				diag "Testing [$filename]";
				ok( ! -e $filename, "[$filename] does not exist before test" );
				ok( 0 == file_count(), 'There are no files before the test' );
		
				create_file( $filename );
			
				ok( -e $filename, "[$filename] exists after opening" );
		
				my @files = files();
				
				ok( $checks{$nf_type}->($files[0]), 
					"Filename comes back as the same NF type" );
				ok( 1 == file_count(), 'There is exactly one file' );
	
				remove_files();
				done_testing();
				};
			};
		}
	}

done_testing();
