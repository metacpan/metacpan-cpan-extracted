package WebService::Postcodeanywhere::BACS::REST;
use strict;
our $VERSION = '0.01';

=head1 NAME

WebService::Postcodeanywhere::BACS::REST - Perl API for postcodeanywhere BACS Information webservice

=head1 SYNOPSIS

  use WebService::Postcodeanywhere::BACS::REST;

  WebService::Postcodeanywhere::BACS::REST->license_code($license);
  WebService::Postcodeanywhere::BACS::REST->account_code($account);

  my $details = WebService::Postcodeanywhere::BACS::REST->getBACSFromSortCode($sortcode);

=head1 DESCRIPTION

This module provides a simple API to the postcodeanywhere
bank information checking webservice through it's REST API.

You will need to register and set up your account with postcodeanywhere,
a free demo is available see www.postcodeanywhere.net for details

=cut

use base qw(Class::Data::Inheritable);
use LWP::Simple qw(get);
use XML::Simple;

# Set up DataFile as inheritable class data.
__PACKAGE__->mk_classdata('webservice_url');
__PACKAGE__->mk_classdata('account_code');
__PACKAGE__->mk_classdata('license_code');

my $default_url = 'http://services.postcodeanywhere.co.uk/xml.aspx';
__PACKAGE__->webservice_url($default_url);

=head1 CLASS METHODS

=head2 account_code

  Gets/Sets the account code to be used for the webservice, this is required.

  You will need to register and set up your account with postcodeanywhere

=head2 license_code

  Gets/Sets the license code to be used for the webservice, this is required.

  You will need to register and set up your account with postcodeanywhere

=head2 webservice_url

  Gets/Sets the webservice url to be used for requests, this is optional as the default should JustWork(TM)

=head2 getBACSFromSortCode

  Takes a single argument of the sortcode in dd-dd-dd format.
  Returns a hashref of the keys/values returned by the webservice.

  my $sortcode = '00-00-00';
  my $details = WebService::Postcodeanywhere::BACS::REST->getBACSFromSortCode($sortcode);

=cut

sub getBACSFromSortCode {
  my ($class,$sortcode) = @_;
  unless ($class->account_code && $class->license_code) { die "[FATAL ERROR] getBACSFromSortCode requires license_code and account_code to be set\n"; }
  my $argument_string = "action=bacs_fetch&account_code=${\__PACKAGE__->account_code}&license_code=${\__PACKAGE__->license_code}&sortcode=$sortcode";
  my $response =  XMLin(get(__PACKAGE__->webservice_url."?$argument_string"));
  my $result = $response->{Data}{Item};
  return $result;
}

1;

__END__

=head2 EXPORT

None by default.

=head1 SEE ALSO

www.postcodeanywhere.net

www.fsite.com

=head1 AUTHOR

Aaron Trevena, E<lt>aaron@fsite.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Foresite Business Solutions, Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
