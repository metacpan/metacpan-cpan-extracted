=head1 NAME

XML::XMLWriter::Element - XML::XMLWriter Element Class

=cut

######################################################################

package XML::XMLWriter::Element;
require 5.8.0;

######################################################################

use strict;
use Carp;
use XML::XMLWriter::PCData;

######################################################################

=head2 In General

Down there are some methods which to you might seem quite useless
since they simply call some other expression which you could also call
directly. I recommend to use them though since in feature releases
they might do more and then you surley don't want to modify your
code. I just document what they call to make clear what they do so far.

=head2 Methods

=head3 new ($elementname, $ParseDTD_object, \%arguments, $pcdata,
$Element_parent_object)

Constructor. Complains by outputting a warning if the attribute list
or some attribute value is not allowed by the DTD.

=cut

######################################################################

sub new {
  my($class,$elem,$dtd,$args,$text,$parent) = @_;
  my $self = bless({}, ref($class) || $class);
  $dtd->attr_list_value_allowed($elem,$args) or carp $dtd->errstr if($dtd and (ref($args) eq 'HASH'));
  $self->{elem} = $elem;
  $self->{args} = $args;
  $self->{dtd} = $dtd;
  $self->{child} = [];
  $self->{parent} = $parent;
  $self->_text($text) if($text);
  return $self;
}

######################################################################

=head3 _text (@pcdata)

Same as C<_pcdata>.

=cut

######################################################################

sub _text {
  my $self = shift;
  return $self->_pcdata(@_);
}

######################################################################

=head3 _pcdata (@pcdata)

Adds a XML::XMLWriter::PCData object to the child list. But returns
the elements object (C<$self>).  See the POD of PCData.pm for more
information on what is done with @pcdata.

=cut

######################################################################

sub _pcdata {
  my ($self,@text) = @_;
  push @{$self->{child}}, XML::XMLWriter::PCData->new(@text);
  return $self;
}

######################################################################

=head3 _entity ($ref)

Simply calls and returns C<_cdata('&$ref;');>.

=cut

######################################################################

sub _entity {
  my($self,$ref) = @_;
  return $self->_cdata("&$ref;");
}

######################################################################

=head3 _comment ($comment)

Simply calls and returns C<_cdata('E<lt>!-- $comment --E<gt>');>.

=cut

######################################################################

sub _comment {
  my($self,$comment) = @_;
  return $self->_cdata("<!-- $comment -->");
}

######################################################################

=head3 _pi ($target, $data) 

Adds an processing instruction to the child list by calling and
returning C<_cdata('E<lt>?$target $data?E<gt>');>.

=cut

######################################################################

sub _pi {
  my($self,$target,$data) = @_;
  return $self->_cdata("<?$target $data?>");
}

######################################################################

=head3 _cdata (@cdata)

Simply adds every element that @cdata contains to the child list.
You can also call directly C<_push_child(@cdata)>.

Returns the object it was called on.

=cut

######################################################################

sub _cdata {
  my($self,@cdata) = @_;
  #push @{$self->{child}}, @cdata;
  $self->_push_child(@cdata);
  return $self;
}

######################################################################

=head3 _add ($element, \%arguments, $pcdata)

Adds element/tag $element to the child list.  It'll produce a warning
if the DTD doesn't allow that operation.  Depending on whether the DTD
says that the newly created element is a empty element or not, the
object C<_add> was called on or the newly created object is returned.

=cut

######################################################################

sub _add {
  my($self,$elem,$args,$text) = @_;
  croak "2. argument must be a hash reference" if(defined($args) and ref($args) ne 'HASH');
  $self->{dtd}->child_allowed($self->{elem}, $elem) or carp $self->{dtd}->errstr if($self->{dtd});
  local $_ = XML::XMLWriter::Element->new($elem,$self->{dtd},$args,$text,$self);
  push @{$self->{child}}, $_;
  return ($self->{dtd} and $self->{dtd}->is_empty($elem)) ? $self : $_;
}

######################################################################

=head3 _parent ()

Returns the elements parent element object.

=cut

######################################################################

sub _parent {
  my $self = shift;
  return $self->{parent};
}

######################################################################

=head3 _get ()

Returns the XML code taking the element it is called on as root. This
method works recursive.  It checks every elements child list and
complains if it is not allowed by the DTD.

=cut

######################################################################

sub _get {
  my($self) = @_;
  my $res = '<' . $self->{elem};
  local $_;
  foreach $_ (keys(%{$self->{args}})) {
    $res .= ' ' . $_ . '="' . $self->{args}->{$_} . '"';
  }
  if($self->{dtd} and $self->{dtd}->is_empty($self->{elem})) {
    $res .= ' />';
  }
  else {
    $res .= '>';
    my @child;
    foreach $_ (@{$self->{child}}) {
      push @child, (ref($_) eq 'XML::XMLWriter::Element') ? $_->{elem} : '#PCDATA';
    }
    $self->{dtd}->child_list_allowed($self->{elem},@child) or carp $self->{dtd}->errstr if($self->{dtd});
    foreach $_ (@{$self->{child}}) {
      $res .= (ref($_) =~ m/^XML::XMLWriter::/) ? join("",$_->_get()) : $_;
    }
    $res .= '</' . $self->{elem} . '>';
  }
  return $res;
}

######################################################################

=head3 _push_child (@childs)

Adds the elements of @childs to the objects child list.
Returns 1.

=cut 

######################################################################

sub _push_child {
  my $self = shift;
  push @{$self->{child}}, @_;
  return 1;
}

######################################################################

=head3 AUTOLOAD (\%arguments, $pcdata);

If you call an undefined method on the object this method is called
instead.

The name of the method that you tried to call will be taken as a tag
resp. element name, then C<_add> is called and returned, passing it
the name as first argument (and forwarding the other arguments).

For every tag that starts with I<_> you have to add one I<_> more
because one will be cutted of. That means that you've to call
C<__foobar(..)> to add a tag called C<_foobar>.

If you don't like that, you can always call C<_add('yourtag', ..)>.

Please see C<_add> for more information.

=cut

######################################################################

sub AUTOLOAD {
  our $AUTOLOAD =~ /::([^:]*)$/;
  return if($1 eq 'DESTROY');
  my $self = shift;
  local $_;
  $_ = $1;
  s/^_//;
  return $self->_add($_, @_);
}

######################################################################

return 1;

__END__
