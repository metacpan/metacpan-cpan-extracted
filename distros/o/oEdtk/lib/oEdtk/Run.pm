package oEdtk::Run;

use strict;
use warnings;

use Archive::Zip	qw(:ERROR_CODES);
use Cwd;
use File::Copy;
use File::Path		qw(rmtree);
use Text::CSV;
use oEdtk::Config	qw(config_read);
use oEdtk::DBAdmin	qw(db_connect);
use oEdtk::EDMS		qw(EDMS_prepare EDMS_process EDMS_import);
use oEdtk::Outmngr	qw(omgr_import omgr_export);
use oEdtk::TexDoc;

use Exporter;

our $VERSION	= 1.5041;
our @ISA		= qw(Exporter);
our @EXPORT_OK	= qw(
	oe_status_to_msg
	oe_compo_run
	oe_after_compo
	oe_csv_to_doc
	oe_outmngr_output_run_tex
	oe_cmd_run
);

sub oe_cmd_run($) {
	my $cmd = shift;

	# Redirect stdout to stderr so the output of the command doesn't confuse
	# the scripts which parse stdout to get the list of files we generated.
	$cmd .= ' >&2';

	warn "INFO : Running command \"$cmd\"\n";
	eval { system($cmd); };
	return if $? == 0;

	my $reason = oe_status_to_msg($?);
	die "ERROR: Command failed : $reason\n";

return 1;
}

sub oe_cmd_run_bg($$) {
	my ($cmd, $ref) = @_;

	if (ref($ref) ne 'SCALAR') {
		die "ERROR: oe_cmd_run_bg() expects a SCALAR reference\n";
	}

	# Install a signal handler first so that we are notified if our
	# child exits prematurely, which should happen fairly rarely.
	$SIG{'CHLD'} = sub {
		my $pid = waitpid(-1, 0);
		if ($pid > 0) {
			if ($? != 0) {
				my $msg = oe_status_to_msg($?);
				warn "INFO : LaTex process exited prematurely : $msg\n";
				die  "ERROR: LaTeX process exited prematurely : $msg\n"; ##### xxxxxx capture des die par le tracker ...
			}
			$$ref = 0;
		}
	};

	$cmd .= ' >&2';
	warn "INFO : start cmd = $cmd \n";
	my $pid = fork();
	if (!defined($pid)) {
		die "ERROR: Cannot fork process: $!\n";
	}
	if ($pid) {
		# Parent process.
		warn "INFO : Successfully started subprocess, pid $pid - look log for details\n";
	} else {
		# Child process.
		exec($cmd);
		# NOT REACHED
		exit;
	}
	return $pid;
}

sub oe_status_to_msg($) {
	my ($status) = @_;

	return undef if $status == 0;
	my $msg = '';
	if ($? == -1) {
		$msg = "failed to execute: $!";
	} elsif ($? & 127) {
		$msg = sprintf("child died with signal %d", $? & 127);
	} else {
		$msg = sprintf("child exited with value %d", $? >> 8);
	}
	return $msg;
}

sub oe_compo_run($;$) {
	my ($app, $options) = @_;

	my $cfg = config_read(['COMPO'], $app);
	my $mode = $options->{'mode'} || 'pdf';

	my $exe;
	if ($mode =~ /^dvi/) {
		$exe = $cfg->{'EDTK_COMPO_CMD_DVI'};
	} else {
		$exe = $cfg->{'EDTK_COMPO_CMD_PDF'};
	}

	# XXXXXXXXXXXXX  C'EST ICI QU'ON CHANGE LE MODE D'EXECUTION EN MODE INCLUDE
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
	# 	# NE FONCTIONNE PAS, À REVOIR EN FONCTION DE pdftex --help
	# 	$param = "./$app." . $cfg->{'EDTK_EXT_WORK'};
	# } else { 
		$param = $cfg->{'EDTK_DIR_SCRIPT'} . "/$app." . $cfg->{'EDTK_EXT_COMPO'}; 
	# }

	# Use the \edExtra mechanism to include additional packages if needed.
	if (defined($options->{'extrapkgs'})) {
		my $extra = '\newcommand{\edExtra}{';
		foreach (@{$options->{'extrapkgs'}}) {
			$extra .= '\RequirePackage';
			my ($pkg, $opts);
			if (ref($_) eq 'ARRAY') {
				($pkg, $opts) = @$_;
				$extra .= "[$opts]";
			} else {
				$pkg = $_;
			}
			$extra .= "{$pkg}";
		}
		$param = $extra . '}\input{' . $param . '}';
	}
	if (defined($options->{'jobname'})) {
		$exe .= " -jobname=$options->{'jobname'}";
	}

	my $cmd = $cfg->{'EDTK_BIN_COMPO'} . "/$exe \"$param\"";

	# Handle additional include directories.
	my @incdirs = ();
	if (defined($options->{'incdirs'})) {
		@incdirs = @{$options->{'incdirs'}};
	}
	# Add EDTK_DIR_DATA_IN to the list of directories LaTeX will
	# look into for when we run via runEdtk.pl.
	push(@incdirs, $cfg->{'EDTK_DIR_DATA_IN'});
	my $old = $ENV{'TEXINPUTS'};
	if (defined($old)) {
		push(@incdirs, $old);
	}
	$ENV{'TEXINPUTS'} = ';' . join(';', @incdirs);

	my $pid;
	# In FIFO mode we need to run the LaTeX process asynchronously.
	if ($options->{'fifo'}) {
		$pid = oe_cmd_run_bg($cmd, \$options->{'cldstatus'});
	} else {
		oe_cmd_run($cmd);
	}
	# Restore the old environment.
	if (defined($old)) {
		$ENV{'TEXINPUTS'} = $old;
	} else {
		delete $ENV{'TEXINPUTS'};
	}

	return $pid if $options->{'fifo'};
}


sub oe_after_compo($$) {
	my ($app, $options) = @_;

	my $cfg = config_read(['EDTK_DB'], $app);
	my $mode = $options->{'mode'} || 'pdf';

	# Run dvipdfm if we were running in DVI+PDF mode.
	if ($mode eq 'dvipdf') {
		my $exe = $cfg->{'EDTK_COMPO_CMD_DVIPDF'};
		my $cmd = "$cfg->{'EDTK_BIN_COMPO'}/$exe $app.dvi";
		oe_cmd_run($cmd);
	}

	# Output the full path to the generated PDF file (used by the
	# composition.sh script to determine what we have generated).
	my $pdf = "$app.pdf";
	if (defined($options->{'jobname'})) {
		$pdf = $options->{'jobname'} . ".pdf";
	}
	if (! -f $pdf) {
		die "ERROR: Could not find the generated PDF file ($pdf)\n";
	}
	my $cwd = getcwd();
	print "$cwd/$pdf\n";

	# Cleanup?
	unlink("$app.aux");
	if ($cfg->{'EDTK_TYPE_ENV'} ne 'Test') {
		unlink($options->{'outfile'}) if ($options->{'outfile'});
	}

	# If no index was requested, we are done.
	if (!$options->{'index'}) {
		warn "INFO : No index file was requested, done.\n";
		return;
	}

	# If an index file was requested, see if we need to import it
	# for later processing, and/or if we need to produce a GED pack.
	my $index = "$app." . $options->{'idldoc'} . ".idx1";
	if (! -f $index) {
		die "ERROR: Could not find the generated index file ($index)\n";
	}

	my $corp = $options->{'corp'};
	if (!defined($corp)) {
		die "ERROR: No corporation name given\n";
	}

	my $dbh = db_connect($cfg, 'EDTK_DBI_PARAM', { RaiseError => 1 });
	my $appdata = $dbh->selectrow_hashref("SELECT * FROM EDTK_REFIDDOC " .
	    "WHERE ED_REFIDDOC = ? AND (ED_CORP = ? OR ED_CORP = '%')", undef,
	    $app, $corp);

	if (!defined($appdata)) {
		warn "INFO : Application $app was not found in EDTK_REFIDDOC\n";
	}

	# Do we need to import the index ?
#	if ($options->{'massmail'} or (defined($appdata) && $appdata->{'ED_MASSMAIL'} eq 'Y')) {
	if ( (defined($appdata) && $appdata->{'ED_MASSMAIL'} eq 'Y')
	     or
	     (defined($appdata) && $appdata->{'ED_MASSMAIL'} eq 'C' && $options->{'massmail'})
		) {
		my $doclib = "$cfg->{'EDTK_DIR_DOCLIB'}/$options->{'doclib'}";
		warn "INFO : Moving $pdf into $doclib\n";
		copy($pdf, $doclib);
		warn "INFO : Importing index into database...\n";
		omgr_import($app, $index, $corp);
	}

	# Do we need to prepare for GED processing?
#	if (defined($appdata) && $appdata->{'ED_EDOCSHARE'} eq 'Y') {
	if ( (defined($appdata) && $appdata->{'ED_EDOCSHARE'} eq 'Y')
	     or
	     (defined($appdata) && $appdata->{'ED_EDOCSHARE'} eq 'C' && $options->{'edms'})
		) {

		if ($options->{'cgi'} && $options->{'cgiged'}) {
			warn "INFO : Direct GED processing...\n";
			my ($index, @pdfs) = EDMS_process($app, $options->{'idldoc'},
			    $pdf, $index);
			EDMS_import($index, @pdfs)
				or die "ERROR: EDMS_import failed\n";
		} elsif (!$options->{'cgi'}) {
			warn "INFO : Preparing ZIP archive for GED...\n";
			EDMS_prepare($app, $options->{'idldoc'}, $pdf, $index);
		}
	}

	# Now we can remove the index file.
	if ($cfg->{'EDTK_TYPE_ENV'} ne 'Test') {
		unlink($index);
	}

return 1;
}

sub oe_csv_to_doc($$) {
	my ($input, $endtag) = @_;

	my $doc = oEdtk::TexDoc->new;
	open(my $fh, '<', $input) or die "Cannot open \"$input\": $!\n";

	my $csv = Text::CSV->new({ binary => 1 });
	my @cols = map { s/_//g; $_ } @{$csv->getline($fh)};

	while (my $vals = $csv->getline($fh)) {
		my %lists = ();
		for (my $i = 0; $i < $#cols; $i++) {
			my ($key, $val) = ($cols[$i], $vals->[$i]);
			if ($key !~ /^(\D+)\d+$/) {
				$doc->append($key, $val);
			} elsif ($val ne '') {
				push(@{$lists{$1}}, $val);
			}
		}
		while (my ($key, $val) = each %lists) {
			$doc->append_table($key, @$val);
		}
		$doc->append($endtag);
	}
	close($fh);
	return $doc;
}

sub oe_outmngr_output_run_tex($;$) {
	my ($filter, $type) = @_;

# Avec la distinction aplication de mise en forme et traitement de lotissement, le test suivant n'a plus de sens
#	if ($type !~ /[MTD]/) {
#		# oe_outmngr_output_run : on ne passe dans index_output qu'en cas de Mass, Debug ou Test de lotissement
#		warn "INFO : traitement OM '$type' -> lotissement suspendu\n";
#		return 1;
#	}

	my $cfg = config_read('COMPO');
	my $type_env= $cfg->{'EDTK_TYPE_ENV'};
	my $basedir = $cfg->{'EDTK_DIR_OUTMNGR'};

	warn "INFO : Appel omgr_export\n";
	my @lots = omgr_export(%$filter);

	foreach (@lots) {
		my ($lot, @doclibs) = @$_;

		my $lotdir = "$basedir/$lot";
		chdir($lotdir) or die "Cannot change directory to \"$lotdir\": $!\n";
		warn "INFO : Preparing job ticket $lot for compo (doclibs = @doclibs)\n";

		# Création du flux intermédiaire.
		my $doc = oEdtk::TexDoc->new;
		$doc->append(oe_csv_to_doc("$lot.job", 'edStartPg'));

		warn "INFO : Preparing index $lot for compo\n";
		$doc->append(oe_csv_to_doc("$lot.idx", 'xFLigne'));
		$doc->append('edEndPg');
		$doc->append('xFinFlux');

		open(my $txt, '>', 'LOTPDF.txt') or die "Cannot open \"LOT.txt\": $!\n";
		print $txt "$doc";
		close($txt);

		warn "INFO : Composition $lot in $basedir/$lotdir\n";
		my $options = {
			jobname => $lot,
			incdirs => [$cfg->{'EDTK_DIR_DOCLIB'}]
		};
		oe_compo_run('LOTPDF', $options);
		oe_after_compo('LOTPDF', $options);

		# Generate the final PDF file.
		if (! -f "$lot.pdf") {
			die "ERROR: Composition did not create PDF file\n";
		}

		warn "INFO : Packaging $basedir $lot\n";
		my $zip = Archive::Zip->new();
		$zip->addFile("$lotdir/$lot.idx", "$lot.idx");
		$zip->addFile("$lotdir/$lot.pdf", "$lot.pdf");
		die "ERROR: Could not create zip archive\n"
		    unless $zip->writeToFileNamed("$basedir/$lot.zip") == AZ_OK;
	}

	# Change the current working directory to the base directory, otherwise
	# we wouldn't be able to remove the temporary directory we are still in.
	chdir($basedir);
	foreach (@lots) {
		my ($lot) = @$_;

		print "$basedir/$lot.zip\n";
		if ($type_env !~ /^De/i) { # on ne la fait pas pour les environnements de Dev ou Debug
			warn "INFO : suppression des fichiers intermediaires ($type_env)\n";
			rmtree("$basedir/$lot");
		}
	}
	return @lots;
}

1;
