package Poros;

=head1 NAME

Poros - A plugin execution platform

=head1 SYNOPSIS

 use Poros;

 my $poros = Poros->new( '/path/file' );

 $poros->run();

=cut
use strict;
use warnings;

use Poros::Path;
use Poros::Query;

sub new 
{
    my $class = shift;
    bless { path => Poros::Path->new( @_ )->make() }, ref $class || $class;
}

=head1 METHODS

=head3 run()

Loads I<query> from STDIN, runs query, and dumps result in YAML to STDOUT.

See Poros::Query.

=cut
sub run
{
    local $| = 1;
    local $/ = undef;

    my $self = shift;
    warn sprintf "%s:%s\n", @ENV{ qw( TCPREMOTEIP TCPREMOTEPORT ) };

    my $query = Poros::Query->load( <> );
    warn $query->yaml();

    YAML::XS::DumpFile \*STDOUT, $query->run( %{ $self->{path}->path() } );
}

1;
