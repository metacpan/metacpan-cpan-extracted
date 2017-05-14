#!/usr/local/bin/perl

# POD docs at end of file

use strict;
use Getopt::Long;
use FileHandle;
use Data::Stag;
use GO::Parser;

my $opt = {handler=>'xml'};
GetOptions($opt,
	   "help|h",
           "obo_set",
           "litemode|l",
           "format|p=s",
           "output|o=s",
           "datatype|t=s",
           "xslt|xsl|x=s",
	   "err|e=s",
           "use_cache",
           "handler_args|a=s%",
           "handler|w|writer=s",
	  );

if ($opt->{help}) {
    system("perldoc $0");
    exit;
}

my $errf = $opt->{err};
my $errhandler = Data::Stag->getformathandler('xml');
if ($errf) {
    $errhandler->file($errf);
}
else {
    $errhandler->fh(\*STDERR);
}

# create an initial parser object; we won't actually use this
# to parse; we use this to get the auto-created handler object
my $initial_parser = GO::Parser->new(%$opt);

# user will specify handler option which makes handler object
my $main_handler = $initial_parser->handler;

# some handlers will do something directly (eg make objects or
# write xml); others will go through a stag transform, and
# then onto the user-specified handler
if ($main_handler->can("is_transform") &&
    $main_handler->is_transform) {
    # create handler chain; the inner handler is what the user
    # specifies (eg xml output)
    my $chain_handler =
      Data::Stag->chainhandlers([$main_handler->CONSUMES],
                                $main_handler,
                                'xml');
    # wrap initial handler inside chained handler
    $main_handler = $chain_handler;
}

$main_handler->file($opt->{output}) if $opt->{output};

# unzip etc
my @files = $initial_parser->normalize_files(@ARGV);
my $in_set = 0;
if ($opt->{obo_set} || @files >1) {
    $main_handler->start_event('obo_set');
    $in_set = 1;
}
while (my $fn = shift @files) {
    my %h = %$opt;
    my $fmt;
    if ($fn =~ /\.obo$/) {
        $fmt = 'obo_text';
    }
    if ($fmt && !$h{format}) {
        $h{format} = $fmt;
    }
    my $parser = new GO::Parser(%h);
    $parser->handler($main_handler);
    $parser->litemode(1) if $opt->{litemode};
    $parser->use_cache(1) if $opt->{use_cache};
    $parser->errhandler($errhandler);
    if ($opt->{xslt}) {
        my $xf = $opt->{xslt};
        $parser->xslt($xf);
    }
    $parser->parse($fn);
    $parser->handler->export if $parser->handler->can("export");
}
$errhandler->finish;
$main_handler->finish;
exit 0;

__END__

=head1 NAME

go2fmt.pl
go2obo_xml
go2owl
go2rdf_xml
go2obo_text

=head1 SYNOPSIS

  go2fmt.pl -w obo_xml -e errlog.xml ontology/*.ontology
  go2fmt.pl -w obo_xml -e errlog.xml ontology/gene_ontology.obo

=head1 DESCRIPTION

parses any GO/OBO style ontology file and writes out as a different
format

=head2 ARGUMENTS

=head3 -e ERRFILE

writes parse errors in XML - defaults to STDERR
(there should be no parse errors in well formed files)

=head3 -p FORMAT

determines which parser to use; if left unspecified, will make a guess
based on file suffix. See below for formats

=head3 -w|writer FORMAT

format for output - see below for list

=head3 -|xslt XSLT

The name or filename of an XSLT transform

This can either be an absolute path to a file anywhere on the
filesystem, or it can just be the name of the xslt; eg

  go2fmt.pl -xslt oboxml_to_owl go.obo

If the name is specified, then first of all $GO_ROOT/xml/xsl/*.xsl
will be searched; if GO_ROOT is not set, then the perl modules dir
where GO is installed will be searched (the xslts will be installed
here automatically if you follow the normal install process)

=head2 -use_cache

If this switch is specified, then caching mode is turned on.

With caching mode, the first time you parse a file, then an additional
file will be exported in a special format that is fast to parse. This
file will have the same filename as the original file, except it will
have the ".cache" suffix.

The next time you parse the file, this program will automatically
check for the existence of the ".cache" file. If it exists, and is
more recent than the file you specified, this is parsed instead. If it
does not exist, it is rebuilt.

This will bring a speed improvement for b<some> of the output formats
below (such as pathlist). Most output formats work with event-based
parsing, so caching the object brings no benefit and will in fact be
slower than bypassing the cache

=head2 FORMATS

writable formats are

=over

=item go_ont

Files with suffix ".ontology"

These store the ontology DAGs

=item go_def

Files with suffix ".defs"

=item go_xref

External database references for GO terms

Files with suffix "2go" (eg ec2go, metacyc2go)

=item go_assoc

Annotations of genes or gene products using GO

Files with prefix "gene-association."

=item obo_text

Files with suffix ".obo"

This is a new file format replacement for the existing GO flat file
formats. It handles ontologies, definitions and xrefs (but not
associations)

=item obo_xml

Files with suffix ".obo.xml" or ".obo-xml"

This is the XML version of the OBO flat file format above

=item prolog

prolog facts - you will need a prolog compiler/interpreter to use
these. You can reason over these facts using Obol or the forthcoming
Bio-LP project

=item tbl

simple (lossy) tabular representation

=item summary

can be used on both ontology files and association files

=item pathlist

shows all paths to the root

=item owl

OWL format (default: OWL-DL)

OWL is a W3C standard format for ontologies

You will need the XSL files from the full go-dev distribution to run
this; see the XML section in L<http://www.godatabase.org/dev>

=item obj_yaml

a YAML representation of a GO::Model::Graph object

=item obj_storable

A dump of the perl L<GO::Model::Graph> object. You need L<Storable>
from CPAN for this to work. This is intended to cache objects on the
filesystem, for fast access. The obj_storable representation may not
be portable

=item text_html

A html-ified OBO output format

=item godb_prestore

XML that maps directly to the GODB relational schema
(can then be loaded using stag-storenode.pl)

=item chadodb_prestore

XML that maps directly to the Chado relational schema
(can then be loaded using stag-storenode.pl)

=back

=head2 DOCUMENTATION

L<http://www.godatabase.org/dev>

=cut

