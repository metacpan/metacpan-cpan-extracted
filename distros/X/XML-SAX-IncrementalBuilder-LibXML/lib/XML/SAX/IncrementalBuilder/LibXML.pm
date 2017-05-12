package XML::SAX::IncrementalBuilder::LibXML::Element;
use strict;
use warnings;

use XML::LibXML;
use base qw(XML::LibXML::Element);
use Class::InsideOut qw(public);

public special => my %special;

sub toString {
   my $self = shift;

   my $str = '';
   my $special = $self->special ? $self->special : '';
   if ($special eq 'Start') {
      $str .= '<' . $self->nodeName;
      foreach my $attr ($self->attributes) {
        $str .= sprintf (" %s=\"%s\"", $attr->nodeName, $attr->getValue);
      }
      $str .= '>';
   }
   elsif ($special eq 'End') {
      $str = sprintf ("</%s>", $self->nodeName);
   }

   return $str;
}

package XML::SAX::IncrementalBuilder::LibXML::Document;
use strict;
use warnings;

use XML::LibXML;
use base qw(XML::LibXML::Document);
use Class::InsideOut qw(public);

public decl => my %decl;

sub toString {
   my $self = shift;

   my $str = '';
   if ($self->decl) {
      $str = '<?xml';
      if (my $v = $self->getVersion) {
         $str .= " version=\"" . $v . "\"";
      }
      if (my $e = $self->getEncoding) {
         $str .= " encoding=\"" . $e . "\"";
      }
      $str .= '?>';
   }

   if ($self->externalSubset) {
      $str .= $self->externalSubset->toString;
   }
   
   return $str;
}

=head1 NAME

XML::SAX::IncrementalBuilder::LibXML - create DOM fragments from SAX events

=head1 SYNOPSIS

   my $builder = XML::SAX::IncrementalBuilder::LibXML->new;
   my $parser = XML::LibXML->new(Handler => $builder);
   $parser->parse( ... );
   while (my $frag = $builder->get_node) {
      # do stuff
   }

=head1 DESCRIPTION

This module builds on L<XML::LibXML::SAX::Builder> to build DOM fragments
from SAX events. Instead of (or in addition to) creating a complete DOM
tree, it splits up the document into chunks based on the depth they are
in the tree.

=cut

package XML::SAX::IncrementalBuilder::LibXML;
use strict;
use warnings;

use base qw(XML::LibXML::SAX::Builder);
use Class::InsideOut qw(register);

our $VERSION = '0.02';

=head1 METHODS

=head2 new

Creates a new object. Accepts the following parameters

=over 2

=item godepth INT

Lets you specify up to how deep in the xml tree you want to have the
elements reported. A value of 2 would report the root element, and
all of its children and grandchildren. The default value for this is 1

=item detach BOOL

Whether to detach the elements at godepth from their parent. This is
useful if you have a very large document to parse, and don't want to
keep it all in memory. For example if L<POE::Filter::SAXBuilder> is
used in a jabber application, which generates a potentially endless
stream of xml.

=back

=cut

sub new {
   my $class = shift;

   my $self = $class->SUPER::new(@_, depth => -1);
   $self->{'godepth'} = 1 unless defined ($self->{'godepth'});
   $self->{'detach'} = 0 unless defined ($self->{'detach'});
   $self->{'finished'} = [];
   return $self;
}

=head2 clone

creates a new instance of the Builder with the same settings.

=cut

sub clone {
   my $self = shift;

   my $class = ref $self;
   my $new_self = $class->new(
      depth => -1,
      godepth => $self->{'godepth'},
      detach => $self->{'detach'},
   );

   return $new_self;
}

=head2 get_node

Returns a single node from the list of nodes that have finished building.

=cut

sub get_node {
   my $self = shift;
   return shift(@{$self->{'finished'}});
}

=head2 finished_nodes

Returns the number of nodes that have been completely built.

=cut

sub finished_nodes {
   my $self = shift;
   return scalar @{$self->{'finished'}};
}

=head2 reset

Set the Builder back to its start state

=cut

sub reset {
   my $self = shift;

   $self->done;
   $self->{depth} = -1;
}

sub _register {
      my ($noderef, $special) = @_;
      register ($$noderef, 'XML::SAX::IncrementalBuilder::LibXML::Element');
      $$noderef->special($special) if (defined $special);
}

#
# Below are the SAX2 methods
#

sub xml_decl {
   my $self = shift;

   $self->{'DOM'}->decl(1);
   $self->SUPER::xml_decl(@_);
}

sub start_document {
   my $self = shift;

   $self->SUPER::start_document(@_);

   bless ($self->{'DOM'}, 'XML::SAX::IncrementalBuilder::LibXML::Document');
   push (@{$self->{'finished'}}, $self->{'DOM'});
}

sub characters {
   my $self = shift;
   my $detached;

   if ($self->{detach} and $self->{depth} == $self->{godepth} - 1) {
      $detached = $self->{Parent};
      my $node = $self->{Parent} = XML::LibXML::DocumentFragment->new;
   }

   $self->SUPER::characters(@_);

   if ($detached) {
      push (@{$self->{finished}}, $self->{Parent});
      $self->{Parent} = $detached;
   }
}

sub start_element {
   my $self = shift;

   $self->{'depth'}++;

   if ($self->{'detach'} and $self->{'depth'} == $self->{'godepth'}) {
      $self->{'detached'} = $self->{Parent};
      my $frag = $self->{Parent} = XML::LibXML::DocumentFragment->new();
   }

   $self->SUPER::start_element(@_);
   my $node = $self->{Parent};

   # Announce elements with a lower depth than we're interested
   # in, even if they're not done yet.
   # FIXME: do we really want this?
   if ($self->{'depth'} < $self->{'godepth'}) {	    
      if ($self->{detach}) {
	 _register (\$node, 'Start');
      }
      push(@{$self->{'finished'}}, $node);
   }
   return $node;
}

sub end_element {
   my $self = shift;

   my $node = $self->{Parent};

   $self->SUPER::end_element(@_);

   if($self->{'depth'} == $self->{'godepth'}) {
      if ($self->{detached}) {
	 $node = $self->{Parent};
	 $self->{Parent} = delete $self->{detached};
      }
      push(@{$self->{'finished'}}, $node);
   }
   if ($self->{'depth'} < $self->{'godepth'}) {
      $node = $node->cloneNode;
      _register (\$node, 'End');
      push(@{$self->{'finished'}}, $node);
   }

   $self->{'depth'}--;

   # flag that we've reached the end of the document
   if ($self->{'depth'} == -1) {
      $self->{'EOD'} = 1;
   }
}

1;

__END__

=head1 CAVEATS

You easily get segfaults if you use xpath on nodes that aren't in a document.
This is a problem in XML::LibXML. Until the problem is fixed, make sure you
put anything you want to run xpath on inside an XML::LibXML::Document first.

=head1 SEE ALSO

L<XML::Filter::DOMFilter::LibXML> has similar functionality, but based
on xpath expressions.

=head1 AUTHOR

Martijn van Beers  <martijn@cpan.org>

=head1 LICENCE

POE::Loop::Glib is released under the GPL version 2.0 or higher.
See the file LICENCE for details. 


=cut
