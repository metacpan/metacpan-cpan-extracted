
=head1 NAME

Weasel::DriverRole - API definition for driver wrappers

=head1 VERSION

0.02

=head1 SYNOPSIS

  use Moose;
  use Weasel::DriverRole;

  with 'Weasel::DriverRole';

  ...  # (re)implement the functions in Weasel::DriverRole

=head1 DESCRIPTION

This module defines the API for all Weasel drivers to be implemented.

By using this role in the driver implementation module, an abstract
method is implmented croak()ing if it's called.

=cut

package Weasel::DriverRole;

use strict;
use warnings;

use Carp;
use Moose::Role;

our $VERSION = '0.02';

=head1 ATTRIBUTES

=over

=item started

Every session is associated with a driver instance. The C<started> attribute
holds a boolean value indicating whether or not the driver is ready to
receive driver commands.

The value managed by the C<start> and C<stop> methods.

=cut

has 'started' => (is => 'rw',
                  isa => 'Bool',
                  default => 0);

=back

=head1 METHODS

=over

=item implements

This method returns the version number of the API which it fully
implements.

L<Weasel::Session> may carp (warn) the user about mismatching API levels
in case a driver is coded against an earlier version than
C<$Weasel::DriverRole::VERSION>.

=cut

sub implements {
    # returning a too-old number with intent: we want warnings if this
    #  method hasn't been implemented by the driver
    return '0.00';
}

=item start

This method allows setup of the driver. It is invoked before any web
driver methods as per the Web driver methods section below.

=cut

sub start { my $self = shift; $self->started(1); }

=item stop

This method allows tear-down of the driver. After tear-down, the C<start>
method may be called again, so the this function should leave the driver
in a restartable state.

=cut

sub stop { my $self = shift; $self->started(0); }

=item restart

This function stops (if started) and starts the driver.


=cut

sub restart { my $self = shift; $self->stop; $self->start; }

=back

=head2 Web driver methods

=head3 Terms

=over

=item element_id / parent_id

These are opaque values used by the driver to identify DOM elements.

Note: The driver should always accept an xpath locator as an id value
  as well as id values returned from earlier driver calls


=back


=head3 API

=over

=item find_all( $parent_id, $locator, $scheme )

Returns the _id values for the elements to be instanciated, matching
the C<$locator> using C<scheme>.

Depending on array or scalar context, the return value is
a list or an arrayref.

Note: there's no function to find a single element. That function
is implemented on the C<Weasel::Session> level.

=cut

sub find_all {
    croak "Abstract inteface method 'find_all' called";
}

=item get( $url )

Loads the page at C<$url> into the driver's browser (browser emulator).

The C<$url> passed in has been expanded by C<Weasel::Session>, prepending
a registered prefix.

=cut

sub get {
    croak "Abstract interface method 'get' called";
}

=item is_displayed($element_id)

Returns a boolean value indicating whether the element indicated by
C<$element_id> is interactable (can be selected, clicked on, etc)

=cut

sub is_displayed {
    croak "Abstract interface method 'is_displayed' called";
}

=item wait_for( $callback, retry_timeout => $num, poll_delay => $num )

The driver may interpret the 'poll_delay' in one of two ways:
 1. The 'poll_delay' equals the number of seconds between the start of
    successive poll requests
 2. The 'poll_delay' equals the number of seconds to wait between the end
    of one poll request and the start of the next

Note: The user should catch inside the callback any exceptions that are
  thrown inside the callback, unless such exceptions are allowed to
  terminate further polling attempts.
  I.e. this function doesn't guard against early termination by
  catching exceptions.

=cut

sub wait_for {
    croak "Abstract interface method 'wait_for' called";
}


=item clear($element_id)

Clicks on an element if an element id is provided, or on the current
mouse location otherwise.

=cut

sub clear {
    croak "Abstract interface method 'clear' called";
}

=item click( [ $element_id ] )

Clicks on an element if an element id is provided, or on the current
mouse location otherwise.

=cut

sub click {
    croak "Abstract interface method 'click' called";
}

=item dblclick()

Double clicks on the current mouse location.

=cut

sub dblclick {
     croak "Abstract interface method 'dblclick' called";
}

=item get_attribute($element_id, $attribute_name)

Returns the value of the attribute named by C<$attribute_name>
of the element indicated by C<$element_id>.

=cut

sub get_attribute {
    croak "Abstract interface method 'get_attribute' called";
}

=item get_page_source($fh)

Writes a get_page_source of the browser's window to the filehandle C<$fh>.

=cut

sub get_page_source {
    croak "Abstract interface method 'get_page_source' called";
}

=item get_text($element_id)

Returns the HTML content of the element identified by C<$element_id>,
the so-called 'innerHTML'.

=cut

sub get_text {
    croak "Abstract interface method 'get_text' called";
}

=item set_attribute($element_id, $attribute_name, $value)

Changes the value of the attribute named by C<$attribute_name> to C<$value>
for the element identified by C<$element_id>.

=cut

sub set_attribute {
    croak "Abstract interface method 'set_attribute' called";
}

=item get_selected($element_id)

=cut

sub get_selected {
    croak "Abstract interface method 'get_selected' called";
}

=item set_selected($element_id, $value)

=cut

sub set_selected {
    croak "Abstract interface method 'set_selected' called";
}

=item screenshot($fh)

Takes a screenshot and writes the image to the file handle C<$fh>.

Note: In the current version of the driver, it's assumed the
  driver writes a PNG image. Later versions may add APIs to
  get/set the type of image generated.

=cut

sub screenshot {
    croak "Abstract interface method 'screenshot' called";
}

=item send_keys($element_id, @keys)

Simulates key input into the element identified by C<$element_id>.

C<@keys> is an array of (groups of) inputs; multiple multi-character
strings may be listed. In such cases the input will be appended. E.g.

  $driver->send_keys($element_id, "hello", ' ', "world");

is valid input to enter the text "hello world" into C<$element_id>.


Note: Special keys are encoded according to the WebDriver spec.
 In case a driver implementation needs differentt encoding of
 special keys, this function should recode from the values
 found in WebDriver::KEYS() to the desired code-set


=cut

sub send_keys {
    croak "Abstract interface method 'send_keys' called";
}

=item tag_name($element_id)

The name of the HTML tag identified by C<$element_id>.

=cut

sub tag_name {
    croak "Abstract interface method 'tag_name' called";
}

=back

=head1 SEE ALSO

L<Weasel>

=head1 COPYRIGHT

 (C) 2016  Erik Huelsmann

Licensed under the same terms as Perl.

=cut



1;
