#!/usr/local/bin/perl -w

use strict;

use GO::Parser;
use GO::AppHandle;
use Data::Stag;
use Getopt::Long;
use Data::Dumper;

if ($ARGV[0] =~ /^\-h/) {
    system("perldoc $0");
    exit;
}
my $apph = GO::AppHandle->connect(\@ARGV);

my $errf;
my $replace;
my $append;
my $fill_count;
my $no_optimize;
my $no_clear_cache;
my $ev;
my $handler_class = 'obo_godb_flat'; # writes flat files to be loaded by mysql
my $dtype = 'go_assoc';

my @tables = qw(association_qualifier association db dbxref evidence_dbxref evidence gene_product_synonym gene_product term association_species_qualifier);  # this must match %TABLES hash in GO::Handlers::obob_godb_flat.pm

my $fmt_arg = "";
if ($ARGV[0] =~ /^\-format/) {
    shift @ARGV;
    $fmt_arg = "-p " . shift @ARGV;
}

# parse global arguments
my @args = ();
while (@ARGV) {
    my $arg = shift @ARGV;
    if ($arg =~ /^\-e$/ || $arg =~ /^\-error$/) {
        $errf = shift @ARGV;
        next;
    }
    push(@args, $arg);
}


# send XML errors to STDERR by default
my $errhandler = Data::Stag->getformathandler('xml');
if ($errf) {
    $errhandler->file($errf);
}
else {
    $errhandler->fh(\*STDERR);
}

my $generic_parser = new GO::Parser ({handler=>$handler_class});
$generic_parser->errhandler($errhandler);

# uncompress any compressed files
my @files = $generic_parser->normalize_files(@args);

# want a single parser for all files... yay RAM!
my $load_parser = GO::Parser->new({format=>$dtype,handler=>$handler_class});
    
$load_parser->handler->apph($apph);
$load_parser->errhandler($errhandler);

for my $append (qw(dbxref term species db)) {

    my $val = $load_parser->handler->apph->get_autoincrement($append);
    $load_parser->handler->{pk}->{$append} = $val;
    # set initial ID values for these tables since we need to append them
}

showtime();
warn " Getting dbxref2id_h...\n";
$load_parser->handler->apph->dbxref2id_h;
my $countDbx = scalar (keys %{$load_parser->handler->apph->dbxref2id_h}) - 1;
warn "Found: $countDbx  DB_NAME entries in DBXREF";

showtime();
warn " Getting dbxref2gpid_h...\n";
$load_parser->handler->apph->dbxref2gpid_h;
warn "Found: ".scalar (keys %{$load_parser->handler->apph->dbxref2gpid_h})." GP entries in DBXREF";
showtime();

warn " Getting acc2id_h...\n";
$load_parser->handler->apph->acc2id_h;
warn "Found: ".scalar (keys %{$load_parser->handler->apph->acc2id_h})." TERM entries";

showtime();
warn " Getting source2id_h...\n";
$load_parser->handler->apph->source2id_h;
warn "Found: ".scalar (keys %{$load_parser->handler->apph->source2id_h})." SOURCE (DB) entries";

showtime();
warn " Getting taxon2id_h...\n";
$load_parser->handler->apph->taxon2id_h;
warn "Found: ".scalar (keys %{$load_parser->handler->apph->taxon2id_h})." SPECIES entries";

#print STDERR Dumper($load_parser->handler->apph->taxon2id_h);

# these four hashes are needed to store primary keys already in the DB.



while (@files) {

    my $fn = shift @files;
    if ($fn =~ /^\-fill_count/) {
	$fill_count = 1;
	next;
    }
    if ($fn =~ /^\-no_optimize/) {
	$no_optimize = 1;
	next;
    }
    if ($fn =~ /^\-no_clear_cache/) {
	$no_clear_cache = 1;
	next;
    }
    if ($fn =~ /^\-append/) {
	$append = 1;
	next;
    }
    if ($fn =~ /^\-replace/) {
	$replace = 1;
	next;
    }
    if ($fn =~ /^\-handler/) {
        $handler_class = shift @files;
        next;
    }
    if ($fn =~ /^\-ev/) {
        $ev = shift @files;
	print STDERR "ev flag set: $ev\n";
        next;
    }


    $load_parser->skip_uncurated(1) if ($ev && $ev =~ /!IEA/i);

    showtime();

    # this could possibly be done once at the beginning, not every file
    # but I'm not sure exactly what it is needed for.
    $apph->reset_acc2name_h;
    $load_parser->acc2name_h($apph->acc2name_h);

#acc2name_h is GO::AppHandles::AppHandleSqlImpl    
    printf STDERR "Valid terms in checklist: %d\n",
      scalar(keys %{$load_parser->acc2name_h || {}});
    
    # fire events from file to $handler
    $load_parser->parse($fn);
    #$fh->close || die ("problem with pipe: $cmd");
    

    showtime();
    print STDERR "READY FOR LOAD: $fn\n";
}

$load_parser->handler->close_files;

eval {
    print STDERR "LOADING TABLES...";
    $apph->bulk_load($load_parser->handler->tables,'\t');

};
if ($@) {
    $generic_parser->err(msg=>"Bulk loading failed $@");

} else {

    print STDERR "LOADED.\n";
}

# all tables should be created now, 

$apph->commit;  # not sure if this is necessary for load data infile.

if ($fill_count) {
    eval {
        $apph->fill_count_table;
    };
    if ($@) {
        $generic_parser->err(msg=>"(FAO Developers: Error making counts: $@");
    }
}

sub showtime {
    my $t=time;
    my $ppt = localtime $t;
    print STDERR "$t $ppt ";
}


__END__

=head1 NAME

load-go.pl

=head1 SYNOPSIS

  load-go.pl -d go -h mydbserver -datatype go_ont *.ontology

=head1 DESCRIPTION

Loads GO data (ontology files, def files, xref files, assoc files)
into a GO database. Will also perform additional housekeeping tasks on
database if required

=head1 MODULES AND SOFTWARE REQUIRED

You will need the 'xsltproc' executable, which is part of libxslt

(You will have this if you have already installed XML::LibXSLT)

You need to have B<both> go-perl and go-db-perl installed

L<http://www.godatabase.org/dev> contains further details on these two modules

This site also has details on the GO database

=head1 ARGUMENTS

  -d DBNAME

  -h DBSERVER

  -datatype FORMAT
     (see below)

  -schema SCHEMA
     by default: godb
     Other values: chado

     Support for the chado schema is in beta. See http://www.gmod.org/chado

  -dbms DRIVER
     by default: mysql
     other values: Pg

     Support for PostgreSQL is in beta

  -append
     by default this script assumes you are loading a dataset for
     the FIRST time. it performs only SQL INSERTs in certain
     cases rather than checking with SELECT if it needs to update.
     
     if you are loading the same file for the second time, use
     this option. the loading will be slightly slower, but it
     will append to existing data

     You should use this option if you are loading multiple
     ontology files in one go!

  -no_optimize
     by default, loading will be optimized; certain primary keys in
     the db will be cached, and certain tables will be INSERTED straight
     into without doing an initial SELECT (the presumption is that these
     datatypes would only be loaded once). See L<GO::Handlers::godb> for
     details.
     If this is turned off, then all data will follow the 
     SELECT followed by UPDATE or INSERT pattern
     This will be slower, but will use less memoty as no cache is required

  -no_clear_cache
     by default the in-memory cache (which reduced SQL lookups) is cleared
     after every single file is loaded. This is to prevent massive caches
     when we load all association files in a single command line.
     If you have plenty of memory, or aren't loading too many assoc
     files you may wish to use this option

  -fill_path
     (TRUE by default, IF an ontology file is parsed)
     
     populates the graph_path transitive closure table on completion

     this option can be used without any files as arguments to
     fill the path table in an already term-populated db

  -no_fill_path

     prevents graph_path table being populated after the ontologies
     have been loaded

  -fill_count

     populates the gene_product_count after all files have been loaded

  -add_root

     adds an explicit root term

     this may be necessary for loading from gene_ontology.obo which
     has 3 ontologies - it can be useful to make a fake root term
     covering these

     NOT FUNCTIONAL - CURRENTLY DONE AUTOMATICALLY

  -append

     you must use this option if you wish to append to data of the
     same type in an already loaded database; it switches off
     bulkloading option

  -replace

     removes all data of the same datatype before loading

  -ev
   
     filters based on an evidence type
     to filter out IEAs, use the not '!' prefix

         -ev '!IEA'
     

=head1 DATATYPES

specify these with the B<-datatype> option

=head2 go_ont

A GO ontology file.

After loading is completed, the path/closure table will be built

=head2 go_def

A GO.defs definitions file

=head2 go_xref

A GO xrefs file; eg ec2go

=head2 go_assoc

A gene_associations file

If you also specify the -fill_count option the gene_product_count table will also get populated (this is done at 

You can also specify the -ev command to filter out specific evidence codes; for example

  load-go.pl -d go -h mydbserver -datatype go-ontology *.ontology
  
=head2 obo

An obo formatted file

=head1 HOW IT WORKS

First the input file is converted into its native XML format (eg
OBO-XML). That native XML format is transformed to an XML format
isomorphic to the GO relational database using an XSLT
stylesheet. This transformed XML is then loaded using DBIx::DBStag

=head1 SEE ALSO

  go-dev/xml/xsl/oboxml_to_godb_prestore.xsl
  L<DBIx::DBStag>
  L<GO::Parser>

=head1 NOTES

When loading gene_association files, will split large files into
multiple smaller files and load these

=cut

