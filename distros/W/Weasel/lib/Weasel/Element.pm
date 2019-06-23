
=head1 NAME

Weasel::Element - The base HTML/Widget element class

=head1 VERSION

0.02

=head1 SYNOPSIS

   my $element = $session->page->find("./input[\@name='phone']");
   my $value = $element->send_keys('555-885-321');

=head1 DESCRIPTION

This module provides the base class for all page elements, encapsulating
the regular element interactions, such as finding child element, querying
attributes and the tag name, etc.

=cut

=head1 DEPENDENCIES



=cut

package Weasel::Element;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

=head1 ATTRIBUTES

=over

=item session

Required.  Holds a reference to the L<Weasel::Session> to which the element
belongs.  Used to access the session's driver to query element properties.x

=cut

has session => (is => 'ro',
                isa => 'Weasel::Session',
                required => 1,
    );

=item _id

Required.  Holds the I<element_id> used by the session's driver to identify
the element.

=cut

has _id => (is => 'ro',
            required => 1);

=back

=head1 SUBROUTINES/METHODS

=over

=item find($locator [, scheme => $scheme] [, widget_args => \@args ] [, %locator_args])

Finds the first child element matching c<$locator>.  Returns C<undef>
when not found.  Optionally takes a scheme argument to identify non-xpath
type locators.

In case the C<$locator> is a mnemonic (starts with an asterisk ['*']),
additional arguments may be provided for expansion of the mnemonic.  See
L<Weasel::FindExpanders::HTML> for documentation of the standard expanders.

Any arguments passed in the C<$widget_args> array reference, are passed to
the widget's constructor.

=cut

sub find {
    my ($self, @args) = @_;

    return $self->session->find($self, @args);
}

=item find_all($locator [, scheme => $scheme] [, widget_args => \@args ] [, %locator_args])

Returns, depending on scalar vs array context, a list or an arrayref
with matching elements.  Returns an empty list or ref to an empty array
when none found.  Optionally takes a scheme argument to identify non-xpath
type locators.

In case the C<$locator> is a mnemonic (starts with an asterisk ['*']),
additional arguments may be provided for expansion of the mnemonic.  See
L<Weasel::FindExpanders::HTML> for documentation of the standard expanders.

Any arguments passed in the C<$widget_args> array reference, are passed to
the widget's constructor.

=cut

sub find_all {
    my ($self, @args) = @_;

    # expand $locator based on framework plugins (e.g. Dojo)
    return $self->session->find_all($self, @args);
}

=item get_attribute($attribute)

Returns the value of the element's attribute named in C<$attribute> or
C<undef> if none exists.

Note: Some browsers apply default values to attributes which are not
  part of the original page.  As such, there's no direct relation between
  the existence of attributes in the original page and this function
  returning C<undef>.

Note: Those users familiar with Selenium might be looking for a method
  called C<is_selected> or C<set_selected>. Weasel doesn't have that
  short-hand. Please use C<get_attribute>/C<set_attribute> with an
  attribute name of C<selected> instead.

=cut

sub get_attribute {
    my ($self, $attribute) = @_;

    return $self->session->get_attribute($self, $attribute);
}

=item set_attribute($attribute, $value)

Sets the value of the element's attribute named in C<$attribute>.

Note: Those users familiar with Selenium might be looking for a method
  called C<is_selected> or C<set_selected>. Weasel doesn't have that
  short-hand. Please use C<get_attribute>/C<set_attribute> with an
  attribute name of C<selected> instead.

=cut

sub set_attribute {
    my ($self, $attribute, $value) = @_;

    return $self->session->set_attribute($self, $attribute, $value);
}

=item get_text()

Returns the element's 'innerHTML'.

=cut

sub get_text {
    my ($self) = @_;

    return $self->session->get_text($self);
}


=item has_class

=cut

sub has_class {
    my ($self, $class) = @_;

    return grep { $_ eq $class }
        split /\s+/x, ($self->get_attribute('class') // '');
}

=item is_displayed

Returns a boolean indicating if an element is visible (e.g.
can potentially be scrolled into the viewport for interaction).

=cut

sub is_displayed {
    my ($self) = @_;

    return $self->session->is_displayed($self);
}

=item click()

Scrolls the element into the viewport and simulates it being clicked on.

=cut

sub click {
    my ($self) = @_;
    return $self->session->click($self);
}

=item send_keys(@keys)

Focusses the element and simulates keyboard input. C<@keys> can be any
number of strings containing unicode characters to be sent.  E.g.

   $element->send_keys("hello", ' ', "world");

=cut

sub send_keys {
    my ($self, @keys) = @_;

    return $self->session->send_keys($self, @keys);
}

=item tag_name()

Returns the name of the tag of the element, e.g. 'div' or 'input'.

=cut

sub tag_name {
    my ($self) = @_;

    return $self->session->tag_name($self);
}

=back

=cut

=head1 AUTHOR

Erik Huelsmann

=head1 CONTRIBUTORS

Erik Huelsmann
Yves Lavoie

=head1 MAINTAINERS

Erik Huelsmann

=head1 BUGS AND LIMITATIONS

Bugs can be filed in the GitHub issue tracker for the Weasel project:
 https://github.com/perl-weasel/weasel/issues

=head1 SOURCE

The source code repository for Weasel is at
 https://github.com/perl-weasel/weasel

=head1 SUPPORT

Community support is available through
L<perl-weasel@googlegroups.com|mailto:perl-weasel@googlegroups.com>.

=head1 LICENSE AND COPYRIGHT

 (C) 2016-2019  Erik Huelsmann

Licensed under the same terms as Perl.

=cut


__PACKAGE__->meta->make_immutable;

1;

