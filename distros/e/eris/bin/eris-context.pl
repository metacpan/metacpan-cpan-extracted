#!perl
# PODNAME: eris-context.pl
# ABSTRACT: Utility for testing the logging contextualizer
## no critic (RequireEndWithOne)
use strict;
use warnings;

use CLI::Helpers qw(:output);
use Data::Printer;
use Hash::Flatten qw(flatten);
use JSON::MaybeXS;
use Getopt::Long::Descriptive;
use YAML;

use eris::log::contextualizer;
use eris::schemas;

#------------------------------------------------------------------------#
# Argument Parsing
my ($opt,$usage) = describe_options(
    "%c %o ",
    [ 'sample|s=s', "Sample messages from the specified context" ],
    ['schema|filtered|f', "Show the schema fitlered output from the schema match instead." ],
    ['bulk|b',      "Show the bulk output from the schema match instead." ],
    ['json|j',      "Show the structure are JSON." ],
    ['flatten|F',   "Flatten the hash keys, defaults to false."],
    ['complete|C',  "Use the complete object instead of just the uniqued context."],
    [],
    [ 'config|c=s', "eris config file", {
        callbacks => { exists => sub { -f shift } }
    }],
    [ 'help' => 'Display this message and exit', { shortcircuit => 1 } ],
);
if( $opt->help ) {
    print $usage->text;
    exit 0;
}

#------------------------------------------------------------------------#
# Main
my $cfg  = $opt->config ? YAML::LoadFile($opt->config) : {};
my $ctxr = eris::log::contextualizer->new( config => $cfg );
my $schm = eris::schemas->new( $cfg->{schemas} ? %{ $cfg->{schemas} } : () );

my @sampled = ();
foreach my $c ( @{ $ctxr->contexts->plugins } ) {
    verbose({color=>'magenta'}, sprintf "Loaded context: %s", $c->name);
    if( $opt->sample and lc $opt->sample eq lc $c->name ) {
        push @sampled, $c->sample_messages;
    }
}

if( @sampled ) {
    foreach my $msg ( @sampled ) {
        dump_record($msg);
    }
}
else {
    # Use the Magic Diamond
    while(<>) {
        chomp;
        verbose({color=>'cyan'}, $_);
        dump_record($_);
    }
}

sub dump_record {
    my $msg = shift;
    my $l = $ctxr->parse($msg);
    my $v = $opt->schema ? $schm->to_document($l)
          : $l->as_doc(
                $opt->flatten  ? ( flatten => 1 )  : (),
                $opt->complete ? ( complete => 1 ) : (),
            );
    if( $opt->bulk ) {
        output({data=>1}, $schm->as_bulk($l));
    }
    elsif( $opt->json ) {
        output({data=>1}, encode_json($v));
    }
    else {
        p($v);
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

eris-context.pl - Utility for testing the logging contextualizer

=head1 VERSION

version 0.008

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
