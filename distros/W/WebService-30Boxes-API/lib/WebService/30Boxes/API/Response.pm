package WebService::30Boxes::API::Response;

use strict;
use warnings;
use HTTP::Response;

our @ISA = qw(HTTP::Response);
our $VERSION = '1.05';

sub new {
   my ($class, $args) = @_;
   my $self = new HTTP::Response;
      $self->{'error_code'} = undef;
      $self->{'error_msg'}  = undef;
      $self->{'success'}    = undef;
      $self->{'_xml'}       = undef;
   bless $self, $class;
   return $self;
}

sub set_error {
   my ($self, $code, $msg) = @_;
   $self->{'success'}  = 0;
   $self->{'error_code'} = $code;
   $self->{'error_msg'}  = $msg;
}

sub set_success {
   my ($self) = @_;
   $self->{'success'}    = 1;
   $self->{'error_code'} = undef;
   $self->{'error_msg'}  = undef;
}

sub reply {
   my ($self, $xml) = @_;
   $self->{'_xml'} = $xml if($xml);
   return $self->{'_xml'};
}

1;
#################### main pod documentation begin ###################

=head1 NAME

WebService::30Boxes::API::Response - Response from 30Boxes REST API

=head1 SYNOPSIS

  use WebService::30Boxes::API;

  # You always have to provide your api_key
  my $boxes  = WebService::30Boxes::API->(api_key => 'your_api_key');

  # Then you might want to lookup a user and print some info
  my $result = $boxes->call('user.FindById', { id => 47 });
  if($result->{'success'}) {
     my $user   = $result->reply->{'user'};
  
     print $user->{'firstName'}, " ",
           $user->{'lastName'}, " joined 30Boxes at ",
           $user->{'createDate'},"\n";
  } else {
     print "An error occured ($result->{'error_code'}: ".
           "$result->{'error_msg'})";
  }

=head1 DESCRIPTION

C<WebService::30Boxes::API::Response>- Response from 30Boxes API

The response object is basically a L<HTTP::Request> class, with a few
things added. These keys can be queried:

=over 5

=item success

Was the call succesful?

=item error_code

If not succesful, what error code did we get?

=item error_msg

And the error message

=back

=head2 METHODS

=head3 reply

C<reply> returns the result of L<XML::Simple>'s parsing of the 30Boxes
reply. See the example above.

=head1 SEE ALSO 

L<WebService::30Boxes::API>, L<HTTP::Request>, L<XML::Simple>

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=WebService::30Boxes::API>

=head1 AUTHOR

M. Blom, 
E<lt>blom@cpan.orgE<gt>,
L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by M. Blom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

