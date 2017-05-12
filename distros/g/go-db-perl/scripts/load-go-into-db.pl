#!/usr/local/bin/perl -w

use strict;

use GO::Parser;
use GO::AppHandle;
use Data::Stag;
use Getopt::Long;

if ($ARGV[0] =~ /^\-h/) {
    system("perldoc $0");
    exit;
}
my $apph = GO::AppHandle->connect(\@ARGV);

# 200000 lines equates roughly to a 500mb xsltproc process
use constant ASSOCFILE_LINE_LIMIT => $ENV{GO_ASSOCFILE_LINE_LIMIT} || 150000;

my $errf;
my $replace;
my $append;
my $fill_count;
my $fill_path;
my $no_fill_path;
my $no_optimize;
my $no_clear_cache;
my $add_root;
my $ev;
my $handler_class = 'godb';
my $reasoner;

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


my $is_parsed_ontology;

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

# gene assoc files are too big for xslt processing; split into smaller files
@files =
  map {
      split_large_assocfile($_);
  } @files;

# parse file list and local arguments
my $dtype;
while (@files) {

    my $fn = shift @files;
    if ($fn =~ /^\-fill_count/) {
	$fill_count = 1;
	next;
    }
    if ($fn =~ /^\-fill_path/) {
	$fill_path = 1;
	next;
    }
    if ($fn =~ /^\-no_fill_path/) {
	$no_fill_path = 1;
	next;
    }
    if ($fn =~ /^\-reasoner/) {
	$no_fill_path = 1;
	$reasoner = 1;
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
    if ($fn =~ /^\-add_root/) {
	$add_root = 1;
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
    if ($fn =~ /^\-datatype/) {
        $dtype = shift @files;
        $fmt_arg = "-p $dtype"; # deprecated
        next;
    }
    if ($fn =~ /^\-ev/) {
        $ev = shift @files;
        next;
    }
    if ($fn =~ /^\-handler/) {
        $handler_class = shift @files;
        next;
    }
    if ($replace) {
        $apph->remove_term_details($fn);
    }

    # if ANY of the files is an ontology
    $is_parsed_ontology = 1
      if !$dtype || $dtype eq 'go_ont' || $dtype =~ /obo/;

    my $this_file_is_an_ontology;
    if ($dtype) {
        $this_file_is_an_ontology = 
          $dtype eq 'go_ont' || $dtype =~ /obo/;
    }

    my $load_parser = GO::Parser->new({format=>$dtype,handler=>$handler_class});
    if ($handler_class eq 'chadodb') {
        $load_parser->xslt('oboxml_to_chadoxml')
          unless $dtype && $dtype eq 'chadoxml';
    }
    else {
        # default: GO DB
        $load_parser->xslt('oboxml_to_godb_prestore');
    }
    $load_parser->handler->apph($apph);
    $load_parser->errhandler($errhandler);

    showtime();

    # Set DBStag optimisations in GO::Handlers::godb
    $load_parser->handler->optimize_by_dtype($dtype,$append) unless $no_optimize;

    # provide parser with an index of term IDs derived
    # from db - this way the
    # parser is aware of illegal entries in xref and assoc files
    $apph->reset_acc2name_h;
    $load_parser->acc2name_h($apph->acc2name_h);
    printf STDERR "Valid terms in checklist: %d\n",
      scalar(keys %{$load_parser->acc2name_h || {}});
    
    # fire events from file to $handler
    $load_parser->parse($fn);
    #$fh->close || die ("problem with pipe: $cmd");
    
    # show statistics
    $load_parser->handler->show_cache;

    # avoid cumulatively large caches
    $load_parser->handler->clear_cache
      unless $no_clear_cache;

    $apph->commit;
    showtime();
    print STDERR "LOADED: $fn\n";
}

# add global root
if ($add_root) {
    $apph->add_root('all');
}

if ($fill_path ||
    ($is_parsed_ontology && !$no_fill_path)) {
    eval {
        $apph->fill_path_table;
    };
    if ($@) {
        $generic_parser->err("(FAO Developers: Error making paths: $@");
    }
}
if ($fill_count) {
    eval {
        $apph->fill_count_table;
    };
    if ($@) {
        $generic_parser->err(msg=>"(FAO Developers: Error making counts: $@");
    }
}
print "\nDone!\n";
exit 0;

sub showtime {
    my $t=time;
    my $ppt = localtime $t;
    print STDERR "$t $ppt ";
}

# break up large assocfiles into a directory of smaller files
#
# breaks occur every ASSOCFILE_LINE_LIMIT, but do NOT
# break in the middle of lines dealing with a gene product
sub split_large_assocfile {
    my $f= shift;
    if ($f !~ /gene_association\.(\S+)/) {
        return $f;
    }
    my $orgdb = $1;
    my ($wc) = (`wc $f` =~ /^\s*(\d+)/);
    chomp $wc;
    print STDERR "WC=$wc\n";
    if ($wc <= ASSOCFILE_LINE_LIMIT) {
        return $f;
    }
    my $splitdir = "$f-splitfiles";
    # remove any previous instance
    if (-d $splitdir) {
        if (system("rm -rf $splitdir")) {
            die "cannot remove $splitdir";
        }
    }
    if (system("mkdir $splitdir")) {
        die "cannot mkdir $splitdir";
    }
    my $fh = FileHandle->new("$f") || die("cannot open $f");
    my $n = 0;
    my $line = 1;
    my $last_gp;
    my $ofh;
    my @new_files = ();
    while (<$fh>) {
        next if /^\!/;
        my ($db, $gp) = /(\w+)\t(\S+)/;

        # if this is the first line OR
        # we have two many lines AND we are no breaking up a gene product
        # THEN start a new part
        if (!$ofh || 
            ($line > ASSOCFILE_LINE_LIMIT && $gp ne $last_gp)) {
            
            $n++;
            $line = 1;
            my $of = "$splitdir/gene_association.$orgdb.part-$n";
            push(@new_files, $of);
            $ofh = FileHandle->new(">$of") || die("cannot write to $of");
        }
        print $ofh $_;
        $last_gp = $gp;
        $line++;
    }
    $fh->close;
    $ofh->close;
    return @new_files;
}

__END__

=head1 NAME

load-go-into-db.pl

=head1 SYNOPSIS

  load-go-into-db.pl -d go -h mydbserver -datatype go_ont *.ontology

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

  load-go-into-db.pl -d go -h mydbserver -datatype go-ontology *.ontology
  
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

