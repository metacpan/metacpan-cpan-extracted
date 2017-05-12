package XML::Essex::NamespaceMap;

$VERSION = 0.000_1;

=head1 NAME

    XML::Essex::NamespaceMap - ...

=head1 SYNOPSIS

=head1 DESCRIPTION

Contains a mapping of namespaces to prefixes.

=head1 METHODS

=over

=cut

use strict;

=item new

    my $map = ns_map $ns1 => $prefix1, ...;  ## In Essex scripts.
    my $map = XML::Essex::NamespaceMap->new(
        $essex,
        $ns1 => $prefix1,
        ...
    );
    my $unregistered_map = XML::Essex::NamespaceMap->new(
        $ns1 => $prefix1,
        ...
    );

=cut

sub new {
    my $proto = shift;
    my $essex;
    $essex = shift if @_ && UNIVERSAL::isa( $_[0], "XML::Essex" );
    my %map = @_;

    my $self = bless {
        Essex => $essex,
        Map   => \%map,
    }, ref $proto || $proto;

    $self->{Essex}->add_namespace_map( $self->{Map} ) if $self->{Essex};

    return $self;
}

sub DESTROY {
    my $self = shift;

    if ( $self->{Essex} ) {
        $self->{Essex}->remove_namespace_map( $self->{Map} );
    }
    else {
        ## Clear out the map in case it was added to an Essex
        ## we don't happen to refer to.
        %{$self->{Map}} = ();
    }
}

=back

=head1 LIMITATIONS

No way to get at the namespaces and prefixes.  Can add one when one
is needed, most uses should go through the essex object to fall back
to earlier mappings if a mapping doesn't happen to have a particular
namespace or prefix.

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
