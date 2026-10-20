package oEdtk::Run;

use strict;
use warnings;

use Archive::Zip qw(:ERROR_CODES);
use Cwd;
use File::Copy;
use File::Path qw(rmtree);
use POSIX      qw(WNOHANG);
use Text::CSV;
use oEdtk::Config  qw(config_read);
use oEdtk::DBAdmin qw(db_connect);
use oEdtk::EDMS    qw(EDMS_prepare EDMS_process EDMS_import);
use oEdtk::FixIdx  qw(make_docs_even_numbered);
use oEdtk::Outmngr qw(omgr_import omgr_export);
use oEdtk::TexDoc;

use Carp                  qw(croak);
use File::Spec::Functions qw(catfile curdir rootdir updir);
use oEdtk::logger         qw(logger);
use PDF::Tk;

use Exporter;

our $VERSION   = 2.1129;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
	oe_status_to_msg
	oe_compo_run
	oe_after_compo
	oe_csv_to_doc
	oe_outmngr_output_run_tex
	oe_cmd_run
);

sub oe_cmd_run {
	my $cmd = shift;

	# Redirect stdout to stderr so the output of the command doesn't confuse
	# the scripts which parse stdout to get the list of files we generated.
	$cmd .= ' >&2';

	warn "INFO: Running command \"$cmd\"\n";
	eval { system($cmd); };
	return if $? == 0;

	my $reason = oe_status_to_msg($?);
	die "ERROR: Command failed : $reason\n";

	return 1;
}

sub oe_cmd_run_bg {
	my ( $cmd, $ref ) = @_;

	if ( ref($ref) ne 'SCALAR' ) {
		die "ERROR: oe_cmd_run_bg() expects a SCALAR reference\n";
	}

	# Wait mode: blocking by default (the mainline behaviour), non-blocking
	# when the configuration sets EDTK_CMD_RUN_BG_NOWAIT (the fork's mode). In
	# the mainline mode the first reap blocks; the loop then drains the
	# remaining children without blocking, so no zombie is left behind.
	my $flags = config_read('COMPO')->{'EDTK_CMD_RUN_BG_NOWAIT'} ? WNOHANG : 0;

	# Install a signal handler first so that we are notified if our
	# child exits prematurely, which should happen fairly rarely.
	$SIG{'CHLD'} = sub {
		my $wait = $flags;
		my $pid;
		while ( ( $pid = waitpid( -1, $wait ) ) > 0 ) {
			if ( $? != 0 ) {
				my $msg = oe_status_to_msg($?);
				warn "INFO: LaTex process exited prematurely : $msg\n";
				die "ERROR: LaTeX process exited prematurely : $msg\n"
					;    ##### xxxxxx capture of die events by the tracker ...
			}
			$$ref = 0;
			$wait = WNOHANG;
		}
	};

	$cmd .= ' >&2';
	warn "INFO: start cmd = $cmd \n";
	my $pid = fork();
	if ( !defined($pid) ) {
		die "ERROR: Cannot fork process: $!\n";
	}
	if ($pid) {

		# Parent process.
		warn "INFO: Successfully started subprocess, pid $pid - look log for details\n";
	}
	else {
		# Child process.
		exec($cmd);

		# NOT REACHED
		exit;
	}
	return $pid;
}

sub oe_status_to_msg {
	my ($status) = @_;

	return if $status == 0;
	my $msg = '';
	if ( $? == -1 ) {
		$msg = "failed to execute: $!";
	}
	elsif ( $? & 127 ) {
		$msg = sprintf( "child died with signal %d", $? & 127 );
	}
	else {
		$msg = sprintf( "child exited with value %d", $? >> 8 );
	}
	return $msg;
}

sub oe_compo_run {
	my ( $app, $options ) = @_;

	my $cfg  = config_read( ['COMPO'], $app );
	my $mode = $options->{'mode'} || 'pdf';

	my $exe;
	if ( $mode =~ /^dvi/ ) {
		$exe = $cfg->{'EDTK_COMPO_CMD_DVI'};
	}
	else {
		$exe = $cfg->{'EDTK_COMPO_CMD_PDF'};
	}

	# XXXXXXXXXXXXX  THIS IS WHERE WE SWITCH THE EXECUTION MODE TO INCLUDE MODE
	# Usage: pdftex [OPTION]... [TEXNAME[.tex]] [COMMANDS]
	#    or: pdftex [OPTION]... \FIRST-LINE
	#    or: pdftex [OPTION]... &FMT ARGS
	#   Run pdfTeX on TEXNAME, usually creating TEXNAME.pdf.
	#   Any remaining COMMANDS are processed as pdfTeX input, after TEXNAME is read.
	#   If the first line of TEXNAME is %&FMT, and FMT is an existing .fmt file,
	#   use it.  Else use `NAME.fmt', where NAME is the program invocation name,
	#   most commonly `pdftex'.
	#
	#   Alternatively, if the first non-option argument begins with a backslash,
	#   interpret all non-option arguments as a line of pdfTeX input.
	#
	#   Alternatively, if the first non-option argument begins with a &, the
	#   next word is taken as the FMT to read, overriding all else.  Any
	#   remaining arguments are processed as above.
	#
	#   If no arguments or options are specified, prompt for input.

	my $param;

	# if (defined $cfg->{'EDTK_COMPO_INCLUDE'} && $cfg->{'EDTK_COMPO_INCLUDE'}=~/yes/i) {
	# 	# DOES NOT WORK, REVIEW ACCORDING TO pdftex --help
	# 	$param = "./$app." . $cfg->{'EDTK_EXT_WORK'};
	# } else {
	$param = $cfg->{'EDTK_DIR_SCRIPT'} . "/$app." . $cfg->{'EDTK_EXT_COMPO'};

	# }

	# Use the \edExtra mechanism to include additional packages if needed.
	if ( defined( $options->{'extrapkgs'} ) ) {
		my $extra = '\newcommand{\edExtra}{';
		foreach ( @{ $options->{'extrapkgs'} } ) {
			$extra .= '\RequirePackage';
			my ( $pkg, $opts );
			if ( ref($_) eq 'ARRAY' ) {
				( $pkg, $opts ) = @$_;
				$extra .= "[$opts]";
			}
			else {
				$pkg = $_;
			}
			$extra .= "{$pkg}";
		}
		$param = $extra . '}\input{' . $param . '}';
	}
	if ( defined( $options->{'jobname'} ) ) {
		$exe .= " -jobname=$options->{'jobname'}";
	}

	my $cmd = $cfg->{'EDTK_BIN_COMPO'} . "/$exe \"$param\"";

	# Handle additional include directories.
	my @incdirs = ();
	if ( defined( $options->{'incdirs'} ) ) {
		@incdirs = @{ $options->{'incdirs'} };
	}

	# Add EDTK_DIR_DATA_IN to the list of directories LaTeX will
	# look into for when we run via runEdtk.pl.
	push( @incdirs, $cfg->{'EDTK_DIR_DATA_IN'} );
	my $old = $ENV{'TEXINPUTS'};
	if ( defined($old) ) {
		push( @incdirs, $old );
	}
	$ENV{'TEXINPUTS'} = ';' . join( ';', @incdirs );

	my $pid;

	# In FIFO mode we need to run the LaTeX process asynchronously.
	if ( $options->{'fifo'} ) {
		$pid = oe_cmd_run_bg( $cmd, \$options->{'cldstatus'} );
	}
	else {
		oe_cmd_run($cmd);
	}

	# Restore the old environment.
	if ( defined($old) ) {
		$ENV{'TEXINPUTS'} = $old;
	}
	else {
		delete $ENV{'TEXINPUTS'};
	}

	return $pid if $options->{'fifo'};
}

sub oe_after_compo {
	my ( $app, $options ) = @_;

	my $cfg  = config_read( ['EDTK_DB'], $app );
	my $mode = $options->{'mode'} || 'pdf';

	# Run dvipdfm if we were running in DVI+PDF mode.
	if ( $mode eq 'dvipdf' ) {
		my $exe = $cfg->{'EDTK_COMPO_CMD_DVIPDF'};
		my $cmd = "$cfg->{'EDTK_BIN_COMPO'}/$exe $app.dvi";
		oe_cmd_run($cmd);
	}

	# Output the full path to the generated PDF file (used by the
	# composition.sh script to determine what we have generated).
	my $pdf = "$app.pdf";
	if ( defined( $options->{'jobname'} ) ) {
		$pdf = $options->{'jobname'} . ".pdf";
	}
	if ( !-f $pdf ) {
		die "ERROR: Could not find the generated PDF file ($pdf)\n";
	}
	my $cwd = getcwd();
	print "$cwd/$pdf\n";

	# Cleanup? Keep the generated output file when the configuration asks for
	# it (EDTK_KEEP_OUT_FILE present and not NONE) or in the Test environment;
	# remove it otherwise.
	unlink("$app.aux");
	my $keep = ( exists $cfg->{'EDTK_KEEP_OUT_FILE'} && $cfg->{'EDTK_KEEP_OUT_FILE'} ne 'NONE' );
	if ( $keep || $cfg->{'EDTK_TYPE_ENV'} eq 'Test' ) {
		warn "INFO: Keeping outfile '$options->{'outfile'}'\n" if ( $options->{'outfile'} );
	}
	elsif ( $options->{'outfile'} ) {
		unlink( $options->{'outfile'} );
	}

	# If no index was requested, we are done.
	if ( !$options->{'index'} ) {
		warn "INFO: No index file was requested, done.\n";
		return;
	}

	# If an index file was requested, see if we need to import it
	# for later processing, and/or if we need to produce a GED pack.
	my $index = "$app." . $options->{'idldoc'} . ".idx1";
	if ( !-f $index ) {
		die "ERROR: Could not find the generated index file ($index)\n";
	}

	my $corp = $options->{'corp'};
	if ( !defined($corp) ) {
		die "ERROR: No corporation name given\n";
	}

	my $dbh     = db_connect( $cfg, 'EDTK_DBI_PARAM', { RaiseError => 1 } );
	my $appdata = $dbh->selectrow_hashref(
		"SELECT * FROM EDTK_REFIDDOC " . "WHERE ED_REFIDDOC = ? AND (ED_CORP = ? OR ED_CORP = '%')",
		undef, $app, $corp
	);

	if ( !defined($appdata) ) {
		warn "INFO: Application $app was not found in EDTK_REFIDDOC\n";
	}

	# Do we need to import the index ?
	#	if ($options->{'massmail'} or (defined($appdata) && $appdata->{'ED_MASSMAIL'} eq 'Y')) {
	if (   ( defined($appdata) && $appdata->{'ED_MASSMAIL'} eq 'Y' )
		or ( defined($appdata) && $appdata->{'ED_MASSMAIL'} eq 'C' && $options->{'massmail'} ) )
	{
		my $doclib = "$cfg->{'EDTK_DIR_DOCLIB'}/$options->{'doclib'}";
		warn "INFO: Moving $pdf into $doclib\n";
		copy( $pdf, $doclib );
		warn "INFO: Importing index into database...\n";
		omgr_import( $app, $index, $corp );
	}

	# Do we need to prepare for GED processing?
	#	if (defined($appdata) && $appdata->{'ED_EDOCSHARE'} eq 'Y') {
	if (   ( defined($appdata) && $appdata->{'ED_EDOCSHARE'} eq 'Y' )
		or ( defined($appdata) && $appdata->{'ED_EDOCSHARE'} eq 'C' && $options->{'edms'} )
		or ( defined($appdata) && $options->{'bpdf'} ) )
	{

		if ( $options->{'cgi'} && $options->{'cgiged'} ) {
			warn "INFO: Direct GED processing...\n";
			my ( $index, @pdfs ) = EDMS_process( $app, $options->{'idldoc'}, $pdf, $index );
			EDMS_import( $index, @pdfs )
				or die "ERROR: EDMS_import failed\n";
		}
		elsif ( !$options->{'cgi'} ) {
			if ( $options->{'bpdf'} ) {
				$pdf = oe_background_pdf( $cfg, $options, $pdf, $index );
			}
			warn "INFO: Preparing ZIP archive for GED...\n";
			EDMS_prepare( $app, $options->{'idldoc'}, $pdf, $index );
		}
	}

	# Now we can remove the index file.
	if ( $cfg->{'EDTK_TYPE_ENV'} ne 'Test' ) {
		unlink($index);
	}

	return 1;
}

# List the entries of a directory whose name matches a regexp, sorted.
sub listing_depository {
	my ( $depo_path, $rgxp_name ) = @_;

	opendir( my $depot, $depo_path )
		or croak "Can't open depository : $depo_path\n";
	my @contents = grep { /$rgxp_name/xms } readdir($depot);
	closedir($depot);

	my @sorted = sort @contents;
	return @sorted;
}

# Double every line of an index file, then renumber the ";n;m;" markers so the
# two copies carry consecutive numbers.
sub update_idx {
	my $idx_file = shift;

	my @tab_line;
	open my $fh, '<', $idx_file
		or croak "ERROR: Cannot open index file \"$idx_file\": $!\n";
	foreach (<$fh>) {
		push @tab_line, $_, $_;
	}
	close $fh;

	open $fh, '>', $idx_file
		or croak "ERROR: Cannot write index file \"$idx_file\": $!\n";
	for my $i ( 0 .. $#tab_line ) {
		my $num_line = $i + 1;
		$tab_line[$i] =~ s/;\d+;(\d+);/;$num_line;$1;/xms;
		print {$fh} $tab_line[$i];
	}
	close $fh;

	return 1;
}

# Overlay the configured background PDF on every page of $pdf (the fork's
# "background pdf" feature). Kept as API only: oe_after_compo is not wired to
# it in this step.
sub oe_background_pdf {
	my ( $cfg, $params, $pdf, $index ) = @_;

	my $pdftk_path = config_read('EDOCMNGR')->{'EDMS_BIN_PDFTK'};
	my $pdftk      = PDF::Tk->new( pdftk => $pdftk_path );

	my $blank_pdf = $cfg->{'EDTK_DIR_BACKGROUNDS'} . q{/} . 'blank' . q{.} . $cfg->{'EDTK_EXT_PDF'};
	croak "ERROR: $blank_pdf don't exist" if !-e $blank_pdf;

	$pdftk->call_pdftk( $pdf, '%04d_split.pdf', 'burst' );

	my @contents = listing_depository( q{./}, '[0-9]*_split\.pdf$' );

	if ( ( scalar @{ $params->{'backgrounds'} } ) ne 1
		&& @contents ne ( scalar @{ $params->{'backgrounds'} } ) )
	{
		croak "ERROR: received "
			. ( scalar @{ $params->{'backgrounds'} } )
			. " but needed 1 or "
			. @contents
			. "\n Quit cause can't continue";
	}

	my $index_background = 0;
	foreach (@contents) {
		my $background_pdf =
			  $cfg->{'EDTK_DIR_BACKGROUNDS'} . q{/}
			. $params->{'backgrounds'}->[$index_background] . q{_}
			. $cfg->{'EDTK_CORP'} . q{.}
			. $cfg->{'EDTK_EXT_PDF'};
		if ( !-e $background_pdf ) {
			if ( $cfg->{'EDTK_TYPE_ENV'} eq 'Production' ) {
				croak "ERROR: background $background_pdf doesn't exist";
			}
			else {
				&logger( 4, "Can't find $background_pdf so I put a blank background\n" );
				$background_pdf = catfile( $cfg->{'EDTK_DIR_BACKGROUNDS'}, 'blank.pdf' );
			}
		}

		my @cat_tab = ( $_, $blank_pdf );
		$pdftk->call_pdftk( \@cat_tab, $_ . q{.} . 'blank', 'cat' );
		$pdftk->call_pdftk( $_ . q{.} . 'blank', $_, 'multibackground', $background_pdf );

		if ( ( $index_background + 1 ) < ( scalar @{ $params->{'backgrounds'} } ) ) {
			$index_background++;
		}
	}

	my $pdf_out =
		q{./} . $params->{'app-ref'} . q{.} . $params->{'idldoc'} . q{.} . $cfg->{'EDTK_EXT_PDF'};
	$pdftk->call_pdftk( \@contents, $pdf_out, 'cat' );

	unlink glob '*split.pdf*' or croak "ERROR: can't delete useless pdf";

	update_idx($index);

	return $pdf_out;
}

sub oe_csv_to_doc {
	my ( $input, $endtag ) = @_;

	my $doc = oEdtk::TexDoc->new;
	open( my $fh, '<', $input ) or die "Cannot open \"$input\": $!\n";

	my $csv  = Text::CSV->new( { binary => 1 } );
	my @cols = map { s/_//gr } @{ $csv->getline($fh) };

	while ( my $vals = $csv->getline($fh) ) {
		my %lists = ();
		for ( my $i = 0 ; $i < $#cols ; $i++ ) {
			my ( $key, $val ) = ( $cols[$i], $vals->[$i] );
			if ( $key !~ /^(\D+)\d+$/ ) {
				$doc->append( $key, $val );
			}
			elsif ( $val ne '' ) {
				push( @{ $lists{$1} }, $val );
			}
		}
		while ( my ( $key, $val ) = each %lists ) {
			$doc->append_table( $key, @$val );
		}
		$doc->append($endtag);
	}
	close($fh);
	return $doc;
}

# True when a lot's filiere (the part of its name after the last dot) is
# declared recto-verso in the configuration. EDTK_FILIERES_RECTO_VERSO is a
# whitespace-separated list of filieres, empty by default (no lot is padded).
sub _filiere_is_rectoverso {
	my ( $lot, $cfg ) = @_;
	my $filiere  = substr( $lot, rindex( $lot, '.' ) + 1 );
	my @declared = split ' ', ( $cfg->{'EDTK_FILIERES_RECTO_VERSO'} // '' );
	return scalar grep { $_ eq $filiere } @declared;
}

sub oe_outmngr_output_run_tex {
	my ( $filter, $type ) = @_;

# With the distinction between composition applications and batching processing, the following test no longer makes sense
#	if ($type !~ /[MTD]/) {
#		# oe_outmngr_output_run: we only go through index_output for Mass, Debug or batching Test
#		warn "INFO: OM processing '$type' -> batching suspended\n";
#		return 1;
#	}

	my $cfg      = config_read('COMPO');
	my $type_env = $cfg->{'EDTK_TYPE_ENV'};
	my $basedir  = $cfg->{'EDTK_DIR_OUTMNGR'};

	warn "INFO: Calling omgr_export\n";
	my @lots = omgr_export(%$filter);

	foreach (@lots) {
		my ( $lot, @doclibs ) = @$_;

		my $lotdir = "$basedir/$lot";
		chdir($lotdir) or die "Cannot change directory to \"$lotdir\": $!\n";
		warn "INFO: Preparing job ticket $lot for compo (doclibs = @doclibs)\n";

		# Create the intermediate stream.
		my $doc = oEdtk::TexDoc->new;
		$doc->append( oe_csv_to_doc( "$lot.job", 'edStartPg' ) );

		warn "INFO: Preparing index $lot for compo\n";
		$doc->append( oe_csv_to_doc( "$lot.idx", 'xFLigne' ) );
		$doc->append('edEndPg');
		$doc->append('xFinFlux');

		# The intermediate stream is written in UTF-8, the encoding the
		# composition expects.
		open( my $txt, '>:encoding(UTF-8)', 'LOTPDF.txt' )
			or die "Cannot open \"LOT.txt\": $!\n";
		print $txt "$doc";
		close($txt);

		warn "INFO: Composition $lot in $basedir/$lotdir\n";
		my $options = {
			jobname => $lot,
			incdirs => [ $cfg->{'EDTK_DIR_DOCLIB'} ]
		};
		oe_compo_run( 'LOTPDF', $options );
		oe_after_compo( 'LOTPDF', $options );

		# Generate the final PDF file.
		if ( !-f "$lot.pdf" ) {
			die "ERROR: Composition did not create PDF file\n";
		}

		# Recto-verso: pad the index to an even number of pages when the lot's
		# filiere is declared recto-verso in the configuration.
		if ( _filiere_is_rectoverso( $lot, $cfg ) ) {
			make_docs_even_numbered("$lot.idx");
		}

		warn "INFO: Packaging $basedir $lot\n";
		my $zip = Archive::Zip->new();
		$zip->addFile( "$lotdir/$lot.idx", "$lot.idx" );
		$zip->addFile( "$lotdir/$lot.pdf", "$lot.pdf" );
		die "ERROR: Could not create zip archive\n"
			unless $zip->writeToFileNamed("$basedir/$lot.zip") == AZ_OK;
	}

	# Change the current working directory to the base directory, otherwise
	# we wouldn't be able to remove the temporary directory we are still in.
	chdir($basedir);
	foreach (@lots) {
		my ($lot) = @$_;

		print "$basedir/$lot.zip\n";
		if ( $type_env !~ /^De/i ) {    # not done for the Dev or Debug environments
			warn "INFO: removing intermediate files ($type_env)\n";
			rmtree("$basedir/$lot");
		}
	}
	return @lots;
}

1;

=head1 NAME

oEdtk::Run - orchestrate a composition run: LaTeX, post-processing and output

=head1 SYNOPSIS

    use oEdtk::Run qw(oe_compo_run oe_after_compo);

    oe_compo_run($app, { mode => 'pdf' });
    oe_after_compo($app, { outfile => $pdf });

=head1 DESCRIPTION

Runs one composition: it launches the LaTeX executable in the configured mode,
post-processes the result (dvipdfm, cleanup, index import), and packs or exports
the output through L<oEdtk::Outmngr> and L<oEdtk::EDMS>. It also provides the
command helpers used throughout the oEdtk runtime.

=head1 FUNCTIONS

=head2 oe_status_to_msg

    my $msg = oe_status_to_msg($status);

Translate a process wait status into a human message, or return nothing when the
status is zero.

=head2 oe_compo_run

    oe_compo_run($app, \%options);

Run the LaTeX composition of C<$app> in the configured mode. C<%options> may
carry C<mode>, C<jobname>, C<extrapkgs>, C<incdirs>, C<fifo> and C<cldstatus>;
in FIFO mode the process runs in the background and its pid is returned.

=head2 oe_after_compo

    oe_after_compo($app, \%options);

Post-process the composition: run C<dvipdfm> in DVI+PDF mode, print the path of
the generated PDF, clean up the intermediate files, and import the index or build
the EDMS pack when one was requested.

=head2 oe_csv_to_doc

    my $doc = oe_csv_to_doc($input, $endtag);

Build an L<oEdtk::TexDoc> from a two-column CSV: each numbered group becomes a
table, and C<$endtag> ends every record.

=head2 oe_outmngr_output_run_tex

    my @lots = oe_outmngr_output_run_tex(\%filter, $type);

Export the matching lots, compose each one into a PDF, pad recto-verso lots, and
pack each lot's index and PDF into a zip archive; return the lots.

=head2 oe_cmd_run

    oe_cmd_run($cmd);

Run C<$cmd>, with its stdout redirected to stderr, and die with the translated
status when it fails.

The following subs are internal helpers and are not part of the public API:
C<oe_cmd_run_bg>, C<listing_depository>, C<update_idx>, C<oe_background_pdf>
and C<_filiere_is_rectoverso>.

=head1 AUTHOR

The oEdtk team.

=cut
