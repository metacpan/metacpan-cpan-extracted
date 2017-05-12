
package Test::WWW::Mechanize::CGIApp;

use strict;
use warnings;

# TODO use Test::WWW::Mechanize;
use base 'Test::WWW::Mechanize';

use HTTP::Request::AsCGI;

our $VERSION = "0.05";

sub new {
  my ($class, %cnf) = @_;
  my $self;
  my $app;

  if (exists($cnf{app})) {
    $app = delete $cnf{app};
  }

  $self = $class->SUPER::new(%cnf);

  $self->app( $app ) if ($app);
  return $self;
}

sub app {
  my $self = shift;

  if (@_) {
    $self->{_app} = shift;
  }
  return $self->{_app};
}

# copied from Test::WWW:Mechanize::Catalyst and slightly localized.
sub _make_request {
    my ( $self, $request ) = @_;
    $request = _cleanup_request($request);
    $self->cookie_jar->add_cookie_header($request) if $self->cookie_jar;

    my $response = $self->_do_request( $request );

    $response->header( 'Content-Base', $request->uri );
    $response->request($request);
    $self->cookie_jar->extract_cookies($response) if $self->cookie_jar;

    # check if that was a redirect
    if (   $response->header('Location')
        && $self->redirect_ok( $request, $response ) )
      {

        # remember the old response
        my $old_response = $response;

        # *where* do they want us to redirect to?
        my $location = $old_response->header('Location');

        # no-one *should* be returning non-absolute URLs, but if they
        # are then we'd better cope with it.  Let's create a new URI, using
        # our request as the base.
        my $uri = URI->new_abs( $location, $request->uri )->as_string;

        # make a new response, and save the old response in it
        $response = $self->_make_request( HTTP::Request->new( GET => $uri ) );
        my $end_of_chain = $response;
        while ( $end_of_chain->previous )    # keep going till the end
	  {
            $end_of_chain = $end_of_chain->previous;
	  }                                          #   of the chain...
        $end_of_chain->previous($old_response);    # ...and add us to it
      }

    return $response;
  }

sub _cleanup_request {
  my $request = shift;

  $request->uri('http://localhost' . $request->uri())
    unless ( $request->uri() =~ m|^http| );

  return($request);
}

sub _do_request {
  my $self = shift;
  my $request = shift;

  my $cgi = HTTP::Request::AsCGI->new($request, %ENV)->setup;
  my $app = $self->app();

  if (defined ($app)) {
    if (ref $app) {
      if (ref $app eq 'CODE') {
	&{$app};
      }
      else {
	die "The app value is a ref to something that isn't implemented.";
      }
    }
    else {
      # use eval since the module name isn't a BAREWORD
      eval "require " . $app;

      if ($app->isa("CGI::Application::Dispatch")) {
	$app->dispatch();
      }
      elsif ($app->isa("CGI::Application")) {
	my $app = $app->new();
	$app->run();
      }
      else {
	die "Unable to use the value of app.";
      }
    }
  }
  else {
    die "App was not defined.";
  }

  return $cgi->restore->response;
}


1;

__END__

=pod

=head1 NAME

Test::WWW::Mechanize::CGIApp - Test::WWW::Mechanize for CGI::Application

=head1 SYNOPSIS

  # We're in a t/*.t test script...
  use Test::WWW::Mechanize::CGIApp;

  my $mech = Test::WWW::Mechanize::CGIApp->new;

  # test a class that uses CGI::Application calling semantics.
  # (in this case we'll new up an instance of the app and call
  # its ->run() method)
  #
  $mech->app("My::WebApp");
  $mech->get_ok("?rm=my_run_mode&arg1=1&arg2=42");

  # test a class that uses CGI::Application::Dispatch
  # to locate the run_mode
  # (in this case we'll just call the ->dispatch() class method).
  #
  my $dispatched_mech = Test::WWW::Mechanize::CGIApp->new;
  $dispatched_mech->app("My::DispatchApp");
  $mech->get_ok("/WebApp/my_run_mode?arg1=1&arg2=42");

  # create an anonymous sub that this class will use to
  # handle the request.
  #
  # this could be useful if you need to do something novel
  # after creating an instance of your class (e.g. the
  # fiddle_with_stuff() below) or maybe you have a unique
  # way to get the app to run.
  #
  my $custom_mech = Test::WWW::Mechanize::CGIApp->new;
  $custom_mech->app(
     sub {
       require "My::WebApp";
       my $app = My::WebApp->new();
       $app->fiddle_with_stuff();
       $app->run();
     });
  $mech->get_ok("?rm=my_run_mode&arg1=1&arg2=42");

  # at this point you can play with all kinds of cool
  # Test::WWW::Mechanize testing methods.
  is($mech->ct, "text/html");
  $mech->title_is("Root", "On the root page");
  $mech->content_contains("This is the root page", "Correct content");
  $mech->follow_link_ok({text => 'Hello'}, "Click on Hello");
  # ... and all other Test::WWW::Mechanize methods

=head1 DESCRIPTION

This package makes testing CGIApp based modules fast and easy.  It takes
advantage of L<Test::WWW::Mechanize> to provide functions for common
web testing scenarios. For example:

  $mech->get_ok( $page );
  $mech->title_is( "Invoice Status",
                   "Make sure we're on the invoice page" );
  $mech->content_contains( "Andy Lester", "My name somewhere" );
  $mech->content_like( qr/(cpan|perl)\.org/,
                      "Link to perl.org or CPAN" );

For applications that inherit from CGI::Application it will handle
requests by creating a new instance of the class and calling its
C<run> method.  For applications that use CGI::Application::Dispatch
it will call the C<dispatch> class method.  If neither of these
options are the right thing, you can set a reference to a sub that
will be used to handle the request.

This module supports cookies automatically.

Check out L<Test::WWW::Mechanize> for more information about all of
the cool things you can test!

=head1 CONSTRUCTOR

=head2 new

Behaves like, and calls, L<Test::WWW::Mechanize>'s C<new> method.  It
optionally uses an "app" parameter (see below), any other
parameters get passed to Test::WWW::Mechanize's constructor. Note
that you can either pass the name of the CGI::Application into the
constructor using the "app" parameter or set it later using the C<app>
method.

  use Test::WWW::Mechanize::CGIApp;
  my $mech = Test::WWW::Mechanize::CGIApp->new;

  # or

  my $mech = Test::WWW::Mechanize::CGIApp->new(app => 'TestApp');

=head1 METHODS

=head2 $mech->app($app_handler)

This method provides a mechanism for informing
Test::WWW::Mechanize::CGIApp how it should go about executing your
run_mode.  If you set it to the name of a class, then it will load the
class and either create an instance and ->run() it (if it's
CGI::Application based), invoke the ->dispatch() method if it's
CGI::Application::Dispatch based, or call the supplied anonymous
subroutine and let it do all of the heavy lifting.

=head1 SEE ALSO

Related modules which may be of interest: L<Test::WWW::Mechanize>,
L<WWW::Mechanize>.

Various implementation tricks came from
L<Test::WWW::Mechanize::Catalyst>.

=head1 AUTHOR

George Hartzell, C<< <hartzell@alerce.com> >>

based on L<Test::WWW::Mechanize::Catalyst> by Leon Brocard, C<< <acme@astray.com> >>.

=head1 COPYRIGHT

Copyright (C) 2007, George Hartzell

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
