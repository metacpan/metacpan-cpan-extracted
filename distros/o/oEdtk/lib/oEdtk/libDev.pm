package oEdtk::libDev;

use strict;

#[JW for editor]:mode=perl:tabSize=8:indentSize=2:noTabs=true:indentOnEnter=true:
#

BEGIN {
	use oEdtk::logger 2.1109;
	use oEdtk::Main 0.42;
	use oEdtk::trackEdtk qw (ini_Edtk_Conf conf_To_Env env_Var_Completion);
	use Config::IniFiles;

	# use File::Copy; 	# to be provided to run dev in the prod context
	use File::Basename;
	use Date::Calc qw(Gmtime Today Compress);

	require oEdtk::tuiEdtk;

	use Exporter;
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %hListeId);    # %EXPORT_TAGS);
	use warnings;

	$VERSION = 0.316;
	@ISA     = qw(Exporter);
	@EXPORT  = qw(
		$NOK
		run_Edtk_dev
		IdUniqueSur7
		lastLong
		lastCourt
		delSp
	);

	@EXPORT_OK = qw(
		check_EDTK_DIR 	wait_Enter
		tree_Directory_Completion
		clean_full_dir		file_list
		prep_Edtk_Data
		)

	#					catSp
}

our $NOK = -1;

#
# CODE - DOC AT THE END
#

# limit the export of these functions (export OK)

sub check_EDTK_DIR () {

	# check the Edtk environment,
	# in particular the existence of the EDTK_DIR directories declared in the environment
	while ( ( my $cle, my $valeur ) = each(%ENV) ) {
		if ( $cle =~ /EDTK\_DIR/ ) {

			#print "$cle => $valeur\n";
			env_Var_Completion($valeur);
			tree_Directory_Completion($valeur);
		}
	}
	1;
}

sub tree_Directory_Completion {

	# complete, if needed, the whole tree of the path passed as a parameter
	# by creating the directories of the path passed as a parameter
	my $tree = shift;

	#print $tree."\n";

	my @listDir = split( /[\/\\]/, $tree );
	$tree = "";
	if ( -e "$listDir[0]/$listDir[1]" ) {
		for ( my $i = 0 ; $i < ( scalar @listDir ) ; $i++ ) {
			$tree .= $listDir[$i] . "/";

			#print "\t $i = $listDir[$i]\n";
			if ( -e $tree ) {
			}
			elsif ( -d $tree ) {
			}
			else {
				&logger( 6, "INFO: -> mkdir, create $tree\n" );
				eval { mkdir $tree; };
				die "ERROR: mkdir $tree  $@" if $@;
			}
		}
	}
	1;
}

sub run_Edtk_dev() {
	import oEdtk::tuiEdtk;

	my $iniEdtk = ini_Edtk_Conf;
	conf_To_Env( $iniEdtk, 'DEFAULT' );
	conf_To_Env( $iniEdtk, 'ENVDESC' );

	#	$ENV{EDTK_FTYP_DFLT} ||=$ENV{EDTK_FTYP_HOMOL};

	if ( $ENV{EDTK_DIR_BASE} eq "" ) {
		not_Configured();
		exit $NOK;
	}
	&check_EDTK_DIR;

	start_Screen();

	my $styleApp = $ENV{EDTK_DIR_SCRIPT} . "/" . $ENV{EDTK_PRGNAME};
	env_Var_Completion($styleApp);
	env_Var_Completion( $ENV{EDTK_DIR_APPTMP} );
	warn "INFO: " . oe_now_time() . " -START- \n";

	my $doclean = 1;
	{
		# LaTeX case
		$doclean = 0;
		$ENV{EDTK_DOC_OUTPUT} = "$ENV{EDTK_FDATAOUT}.$ENV{EDTK_EXT_WORK}";

# xxxxxxxx check, but we no longer need it now that it works (no need to check the intermediate files)
#		$ENV{EDTK_EXT_DEFAULT}=$ENV{EDTK_EXT_WORK};

		chdir( $ENV{EDTK_DIR_APPTMP} )
			or die "ERROR: Cannot change current directory: $!\n";
		my $ctrl = &prep_Edtk_Data( $ENV{EDTK_FDATAIN} . "." . $ENV{EDTK_EXT_DATA} )
			;    #, $ENV{EDTK_DOC_OUTPUT});
		warn "INFO: " . oe_now_time() . " -END Extract- \n";

		if ( $ctrl eq $NOK ) {
			warn "ERROR: return $? in prep_Edtk_Data\n";
			&wait_Enter();
			exit $NOK;
		}
		else {
			#warn "INFO: data extraction seem good\n";
			#$ENV{EDTK_DOC_OUTPUT} =$ctrl;
		}
	}

	warn "INFO: " . oe_now_time() . " -END- \n";

	# if everything ran correctly, empty the tmp dir
	# $| = 1; # autoflush
	if ($doclean) {
		warn "INFO: clean temp\n";
		clean_full_dir( $ENV{EDTK_DIR_APPTMP} );
	}

	stop_Screen();
	1;
}

sub prep_Edtk_Data {

	# trigger the data extraction process
	# in the context of the automated run run_Edtk_dev
	my $command = "$ENV{EDTK_DIR_APP}/$ENV{EDTK_PRGNAME}/$ENV{EDTK_PRGNAME}.$ENV{EDTK_EXT_PERL}";
	my $arg1    = shift;
	my $arg2    = shift || "";
	my $option  = shift || "";

	env_Var_Completion($arg2);
	warn "INFO: $command $arg1 $arg2\n";
	env_Var_Completion($command);
	env_Var_Completion($arg1);
	env_Var_Completion($option);

	eval {
		#system($command, $arg1, $arg2, $option);
		system( $command, $arg1, $option );
	};

	if ($@) {
		warn "INFO: ERROR -> $@\n";
		warn "INFO: ERROR $command $arg1 $arg2 return $? \n";

		return $NOK;
	}

	1;
}

sub wait_Enter() {
	print "\nPause, press <enter> to continue...\n";
	until (<STDIN>) {
	}
	1;
}

sub delSp(\$) {    ## no critic (ProhibitSubroutinePrototypes)

	#remove spaces
	# the parameter is an implicit reference, example: delSp($chaine)
	# returns the number of removed characters
	my $rChaine = shift;
	return ${$rChaine} =~ s/\s//go;
}

sub IdUniqueSur6 () {    # deprecated function
						 #format an id to 6 alphanumeric characters
						 # receives as a parameter the reference to an identifier
						 # duplicate handling internal to the function run
	my $rId = shift;
	my %hListeId;
	my $cpt = 0;
	${$rId} = sprintf( "%-6.6s", ${$rId} );
	${$rId} =~ s/\s/x/g;

	while ( exists( $hListeId{ ${$rId} } ) ) {
		${$rId} = sprintf( "%-4.4s%0.2d", ${$rId}, $cpt++ );
	}
	$hListeId{ ${$rId} } = 1;
	1;
}

{
	my $appelIUS7 = 0;    # constant variable local to the function

	sub IdUniqueSur7 () {

# define a unique identifier over 7 characters
# the first 6 characters of the passed key are extracted
# if the id is already known, take the first 4 and append a 3-digit counter (matches the call sequence)
# if it is still not unique, take the first 3 characters and pad the 3-digit counter with a character
# receives: - a reference to a key
#          - optional: a reference to a counter value (3 digits)

		my ( $refId, $rInit ) = @_;
		if ($rInit) { $appelIUS7 = ${$rInit} }
		else        { $appelIUS7++ }

		${$refId} = sprintf( "%-7.7s", ${$refId} );
		${$refId} =~ s/\s/x/g;
		if ( exists( $hListeId{ ${$refId} } ) ) {
			${$refId} = sprintf( "%-4.4s%0.3d", ${$refId}, $appelIUS7 );

			my $cpt = 97;    # for the character "a"
			while ( exists( $hListeId{ ${$refId} } ) ) {
				${$refId} = sprintf( "%-3.3s%0.3d%1.1s", ${$refId}, $appelIUS7, chr( $cpt++ ) );
				die &logger( $NOK, "cannot create a unique key" ) if ( $cpt >= 123 );

# use Log::Log4perl;
# Log::Log4perl->init("log.conf"); => read log.conf
# $logger = Log::Log4perl->get_logger("");
# $logger->logdie("cannot create a unique key") if ($cpt >= 123);
# $logger->trace("...");  # Log a trace message
# $logger->debug("...");  # Log a debug message
# $logger->info("...");   # Log a info message
# $logger->warn("...");   # Log a warn message	/ $logger->error_warn("..."); (includes the call to warn())
# $logger->error("...");  # Log a error message	/ $logger->logdie ("..."); (includes the call to die())
# $logger->fatal("...");  # Log a fatal message
			}
		}
		$hListeId{ ${$refId} } = 1;
		return 1;
	}
}

sub lastLong {

	# select the most significant alpha token of the string passed by reference
	# example call: $mot=&lastLong ($chaine);
	# the separator characters are spaces, _ or -

	my $chaine = shift;
	$chaine =~ s/-/ /g;
	$chaine =~ s/_/ /g;
	oe_trimp_space($chaine);

	# If PATTERN contains parentheses (and therefore subpatterns), an extra element is created
	# in the result array for each string matched by the subpattern.
	#    split(/([,-])/, "1-10,20", 3);
	# produces the list of values
	#    (1, '-', 10, ',', 20)
	# http://perl.enstimac.fr/DocFr/perlfunc.html#item_split
	my @mots = split( " ", $chaine );
	my ( $mot, $motLong );
	my $taille = 0;

	while ( $mot = shift(@mots) ) {
		if ( length($mot) >= $taille ) {
			$taille  = length($mot);
			$motLong = $mot;
		}
	}

	return $motLong;
}

sub lastCourt {

	# select the shortest alpha token of the string passed by reference
	# example call: $mot=&lastCourt ($chaine);
	my $chaine = shift;
	$chaine =~ s/-/ /g;
	$chaine =~ s/_/ /g;
	oe_trimp_space($chaine);
	my @mots = split( " ", $chaine );
	my ( $mot, $motCourt );
	my $taille = 1000;

	while ( $mot = shift(@mots) ) {
		if ( length($mot) <= $taille ) {
			$taille   = length($mot);
			$motCourt = $mot;
		}
	}

	#print "$chaine $taille $motCourt\n";
	return $motCourt;
}

sub clean_full_dir {

	# unlink alone does not work on windows with wildcards ???
	# this function cleans the directory passed as a parameter
	# and the subdirectories
	my ( $membre, $option, $key, @listRep );
	my $DIR;
	$membre = shift;
	$option = shift;
	$option ||= "";

	# build the search pattern for the regular expression
	my $suppr_motif;
	$suppr_motif = ".*";

	# print "del. -> $suppr_motif -> $membre\n";

	# handle directory separators
	# the standard perl separator (on *nix / windows ...) -> /
	$membre .= "/";

	# the separator supplied on Dos is converted \ -> /
	$membre =~ s/\\+/\//g;

	# remove repeated /+ -> /
	$membre =~ s/\/+/\//g;

	unshift( @listRep, $membre );

	$key = pop @listRep;
ITEMS: for ( ; $key ; ) {

		# since listRep is interactive foreach ignores values added to listRep
		# print "path= <$key> < \@listRep=>@listRep<\n";

		eval { opendir( $DIR, $key ); };
		if ($?) {
			warn "INFO: WARNING opendir(DIR, $key) return $?\n";
			next ITEMS;
		}

		$membre = readdir($DIR);
		for ( ; $membre ; ) {
			if ( $membre ne "." && $membre ne ".." ) {

				# if the member is a directory
				if ( -d $key . $membre ) {

					# print "$key$membre \t (directory)\n";
					push( @listRep, "$key$membre/" );

				}
				else {
					my $file = $key . $membre;

					# print "$file\n";
					if ( $file =~ m{$suppr_motif} ) {
						if ( $option ne "--dry-run" ) {
							warn "INFO: deleting $file\n" if ( $option eq "--verbose" );
							unlink($file);
						}
						else {
							warn "INFO: --dry-run : $file\n";
						}
					}
				}    #end of if
			}    #end of if
			$membre = readdir($DIR);
		}    #end of for

		closedir($DIR);
		$key = pop @listRep;
	}    #end of for

	#close OUT;

	1;
}

sub file_list {
	my ( $key, @listRep, @listFile );
	my $DIR;
	my $membre = shift;
	my $motif  = shift;
	my $opt    = shift;
	$opt ||= "";

	# handle directory separators
	# the standard perl separator (on *nix / windows ...) -> /
	$membre .= "/";

	# the separator supplied on Dos is converted \ -> /
	$membre =~ s/\\+/\//g;

	# remove repeated /+ -> /
	$membre =~ s/\/+/\//g;

	unshift( @listRep, $membre );

	$key = pop @listRep;
ITEMS: for ( ; $key ; ) {

		# since listRep is interactive foreach ignores values added to listRep
		# print "path= <$key> < \@listRep=>@listRep<\n";

		eval { opendir( $DIR, $key ); };
		if ($?) {
			warn "INFO: WARNING opendir(DIR, $key) return $?\n";
			next ITEMS;
		}

		$membre = readdir($DIR);
		for ( ; $membre ; ) {
			if ( $membre ne "." && $membre ne ".." ) {

				# if the member is a directory
				if ( -d $key . $membre ) {

					# print "$key$membre \t (directory)\n";
					push( @listRep, "$key$membre/" );

				}
				else {
					my $file = $key . $membre;

					# print "$file\n";
					if ( $file =~ m{$motif} ) {
						push( @listFile, $file );
					}
				}    #end of if
			}    #end of if
			$membre = readdir($DIR);
		}    #end of for

		closedir($DIR);
		$key = pop @listRep;
	}    #end of for

	#close OUT;

	return @listFile;
}

END {
}
1;
