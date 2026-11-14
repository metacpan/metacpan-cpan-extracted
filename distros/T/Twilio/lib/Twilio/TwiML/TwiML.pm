package Twilio::TwiML::TwiML;

use 5.016;
use warnings;

use overload
  q{""}    => sub { $_[0]->as_xml },
  bool     => sub { 1 },
  fallback => 1;

use Scalar::Util qw(blessed);

use Twilio::Json;
use Twilio::Serialize;

our $VERSION = '2.002';

my $DECLARATION = qq{<?xml version="1.0" encoding="UTF-8"?>\n};

my %TEXT_ESCAPE      = ('&' => '&amp;', '<' => '&lt;', '>' => '&gt;', "\r" => '&#13;');
my %ATTRIBUTE_ESCAPE = (%TEXT_ESCAPE, q{"} => '&quot;', "\n" => '&#10;', "\t" => '&#9;');

sub new {
  my ($class, $name, $value, $attributes) = @_;

  my $self = bless { name => $name, attributes => {}, children => [defined $value ? $value : ()] },
    $class;

  my %given = %{ $attributes // {} };
  $self->set_attribute($_, $given{$_}) for sort keys %given;
  return $self;
}

sub append {
  my ($self, $child) = @_;
  push @{ $self->{children} }, $child;
  return $self;
}

sub nest {
  my ($self, $child) = @_;
  push @{ $self->{children} }, $child;
  return $child;
}

sub set_attribute {
  my ($self, $name, $value) = @_;

  # A name no element knows is written as it is, so new TwiML works before this library has it.
  my $known = $self->attribute_table->{$name};
  if ($known) {
    $name  = $known->{name};
    $value = Twilio::Serialize::boolean_to_string($value) if $known->{boolean};
  }
  $self->{attributes}{$name} = $value;
  return $self;
}

sub attribute_table { return {} }

sub add_child {
  my ($self, $name, $value, $attributes) = @_;
  require Twilio::TwiML::GenericNode;
  return $self->nest(Twilio::TwiML::GenericNode->new($name, $value, $attributes));
}

sub as_xml {
  my ($self) = @_;
  return $DECLARATION . $self->_element . "\n";
}

sub _element {
  my ($self) = @_;

  my $attributes = join q{}, map { $self->_attribute($_) } sort keys %{ $self->{attributes} };
  my $start      = "<$self->{name}$attributes";
  return "$start/>" if !@{ $self->{children} };

  my $content = join q{}, map { _child($_) } @{ $self->{children} };
  return "$start>$content</$self->{name}>";
}

# Any other object is text by its own conversion, such as a URI given to <Play>. A hash or an
# array is written as JSON, the content <Task> takes, as twilio-python does.
sub _child {
  my ($child) = @_;
  return $child->_element if blessed($child) && $child->isa(__PACKAGE__);

  my $text = ref $child eq 'HASH' || ref $child eq 'ARRAY' ? Twilio::Json::encode($child) : $child;
  return _escaped($text, \%TEXT_ESCAPE, qr/[&<>\r]/);
}

sub _attribute {
  my ($self, $name) = @_;

  my $value = $self->{attributes}{$name};
  return q{} if !defined $value;

  my $text = _escaped(_attribute_text($value), \%ATTRIBUTE_ESCAPE, qr/[&<>\r\n\t"]/);
  return qq{ $name="$text"};
}

# A JSON boolean and a reference to 1 or 0 say true or false. Elements that know an attribute is
# a boolean turn a plain Perl value into one of these first.
sub _attribute_text {
  my ($value) = @_;

  return join q{ }, @{$value} if ref $value eq 'ARRAY';
  return ${$value} ? 'true' : 'false' if ref $value eq 'SCALAR';
  return $value    ? 'true' : 'false' if blessed($value) && $value->isa('JSON::PP::Boolean');
  return "$value";
}

# Text may arrive as characters or as UTF-8 bytes, as in the rest of the library, and the
# document says it is UTF-8.
sub _escaped {
  my ($text, $escapes, $pattern) = @_;

  my $encoded = "$text";
  utf8::encode($encoded) if utf8::is_utf8($encoded);
  $encoded =~ s/($pattern)/$escapes->{$1}/g;
  return $encoded;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Twilio::TwiML::TwiML - Base class of every TwiML element

=head1 SYNOPSIS

  use Twilio::TwiML::GenericNode;

  my $response = Twilio::TwiML::GenericNode->new('Response');
  my $say      = $response->add_child('Say', 'Hello', { voice => 'alice' });
  $say->set_attribute(language => 'es-MX');

  print $response->as_xml;

=head1 DESCRIPTION

Builds a TwiML document as a tree of elements, and writes it the way twilio-php
does. An element converts to its document in string context, so it can be printed
directly.

Attributes are written in alphabetical order, because a Perl hash has no order of
its own. Twilio does not depend on the order. An attribute with an undefined value
is left out.

Text can be given as characters or as UTF-8 bytes. The document is returned as
UTF-8 bytes, ready to send, so do not add an encoding layer when printing it.

=head1 METHODS

=head2 new

  my $element = Twilio::TwiML::TwiML->new($name, $value, \%attributes);

=head2 append

  $element->append('Some text');
  $element->append($other_element);

Adds text or an element at the end, and returns C<$element>.

=head2 nest

  my $child = $element->nest($other_element);

Adds an element at the end, and returns that element.

=head2 add_child

  my $child = $element->add_child($name, $value, \%attributes);

Adds a new element with any name, for TwiML this library does not know about, and
returns it.

=head2 set_attribute

  $element->set_attribute(name => 'value');

Sets an attribute and returns C<$element>. An array reference is written as a list
separated by spaces, and a reference to 1 or 0 as C<true> or C<false>. A name the
element does not know is written as it is.

=head2 attribute_table

Returns what each element knows about its attributes. Generated elements use it to
turn C<send_digits> into C<sendDigits>, and a Perl true value into C<true>.

=head2 as_xml

Returns the document, with the XML declaration.

=head1 LICENSE

Copyright (c) 2026 Francisco Zarabozo. Released under the MIT License.

=cut
