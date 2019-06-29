
=head1 NAME

Weasel::Driver::Selenium2 - Weasel driver wrapping Selenium::Remote::Driver

=head1 VERSION

0.09

=head1 SYNOPSIS

  use Weasel;
  use Weasel::Session;
  use Weasel::Driver::Selenium2;

  my %opts = (
    wait_timeout => 3000,    # 3000 msec == 3s
    window_size => '1024x1280',
    caps => {
      port => 4444,
      # ... and other Selenium::Remote::Driver capabilities options
    },
  );
  my $weasel = Weasel->new(
       default_session => 'default',
       sessions => {
          default => Weasel::Session->new(
            driver => Weasel::Driver::Selenium2->new(%opts),
          ),
       });

  $weasel->session->get('http://localhost/index');


=head1 DESCRIPTION

This module implements the L<Weasel::DriverRole> protocol, wrapping
Selenium::Remote::Driver.

=cut


=head1 DEPENDENCIES

This module wraps L<Selenium::Remote::Driver>, version 2.

=cut


package Weasel::Driver::Selenium2;

use strict;
use warnings;

use namespace::autoclean;

use MIME::Base64;
use Selenium::Remote::Driver;
use Time::HiRes qw/ time sleep /;
use Weasel::DriverRole;
use Carp;
use English qw(-no_match_vars);

use Moose;
with 'Weasel::DriverRole';

our $VERSION = '0.09';


=head1 ATTRIBUTES

=over

=item _driver

Internal. Holds the reference to the C<Selenium::Remote::Driver> instance.

=cut

has '_driver' => (is => 'rw',
                  isa => 'Selenium::Remote::Driver',
                 );

=item wait_timeout

The number of miliseconds to wait before failing to find a tag
or completing a wait condition, turns into an error.

Change by calling C<set_wait_timeout>.

=cut

has 'wait_timeout' => (is => 'rw',
                       writer => '_set_wait_timeout',
                       isa => 'Int',
    );


=item window_size

String holding '<height>x<width>', the window size to be used. E.g., to
set the window size to 1280(wide) by 1024(high), set to: '1024x1280'.

Change by calling C<set_window_size>.

=cut

has 'window_size' => (is => 'rw',
                      writer => '_set_window_size',
                      );

=item caps

Capabilities to be passed to the Selenium::Remote::Driver constructor
when C<start> is being called.  Changes won't take effect until the
session is stopped and started or restarted.

=cut

has 'caps' => (is => 'ro',
               isa => 'HashRef',
               required => 1,
              );

=back

=head1 IMPLEMENTATION OF Weasel::DriverRole

For the documentation of the methods in this section,
see L<Weasel::DriverRole>.

=over

=item implements

=cut

sub implements {
    return '0.02';
}

=item start

A few capabilities can be specified in t/.pherkin.yaml
Some can even be specified as environment variables, they will be expanded here if present.

=cut

sub start {
    my $self = shift;

    do {
        if ( defined  $self->{caps}{$_}) {
            my $capability_name = $_;
            if ( $self->{caps}{$capability_name} =~
                  /\$\{             # a dollar sign and opening brace
                   ([^\}]+)         # any character not a closing brace
                   \}/x             # a closing brace
                ) {
              $self->{caps}{$capability_name} = $ENV{$1};
            }
        }
    } for (qw/browser_name remote_server_addr version platform/);

    my $driver = Selenium::Remote::Driver->new(%{$self->caps});

    $self->_driver($driver);
    $self->set_wait_timeout($self->wait_timeout);
    $self->set_window_size($self->window_size);
    return $self->started(1);
}

=item stop

=cut

sub stop {
    my $self = shift;
    my $driver = $self->_driver;

    $driver->quit if defined $driver;
    return $self->started(0);
}

=item find_all

=cut

sub find_all {
    my ($self, $parent_id, $locator, $scheme) = @_;
    # $parent_id is either a string containing an xpath
    #   or a native Selenium::Remote::WebElement

    my @rv;
    my $_driver = $self->_driver;
    if ($parent_id eq '/html') {
        @rv = $_driver->find_elements($locator, $scheme // 'xpath');
    }
    else {
        $parent_id = $self->_resolve_id($parent_id);
        @rv = $_driver->find_child_elements($parent_id, $locator,
                                            $scheme // 'xpath');
    }
    return wantarray ? @rv : \@rv;
}

=item get

=cut

sub get {
    my ($self, $url) = @_;

    return $self->_driver->get($url);
}

=item wait_for

=cut

sub wait_for {
    my ($self, $callback, %args) = @_;

    # Do NOT use Selenium::Waiter, it eats all exceptions!
    my $end = time() + $args{retry_timeout};
    my $rv;
    while (1) {
        $rv = $callback->();
        return $rv if $rv;

        if (time() <= $end) {
            sleep $args{poll_delay};
        }
        else {
            croak 'wait_for deadline expired; consider increasing the deadline';
        }
    }

    return;
}


=item clear

=cut

sub clear {
    my ($self, $id) = @_;

    return $self->_resolve_id($id)->clear;
}

=item click

=cut

sub click {
    my ($self, $element_id) = @_;

    if (defined $element_id) {
        return $self->_scroll($self->_resolve_id($element_id))->click;
    }
    else {
        return $self->_driver->click;
    }
}

=item dblclick

=cut

sub dblclick {
    my ($self) = @_;

    return $self->_driver->dblclick;
}

=item execute_script

=cut

sub execute_script {
    my $self = shift;
    return $self->_driver->execute_script(@_);
}

=item get_attribute($id, $att_name)

=cut

sub get_attribute {
    my ($self, $id, $att) = @_;

    return $self->_resolve_id($id)->get_attribute($att);
}

=item get_page_source($fh)

=cut

sub get_page_source {
    my ($self,$fh) = @_;

    print {$fh} $self->_driver->get_page_source()
       or croak "error saving page source: $ERRNO";
    return;
}

=item get_text($id)

=cut

sub get_text {
    my ($self, $id) = @_;

    return $self->_resolve_id($id)->get_text;
}

=item is_displayed($id)

=cut

sub is_displayed {
    my ($self, $id) = @_;

    return $self->_resolve_id($id)->is_displayed;
}

=item set_attribute($id, $att_name, $value)

=cut

sub set_attribute {
    my ($self, $id, $att, $value) = @_;

    return $self->_resolve_id($id)->set_attribute($att, $value);
}

=item get_selected($id)

=cut

sub get_selected {
    my ($self, $id) = @_;

    return $self->_resolve_id($id)->is_selected;
}

=item set_selected($id, $value)

=cut

sub set_selected {
    my ($self, $id, $value) = @_;

    # Note: we're using a deprecated method here, but...
    # as long as it's there... why not?
    # The other solution is to use is_selected to verify the current state
    # and toggling by click()ing
    return $self->_resolve_id($id)->set_selected($value);
}

=item screenshot($fh)

=cut

sub screenshot {
    my ($self, $fh) = @_;

    print {$fh} MIME::Base64::decode($self->_driver->screenshot)
        or croak "error saving screenshot: $ERRNO";
    return;
}

=item send_keys($element_id, @keys)

=cut

sub send_keys {
    my ($self, $element_id, @keys) = @_;

    return $self->_resolve_id($element_id)->send_keys(@keys);
}

=item tag_name($elem)

=cut

sub tag_name {
    my ($self, $element_id) = @_;

    return $self->_resolve_id($element_id)->get_tag_name;
}

=back

=head1 SUBROUTINES/METHODS

This module implements the following methods in addition to the
Weasel::DriverRole protocol methods:

=over

=item set_wait_timeout

Sets the C<wait_timeut> attribute of the object as well as
of the Selenium::Remote::Driver object, if a session has been
started.

=cut

sub set_wait_timeout {
    my ($self, $value) = @_;
    my $driver = $self->_driver;

    $driver->set_implicit_wait_timeout($value)
        if defined $driver;
    return $self->_set_wait_timeout($value);
}

=item set_window_size

Sets the C<window_size> attribute of the object as well as the
window size of the currently active window of the Selenium::Remote::Driver
object, if a session has been started.

=cut

sub set_window_size {
    my ($self, $value) = @_;
    my $driver = $self->_driver;

    $driver->set_window_size(split /x/, $value)
        if defined $driver;
    return $self->_set_window_size($value);
}

=back

=cut

# PRIVATE IMPLEMENTATIONS


sub _resolve_id {
    my ($self, $id) = @_;

    if (ref $id) {
        return $id;
    }
    else {
        my @rv = $self->_driver->find_elements($id,'xpath');
        return (shift @rv);
    }
}

sub _scroll {
    my ($self, $id) = @_;

    $self->_driver->execute_script('arguments[0].scrollIntoView(true);',
                                   $id);
    return $id;
}

__PACKAGE__->meta()->make_immutable();

=head1 AUTHOR

Erik Huelsmann

=head1 CONTRIBUTORS

=over

=item Erik Huelsmann

=item Yves Lavoie

=back

=head1 MAINTAINERS

Erik Huelsmann

=head1 BUGS AND LIMITATIONS

Bugs can be filed in the GitHub issue tracker for the Weasel project:
 https://github.com/perl-weasel/weasel-driver-selenium2/issues

=head1 SOURCE

The source code repository for Weasel is at
 https://github.com/perl-weasel/weasel-driver-selenium2

=head1 SUPPORT

Community support is available through
L<perl-weasel@googlegroups.com|mailto:perl-weasel@googlegroups.com>.

=head1 LICENSE AND COPYRIGHT

 (C) 2016-2019  Erik Huelsmann

Licensed under the same terms as Perl.

=cut

1;

