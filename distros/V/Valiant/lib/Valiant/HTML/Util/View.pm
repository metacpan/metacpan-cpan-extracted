package Valiant::HTML::Util::View;

use warnings;
use strict;
use Valiant::HTML::SafeString ();

sub safe { shift; return Valiant::HTML::SafeString::safe(@_) }
sub raw { shift; return Valiant::HTML::SafeString::raw(@_) }
sub safe_concat { shift; return Valiant::HTML::SafeString::safe_concat(@_) }
sub escape_html { shift; return Valiant::HTML::SafeString::escape_html(@_) }

sub read_attribute_for_html {
  my ($self, $attribute) = @_;
  return unless defined $attribute;
  return my $value = $self->$attribute if $self->can($attribute);
  return $self->{$attribute} if exists $self->{$attribute};
  die "No such attribute '$attribute' for view"; 
}

sub attribute_exists_for_html {
  my ($self, $attribute) = @_;
  return unless defined $attribute;
  return 1 if $self->can($attribute);
  return 1 if exists $self->{$attribute};
  return;
}

sub new {
  my ($class, %attrs) = @_;
  return bless \%attrs, $class;
}

1;

=head1 NAME

Valiant::HTML::Util::View - Default view for Formbuilder

=head1 SYNOPSIS

For internal use only

=head1 DESCRIPTION

When using the L<Valiant> HTML packages (L<Valiant::HTML::FormBuilder>, L<Valiant::HTML::FormTags>
and the rest) a default view is required to provide methods for escaping strings
as well as potentially providing data.  This way we escape strings compatible with your
view template system.  If you are using these packages outside a view or template system
then we will use this package to provide those methods. Or if your template does not do
escaping (such as L<Template::Toolkit>).  You can use this as an example of how to write
an adaptor to make things like L<Valiant::HTML::FormBuilder> escape strings such that your
system works with them.

=head1 METHODS

This class defines the following instance methods.

=head2 raw

given a string return a single tagged object which is marked as safe for display.  Do not do any HTML 
escaping on the string.  This is used when you want to pass strings straight to display and that you 
know is safe.  Be careful with this to avoid HTML injection attacks.

=head2 safe

given a string return a single tagged object which is marked as safe for display.  First HTML escape the
string as safe unless its already been done (no double escaping).

=head2 safe_concat

Same as C<safe> but instead works an an array of strings (or mix of strings and safe string objects) and
concatenates them all into one big safe marked string.

=head2 escape_html

Given a string return string that has been HTML escaped.

=head2 read_attribute_for_html

Given an attribute name return the value that the view has defined for it.  

=head2 attribute_exists_for_html

Given an attribute name return true if the view has defined it.

=head1 SEE ALSO

L<Valiant>, L<Valiant::HTML::SafeString>, L<Valiant::HTML::FormBuilder>

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
