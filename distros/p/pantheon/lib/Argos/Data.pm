package Argos::Data;

=head1 NAME

Argos::Data

=head1 SYNOPSIS

 use Argos::Data;

 my $data = Argos::Data->new( foobar => '/data/dir' );

 map { $data->load( $_ ) } @yaml;

 $data->dump();

=cut
use strict;
use warnings;

use YAML::XS;
use File::Spec;
use File::Temp;

sub new
{
    my $class = shift;
    bless { name => shift, path => shift, data => {} }, ref $class || $class;
}

=head1 METHODS

=head3 load( $yaml )

Load data. Returns invoking object.

=cut
sub load
{
    my ( $self, $data ) = splice @_;

    for my $stat ( keys %{ $data = YAML::XS::Load( $data ) } )
    {
        while ( my ( $mesg, $node ) = each %{ $data->{$stat} } )
        {
            push @{ $self->{data}{$stat}{$mesg} }, @$node;
        }
    }
    return $self;
}

=head3 dump()

For each set of data indexed by $key, dump data to $path/$name.$key, and
clear data. Returns invoking object.

=cut
sub dump
{
    my $self = splice @_;
    my ( $name, $path, $data ) = @$self{ qw( name path data ) };

    $self->clear();

    for my $stat ( keys %$data )
    {
        my $path = File::Spec->join( $path, "$name.$stat" );
        my $temp = File::Temp->new( UNLINK => 0 );

        YAML::XS::DumpFile( $temp, delete $data->{$stat} ); 
        system sprintf "mv %s $path", $temp->filename();
    }
    return $self;
}

=head3 clear()

Clear all data files.

=cut
sub clear
{
    my $self = splice @_;
    my ( $name, $path ) = @$self{ qw( name path ) };
    map { unlink $_ } glob File::Spec->join( $path, "$name.*" );
}

1;
