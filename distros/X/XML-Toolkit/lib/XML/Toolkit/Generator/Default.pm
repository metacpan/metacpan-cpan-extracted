package XML::Toolkit::Generator::Default;
{
  $XML::Toolkit::Generator::Default::VERSION = '0.15';
}
use Moose;
use Encode;
use namespace::autoclean;

extends qw(XML::Generator::Moose);
with qw(
  XML::Toolkit::Generator::Interface
  XML::Toolkit::Builder::NamespaceRegistry
);

after 'xml_decl' => sub {
    my $self = shift;
    for my $pair ( $self->xmlns_pairs ) {
        my ( $prefix, $uri ) = @$pair;
        $self->start_prefix_mapping( $prefix => $uri, );
    }
    $self->newline;
};

sub get_element_name {
    my ( $self, $meta ) = @_;
    if ( $meta->can('description') ) {
        return $meta->description->{Name};
    }
    else {
        my $name = $meta->name;
        $name =~ /::(\w+)$/oi;
        return lcfirst $1;
    }
}

sub is_node {
    my ( $self, $attr ) = @_;
    confess "no attribute" unless $attr;
    return 0               unless $attr->can('description');
    return 0               unless $attr->description->{node_type};
    return 1;
}

sub is_child_node {
    my ( $self, $attr ) = @_;
    return 0 unless $self->is_node($attr);
    return 1 if $attr->description->{node_type} eq 'child';
    return 0;
}

sub is_text_node {
    my ( $self, $attr ) = @_;
    return 0 unless $self->is_node($attr);
    return 1 if $attr->description->{node_type} eq 'character';
    return 0;
}

sub is_cdata_node {
    my ( $self, $attr ) = @_;
    return 0 unless $self->is_node($attr);
    return 1 if $attr->description->{cdata};
    return 0;
}

sub is_attribute_node {
    my ( $self, $attr ) = @_;
    return 0 unless $self->is_node($attr);
    return 1 if $attr->description->{node_type} eq 'attribute';
    return 0;
}

sub get_attribute_nodes {
    my ( $self, $meta, $obj ) = @_;
    my @attrs = grep { $self->is_attribute_node($_) }
      grep { defined $_->get_value($obj) }
      map  { $meta->get_attribute($_) } $meta->get_attribute_list;
    return map {
        $_->description->{LocalName} =>
          { %{ $_->description }, Value => $_->get_value($obj) }
    } @attrs;
}

sub parse_object {
    my ( $self, $meta, $obj, $descr ) = @_;
    my %attrs = $self->get_attribute_nodes( $meta, $obj );
    my $name = $descr->{Name};

    $self->start_element(
        $name => \%attrs,
        $descr,
    );

    for my $attr ( $self->_get_sorted_filtered_attributes($meta) ) {
        if ( $self->is_text_node($attr) ) {
            my $data = $attr->get_value($obj);
            $self->is_cdata_node($attr)
              ? $self->cdata($data)
              : $self->characters($data);
        }
        elsif ( $self->is_child_node($attr) ) {
            next unless my $value = $attr->get_value($obj);
            for my $child ( grep { defined } @$value ) {
                next unless blessed $child;
                $self->parse_object( $child->meta, $child, $attr->description );
            }
        }
        else { warn "${\$attr->dump} is funky" }
    }
    $self->end_element($name);
}

augment 'parse' => sub {
    my ( $self, $obj ) = @_;
    $self->parse_object( $obj->meta, $obj, { Name => $self->get_element_name( $obj->meta ) } );

};

sub _get_sorted_filtered_attributes {
    my ( $self, $meta ) = @_;
    sort {
        return -1 unless exists $a->description->{sort_order};
        return 1  unless exists $b->description->{sort_order};
        return $a->description->{sort_order} <=> $b->description->{sort_order}
      }
      grep { !$self->is_attribute_node($_) }
      grep { !$_->does('XML::Toolkit::Trait::NoXML') }
      $meta->get_all_attributes;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

XML::Toolkit::Generator::Default - A Default Moose Object to XML Generator

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use XML::Toolkit::Generator::Default;
    XML::Toolkit::Generator::Default->new( Handler => XML::SAX::Writer->new );

=head1 DESCRIPTION

A subclass of XML::Generator::Moose, this class generates SAX events from
Moose objects.
    
=head1 ATTRIBUTES

See XML::Generator::Moose.

=head1 METHODS

=over

=item get_element_name

=item is_node

=item is_child_node

=item is_text_node

=item is_attribute_node

=item get_attribute_nodes

=item parse_object

=back

See Also XML::Generator::Moose

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-xml-toolkit@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Chris Prather  C<< <chris@prather.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Chris Prather C<< <chris@prather.org> >>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
