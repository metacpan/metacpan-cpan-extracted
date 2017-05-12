package Tree::Template::Declare::LibXML;
{
  $Tree::Template::Declare::LibXML::DIST = 'Tree-Template-Declare';
}
$Tree::Template::Declare::LibXML::VERSION = '0.7';
use strict;
use warnings;
use Carp;
use XML::LibXML;

sub new {
    my ($class)=@_;

    return bless {ns=>{':default'=>undef}},$class;
}

sub _munge_exports {
    my ($self,$exports,$current_node_aref)=@_;

    my %all_exports=(
        %{$exports},
        xmlns => sub($$) {
            $self->{ns}->{$_[0]}=$_[1];
            return;
        },
        text_node => sub($) {
            if ($current_node_aref->[0]) {
                $current_node_aref->[0]->appendTextNode($_[0]);
            }
        },
    );

    return \%all_exports;
}

sub new_tree {
    my ($self)=@_;

    return XML::LibXML::Document->new();
}

sub finalize_tree {
    my ($self,$tree)=@_;

    return $tree;
}

sub _get_ns {
    my ($self,$name)=@_;

    my ($prefix)=($name=~m{\A (.*?) : }smx);

    if (!defined($prefix) || length($prefix)==0) {
        return '',$self->{ns}->{':default'};
    }

    if (exists $self->{ns}->{$prefix}) {
        return $prefix, $self->{ns}->{$prefix};
    }
    return;
}

sub new_node {
    my ($self)=@_;

    return XML::LibXML::Element->new('');
}

sub add_child_node {
    my ($self,$parent,$child)=@_;

    my $doc=$parent->ownerDocument;
    if ($doc) {
        $child=$doc->adoptNode($child);
    }

    if ($parent->isa('XML::LibXML::Document')) {
        $parent->setDocumentElement($child);
    }
    else {
        $parent->appendChild($child);
    }
    return $parent;
}

sub set_node_name {
    my ($self,$node,$name)=@_;

    $node->setNodeName($name);
    my ($prefix,$uri)=$self->_get_ns($name);
    if ($uri) {
        $node->setNamespace($uri,$prefix,1);
    }

    return;
}

sub set_node_attributes {
    my ($self,$node,$attrs)=@_;

    while (my ($name,$val)=each %{$attrs}) {
        my ($prefix,$uri)=$self->_get_ns($name);
        if ($prefix and $uri) {
            $node->setAttributeNS($uri, $name, $val);
        }
        else {
            $node->setAttribute($name, $val);
        }
    }

    return;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Tree::Template::Declare::LibXML - adaptor for LibXML

=head1 VERSION

version 0.7

=head1 SYNOPSIS

See L<Tree::Template::Declare>.

=head1 SPECIFICITIES

A function C<xmlns> is exported, so that you can declare XML namespaces:

  xmlns test => 'http://test/';

  node { name 'test:elem'; attribs id => 1, 'test:attr' => 5 };

You I<can> create nodes with qualified names with undeclared prefixes,
but it's probably not a good idea.

To add text nodes, you could do something like:

  my $el=node { name 'elem_with_text' };
  $el->appendTextNode('some text content');

This is ugly, so you can do:

 node {
   name 'elem_with_text';
   text_node 'some text content';
 };

=for Pod::Coverage add_child_node finalize_tree new new_node new_tree set_node_attributes set_node_name

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: adaptor for LibXML

