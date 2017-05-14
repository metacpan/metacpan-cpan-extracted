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
           "subset=s",
           "id=s@",
           "partial",
           "to=s",
           "namespace=s",
           "filter_code=s",
           "use_cache",   # auto pass-through
	  );

if ($opt->{help}) {
    system("perldoc $0");
    exit;
}

my $filter_sub;

# functional-programming style filters
if ($opt->{filter_code}) {
    $filter_sub = eval $opt->{filter_code};
}
if ($opt->{namespace}) {
    die "cannot use filter_code combined with namespace option" 
      if $filter_sub;
    $filter_sub = sub {
        shift->namespace eq $opt->{namespace};
    };
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
my $subset = $opt->{subset};
my $partial = $opt->{partial};

if (!defined $partial) {
    $partial = 1 if $subset;
}


my @files = GO::Parser->new->normalize_files(@ARGV);
if (!@files) {
    print STDERR "You must specify at least one ontology file!\n";
    exit 1;
}
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
    $parser->litemode(1) if $opt->{litemode};
    $parser->errhandler($errhandler);
    $parser->parse($fn);
    my $g = $parser->handler->graph;

    my @terms = map {$g->get_term($_) || die("no such id:$_")} @ids;
    if ($subset) {
        my $terms_in_subset =
          $g->get_terms_by_subset($subset);
        push(@terms, @$terms_in_subset);
    }
    if ($filter_sub) {
        push(@terms,
             grep {$filter_sub->($_)} @{$g->get_all_terms});
    }
    my $subg = $g->subgraph_by_terms(\@terms,{partial=>$partial});
    $subg->export({format=>$opt->{to} || 'obo'});
}
$errhandler->finish;
exit 0;

__END__

=head1 NAME

go-filter-subset.pl - extracts a subgraph from an ontology file

=head1 SYNOPSIS

  go-filter-subset.pl -id GO:0003767 go.obo

  go-filter-subset.pl -id GO:0003767 -to png go.obo | xv -

  go-filter-subset.pl -filter_code 'sub{shift->name =~ /transcr/}' go.obo

=head1 DESCRIPTION

Exports a subset of an ontology from a file. The subset can be based
on a specified set of IDs, a preset "subset" filter in the ontology
file (eg a GO "slim" or subset), or a user-defined filter.

The subset can be exported in any format, including a graphical image

=head1 ARGUMENTS

=over

=item -id ID

ID to use as leaf node in subgraph. All ancestors of this ID are
included in the exported graph (unless -partial is set)

Multiple IDs can be passed

  -id ID1 -id ID2 -id ID3 ....etc

=item -subset SUBSET_ID

Extracts a named subset from the ontology file. (only works with obo
format files). For example, a specific GO slim

ONLY terms belonging to the subset are exported - the -partial option
is automatically set

=item -namespace NAMESPACE

only terms in this namespace

=item -filter_code SUBROUTINE

B<advanced option>

A subroutine with which the L<GO::Model::Term> object is tested for
inclusion in the subgraph (all ancestors are automatically included)

You should have an understanding of the go-perl object model before
using this option

Example:

  go-filter-subset -filter_code 'sub {shift->namespace eq 'molecular_function'}' go.obo

(the same things can be achieved with the -namespace option)

=item -partial

If this is set, then only terms that match the user query are
included. Parentage is set to the next recursive parent node in the
filter

For example, with the -subset option: if X and Y belong to the subset,
and Z does not, and X is_a Z is_a Y, then the exported graph withh
have X is_a Y

=item -use_cache

If this switch is specified, then caching mode is turned on.

With caching mode, the first time you parse a file, then an additional
file will be exported in a special format that is fast to parse. This
file will have the same filename as the original file, except it will
have the ".cache" suffix.

The next time you parse the file, this program will automatically
check for the existence of the ".cache" file. If it exists, and is
more recent than the file you specified, this is parsed instead. If it
does not exist, it is rebuilt.

=back

=head2 DOCUMENTATION

L<http://www.godatabase.org/dev>

=cut

