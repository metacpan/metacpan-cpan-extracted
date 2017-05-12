package XML::Filter::Namespace;

use strict;

use base qw( XML::SAX::Base Class::Accessor );

use vars qw( $VERSION );

# Manually maintained, this is the package's version number.
$VERSION = '1.03';

sub start_document {
    my $self = shift;
    my ( $data ) = @_;

    die __PACKAGE__.": no namespace specified\n"
	unless $self->ns;

    $self->seen_root( 0 );

    if ($self->nl_after_tag) {
        die __PACKAGE__.": nl_after_tag: not a hash ref\n"
            unless ref($self->nl_after_tag) eq 'HASH';
    } else {
        $self->nl_after_tag( {} );
    }

    $self->SUPER::start_document( $data );
}

# Stub out these as we provide our own.
sub start_dtd { }
sub end_dtd   { }

# Destroy comments.
sub comment { }

sub wanted_ns {
    my $self = shift;
    my ( $data ) = @_;
    return $data->{ NamespaceURI } && $data->{ NamespaceURI } eq $self->ns;
}

{
    my $in_ns = 0;

    sub start_prefix_mapping {
        my $self = shift;
        my ( $data ) = @_;

        return unless $self->wanted_ns( $data );
        return if $in_ns++;

        # Make it the default namespace.
        $data->{ Prefix } = '';

        $self->SUPER::start_prefix_mapping( $data );
    }

    sub end_prefix_mapping {
        my $self = shift;
        my ( $data ) = @_;

        return unless $self->wanted_ns( $data );
        return unless $in_ns--;

        $self->SUPER::end_prefix_mapping( $data );
    }
}

sub start_element {
    my $self = shift;
    my ( $data ) = @_;

    return unless $self->wanted_ns( $data );

    # Delete each attribute that isn't in our namespace.
    foreach my $att_name ( keys %{ $data->{ Attributes } } ) {
        my $attr = $data->{ Attributes }->{ $att_name };
        next if $self->wanted_ns( $attr );
        delete $data->{ Attributes }->{ $att_name };
    }

    $self->fix_attr_prefix( $data->{ Attributes } );

    $self->emit_doctype( $data )
        if !$self->seen_root && ($self->systemid || $self->publicid);

    $self->SUPER::start_element( $data );
    $self->seen_root( 1 );
}

sub emit_doctype {
    my $self = shift;
    my ( $data ) = @_;

    warn __PACKAGE__.": public id specified with no system id\n"
        if $self->publicid && ! $self->systemid;

    $self->SUPER::start_dtd( {
        Name     => $data->{ LocalName },
        SystemId => $self->systemid || '',
        PublicId => $self->publicid || '',
    } );
    $self->SUPER::end_dtd( {} );
}

sub end_element {
    my $self = shift;
    my ( $data ) = @_;

    return unless $self->wanted_ns( $data );

    $self->SUPER::end_element( $data );

    $self->characters( { Data => "\n" } )
        if $self->nl_after_tag->{ $data->{LocalName} };
}

sub fix_attr_prefix {
    my $self = shift;
    my ( $attrs ) = @_;
    foreach my $a ( values %$attrs ) {
        $a->{ Name } =~ s/.*://;
        $a->{ Prefix } = '';
    }
}

__PACKAGE__->mk_accessors( qw( ns systemid publicid seen_root nl_after_tag ) );

1;
__END__

=pod

=head1 NAME

XML::Filter::Namespace - strip all but a single namespace

=head1 SYNOPSIS

  use XML::Filter::Namespace;

  # The traditional way.
  use XML::SAX::ParserFactory;
  use XML::SAX::Writer;
  my $w   = XML::SAX::Writer->new( Output => \*STDOUT );
  my $xfn = XML::Filter::Namespace->new( Handler => $w );
  $xfn->ns( 'urn:my-namespace' );
  my $p = XML::SAX::ParserFactory->parser( Handler => $xfn );
  $p->parse_uri( '-' );    # Take input from STDIN.

  # The SAX Machines way.
  use XML::SAX::Machines qw( Pipeline );
  my $strip = XML::Filter::Namespace->new;
  $strip->ns( 'urn:my-namespace' );
  my $m = Pipeline->new( $strip => \*STDOUT );
  $m->parse_uri( '-' );    # Take input from STDIN.

=head1 DESCRIPTION

This module strips out everything in an XML document that does not belong in a
specified namespace.  This often provides a view of the XML that is much
clearer when multiple namespaces are in use.

A warning will be issued if a publicid is specified without a systemid.

Duplicate namespace declarations will be stripped out.

=head1 METHODS

=over 4

=item ns ( NAMESPACE )

Set the namespace to include.  Must be set before parsing.

=item systemid ( SYSTEMID )

Set to the SystemID of a DTD.  This will cause a DOCTYPE declaration to
be output.

=item publicid ( PUBLICID )

Set to the PublicId of a DTD.  This will cause a DOCTYPE declaration to
be output.

=item nl_after_tag ( HASHREF )

Set to a hash reference whose keys are tag names (sans prefix) and whose
values are true.  Those tags will have newlines output after their close
tag.

=back

=head1 SEE ALSO

L<XML::SAX::Base>(3), L<filtns>(1).

=head1 BUGS

There should be an option to keep attributes which are in the empty namespace.

=head1 AUTHOR

Dominic Mitchell E<lt>cpan@semantico.comE<gt>

=head1 VERSION

@(#) $Id: Namespace.pm,v 1.8 2003/04/27 18:41:40 dom Exp $

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim: set ai et sw=4 :

