#!perl
# PODNAME: eris-field-lookup.pl
# ABSTRACT: Utility for testing the logging contextualizer
## no critic (RequireEndWithOne)
use strict;
use warnings;

use CLI::Helpers qw(:output);
use Data::Printer;
use Getopt::Long::Descriptive;
use YAML;
use eris::dictionary;

#------------------------------------------------------------------------#
# Argument Parsing
my ($opt,$usage) = describe_options(
    "%c %o <fields to lookup>",
    [ 'list|l',     "list all available fields" ],
    [],
    [ 'config|c=s', "eris config file", {
        callbacks => { exists => sub { -f shift } }
    }],
    [],
    ['help', 'Display this help', { shortcircuit => 1 }],
);
if( $opt->help ) {
    print $usage->text;
    exit 0;
}

#------------------------------------------------------------------------#
# Main
my $cfg = $opt->config ? YAML::LoadFile($opt->config) : {};
my %args = exists $cfg->{dictionary} && ref $cfg->{dictionary} eq 'HASH' ? %{ $cfg->{dictionary} } : ();
my $dict = eris::dictionary->new(%args);

if( $opt->list ) {
    my $fields = $dict->fields;
    output({color=>'cyan'}, sprintf "Found %d fields in the dictionary.", scalar(keys %{ $fields }));
    foreach my $f (sort keys %{ $fields }) {
        my $F = $dict->lookup($f);
        output({indent=>1}, sprintf "%s (%s) %s", $f, $fields->{$f}, $F->{description});
    }
    exit 0;
}

die $usage->text unless @ARGV;
foreach my $field (@ARGV) {
    output({clear=>1,color=>'yellow'}, "Looking up '$field'");
    p( $dict->lookup($field) );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

eris-field-lookup.pl - Utility for testing the logging contextualizer

=head1 VERSION

version 0.008

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
