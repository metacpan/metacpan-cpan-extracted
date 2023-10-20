package Valiant::HTML::SafeString;

use warnings;
use strict;
use Exporter 'import';
use HTML::Escape ();
use Scalar::Util (); 
use Carp;

use overload 
  bool => sub { shift->to_bool }, 
  '""' => sub { shift->to_string },
  '+' => sub {
    my ($self, $other, $reverse) = @_;
    croak "Can only join two safe string objects" unless (ref($other) eq ref($self));
  
    return $reverse
        ? raw("${other}${self}")
        : raw("${self}${other}");
  },
  fallback => 1;

our @EXPORT_OK = qw(raw flattened_raw safe flattened_safe is_safe escape_html safe_concat concat);
our %EXPORT_TAGS = (all => \@EXPORT_OK, core => ['raw', 'safe', 'escape_html', 'safe_concat']);

sub _make_safe {
  my $string_to_make_safe = shift;
  return bless(\$string_to_make_safe, 'Valiant::HTML::SafeString');
}

sub escape_html {
  my $string = shift;
  return HTML::Escape::escape_html($string);
}

sub raw {
  if(scalar(@_) == 1) {
    return is_safe($_[0]) ? $_[0] : _make_safe($_[0])
  } else {
    return map { is_safe($_) ? $_ : _make_safe($_) } @_;
  }
}

sub flattened_raw {
  my $string = join '', map { is_safe($_) ? $_->to_string : $_ } @_;
  return _make_safe $string;
}

sub is_safe {
  my $string_to_test = shift;
  return 0 unless defined($string_to_test);
  return 0 unless
    ((Scalar::Util::blessed($string_to_test)||'') eq 'Valiant::HTML::SafeString') || 
    ((Scalar::Util::blessed($string_to_test)||'') eq 'Mojo::ByteStream');
  return 1;
}

sub safe {
  if(scalar(@_) == 1) {
    return is_safe($_[0]) ? $_[0] : _make_safe(escape_html($_[0]))
  } else {
    return map { is_safe($_) ? $_ : _make_safe(escape_html($_)) } @_;
  }
}

sub safe_concat { return flattened_safe(@_) }

sub flattened_safe {
  my $string = join '', map { is_safe($_) ? $_->to_string : escape_html($_) } grep { defined($_) } @_;
  return _make_safe $string;
}

sub new {
  my $class = shift;
  return flattened_safe(@_);
}

sub concat { return flattened_safe(@_) }

sub to_string { return ${$_[0]} }

sub to_bool { return ${$_[0]} ? 1 : 0 }

sub append {
  my ($self, @rest) = @_;
  my $string = join '', map { is_safe($_) ? $_->to_string : escape_html($_) } grep { defined($_) } @rest;
  ${$self} .= $string;
}

1;

=head1 NAME

Valiant::HTML::SafeString - String rendering safety

=head1 SYNOPSIS

  use Valiant::HTML::SafeString 'safe', 'escape';

=head1 DESCRIPTION

Protecting your templates from the various types of character injection attacks is
a prime concern for anyone working with the HTML user interface.  This class provides
some methods and exports to make this job easier.

=head1 EXPORTABLE FUNCTIONS

The following functions can be exported by this library

=head2 safe

Given a string or array, returns such marked as 'safe' by using C<html_escape> on the string and
then encapsulating it inside an instance of L<Valiant::HTML::SafeString>. You can safely pass arguments
to this since if the string is already marked safe we just return it unaltered.

=head2 flattened_safe

Same as C<safe> but always returns a string even if you pass an array of strings (they are all
joined together).

=head2 raw

Given a string or array of strings, return each marked as safe (by encapsulating it inside an
instance of L<Valiant::HTML::SafeString>.  This will just mark strings as safe without doing any
escaping first (for that see C<safe>) so be careful with this.

=head2 flattened_raw

Same as C<raw> but always returns a string even if you pass an array of strings (they are all
joined together).

=head2 is_safe

Given a string return a boolean indicating if its marked safe or not.  Since C<safe> and C<raw> never
double the escapulations / escaping, you probably never need this but saw no reason to not expose it.

=head2 escape_html

A wrapper on L<HTML::Escape> just to make your life a bit easier

=head1 CLASS METHODS

This package exposes the folllowing class methods

=head2 new

    my $safe_string = Valiant::HTML::SafeString->new(@strings);

Given a string, or array of strings, returns a single string that has been C<html_escape>'d as needed
and encapulated in an instance.  Its safe to pass arguments to this without testing since if a string
is already marked safe we don't do any extra escaping (although you will get a new instance).

=head1 INSTANCE METHODS

Instances of L<Valiant::HTML::SafeString> expose the following public methods

=head2 concat

Returns a new safe string which appends a list of strings to the old one, making those new strings
'safe' as needed.  Basically this will escape any strings not marked safe already and then joins them
altogether in a single safe string.

=head2 to_string

Returns the raw string, suitable for display.

=head2 to_bool

Returns a boolean indicating if the string is empty or not.

=head1 OVERLOADING

String context calles C<to_string>; Boolean context returns true unless the string is empty.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
