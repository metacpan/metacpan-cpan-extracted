package WebService::PutIo;

our $VERSION='0.3';

use base 'Mojo::Base';

use Mojo::UserAgent;
use Mojo::JSON;
use Mojo::URL;
use WebService::PutIo::Result;
use Carp qw/croak/;

__PACKAGE__->attr([qw/api_key api_secret/]);
__PACKAGE__->attr(ua => sub { Mojo::UserAgent->new; });
__PACKAGE__->attr(json => sub { Mojo::JSON->new; });

sub request {
	my ($self,$class,$method,%params)=@_;
	croak "Must set api_key and api_secret" unless $self->api_key && $self->api_secret;
	$params ||= ();
	my $data={
		api_key    => $self->api_key,
		api_secret => $self->api_secret,
		params	   => \%params
	};
	my $url=Mojo::URL->new('http://api.put.io/')
				     ->path("/v1/$class/$method")
				     ->query(method=>$method);
	my $tx=$self->ua->post_form( $url => { request => $self->json->encode($data) } );
	if (my $res=$tx->success) {
		return WebService::PutIo::Result->new( response => $res );
	}
	else {
		my ($message,$code)=$tx->error;
		croak "Request failed($code): $message";
	}
}

1;

=head1 NAME

WebService::PutIo - WebService client for the put.io API

=head1 SYNOPSIS

    use WebService::PutIo;
	my $ua=WebService::PutIo->new(api_key=>'foo',api_secret=>'bar');
	my $res=$ua->request('files','list');
	foreach my $file (@{$res->results}) {
	   print "Got ". Data::Dumper($file);
	}

=head1 DESCRIPTION

This is a simple Web Service client for the ping.io service. See the other
sub-classes for the actual API functions you can call. 

=head1 ATTRIBUTES

=head2 api_key

=head2 api_secret

These are the authentication credentials for ping.io. Get them from your
account page.

=head2 ua

<<<<<<< HEAD
The client to use. Defaults to L<Mojo::UserAgent>->new
||||||| merged common ancestors
The client to use. Defaults to L<Mojo::Client>->new
=======
The useragent client to use. Defaults to L<Mojo::UserAgent>->new
>>>>>>> 09f641cdc79848ee9224fd2f2e60408c9d411d75

=head2 json

The JSON object to use. Defaults to L<Mojo::JSON>->new

=head1 METHODS

=head2 request <$class>, <$method>, [%params]

Send an API request. Takes a class to operate on, an API method, and
an optional hash of parameters.

=head1 SEE ALSO

L<WebService::PutIo::Files>, L<WebService::PutIo::Messages>, L<WebService::PutIo::Subscriptions>,
L<WebService::PutIo::Transfers>, L<WebService::PutIo::URLs>,L<WebService::PutIo::User>

=head1 AUTHOR

Marcus Ramberg, C<mramberg@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Marcus Ramberg.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
