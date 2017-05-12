package WWW::SFDC::Partner;
# ABSTRACT: Interface to the Salesforce.com Partner API

use 5.12.0;
use strict;
use warnings;

our $VERSION = '0.37'; # VERSION

use Data::Dumper;
use Log::Log4perl ':easy';
use Method::Signatures;
use Scalar::Util 'blessed';
use SOAP::Lite;

use Moo;
with "WWW::SFDC::Role::SessionConsumer", "WWW::SFDC::Role::CRUD";

has 'uri',
  is => 'ro',
  default => "urn:partner.soap.sforce.com";

sub _extractURL { return $_[1]->{serverUrl} }

method _prepareSObjects (@_) {
  # prepares an array of objects for an update or insert call by converting
  # it to an array of SOAP::Data

  TRACE "objects for operation", Dumper \@_;

  return map {
      my $obj = $_;
      my @type;
      if ($obj->{type}) {
        @type = SOAP::Data->name('type' => $obj->{type});
        delete $obj->{type};
      }

      SOAP::Data->name(sObjects => \SOAP::Data->value(
        @type,
        map {
          (blessed ($obj->{$_}) and blessed ($obj->{$_}) eq 'SOAP::Data')
            ? $obj->{$_}
            : SOAP::Data->name($_ => $obj->{$_})
        } keys %$obj
      ))
    } @_;
}


method setPassword (:$Id!, :$Password!){
  INFO "Setting password for user $Id";
  return $self->_call(
    'setPassword',
    SOAP::Data->name(userID => $Id),
    SOAP::Data->name(password => $Password),
   );
}

1;

__END__

=pod

=head1 NAME

WWW::SFDC::Partner - Interface to the Salesforce.com Partner API

=head1 VERSION

version 0.37

=head1 SYNOPSIS

    my $client =  WWW::SFDC->new(
        username => "foo",
        password => "bar",
        url      => "url",
    );

    my @objects = $client->Partner->query("SELECT field, ID FROM Object__c WHERE conditions");

    $client->update(
        map { $_->{field} =~ s/baz/bat/ } @objects
    );

This module consumes L<WWW::SFDC::Role::CRUD>.

=head1 METHODS

=head2 setPassword

   $client->Partner->setPassword(Id => $ID, Password => $newPassword);

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/sophos/WWW-SFDC/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::SFDC::Partner

You can also look for information at L<https://github.com/sophos/WWW-SFDC>

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
