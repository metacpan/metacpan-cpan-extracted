package WWW::JSONAPI;

use 5.006;
use strict;
use warnings FATAL => 'all';
use LWP;
use HTTP::Request;
use JSON;
use Carp;

=head1 NAME

WWW::JSONAPI - Very thin and inadequate wrapper for JSON APIs

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module contains utterly minimal functionality for interacting with JSON-based REST services with or without SSL.
It resulted from my development of L<WWW::KeePassRest>, and has the purpose of providing a very thin but convenient
abstraction layer on top of LWP and JSON for that API. Other than those, it has no dependencies.
Version 0.01 contains only those methods needed by WWW::KeePassRest, so really it shouldn't even be considered
Version 0.01, but rather 0.00001 or so.

For a more feature-rich JSON module, you'll probably want L<WWW::JSON>. Seriously. Anything but this one.

   use WWW::JSONAPI;
   
   my $json = WWW::JSONAPI->new(cert_file => 'cert/wwwkprcert.pem',
                                key_file  => 'cert/wwwkprkey.pem',
                                base_url  => 'https://localhost:12984/keepass/');
   
   my $hashref = $json->GET_json ("entry/$uuid");
   
The last request and response are always available if you have something else you want to do with them.

If the server responds with anything but a 200, the module croaks with the status line of the response.
Note that this also applies to 301/302 forwards and the like. Failure to connect is flagged with a C<500 Can't connect ___>
error; this comes from LWP and is still grounds for croaking.

=head1 SUBROUTINES/METHODS

Aside from C<new> and C<ua>, the module only includes the
calls needed to support WWW::KeePassRest, with no attempt at completeness.

The form of each method is [input]_[method]_[output], where [input] is either "json" or omitted, [method] is GET, POST,
PUT, or DELETE, and [output] is either "json" for output that should be JSON-decoded or "string" for output that should
be returned with no decoding.

=head2 new

Sets up the LWP user agent, including SSL parameters. The following options can be provided:

=over

=item C<base_url>: the base URL for the API; this will be prepended to every request URL.

=item C<cert_file>: the relative or absolute path to a certificate file for SSL

=item C<key_file>: the corresponding key file

=back

If the base_url option is omitted, you will have to specify the full URL for every request.
This would be weird, but who am I to say it's not a perfectly valid way of doing things?

=cut

sub new {
   my $self = bless {}, shift;
   my %opts = @_;
   
   $self->{ua} = LWP::UserAgent->new();
   $self->{q}  = undef;  # Last query.
   $self->{r}  = undef;  # Last response.
   
   if (defined $opts{cert_file} || defined $opts{key_file}) {
      my $cert_file = $opts{cert_file} || croak ('Need both cert and key files for WWW::JSONAPI, or neither');
      my $key_file  = $opts{key_file}  || croak ('Need both cert and key files for WWW::JSONAPI, or neither');
      $self->{ua}->ssl_opts (
         SSL_version         => 'SSLv3',
         verify_hostname => 0,
         SSL_cert_file       => $cert_file,
         SSL_key_file        => $key_file,
      );
   }
   
   $self->{base_url} = $opts{base_url} || '';
   $self->{j} = JSON->new->utf8;
   
   return $self;
}

=head2 ua, req, res

=over

=item C<ua>: returns the LWP user agent for direct access

=item C<req>: returns the last request object

=item C<res>: returns the last response object

=back

=cut

sub ua { $_[0]->{ua} }



# ------------------------------------
# Error handling
# ------------------------------------

sub _bad_retcode {
   my $self = shift;
   croak $self->{r}->status_line;
}

=head2 json_POST_json

Does a POST request, taking a hashref of parameters to the POST and expecting JSON back, which it converts to
a hashref for return to the caller.

=cut

sub json_POST_json {
   my ($self, $url, $out) = @_;
   $self->{q} = HTTP::Request->new (POST => $self->{base_url} . $url, ['Content-Type' => 'application/json'], $self->{j}->encode($out));
   $self->{r} = $self->{ua}->request($self->{q});
   return $self->_bad_retcode unless $self->{r}->is_success;
   return $self->{j}->decode($self->{r}->content);
}

=head2 json_POST_string

Same as json_POST_json, but simply returns the literal return value without attempting to decode it.

=cut

sub json_POST_string {
   my ($self, $url, $out) = @_;
   $self->{q} = HTTP::Request->new (POST => $self->{base_url} . $url, ['Content-Type' => 'application/json'], $self->{j}->encode($out));
   $self->{r} = $self->{ua}->request($self->{q});
   return $self->_bad_retcode unless $self->{r}->is_success;
   return $self->{r}->content;
}

=head2 json_PUT_string

Does a PUT request, taking a hashref of parameters to the PUT and expecting a string back that will not be JSON-decoded.

=cut

sub json_PUT_string {
   my ($self, $url, $out) = @_;
   $self->{q} = HTTP::Request->new (PUT => $self->{base_url} . $url, ['Content-Type' => 'application/json'], $self->{j}->encode($out));
   $self->{r} = $self->{ua}->request($self->{q});
   return $self->_bad_retcode unless $self->{r}->is_success;
   return $self->{r}->content;
}

=head2 GET_json

Performs a GET request on the URL provided, interpreting the return as JSON and returning a hashref.

=cut

sub GET_json {
   my ($self, $url) = @_;
   $self->{q} = HTTP::Request->new (GET => $self->{base_url} . $url);
   $self->{r} = $self->{ua}->request($self->{q});
   return $self->_bad_retcode unless $self->{r}->is_success;
   return $self->{j}->decode($self->{r}->content);
}

=head2 DELETE_string

Performs a DELETE request on the URL provided, interpreting the return as a string that will not be JSON-decoded.

=cut

sub DELETE_string {
   my ($self, $url) = @_;
   $self->{q} = HTTP::Request->new (DELETE => $self->{base_url} . $url);
   $self->{r} = $self->{ua}->request($self->{q});
   return $self->_bad_retcode unless $self->{r}->is_success;
   return $self->{r}->content;
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-jsonapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-JSONAPI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::JSONAPI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-JSONAPI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-JSONAPI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-JSONAPI>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-JSONAPI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of WWW::JSONAPI
