package WebService::Pixela;
use 5.010001;
use strict;
use warnings;
use HTTP::Tiny;
use Carp;
use WebService::Pixela::User;
use WebService::Pixela::Graph;
use WebService::Pixela::Pixel;
use WebService::Pixela::Webhook;
use URI;
use JSON;
use Class::Accessor::Lite(
    new => 0,
    ro  => [qw/
        user
        graph
        pixel
        webhook
        _agent
    /],
    rw  => [qw/
        username
        token
        base_url
    /],
);

our $VERSION = "0.01";

sub new {
    my ($class,%args) = @_;
    my $self = bless +{}, $class;

    # initalize
    $self->{username} = $args{username} // croak 'require username';
    $self->{token}    = $args{token}    // (carp('not input token'), undef);
    $self->{base_url} = $args{base_url} // "https://pixe.la/";
    $self->{decode}   = $args{decode}   // 1;
    $self->{_agent}   = HTTP::Tiny->new();

    #WebService::Pixela instances
    $self->{user}    = WebService::Pixela::User->new($self);
    $self->{graph}   = WebService::Pixela::Graph->new($self);
    $self->{pixel}   = WebService::Pixela::Pixel->new($self);
    $self->{webhook} = WebService::Pixela::Webhook->new($self);

    return $self;
}

sub decode {
    my $self = shift;
    if (@_){
        $self->{decode} = shift;
        return $self;
    }
    return $self->{decode};
}

sub _decode_or_simple_return_from_json {
    my ($self,$rev_json) = @_;

    unless ($self->decode){
        return $rev_json;
    }

    return decode_json($rev_json);
}

sub _request {
    my ($self,$method,$path,$params) = @_;

    my $uri = URI->new('v1/'.$path)->abs($self->base_url);

    my $receive_json = $self->_agent->request($method, $uri->as_string, $params)->{"content"};

    return $self->_decode_or_simple_return_from_json($receive_json);
}

sub query_request {
    my ($self,$method,$path,$query) = @_;

    my $uri = URI->new('v1/'.$path)->abs($self->base_url);

    if ($query){
        $uri->query_form($query);
    }

    return $self->_agent->request($method, $uri->as_string)->{"content"};
}


sub request {
    my ($self,$method,$path,$content) = @_;

    my $params = {};
    if (defined $content && %$content){
        $params->{content} = encode_json($content);
    }

    return $self->_request($method,$path,$params);
}

sub request_with_xuser_in_header {
    my ($self,$method,$path,$content) = @_;

    my $params = {
        headers => { 'X-USER-TOKEN' => $self->token },
    };

    if (defined $content && %$content){
        $params->{content} = encode_json($content);
    }

    return $self->_request($method,$path,$params);
}

sub request_with_content_length_in_header {
    my ($self,$method,$path,$length) = @_;

    $length //= 0;

    my $params = {
        headers => { 'Content-Length' => $length },
    };

    return $self->_request($method,$path);
}

sub request_with_dual_in_header {
    my ($self,$method,$path,$length) = @_;

    $length //= 0;

    my $params = {
        headers => {
            'X-USER-TOKEN'   => $self->token,
            'Content-Length' => $length,
        },
    };

    return $self->_request($method,$path,$params);
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Pixela - It's L<https://pixe.la> API client for Perl.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WebService::Pixela;

    # All WebService::Pixela methods use this token and user name in URI, JSON, etc.
    my $pixela = WebService::Pixela->new(token => "thisissecret", username => "testname");

    $pixela->user->create(); # default agreeTermsOfService and notMinor "yes"
    # or...
    $pixela->user->create(agree_terms_of_service => "yes", not_minor => "no"); # can input agreeTermsOfService and notMinor

    my %graph_params = (
        name     => 'test_graph',
        unit     => 'test',
        type     => 'int',
        color    => 'shibafu',
        timezone => 'Asia/Tokyo',
    );

    print $pixela->graph->id('graph_id')->create(%graph_params)->{message} . "\n";

    #return json text

    my $json = $pixela->decode(0)->graph->get();
    $pixela->decode(1);
    $pixela->webhook->create(type => 'increment');

    my $hash = $pixela->webhook->hash() . "\n";
    my $pixel = $pixela->pixel->get(date => '20180915');

    $pixela->user->delete(); # delete method not require arguments


=head1 DESCRIPTION

WebService::Pixela is API client about L<https://pixe.la>

=head1 CI_PIXELA

=begin html

<a href="https://pixe.la/v1/users/anatofuz/graphs/p5-cpan-pixela.html"><img src="https://pixe.la/v1/users/anatofuz/graphs/p5-cpan-pixela" alt="CI activity" style="max-width:100%"></a>

=end html

=head1 ORIGINAL API DOCUMENT

See also L<https://docs.pixe.la/> .

This module corresponds to version 1.

=head1 INTERFACE

=head2 Class Methods

=head3 C<< WebService::Pixela->new(%args) >>

It is WebService::Pixela constructor.

I<%args> might be:

=over

=item C<< username :  Str >>

Pixela service username.

=item C<< token  :  Str >>

Pixela service token.

=item C<< base_url : Str : default => 'https://pixe.la/' >>

Pixela service api root url.
(It does not include version URL.)

=item C<< decode : boolean : default => 1  >>

If I<decode> is true it returns a Perl object, false it returns json as is.


=back

=head4 What does the WebService::Pixela instance contain?

WebService::Pixela instance have four representative instance methods.
Each representative instance methods is an instance of the same class 'WebService::Pixela::' name.

=head2 Instance Methods (It does not call other WebService::Pixela::.* instances.)

=head3 C<< $pixela->username  : Str >>

Output and set the user name of the instance.

=head3 C<< $pixela->token  : Str >>

Output and set the token of the instance.

=head3 C<< $pixela->base_url : Str >>

Output and set the base url of the instance.

=head3 C<< $pixela->decode : boolean   >>

Output and set the decode of the instance.
If I<decode> is true it returns a Perl object, false it returns json as is.

=head2 Instance Methods 

It conforms to the official API document.
See aloso L<https://docs.pixe.la/> .

=head3 C<< $pixela->user >>

This instance method uses  a L<WebService::Pixela::User> instance.

=head4 C<< $pixela->user->create(%opts) >>

It is Pixe.la user create.


I<%opts> might be:

=over

=item C<< agree_terms_of_service :  [yes|no]  (default : "yes" ) >>

Specify yes or no whether you agree to the terms of service.
If there is no input, it defaults to yes. (For this module.)

=item C<< not_minor :  [yes|no]  (default : "yes") >>

Specify yes or no as to whether you are not a minor or if you are a minor and you have the parental consent of using this (Pixela) service.
If there is no input, it defaults to yes. (For this module.)

=back

See also L<https://docs.pixe.la/#/post-user>

=head4 C<< $pixela->user->update($newtoken) >>

Updates the authentication token for the specified user.

I<$newtoken> might be:

=over

=item C<< $newtoken :Str >>

It is a new authentication token.

=back

See also L<https://docs.pixe.la/#/update-user>

=head4 C<< $pixela->user->delete() >>

Deletes the specified registered user.

See also L<https://docs.pixe.la/#/delete-user>

=head3 C<< $pixela->graph >>

This instance method uses  a L<WebService::Pixela::Graph> instance.

=head4 C<< $pixela->graph->create(%opts) :$hash_ref >>

It is Pixe.la graph create.

I<%opts> might be:

=over

=item C<< [required (autoset)] id :  Str >>

It is an ID for identifying the pixelation graph.

If set in an instance of WebService::Pixela::Graph, use that value.

=item C<< [required] name :  Str >>

It is the name of the pixelation graph.

=item C<< [required] unit :  Str >>

It is a unit of the quantity recorded in the pixelation graph. Ex. commit, kilogram, calory.

=item C<< [required] type :  Str >>

It is the type of quantity to be handled in the graph. Only int or float are supported.

=item C<< [required] color : Str >>

Defines the display color of the pixel in the pixelation graph.
I<shibafu> (green), I<momiji> (red), I<sora> (blue), I<ichou> (yellow), I<ajisai> (purple) and I<kuro> (black) are supported as color kind.

=item C<< timezone : Str  >>

[optional] Specify the timezone for handling this graph as I<Asia/Tokyo>. 
If not specified, it is treated as I<UTC>.

=item C<< self_sufficient : Str  >>

[optional] If SVG graph with this field I<increment> or I<decrement> is referenced, Pixel of this graph itself will be incremented or decremented.
It is suitable when you want to record the PVs on a web page or site simultaneously.
The specification of increment or decrement is the same as Increment a Pixel and Decrement a Pixel with webhook.
If not specified, it is treated as I<none> .

=back

See Also L<https://docs.pixe.la/#/post-graph>

=head4 C<< $pixela->graph->get() >>

Get all predefined pixelation graph definitions.

If you setting I<$pixela->decode(1) [default]> return array refs.
Otherwise it returns json.

See Also L<https://docs.pixe.la/#/get-graph>

=head4 C<< $pixela->graph->get_svg(%args) >>

I<%opts> might be:

=over

=item C<< data :Str >>

[optional] If you specify it in yyyyMMdd format, will create a pixelation graph dating back to the past with that day as the start date.
If this parameter is not specified, the current date and time will be the start date.
(it is used C<<timezone>> setting if Graph’s C<<timezone>> is specified, if not specified, calculates it in C<<UTC>>)

=item C<< mode :Str >>

[optional] Specify the graph display mode.
As of October 23, 2018, support only short mode for displaying only about 90 days.

=back

See Also L<https://docs.pixe.la/#/get-svg>

=head4 C<< $pixela->graph->update(%args) >>

I<%options> might be C<< $pixela->graph->create() >> options.

See Also L<https://docs.pixe.la/#/put-graph>

=head4 C<< $pixela->graph->delete() >>

Delete the predefined pixelation graph definition.

See Also L<https://docs.pixe.la/#/delete-graph>

=head4 C<< $pixela->graph->html() >>

Displays the details of the graph in html format.
(This method return html urls)

See Also L<https://docs.pixe.la/#/get-graph-html>

=head4 C<< $pixela->graph->pixels(%args) >>

Get a Date list of Pixel registered in the graph specified by graphID.
You can specify a period with from and to parameters.

I<%args> might be

=over

=item C<< from :Str >>

[optional] Specify the start position of the period.

=item C<< to : Str >>

[optional] Specify the end position of the period.

=back

See Also L<https://docs.pixe.la/#/get-graph-pixels>

=head3 C<< $pixela->pixel >>

This instance method uses  a L<WebService::Pixela::Pixel> instance.


=head4 C<< $pixela->pixel->post(%opts) >>

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

See also

L<https://docs.pixe.la/#/post-pixel>


=head4 C<< $pixela->pixel->get(%opts) >>

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

See also

L<https://docs.pixe.la/#/get-pixel>

=head4 C<< $pixela->pixel->update(%opts) >>

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

See also

L<https://docs.pixe.la/#/put-pixel>

=head4 C<< $pixela->pixel->increment(%opts) >>

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

See also

L<https://docs.pixe.la/#/increment-pixel>

=head4 C<< $pixela->pixel->decrement(%opts) >>


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

See also

L<https://docs.pixe.la/#/decrement-pixel>

=head4 C<< $pixela->pixel->delete(%opts) >>

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

See also

L<https://docs.pixe.la/#/delete-pixel>

=head3 C<< $pixela->webhook >>

This instance method uses  a L<WebService::Pixela::Webhook> instance.

=head4 C<< $pixela->webhook->create(%opts) >>

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

=head4 C<< $pixela->webhook->hash($webhookhash) >>

This is webhookHash.
Used by Pixela's webhook service.

I<$webhookhash> might be:

=over

=item C<< $webhookhash :Str >>

It is a new webhookHash.
If the graph id is set for an instance, it will be automatically used create method.

=back

=head4 C<< $pixela->webhook->get() >>

Get all predefined webhooks definitions.
This method return array_ref or json value(switching decode method).

See also L<https://docs.pixe.la/#/get-webhook>

=head4 C<< $pixela->webhook->invoke($webhookhash) >>

Invoke the webhook registered in advance.
It is used “timezone” setting as post date if Graph’s “timezone” is specified, if not specified, calculates it in “UTC”.

I<$webhookhash> might be:

=over

=item C<< $webhookhash :Str >>

If the webhookhash is using thid method , it will be automatically used.
(You do not need to enter it as an argument)

=back

See also L<https://docs.pixe.la/#/invoke-webhook>

=head4 C<< $pixela->webhook->delete($webhookhash) >>

Delete the registered Webhook.

I<$webhookhash> might be:

=over

=item C<< $webhookhash :Str >>

If the webhookhash is using thid method , it will be automatically used.
(You do not need to enter it as an argument)

=back

See also L<https://docs.pixe.la/#/delete-webhook>

=head1 LICENSE

Copyright (C) Takahiro SHIMIZU.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takahiro SHIMIZU E<lt>anatofuz@gmail.comE<gt>

=cut

