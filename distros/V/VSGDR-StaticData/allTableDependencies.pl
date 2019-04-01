#!/usr/bin/perl

use Modern::Perl;
use 5.010;

use autodie qw(:all);
no indirect ':fatal';

use Carp;
use DBI;
use Graph;
use GraphViz;

use Getopt::Euclid qw( :vars<opt_> );
use Data::Dumper;
use VSGDR::StaticData;

use version ; our $VERSION = qv('0.01');

my %tables;

my $dbh             = DBI->connect("dbi:ODBC:${opt_connection}", q{}, q{}, { AutoCommit => 1, RaiseError => 1 });

my $ra_dep          = VSGDR::StaticData::dependency($dbh);
my $g               = Graph->new( 'directed' => 1 ) ;
my $g2              = GraphViz->new();

foreach my $rec (@{$ra_dep}) {
#warn Dumper $rec;
    $g->add_vertex("$$rec[1].$$rec[2]") ;
    $g->add_vertex("$$rec[4].$$rec[5]") ;    
    $g->add_edge("$$rec[1].$$rec[2]","$$rec[4].$$rec[5]");
    
    $g2->add_node("$$rec[1].$$rec[2]") ;
    $g2->add_node("$$rec[4].$$rec[5]") ;    
    $g2->add_edge("$$rec[1].$$rec[2]" => "$$rec[4].$$rec[5]",label => "$$rec[6]");
    
}

open my $H, ">", "c:\\temp\\mb.jpg" ;
binmode $H;
$g2->as_jpeg($H);
close $H;


##### remove any successors....... we're not asked to dump data for these
####for my $v ( $g->all_successors($combinedName)) {
####    $g->delete_vertex($v);
####}
####
##### remove any unconnected nodes
####for my $v ( grep {$_ ne $combinedName } $g->vertices() ) {
####    if ( ! $g->is_reachable($combinedName,$v) && ! $g->is_reachable($v,$combinedName) ) {
####        $g->delete_vertex($v);
####    }
####}

if ($g->has_a_cycle() ){
    warn "There are cycles in the dependencies.";
    warn "Unsorted List of tables follows.";
    my @res = $g->vertices();
    do { $" = "\n"; print "@res"; };
}
else {
    my @res = $g->topological_sort();
    do { $" = "\n"; print "@res"; };
}

exit ;

END {
    $dbh->disconnect()          if $dbh ;
}



__DATA__


=head1 NAME


alltTableDependencies.pl - Given a database output all tables in key-dependency preserving order

=head1 VERSION

0.01

=head1 USAGE

alltTableDependencies.pl -t <tablename> -c <odbc connection> [options]

=head1 REQUIRED ARGUMENTS

=over

=item  -c[onnection] [=] <dsn>

Specify ODBC connection for Test script


=back


=head1 OPTIONS

=over


=back


=head1 AUTHOR

Ded MedVed.



=head1 BUGS

Hopefully none.



=head1 COPYRIGHT

Copyright (c) 2013, Ded MedVed. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

