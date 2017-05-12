package WebService::PutIo::Result;	

use base qw/Mojo::Base/;

use Mojo::JSON;
use Carp qw/croak/;

__PACKAGE__->attr(qw/response/);
__PACKAGE__->attr('json' => sub { Mojo::JSON->new });
__PACKAGE__->attr( data => sub { my $self=shift;$self->json->decode($self->response->body) });

sub count {
	return shift->data->{response}->{total};
}

sub results {
	my $self=shift;
	if($self->data->{error}) {
		croak('API Request failed: '. $self->data->{error_message});
	}
	return $self->data->{response}->{results};
}


=head1 NAME

WebService::PutIo - WebService client for the put.io API

=head1 SYNOPSIS

    use WebService::PutIo::Result;
	my $res=WebService::PutIo::Result->new(response=>$res);
	foreach my $file (@{$res->results}) {
	   print "Got ". Data::Dumper($file);
	}

=head1 DESCRIPTION

Result object for the put.io Web Service API.

=head1 ATTRIBUTES

=head2 response

A L<Mojo::Message::Response> object representing the response from put.io

=head2 json 

JSON object for deserializing. Defaults to a plain L<Mojo::JSON>.


=head2 data

The deserialized JSON body.

=head1 METHODS

=head2 count

Number of elements returned by the web service call.

=head2 results

Returns an arrayref of results as perl structures. 

=head1 AUTHOR

Marcus Ramberg, C<mramberg@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Marcus Ramberg.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

1;