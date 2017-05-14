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

my @files = GO::Parser->new->normalize_files(@ARGV);
while (my $fn = shift @files) {
    eval {
        summarise_file($fn);
    };
    if ($@) {
        $errhandler->err_event(exception=>"$@");
    }
}

sub summarise_file {
    my $fn = shift;
    my %h = %$opt;
    my $fmt;
    if ($fn =~ /\.obo/) {
        $fmt = 'obo_text';
    }
    if ($fn =~ /\.ont/) {
        $fmt = 'go_ont';
    }
    if ($fmt && !$h{format}) {
        $h{format} = $fmt;
    }
    $h{handler} = 'obj';
    my $parser = new GO::Parser(%h);
    $parser->litemode(1);
    $parser->use_cache(1) if $opt->{use_cache};
    $parser->errhandler($errhandler);
    $parser->parse($fn);
    my $g = $parser->handler->graph;
    my %counts = ();
    my %ns_h=();
    foreach my $t (@{$g->get_all_terms}) {
        next if $t->is_obsolete;
        my $ns = $t->term_type;
        if (!$ns) {
            if ($fn =~ /\/(.*)\.\w+/) {
                $ns = $1;
            }
            else {
                $ns = $fn;
            }
        }
        $ns_h{$ns}=1;
        my $acc = $t->acc;
        $counts{term}->{$ns}++;
        my $parent_rels = $g->get_parent_relationships($acc);
        $counts{relationship}->{$ns} += scalar(@$parent_rels);
        my $paths = $g->paths_to_top($acc);
        my $n_paths = scalar(@$paths);
        $counts{path}->{$ns} += $n_paths;
        if ($n_paths >= $counts{pathmax}->{$ns}) {
            $counts{pathmax}->{$ns} = $n_paths;            
            $counts{pathmaxacc}->{$ns} = $acc;            
            $counts{pathmaxname}->{$ns} = $t->name;            
        }


    }
    foreach my $ns (keys %ns_h) {
        printf "%s\n",
          join("\t",
               $fn,
               $ns,
               (map {$counts{$_}->{$ns}} qw(term relationship path)),
               $counts{path}->{$ns}/$counts{term}->{$ns},
               (map {$counts{$_}->{$ns}} qw(pathmax pathmaxacc pathmaxname)),
              );
    }
}
$errhandler->finish;
exit 0;


__END__

=head1 NAME

go-dag-summary

=head1 SYNOPSIS

  go-dag-summary ontology/gene_ontology.obo

=head1 DESCRIPTION

Summarises an ontology

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


=head1 OUTPUT

One row per ontology

Each row has the following columns

=over

=item input filename

=item total no of terms

=item total no of relationships

=item total no of paths

=item avg no of paths per term (p/t)

=item maximum no of paths for any term

=item ID of term with maximum no of paths

NOTE: obsolete terms are not included

=back

=head2 DOCUMENTATION

L<http://www.godatabase.org/dev>

=head2 SEE ALSO

L<http://www.fruitfly.org/~cjm/obol/doc/go-complexity.html>

=cut

