package oEdtk::EDMS;

# Electronic Document Management (GED in French).
# Merged at S54 from the fork's ECM-oriented rewrite (36 index columns, the
# Alfresco header, _log / my_system) plus the mainline EDMS_package and the
# edidx helpers (which the fork exported but never defined).
use strict;
use warnings;
use Carp qw(carp croak);

use Exporter;
our $VERSION   = 2.1126;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
	EDMS_edidx_build
	EDMS_edidx_write
	EDMS_idldoc_seqpg
	EDMS_idx_create_csv
	EDMS_import
	EDMS_package
	EDMS_prepare
	EDMS_process
	EDMS_process_zip
);

use Archive::Zip qw(:ERROR_CODES);
use Cwd;
use File::Basename;
use File::Copy;
use IPC::Run3 qw(run3);
use Net::FTP;
use oEdtk::Main;
use oEdtk::Config qw(config_read);
use POSIX         qw(strftime);
use Text::CSV;
use Time::HiRes qw(gettimeofday);
use XML::Writer;

# use PDF;		# add to the prerequisites

# The per-page .idx1 read by EDMS_idx_process (and posted by
# oEUser::DisseminationPlan) carries these 36 columns, in this exact order: the
# ECM layout of the fork. oEUser::DisseminationPlan's INDEX_* constants pin the
# same positions (ID_LOT=1, PAGE=2, DOC=3, NOM_PRENOM=7, DATE_EDITION=9,
# CONTRAT_INDIV=13, TYPE_DOC=31).
my @INDEX_ECM_COLS = (
	'ED_REFIDDOC',    # 1  id in the document repository
	'ED_IDLDOC',      # 2  unique document id within the page-layout batch
	'ED_IDSEQPG',     # 3  page sequence number within the page-layout batch
	'ED_SEQDOC',      # 4  document sequence number within the batch
	'ED_CPDEST',      # 5  recipient postal code
	'ED_VILLDEST',    # 6  recipient city
	'ED_IDDEST',      # 7  recipient id in the management system
	'ED_NOMDEST',     # 8  recipient name
	'ED_IDEMET',      # 9  sender id
	'ED_DTEDTION',    # 10 edition date printed on the document
	'ED_TYPPROD',     # 11 production type associated with the batch
	'ED_PORTADR',     # 12 flag: document carries an address
	'ED_ADRLN1',      # 13 address line 1
	'ED_CLEGED1',     # 14 archiving system key
	'ED_ADRLN2',      # 15 address line 2
	'ED_CLEGED2',     # 16 archiving system key
	'ED_ADRLN3',      # 17 address line 3
	'ED_CLEGED3',     # 18 archiving system key
	'ED_ADRLN4',      # 19 address line 4
	'ED_CLEGED4',     # 20 archiving system key
	'ED_ADRLN5',      # 21 address line 5
	'ED_CORP',        # 22 issuing entity of the page
	'ED_DOCLIB',      # 23 merge library associated with the page
	'ED_REFIMP',      # 24 pre-printed, printed or insert reference
	'ED_ADRLN6',      # 25 address line 6
	'ED_SOURCE',      # 26 index source or ed_corp entity
	'ED_OWNER',       # 27 document owner
	'ED_HOST',        # 28 hostname this entry came from
	'ED_IDIDX',       # 29 index id
	'ED_CATDOC',      # 30 document category
	'ED_CODRUPT',     # 31 burst forcing code
	'ED_TYPDOC',      # 32 document type (ECM)
	'ED_IDCOLL',      # 33 collection id (ECM)
	'ED_IDMNT',       # 34 archive id from the extension (ECM)
	'ED_CLEGED5',     # 35 extra archiving key (ECM)
	'ED_IDPMSIR',     # 36 legal-entity / SIRET id (ECM)
);

# Timestamp of the previous _log call, so it can print the elapsed time.
my $LOG_SEC0  = 0;
my $LOG_USEC0 = 0;

# Log one message on STDERR, with a timestamp, the caller location and (from the
# second call on) the elapsed time. Kept file-scoped rather than 'state' so the
# module stays free of feature pragmas.
sub _log {
	my ($str) = @_;
	$str //= q{};
	$str =~ s{^\s*}{ }sx;
	my ( $package, $filename, $line ) = caller;
	my ( $seconds, $microseconds ) = gettimeofday;

	my $sec1  = $seconds - $LOG_SEC0;
	my $usec1 = $microseconds - $LOG_USEC0;
	if ( $usec1 < 0 ) {
		$sec1--;
		$usec1 += 1_000_000;
	}
	if ($LOG_SEC0) {
		print STDERR sprintf( '-- elapsed: %d.%06d sec', $sec1, $usec1 ), "\n";
	}
	( $LOG_SEC0, $LOG_USEC0 ) = ( $seconds, $microseconds );

	my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($seconds);
	my $timestamp = sprintf '%04d-%02d-%02d %02d:%02d:%02d.%06d', 1900 + $year, 1 + $mon,
		$mday, $hour, $min, $sec, $microseconds;
	print STDERR sprintf( "\n%s %s %s +%d%s", $timestamp, $package, $filename, $line, $str ), "\n";
	return 0;
}

# Run a command, capture its streams and return its exit value.
sub my_system {
	my ($cmd) = @_;
	_log("Running command:\n$cmd");
	my ( $out, $err );
	run3 $cmd, undef, \$out, \$err;
	my $ret = $?;
	my ( $exit_value, $signal ) = ( $ret >> 8, $ret & 127 );
	_log("...done. exit_value=$exit_value signal=$signal");
	_log("...stdout:\n[[$out]]");
	_log("...stderr:\n[[$err]]");
	return $exit_value;
}

# Utility function to construct filenames.
sub EDMS_idldoc_seqpg {
	my ( $idldoc, $page ) = @_;

	return sprintf( "${idldoc}_%07d", $page );
}

# Package a DOC along with its index in a zip archive for later processing.
sub EDMS_prepare {
	my ( $app, $idldoc, $doc_path, $idx_path ) = @_;

	if ( !-e $doc_path ) {
		carp "$doc_path don't exist";
		exit 0;
	}
	if ( !-e $idx_path ) {
		carp "$idx_path don't exist";
		exit 0;
	}

	my $cfg = config_read('EDOCMNGR');
	my $zip = Archive::Zip->new();
	$zip->addFile( $doc_path, "$app.$idldoc.pdf" );
	$zip->addFile( $idx_path, basename($idx_path) );

	my $zipfile = "$cfg->{'EDTK_DIR_EDOCMNGR'}/$app.$idldoc.out.zip";
	die "ERROR: Could not create zip achive \"$zipfile\"\n"
		unless $zip->writeToFileNamed($zipfile) == AZ_OK;
	print "$zipfile\n";

	return 1;
}

# Package some documents along with one index in a zip archive.
sub EDMS_package {
	my $app      = shift;
	my $idldoc   = shift;
	my @elements = @_;

	my $cfg = config_read('EDOCMNGR');
	my $zip = Archive::Zip->new();

	foreach (@elements) {
		$zip->addFile( $_, basename($_) );
	}

	my $zipfile = "$cfg->{'EDTK_DIR_EDOCMNGR'}/$app.$idldoc.out.zip";
	die "ERROR: Could not create zip achive \"$zipfile\"\n"
		unless $zip->writeToFileNamed($zipfile) == AZ_OK;
	print "$zipfile\n";

	return 1;
}

sub EDMS_process_zip {
	my ( $zipfile, $outdir ) = @_;

	my $zipname = basename($zipfile);
	if ( $zipname !~ /^([^.]+)\.(.+)\.out\.zip$/ ) {
		die "ERROR: Unexpected zip filename: $zipname\n";
	}
	my ( $app, $idldoc ) = ( $1, $2 );

	my $zip = Archive::Zip->new();
	if ( $zip->read($zipfile) != AZ_OK ) {
		die "ERROR: Could not read zip archive \"$zipfile\"\n";
	}

	my @files        = $zip->members();
	my ($idx_member) = $zip->membersMatching('\.idx1$');
	my ($doc_member) = $zip->membersMatching('\.pdf$');
	if ( !defined($doc_member) ) {
		($doc_member) = $zip->membersMatching('\.xls$');
	}
	if ( !defined($doc_member) ) {
		($doc_member) = $zip->membersMatching('\.doc$');
	}
	if ( !defined($doc_member) || !defined($idx_member) ) {
		die "ERROR: Could not find document(s) or index file in archive\n";
	}
	my $doc_name = $doc_member->fileName();
	my $idx_name = $idx_member->fileName();
	my $doc_path = $doc_name;
	my $idx_path = $idx_name;
	if ( defined($outdir) ) {
		$doc_path = "$outdir/$doc_path";
		$idx_path = "$outdir/$idx_path";
	}
	if ( $zip->extractMember( $doc_member, $doc_path ) != AZ_OK ) {
		die "ERROR: Could not extract \"$doc_name\" from archive\n";
	}
	if ( $zip->extractMember( $idx_member, $idx_path ) != AZ_OK ) {
		die "ERROR: Could not extract \"$idx_name\" from archive\n";
	}

	return EDMS_process( $app, $idldoc, $doc_name, $idx_name, $outdir );
}

# Process document(s) with its index in a way suitable for the edms software.
sub EDMS_process {
	my ( $app, $idldoc, $doc, $index, $outdir ) = @_;

	_log("EDMS_process: app=$app idldoc=$idldoc doc=$doc index=$index outdir=$outdir");

	# Replace - and . with _ because Docubase cannot import names with dots.
	$idldoc =~ s/[-\.]/_/g;
	$app    =~ s/[-\.]/_/g;

	my $cfg      = config_read('EDOCMNGR');
	my $format   = $cfg->{'EDMS_IDX_FORMAT'};
	my @edmscols = split( /,/, $cfg->{'EDMS_INDEX_COLS'} );

	my $oldcwd;
	if ( defined($outdir) ) {
		$oldcwd = getcwd();
		chdir($outdir)
			or die "ERROR: Cannot change current directory to \"$outdir\": $!\n";
	}
	my @outfiles = ();

	if ( $doc =~ /pdf$/i ) {
		my $rv =
			my_system( $cfg->{'EDMS_BIN_PDFTK'} . " $doc burst output ${app}_${idldoc}_%07d.pdf " );
		if ( $rv != 0 ) {
			die "ERROR: Could not burst PDF file $doc!\n";
		}
	}
	else {
		my $cible = _docubase_file_name($doc);
		move( $doc, $cible ) or die "ERROR: failed to move $cible ($doc)\n";
		push( @outfiles, $cible );
	}

	if ( $format eq 'DOCUBASE' ) {
		@outfiles = EDMS_idx_create_csv( $cfg, $index, $app, $idldoc, \@edmscols );
	}
	elsif ( $format eq 'SCOPMASTER' ) {
		@outfiles = EDMS_idx_create_xml( $cfg, $index, $app, $idldoc, \@edmscols );
	}
	else {
		die "ERROR: Unexpected index format: $format\n";
	}

	if ( $cfg->{'EDTK_TYPE_ENV'} ne 'Test' ) {
		unlink($doc) if ( $doc =~ /pdf$/i );
		unlink('doc_data.txt');    # pdftk creates this one.
	}

	if ( defined($outdir) ) {

		# Restore the original working directory.
		chdir($oldcwd);
	}

	return @outfiles;
}

# Transfer the PDF files and the index to the EDMS application. On success it
# returns a true value: both callers guard with "EDMS_import(...) or die"
# (oEdtk::Run), so a false success return would make that guard fatal.
sub EDMS_import {
	my ( $index, @docs ) = @_;

	my $cfg = config_read('EDOCMNGR');
	my $ftp = Net::FTP->new( $cfg->{'EDMS_FTP_HOST'}, Port => $cfg->{'EDMS_FTP_PORT'} )
		or die "ERROR: Cannot connect to $cfg->{'EDMS_FTP_HOST'}: $@\n";
	$ftp->login( $cfg->{'EDMS_FTP_USER'}, $cfg->{'EDMS_FTP_PASS'} )
		or die "ERROR: Cannot login: " . $ftp->message() . "\n";
	$ftp->binary()
		or die "ERROR: Cannot set binary mode: " . $ftp->message() . "\n";
	$ftp->cwd( $cfg->{'EDMS_FTP_DIR_DOCS'} )
		or die "ERROR: Cannot change working directory: " . $ftp->message() . "\n";

	# The index must be transferred last, otherwise the PDF files that have not
	# been transferred yet will not be processed.
	foreach my $doc (@docs) {
		$ftp->put($doc)
			or die "ERROR: Cannot upload DOC file: " . $ftp->message() . "\n";
	}
	$ftp->cwd()
		or die "ERROR: Cannot change working directory: " . $ftp->message() . "\n";
	$ftp->cwd( $cfg->{'EDMS_FTP_DIR_IDX'} )
		or die "ERROR: Cannot change working directory: " . $ftp->message() . "\n";
	$ftp->put($index)
		or die "ERROR: Cannot upload index file: " . $ftp->message() . "\n";
	$ftp->quit();

	return 1;
}

# Read the initial index file, and call the given function for each new
# document. Also concatenate PDF files if needed (multi-page documents).
sub EDMS_idx_process($$$$&) {    ## no critic (ProhibitSubroutinePrototypes)
	my ( $app, $idx, $idldoc, $keys, $sub ) = @_;

	_log("EDMS_idx_process: app=$app idx=$idx idldoc=$idldoc");

	open( my $fh, '<', $idx ) or die "ERROR: Cannot open \"$idx\": $!\n";
	my $csv = Text::CSV->new( { binary => 1, sep_char => ';' } );
	$csv->column_names(@INDEX_ECM_COLS);
	my $lastdoc = 0;
	my $firstpg = 0;
	my $numpgs  = 1;
	my %docvals = ();
	my $vals;

	while ( $vals = $csv->getline_hr($fh) ) {
		if ( $vals->{'ED_SEQDOC'} != $lastdoc ) {
			if ( $lastdoc != 0 ) {
				EDMS_merge_docs( $app, $idldoc, $firstpg, $numpgs );
				$sub->( \%docvals, $firstpg, $numpgs );
				undef(%docvals);
			}
			$lastdoc = $vals->{'ED_SEQDOC'};

			# Remember the values we are interested in for the edms.
			foreach (@$keys) {
				$docvals{$_} = $vals->{$_};
			}
			$docvals{'ED_DOCLIB'} = $vals->{'ED_DOCLIB'};
			$firstpg              = $vals->{'ED_IDSEQPG'};
			$numpgs               = 1;

		}
		else {

			# Remember the values we are interested in for the edms.
			foreach (@$keys) {
				$docvals{$_} = $vals->{$_} if $vals->{$_};
			}
			$docvals{'ED_DOCLIB'} = $vals->{'ED_DOCLIB'};
			$numpgs++;
		}
	}
	close($fh);

	# Handle the last document.
	if ( $lastdoc != 0 ) {
		EDMS_merge_docs( $app, $idldoc, $firstpg, $numpgs );
		$sub->( \%docvals, $firstpg, $numpgs );
	}
	return 0;
}

sub _docubase_file_name {
	my $filename = shift;

	$filename =~ s/(^.*)(\.\w{2,4}$)/$1/;
	my $ext = $2 || "";
	$filename =~ s/[-\.]/_/g;
	$filename .= $ext;

	return $filename;
}

# Prepend the Alfresco header line to the index CSV, when the site activates it
# (EDMS_ACTIVATE_HEADER_ALFRESCO = YES). Default behaviour: do not activate.
sub preprend_alfresco_header_if_needed {
	my ( $cfg, $fh, $csv ) = @_;

	if ( exists $cfg->{'EDMS_ACTIVATE_HEADER_ALFRESCO'}
		&& $cfg->{'EDMS_ACTIVATE_HEADER_ALFRESCO'} eq 'YES' )
	{
		my $_csv = Text::CSV->new( { sep_char => ';' } );
		if ( $_csv->parse( $cfg->{'EDMS_IDX_HEADER'} ) ) {
			$csv->print( $fh, [ $_csv->fields() ] );
		}
		else {
			croak join( "\n",
				'Cannot parse config value EDMS_IDX_HEADER as a CSV record:',
				$_csv->error_diag(),  '', 'Config value EDMS_IDX_HEADER is:',
				$_csv->error_input(), '' );
		}
	}
	return 0;
}

# Create an EDMS index file in CSV format (for the EDMS application).
sub EDMS_idx_create_csv {
	my ( $cfg, $idx, $app, $idldoc, $keys ) = @_;

	my $csv     = Text::CSV->new( { binary => 1, sep_char => ';', eol => "\n", quote_space => 0 } );
	my $edmsidx = "${app}_$idldoc.idx";
	open( my $fh, '>', $edmsidx ) or die "ERROR: Cannot create \"$edmsidx\": $!\n";

	preprend_alfresco_header_if_needed( $cfg, $fh, $csv );

	# Always return the index file as the first file in the list, see
	# EDMS_import() for why this is important.
	my @outfiles = ($edmsidx);
	EDMS_idx_process(
		$app, $idx, $idldoc, $keys,
		sub {
			my ( $vals, $firstpg, $numpgs ) = @_;
			my $iddoc = $vals->{'ED_IDLDOC'};
			delete( $vals->{'ED_IDLDOC'} );
			if ( $vals->{'ED_DOCLIB'} =~ /pdf$/i ) {
				$vals->{'EDMS_IDLDOC_SEQPG'} = EDMS_idldoc_seqpg( $iddoc, $firstpg );
				$vals->{'EDMS_FILENAME'} =
					"${app}_" . EDMS_idldoc_seqpg( $idldoc, $firstpg ) . ".pdf";
			}
			else {
				$vals->{'EDMS_FILENAME'} = _docubase_file_name( $vals->{'ED_DOCLIB'} );
			}

			# Dates need to be in a specific format.
			my $datefmt = $cfg->{'EDMS_DATE_FORMAT'};
			if ( $vals->{'ED_DTEDTION'} !~ /^(\d{4})(\d{2})(\d{2})$/ ) {
				die "ERROR: Unexpected date format for ED_DTEDTION: $vals->{'ED_DTEDTION'}\n";
			}
			my ( $year, $month, $day ) = ( $1, $2, $3 );
			$vals->{'EDMS_PROCESS_DT'} =
				strftime( $datefmt, 0, 0, 0, $day, $month - 1, $year - 1900 );

			# Owner id for group access in edms.
			if ( $vals->{'ED_IDEMET'} =~ /^\D{1}\d{3}/ ) {
				$vals->{'ED_OWNER'} = $vals->{'ED_IDEMET'};
			}
			else {
				$vals->{'ED_OWNER'} = $vals->{'ED_SOURCE'};
			}

			# Remove every ';' from the values (the fork's ECM constraint).
			foreach my $key (@$keys) {
				$vals->{$key} =~ s/;//g;
			}

			my @edmsvals = map { $vals->{$_} } @$keys;
			$csv->print( $fh, \@edmsvals );

			push( @outfiles, $vals->{'EDMS_FILENAME'} );
		}
	);
	close($fh);
	return @outfiles;
}

# Create edms indexes in XML format (one per PDF file).
sub EDMS_idx_create_xml {
	my ( $cfg, $idx, $app, $idldoc, $keys ) = @_;

	my @outfiles = ();
	EDMS_idx_process(
		$app, $idx, $idldoc, $keys,
		sub {
			my ( $vals, $firstpg, $numpgs ) = @_;

			my $docid = EDMS_idldoc_seqpg( $vals->{'ED_IDLDOC'}, $firstpg );
			delete( $vals->{'ED_IDLDOC'} );
			my $xmlfile = "$docid.edms.xml";
			$vals->{'ED_DOCLIB'} =~ /\.(\w{2,4})$/;
			my $ext = $1;

			open( my $fh, '>', $xmlfile ) or die "ERROR: Cannot create \"$xmlfile\": $!\n";
			my $xml = XML::Writer->new( OUTPUT => $fh, ENCODING => 'utf-8' );
			$xml->xmlDecl('utf-8');
			$xml->startTag('idxext');

			foreach my $pagenum ( 1 .. $numpgs ) {
				$xml->startTag( 'page', num => $pagenum );
				if ( $pagenum == 1 ) {
					while ( my ( $key, $val ) = each(%$vals) ) {
						$xml->emptyTag( 'index', key => $key, value => $val );
					}
				}
				$xml->endTag('page');
			}
			$xml->endTag('idxext');
			$xml->end();
			close($fh);

			push( @outfiles, $xmlfile );
			push( @outfiles, "${app}_$docid.$ext" );
		}
	);
	return @outfiles;
}

# Concatenate PDF documents if needed.
sub EDMS_merge_docs {
	my ( $app, $idldoc, $firstpg, $numpgs ) = @_;

	_log("EDMS_merge_docs: app=$app idldoc=$idldoc firstpg=$firstpg numpgs=$numpgs");
	my $cfg = config_read('EDOCMNGR');

	# A single-page document has nothing to concatenate.
	return unless $numpgs > 1;

	my $lastpg = $firstpg + $numpgs - 1;
	my @pages =
		map { "${app}_" . EDMS_idldoc_seqpg( $idldoc, $_ ) . ".pdf" } ( $firstpg .. $lastpg );
	my $output = "$pages[0].tmp";

	if ( defined $cfg->{'EDMS_BIN_GS'} && $cfg->{'EDMS_BIN_GS'} ne "" ) {

		# PDFs created with pdftk are too heavy, so change the operating mode.
		my $gs =
			my_system( $cfg->{'EDMS_BIN_GS'}
				. " -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=$output @pages " );
		if ( $gs != 0 ) {
			die "ERROR: Could not concatenate pages $firstpg to $lastpg!\n";
		}
	}
	else {
		my $rv =
			my_system(
			$cfg->{'EDMS_BIN_PDFTK'} . " " . join( ' ', @pages ) . " cat output $output" );
		if ( $rv != 0 ) {
			die "ERROR: Could not concatenate pages $firstpg to $lastpg!\n";
		}
	}

	# Remove the old files and rename the concatenated PDF after the first page.
	foreach (@pages) {
		unlink($_);
	}
	move( $output, $pages[0] );
	return;
}

# Build the ECM index keys of one document from the raw request parameters. The
# fork exported this sub but never defined it; the mainline body is kept here.
sub EDMS_edidx_build(\%) {    ## no critic (ProhibitSubroutinePrototypes)
	my ($refOpt) = @_;
	my $cfg = config_read('EDOCMNGR');

# required index keys 	: ED_REFIDDOC, ED_CORP, ED_SOURCE, ED_IDDEST, ED_NOMDEST, ED_IDEMET, ED_OWNER, ED_CORP
# optional keys		: ED_DTEDTION, ED_CLEGED1, ED_VILLDEST, ED_CLEGED2, ED_CLEGED3, ED_CLEGED4
# computed/(re)computed keys		: ED_DTEDTION, EDMS_IDLDOC_SEQPG, EDMS_FILENAME

	# REQUIRED KEYS
	if ( !defined $$refOpt{'ED_REFIDDOC'} or $$refOpt{'ED_REFIDDOC'} eq "" ) {
		die "ERROR: ED_REFIDDOC required.\n";
	}
	if ( !defined $$refOpt{'ED_SOURCE'} or $$refOpt{'ED_SOURCE'} eq "" ) {
		die "ERROR: ED_SOURCE required.\n";
	}
	if ( !defined $$refOpt{'ED_IDDEST'} or $$refOpt{'ED_IDDEST'} eq "" ) {
		die "ERROR: ED_IDDEST required.\n";
	}
	if ( !defined $$refOpt{'ED_NOMDEST'} or $$refOpt{'ED_NOMDEST'} eq "" ) {
		die "ERROR: ED_NOMDEST required.\n";
	}
	if ( !defined $$refOpt{'ED_IDEMET'} or $$refOpt{'ED_IDEMET'} eq "" ) {
		die "ERROR: ED_IDEMET required.\n";
	}
	if ( !defined $$refOpt{'ED_OWNER'} or $$refOpt{'ED_OWNER'} eq "" ) {
		die "ERROR: ED_OWNER required.\n";
	}
	if ( !defined $$refOpt{'ED_CORP'} or $$refOpt{'ED_CORP'} eq "" ) {
		die "ERROR: ED_CORP required.\n";
	}

	# COMPUTED KEYS
	my $FILE_EXT = $$refOpt{'ED_FILENAME'};
	$FILE_EXT =~ s/^(.*\.)(\w+)$/$2/;
	$$refOpt{'ED_FORMFLUX'} = uc($FILE_EXT);

	my ( $sec, $min, $hour, $day, $month, $year );
	if ( !defined $$refOpt{'ED_DTEDTION'} || $$refOpt{'ED_DTEDTION'} !~ /^(\d{4})(\d{2})(\d{2})$/ )
	{
		( $sec, $min, $hour, $day, $month, $year ) = localtime();
		$month++;
		$year += 1900;
	}
	else {
		( $year, $month, $day ) = ( $1, $2, $3 );
	}

	# DATES NEED TO BE IN A SPECIFIC FORMAT.
	my $datefmt = $cfg->{'EDMS_DATE_FORMAT'};
	$$refOpt{'ED_DTEDTION'} = strftime( $datefmt, 0, 0, 0, $day, $month - 1, $year - 1900 );
	$$refOpt{'ED_IDLDOC'}   = oEdtk::Main::oe_ID_LDOC();
	$$refOpt{'ED_IDSEQPG'}  = 1;
	$$refOpt{'ED_SEQDOC'}   = 1;
	$$refOpt{'EDMS_IDLDOC_SEQPG'} =
		EDMS_idldoc_seqpg( $$refOpt{'ED_IDLDOC'}, $$refOpt{'ED_IDSEQPG'} );
	$$refOpt{'EDMS_FILENAME'} = $$refOpt{'ED_REFIDDOC'} . "_" . $$refOpt{'EDMS_IDLDOC_SEQPG'};
	$$refOpt{'EDMS_FILENAME'} =~ s/[-\.\s]/_/g;
	$$refOpt{'EDMS_FILENAME'} = $$refOpt{'EDMS_FILENAME'} . "." . $FILE_EXT;
	$$refOpt{'ED_DOCLIB'}     = $$refOpt{'EDMS_FILENAME'};

	# OPTIONAL KEYS
	$$refOpt{'ED_VILLDEST'} |= "";
	$$refOpt{'ED_CLEGED1'}  |= "";
	$$refOpt{'ED_CLEGED2'}  |= "";
	$$refOpt{'ED_CLEGED3'}  |= "";
	$$refOpt{'ED_CLEGED4'}  |= "";
	return;
}

# Append one index line, in the EDMS_INDEX_COLS order, to the EDMS index file.
sub EDMS_edidx_write(\%) {    ## no critic (ProhibitSubroutinePrototypes)
	my ($refOpt)  = shift;
	my $cfg       = config_read('EDOCMNGR');
	my @edms_cols = split( /,/, $cfg->{'EDMS_INDEX_COLS'} );
	my $index     = $$refOpt{'ED_REFIDDOC'} . "_" . $$refOpt{'ED_IDLDOC'} . ".idx";

	open( my $fh, '>>', $index ) or die "ERROR: can't open $index : $!";
	my $csv = Text::CSV->new( { binary => 1, sep_char => ';', eol => "\n", quote_space => 0 } );

	my @fields;
	foreach my $key (@edms_cols) {
		push( @fields, $$refOpt{$key} );
	}

	$csv->print( $fh, \@fields );
	close($fh);
	return;
}

1;

=head1 NAME

oEdtk::EDMS - electronic document management output: index files and archive transfer

=head1 SYNOPSIS

    use oEdtk::EDMS qw(EDMS_process EDMS_import);

    my @files = EDMS_process($app, $idldoc, $doc, $index, $outdir);
    EDMS_import($index, @files) or die "transfer failed\n";

=head1 DESCRIPTION

Builds the index files that feed an electronic document management system and
transfers them to it. A document and its per-page index are packed into a zip
archive, then unpacked and processed: PDF pages are burst or concatenated with
the configured helpers, and the index is rewritten in the format the site
expects (C<DOCUBASE> CSV or C<SCOPMASTER> XML). C<EDMS_import> uploads the
result over FTP, the index last so that the documents are already in place.

=head1 FUNCTIONS

=head2 EDMS_edidx_build

    EDMS_edidx_build(\%options);

Fill the required ECM index keys of one document from the raw request
parameters. Dies when a required key is missing, and computes the derived keys
(the edition date, the document id, the page sequence and the file name).

=head2 EDMS_edidx_write

    EDMS_edidx_write(\%options);

Append one index line, in the C<EDMS_INDEX_COLS> order, to the per-document
index file.

=head2 EDMS_idldoc_seqpg

    my $id = EDMS_idldoc_seqpg($idldoc, $page);

Build the C<idldoc_NNNNNNN> identifier that names one page of a document.

=head2 EDMS_idx_create_csv

    my @files = EDMS_idx_create_csv($cfg, $idx, $app, $idldoc, $keys);

Build the C<DOCUBASE> index in CSV form, one line per document, and return the
index file first followed by each document file name.

=head2 EDMS_import

    EDMS_import($index, @docs) or die;

Upload the documents and then the index to the EDMS application over FTP.
Returns true on success, so callers can guard with C<or die>.

=head2 EDMS_package

    EDMS_package($app, $idldoc, @elements);

Pack some documents together with one index into the standard out zip archive
and print the path of the archive. Returns true on success.

=head2 EDMS_prepare

    EDMS_prepare($app, $idldoc, $doc_path, $idx_path);

Pack a document and its index into the standard out zip archive, or stop when
either file is missing. Returns true on success.

=head2 EDMS_process

    my @files = EDMS_process($app, $idldoc, $doc, $index, $outdir);

Burst or move the document, build its index in the configured format, and
return the produced files. The optional C<$outdir> is used as a working
directory and restored afterwards.

=head2 EDMS_process_zip

    my @files = EDMS_process_zip($zipfile, $outdir);

Read a standard out zip archive, extract its document and index, and return
L</EDMS_process> of the pair.

The following subs are internal helpers and are not part of the public API:
C<_log>, C<my_system>, C<EDMS_idx_process>, C<EDMS_merge_docs>,
C<EDMS_idx_create_xml>, C<_docubase_file_name> and
C<preprend_alfresco_header_if_needed>.

=head1 AUTHOR

The oEdtk team.

=cut
