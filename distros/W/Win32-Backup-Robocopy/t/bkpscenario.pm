package # hide from CPAN indexer
		bkpscenario;
use strict;
use warnings;
use Carp;
use File::Path qw( make_path remove_tree );
use File::Spec;

sub create_dirs{
	my $base = shift // 'test_backup';
	my $tbasedir = File::Spec->catdir(File::Spec->tmpdir(),$base);
	my $tsrc = File::Spec->catdir( $tbasedir,'src');
	my $tdst = File::Spec->catdir( $tbasedir,'dst');
	foreach  my $dir ($tbasedir,$tsrc,$tdst){
			unless (-d $dir){ make_path( $dir ) }
			carp ( "unable to create temporary folder: [$dir]!" ) unless -d $dir;
			return undef unless -d $dir;
	}
	return ($tbasedir,$tsrc,$tdst);
}
sub open_file{
	my $tsrc = shift;
	my $filename = shift;
	my $file1 = File::Spec->catfile($tsrc, $filename);
	open my $tfh1, '>>', $file1 or croak "unable to write $file1 in $tsrc!";
	return $tfh1;
}

sub update_file{
	my $fh = shift;
	my $part = shift;
	my @parts = (
		# part 0
		"\t\tA ZACINTO\n\n".
		"Né più mai toccherò le sacre sponde\n".
		"  ove il mio corpo fanciulletto giacque,\n".
		"  Zacinto mia, che te specchi nell'onde\n".
		"  del greco mar da cui vergine nacque"
		,
		# part 1
		"\nVenere, e fea quelle isole feconde\n".
		"  col suo primo sorriso, onde non tacque\n".
		"  le tue limpide nubi e le tue fronde\n".
		"  l'inclito verso di colui che l'acque"
		,
		# part 2
		"\nCantò fatali, ed il diverso esiglio\n".
		"  per cui bello di fama e di sventura\n".
		"  baciò la sua petrosa Itaca Ulisse"
		,
		# part 3
		"\n\nTu non altro che il canto avrai del figlio,\n".
		"  o materna mia terra; a noi prescrisse\n".
		"  il fato illacrimata sepoltura.\n"
	);
	print $fh $parts[ $part ];
	close $fh or croak "Unable to close file!";
}

sub check_last_line{
	my $folder = shift;
	my $file = shift;
	my $line = shift;
	open my $fh,'<', File::Spec->catfile($folder, $file) 
		or croak "impossible to open $file in $folder!";
	my $last_line;
	my $ret;
	while(<$fh>){ $last_line = $_}
	close $fh or croak "unable to close file!";
	if ( $last_line eq $line ){
		$ret = 1;
	}
	return $ret;
}

sub clean_all{
	my $dir = shift;
	remove_tree $dir or croak "impossible to remove directory [$dir]!";
}
1;
