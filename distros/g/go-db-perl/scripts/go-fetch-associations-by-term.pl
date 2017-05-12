#!/usr/local/bin/perl

# POD docs at end of file

use strict;
use Getopt::Long;
use FileHandle;
use GO::AppHandle;
use GO::IO::ObanOwl;

$|=1;


if (!@ARGV) {
    system("perldoc $0");
    exit 1;
}

use Getopt::Long;

my $apph = GO::AppHandle->connect(\@ARGV);
my $opt = {};
GetOptions($opt,
	   "help|h",
           "id=s@",
           "query|q=s%",
           "denormalized",
           "writer|w=s",
           "use_property|p=s@",
	  );

if ($opt->{help}) {
    system("perldoc $0");
    exit;
}

my $search = "@ARGV";
my $query = $opt->{query} || {};
if ($search) {
    $query->{search} = $search;
}
if ($opt->{id}) {
    $query->{acc} = $opt->{id};
}

my $gp_h = {};
my $terms = $apph->get_terms_with_associations($query);

my $writer = $opt->{writer};
if ($writer) {
    if ($writer = 'obanowl') {
        my $io = GO::IO::ObanOwl->new;
        $io->write_all(-terms=>$terms);
    }
    else {
        die $writer;
    }
    exit 0;
}

foreach my $term (@$terms) {
    my $assocs = $term->association_list;
    foreach my $assoc (@$assocs) {
        my $gp = $assoc->gene_product;
        $gp_h->{$gp->id}->{obj} = $gp;
        $gp_h->{$gp->id}->{term_h}->{$term->acc} = $term;
    }
}
my @gps = 
  sort {$a->symbol cmp $b->symbol} map {$gp_h->{$_}->{obj}} keys %$gp_h;

my $use_prop = $opt->{use_property};
foreach my $gp (@gps) {
    my $ph = $gp->properties || {};
    my @vals =
      ($gp->xref->dbname,
       $gp->xref->accession,
       $gp->symbol,
       $gp->full_name,
      );
    if ($use_prop) {
        foreach (@$use_prop) {
            push(@vals,
                 join('; ',
                      @{$ph->{$_} || []}));
        }
    }
    else {
        push(@vals,
             join('; ',
                  map {
                      my $k=$_;
                      map {
                          sprintf('%s "%s"', $k, $_)
                      } @{$ph->{$k} || []}
                  } keys %$ph
                 )
            );
    }

    my $id = $gp->id;
    my $term_h = $gp_h->{$id}->{term_h} || {};
    my @term_accs = sort {$a cmp $b} keys %$term_h;
    if ($opt->{denormalized}) {
        foreach (@term_accs) {
            printrow(@vals, $_, $term_h->{$_}->name);
        }
    }
    else {
        push(@vals,
             join('; ',
                  map {sprintf('%s "%s"', $_, $term_h->{$_}->name)} @term_accs
                 ));
        printrow(@vals);
    }
}
exit 0;

sub printrow {
    my @vals = @_;
    @vals = map {s/\t/\\t/;s/\n/\\n/;$_} @vals;
    print join("\t", @vals),"\n";
    return;
}

__END__

=head1 NAME

go-fetch-associations-by-terms.pl - queries db for associations to terms

=head1 SYNOPSIS

  go-fetch-associations-by-terms.pl -d go -h localhost "cysteine*"

  go-fetch-associations-by-terms.pl -d go -id GO:0008234 -id GO:003693

  go-fetch-associations-by-term.pl -d go_load -denormalized -q type=biological_process -q "search=cysteine*"

  go-fetch-associations-by-term.pl -d go_load -q "where=term.name like '%neuroderm%' or term.name like '%procephalic%'"

=head1 DESCRIPTION

Queries db for associations to queried terms. Traverses DAG to get
recursive associations

=head1 ARGUMENTS

Arguments are either connection arguments, generic to all go-db-perl
scripts, and arguments specific to this script

=head2 CONNECTION ARGUMENTS

Specify db connect arguments first; these are:

=over

=item -dbname [or -d]

name of database; usually "go" but you may want point at a test/dvlp database

=item -dbuser 

name of user to connect to database as; optional

=item -dbauth

password to connect to database with; optional

=item -dbhost [or -h]

name of server where the database server lives; see
http://www.godatabase.org/dev/database for details of which servers
are active. or you can just specify "localhost" if you have go-mysql
installed locally

=back

=head2 SCRIPT ARGUMENTS

=over

=item -id ID

GO/OBO accession no; multiple can be passed on one line; eg

 -id GO:0008234 -id GO:003693

=item -q KEY=VAL

Pass in query constraints

See L<GO::AppHandle> for full list, under get_terms() method

=item -denormalized

Writes one row for every gene_product to term association (default
will combine all terms for one gene product on one row)

=item -use_property PROP

if the db has gene_product_property defined, this will fill in the
specified propery value instead of summarising all
properties. Multiple props can be passed.

=back

=head1 OUTPUT

The default output produces tab-delimited rows with the following data:

=over

=item GeneProduct-dbname

=item GeneProduct-accession

=item GeneProduct-symbol

=item GeneProduct-full_name

=item GeneProduct-properties

=item Terms

=back

Only the terms that were in the initial query which are associated to
that gene product are listed

With the -denormalized option each term is listed on its own row, with
two additional columns (termacc and termname)

=head2 DOCUMENTATION

L<http://www.godatabase.org/dev>

=head2 SEE ALSO

L<GO::AppHandle>

=cut

