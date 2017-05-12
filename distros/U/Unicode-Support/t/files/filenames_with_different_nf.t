use 5.014;
use utf8;
use warnings;
use strict;
use open IO => ':utf8';

require 't/lib/file_utils.pl';

=encoding utf8

=head1 NAME

filenames_with_different_nf - do you get the file if the filename normalizes

=head1 SYNOPISIS

	perl5.14 -CS filenames_with_different_nf.t

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

make_test_dir();

my %nfs = (
	NFC  => \&Unicode::Normalize::NFC,
	NFD  => \&Unicode::Normalize::NFD,
	NFKD => \&Unicode::Normalize::NFKD,
	NFKC => \&Unicode::Normalize::NFKC,
	);

my %failures;

foreach my $filename ( @names ) {
	my $code_numbers = get_code_numbers( $filename );
	my $label = "Input filename [$filename] with code numbers [$code_numbers]";

	subtest $label => sub {
		ok( ! -e $filename, "[$filename] does not exist before test" );
		ok( 0 == file_count(), 'There are no files before the test' );

		create_file( $filename );
	
		foreach my $nf_type ( keys %nfs ) {
			my $nf_file = $nfs{$nf_type}->($filename);
			my $code_numbers = get_code_numbers( $nf_file );
			my $rc1 = ok( -e $nf_file, "-e with $nf_type returns true ($code_numbers)" );
			
			my $rc2 = open( my $fh, '<', $nf_file );
			my $bang = $rc2 ? '' : "error => $!";
			ok( $rc2,
				"open() with $nf_type returns true ($code_numbers) $bang"
				);
			$failures{$nf_type}++ unless( $rc1 and $rc2 );
			}

		remove_files();
		done_testing();
		};
	}

foreach my $nf_type ( keys %nfs ) {
	$failures{$nf_type} ?
		fail( "$nf_type does not always work" )
			:
		pass( "$nf_type seems to always work" );
	}

done_testing();
