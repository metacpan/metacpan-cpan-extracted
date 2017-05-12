# This code is a part of tux_perl, and is released under the GPL.
# Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
# See README and COPYING for more information, or see
#   http://tux-perl.sourceforge.net/.
#
# $Id: Tux.pm,v 1.6 2002/11/11 17:50:00 yaleh Exp $

package Tux;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Tux ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Tux::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Tux', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

use Tux::Constants qw/:all/;

use constant CRLF => "\r\n";
use constant HTTP_CHUNK_EOF => "0\r\n\r\n";
use constant HTTP_CHUNK_EOF_LEN => 5;

sub http_header{
  my($self)=shift;
  my $headers={@_};
  $headers->{'Transfer-Encoding'}='chunked';
  my $result='HTTP/1.'.$self->http_version.' '.$self->http_status.CRLF;
  for (keys %{$headers}){
    $result .= $_.': '.$headers->{$_}.CRLF;
  }
  return ($result .= CRLF);
}

sub http_chunk{
  my($self,$data)=@_;
  return 1 unless defined($data);
  my $len=length($data);
  return 1 unless $len;
  return sprintf("%x%s%s%s",$len,CRLF,$data,CRLF);
}

sub http_chunk_eof{
  my($self)=@_;
  return HTTP_CHUNK_EOF;
}

sub tux_print{
  my $self=shift;

  my $count=scalar @_;
  return undef if($count<0);

  # join and chunk
  my $temp=join('',@_);

  $temp=$self->http_chunk($temp);
  $self->object_addr($temp);

  return $self->tux(TUX_ACTION_SEND_BUFFER);
}

sub tux_print_header{
  my($self)=shift;
  my $temp=$self->http_header(@_);
  $self->object_addr($temp);
  return $self->tux(TUX_ACTION_SEND_BUFFER);
}

sub tux_print_http_chunk_eof{
  my($self)=@_;
  $self->object_addr(HTTP_CHUNK_EOF,HTTP_CHUNK_EOF_LEN);
  return $self->tux(TUX_ACTION_SEND_BUFFER);
}

1;
__END__

=head1 NAME

Tux - Perl extension for Tux webserver

=head1 SYNOPSIS

  package Tux::Sample::Template;

  use strict;

  use Tux;
  use Tux::Constants qw/:event/;

  my $html_content;

  BEGIN{
    $html_content = << 'EOT';
  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
  <html>
  <head>
    <title>tux_perl Template</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
    <meta name="GENERATOR" content="Quanta Plus">
  </head>
  <body>
  <h1>tux_perl Template</h1>
  <hr>
  Congratulation! Your tux_perl is working now!
  </body>
  </html>
  EOT
  }

  sub handler{
    my($r)=@_;

   SWITCH:
    {
      ($r->event==0) && do{
        $r->event(1);
        $r->http_status(200);
        return $r->tux_print_header('Content-Type' => 'text/html');
      };

      ($r->event==1) && do{
        $r->event(2);
        return $r->tux_print($html_content);
      };

      ($r->event==2) && do{
        $r->event(TUX_EVENT_FINISH_REQ);
        return $r->tux_print_http_chunk_eof;
      };

    }
    return 0;
  }

  1;

=head1 ABSTRACT

Tux is a VERY FAST http server embedded in Linux kernel. tux_perl
is an user space Perl interpreter for Tux. tux_perl is event driven.
It can generate dynamic web content quite fast.

=head1 DESCRIPTION

tux_perl run in user space as a module of Tux. It inherits the
event driven structure of normal Tux module. Minimizing the
overhead of process scheduling, it's speed is quite fast.

Because of th event driven structure, there are some differences
between developing tux_perl driven modules and traditional CGIs
or web scripts.

=head2 CONFIG FILE

tux_perl reads the config file for the options and handlers.
Usually the config file will be B<PREFIX/etc/tux_perl.conf>.

  imp_lib /usr/lib/perl5/site_perl/5.8.0/i386-linux-thread-multi/auto/Tux/tux_perl_imp.so
  init_log_file /var/log/tux_perl_init.log
  runtime_log_file /var/log/tux_perl_runtime.log
  perl_lib_path /usr/lib/perl5/site_perl/5.8.0/i386-linux-thread-multi
  <perl_module>
          name Static
          lib Tux::Sample::Static
          handler Tux::Sample::Static::handler
  </perl_module>
  <perl_module>
          name Template
          lib Tux::Sample::Template
          handler Tux::Sample::Template::handler
  </perl_module>

=over 4

=item imp_lib

=over 4

There are tow dynamic libraries for tux_perl. B<tux_perl.so> is loaded
bu Tux directly, B<tux_perl_imp.so> is loaded by tux_perl.so. The
config file of Tux should be set to load tux_perl.so, and the
location of tux_perl_imp.so should be specified in tux_perl.conf
with B<imp_lib> option.

Usually this option is already set by B<Makefile>.

=back

=item init_log_file

=over 4

Because Tux module run in different privileges during the initial
time and runtime, two log files are supported. B<init_log_file> will
log the information during initial time. Comment out this options
with '#' will disable initial time log. This log will be written
with B<root> privileges.

=back

=item runtime_log_file

=over 4

B<runtime_log_file> will log the information during runtime. Comment
out this options with '#' will disable runtime log. This log will
be written with privileges specified in the config file of Tux.

Notice, because Tux chroot to the B<DOCROOT> before enter user space
module. This path is related to the DOCROOT.

=back

=item perl_lib_path

=over 4

Append new Perl library path. B<Multi> paths can be specified with
one B<perl_lib_path> option for every path.

=back

=item perl_module

=over 4

The handlers are specified in the E<lt>perl_module<gt> sections, one
section per handler.

=item name

=over 4

The name of the handler, which is used in the URL. The URL reads

  http://host/path/tux_perl.tux?name

=back

=item lib

=over 4

The package name of the handler module. tux_perl will look in the
Perl lib path for the module. Please append the path with perl_lib_path
if it's not included by default.

=back

=item handler

=over 4

The method name of the handler.

=back

=back

=back

=head2 EVENT DRIVEN AND REQUEST SCHEDULING

To avoid the overhead of process scheduling, non-blocking event
driven structure is deployed in Tux. The request are processed
when it's READY, and B<rescheduled> when it returned from the handle
or called the B<tux() system call> to send result or read other
resources.

The code of tux_perl driven module has to be split into several
pieces by the tux() system call, because when the tux() system
call returned, the original request may be rescheduled and B<another>
one may be returned. The module should not continue operating on this
request, but exit and kernel will schedule the requests correctly.

All the methods of Tux perl lib which uses tux() system call are
prefixed by tux_. Modules should exit after calling these methods:

  return $r->tux_print($html_content);

=head2 TUX OBJECT

The tux() system call and the parameter B<user_req_t> are wrapped as
a Tux object of Perl. A parameter of class Tux is passed to the
handler when it is called.

=over 4

=item $r->tux($action)

=over 4

The tux method call the tux() system call. The request will be passed
as the second argument. Refer to the tux(2) man page and Tux::Constants
for the description of $action. Be sure to use B<Tux::Constants> package
when calling this method.

  use Tux::Constants qw/:action/;

=back

=item $r->version_major

=over 4

Get the major version of Tux.

=back

=item $r->version_minor

=over 4

Get the minor version of Tux.

=back

=item $r->version_patch

=over 4

Get the patch version of Tux.

=back

=item $r->http_version

=over 4

Get the http version of the request, 0 for HTTP/1.0, 1 for HTTP/1.1 .

=back

=item $r->http_method

=over 4

Get the method of the request, one of B<METHOD_NONE>, B<METHOD_GET>,
B<METHOD_HEAD>, B<METHOD_POST>, or B<METHOD_PUT>.

=back

=item $r->sock

=over

Socket file descriptor; writing to this will send  data  to  the
connected client associated with this request.  Do not read from
this socket file descriptor; you could potentially  confuse  the
HTTP engine.

=back

=item $r->event([$event])

=over 4

Private, per-request state for use in tux modules. The system
will preserve this value as long as a request is active. Passing
an argument will set the event.

=back

=item $r->thread_nr

=over 4

Thread index; see discussion of TUX_ACTION_STARTTHREAD in tux(2).

=back

=item $r->http_status([$status])

=over 4

Set the error status as an integer for error reporting. Must be
set before B<tux_print_header()> or B<http_header()>.

=back

=item $r->module_index

=over 4

Used by the tux daemon to determine which loadable module to
associate with a req.

=back

=item $r->client_host

=over 4

The IP address of the host to which sock is connected.

=back

=item $r->object_addr([$addr],[$length])

=over 4

Set to an address for a buffer of at least $r->objectlen size
into which to read an object from the URL cache with the
B<TUX_ACTION_READ_OBJECT> action. TUX_ACTION_READ_OBJECT must not
be called unless $r->objectlen >= 0, and TUX implicitly  relies
on $r->object_addr being at least $r->objectlen in size.

Without argument, object_addr returns the object as a string.
If only parameter $addr is set, the object_addr will be set to
$addr and objectlen will be set to length of $addr. If parameter
$length is also set, objectlen will be set to $length.

=back

=item $r->objectlen([$length])

=over 4

The  size of a file that satisfies the current request and which
is currently living in the URL cache. This is set if a request
returns after B<TUX_ACTION_GET_OBJECT>. A module should make sure
that the buffer at $r->object_addr is at least $r->objectlen
in size before calling TUX_ACTION_READ_OBJECT.

Passing an argument will set the objectlen.

=back

=item $r->objectname([$name])

=over 4

Specifies the name of a URL to get with the B<TUX_ACTION_GET_OBJECT>
action. If the URL is not immediately available (that is, is not
in the URL cache), the request is queued and the tux subsystem may
go on to other  ready  requests while waiting.

Passing an argument will set the objectname.

=back

=item $r->query([$query])

=over 4

The full query string sent from the client. Passing an argument will
set the query.

=back

=item $r->cookies([$cookies])

=over 4

If cookies are in the request header, cookies is the string in which
the cookies are passed to the module. Passing an argument will set the
cookies.

=back

=item $r->content_type([$content_type])

=over 4

The Content-Type header value for the request. Passing an argument will
set the content-type.

=back

=item $r->user_agent([$user_agent])

=over 4

The User-Agent header value for the request. Passing an argument will
set the User-Agent.

=back

=item $r->accept([$accept])

=over 4

The Accept header value for the request. Passing an argument will set
the Accept.

=back

=item $r->accept_charset([$charset])

=over 4

The Accept-Charset header value for the request. Passing an argument
will set the Accept-Charset.

=back

=item $r->accept_encoding([$encoding])

=over 4

The Accept-Encoding header value for the request. Passing an argument
will set the Accept-Encoding.

=back

=item $r->accept_language([$language])

=over 4

The Accept-Language header value for the request. Passing an argument
will set the Accept-Language.

=back

=item $r->cache_control([$cache_control])

=over 4

The Cache-Control header value for the request. Passing an argument
will set the Cache-Control.

=back

=item $r->if_modified_since([$if_modified_since])

=over 4

The If-Modified-Since header value for the request. Passing an argument
will set the If-Modified-Since.

=back

=item $r->negotiate([$negotiate])

=over 4

The Negotiate header value for the request. Passing an argument will
set the Negotiate.

=back

=item $r->pragma([$pragma])

=over 4

The Pragma header value for the request. Passing an argument will
set the Pragma.

=back

=item $r->referer([$referer])

=over 4

The Referer header value for the request. Passing an argument will
set the Referer.

=back

=item $r->post_data

=over 4

For POST requests, the incoming data is placed in post_data.

=back

=item $r->new_date

=over 4

Returns the current date/time.

=back

=item $r->keep_alive([$keep_alive])

=over 4

The KeepAlive header value for the request. Passing an argument will
set the KeepAlive.

=back

=item $r->http_header([$header_name => $value, ...])

=over 4

Generate HTTP response header with inputed header names and values.
Transfer-Encoding header will be set to C<chunked> by default. HTTP
version will be detected automatic.

=back

=item $r->http_chunk($string1, $string2, ...)

=over 4

Generate a chunk of content. tux_perl support HTTP/1.1 keep alive
function with Transfer-Encoding of C<chunked>.

=back

=item $r->http_chunk_eof

=over 4

Generate an EOF symbol for chunk. It's necessary at the end of a HTTP/1.1
response.

=back

=item $r->tux_print($string1, $string2, ...)

=over 4

Print the strings as the body of HTTP response. Strings will be wrapped
into a chunk first. Don't send HTTP header with it.

=back

=item $r->tux_print_header([$header_name => $value, ...])

=over 4

Generate the HTTP response header and print it. Refer to the http_header
function.

=back

=item $r->tux_print_http_chunk_eof

=over

Print the EOF symbol for chunk.

=back

=back

=head2 DOCROOT

Tux B<chroot> to the DOCROOT specified at it's config file before calling
the user space module. So, the environments of initial time and run time
will be different. To resolve the problem, folders can be C<link> to the
DOCROOT folder with mount --bind.

  mount --bind /usr /var/www/html/usr

If your module loaded other perl libraries dynamically, /usr/lib is
required to C<link>.

=head2 EXPORT

None by default.



=head1 SEE ALSO

tux(2),
Tux::Constants(3)

More information about tux_perl can be found at

  http://tux-perl.sourceforge.net
  http://sourceforge.net/projects/tux-perl

=head1 AUTHOR

Yale Huang, E<lt>yale@sdf-eu.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Yale Huang

This library is released under the GPL; you can redistribute it and/or modify
it under the term of GPL.

=cut
