#!/usr/bin/env perl
# PODNAME: eris-context.pl
# ABSTRACT: Utility for testing the logging contextualizer
use strict;
use warnings;

use CLI::Helpers qw(:output);
use Data::Printer;
use FindBin;
use Getopt::Long::Descriptive;
use Path::Tiny;
use eris::log::contextualizer;

#------------------------------------------------------------------------#
# Path Setup
my $path_base = path("$FindBin::Bin")->parent;

#------------------------------------------------------------------------#
# Argument Parsing
my ($opt,$usage) = describe_options(
    "%c %o ",
    [ 'sample|s:s', "Sample messages from the specified context" ],
    [],
    [ 'config|c:s', "eris config file", {
        callbacks => { exists => sub { -f shift } }
    }],
);

#------------------------------------------------------------------------#
# Main
my $ctxr = eris::log::contextualizer->new( $opt->config ? (config => $opt->config) : () );

my @sampled = ();
foreach my $c ( @{ $ctxr->contexts->plugins } ) {
    verbose({color=>'magenta'}, sprintf "Loaded context: %s", $c->name);
    if( lc $opt->sample eq $c->name ) {
        push @sampled, $c->sample_messages;
    }
}

if( @sampled ) {
    foreach my $msg ( @sampled ) {
        p( $ctxr->parse($msg) );
    }
}
else {
    # Use the Magic Diamond
    while(<>) {
        chomp;
        verbose({color=>'cyan'}, $_);
        my $l = $ctxr->parse($_);
        p($l);
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

eris-context.pl - Utility for testing the logging contextualizer

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
