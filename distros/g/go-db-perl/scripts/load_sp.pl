#!/usr/local/bin/perl -w

######################################################################
#$Header: /cvsroot/geneontology/go-dev/go-db-perl/scripts/load_sp.pl,v 1.20 2009/07/15 18:15:33 benhitz Exp $
######################################################################

BEGIN {
    if (defined($ENV{GO_ROOT})) {
	use lib "$ENV{GO_ROOT}/perl-api";
    }
}

use strict;
use FileHandle;
use GO::AppHandle;
use GO::Model::Xref;
use Bio::DB::SwissProt;
use Bio::SeqIO;
use Bio::Index::Swissprot;
use Bio::Index::GenBank;
use LWP::Simple;
use LWP::UserAgent;

use constant SPROTFILE => 'uniprot_sprot.dat.gz';
use constant TREMBLFILE => 'uniprot_trembl.dat.gz';
use constant UNIPROTSRC => 'Uniprot';
use constant NCBISRC => 'Ncbi';
use constant TMPSPFILE => '/tmp/load_sp_file.tmp';  # for bioperl to parse
use constant BATCH => 500; # tested limit, increase may crash eutil
use constant TRY => 3;
use constant URLBASE => "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";

if (!@ARGV) {
    die usage();
}

use Getopt::Long;

my $apph = GO::AppHandle->connect(\@ARGV);

# get command line arguments
my $cmdoption = {};
GetOptions($cmdoption,
           "help=s",
#           "speciesdb=s",
#	   "swissdir=s",
	   "uniprotdir=s",
#           "evcode|e=s@",
           "out=s",
	   "log=s",    #failed entries logged here for report to mod
           "verbose+",
	   "nouni+",  # skip the gp2protein.uniprot file and other mapping files
	   "noncbi+",  # skip ncbi loading (badly broken April 2009)
          );

my $ncbisource = NCBISRC;
my $uniprotsource = UNIPROTSRC;

if ($cmdoption->{help}) {
    die usage();
}

warn "$0 starts at ". localtime() . "\n";

my $outfh;
if ($cmdoption->{out}) {
    $outfh = FileHandle->new(">".$cmdoption->{out});
}

my $logfh;
if ($cmdoption->{log}) {
    $logfh = FileHandle->new(">". $cmdoption->{log});
}

#if ($cmdoption->{evcode}) {
#    $apph->filters->{evcodes} = $cmdoption->{evcode};
#}

my $verbose = 0;
$verbose = 1 if ($cmdoption->{verbose});

my $nouniprot = 0;
$nouniprot = 1 if ($cmdoption->{nouni});

#my $swissdir = $cmdoption->{swissdir} || "proteomes";

my $uniprotdir = $cmdoption->{uniprotdir} || "uniprot";

my $SPROTFILE = "$uniprotdir/" . SPROTFILE;
my $TREMBLFILE = "$uniprotdir/" . TREMBLFILE;
unless (-e $SPROTFILE) {
    die $SPROTFILE." does not exist.\n";
}

unless (-e $TREMBLFILE) {
    die $TREMBLFILE." does not exist.\n";
}

# open all gp2protein files and archive all ids for retrieval
my $Xref_hashref;  # {xrefid} {source} {modacc} = speciesdb
my $dupCount = 0;
my $totalCount = 0;
my $tmpFile = TMPSPFILE . '.' . $$;  #multiple process may run this script
unlink $tmpFile if (-e $tmpFile);

my $dbxref2gp = $apph->dbxref2gp_h;

while (my $file = shift @ARGV) {
    my $speciesdb;
    if ($cmdoption->{speciesdb}) {
        $speciesdb = $cmdoption->{speciesdb};
    }
    elsif ($file =~ /gp2protein\.(\w+)\.gz/)  {
        $speciesdb = $1;
    }
    elsif ($file =~ /gp2protein\.(\w+)/)  {
        $speciesdb = $1;
    }
    else {
        die("$file not right format; must be gp2protein.SPECIESDB");
    }

    if ($nouniprot && $speciesdb =~ /(unigene|geneid|refseq)/) {
	warn("Skipping $file, -nouni set");
	next;
    }

    my $filehandle;
    if ($file =~ /\.gz/) {
        $filehandle = FileHandle->new("gzcat $file |") || die "can not gzcat $file: $!";
    }
    else {
        $filehandle = FileHandle->new($file) || die "can not open $file: $!";
    }

#    my @Failed = ();

    while (defined (my $line = <$filehandle>)) {
	chomp $line;
	next if $line =~ m/^\!/; # skip comment line on top
	next unless $line =~ m/\w+/; # skip empty line

	my ($modacc, $xrefstr) = split(/\s+/, $line);

	#xref part can be multiple ids mapped to one modacc
	my @xrefs = split(/;/, $xrefstr);

	for my $xref (@xrefs) {

	    unless ($xref =~ m/(\S+):(\S+)/) {
		warn ("seq dbxref must be DB:ACC format\n") if $verbose;
		next;
	    }
 
	    my $source = uc($1);  # NCBI, SWA, UNIPROT
	    my $xrefid = $2;  # Accession of uniport or ncbi protein db
	    if ($source =~ m/NCBI/) {
		$source = NCBISRC;
	    } else {
		$source = UNIPROTSRC;
	    }

	    my $curr_speciesdb = uc $speciesdb;

	    if ($modacc =~ m/(\w+)\:(\S+)/) {
		$curr_speciesdb = uc $1;
		$modacc = $2;

		# format inconsistency of dbxref.xref_key and gp2protein file column1
		if ($curr_speciesdb eq 'MGI' && $modacc =~ /^[0-9]+$/) { 
		    $modacc = "MGI:$modacc";
#                } elsif ($curr_speciesdb eq 'RGD' &&  $modacc =~ /^[0-9]+$/) { 
#		    $modacc = "RGD:$modacc";
		} elsif ($curr_speciesdb eq 'WB') {
		    $modacc =~ s/^WP://;
		}
	    }

	    # skip if no gene product
	    unless (exists $dbxref2gp->{uc($modacc)}->{uc($curr_speciesdb)}) {
		warn ("No gene product for modacc=$modacc speciesdb=${curr_speciesdb}\n") if $verbose;
		print $logfh "NO_GP\t${curr_speciesdb}:${modacc}\t$xrefstr\n" if defined $logfh;
                next;
	    }

	    # populate hash
	    if (exists $$Xref_hashref{$xrefid}{$source}{$modacc}) {
		$dupCount++;
	    }
	    else {
		$$Xref_hashref{$xrefid}{$source}{$modacc} = $curr_speciesdb;
	    }
        }
	$totalCount++;
    }
    close $filehandle;
    
#    if (defined $logfh) {
#	print $logfh "$file: ". @Failed . " entries skipped.\n";
#	print $logfh join("\n", @Failed) ."\n" if (@Failed > 0);
#    }
}

my $numToLoad = keys %$Xref_hashref;

if ($numToLoad > 0) {
    warn( "Number to load:". (keys %$Xref_hashref) ."\n") if $verbose;
} else {
    die "$0: Nothing to load for gp2proteins!!\n";
}

# go through uniprot file to find id

my @unifiles = ( $SPROTFILE, $TREMBLFILE );

###################################################################
# go through these two uniprot files and parse out sequences if in
# gp2protein xref list. Then load sequence into database.
###################################################################
my $countfound = 0;

my $loadSuccess = {}; # For uniprot, {mod_db}->{mod_acc}->{uniprot_xref}

for my $file (@unifiles) {    
    open (IN, "gzcat $file |") || die "can not gzcat $file: $!";

    my $uniprotid = '';
    my $accession = '';
    my $matchid = '';  # in gp2protein
    my $save_flag = 0;
    my %foundIds = (); # use to load xref table
    my $entrysaved = '';
    my $seqsection = 0;

WHL: while (defined (my $line = <IN>)) {
	chomp $line;

	# example line from uniprot file
	# ID   104K_THEPA     STANDARD;      PRT;   924 AA.
        # AC   Q9C5W6; Q9FZD3;

	if ($line =~ m/^ID\s+(\S+)/) {
	    $uniprotid = $1;
	    
	    if (exists $Xref_hashref->{$uniprotid}) {
		my $tmpSrc = UNIPROTSRC;
		for my $mod (%{$Xref_hashref->{$uniprotid}->{$tmpSrc}}) {
		    $foundIds{$mod} = $Xref_hashref->{$uniprotid}->{$tmpSrc}->{$mod};
		}
		$save_flag++;  #find id of interest
		$matchid = $uniprotid;
	    }
	}
	elsif ($line =~  m/^AC/) {
	    # there can be multiple acc on this line
            # (this ensures we satisfy the requirement that secondary IDs in the gp2protein file can be used)
	    my $tmpstr = $line;
	    $tmpstr =~ s/AC//;
	    $tmpstr =~ s/\s+//g;
	    $tmpstr =~ s/;$//;
	    my $tmpSrc = UNIPROTSRC;

	    for my $xref ( split(/;/, $tmpstr) ) {
		if (exists $Xref_hashref->{$xref}) {
		    for my $mod (%{$Xref_hashref->{$xref}->{$tmpSrc}}) {
			next unless ($mod) && ($Xref_hashref->{$xref}->{$tmpSrc}->{$mod});
			$foundIds{$mod} = $Xref_hashref->{$xref}->{$tmpSrc}->{$mod};
		    }
		    $save_flag++;  #find id of interest
		    $matchid = $xref;
		}
	    }
	}

	if ($line =~ m/^\/\//) { #end of sequence and this entry
	    if ($save_flag) { # this entry have id of interest from gp2protein file

		#check first if there is gene product for modacc
		#if not, skip loading sequence
		my @gps = ();
		my %modacc2db = ();
		while ( my ($modacc,$speciesdb) = each %foundIds ) {

		    my $gpAref = 
			$apph->get_products({xref=>{xref_key=>$modacc, 
					           xref_dbname=>$speciesdb}});

		    # skip if no gene product.
		    if (!@$gpAref) {
			    warn ("$modacc $speciesdb not in db") if $verbose;
			    next;
		    }
		    elsif (@$gpAref > 1) {
				warn (@$gpAref ." >1 match $modacc $speciesdb") if $verbose;
		    }
		    $modacc2db{$modacc} = $speciesdb;
		    @gps = (@gps, @$gpAref); 
		}

		if (@gps) {
		    # save in a tmp file for indexing and parsing by bioperl
		    open( TMP, ">$tmpFile" ) || 
			die "Can not open $tmpFile: $!";

		    print TMP "$entrysaved" . '//'."\n";
		    close TMP;
		
		    my $indexfile = $tmpFile . '.idx';
		    unlink $indexfile if -e $indexfile;

		    my $spindex =
		      Bio::Index::Swissprot->new(-file=> $indexfile,
						 -write_flag=>"WRITE");
		    
		    eval { $spindex->make_index($tmpFile) };

		    if ($@) {
				warn "ERROR when performing bioperl swissprot index: $@\n" if $verbose;
				warn "Entry that cause the above error: uniprotid=$uniprotid\n"if $verbose;
				next WHL;
		    }
		    else {
			
			my $bioseqObj = $spindex->fetch($uniprotid);

			if ($bioseqObj) {
			    &load_sequence(\@gps, UNIPROTSRC, $bioseqObj);

			    #write sequence to output file
			    while (my ($modacc, $speciesdb) = each %modacc2db) {
				if (defined $outfh) {
				    print $outfh ">${speciesdb}|${modacc} Uniprot:${uniprotid}\n";
				    print $outfh $spindex->get_Seq_by_acc($uniprotid)->seq . "\n";
				}

				$loadSuccess->{$speciesdb}->{$modacc}->{$matchid}++;
				
				if ($verbose) {
				    warn("LOADSUC: db=${speciesdb} acc=${modacc} id=${matchid}\n");
				}
			    }

			} else {

			    if ($verbose) {
			        warn "FAIL_PARSE_SEQ_UNIPROT";
			        while (my ($modacc, $speciesdb) = each %modacc2db) {
			            warn "\t${speciesdb}|${modacc}\t${uniprotid}";
			        }
			        warn "\n";
			    }
			}
		    }

		    $countfound++;
		}
	    }   #if save_flag

	    #reset everything
	    $uniprotid = '';
	    $accession = '';
	    $matchid = '';
	    $save_flag = 0;
	    %foundIds = ();
	    $entrysaved = '';
	    $seqsection = 0;
	}
	else { #save this record
	    $entrysaved .= "$line\n";
	}
    }
    close IN;
}

&print_uniprot_report($loadSuccess, $Xref_hashref, $logfh) if (defined $logfh);

###################################################################
# Deal with NCBI ids
###################################################################

my %ToRetrieve;

unless ($cmdoption->{noncbi}) {
    for my $xref ( keys %$Xref_hashref ) {
	for my $modacc (sort keys %{$Xref_hashref->{$xref}->{$ncbisource}} ) {
		my $speciesdb = $Xref_hashref->{$xref}->{$ncbisource}->{$modacc};
		my $gpAref = $apph->get_products({xref=>{xref_key=>$modacc,
						  xref_dbname=>$speciesdb}});

	    if (@$gpAref) {
		    my $ncbiacc = $xref;
		    $ncbiacc =~ s/\.\d+$//;  #remove version 

		    $ToRetrieve{$speciesdb}{$ncbiacc}{$modacc} = $gpAref;
	    }
	}
    }

    for (my $i=0; $i<3; $i++) {  #redo failed ones
	my $redo = &retrieve_from_ncbi(\%ToRetrieve, $outfh);
	last unless (%$redo);
	%ToRetrieve = %$redo;

	if ($i == 2) {
	    &print_ncbi_report($redo, $logfh) if (defined $logfh);
	}
    }

}
$outfh->close if (defined $outfh);

$logfh->close if (defined $logfh);

warn("$0 finishes at ". localtime() . "\n");

exit;

##################################################################
sub retrieve_from_ncbi {
##################################################################
    my ($ToRetrieve, $outfh) = @_;
	
    my %Redo = ();
    for my $dbname (keys %$ToRetrieve) {

        my @ids = sort keys %{$ToRetrieve->{$dbname}};

        for (my $i = 0; $i < @ids; $i += BATCH) {
	    unlink $tmpFile if (-e $tmpFile);  # clean before each batch

	    my $end = $i + BATCH - 1;
	    $end = @ids -1 if ($end >= @ids);
	    my @todo = @ids[$i .. $end];

	    warn("BATCH: ". join(',', @todo) . "\n") if $verbose;

	    if ( &batch_retrieval_ncbi(\@todo) ) {
	    	&load_and_write_file(\@todo, \%ToRetrieve, $dbname, $outfh, \%Redo);
	    }
    	}
    }
	
    return \%Redo;
}

##################################################################
sub load_and_write_file {
##################################################################
    my ($todo, $toRetr, $dbname, $out, $redo) = @_;

    my $indexfile = $tmpFile . '.idx';
    unlink $indexfile if -e $indexfile; 

    my $gbindex = Bio::Index::GenBank->new(-file=> $indexfile,
                                           -write_flag=>"WRITE");
    eval { $gbindex->make_index($tmpFile) };
    
    if ($@) {
        warn "ERROR when performing bioperl genbank index: $@\n" if $verbose;
	return;
    }

    for my $xref (@$todo) {

        my $bioseqObj = $gbindex->fetch($xref);

	if ($bioseqObj) {

	    for my $acc ( keys %{$toRetr->{$dbname}->{$xref}}) {
		&load_sequence($toRetr->{$dbname}->{$xref}->{$acc}, NCBISRC, $bioseqObj);
				
                #write sequence to output file in fasta
		if (defined $outfh) {
		    print $outfh ">${dbname}|${acc} NCBI:${xref}\n";
		    print $outfh $gbindex->get_Seq_by_acc($xref)->seq . "\n";
		}
	    }
    	} else {
    	    $redo->{$dbname}->{$xref} = $toRetr->{$dbname}->{$xref};
    		
	    if ($verbose) {
	    	warn("FAIL_PARSE_SEQ_NCBI\t$dbname|". 
			     join(',', keys %{$toRetr->{$dbname}->{$xref}}) ."\t$xref\n");
	    	open(TEMP, $tmpFile) or die "Can not open $tmpFile\n";
	    	my @lines = <TEMP>;
	    	close TEMP;
		warn(join("\n", @lines)) ;
	    }
	}
    }
}

##################################################################
sub batch_retrieval_ncbi {
##################################################################
    my $ids = shift;
    
    my %params = ( 'db' => 'protein',
		   'retmax' => BATCH,
	           'term' => join(',', @$ids),
#		   'verbose' => 1,
	           'usehistory' => 'y'
		  );

    my $results;

#    for (my $i=0; $i<TRY; $i++) {
#	$results = &esearch(\%params);
#	last if ($$results{'query_key'} && $$results{'WebEnv'});
#    }

    my %params4 = ('db' => $params{'db'},
		   'id' => join(',',@$ids),
#                   'query_key' => $$results{'query_key'},
#                   'WebEnv' => $$results{'WebEnv'},
                   'retmode' => 'text',
#                   'rettype' => 'genbank',
                   'rettype' => 'gb',
	           'retstart' => 0,
                   'retmax' => BATCH,
#		   'verbose' => 1,
                   'outfile' => $tmpFile
		   );
#    if  ($$results{'query_key'} && $$results{'WebEnv'}) {
        &efetch(\%params4);  #download saved in tmp file
	return 1;
#    } else {
#	warn("FAIL_BATCH_NCBI: ". join(',', @$ids) ."\n") if $verbose;
#	return 0;
#    }
}

######################################################################
sub esearch {
######################################################################
    my $params = shift;

    my @paramstr;
    while (my ($k, $v) = each %$params) {
	next if ($k eq 'verbose');
	push(@paramstr, "$k=$v");
    }

    my $url = URLBASE . "esearch.fcgi?". join('&', @paramstr);

    warn "\n$url\n\n" if ($$params{'verbose'} or $verbose);

    my $raw = get($url);

    my %results;
    $raw =~ /<QueryKey>(\d+)<\/QueryKey>.*<WebEnv>(\S+)<\/WebEnv>/s;
    $results{'query_key'} = $1;
    $results{'WebEnv'} = $2;
 
    warn "$raw\n" if ($$params{'verbose'} or $verbose);

    return \%results;
}

###################################################################
sub efetch {
###################################################################
# Performs EFetch. 
# Input: %params:
# $params{'db'} - database
# $params{'id'} - UID list (ignored if query_key exists)
# $params{'query_key'} - query key 
# $params{'WebEnv'} - web environment
# $params{'retmode'} - output data format
# $params{'rettype'} - output data record type
# $params{'retstart'} - first record in set to retrieve
# $params{'retmax'} - number of records to retrieve
# $params{'seq_start'} - retrieve sequence starting at this position
# $params{'seq_stop'} - retrieve sequence until this position
# $params{'strand'} - which DNA strand to retrieve (1=plus, 2=minus)
# $params{'complexity'} - determines what data object to retrieve
# $params{'tool'} - tool name
# $params{'email'} - e-mail address
#
# Output: $raw; raw EFetch output

    my $params = shift;

    my @paramstr;
    while (my ($k, $v) = each %$params) {
	next if ($k eq 'outfile');
	push(@paramstr, "$k=$v");
    }

    my $url = URLBASE . "efetch.fcgi?". join('&', @paramstr);

    warn "$url\n" if ($$params{'verbose'} or $verbose);

    my $raw = get($url);

    warn "$raw\n" if ($$params{'verbose'});

    open(OUT, ">$$params{'outfile'}") || die "Can not open $$params{'outfile'} to append: $!";
    print OUT $raw;
    close OUT;
}

##################################################################
sub load_sequence {
##################################################################
# load protein sequence into GO db

    my ($gps, $source, $proteinseq) = @_;

    my $seq = GO::Model::Seq->new;
    $seq->pseq($proteinseq);

    my $xref = GO::Model::Xref->new;
    $xref->xref_key($seq->accession);
    $xref->xref_dbname($source);
    $seq->add_xref($xref);
    $seq->display_id($seq->accession);
    
    for my $gp (@$gps) {
	warn("LOADING " . $seq->accession . " from $source") if $verbose;
	$apph->set_product_seq($gp, $seq);
    }
}

#################################################################
sub print_ncbi_report {
#################################################################
    my ($list, $fh) = @_;

    for my $db (keys %$list) {
	for my $xref (keys %{$list->{$db}}) {
	    for my $acc (keys %{ $list->{$db}->{$xref} }) {
		print $fh "NO_SEQ\t$db:$acc\tNCBI_NP:$xref\n";
	    }
	}
    }
}

#################################################################
sub print_uniprot_report {
#################################################################
    my ($loaded, $alltodo, $fh) = @_;

#    print $fh "UNIPROT fail ids in gp2protein:\n";

    for my $xref ( keys %$alltodo ) {
        for my $acc ( sort keys %{$alltodo->{$xref}->{$uniprotsource}} ) {
	    my $db = $alltodo->{$xref}->{$uniprotsource}->{$acc};
	    
	    unless (exists $loaded->{$db}->{$acc}->{$xref}) {
		print $fh "NO_SEQ\t$db:$acc\tUniProt:$xref\n";
	    }
	}
    }
}

#################################################################
sub usage {
#################################################################
    print "$0  [-d dbname] [-h dbhost]  [-u user] [-p pssd] [-dbsocket mysql.sock] [-swissdir dirname] [-uniprotdir uniprotdir] [-out gp_sequences.fasta] [-log gp2protein_fail.log] [-verbose] [-nouni] gp2protein.*\n";
    print <<EOM;

This script will read from a gp2protein file, download the protein sequences 
from uniprot(local data file) or ncbi(remote) and store sequences and dbxrefs 
in amigo database schema.

It will also write sequences to a fasta file specified on cmd line.

 REQUIREMENTS: You must have bioperl installed; see http://www.bioperl.org

EOM
}
