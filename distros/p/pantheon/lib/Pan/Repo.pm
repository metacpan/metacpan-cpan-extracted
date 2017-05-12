package Pan::Repo;

=head1 NAME

Pan::Repo - group management interface

=head1 SYNOPSIS

 use Pan::Repo;

 my $repo = Pan::Repo->new
 (
     conf => '/conf/file',
     path => '/path/file',
 );

 my %conf = $repo->dump

=cut
use strict;
use warnings;
use Carp;

use Pan::Path;
use Pan::Conf;
use Pan::Transform;

=head1 CONFIGURATION

=head3 conf

See Pan::Conf.

=head3 path

See Pan::Path.

=cut
sub new 
{
    my ( $class, %self, %code, %conf ) = splice @_;
    my $conf = Pan::Conf->new( $self{conf} );
    my $path = $self{path} = Pan::Path->new( $self{path} )->make();
    my $name = $self{group};

    for my $name ( defined $name ? $name : $conf->names() )
    {
        my $conf = $conf{$name} = $conf->dump( $name );
        my $transform = $conf->{transform};

        for my $i ( 0 .. @$transform - 1 )
        {
            my $t = $transform->[$i];
            my $code = $code{$t} ||= Pan::Transform
                ->new( map { $_ => $path->path( $_ => $t ) } qw( code conf ) );

            confess "transform $t: $name undefined"
                unless $transform->[$i] = $code->dump( $name );
        }
    }
    bless { %self, conf => \%conf }, ref $class || $class;
}

=head1 METHODS

=head3 dump()

Returns all group configurations.

=cut
sub dump
{
    my $self = shift;
    my $conf = $self->{conf};
    return wantarray ? %$conf : shift $conf;
}

1;
