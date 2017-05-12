#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007,2009 -- leonerd@leonerd.org.uk

package XML::Filter::Conditional;

use strict;
use warnings;
use base qw( XML::SAX::Base );

use Carp;

our $VERSION = '0.05';

=head1 NAME

C<XML::Filter::Conditional> - an XML SAX filter for conditionally ignoring XML
content

=head1 SYNOPSIS

CODE:

 package My::XML::Filter;
 use base qw( XML::Filter::Conditional );

 sub store_switch
 {
    my $self = shift;
    my ( $e ) = @_;

    my $ename = $e->{Attributes}{'{}env'}{Value};
    return $ENV{$ename};
 }

 sub eval_case
 {
    my $self = shift;
    my ( $value, $e ) = @_;

    return $value eq $e->{Attributes}{'{}value'}{Value};
 }

XML:

 <message>
   <switch env="USER">
     <case value="root">Hello there, root user</case>
     <case value="mail">Hello there, mail user</case>
     <otherwise>Hello, whoever you are</otherwise>
   </switch>
 </message>

=head1 DESCRIPTION

This module provides an abstract base class to implement a PerlSAX filter
which conditionally ignores part of the XML content. The base class provides
the implememtation of actually surpressing SAX events for filtering purposes,
and delegates the evaluation of matches to the subclassed instance.

The evaluation of the matches is performed by the abstract methods
C<store_switch()> and C<eval_case()>; see their detail below.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $filter = XML::Filter::Conditional->new( %opts )

Takes the following options:

=over 8

=item Handler => OBJECT

The PerlSAX handler (or another filter) that will receive the PerlSAX events
from this filter.

=item SwitchTag => STRING or REGEXP

=item CaseTag => STRING or REGEXP

=item OtherwiseTag => STRING or REGEXP

Changes the tag names used for the C<switch>, C<case> and C<otherwise>
elements. Can be precompiled regexp values instead of literal strings. The
values will be matched against the local name of the tag only, ignoring any
namespace prefix.

=item NamespaceURI => STRING

If present, the tags will only be recognised if they are part of the given
namespace. Defaults to the empty string, meaning tags will only be recognised
if they do not have a namespace prefix, and no default namespace was defined
for the document.

=item MatchAll => BOOLEAN

Determines whether all of the matching C<< <case> >> elements will be used, or
only the first one that matches. By default, only the first matching one will
be used.

=back

=cut

sub new
{
   my $class = shift;
   my %opts = @_;

   # Check that the abstract methods are implemented

   $class->can( "store_switch" ) or
      croak "$class must provide ->store_switch()";
   $class->can( "eval_case" ) or
      croak "$class must provide ->eval_case()";

   my $switchtag    = delete $opts{SwitchTag}    || "switch";
   my $casetag      = delete $opts{CaseTag}      || "case";
   my $otherwisetag = delete $opts{OtherwiseTag} || "otherwise";

   $opts{NamespaceURI} ||= "";

   my $self = $class->SUPER::new( %opts );

   $self->{switch_stack} = [];

   $self->{switchre}    = ref($switchtag) eq "Regexp" ?
                             $switchtag :
                             qr/^\Q$switchtag\E$/;

   $self->{casere}      = ref($casetag) eq "Regexp" ?
                             $switchtag :
                             qr/^\Q$casetag\E$/;

   $self->{otherwisere} = ref($otherwisetag) eq "Regexp" ?
                             $otherwisetag :
                             qr/^\Q$otherwisetag\E$/;

   return $self;
}

# We'll keep a little state machine
# <switch>
#   outside
#   <case thatmatches> in hot  </case>
#   <case> in cold </case>
# </switch>

use constant STATE_SWITCH_OUTSIDE => 1;
use constant STATE_SWITCH_INHOT   => 2;
use constant STATE_SWITCH_INCOLD  => 3;

# Define an exception subclass
@XML::Filter::Conditional::Exception::ISA = qw( XML::SAX::Exception );

sub throw_exception
{
   my $self = shift;
   my ( $message ) = @_;

   my %args = ( Message => $message );

   if( defined( my $locator = $self->{Locator} ) ) {
      $args{$_} = $locator->{$_} for (qw( LineNumber ColumnNumber ));
   }

   XML::Filter::Conditional::Exception->throw( %args );
}

sub set_document_locator
{
   my $self = shift;
   my ( $locator ) = @_;

   $self->{Locator} = $locator;

   $self->SUPER::set_document_locator( $locator );
}

sub start_element
{
   my $self = shift;
   my ( $e ) = @_;

   my $name = $e->{LocalName};

   my $right_namespace = ( ($e->{NamespaceURI}||"") eq $self->{NamespaceURI} );

   if( $right_namespace and $name =~ $self->{switchre} ) {
      push @{ $self->{switch_stack} }, 
         {
            state   => STATE_SWITCH_OUTSIDE,
            didcase => 0,
         };

      $self->{switch_state} = $self->{switch_stack}[-1];

      $self->{switch_state}{cond} = $self->store_switch( $e );

      return; # EAT
   }
   elsif( $right_namespace and $name =~ $self->{casere} ) {
      my $state = $self->{switch_state}{state};

      defined $state or
         $self->throw_exception( "Found a <$name> element outside of a containing switch" );

      $state == STATE_SWITCH_OUTSIDE or
         $self->throw_exception( "Found a <$name> element nested within another" );

      if( $self->{MatchAll} or !$self->{switch_state}{didcase} ) {
         if( $self->eval_case( $self->{switch_state}{cond}, $e ) ) {
            $self->{switch_state}{state} = STATE_SWITCH_INHOT;
            return; # EAT
         }
      }

      $self->{switch_state}{state} = STATE_SWITCH_INCOLD;
      return; # EAT
   }
   elsif( $right_namespace and $name =~ $self->{otherwisere} ) {
      my $state = $self->{switch_state}{state};

      defined $state or
         $self->throw_exception( "Found a <$name> element outside of a containing switch" );

      $state == STATE_SWITCH_OUTSIDE or
         $self->throw_exception( "Found a <$name> element nested within another" );

      # Treat it like a case which might be true

      if( !$self->{switch_state}{didcase} ) {
         $self->{switch_state}{state} = STATE_SWITCH_INHOT;
         return; # EAT
      }

      $self->{switch_state}{state} = STATE_SWITCH_INCOLD;
      return; # EAT
   }
   else {
      my $state = $self->{switch_state}{state};
      if( defined $state and $state == STATE_SWITCH_INCOLD ) {
         return; # EAT
      }
   }

   return $self->SUPER::start_element( $e );
}

sub end_element
{
   my $self = shift;
   my ( $e ) = @_;

   my $name = $e->{LocalName};

   my $right_namespace = ( ($e->{NamespaceURI}||"") eq $self->{NamespaceURI} );

   my $state = $self->{switch_state}{state};

   if( $right_namespace and $name =~ $self->{switchre} ) {
      pop @{ $self->{switch_stack} };
      $self->{switch_state} = $self->{switch_stack}[-1];

      return; # EAT
   }
   elsif( $right_namespace and $name =~ $self->{casere} ) {
      if( $state == STATE_SWITCH_INHOT ) {
         $self->{switch_state}{didcase} = 1;
      }

      $self->{switch_state}{state} = STATE_SWITCH_OUTSIDE;

      return; # EAT
   }
   elsif( $right_namespace and $name =~ $self->{otherwisere} ) {
      return; # EAT
   }
   else {
      return if( defined $state and $state == STATE_SWITCH_INCOLD );
   }

   return $self->SUPER::end_element( $e );
}

sub _surpress
{
   my $self = shift;

   my $state = $self->{switch_state}{state};

   if( defined $state and $state == STATE_SWITCH_INCOLD ) {
      return 1;
   }

   return 0;
}

sub characters
{
   my $self = shift;
   my ( $e ) = @_;

   return if $self->_surpress;

   return $self->SUPER::characters( $e );
}

sub comment
{
   my $self = shift;
   my ( $e ) = @_;

   return if $self->_surpress;

   return $self->SUPER::comment( $e );
}

sub processing_instruction
{
   my $self = shift;
   my ( $e ) = @_;

   return if $self->_surpress;

   return $self->SUPER::processing_instruction( $e );
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 ABSTRACT METHODS

The following methods must be implemented by any instance of this class which
is constructed.

=head2 $value = $self->store_switch( $e )

This method is called when a C<switch> element is entered. It is passed the
PerlSAX node in the C<$e> parameter. The value it returns, in scalar context,
is stored by the object, to pass into any C<eval_case()> methods which may
apply to this element.

This method helps to keep the case evaluations efficient, by allowing the
evaluation logic to precompute whatever values it might find useful once, to
be reused by the cases themselves. See the SYNOPSIS section for an example.

=head2 $bool = $self->eval_case( $value, $e )

This method is called when a C<case> element is found, to determine whether it
should be considered to match. It is passed whatever the earlier
C<store_switch()> method returned as the C<$value> parameter, and the PerlSAX
node as the C<$e> parameter. It should return a value, whose truth will be
used to determine if the case matches.

See the SYNOPSIS section for an example.

=cut

=head1 SEE ALSO

=over 4

=item *

L<XML::SAX> - Simple API for XML

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut
