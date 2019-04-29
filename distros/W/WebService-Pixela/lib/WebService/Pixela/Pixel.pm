package WebService::Pixela::Pixel;
use 5.010001;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = "0.021";

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

sub post {
    my ($self,%args) = @_;
    my $params = {};

    #check graphID
    my $id = $self->_check_id($args{id});

    #check date
    $params->{date}     = $args{date}     // croak 'require date';
    $params->{date} .= '';

    #check quantity
    $params->{quantity} = $args{quantity} // croak 'require quantity';
    $params->{quantity}.= '';

    #check optionalData
    $params->{optionalData} = $args{optional_data} if $args{optional_data};

    my $path = $self->_create_path($id);
    return $self->client->request_with_xuser_in_header('POST',$path,$params);
}

sub get {
    my ($self, %args) = @_;

    my $id = $self->_check_id($args{id});

    my $date = $args{date} // croak 'require date';

    my $path = $self->_create_path($id,$date);
    return $self->client->request_with_xuser_in_header('GET',$path);
}

sub update {
    my ($self,%args) = @_;

    my $id = $self->_check_id($args{id});

    #check date
    my $date = $args{date} // croak 'require date';

    my $params = {};

    #check quantity
    $params->{quantity}     = $args{quantity} . ''      if $args{quantity};

    #check optionalData
    $params->{optionalData} = $args{optional_data} if $args{optional_data};

    my $path = $self->_create_path($id,$date);
    return $self->client->request_with_xuser_in_header('PUT',$path,$params);
}

sub increment {
    my ($self,%args) = @_;
    my $client = $self->client;

    my $id = $self->_check_id($args{id});

    my $path = $self->_create_path($id);
    $path = $path . '/increment';

    my $length = $args{length} // 0;

    return $client->request_with_dual_in_header('PUT',$path,$length);
}

sub decrement {
    my ($self,%args) = @_;
    my $client = $self->client;

    my $id = $self->_check_id($args{id});

    my $path = $self->_create_path($id);
    $path = $path . '/decrement';

    my $length = $args{length} // 0;

    return $client->request_with_dual_in_header('PUT',$path,$length);
}

sub delete {
    my ($self,%args) = @_;
    my $client = $self->client;

    my $id = $self->_check_id($args{id});
    my $date = $args{date} // croak 'require date';

    my $path = $self->_create_path($id,$date);

    return $self->client->request_with_xuser_in_header('DELETE',$path);
}

sub _check_id {
    my ($self,$arg_id) = @_;

    my $id = $arg_id ? $arg_id : $self->client->graph->id();
    croak 'require graph_id' unless $id;
    return $id;
}

sub _create_path {
    my ($self,$id,$date) = @_;
    my $path = 'users/'.$self->client->username.'/graphs/'.$id;
    return defined $date ? $path . '/' . $date : $path;
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Pixela::Pixel - It's Pixela Webhook API client

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WebService::Pixela;

    my $pixela = WebService::Pixela->new(token => $ENV{TOKEN}, username => $ENV{USERNAME});

    # set graph id
    $pixela->graph->id('anatofuz-test');

    $pixela->pixel->get(date => '20180915');
    $pixela->pixel->update(date => '20180915', quantity => 50);

    $pixela->pixel->increment(date => '20180915');
    $pixela->pixel->decrement(date => '20180915');

    $pixela->pixel->get(date => '20180915');
    $pixela->pixel->delete(date => '20180915');


=head1 DESCRIPTION

WebService::Pixela::Pixel is user API client about L<Pixe.la|https://pixe.la> webservice.

=head1 INTERFACE

=head2 instance methods

This instance method require L<WebService::Pixela> instance.
So, Usually use these methods from the C<< WebService::Pixela >> instance.

=head3 C<< $pixela->pixel->post(%opts) >>

It records the quantity of the specified date as a "Pixel".

I<%opts> might be:

=over

=item C<< ([required]) id  :  Str  >>

Specify the target graph as an ID.
If the graph id is set for an instance, it will be automatically used.
(You do not need to enter it as an argument)

=item C<< [required] date : [yyyyMMdd] >>

The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

=item C<< [required] quantity : String >>

Specify the quantity to be registered on the specified date.
Validation rule: int^-?[0-9]+ float^-?[0-9]+.[0-9]+

=item C<< optional_data : json_string >>

Additional information other than quantity. It is specified as JSON string.
The amount of this data must be less than 10 KB.

=back

=head4 See also

L<https://docs.pixe.la/#/post-pixel>


=head3 C<< $pixela->pixel->get(%opts) >>

Get registered quantity as "Pixel".

I<%opts> might be:

=over

=item C<< ([required]) id  :  Str  >>

Specify the target graph as an ID.
If the graph id is set for an instance, it will be automatically used.
(You do not need to enter it as an argument)

=item C<< [required] date : [yyyyMMdd] >>

The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

=back

=head4 See also

L<https://docs.pixe.la/#/get-pixel>

=head3 C<< $pixela->pixel->update(%opts) >>

Update the quantity already registered as a "Pixel".
If target "Pixel" not exist, create a new "Pixel" and set quantity.

I<%opts> might be:

=over

=item C<< ([required]) id  :  Str  >>

Specify the target graph as an ID.
If the graph id is set for an instance, it will be automatically used.
(You do not need to enter it as an argument)

=item C<< [required] date : [yyyyMMdd] >>

The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

=item C<<  quantity : String >>

Specify the quantity to be registered on the specified date.
Validation rule: int^-?[0-9]+ float^-?[0-9]+.[0-9]+

=item C<< optional_data : json_string >>

Additional information other than quantity. It is specified as JSON string.
The amount of this data must be less than 10 KB.

=back

=head4 See also

L<https://docs.pixe.la/#/put-pixel>

=head3 C<< $pixela->pixel->increment(%opts) >>

Increment quantity "Pixel" of the day (it is used "timezone" setting if Graph's "timezone" is specified, if not specified, calculates it in "UTC").
If the graph type is int then 1 added, and for float then 0.01 added.

I<%opts> might be:

=over

=item C<< ([required]) id  :  Str  >>

Specify the target graph as an ID.
If the graph id is set for an instance, it will be automatically used.
(You do not need to enter it as an argument)

=item C<< [required] date : [yyyyMMdd] >>

The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

=item C<<  length : Int (default 0) >>

Since the request body is not specifield, specify the I<Content-Length> header.
(Default 0)

=back

=head4 See also

L<https://docs.pixe.la/#/increment-pixel>

=head3 C<< $pixela->pixel->decrement(%opts) >>


Decrement quantity "Pixel" of the day (it is used "timezone" setting if Graph's "timezone" is specified, if not specified, calculates it in "UTC").
If the graph type is int then -1 added, and for float then -0.01 added.

I<%opts> might be:

=over

=item C<< ([required]) id  :  Str  >>

Specify the target graph as an ID.
If the graph id is set for an instance, it will be automatically used.
(You do not need to enter it as an argument)

=item C<< [required] date : [yyyyMMdd] >>

The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

=item C<<  length : Int (default 0) >>

Since the request body is not specifield, specify the I<Content-Length> header.
(Default 0)

=back

=head4 See also

L<https://docs.pixe.la/#/decrement-pixel>

=head3 C<< $pixela->pixel->delete(%opts) >>

Delete the registered "Pixel".

I<%opts> might be:

=over

=item C<< ([required]) id  :  Str  >>

Specify the target graph as an ID.
If the graph id is set for an instance, it will be automatically used.
(You do not need to enter it as an argument)

=item C<< [required] date : [yyyyMMdd] >>

The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

=back

=head4 See also

L<https://docs.pixe.la/#/delete-pixel>

=head1 LICENSE

Copyright (C) Takahiro SHIMIZU.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takahiro SHIMIZU E<lt>anatofuz@gmail.comE<gt>

=cut

