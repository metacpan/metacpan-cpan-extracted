package WWW::PostalMethods;

use strict;
use warnings;

use SOAP::Lite;
use MIME::Base64;

our $VERSION = 0.01;

=head1 NAME

WWW::PostalMethods - Interface to the PostalMethods API

=head1 SYNOPSIS

my $pm = WWW::PostalMethods->new(
    username  => 'emperorzurg',
    password  => 'buzzmustdie',
    work_mode => 'Development',
);

$pm->send_letter(
    description => 'Reminder to buy beer',
    extension   => 'html',
    data        => qq|
        <h1>Hello!</h1>
        <p>This is an automated notification that you should buy beer.
    |,
);

=head1 METHODS

=head2 new

Returns a new WWW::PostalMethods object.

Takes the following required parameters:

username - Your PostalMethods.com username

password - Your PostalMethods.com password

and the following optional parameters:

work_mode - The work mode to use (Development or Production) - defaults to Development

=cut

sub new {
    my ($class, %params) = @_;

    my $self = \%params;
    bless $self, $class;

    return $self;
}

=head2 send_letter

Sends a new letter via PostalMethods.

Takes the following required parameters:

description - Describes the letter

extension - File extension

And one of the following parameters:

data - The data to be passed

base64_data - The data to be passed, base64-encoded

=cut

sub send_letter
{
    my ($self, %params) = @_;

    my $res = $self->api_call('SendLetter', {
        MyDescription  => $params{description},
        FileExtension  => $params{extension},
        FileBinaryData => $params{base64_data} || encode_base64($params{data}),
        WorkMode       => $self->{work_mode},
    });

    return $res;
}

=head2 api_call

Direct all to make a PostalPathods API call.

Takes the call and a hash reference of parameters as an API call.

The username and password will be auto-filled, the rest is up to you.

=cut

sub api_call
{
    my ($self, $call, $params) = @_;

    $params->{Username} = $self->{username};
    $params->{Password} = $self->{password};

    my @params = map { SOAP::Data->new(name => $_, value => $params->{$_})->uri('PostalMethods') }
        keys %$params;

    $self->_soap->$call(@params);
}

sub _soap
{
    my $self = shift;

    $self->{_soap} ||= SOAP::Lite
        ->uri('PostalMethods')
        ->on_action( sub { join '/', 'PostalMethods', $_[1] } )
        ->proxy('https://api.postalmethods.com/2009-02-26/PostalWS.asmx');

    return $self->{_soap};
}

=head1 TO DO

This is a very simplistic implementation. Native support of more complex queries would be neat.

More to come, patches also welcome.

=head1 DEPENDENCIES

SOAP::Lite, MIME::Base64

=head1 AUTHORS

OHPA Software (http://ohpasw.com)

=head1 COPYRIGHT & LICENSE

Copyright (C) 2013 OHPA Software.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

