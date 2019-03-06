package WebService::Pixela::Webhook;
use 5.010001;
use strict;
use warnings;
use Carp qw/croak/;
use JSON qw/decode_json/;

our $VERSION = "0.01";

sub new {
    my ($class,$pixela_client) = @_;
    return bless +{
        client => $pixela_client,
    }, $class;
}


sub client {
    my $self = shift;
    return $self->{client};
}

sub hash {
    my $self = shift;
    if (@_){
        $self->{hash} = shift;
        return $self;
    }
    return $self->{hash};
}

sub create {
    my ($self,%args) = @_;
    my $params = {};

    #check graphID
    $params->{graphID} = $args{graph_id} // $self->client->graph->id;
    croak 'require graph_id' unless $params->{graphID};

    #check type
    croak 'require type' unless $args{type};
    map {
            if( $args{type} =~ /^$_$/i){
                $params->{type} = lc($args{type});
            }
    } (qw/increment decrement/);
    croak 'invalid type' unless $params->{type};

    my $path = 'users/'.$self->client->username.'/webhooks';
    my $res  = $self->client->request_with_xuser_in_header('POST',$path,$params);

    my $res_json = $self->client->decode() ? $res : decode_json($res);

    if($res_json->{isSuccess}){
        $self->hash($res_json->{webhookHash});
    }

    return $res;
}

sub get {
    my $self   = shift;
    my $client = $self->client;

    my $path = 'users/'.$client->username.'/webhooks/';
    my $res = $client->request_with_xuser_in_header('GET',$path);

    return $client->decode() ? $res->{webhooks} : $res;
}

sub invoke {
    my ($self,$hash) = @_;
    my $client = $self->client;

    $hash //= $self->hash();
    croak 'require webhookHash' unless $hash;

    my $path = 'users/'.$client->username.'/webhooks/'.$hash;
    return $client->request_with_content_length_in_header('POST',$path,0);
}

sub delete {
    my ($self,$hash) = @_;
    my $client = $self->client;

    $hash //= $self->hash();
    croak 'require webhookHash' unless $hash;

    my $path = 'users/'.$client->username.'/webhooks/'.$hash;
    return $self->client->request_with_xuser_in_header('DELETE',$path);
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Pixela::Webhook - It's Pixela Webhook API client

=head1 SYNOPSIS

    use strict;
    use warnings;
    use utf8;

    use WebService::Pixela;

    # All WebService::Pixela methods use this token and user name in URI, JSON, etc.
    my $pixela = WebService::Pixela->new(token => "thisissecret", username => "testname");

    # setting graph id
    $pixela->graph->id('graph_id');

    $pixela->webhook->create(type => 'increment');

    print $pixela->webhook->hash() ."\n"; # dump webhookHash

    $pixela->webhook->invoke();

    $pixela->webhook->delete();

=head1 DESCRIPTION

WebService::Pixela::Webhook is user API client about L<Pixe.la|https://pixe.la> webservice.

=head1 INTERFACE

=head2 instance methods

This instance method require L<WebService::Pixela> instance.
So, Usually use these methods from the C<< WebService::Pixela >> instance.

=head3 C<< $pixela->webhook->create(%opts) >>

Create a new Webhook by Pixe.la
This method return webhookHash, this is automatically set instance.

I<%opts> might be:

=over

=item C<< [required] graph_id  :  Str  >>

Specify the target graph as an ID.
If the graph id is set for an instance, it will be automatically used.
(You do not need to enter it as an argument)

=item C<< [required] type : [increment|decrement] >>

Specify the behavior when this Webhook is invoked.
Only C<< increment >> or C<< decrement >> are supported.
(There is no distinction between upper case and lower case letters.)

=back

=head4 See also

L<https://docs.pixe.la/#/post-webhook>

=head3 C<< $pixela->webhook->hash($webhookhash) >>

This is webhookHash.
Used by Pixela's webhook service.

I<$webhookhash> might be:

=over

=item C<< $webhookhash :Str >>

It is a new webhookHash.
If the graph id is set for an instance, it will be automatically used create method.

=back

=head3 C<< $pixela->webhook->get() >>

Get all predefined webhooks definitions.
This method return array_ref or json value(switching decode method).

=head4 See also

L<https://docs.pixe.la/#/get-webhook>

=head3 C<< $pixela->webhook->invoke($webhookhash) >>

Invoke the webhook registered in advance.
It is used “timezone” setting as post date if Graph’s “timezone” is specified, if not specified, calculates it in “UTC”.

I<$webhookhash> might be:

=over

=item C<< $webhookhash :Str >>

If the webhookhash is using thid method , it will be automatically used.
(You do not need to enter it as an argument)

=back

=head4 See also

L<https://docs.pixe.la/#/invoke-webhook>

=head3 C<< $pixela->webhook->delete($webhookhash) >>

Delete the registered Webhook.

I<$webhookhash> might be:

=over

=item C<< $webhookhash :Str >>

If the webhookhash is using thid method , it will be automatically used.
(You do not need to enter it as an argument)

=back

=head4 See also

L<https://docs.pixe.la/#/delete-webhook>

=head1 LICENSE

Copyright (C) Takahiro SHIMIZU.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takahiro SHIMIZU E<lt>anatofuz@gmail.comE<gt>

=cut

