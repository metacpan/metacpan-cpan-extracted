#!/usr/local/bin/perl

# POD docs at end of file

use strict;
use Getopt::Long;
use FileHandle;
use GO::Parser;
use Data::Stag;

$|=1;

my $opt = {};
GetOptions($opt,
	   "help|h",
           "format|p=s",
	   "err|e=s",
           "id=s@",
           "names",
           "use_cache",
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

my @ids = @{$opt->{id} || []};
if (!@ids) {
    print STDERR "specify id list with -id ID option\n";
    exit 1;
}

my @files = GO::Parser->new->normalize_files(@ARGV);
while (my $fn = shift @files) {
    my $fn = shift;
    my %h = %$opt;
    my $fmt;
    if ($fn =~ /\.obo/) {
        $fmt = 'obo_text';
    }
    if ($fmt && !$h{format}) {
        $h{format} = $fmt;
    }
    $h{handler} = 'obj';
    my $parser = new GO::Parser(%h);
    $parser->litemode(1);
    $parser->errhandler($errhandler);
    $parser->parse($fn);
    my $g = $parser->handler->graph;

    foreach my $id (@ids) {
        my $t = $g->get_term($id);
        if (!$t) {
            next;
        }
        printf "%s %s\n", $id, $t->name;
        my $paths = $g->paths_to_top($id) || [];
        foreach my $path (@$paths) {
            printf "  PATH: %s\n",
              $path->to_text($opt->{names} ? () : ('acc'));
        }
    }
}
$errhandler->finish;
exit 0;

__END__

=head1 NAME

go-show-paths-to-root.pl - shows all possible paths from a term to the top

=head1 SYNOPSIS

  go-show-paths-to-root.pl -id GO:0008021 ontology/gene_ontology.obo
  go-show-paths-to-root.pl -names -id GO:0008021 ontology/gene_ontology.obo

=head1 DESCRIPTION

traverses DAG showing all paths (terms and intervening relationships)
to the root

This script is purely file based; it needs to parse the ontology each time

Subsequent parses can be speeded up using the use_cache option

If you wish to use the GO MySQL db, see the script
go-db-show-paths-to-root.pl in the go-db-perl distribution

=head1 ARGUMENTS

=head3 -e ERRFILE

writes parse errors in XML - defaults to STDERR
(there should be no parse errors in well formed files)

=head3 -p FORMAT

determines which parser to use; if left unspecified, will make a guess
based on file suffix. See below for formats

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

=head2 DOCUMENTATION

L<http://www.godatabase.org/dev>

=cut

