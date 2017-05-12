#!/usr/local/bin/perl -w

######################################################################
#$Header: /cvsroot/geneontology/go-dev/go-db-perl/scripts/load-sp-bulk.pl,v 1.12 2008/07/21 22:18:55 benhitz Exp $
######################################################################

BEGIN {
	if ( defined( $ENV{GO_ROOT} ) ) {
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

use constant SPROTFILE  => 'uniprot_sprot.dat.gz';
use constant TREMBLFILE => 'uniprot_trembl.dat.gz';
use constant UNIPROTSRC => 'UniProtKB';
use constant NCBISRC    => 'Ncbi';
use constant TMPSPFILE  => '/tmp/load_ncbi_file.tmp';    # for bioperl to parse
use constant SPINDEX    => '/tmp/uniprot_index';         # for bioperl to parse
use constant BATCH => 500;    # tested limit, increase may crash eutil
use constant TRY   => 3;
use constant URLBASE => "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
use constant GUNZIP  => '/bin/gunzip';

if ( !@ARGV ) {
	die usage();
}

use Getopt::Long;

use constant DELIMITER => "\t";    # separates fields

my $TABLES = {
	dbxref => [qw(id xref_dbname xref_key xref_keytype xref_desc)]
	,                              # must append many dbxrefs
	seq =>
	  [qw(id display_id description seq seq_len md5checksum moltype timestamp)],
	seq_dbxref => [qw(seq_id dbxref_id)],
};

die "Must supply -local-infile argument for bulk loading with mysql" unless grep (/local-infile/, @ARGV);
my $apph = GO::AppHandle->connect( \@ARGV );

# get command line arguments
my $cmdoption = {};
GetOptions(
	$cmdoption,
	"help=s",
	#           "speciesdb=s",
	#	   "swissdir=s",
	"uniprotdir=s",
	#           "evcode|e=s@",
	"out=s",
	"log=s",     #failed entries logged here for report to mod
	"verbose+",
	"nouni+",
	"skip",  # if -skip then use existing .txt files
);

my $ncbisource    = NCBISRC;
my $uniprotsource = UNIPROTSRC;

if ( $cmdoption->{help} ) {
	die usage();
}

print STDERR "$0 starts at " . localtime() . "\n";

my $outfh;
if ( $cmdoption->{out} ) {
	$outfh = FileHandle->new( ">" . $cmdoption->{out} );
}

my $logfh;
if ( $cmdoption->{log} ) {
	$logfh = FileHandle->new( ">" . $cmdoption->{log} );
}

#if ($cmdoption->{evcode}) {
#    $apph->filters->{evcodes} = $cmdoption->{evcode};
#}

my $verbose = 0;
$verbose = 1 if ( $cmdoption->{verbose} );

my $nouniprot = 0;
$nouniprot = 1 if ($cmdoption->{nouni});

#my $swissdir = $cmdoption->{swissdir} || "proteomes";

my $uniprotdir = $cmdoption->{uniprotdir} || "uniprot";

my $SPROTFILE  = "$uniprotdir/" . SPROTFILE;
my $TREMBLFILE = "$uniprotdir/" . TREMBLFILE;
unless ( -e $SPROTFILE ) {
	die $SPROTFILE . " does not exist.\n";
}

unless ( -e $TREMBLFILE ) {
	die $TREMBLFILE . " does not exist.\n";
}

# go through uniprot file to find id

my @unifiles = ( $SPROTFILE, $TREMBLFILE );
my $idxFile = SPINDEX . '.' . $$ . '.idx'; #multiple process may run this script
unlink $idxFile if ( -e $idxFile );


###################################################################
# Load all sequences in UniProt files by mysql_local_infile
###################################################################
my $countfound = 0;

my $loadSuccess = {};    # For uniprot, {mod_db}->{mod_acc}->{uniprot_xref}

my %FH;                  # hash of filehandles for flat  database table
my %ID;                  # hash of ids (primary keys) for database tables

showtime();
print STDERR " Getting dbxref2id_h...\n";
$apph->dbxref2id_h;
my $n = scalar( keys %{ $apph->dbxref2id_h } ) - 1;
$ID{dbxref} = $apph->dbxref2id_h->{max};
print STDERR "Found: $n DB_NAME entries in DBXREF starting at ",$ID{dbxref}," \n";
showtime();

if ($cmdoption->{skip}) {

    print STDERR "Skipping UniProt dumping, using existing files\n";

} else {
    for my $tabName ( keys(%$TABLES) ) {

	$FH{$tabName} = FileHandle->new(">$tabName.txt");
	$ID{$tabName} = 0 unless $ID{$tabName};

    }

    &index_uniprot(\@unifiles);
    
}
eval {
	print STDERR "LOADING TABLES for seqdb...";
	$apph->bulk_load( $TABLES, DELIMITER);

};
if ($@) {
	print STDERR "Bulk loading of uniprot failed $@" ;

} else {

	print STDERR "seqdb (UniProt) LOADED.\n";
}

# all tables should be created now,

$apph->commit;    # not sure if this is necessary for load data infile.

# open all gp2protein files and archive all ids for retrieval
my $Xref_hashref =
  {}; # {xrefid} {source} {modacc} = speciesdb - for bulk loading only used for NCBI.
my $dupCount   = 0;
my $totalCount = 0;

my $tmpFile = TMPSPFILE . '.' . $$;    #multiple process may run this script
unlink $tmpFile if ( -e $tmpFile );

# read gp2protein files.
&read_gp2protein( $logfh, $Xref_hashref, $apph, $cmdoption, @ARGV );

###################################################################
# Deal with NCBI ids
###################################################################

my %ToRetrieve;

for my $xref ( keys %$Xref_hashref ) {
	for my $modacc ( sort keys %{ $Xref_hashref->{$xref}->{$ncbisource} } ) {
		my $speciesdb = $Xref_hashref->{$xref}->{$ncbisource}->{$modacc};
		my $gpAref = $apph->get_products(
										  {
											xref => {
													  xref_key    => $modacc,
													  xref_dbname => $speciesdb
											}
										  }
		);

		if (@$gpAref) {
			my $ncbiacc = $xref;
			$ncbiacc =~ s/\.\d+$//;    #remove version

			$ToRetrieve{$speciesdb}{$ncbiacc}{$modacc} = $gpAref;
		}
	}
}

for ( my $i = 0 ; $i < 3 ; $i++ ) {    #redo failed ones
	my $redo = &retrieve_from_ncbi( \%ToRetrieve, $outfh );
	last unless (%$redo);
	%ToRetrieve = %$redo;

	if ( $i == 2 ) {
		&print_ncbi_report( $redo, $logfh ) if ( defined $logfh );
	}
}

$outfh->close if ( defined $outfh );

$logfh->close if ( defined $logfh );

print STDERR  "$0 finishes at " . localtime() . "\n";


##################################################################
sub retrieve_from_ncbi {
##################################################################
	my ( $ToRetrieve, $outfh ) = @_;

	my %Redo = ();
	for my $dbname ( keys %$ToRetrieve ) {

		my @ids = sort keys %{ $ToRetrieve->{$dbname} };

		for ( my $i = 0 ; $i < @ids ; $i += BATCH ) {

			#	    unlink $tmpFile if (-e $tmpFile);  # clean before each batch

			my $end = $i + BATCH - 1;
			$end = @ids - 1 if ( $end >= @ids );
			my @todo = @ids[ $i .. $end ];

			print STDERR "BATCH: " . join( ',', @todo ) . "\n"  if $verbose;

			if ( &batch_retrieval_ncbi( \@todo ) ) {
				&load_and_write_file( \@todo, \%ToRetrieve, $dbname, $outfh,
									  \%Redo );
			}
		}
	}

	return \%Redo;
}

##################################################################
sub load_and_write_file {
##################################################################
	my ( $todo, $toRetr, $dbname, $out, $redo ) = @_;

	my $indexfile = $tmpFile . '.idx';
	unlink $indexfile if -e $indexfile;

	my $gbindex = Bio::Index::GenBank->new(    -file       => $indexfile,
											-write_flag => "WRITE" );
	eval { $gbindex->make_index($tmpFile) };

	if ($@) {
		print STDERR "ERROR when performing bioperl genbank index: $@\n"
		  if $verbose;
		return;
	}

	for my $xref (@$todo) {

		my $bioseqObj = $gbindex->fetch($xref);

		if ($bioseqObj) {

			for my $acc ( keys %{ $toRetr->{$dbname}->{$xref} } ) {
				eval {
					&load_sequence( $toRetr->{$dbname}->{$xref}->{$acc},
									NCBISRC, $bioseqObj );
				};

				if ($@) {
					print STDERR
						  "ERROR_LOADSEQ: ${dbname}|${acc} NCBI:${xref}: $@\n";
					next;
				}

				#write sequence to output file in fasta
				if ( defined $outfh ) {
					print $outfh ">${dbname}|${acc} NCBI:${xref}\n";
					print $outfh $gbindex->get_Seq_by_acc($xref)->seq . "\n";
				}
			}
		} else {
			$redo->{$dbname}->{$xref} = $toRetr->{$dbname}->{$xref};

			if ($verbose) {
				print STDERR "FAIL_PARSE_SEQ_NCBI\t$dbname|"
							. join( ',', keys %{ $toRetr->{$dbname}->{$xref} } )
							. "\t$xref\n" ;
				open( TEMP, $tmpFile ) or die "Can not open $tmpFile\n";
				my @lines = <TEMP>;
				close TEMP;
				print STDERR join( "\n", @lines ) ;
			}
		}
	}
}

##################################################################
sub batch_retrieval_ncbi {
##################################################################
	my $ids = shift;

	my %params = (
		'db'     => 'protein',
		'retmax' => BATCH,
		'term'   => join( ',', @$ids ),

		#		   'verbose' => 1,
		'usehistory' => 'y'
	);

	my $results;

	for ( my $i = 0 ; $i < TRY ; $i++ ) {
		$results = &esearch( \%params );
		last if ( $$results{'query_key'} && $$results{'WebEnv'} );
	}

	my %params4 = (
		'db'        => $params{'db'},
		'query_key' => $$results{'query_key'},
		'WebEnv'    => $$results{'WebEnv'},
		'retmode'   => 'text',
		'rettype'   => 'genbank',
		'retstart'  => 0,
		'retmax'    => BATCH,

		#		   'verbose' => 1,
		'outfile' => $tmpFile
	);
	if ( $$results{'query_key'} && $$results{'WebEnv'} ) {
		&efetch( \%params4 );    #download saved in tmp file
		return 1;
	} else {
		print STDERR "FAIL_BATCH_NCBI: " . join( ',', @$ids ) . "\n" 
		  if $verbose;
		return 0;
	}
}

######################################################################
sub esearch {
######################################################################
	my $params = shift;

	my @paramstr;
	while ( my ( $k, $v ) = each %$params ) {
		next if ( $k eq 'verbose' );
		push( @paramstr, "$k=$v" );
	}

	my $url = URLBASE . "esearch.fcgi?" . join( '&', @paramstr );

	print STDERR "\n$url\n\n" if ( $$params{'verbose'} or $verbose );

	my $raw = get($url);

	my %results;
	$raw =~ /<QueryKey>(\d+)<\/QueryKey>.*<WebEnv>(\S+)<\/WebEnv>/s;
	$results{'query_key'} = $1;
	$results{'WebEnv'}    = $2;

	print STDERR "$raw\n" if ( $$params{'verbose'} or $verbose );

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
	while ( my ( $k, $v ) = each %$params ) {
		next if ( $k eq 'outfile' );
		push( @paramstr, "$k=$v" );
	}

	my $url = URLBASE . "efetch.fcgi?" . join( '&', @paramstr );

	print STDERR "$url\n" if ( $$params{'verbose'} or $verbose );

	my $raw = get($url);

	print STDERR "$raw\n" if ( $$params{'verbose'} );

	open( OUT, ">$$params{'outfile'}" )
	  || die "Can not open $$params{'outfile'} to append: $!";
	print OUT $raw;
	close OUT;
}

##################################################################
sub load_sequence {
##################################################################
	# load protein sequence into GO db, usually a NCBI seq.

	my ( $gps, $source, $proteinseq ) = @_;

	my $seq = GO::Model::Seq->new;
	$seq->pseq($proteinseq);

	my $xref = GO::Model::Xref->new;
	$xref->xref_key( $seq->accession );
	$xref->xref_dbname($source);
	$seq->add_xref($xref);
	$seq->display_id( $seq->accession );

	for my $gp (@$gps) {
		warn( "LOADING " . $seq->accession . " from $source" ) if $verbose;
		$apph->set_product_seq( $gp, $seq );
	}
}

##################################################################
sub map_gp_to_seq {
##################################################################
	# match GPs in gp2protein to uniref or NCBI loaded sequence

	my ( $xrefid, $source, $modacc, $speciesdb ) = @_;
	my $seq = $apph->get_seq( { dbxref_xref_key  => $xrefid } );

	unless ($seq) {
	    print STDERR "ERROR: Sequence could not be found for $xrefid, skipping...\n";
	    return 0;
	}

	my $gpAref = $apph->get_products(
								   {
									 xref => {
											   xref_key    => $modacc,
											   xref_dbname => $speciesdb
									 }
								   }
	);

	if ( !@$gpAref ) {
	    print STDERR "ERROR: $modacc $speciesdb not in db\n";
		return 0;
	} elsif ( @$gpAref > 1 ) {
		print STDERR "WARNING: " . @$gpAref . " >1 match $modacc $speciesdb\n"  if $verbose;
	}

	for my $gp (@$gpAref) {
		print STDERR
				"MAPPING " . $seq->display_id . " to $modacc" . " from $source\n" 
		  if $verbose;
		$apph->set_product_seq( $gp, $seq );
	}
	return 1;
}

#################################################################
sub print_ncbi_report {
#################################################################
	my ( $list, $fh ) = @_;

	for my $db ( keys %$list ) {
		for my $xref ( keys %{ $list->{$db} } ) {
			for my $acc ( keys %{ $list->{$db}->{$xref} } ) {
				print $fh "NO_SEQ\t$db:$acc\tNCBI_NP:$xref\n";
			}
		}
	}
}

#################################################################
sub read_gp2protein {
#################################################################

        my $logfh = shift;
        my $Xref_hashref = shift;
	my $apph         = shift;
	my $cmdoption    = shift;
#	my $dbxref2gp    = $apph->dbxref2gp_h;

	print STDERR "Mem Usage: ", qx{ ps -o rss,vsz $$ },"\n" if $verbose;
	while ( my $file = shift @_ ) {
		my $speciesdb;
		if ( $cmdoption->{speciesdb} ) {
			$speciesdb = $cmdoption->{speciesdb};
		} elsif ( $file =~ /gp2protein\.(\w+)\.gz/ ) {
			$speciesdb = $1;
		} elsif ( $file =~ /gp2protein\.(\w+)/ ) {
			$speciesdb = $1;
		} else {
			die("$file not right format; must be gp2protein.SPECIESDB");
		}

		if ($nouniprot && $speciesdb =~ /(unigene|geneid|refseq)/) {
		    warn("Skipping $file, -nouni set");
		    next;
		}
	
		my $filehandle;
		if ( $file =~ /\.gz/ ) {
			$filehandle = FileHandle->new("gzcat $file |")
			  || die "can not gzcat $file: $!";
		} else {
			$filehandle = FileHandle->new($file)
			  || die "can not open $file: $!";
		}

		my @Failed = ();

		my $line_number = 0;
		my $num_failed  = 0;
		print STDERR "Reading $file...\n" if $verbose;
		while ( defined( my $line = <$filehandle> ) ) {
			chomp $line;
			next if $line =~ m/^\!/;    # skip comment line on top
			next unless $line =~ m/\w+/;    # skip empty line

			my ( $modacc, $xrefstr ) = split( /\s+/, $line );

			#xref part can be multiple ids mapped to one modacc
			my @xrefs = split( /;/, $xrefstr );

			$line_number++;
			my $curr_speciesdb = uc $speciesdb;
			my $tmp_speciesdb;

			if ( $modacc =~ m/(\w+)\:(\S+)/ ) {
			    $tmp_speciesdb = uc $1;
			    $modacc         = $2;

		   # format inconsistency of dbxref.xref_key and gp2protein file column1
			    if ( $tmp_speciesdb eq 'MGI' && int($modacc) ) {
				$modacc = "MGI:$modacc";
#			    } elsif ($tmp_speciesdb eq 'RGD' && int($modacc)) { 
#				$modacc = "RGD:$modacc";
			    } elsif ( $tmp_speciesdb eq 'WB' ) {
				$modacc =~ s/^WP://;
			    }
			}

			# skip if no gene product
			unless ( exists $apph->dbxref2gp_h->{$modacc}->{$tmp_speciesdb} ) {
			    print STDERR ( "No gene product for modacc=$modacc speciesdb=$tmp_speciesdb ($curr_speciesdb)\n" ) if $verbose;
			    $num_failed++;
			    next;
			}

			for my $xref (@xrefs) {

				unless ( $xref =~ m/(\S+):(\S+)/ ) {
					print STDERR (
"seq dbxref must be DB:ACC format ($file line: $line_number)\n"
					  )
					  if $verbose;
					$num_failed++;
					next;
				}

				my $source = uc($1);   # NCBI, SWA, UNIPROT
				my $xrefid = $2;       # Accession of uniport or ncbi protein db
				if ( $source =~ m/NCBI/ ) {
					$source = NCBISRC;
				} else {
					$source = UNIPROTSRC;
				}



				if (
					 !&map_gp_to_seq(                $xrefid, $source,
									  $modacc, $tmp_speciesdb )
				  )
				{

					# it's NCBI, populate hash, don't load
					if ( exists $Xref_hashref->{$xrefid}{$source}{$modacc} ) {
						$dupCount++;
					} else {
						$Xref_hashref->{$xrefid}{$source}{$modacc} =
						  $tmp_speciesdb;
					}
				}
				$totalCount++;
			    }
		    }
	    
		print STDERR "Mem Usage: ", qx{ ps -o rss,vsz $$ },"\n" if $verbose;
		close $filehandle;

		if ( defined $logfh ) {
				print $logfh "$file: $num_failed entries skipped.\n";
			}
	    }

	my $numToLoad = keys %$Xref_hashref;
	
	if ( $numToLoad > 0 ) {
	    print STDERR "Number to load (NCBI): $numToLoad.\n" if $verbose;
	}
    
    }

#################################################################
	sub dump_table {
#################################################################

		my $tab       = shift;
		my $fieldsRef = shift;

		die "Don't know anything about $tab"
		  if ( !$TABLES->{$tab} || !scalar( @{ $TABLES->{$tab} } ) );

		die "Tried to write wrong number of fields $tab"
		  if scalar(@$fieldsRef) != scalar( @{ $TABLES->{$tab} } );

		my $fh = $FH{$tab};

		print $fh ( join( DELIMITER, @$fieldsRef ) );
		print $fh "\n";
	}
#################################################################
       sub index_uniprot {
#################################################################

	   my $unifiles = shift;

	   my @unzipped = ();
	   print STDERR "Unzipping UniProt files...\n";

	   for my $file (@$unifiles) {
	       my $fn = $file;
	       $fn =~ s/\.gz//;
	       system("gzcat $file > $fn") unless -e "$fn";
	       push @unzipped, $fn;
	   }

	   showtime();

	   my $uniprotid  = '';
	   my $accession  = '';
	   my $matchid    = '';    # in gp2protein
	   my $save_flag  = 0;
	   my %foundIds   = ();    # use to load xref table
	   my $entrysaved = '';
	   my $seqsection = 0;

	   print STDERR "Indexing Uniprot files...\n";
	   my $spindex = Bio::Index::Swissprot->new( -file       => $idxFile,
						     -write_flag => 1 );

	   $spindex->make_index(@unzipped);

	   print STDERR "Found ", $spindex->count_records, " records in DBM.\n";
	   showtime();

	   for my $k ( $spindex->get_all_primary_ids ) {

	       next if $k =~ /^__/; # dbm internal hash;
	       my $source    = UNIPROTSRC;
	       my $bioseqObj = undef;
	       eval { $bioseqObj = $spindex->fetch($k); };
	       if ($@) {
		   print STDERR "Error getting object for $k, skipping\n";
		   next;
	       }

	       if ($bioseqObj) {
		   my $seq = GO::Model::Seq->new;
		   $seq->pseq($bioseqObj);
		   dump_table(
			      'seq',
			      [
			       ++$ID{seq},   $seq->display_id,
			       $seq->desc,   $seq->residues,
			       $seq->length, $seq->md5checksum,
			       '\N',         '\N',
			       ]
			      );

		   my $dbxrefId;
		   unless ( $dbxrefId =
			    $apph->dbxref2id_h->{$source}->{ $seq->accession } )
		   {

			    dump_table(
						    'dbxref',
						    [
						       ++$ID{dbxref}, $source, $seq->accession, '\N', '\N',
						    ]
			    );

			    $apph->dbxref2id_h->{$source}->{ $seq->accession } = $ID{dbxref};
			    $dbxrefId = $ID{dbxref};
		    }

		   dump_table( 'seq_dbxref', [ $ID{seq}, $dbxrefId, ] );
		   
	       }

	   }
	   showtime();

}
#################################################################
	sub showtime {
#################################################################
		my $t   = time;
		my $ppt = localtime $t;
		print STDERR "$t $ppt ";
	}
#################################################################
sub usage {
#################################################################
    print "$0  [-d dbname] [-h dbhost]  [-u user] [-p pssd] [-dbsocket mysql.sock] [-swissdir dirname] [-uniprotdir uniprotdir] [-out gp_sequences.fasta] [-log gp2protein_fail.log] [-verbose] gp2protein.*\n";
    print <<EOM;

This script will read from a gp2protein file, download the protein sequences 
from uniprot(local data file) or ncbi(remote) and store sequences and dbxrefs 
in amigo database schema.

It will also write sequences to a fasta file specified on cmd line.

 REQUIREMENTS: You must have bioperl installed; see http://www.bioperl.org

EOM
}

