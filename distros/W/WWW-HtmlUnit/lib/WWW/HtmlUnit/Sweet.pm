package WWW::HtmlUnit::Sweet;

=head1 NAME

WWW::HtmlUnit::Sweet - Wrapper around WWW::HtmlUnit to add some sweetness

=head1 SYNOPSIS

  use WWW::HtmlUnit::Sweet;
  my $agent = WWW::HtmlUnit::Sweet->new;

  $agent->getPage('http://google.com/');

  # Type into the currently focused element
  $agent->type("Hello\n");

  # Print out the XML of the page
  print $agent->asXml;

=head1 DESCRIPTION

Using L<WWW::HtmlUnit> as a foundation, this adds some convenience things. The main addition is that the $agent you get from ->new does some AUTOLOAD things to allow you to treat the $agent as either a browser, a window, or a page. That way you can treat it a lot more like a L<WWW::Mechanize> object.

This module might change drastically, buyer beware!

=head1 IMPORT PARAMETERS

When you 'use' this module, you can pass some parameters. Any parameter that L<WWW::HtmlUnit::Sweet> doesn't use will be passed on to L<WWW::HtmlUnit>, or ultimately L<Inline::Java>.

=over 4

=item * show_errors - Flag to stop the supression of stderr

=item * error_filename - Filename to append stderr to

=item * error_fh - Filehandle to append stderr to

=item * errors_to_tmpfile - Send stderr to a temporary file (L<IO::File>)

=back 4

Useful examples:

  # Show errors on STDERR
  use WWW::HtmlUnit::Sweet show_errors => 1;

  # Append errors to /tmp/errors.txt
  use WWW::HtmlUnit::Sweet error_filename => '/tmp/errors.txt';

Note that if you don't pass anything, errors will be sent to /dev/null (or a temporary file if you don't have /dev/null).

=cut

use strict;
use warnings;

# Hold our error filehandle
our $error_fh;

sub import {
  my $class = shift;
  my %parameters = @_;

  if($parameters{show_errors}) {
    delete $parameters{show_errors};
    require WWW::HtmlUnit;
    WWW::HtmlUnit->import( %parameters );
  } else {
    if($parameters{error_filename}) {
      open $error_fh, '>>', $parameters{error_filename}
        or die "Error opening $parameters{error_filename}, $!\n";
      delete $parameters{error_filename};
    } elsif($parameters{error_fh}) {
      $error_fh = $parameters{error_fh};
      delete $parameters{error_fh};
    } elsif($parameters{errors_to_tmpfile} || ! -c '/dev/null') {
      require IO::File;
      $error_fh = IO::File->new_tmpfile;
      delete $parameters{errors_to_tmpfile};
    } else {
      open $error_fh, '>', '/dev/null'
        or die "Error opening $parameters{error_filename}, $!\n";
    }

    # So we save STDERR, then redirect it

    no warnings; # stop complaint about SAVEERR never being used again
    open SAVEERR, '>&', STDERR;
    use warnings;
    close STDERR;
    open STDERR, '>&', $error_fh;
 
    # Now Inline::Java will use our special filehandle instead of STDERR
    require WWW::HtmlUnit;
    WWW::HtmlUnit->import( %parameters );

    # Now put STDERR back!
    close STDERR;
    open STDERR, '>&', SAVEERR;
	}

}

=head1 METHODS

=head2 $agent = WWW::HtmlUnit::Sweet->new

Create a new sweet agent. Use this kinda like looking at a browser on the screen. The methods you call will be invoked (if possible) on the current browser, window, page, or focused element.

The 'new' method can also take a browser version and a starting url, like this:

  my $agent = WWW::HtmlUnit::Sweet->new(
    version => 'FIREFOX_3',
    url => 'http://google.com/'
  );

=cut

sub new {
	my $class = shift;
	my $self = { @_ };
	bless $self, $class;
	$self->{browser} = WWW::HtmlUnit->new( $self->{version} );
  $self->getPage( $self->{url} ) if $self->{url};
	return $self;
}

=head2 $agent->wait_for(sub { ... }, $timeout)

Execute the provided sub once a second until it returns true, or until the the timeout has been reached. If a timeout isn't passed, it will default to 10 seconds (which you can change by setting C<< $WWW::HtmlUnit::Sweet::default_timeout >>). This is handy for waiting for the page to finish executing some javascript, or loading.

Example:

  # Wait for an element with id 'foo' to exist
  $agent->wait_for(sub {
    $agent->getElementById('foo')
  });

=cut

our $default_timeout = 10;

sub wait_for {
  my ($agent, $subref, $timeout) = @_;
  $timeout ||= $default_timeout;
  while($timeout) {
    return if eval { $subref->() } && ! $@;
    sleep 1;
    $timeout--;
  }
  die "Timeout!\n";
}

=head2 AUTOLOAD, aka $agent->whatever(..)

This is where the sweetness starts kicking in. First it will try to call ->whatever on the browser, and if there is no method named 'whatever' there it will be called on the current window, and if there is no method named 'whatever' there it will be called on the current page in that window, and if there is no method 'whatever' there it will be called on the currently focused element.

Examples:

  # This works at the browser level
  $agent->getPage('http://google.com/');

  # Get the 'name' for the current window
  my $window_name = $agent->getName;

  # Working from the current page, get an element by ID
  my $sidebar_element = $agent->getElementById('sidebar');

  # Click on the currently focused element
  $agent->click;

This scheme works quite well because HtmlUnit itself just so happens to not overlap their method names between different classes. Lucky us!

Note: We also call ->toArray on results if needed. Probably at some point we'll get ALL array-like results from HtmlUnit to auto-execute ->toArray.

=cut

# This will make us act a bit more like Mechanize
sub AUTOLOAD {
	my $self = shift;
	our $AUTOLOAD;
	my $method = $AUTOLOAD; $method =~ s/.*:://;
	return if $method eq 'DESTROY';
	my $retval = eval {
    
    my $browser = $self->{browser};
    my $window = $browser && $browser->getCurrentWindow;
    my $page = $window && $window->getEnclosedPage;
    my $element = $page && $page->getFocusedElement;

    my $result;
		if($browser && $browser->can($method)) {
			$result = $browser->$method(@_);
		} elsif($window && $window->can($method)) {
			$result = $window->$method(@_);
		} elsif($page && $page->can($method)) {
			$result = $page->$method(@_);
		} elsif($element && $element->can($method)) {
			$result = $element->$method(@_);
		} else {
			die "Method $method not found!";
		}
    if(ref $result && $result->can('toArray')) {
      return $result->toArray;
    } else {
      return $result;
    }
	};
	if($@ && ref($@) =~ /Exception/) {
		print STDERR "HtmlUnit ERROR: " . $@->getMessage . "\n";
		die $@; # Pass it up the chain
	} elsif($@) {
		warn $@;
	}
	return $retval;
}


package WWW::HtmlUnit::com::gargoylesoftware::htmlunit::html::HtmlSelect;

# Fix the get_option to take nicer params
# TODO: document this!

sub get_option {
	my ($self, %params) = @_;
	if($params{text}) {
		return eval {$self->getOptionByText($params{text})};
	} elsif($params{value}) {
		return eval {$self->getOptionByValue($params{value})};
	}
	die "Must pass either text or value";
}

package WWW::HtmlUnit::java::lang::Object;

sub sweeten {
  return WWW::HtmlUnit::Sweet->new();
}

=head1 TODO

Add more documentation and examples and sweetness :)

=head1 SEE ALSO

L<WWW::HtmlUnit>

=head1 AUTHOR

  Brock Wilcox <awwaiid@thelackthereof.org> - http://thelackthereof.org/

=head1 COPYRIGHT

  Copyright (c) 2009-2011 Brock Wilcox <awwaiid@thelackthereof.org>. All rights
  reserved.  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut

1;

