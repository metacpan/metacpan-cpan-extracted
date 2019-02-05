package # hide from CPAN indexer
		bkpscenario;
use strict;
use warnings;
use Carp;
use File::Path qw( make_path remove_tree );
use File::Spec;
use Test::More;
use Win32;

sub check_robocopy_version{
	my $verbose = shift;
	if ( $verbose ){
		note "Admin priviledge: ",
		 Win32::IsAdminUser() ? 'Administrator' : 'NO';
	}
	my $system32 = File::Spec->catdir( $ENV{windir}, 'System32' );
	my $systemwow64 = File::Spec->catdir( $ENV{windir}, 'SysWOW64' );
	my $robo64 = File::Spec->catfile( $system32, 'robocopy.exe' );
	my $robo32 = File::Spec->catfile( $systemwow64, 'robocopy.exe' );
	my %ret;
	foreach my $prog ( $robo32, $robo64 ){
		if ( -f $prog ){ 
			my ($first,$second,$third,$fourth) = Win32::GetFileVersion( $prog );
			$ret{$prog} = join '.',$first,$second,$third,$fourth;
	
			# check bugged version XP026 5.1.2600.26 
			# see https://ss64.com/nt/robocopy.html 
			# Version XP026 returns a success errorlevel even when it fails.
			#( from wikipedia ) 
			# 1.71	4.0.1.71	1997	Windows NT Resource Kit	
			# 1.95	4.0.1.95	1999	Windows 2000 Resource Kit	
			# 1.96	4.0.1.96	1999	Windows 2000 Resource Kit
			# XP010	5.1.1.1010	2003	Windows 2003 Resource Kit	
			# XP026	5.1.2600.26	2005	Downloaded with Robocopy GUI v.3.1.2; /DCOPY:T option introduced	
			# XP027	5.1.10.1027	2008	Bundled with Windows Vista, Server 2008, Windows 7, Server 2008r2
			# 6.1	6.1.7601	2009	KB2639043
			# 6.2	6.2.9200	2012	Bundled with Windows 8
			# 6.3	6.3.9600	2013	Bundled with Windows 8.1
			# 10.0	10.0.10240.16384	2015	Bundled with Windows 10
			# 10.0.16	10.0.16299.15	2017	Bundled with Windows 10 1709
			# 10.0.17	10.0.17763.1	2018	Bundled with Windows 10 1809
			if ( $verbose ){
				note "BUGGED VERSION at [$prog] ( XP026	5.1.2600.26 )" 
					if $ret{$prog} eq '5.1.2600.26';
				note "ANCIENT VERSION of robocopy.exe (pre 1997)"
					unless defined $ret{$prog};
				note "PROBABLY GOOD VERSION at [$prog] [$ret{$prog}]"
					if $ret{$prog} =~ /^5\.1\.10\./;
				note "RECENT VERSION at [$prog] [$ret{$prog}]"
					if $ret{$prog} =~ /^6|^10/;				
			}
		}
	
	}
	return \%ret;
}

sub create_dirs{
	my $base = shift // 'test_backup';
	# better a different name to avoid collision if multiple perls
	# try to test my module. 
	$base = $base.'-'.int(rand(1000)).int(rand(1000)).int(rand(1000));
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
