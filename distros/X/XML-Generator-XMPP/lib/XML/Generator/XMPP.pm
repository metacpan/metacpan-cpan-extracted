package XML::Generator::XMPP;
use strict;
use warnings;

use base qw(XML::SAX::Base);

our $VERSION='0.02';

=head1 NAME

XML::Generator::XMPP - easily create XMPP packets

=head1 SYNOPSIS

   my $builder = XML::SAX::IncrementalBuilder::LibXML->new(detach => 1);
   my $xpc = XML::LibXML::XPathContext->new;
   my $gen = XML::Generator::XMPP(
      Handler => $builder,
      XPC => $xpc,
      Server => 'jabber.org',
   );

   my $client = 'cl';
   $xpc->registerNs($client, 'jabber:client');

   $x->start;

   $x->nodes([
      "$client:presence" => [],
   ]);

   $x->end;

   while (my $node = $builder->get_node()) {
      print SOCKET $node->toString;
   }

=head1 DESCRIPTION

XML::Generator::XMPP uses L<XML::SAX::IncrementalBuilder::LibXML> and
L<XML::LibXML::XPathContext> to create XML nodes for the XMPP packets
you want to send.

As you can see in the synopsis, you use start(), end() and nodes() to
describe what nodes to create, and then ask the
L<XML::SAX::IncrementalBuilder::LibXML> object for the generated nodes.
the 'incremental' means you can do this at any time, so you don't need
to wait till after end() (which would have made this unworkable).

IncrementalBuilder generates nodes that are suitable for printing into
your socket verbatim. That means the while loop from the L<SYNOPSIS>
would write a valid XMPP stream into the socket.

=head1 CONSTRUCTOR

=head2 new

Creates a new instance. This has three named parameters, which are all
required:

=over 2

=item Handler

The SAX builder object. Theoretically, this could be any XML::SAX class
that generates DOM fragments with L<XML::LibXML::Node> objects, but the
only real option in L<XML::SAX::IncrementalBuilder::LibXML>.

=item XPC

An L<XML::LibXML::XPathContext> object. This is used to get the namespaces
right. You should register any namespace you plan to use with this object.

=item Server

The name of the XMPP server you are connecting to. This is used in the
start() method to generate a correct <stream:stream> element.

=back

=head1 METHODS

=head2 start

Generates the initial <stream:stream> element that starts the XML stream

=cut

sub start {
   my $self = shift;
   $self->{Handler}->reset();
   $self->start_document({});
   $self->xml_decl({Version => '1.0'});
   $self->start_prefix_mapping({Prefix => 'stream', NamespaceURI => 'http://etherx.jabber.org/streams'});
   $self->start_prefix_mapping({Prefix => '', NamespaceURI => 'jabber:client'});
   $self->start_element({
      Name	     => 'stream:stream',
      LocalName	     => 'stream',
      Prefix	     => 'stream',
      NamespaceURI   => 'http://etherx.jabber.org/streams',
      Attributes     => {
         to       => $self->{Server},
         version  => '1.0',
      },
   });
}

my $count = 0;
sub _generate_id {
   return "id-" . $count++;
}

sub _handle_node {
   my ($self, $node, $data) = @_;

   my $nss = $self->{Handler}->{NamespaceStack};
   $nss->push_context;

   my ($ns, $name) = split (':', $node);
   my ($ns_uri, $new_mapping, $el_data);
   if ($ns_uri = $nss->get_uri($ns)) {
      my $fullname = ($ns ? "$ns:" : '') . $name;
      $el_data = {Name => $fullname, LocalName => $name, Prefix => $ns, NamespaceURI => $ns_uri};
   } else {
      $new_mapping = 1;
      $ns_uri = $self->{XPC}->lookupNs($ns);
      $nss->declare_prefix($ns, $ns_uri); # declare
      if ($nss->get_uri('') ne $ns_uri) {
      	$nss->declare_prefix('', $ns_uri); # and also set new default
      	$self->start_prefix_mapping({Prefix => $ns, NamespaceURI => $ns_uri});
      	$el_data = {Name => $name, NamespaceURI => $ns_uri};
      } else {
      	$el_data = {Name => $name, Prefix => ''};
      }
      $nss->push_context;
   }
   if (@$data and $data->[0] eq 'Attributes') {
      my ($attr, $list) = splice (@$data, 0, 2);
      foreach my $fullname (keys %$list) {
         my ($attr_ns, $name) = split (':', $fullname);
         if ($attr_ns eq $ns) {
            # default attribute namespace is the namespace of the element.
            $list->{$name} = delete $list->{$fullname};
         }
      }
      $el_data->{$attr} = $list;
   }
   my $returnnode = $self->start_element($el_data);
   while (@$data) {
      my ($type, $data) = splice (@$data, 0, 2);

      if ($type eq 'Text') {
         $self->characters({Data => $data});
      } elsif ($type eq 'Child') {
         while (@$data) {
            $self->_handle_node(splice (@$data, 0, 2));
         }
      } elsif ($type eq 'Subtree') {
         $returnnode->appendChild($data);
      } else {
         die "unknown $type";
      }
   }
   $self->end_element($el_data);
   if ($new_mapping) {
      $self->end_prefix_mapping({Prefix => $ns});
      $nss->pop_context;
   }
   $nss->pop_context;
}

=head2 nodes

Creates XML nodes from the list you pass it. The basic syntax is as follows

  $generator->nodes( [
    "nsprefix:nodename" => [ ..list of options.. ]
  ] );

The namespace prefix is required and must be registered with the XPathContext
you have passed into the constructor.

The list of options for a node is essentially a hash, but written as a list
so you can have more than one of the same 'key'. The following keys are
allowed:

=over 2

=item Attributes => {'nsprefix:attr_name' => 'value'}

If present, this must be the first in the list. Again, the namespace
prefix is mandatory, and must be registered with the XPathContext.

=item Text => 'text'

Creates a Text node.

=item Child => [ 'nsprefix:nodename' => [ ... ], ... ]

Create one or more child nodes. The same syntax as for the main nodes
list applies.

=item Subtree => XML::LibXML::Element->new('foo')

Add an XML::LibXML::Element child node. This can be useful if you are
using some module that generates some XML for you, and you need to put
it inside an XMPP packet. Note that you are responsible for making sure
that the namespaces are correct.

=back

As you can see in the L</SYNOPSIS>, leaving the list empty is valid
behaviour. This creates an empty node.

=cut

sub nodes {
   my ($self, $nodelist) = @_;

   while (@$nodelist) {
      $self->_handle_node(splice (@$nodelist, 0, 2));
   }
}

=head2 end

Generates the closing </stream:stream> element that closes the XML stream.
=cut

sub end {
   my $self = shift;

   $self->end_element({Name => 'stream:stream', LocalName => 'stream', Prefix => 'stream'});
   $self->end_prefix_mapping({Prefix => 'stream', NamespaceURI => 'http://etherx.jabber.org/streams'});
   $self->end_prefix_mapping({Prefix => ''});
   $self->end_document({});
}

=head1 CONVENIENCE METHODS

The following are methods you can use to ease the construction of
the structure you pass to the nodes() method. They return a listref
you can pass into nodes() as the top listref it expects.

  $self->nodes( $self->iq(...) );

=cut

=head2 iq TYPE, TO, CHILDREN

  $iq = $self->iq(get => 'someone@example.com', [
                "disco:query" => [],
        ],
  ) 

Creates the structure for an 'iq' element. The TYPE and TO parameters
should contain the content of the attributes with the corresponding
name, and CHILDREN is a listref containing zero or more child
descriptions in the same format as you use in nodes()

=cut

sub iq {
   my ($self, $type, $destination, $child) = @_;

   my $attr = {
            ':type' => $type,
            ':id' => _generate_id(),
   };
   $attr->{':to'} = $destination if $destination;

   return [":iq" => [
         Attributes => $attr,
         Child => $child,
      ]
   ];
}

1;
__END__

=head1 AUTHOR

Martijn van Beers  <martijn@cpan.org>

=head1 LICENCE

XML::Generator::XMPP is released under the GPL version 2.0 or higher.
See the file LICENCE for details. 

=cut

