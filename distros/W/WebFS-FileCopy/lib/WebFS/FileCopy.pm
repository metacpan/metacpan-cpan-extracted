package WebFS::FileCopy;

# Copyright (C) 1998-2001 by Blair Zajac.  All rights reserved.  This
# package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

require 5.004_04;

use strict;
use Exporter;
use Carp qw(croak cluck);
use Cwd;
use URI 1.09;
use URI::file;
use LWP::Version 0.24;
use LWP::UA 1.30;
use LWP::MainLoop qw(mainloop);
use LWP::Conn::HTTP;
use LWP::Conn::FTP;
use LWP::Request;
use HTTP::Request::Common 1.16 qw(GET PUT);
use Net::FTP 2.56;
use WebFS::FileCopy::Put;

use vars qw(@EXPORT @ISA $VERSION $ua $WARN_DESTROY);

@EXPORT  = qw(&copy_url &copy_urls &delete_urls &get_urls &list_url
	      &move_url &put_urls);
@ISA     = qw(Exporter);
$VERSION = substr q$Revision: 1.04 $, 10;

# To allow debugging of object destruction, setting WARN_DESTORY to 1
# till have DESTROY methods print a message when a object is destroyed.
$WARN_DESTROY = 0;

# Unless the data_cb and done_cb elements of a LWP::Request object are
# deleted after use, the all objects using them will not DESTROY till the
# end of execution of the program.  Use this subroutine to remove these
# elements.
sub _cleanup_requests {
  foreach my $get_req (@_) {
    next unless $get_req;
    delete $get_req->{data_cb};
    delete $get_req->{done_cb};
  }
}

package WebFS::FileCopy::UA;
use base 'LWP::UA';
use LWP::MainLoop qw(mainloop);
use Carp qw(cluck);
sub _start_read_request {
  my ($self, $req) = @_;

  bless $req, 'LWP::Request' if ref($req) eq 'HTTP::Request';

  my $res;
  $req->{data_cb} = sub {
    $res = $_[1];
    $res->add_content($_[0]);
  };
  $req->{done_cb} = sub {
    $res = shift;
    $res->{done}++;
  };

  $self->spool($req);

  mainloop->one_event until $res || mainloop->empty;

  bless $res, 'WebFS::FileCopy::Response';
}

sub _start_transfer_request {
  my $self = shift;

  unless (@_ > 1) {
    cluck "WebFS::FileCopy::_start_transfer_request passed two few arguments";
    return;
  }

  # Create and submit the GET request.
  my $get_req = shift;
  my $get_res = $self->_start_read_request($get_req);

  my @put_req = @_;

  # Check the response.
  return $get_res unless $get_res->is_success;

  # This array holds the file: or ftp: objects that support print and
  # close methods on the outgoing data.  If the put fails, then hold the
  # response placed into $@.  Keep track that the responses for each PUT
  # are in the same order as the requests.
  my @put_connections = ();
  my @put_res         = ();
  my $i               = 0;
  foreach my $put_req (@put_req) {
    my $conn = WebFS::FileCopy::Put->new($put_req);
    if ($conn) {
      $put_connections[$i] = $conn;
      $put_res[$i]         = undef;
    } else {
      $put_connections[$i] = undef;
      $put_res[$i]         = $@;
    }
    ++$i;
  }

  # This subroutine writes the current get contents to the output handles.
  my $print_sub = sub {
    my $get_res = shift;
    my $buffer  = $get_res->content('');
    return unless length($buffer);
    foreach my $put_conn (@put_connections) {
      next unless $put_conn;
      $put_conn->print($buffer);
    }
  };

  my $data_cb_sub = sub {
    $get_res = $_[1];
    $get_res->add_content($_[0]);
    &$print_sub($get_res);
  };

  my $done_cb_sub = sub {
    $get_res = shift;
    $get_res->{done}++;
    &$print_sub($get_res);
    # Add the HTTP::Response for closing each put.
    my $i = -1;
    foreach my $put_conn (@put_connections) {
      ++$i;
      next unless $put_conn;
      $put_res[$i] = $put_conn->close;
    }
    $get_res->{put_requests} = \@put_res;
  };

  # Update the callbacks to handle the new data transfer.
  $get_req->{data_cb} = $data_cb_sub;
  $get_req->{done_cb} = $done_cb_sub;

  # The gets may already be completed at this point.  If this is so, then
  # send the data to the outgoing URIs and close up.
  &$done_cb_sub($get_res) if exists($get_res->{done});

  $get_res;
}

sub DESTROY {
  if ($WebFS::FileCopy::WARN_DESTROY) {
    my $self = shift;
    print STDERR "DESTROYing $self\n";
  }
}

package WebFS::FileCopy::Response;
use base 'HTTP::Response';
use LWP::MainLoop qw(mainloop);

sub _read_content {
  my $self = shift;

  my $c = $self->content('');
  return $c if length($c);

  return if $self->{done};

  # Now wait for more data.
  my $data;
  $self->request->{data_cb} = sub { $data = $_[0]; };
  mainloop->one_event until
    mainloop->empty || defined($data) || $self->{done};

  $data;
}

sub DESTROY {
  if ($WebFS::FileCopy::WARN_DESTROY) {
    my $self = shift;
    print STDERR "DESTROYing $self\n";
  }
}

package WebFS::FileCopy;

sub _init_ua {
  # Create a global UserAgent object.
  $ua = WebFS::FileCopy::UA->new;
  $ua->env_proxy;
}

# Take either a string, a URI, a HTTP::Request, a LWP::Request and make
# it into an absolute URI.  Do not touch the given URI.  If the URI is
# missing a scheme, then assume it to be file and if the file path is
# not an absolute one, then assume that the current directory contains
# the file.
sub _create_uri {
  my ($uri, $base) = @_;

  # Handle the URI differently if it is a string or an object.  If the uri
  # is an object, then check if it is a HTTP::Request or a child of that
  # class and take the URI from that object.  Now we have a URI object and
  # make sure it is canonicalized, since with a URI like http://www.a1.com
  # the path will be undefined.
  if (ref($uri)) {
    $uri = $uri->uri if $uri->isa('HTTP::Request');
    $uri = $uri->clone;
    $uri = $uri->abs($base) if defined($base) && $base;
    $uri = $uri->canonical;
  } else {
    my $temp = $uri;
    if (defined($base) and $base) {
      $uri = eval { URI->new_abs($uri, $base)->canonical; };
    } else {
      $uri = eval { URI->new($uri)->canonical; };
    }
    cluck "WebFS::FileCopy::_create_uri failed on $temp: $@" if $@;
  }
  $uri;
}

# Take a request method (POST, GET, etc) and either a string URI, a URI
# object, a HTTP::Request or subclass of HTTP::Request object such as
# LWP::Request.  Make use of _create_uri if the URI is not a HTTP::Request
# type.  If it is a HTTP::Request make a clone and work with that.
sub _create_request {
  my ($method, $uri, $base) = @_;

  if (ref($uri) and $uri->isa('HTTP::Request')) {
    # Recase the object into a LWP::Request and make sure the method
    # is the request type.
    $uri = bless $uri->clone, 'LWP::Request';
    $uri->method($method);
    return $uri;
  } else {
    return LWP::Request->new($method, _create_uri($uri, $base));
  }
}

# Take a URI and return if the URI is a directory or a file.  A directory
# always ends in /.
sub _is_directory {
  my ($uri, $base) = @_;

  $uri = _create_uri($uri, $base);

  return $uri ? ($uri->path =~ m:/$:) : undef;
}

sub get_urls {
  return () unless @_;

  my @uris = @_;

  _init_ua unless $ua;

  # Quickly spool each GET request.
  my @get_req = ();
  my @get_res = ();
  my $i = 0;
  foreach my $uri (@uris) {
    my $get_req = _create_request('GET', $uri);

    # $j is created here to be local to this loop and recorded in each
    # anonymous subroutine created below.
    my $j = $i;

    $get_res[$j] = undef;
    $get_req->{data_cb} = sub {
      $get_res[$j] = $_[1];
      $get_res[$j]->add_content($_[0]);
    };
    $get_req->{done_cb} = sub {
      $get_res[$j] = shift;
      $get_res[$j]->{done}++;
    };
    $ua->spool($get_req);
    $get_req[$j] = $get_req;
    ++$i;
  }

  # Perform one_event() until all of the done requests are handled.
  while (1) {
    my $done = 1;
    foreach my $get_res (@get_res) {
      unless (defined($get_res) and exists($get_res->{done})) {
        $done = 0;
        last;
      }
    }
    last if $done || mainloop->empty;
    mainloop->one_event;
  }

  # Allow garbage collection to happen.
  _cleanup_requests(@get_req);

  # Return the responses.
  @get_res;
}

sub put_urls {
  unless (@_ >= 2) {
    $@ = 'Too few arguments';
    cluck $@;
    return;
  }

  my $string_or_code = shift;

  # Convert string URIs to LWP::Requests.
  my @put_reqs = map { _create_request('PUT', $_) } @_;

  # This holds the responses for each PUT request.
  my @put_res = ();

  # Go through each URI and create a request for it if the URI is ok.
  my @put_req = ();
  my $leave_now = 1;
  foreach my $put_req (@put_reqs) {
    my $uri = $put_req->uri;

    # We put this in so that give_response can be used.
    $put_req->{done_cb} = sub { $_[0]; };

    # Need a valid URI.
    unless ($uri) {
      push(@put_req, 0);
      push(@put_res,
        $put_req->give_response(400, 'Missing URL in request'));
      next;
    }

    # URI cannot be a directory.
    if (_is_directory($uri)) {
      push(@put_req, 0);
      push(@put_res,
        $put_req->give_response(403, 'URL cannot be a directory'));
      next;
    }

    # URI scheme needs to be either ftp or file.
    my $scheme = $uri->scheme;
    unless ($scheme && ($scheme eq 'ftp' or $scheme eq 'file')) {
      push(@put_req, 0);
      push(@put_res,
        $put_req->give_response(400, "Invalid scheme $scheme"));
      next;
    }

    # We now have a valid request.
    push(@put_req, $put_req);
    push(@put_res, $put_req->give_response(201));
    $leave_now = 0;
  }

  # Leave now if there are no valid requests.  @put_req contains 0's for
  # each invalid URI.
  if ($leave_now) {
    # Allow garbage collection to happen.
    _cleanup_requests(@put_req);
    return @put_res;
  }

  _init_ua unless $ua;

  # For each valid PUT request, create the connection.
  my @put_connections = ();
  my $i = 0;
  foreach my $put_req (@put_req) {
    my $conn;
    if ($put_req) {
      $conn = WebFS::FileCopy::Put->new($put_req);
      # If the connection cannot be created, then get the response from $@.
      $put_res[$i] = $@ unless $conn;
    }
    push(@put_connections, $conn);
    ++$i;
  }

  # Push the data to each valid connection.  For the CODE reference,
  # call it until it returns undef or ''.
  if (ref($string_or_code) eq 'CODE') {
    my $buffer;
    while (defined($buffer = &$string_or_code) and length($buffer)) {
      foreach my $conn (@put_connections) {
        next unless $conn;
        $conn->print($buffer);
      }
    }
  } else {
    foreach my $conn (@put_connections) {
      next unless $conn;
      $conn->print($string_or_code);
    }
  }

  # Close the connection and hold onto the close status.
  $i = 0;
  foreach my $put_conn (@put_connections) {
    if ($put_conn) {
      $put_res[$i] = $put_conn->close;
    }
    ++$i;
  }

  # Allow garbage collection to happen.
  _cleanup_requests(@put_req);

  @put_res;
}

sub copy_urls {
  unless (@_ == 2 or @_ == 3) {
    $@ = 'Incorrect number of arguments';
    cluck $@;
    return;
  }

  my ($from_input, $to_input, $base) = @_;

  # Create the arrays holding the to and from locations using either the
  # array references or the single URIs.
  my @from = ref($from_input) eq 'ARRAY' ? @$from_input : ($from_input);
  my @to   = ref($to_input)   eq 'ARRAY' ? @$to_input   : ($to_input);

  # Convert string URIs to LWP::Requests.
  @from = map { _create_request('GET', $_, $base) } @from;
  @to   = map { _create_request('PUT', $_, $base) } @to;

  my $number_valid_froms = grep($_->uri, @from);
  my $number_valid_tos   = grep($_->uri, @to);

  # We ignore empty URIs, but make sure there are some URIs.
  unless ($number_valid_froms) {
    $@ = 'No non-empty GET URLs';
    return;
  }

  unless ($number_valid_tos) {
    $@ = 'No non-empty PUT URLs';
    return;
  }

  # Check that the to destination URIs are either file: or ftp:.
  foreach my $put_req (@to) {
    # Skip empty requests.
    my $uri = $put_req->uri;
    next unless $uri;
    my $scheme = $uri->scheme;
    unless ($scheme && ($scheme eq 'ftp' or $scheme eq 'file')) {
      $@ = "Can only copy to file or FTP URLs: " . $uri;
      return;
    }
  }

  # All of the from URIs must be non-directories.
  foreach my $get_req (@from) {
    my $uri = $get_req->uri;
    if ($uri and _is_directory($uri)) {
      $@ = "Cannot copy directories: " . $uri;
      return;
    }
  }

  # If any of the destination URIs is a file, then there can only be
  # one source URI.
  if ($number_valid_froms > 1) {
    foreach my $put_req (@to) {
      my $uri = $put_req->uri;
      next unless $uri;
      if (!_is_directory($uri)) {
        $@ = 'Cannot copy many files to one file';
        return;
      }
    }
  }

  _init_ua unless $ua;

  # Set up the transfer between the from and to URIs.
  my @get_res = ();
  foreach my $get_req (@from) {
    my $from_uri = $get_req->uri;

    # If the from URI is empty, then generate a missing URI response.
    unless ($from_uri) {
      $get_req->{done_cb} = sub { $_[0]; };
      push(@get_res, $get_req->give_response(400, 'Missing URL in request'));
      next;
    }

    # Do not generate the put requests if this is an empty from URI.
    my @put_req = ();

    foreach (@to) {
      my $put_req = $_->clone;
      my $to_uri  = $put_req->uri;
      # If the to URI is a directory, then copy the filename from the
      # from URI to the to URI.
      if (_is_directory($to_uri)) {
        my @from_path = split(/\//, $from_uri->path);
        $to_uri->path($to_uri->path . $from_path[$#from_path]);
        $put_req->uri($to_uri);
      }

      # Put together a put request using the output from a get request.
      push(@put_req, $put_req);
    }
    my $get_res = $ua->_start_transfer_request($get_req, @put_req);
    push(@get_res, $get_res) if $get_res;
  }

  # Loop until all of the data is transfered.
  while (1) {
    my $done = 1;
    foreach my $get_res (@get_res) {
      next unless $get_res->is_success;
      $done &&= exists($get_res->{put_requests});
    }
    last if $done || mainloop->empty;
    mainloop->one_event;
  }

  # Allow garbage collection to happen.
  _cleanup_requests(@from, @to);

  @get_res;
}

# Print a status summary using the return from copy_urls.
sub _dump {
  my $fd = (ref($_[0]) || $_[0] =~ /^\*[\w:]+\w$/) ? shift : 'STDOUT';
  foreach my $get_res (@_) {
    my $uri = $get_res->request->uri;
    print $fd "GET from $uri ";
    unless ($get_res->is_success) {
      print $fd "FAILED ", $get_res->message, "\n";
      next;
    }

    print $fd "SUCCEEDED\n";
    foreach my $c (@{$get_res->{put_requests}}) {
      $uri = $c->request->uri;
      if ($c->is_success) {
        print $fd "    to $uri succeeded\n"
      } else {
        print $fd "    to $uri failed: ", $c->message, "\n";
      }
    }
  }
}

sub copy_url {
  unless (@_ == 2 or @_ == 3) {
    $@ = 'Incorrect number of arguments';
    cluck $@;
    return;
  }

  my ($from, $to, $base) = @_;

  # Convert string URIs to URIs.
  $from = _create_request('GET', $from, $base);
  $to   = _create_request('PUT', $to,   $base);

  # Check for valid URIs.
  unless ($from->uri) {
    $@ = 'Missing GET URL';
    return;
  }

  unless ($to->uri) {
    $@ = 'Missing PUT URL';
    return;
  }

  # Run the real copy_urls and get the return value.
  my @ret = copy_urls($from, $to, $base);
  return unless @ret;

  my $get_res = shift(@ret);
  unless ($get_res->is_success) {
    $@ = 'GET ' . $get_res->request->uri . ': ' . $get_res->message;
    return 0;
  }
  my @put_res = @{$get_res->{put_requests}};

  # This should never happen.
  unless (@put_res) {
    $@ = 'Found a bug: no returned PUT requests from copy_urls';
    cluck $@;
    return;
  }

  # Check each PUT request.
  foreach my $put_res (@put_res) {
    unless ($put_res->is_success) {
      $@ = 'PUT ' . $put_res->request->uri . ': ' . $put_res->message;
      return 0;
    }
  }
  1;
}

sub delete_urls {
  my @uris = @_;

  return () unless @uris;

  _init_ua unless $ua;

  # Go through each URI, create a request, and spool it.
  my @del_req = ();
  my @del_res = ();
  my $i = 0;
  foreach my $uri (@uris) {
    my $del_req = _create_request('DELETE', $uri);

    # $j is created here to be local to this loop and recorded in each
    # anonymous subroutine created below.
    my $j = $i;

    $del_res[$j] = undef;
    $del_req->{done_cb} = sub { $del_res[$j] = shift; };
    $ua->spool($del_req);
    $del_req[$j] = $del_req;
    ++$i;
  }

  # Perform one_event until all of the done requests are handled.
  while (1) {
    my $done = 1;
    foreach my $del_res (@del_res) {
      unless (defined($del_res)) {
        $done = 0;
        last;
      }
    }
    last if $done || mainloop->empty;
    mainloop->one_event;
  }

  # Allow garbage collection to happen.
  _cleanup_requests(@del_req);

  # Return the status.
  @del_res;
}

sub move_url {
  unless (@_ == 2 or @_ == 3) {
    $@ = 'Incorrect number of arguments';
    cluck $@;
    return;
  }

  my ($from, $to, $base) = @_;

  # Convert string URIs to URIs.
  $from = _create_request('GET', $from, $base);
  $to   = _create_request('PUT', $to,   $base);

  # Copy the URI.  Make sure to pass down $@ failures from copy_url.
  if (copy_url($from, $to)) {
    my @ret = delete_urls($from);
    my $ret = $ret[0];
    if ($ret->is_success) {
      return 1;
    } else {
      $@ = $ret->message;
      return 0;
    }
  } else {
    return 0;
  }
}

sub _list_file_uri {
  my $uri = shift;

  # Check that the host is ok.
  my $host = $uri->host;
  if ($host and $host !~ /^localhost$/i) {
    $@ = 'Only file://localhost/ allowed';
    return;
  }

  # Get file path.
  my $path = $uri->file;

  # Check that the directory exists and is readable.
  unless (-e $path) {
    $@ = "File or directory `$path' does not exist";
    return;
  }
  unless (-r _) {
    $@ = "User does not have read permission for `$path'";
    return;
  }
  unless (-d _) {
    $@ = "Path `$path' is not a directory";
    return;
  }

  # List the directory.
  unless (opendir(D, $path)) {
    $@ = "Cannot read directory `$path': $!";
    return;
  }

  my @listing = sort readdir(D);

  closedir(D) or
    print STDERR "$0: error in closing directory `$path': $!\n";

  @listing;
}

sub _list_ftp_uri {
  my $uri = shift;

  my $req = _create_request('GET', $uri);
  $req->{done_cb} = sub { $_[0] };
  my $ftp = _open_ftp_connection($req);
  unless ($ftp) {
    $@ = $@->message;
    return;
  }

  # Get and fix path.
  my @path = $uri->path_segments;
  # There will always be an empty first component.
  shift(@path);
  # Remove the empty trailing components.
  pop(@path) while @path && $path[-1] eq '';

  # Change directories.
  foreach my $dir (@path) {
    unless ($ftp->cwd($dir)) {
      $@ = "Cannot chdir to `$dir'";
      return;
    }
  }

  # Now get a listing.
  my @listing = $ftp->ls;

  # Close the connection.
  $ftp->quit;

  @listing;
}

sub list_url {
  my $uri = shift;

  $uri = _create_uri($uri);
  unless ($uri) {
    $@ = "Missing URL";
    return;
  }

  my $scheme = $uri->scheme;
  unless ($scheme) {
    $@ = "Missing scheme in URL $uri";
    return;
  }

  if ($scheme eq 'file' || $scheme eq 'ftp' ) {
    my $code = "_list_${scheme}_uri";
    no strict 'refs';
    my @listing = &$code($uri);
    if (@listing) {
      return @listing;
    } else {
      return;
    }
  } else {
    $@ = "Unsupported scheme $scheme in URL $uri";
    return;
  }
}

# Open a FTP connection.  Return either a Net::FTP object or undef if
# failes.  If somethings fails, then $@ will hold a HTTP::Response
# object.
sub _open_ftp_connection {
  my $req = shift;

  my $uri = $req->uri;
  unless ($uri->scheme eq 'ftp') {
    cluck "Use a FTP URL";
    $@ = $req->give_response(400, "Use a FTP URL");
    return;
  }

  # Handle user authentication.  If the username, password and/or
  # account is not set, then Net::FTP will attempt to set these
  # properly, so there's no point in doing that here.
  my ($user, $pass) = $req->authorization_basic;
  $user  ||= $uri->user;
  $pass  ||= $uri->password;
  my $acct = $req->header('Account');

  # Open the initial connection.
  my $ftp = Net::FTP->new($uri->host);
  unless ($ftp) {
    $@ =~ s/^Net::FTP: //;
    $@ = $req->give_response(500, $@);
    return;
  }

  # Try to log in.
  unless ($ftp->login($user, $pass, $acct)) {
    # Unauthorized access.  Fake a RC_UNAUTHORIZED response.
    $@ = $req->give_response(401, $ftp->message);
    $@->header("WWW-Authenticate", qq(Basic Realm="FTP login"));
    return;
  }

  # Switch to ASCII or binary mode.
  if ($uri =~ /type=a/i) {
    $ftp->ascii;
  } else {
    $ftp->binary;
  }

  $ftp;
}

1;

__END__

=pod

=head1 NAME

WebFS::FileCopy - Get, put, move, copy, and delete files located by URIs

=head1 SYNOPSIS

 use WebFS::FileCopy;

 my @res = get_urls('ftp://www.perl.com', 'http://www.netscape.com');
 print $res[0]->content if $res[0]->is_success;

 # Get content from pages requiring basic authentication.
 my $req = LWP::Request->new('GET' => 'http://www.dummy.com/');
 $req->authorization_basic('my_username', 'my_password');
 @res = get_urls($req);

 put_urls('put this text', 'ftp://ftp/incoming/new', 'file:/tmp/NEW');
 move_url('file:/tmp/NEW', 'ftp://ftp/incoming/NEW.1');
 delete_urls('ftp://ftp/incoming/NEW.1', 'file:/tmp/NEW');

 copy_url('http://www.perl.com/index.html', 'ftp://ftp.host/outgoing/SIG');

 copy_urls(['file:/tmp/file1', 'http://www.perl.com/index.html],
           ['file:/tmp/DIR1/', 'file:/tmp/DIR2', 'ftp://ftp/incoming/']);

 my @list1 = list_url('file:/tmp');
 my @list2 = list_url('ftp://ftp/outgoing/');

=head1 DESCRIPTION

This package provides some simple routines to read, move, copy,
and delete files as references by string URLs, URI objects or URIs
embedded in HTTP::Reqeust or LWP::Request objects.  All subroutines
in this package that expect a URI will accept a string, a URI object,
or a HTTP::Reqeust or LWP::Request with an embedded URI. If passed a
HTTP::Request or LWP::Request, then the method of the object is ignored
and the proper method will be used to either GET or PUT the requested UIR.

The distinction between files and directories in a URI is tested by
looking for a trailing / in the path.  If a trailing / exists, then the
URI is considered to point to a directory, otherwise it is a file.

All of the following subroutines are exported to the users namespace
automatically.  If you do not want this, then I<require> this package
instead of I<use>ing it.

=head1 SUBROUTINES

=over 4

=item B<get_urls> I<uri> [I<uri> [I<uri> ...]]

The I<get_urls> function will fetch the documents identified by the
given URIs and returns a list of I<HTTP::Response>s.  You can test if
the GET succeeded by using the I<HTTP::Response> I<is_success> method.
If I<is_success> returns 1, then use the I<content> method to get the
contents of the GET.

Get_urls performs the GETs in parallel to speed execution and should be
faster than performing individual gets.

Example printing the success and the content from each URI:

    my @uris = ('http://perl.com/', 'file:/home/me/.sig');
    my @response = get_urls(@uris);
    foreach my $res (@response) {
      print "FOR URL ", $res->request->uri;
      if ($res->is_success) {
        print "SUCCESS.  CONTENT IS\n", $res->content, "\n";
      } else {
        print "FAILED BECAUSE ", $res->message, "\n";
      }
    }

=item B<put_urls> I<string> I<uri> [I<uri> [I<uri> ...]]

=item B<put_urls> I<coderef> I<uri> [I<uri> [I<uri> ...]]

Put the contents of I<string> or the return from &I<coderef>() into the
listed I<uri>s.  The destination I<uri>s must be either ftp: or file:
and must specify a complete file; no directories are allowed.  If the
first form is used with I<string> then the contents of I<string> will
be sent.  If the second form is used, then I<coderef> is a reference
to a subroutine or anonymous CODE and &I<coderef>() will be called
repeatedly until it returns '' or undef and all of the text it returns
will be stored in the I<uri>s.

Upon return, I<put_urls> returns an array, where each element contains
a I<HTTP::Response> object corresponding to the success or failure of
transferring the data to the i-th I<uri>.  This object can be tested for
the success or failure of the PUT by using the I<is_success> method on
the element.  If the PUT was not successful, then the I<message> method
may be used to gather an error message explaining why the PUT failed.
If there is invalid input to I<put_urls> then I<put_urls> returns an
empty list in a list context, an undefined value in a scalar context,
or nothing in a void context, and $@ contains a message containing
explaining the invalid input.

For example, the following code, prints either YES or NO and a failure
message if the put failed.

    @a = put_urls('text',
                  'http://www.perl.com/test.html',
                  'file://some.other.host/test',
                  'ftp://ftp.gps.caltech.edu/test');
    foreach $put_res (@a) {
      print $put_res->request->uri, ' ';
      if ($put_res->is_success) {
        print "YES\n";
      } else {
        print "NO ", $put_res->message, "\n";
      }
    }

=item B<copy_url> I<uri_from> I<uri_to> [I<base>]

Copy the content contained in the URI I<uri_from> to the location
specified by the URI I<uri_to>.  I<uri_from> must contain the complete
path to a file; no directories are allowed.  I<uri_to> must be a file:
or ftp: URI and may either be a directory or a file.

If supplied, I<base> may be used to convert I<uri_from> and I<uri_to>
from relative URIs to absolute URIs.

On return, I<copy_url> returns 1 on success, 0 on otherwise.  On failure
$@ contains a message explaining the failure.  See B<copy_urls> if you
want to quickly copy a single file to multiple places or copy multiple
files to one directory or both.  B<copy_urls> provides simultaneous file
transfers and will do the task much faster than calling I<copy_url> many
times over.  If invalid input is given to I<copy_url>, then it returns
an empty list in a list context, an undefined value in a scalar context,
or nothing in a void context and $@ contains a message explaining the
invalid input.

=item B<copy_urls> I<uri_file_from> I<uri_file_to> [I<base>]

=item B<copy_urls> I<uri_file_from> I<uri_dir_to> [I<base>]

Copy the content contained at the specified URIs to other locations
also specified by URIs.  The first argument to I<copy_urls> is either a
single URI or a reference to an array of URIs to copy.  All of these URIs
must contain the complete path to a file; no directories are allowed.
The second argument may be a single URI or a reference to an array
of URIS.  If any of the destination URIs are a location of a file and
not a directory, then only one URI can be passed as the first argument.
If a reference to an array of URIs is passed as the second argument,
then all URIs must point to directories, not files.  Only file: and ftp:
URIs may be used as the destination of the copy.

If supplied, I<base> may be used to convert relative URIs to absolute
URIs for all URIs supplied to I<copy_urls>.

The copy operations of the multiple URIs are done in parallel to speed
execution.

On return I<copy_urls> returns a list of the I<LWP::Response> from each
GET performed on the from URIs.  If there is invalid input to I<copy_urls>
then I<copy_urls> returns an empty list in a list context, an undefined
value in a scalar context, or nothing in a void context and contains $@
a message explaining the error.  The success or failure of each GET may
be tested by using I<is_success> method on each element of the list.
If the GET succeeded (I<is_success> returns TRUE), then hash element
I<'put_requests'> exists and is a reference to a list of I<LWP::Response>s
containing the response to the PUT.  For example, the following code
prints a message containing the results from I<copy_urls>:

    my @get_res = copy_urls(......);
    foreach my $get_res (@get_res) {
      my $uri = $get_res->request->uri;
      print "GET from $uri ";
      unless ($get_res->is_success) {
        print "FAILED\n";
        next;
      }
  
      print "SUCCEEDED\n";
      foreach my $c (@{$get_res->{put_requests}}) {
        $uri = $c->request->uri;
        if ($c->is_success) {
          print "    to $uri succeeded\n"
        } else {
          print "    to $uri failed: ", $c->message, "\n";
        }
      }
    }

=item B<delete_urls> I<uri> [I<uri> [I<uri> ...]]

Delete the files located by the I<uri>s and return a I<HTTP::Response>
for each I<uri>.  If the I<uri> was successfully deleted, then the
I<is_success> method returns 1, otherwise it returns 0 and the I<message>
method contains the reason for the failure.

=item B<move_url> I<from_uri> I<to_uri> [I<base>]

Move the contents of the I<from_uri> URI to the I<to_uri> URI.  If I<base>
is supplied, then the I<from_uri> and I<to_uri> URIs are converted
from relative URIs to absolute URIs using I<base>.  If the move was
successful, then I<move_url> returns 1, otherwise it returns 0 and $@
contains a message explaining why the move failed.  If invalid input was
given to I<move_url> then it returns an empty list in a list context,
an undefined value in a scalar context, or nothing in a void context
and $@ contains a message explaining the invalid input.

=item B<list_url> I<uri>

Return a list containing the filenames in the directory located at I<uri>.
Only file and FTP directory URIs currently work.  If for any reason the
list can not be obtained, then I<list_url> returns an empty list in a
list context, an undefined value in a scalar context, or nothing in a
void context and $@ contains a message why I<list_url> failed.

=back 4

=head1 SEE ALSO

See also the L<HTTP::Response>, L<HTTP::Request>, L<LWP::Request>,
and L<LWP::Simple>.

=head1 AUTHOR

Blair Zajac <blair@akamai.com>

=head1 COPYRIGHT

Copyright (C) 1998-2001 by Blair Zajac.  All rights reserved.  This
package is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
