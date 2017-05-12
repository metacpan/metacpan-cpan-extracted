package oEdtk::EDMS;
# Electronic Document Management (GED in french)
use strict;
use warnings;

use Exporter;
our $VERSION	= 0.8035;
our @ISA	= qw(Exporter);
our @EXPORT_OK	= qw(
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

# use File::Temp	qw(tempdir);
use Archive::Zip	qw(:ERROR_CODES);
use Cwd;
use File::Basename;
use File::Copy;
use Net::FTP;
use oEdtk::Main;
use oEdtk::Config	qw(config_read);
use oEdtk::DBAdmin	qw(@INDEX_COLS);
use POSIX		qw(strftime);
use Text::CSV;
use XML::Writer;

# use PDF;		# ajouter dans les prerequis


# Utility function to construct filenames.
sub EDMS_idldoc_seqpg($$) {
	my ($idldoc, $page) = @_;

	# Modifié suite au problème de . dans le nom de fichier pour Docubase
	# $idldoc =~ s/\./_/;
	return sprintf("${idldoc}_%07d", $page);
}

# Package a DOC along with its index in a zip archive for later processing.
sub EDMS_prepare($$$$) {
	my $app	= shift;
	my $idldoc= shift;
	my $doc_path=shift;
	my $idx_path=shift;
	my $doc = "$app.$idldoc.pdf";

	my $cfg = config_read('EDOCMNGR');
	my $zip = Archive::Zip->new();
	$zip->addFile($doc_path, $doc);
	$zip->addFile($idx_path, basename($idx_path));

	my $zipfile = "$cfg->{'EDTK_DIR_EDOCMNGR'}/$app.$idldoc.out.zip";
	die "ERROR: Could not create zip achive \"$zipfile\"\n"
	    unless $zip->writeToFileNamed($zipfile) == AZ_OK;
	print "$zipfile\n";

return 1;
}


# Package some documents along with one index in a zip archive.
sub EDMS_package($$@) {
	my $app	= shift;
	my $idldoc= shift;
	my @elements=@_;

	my $cfg = config_read('EDOCMNGR');
	my $zip = Archive::Zip->new();

	foreach (@elements){
		$zip->addFile($_, basename($_));
	}

	my $zipfile = "$cfg->{'EDTK_DIR_EDOCMNGR'}/$app.$idldoc.out.zip";
	die "ERROR: Could not create zip achive \"$zipfile\"\n"
	    unless $zip->writeToFileNamed($zipfile) == AZ_OK;
	print "$zipfile\n";

return 1;
}


sub EDMS_process_zip($;$) {
	my ($zipfile, $outdir) = @_;

	my $zipname = basename($zipfile);
	if ($zipname !~ /^([^.]+)\.(.+)\.out\.zip$/) {
		die "ERROR: Unexpected zip filename: $zipname\n";
	}
	my ($app, $idldoc) = ($1, $2);

	my $zip = Archive::Zip->new();
	if ($zip->read($zipfile) != AZ_OK) {
		die "ERROR: Could not read zip archive \"$zipfile\"\n";
	}

	my @files = $zip->members();
	my ($idx_member) = $zip->membersMatching('\.idx1$');
	my ($doc_member) = $zip->membersMatching('\.pdf$');
		if (!defined($doc_member)){
			($doc_member) = $zip->membersMatching('\.xls$');
		}
		if (!defined($doc_member)){
			($doc_member) = $zip->membersMatching('\.doc$');
		}
	if (!defined($doc_member) || !defined($idx_member)) {
		die "ERROR: Could not find document(s) or index file in archive\n";
	}
	my $doc_name = $doc_member->fileName();
	my $idx_name = $idx_member->fileName();
	my $doc_path = $doc_name;
	my $idx_path = $idx_name;
	if (defined($outdir)) {
		$doc_path = "$outdir/$doc_path";
		$idx_path = "$outdir/$idx_path";
	}
	warn "INFO : Extracting file \"$doc_name\"\n";
	if ($zip->extractMember($doc_member, $doc_path) != AZ_OK) {
		die "ERROR: Could not extract \"$doc_name\" from archive\n";
	}
	warn "INFO : Extracting file \"$idx_name\"\n";
	if ($zip->extractMember($idx_member, $idx_path) != AZ_OK) {
		die "ERROR: Could not extract \"$idx_name\" from archive\n";
	}

return EDMS_process($app, $idldoc, $doc_name, $idx_name, $outdir);
}


# Process document(s) with its index in a way suitable for the edms software.
sub EDMS_process($$$$;$) {
	my ($app, $idldoc, $doc, $index, $outdir) = @_;
	# Remplace les - et les . par des _ car Docubase ne peut pas importer de fichier comprenant des . dans leur nom
	$idldoc	=~ s/[-\.]/_/g;
	$app		=~ s/[-\.]/_/g;

	my $cfg = config_read('EDOCMNGR');
	my $format  = $cfg->{'EDMS_IDX_FORMAT'};
	my @edmscols = split(/,/, $cfg->{'EDMS_INDEX_COLS'});

	my $oldcwd;
	if (defined($outdir)) {
		$oldcwd = getcwd();
		chdir($outdir)
		    or die "ERROR: Cannot change current directory to \"$outdir\": $!\n";
	}
	my @outfiles = ();

	if ($doc =~ /pdf$/i){
		warn "INFO : Splitting $doc into individual docs...\n";

		## gs -sDEVICE=pdfwrite \
		##   -q -dNOPAUSE -dBATCH \
		##   -sOutputFile=sample-1.pdf \
		##   -dFirstPage=1 \
		##   -dLastPage=1 \
		##   FAX200904010240-1.PDF
		#my $this_pdf = PDF->new;
		#$this_pdf = PDF->new($doc);

		#my $output = "${app}_${idldoc}_%07d.pdf";
		#my $gs = system ($cfg->{'EDMS_BIN_GS'} . " -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dFirstPage=1 -dLastPage=". $this_pdf->Pages ." -sOutputFile=$output $doc ");
		#if ($gs != 0) {
		#	die "ERROR: Could not split pages from $doc to $output !\n";
		#}

		# Modifié suite au problème des points dans les noms de fichiers pour docubase
		my $rv = system($cfg->{'EDMS_BIN_PDFTK'} . " $doc burst output ${app}_${idldoc}_%07d.pdf ");

		if ($rv != 0) {
			die "ERROR: Could not burst PDF file $doc!\n";
		}

	} else {
		#warn "DEBUG: document $doc is not pdf file\n";
		my $cible = _docubase_file_name($doc);
		move ($doc, $cible) or die "ERROR: echec move $cible ($doc)\n";
		push (@outfiles, $cible);
	}

	if ($format eq 'DOCUBASE') {
		@outfiles = EDMS_idx_create_csv($cfg, $index, $app, $idldoc, \@edmscols);
	} elsif ($format eq 'SCOPMASTER') {
		@outfiles = EDMS_idx_create_xml($cfg, $index, $app, $idldoc, \@edmscols);
	} else {
		die "ERROR: Unexpected index format: $format\n";
	}

	if ($cfg->{'EDTK_TYPE_ENV'} ne 'Test') {
		unlink($doc) if ($doc =~ /pdf$/i);
		unlink($index);
		unlink('doc_data.txt');		# pdftk creates this one.
	}

	if (defined($outdir)) {
		# Restore original working directory.
		chdir($oldcwd);
	}

return @outfiles;
}


# TRANSFER THE PDF FILES AND THE INDEX TO edms APPLICATION.
sub EDMS_import($@) {
	my ($index, @docs) = @_;

	my $cfg = config_read('EDOCMNGR');
	warn "INFO : Connection to edms FTP server $cfg->{'EDMS_FTP_HOST'}:$cfg->{'EDMS_FTP_PORT'}\n";
	my $ftp = Net::FTP->new($cfg->{'EDMS_FTP_HOST'}, Port => $cfg->{'EDMS_FTP_PORT'})
	    or die "ERROR: Cannot connect to $cfg->{'EDMS_FTP_HOST'}: $@\n";
	$ftp->login($cfg->{'EDMS_FTP_USER'}, $cfg->{'EDMS_FTP_PASS'})
	    or die "ERROR: Cannot login: " . $ftp->message() . "\n";
	$ftp->binary()
	    or die "ERROR: Cannot set binary mode: " . $ftp->message() . "\n";
	$ftp->cwd($cfg->{'EDMS_FTP_DIR_DOCS'})
	    or die "ERROR: Cannot change working directory: " . $ftp->message() . "\n";

	# It is important to transfer the edms APPLICATION index file last, otherwise
	# the PDF files that haven't been transferred yet will not be processed.
	foreach my $doc (@docs) {
		warn "INFO : Uploading DOC file $doc\n";
		$ftp->put($doc)
		    or die "ERROR: Cannot upload DOC file : " . $ftp->message() . "\n";
	}
	warn "INFO : Uploading index file $index\n";
	$ftp->cwd()
	    or die "ERROR: Cannot change working directory : " . $ftp->message() . "\n";
	$ftp->cwd($cfg->{'EDMS_FTP_DIR_IDX'})
	    or die "ERROR: Cannot change working directory : " . $ftp->message() . "\n";
	$ftp->put($index)
	    or die "ERROR: Cannot upload index file : " . $ftp->message() . "\n";
	$ftp->quit();
}

# READ THE INITIAL INDEX FILE, AND CALL THE GIVEN FUNCTION FOR EACH NEW
# DOCUMENT. ALSO CONCATENATE PDF FILES IF NEEDED (FOR MULTI-PAGES DOCUMENTS).
sub EDMS_idx_process($$$$&) {
	my ($app, $idx, $idldoc, $keys, $sub) = @_;

	my @idxcols = map { $$_[0] } @INDEX_COLS[0..28]; # il faudrait peut être pousser jusqu'à 30 (ED_CODRUPT) voir plus

	open(my $fh, '<', $idx) or die "ERROR: Cannot open \"$idx\": $!\n";
	my $csv = Text::CSV->new({ binary => 1, sep_char => ';' });
	$csv->column_names(@idxcols);
	my $lastdoc = 0;
	my $firstpg = 0;
	my $numpgs  = 1;
	my %docvals = ();
	my $vals;

	while ($vals = $csv->getline_hr($fh)) {
		if ($vals->{'ED_SEQDOC'} != $lastdoc) {
			if ($lastdoc != 0) {
				EDMS_merge_docs($app, $idldoc, $firstpg, $numpgs);
				$sub->(\%docvals, $firstpg, $numpgs);
				undef (%docvals);
			}
			$lastdoc = $vals->{'ED_SEQDOC'};
			# Remember the values we are interested in for the edms.
			foreach (@$keys) {
				$docvals{$_} = $vals->{$_};
			}
			$docvals{'ED_DOCLIB'} = $vals->{'ED_DOCLIB'};
			$firstpg = $vals->{'ED_IDSEQPG'};
			$numpgs  = 1;

		} else {
			# Remember the values we are interested in for the edms.
			foreach (@$keys) {
				$docvals{$_} = $vals->{$_} if $vals->{$_};
			}
			$docvals{'ED_DOCLIB'} = $vals->{'ED_DOCLIB'};
			$numpgs++;
		}
	}

	# Handle the last document.
	if ($lastdoc != 0) {
		EDMS_merge_docs($app, $idldoc, $firstpg, $numpgs);
		$sub->(\%docvals, $firstpg, $numpgs);
	}
	close($fh);
}


sub _docubase_file_name($){
	my $filename = shift;

	$filename =~s/(^.*)(\.\w{2,4}$)/$1/;
	my $ext	= $2 || "";
	$filename =~s/[-\.]/_/g;
	$filename .= $ext;

return $filename;
}


# CREATE A EDMS INDEX FILE IN CSV FORMAT (FOR EDMS APPLICATION).
sub EDMS_idx_create_csv($$$$$) {
	my ($cfg, $idx, $app, $idldoc, $keys) = @_;

	my $csv = Text::CSV->new({ binary => 1, sep_char => ';', eol => "\n", quote_space => 0 });
	my $edmsidx = "${app}_$idldoc.idx";
	open(my $fh, '>', $edmsidx) or die "ERROR: Cannot create \"$edmsidx\": $!\n";

	# Always return the index file as the first file in the list, see
	# EDMS_import() for why this is important.
	my @outfiles = ($edmsidx);
	EDMS_idx_process($app, $idx, $idldoc, $keys, sub {
		my ($vals, $firstpg, $numpgs) = @_;

		if ($vals->{'ED_DOCLIB'} =~ /pdf$/i) {
			$vals->{'EDMS_IDLDOC_SEQPG'} = EDMS_idldoc_seqpg($idldoc, $firstpg);
			$vals->{'EDMS_FILENAME'}  = "${app}_". $vals->{'EDMS_IDLDOC_SEQPG'} .".pdf";
		} else {
			$vals->{'EDMS_FILENAME'}  = _docubase_file_name($vals->{'ED_DOCLIB'});
		}

		# Dates need to be in a specific format.
		my $datefmt = $cfg->{'EDMS_DATE_FORMAT'};
		if ($vals->{'ED_DTEDTION'} !~ /^(\d{4})(\d{2})(\d{2})$/) {
			die "ERROR: Unexpected date format for ED_DTEDTION: $vals->{'ED_DTEDTION'}\n";
		}
		my ($year, $month, $day) = ($1, $2, $3);
		$vals->{'EDMS_PROCESS_DT'} = strftime($datefmt, 0, 0, 0, $day, $month - 1, $year - 1900);

		# owner id for group acces in edms
		# la règle de gestion ne devrait pas etre ici, à faire évoluer
		if ($vals->{'ED_IDEMET'} =~/^\D{1}\d{3}/) {
			$vals->{'ED_OWNER'} = $vals->{'ED_IDEMET'};
		} else {
			$vals->{'ED_OWNER'} = $vals->{'ED_SOURCE'};
		}

		my @edmsvals = map { $vals->{$_} } @$keys;
		$csv->print($fh, \@edmsvals);

		push(@outfiles, $vals->{'EDMS_FILENAME'});
	});
	close($fh);
	return @outfiles;
}

# Create edms indexes in XML format (one per PDF file).
sub EDMS_idx_create_xml($$$$$) {
	my ($cfg, $idx, $app, $idldoc, $keys) = @_;

	my @outfiles = ();
	EDMS_idx_process($app, $idx, $idldoc, $keys, sub {
		my ($vals, $firstpg, $numpgs) = @_;

		my $docid = EDMS_idldoc_seqpg($idldoc, $firstpg);
		my $xmlfile = "$docid.edms.xml";
		$vals->{'ED_DOCLIB'} =~ /\.(\w{2,4})$/;
		my $ext = $1;

		open(my $fh, '>', $xmlfile) or die "ERROR: Cannot create \"$xmlfile\": $!\n";
		my $xml = XML::Writer->new(OUTPUT => $fh, ENCODING => 'utf-8');
		$xml->xmlDecl('utf-8');
		$xml->startTag('idxext');

		foreach my $pagenum (1..$numpgs) {
			$xml->startTag('page', num => $pagenum);
			if ($pagenum == 1) {
				while (my ($key,$val) = each(%$vals)) {
					$xml->emptyTag('index', key => $key, value => $val);
				}
			}
			$xml->endTag('page');
		}
		$xml->endTag('idxext');
		$xml->end();
		close($fh);

		push(@outfiles, $xmlfile);
		push(@outfiles, "${app}_$docid.$ext");
	});
	return @outfiles;
}

# Concatenate PDF documents if needed.
sub EDMS_merge_docs($$$$) {
	my ($app, $idldoc, $firstpg, $numpgs, $optimizer) = @_;
	my $cfg = config_read('EDOCMNGR'); # , $cfg->{'EDMS_PDF_OPTIMIZER'}

	# If the document is only one page long, there is nothing to concatenate.
	return unless $numpgs > 1;

	my $lastpg = $firstpg + $numpgs - 1;
	my @pages  = map { "${app}_" . EDMS_idldoc_seqpg($idldoc, $_) . ".pdf" } ($firstpg .. $lastpg);
	warn "INFO : Concatenating pages $firstpg to $lastpg into $pages[0]\n";
	my $output = "$pages[0].tmp";

	if (defined $cfg->{'EDMS_BIN_GS'} && $cfg->{'EDMS_BIN_GS'} ne "") {
		#  les pdf créés avec pdftk sont trop lourds, changement de mode opératoire ...
		my $gs = system ($cfg->{'EDMS_BIN_GS'} . " -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=$output @pages ");
		if ($gs != 0) {
			die "ERROR: Could not concatenate pages $firstpg to $lastpg!\n";
		}
	} else {
		my $rv = system($cfg->{'EDMS_BIN_PDFTK'} . " " . join(' ', @pages) . " cat output $output");
		if ($rv != 0) {
			die "ERROR: Could not concatenate pages $firstpg to $lastpg!\n";
		}
	}

	# Now, remove old files, and rename concatenated PDF to the name of
	# the PDF file of the first page.
	foreach (@pages) {
		unlink($_);
	}
	move($output, $pages[0]);
}


sub EDMS_edidx_build (\%){
	my ($refOpt) 	= @_;
	my $cfg 	= config_read('EDOCMNGR');

# EDMS_INDEX_COLS		=ED_REFIDDOC,ED_CORP,ED_SOURCE,EDMS_IDLDOC_SEQPG,ED_DTEDTION,ED_CLEGED1,ED_IDDEST,ED_NOMDEST,ED_VILLDEST,ED_IDEMET,ED_CLEGED2,ED_CLEGED3,ED_CLEGED4,ED_OWNER,EDMS_FILENAME
# clefs d'index requises 	: ED_REFIDDOC, ED_CORP, ED_SOURCE, ED_IDDEST, ED_NOMDEST, ED_IDEMET, ED_OWNER, ED_CORP
# clefs optionnelles		: ED_DTEDTION, ED_CLEGED1, ED_VILLDEST, ED_CLEGED2, ED_CLEGED3, ED_CLEGED4
# clefs (re)calculées		: ED_DTEDTION, EDMS_IDLDOC_SEQPG, EDMS_FILENAME

	# REQUIRED KEYS
	if (!defined $$refOpt{'ED_REFIDDOC'} or $$refOpt{'ED_REFIDDOC'} eq ""){
		die "ERROR: ED_REFIDDOC required.\n";
	}
	if (!defined $$refOpt{'ED_SOURCE'} or $$refOpt{'ED_SOURCE'} eq ""){
		die "ERROR: ED_SOURCE required.\n";
	}
	if (!defined $$refOpt{'ED_IDDEST'} or $$refOpt{'ED_IDDEST'} eq ""){
		die "ERROR: ED_IDDEST required.\n";
	}
	if (!defined $$refOpt{'ED_NOMDEST'} or $$refOpt{'ED_NOMDEST'} eq ""){
		die "ERROR: ED_NOMDEST required.\n";
	}
	if (!defined $$refOpt{'ED_IDEMET'} or $$refOpt{'ED_IDEMET'} eq ""){
		die "ERROR: ED_IDEMET required.\n";
	}
	if (!defined $$refOpt{'ED_OWNER'} or $$refOpt{'ED_OWNER'} eq ""){
		die "ERROR: ED_OWNER required.\n";
	}
	if (!defined $$refOpt{'ED_CORP'} or $$refOpt{'ED_CORP'} eq ""){
		die "ERROR: ED_CORP required.\n";
	}


	# COMPUTED KEYS
	my $FILE_EXT	= $$refOpt{'ED_FILENAME'}; #= $req->upload('EDMS_FILENAME');
	$FILE_EXT		=~s/^(.*\.)(\w+)$/$2/;
	$$refOpt{'ED_FORMFLUX'}	= uc ($FILE_EXT);

	my ($sec,$min,$hour,$day,$month,$year);
	if (!defined $$refOpt{'ED_DTEDTION'} || $$refOpt{'ED_DTEDTION'} !~ /^(\d{4})(\d{2})(\d{2})$/) {
		#die "ERROR: Unexpected date format for ED_DTEDTION: $$refOpt{'ED_DTEDTION'}\n";
		($sec,$min,$hour,$day,$month,$year) = localtime();
		$month ++;
		$year += 1900;
	} else {
		($year, $month, $day) = ($1, $2, $3);
	}

	# DATES NEED TO BE IN A SPECIFIC FORMAT.
	my $datefmt = $cfg->{'EDMS_DATE_FORMAT'};
	$$refOpt{'ED_DTEDTION'}		= strftime($datefmt, 0, 0, 0, $day, $month - 1, $year - 1900);
	$$refOpt{'ED_IDLDOC'}		= oEdtk::Main::oe_ID_LDOC();
	$$refOpt{'ED_IDSEQPG'}		= 1;
	$$refOpt{'ED_SEQDOC'}		= 1;
	$$refOpt{'EDMS_IDLDOC_SEQPG'} 	= EDMS_idldoc_seqpg($$refOpt{'ED_IDLDOC'}, $$refOpt{'ED_IDSEQPG'});
	$$refOpt{'EDMS_FILENAME'} 	= $$refOpt{'ED_REFIDDOC'} . "_" .$$refOpt{'EDMS_IDLDOC_SEQPG'};
	$$refOpt{'EDMS_FILENAME'} 	=~s/[-\.\s]/_/g;
	$$refOpt{'EDMS_FILENAME'} 	= $$refOpt{'EDMS_FILENAME'} . "." . $FILE_EXT ;
	$$refOpt{'ED_DOCLIB'}		= $$refOpt{'EDMS_FILENAME'};

	# OPTIONNAL KEYS
	$$refOpt{'ED_VILLDEST'}|= "";
	$$refOpt{'ED_CLEGED1'} |= "";
	$$refOpt{'ED_CLEGED2'} |= "";
	$$refOpt{'ED_CLEGED3'} |= "";
	$$refOpt{'ED_CLEGED4'} |= "";
}


sub EDMS_edidx_write (\%) {
	my ($refOpt)	= shift;
	my $cfg		= config_read('EDOCMNGR');
	my @edms_cols 	= split(/,/, $cfg->{'EDMS_INDEX_COLS'});
	my $index 	= $$refOpt{'ED_REFIDDOC'} . "_" . $$refOpt{'ED_IDLDOC'} .".idx";

	open (my $fh, ">>$index") or die "ERROR: can't open $index : $!";
	my $csv = Text::CSV->new({ binary => 1, sep_char => ';', eol => "\n", quote_space => 0 });

	my @fields; # = map { $$refOpt{$$_[0]} } @edms_cols;
	foreach my $key (@edms_cols){
		push (@fields, $$refOpt{$key});
	}

	$csv->print($fh, \@fields);
	 close($fh);
}


1;
