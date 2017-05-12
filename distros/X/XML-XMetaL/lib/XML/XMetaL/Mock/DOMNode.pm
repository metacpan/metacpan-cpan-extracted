package XML::XMetaL::Mock::DOMNode;

use 5.008;
use strict;
use warnings;

use Carp;
use Hash::Util qw(lock_keys);

use XML::XMetaL::Mock::DOMNodeList;

use constant TRUE  => 1;
use constant FALSE => 0;

our @keys = qw(
    nodeID
    attributes 
    childNodes 
    firstChild 
    lastChild 
    nextSibling 
    nodeName 
    nodeType 
    nodeValue 
    ownerDocument 
    parentNode 
    previousSibling 
);

our %node_types = (
    DOMElement                => 1,
    DOMAttr                   => 2,
    DOMText                   => 3,
    DOMCDATASection           => 4,
    DOMEntityReference        => 5,
    DOMEntity                 => 6,
    DOMProcessingInstruction  => 7,
    DOMComment                => 8,
    DOMDocument               => 9,
    DOMDocumentType           => 10,
    DOMDocumentFragment       => 11,
    DOMNotation               => 12,
    DOMCharacterReference     => 505,
);

sub new {
    my ($class, %args) = @_;
    my $self;
    eval {
        my %properties;
        @properties{@keys} = @args{@keys};
        $self = bless \%properties, ref($class) || $class;
        #lock_keys(%$self, @keys);
        $self->{childNodes} = XML::XMetaL::Mock::DOMNodeList->new();
        $self->_set_node_type();
    };
    croak $@ if $@;
    return $self;
}

sub _set_node_type {
    my ($self) = @_;
    my $class = ref $self;
    my ($key) = $class =~ /([^:]+)$/;
    croak "Node name ".($key || "FALSE")." does not exist"
        unless exists $node_types{$key};
    my $node_type = $node_types{$key};
    $self->{nodeType} = $node_type;
}

sub appendChild {
    eval {
        my $self = shift @_;
        my XML::XMetaL::Mock::DOMNode     $child_node = shift(@_) || croak("Missing argument");
        my XML::XMetaL::Mock::DOMNodeList $child_node_list = $self->{childNodes};
        $child_node->{parentNode} = $self;
        $child_node_list->add($child_node);
    };
    croak $@ if $@;
}

#cloneNode 

sub hasChildNodes {
    my $self = shift @_;
    my XML::XMetaL::Mock::DOMNodeList $child_node_list = $self->{childNodes};
    return $child_node_list->hasChildNodes();
}

#insertBefore 
#removeChild 
#replaceChild 


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::XMetaL::Mock::DOMNode - Mock XMetaL DOMNode class

=head1 SYNOPSIS

 use base qw(XML::XMetaL::Base);

=head1 DESCRIPTION


=head2 Class Methods

None.

=head2 Public Methods


=head1 ENVIRONMENT

The Corel XMetaL XML editor must be installed.

=head1 BUGS

A lot, I am sure.

Please send bug reports to E<lt>henrik.martensson@bostream.nuE<gt>.


=head1 SEE ALSO

See L<XML::XMetaL>.

=head1 AUTHOR

Henrik Martensson, E<lt>henrik.martensson@bostream.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Henrik Martensson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
