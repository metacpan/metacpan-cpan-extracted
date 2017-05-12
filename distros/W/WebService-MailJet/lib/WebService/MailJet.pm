# ABSTRACT: WebService::MailJet
package WebService::MailJet;
use Moo;
use MIME::Base64;
with 'WebService::Client';

our $VERSION = '0.0003';

use Carp qw(croak);

has auth_key => ( is => 'ro', required => 1 );
has auth_secret => ( is => 'ro', required => 1 );

has '+base_url' => ( default => 'https://api.mailjet.com/v3/REST/' );

sub BUILD {
    my ($self) = @_;
    my $basic = MIME::Base64::encode ($self->auth_key.":".$self->auth_secret,'');
    $self->ua->default_header(Authorization => "Basic " . $basic);
}
sub send {
    my ($self,$method,$data) = @_;
    return $self->get($method,$data);
}
sub send_post {
    my ($self,$method,$data) = @_;
    return $self->post($method,$data);
}

sub send_put{
	my ($self,$method,$data) = @_;
	return $self->post($method,$data);
}

sub send_delete{
    my ($self,$method,$data) = @_;
    return $self->post($method,$data);
}

1

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MailJet - WebService::MailJet

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use WebService::Mailjet;

    my $mailjet = WebService::MailJet->new(auth_key => 'abc',auth_secret=>'xyz');

    All "GET" Methods are called on send

    my $json = $mailjet->send('apikey');

    All "post" methos are called on send_post

    my $data = ( 'name' =>'Name' , 'DateType'=> "str", 'NameSpace' : 'static' );

    my $json = $mailjet->send_post('contactmetadata' , %data);

    All "put" methos are called on send_put

    my $data = ( 'title' => 'Update title of the Newsletter' );

    my $json = $mailjet->send_put('newsletter/123' , %data);

=cut

=head1 AUTHOR

Anwesh <kanishkablack@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by AhamTech.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
