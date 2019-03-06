[![Build Status](https://travis-ci.com/AnaTofuZ/p5-WebService-Pixela.svg?branch=master)](https://travis-ci.com/AnaTofuZ/p5-WebService-Pixela)
# NAME

WebService::Pixela - It's [https://pixe.la](https://pixe.la) API client for Perl.

# SYNOPSIS

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

# DESCRIPTION

WebService::Pixela is API client about [https://pixe.la](https://pixe.la)

# CI\_PIXELA

<div>
    <a href="https://pixe.la/v1/users/anatofuz/graphs/p5-cpan-pixela.html"><img src="https://pixe.la/v1/users/anatofuz/graphs/p5-cpan-pixela" alt="CI activity" style="max-width:100%"></a>
</div>

# ORIGINAL API DOCUMENT

See also [https://docs.pixe.la/](https://docs.pixe.la/) .

This module corresponds to version 1.

# INTERFACE

## Class Methods

### `WebService::Pixela->new(%args)`

It is WebService::Pixela constructor.

_%args_ might be:

- `username :  Str`

    Pixela service username.

- `token  :  Str`

    Pixela service token.

- `base_url : Str : default => 'https://pixe.la/'`

    Pixela service api root url.
    (It does not include version URL.)

- `decode : boolean : default => 1`

    If _decode_ is true it returns a Perl object, false it returns json as is.

#### What does the WebService::Pixela instance contain?

WebService::Pixela instance have four representative instance methods.
Each representative instance methods is an instance of the same class 'WebService::Pixela::' name.

## Instance Methods (It does not call other WebService::Pixela::.\* instances.)

### `$pixela->username  : Str`

Output and set the user name of the instance.

### `$pixela->token  : Str`

Output and set the token of the instance.

### `$pixela->base_url : Str`

Output and set the base url of the instance.

### `$pixela->decode : boolean`

Output and set the decode of the instance.
If _decode_ is true it returns a Perl object, false it returns json as is.

## Instance Methods 

It conforms to the official API document.
See aloso [https://docs.pixe.la/](https://docs.pixe.la/) .

### `$pixela->user`

This instance method uses  a [WebService::Pixela::User](https://metacpan.org/pod/WebService::Pixela::User) instance.

#### `$pixela->user->create(%opts)`

It is Pixe.la user create.

_%opts_ might be:

- `agree_terms_of_service :  [yes|no]  (default : "yes" )`

    Specify yes or no whether you agree to the terms of service.
    If there is no input, it defaults to yes. (For this module.)

- `not_minor :  [yes|no]  (default : "yes")`

    Specify yes or no as to whether you are not a minor or if you are a minor and you have the parental consent of using this (Pixela) service.
    If there is no input, it defaults to yes. (For this module.)

See also [https://docs.pixe.la/#/post-user](https://docs.pixe.la/#/post-user)

#### `$pixela->user->update($newtoken)`

Updates the authentication token for the specified user.

_$newtoken_ might be:

- `$newtoken :Str`

    It is a new authentication token.

See also [https://docs.pixe.la/#/update-user](https://docs.pixe.la/#/update-user)

#### `$pixela->user->delete()`

Deletes the specified registered user.

See also [https://docs.pixe.la/#/delete-user](https://docs.pixe.la/#/delete-user)

### `$pixela->graph`

This instance method uses  a [WebService::Pixela::Graph](https://metacpan.org/pod/WebService::Pixela::Graph) instance.

#### `$pixela->graph->create(%opts) :$hash_ref`

It is Pixe.la graph create.

_%opts_ might be:

- `[required (autoset)] id :  Str`

    It is an ID for identifying the pixelation graph.

    If set in an instance of WebService::Pixela::Graph, use that value.

- `[required] name :  Str`

    It is the name of the pixelation graph.

- `[required] unit :  Str`

    It is a unit of the quantity recorded in the pixelation graph. Ex. commit, kilogram, calory.

- `[required] type :  Str`

    It is the type of quantity to be handled in the graph. Only int or float are supported.

- `[required] color : Str`

    Defines the display color of the pixel in the pixelation graph.
    _shibafu_ (green), _momiji_ (red), _sora_ (blue), _ichou_ (yellow), _ajisai_ (purple) and _kuro_ (black) are supported as color kind.

- `timezone : Str`

    \[optional\] Specify the timezone for handling this graph as _Asia/Tokyo_. 
    If not specified, it is treated as _UTC_.

- `self_sufficient : Str`

    \[optional\] If SVG graph with this field _increment_ or _decrement_ is referenced, Pixel of this graph itself will be incremented or decremented.
    It is suitable when you want to record the PVs on a web page or site simultaneously.
    The specification of increment or decrement is the same as Increment a Pixel and Decrement a Pixel with webhook.
    If not specified, it is treated as _none_ .

See Also [https://docs.pixe.la/#/post-graph](https://docs.pixe.la/#/post-graph)

#### `$pixela->graph->get()`

Get all predefined pixelation graph definitions.

If you setting _$pixela-_decode(1) \[default\]> return array refs.
Otherwise it returns json.

See Also [https://docs.pixe.la/#/get-graph](https://docs.pixe.la/#/get-graph)

#### `$pixela->graph->get_svg(%args)`

_%opts_ might be:

- `data :Str`

    \[optional\] If you specify it in yyyyMMdd format, will create a pixelation graph dating back to the past with that day as the start date.
    If this parameter is not specified, the current date and time will be the start date.
    (it is used `<timezone`> setting if Graph’s `<timezone`> is specified, if not specified, calculates it in `<UTC`>)

- `mode :Str`

    \[optional\] Specify the graph display mode.
    As of October 23, 2018, support only short mode for displaying only about 90 days.

See Also [https://docs.pixe.la/#/get-svg](https://docs.pixe.la/#/get-svg)

#### `$pixela->graph->update(%args)`

_%options_ might be `$pixela->graph->create()` options.

See Also [https://docs.pixe.la/#/put-graph](https://docs.pixe.la/#/put-graph)

#### `$pixela->graph->delete()`

Delete the predefined pixelation graph definition.

See Also [https://docs.pixe.la/#/delete-graph](https://docs.pixe.la/#/delete-graph)

#### `$pixela->graph->html()`

Displays the details of the graph in html format.
(This method return html urls)

See Also [https://docs.pixe.la/#/get-graph-html](https://docs.pixe.la/#/get-graph-html)

#### `$pixela->graph->pixels(%args)`

Get a Date list of Pixel registered in the graph specified by graphID.
You can specify a period with from and to parameters.

_%args_ might be

- `from :Str`

    \[optional\] Specify the start position of the period.

- `to : Str`

    \[optional\] Specify the end position of the period.

See Also [https://docs.pixe.la/#/get-graph-pixels](https://docs.pixe.la/#/get-graph-pixels)

### `$pixela->pixel`

This instance method uses  a [WebService::Pixela::Pixel](https://metacpan.org/pod/WebService::Pixela::Pixel) instance.

#### `$pixela->pixel->post(%opts)`

It records the quantity of the specified date as a "Pixel".

_%opts_ might be:

- `([required]) id  :  Str`

    Specify the target graph as an ID.
    If the graph id is set for an instance, it will be automatically used.
    (You do not need to enter it as an argument)

- `[required] date : [yyyyMMdd]`

    The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

- `[required] quantity : String`

    Specify the quantity to be registered on the specified date.
    Validation rule: int^-?\[0-9\]+ float^-?\[0-9\]+.\[0-9\]+

- `optional_data : json_string`

    Additional information other than quantity. It is specified as JSON string.
    The amount of this data must be less than 10 KB.

See also

[https://docs.pixe.la/#/post-pixel](https://docs.pixe.la/#/post-pixel)

#### `$pixela->pixel->get(%opts)`

Get registered quantity as "Pixel".

_%opts_ might be:

- `([required]) id  :  Str`

    Specify the target graph as an ID.
    If the graph id is set for an instance, it will be automatically used.
    (You do not need to enter it as an argument)

- `[required] date : [yyyyMMdd]`

    The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

See also

[https://docs.pixe.la/#/get-pixel](https://docs.pixe.la/#/get-pixel)

#### `$pixela->pixel->update(%opts)`

Update the quantity already registered as a "Pixel".
If target "Pixel" not exist, create a new "Pixel" and set quantity.

_%opts_ might be:

- `([required]) id  :  Str`

    Specify the target graph as an ID.
    If the graph id is set for an instance, it will be automatically used.
    (You do not need to enter it as an argument)

- `[required] date : [yyyyMMdd]`

    The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

- `quantity : String`

    Specify the quantity to be registered on the specified date.
    Validation rule: int^-?\[0-9\]+ float^-?\[0-9\]+.\[0-9\]+

- `optional_data : json_string`

    Additional information other than quantity. It is specified as JSON string.
    The amount of this data must be less than 10 KB.

See also

[https://docs.pixe.la/#/put-pixel](https://docs.pixe.la/#/put-pixel)

#### `$pixela->pixel->increment(%opts)`

Increment quantity "Pixel" of the day (it is used "timezone" setting if Graph's "timezone" is specified, if not specified, calculates it in "UTC").
If the graph type is int then 1 added, and for float then 0.01 added.

_%opts_ might be:

- `([required]) id  :  Str`

    Specify the target graph as an ID.
    If the graph id is set for an instance, it will be automatically used.
    (You do not need to enter it as an argument)

- `[required] date : [yyyyMMdd]`

    The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

- `length : Int (default 0)`

    Since the request body is not specifield, specify the _Content-Length_ header.
    (Default 0)

See also

[https://docs.pixe.la/#/increment-pixel](https://docs.pixe.la/#/increment-pixel)

#### `$pixela->pixel->decrement(%opts)`

Decrement quantity "Pixel" of the day (it is used "timezone" setting if Graph's "timezone" is specified, if not specified, calculates it in "UTC").
If the graph type is int then -1 added, and for float then -0.01 added.

_%opts_ might be:

- `([required]) id  :  Str`

    Specify the target graph as an ID.
    If the graph id is set for an instance, it will be automatically used.
    (You do not need to enter it as an argument)

- `[required] date : [yyyyMMdd]`

    The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

- `length : Int (default 0)`

    Since the request body is not specifield, specify the _Content-Length_ header.
    (Default 0)

See also

[https://docs.pixe.la/#/decrement-pixel](https://docs.pixe.la/#/decrement-pixel)

#### `$pixela->pixel->delete(%opts)`

Delete the registered "Pixel".

_%opts_ might be:

- `([required]) id  :  Str`

    Specify the target graph as an ID.
    If the graph id is set for an instance, it will be automatically used.
    (You do not need to enter it as an argument)

- `[required] date : [yyyyMMdd]`

    The date on which the quantity is to be recorded. It is specified in yyyyMMdd format.

See also

[https://docs.pixe.la/#/delete-pixel](https://docs.pixe.la/#/delete-pixel)

### `$pixela->webhook`

This instance method uses  a [WebService::Pixela::Webhook](https://metacpan.org/pod/WebService::Pixela::Webhook) instance.

#### `$pixela->webhook->create(%opts)`

Create a new Webhook by Pixe.la
This method return webhookHash, this is automatically set instance.

_%opts_ might be:

- `[required] graph_id  :  Str`

    Specify the target graph as an ID.
    If the graph id is set for an instance, it will be automatically used.
    (You do not need to enter it as an argument)

- `[required] type : [increment|decrement]`

    Specify the behavior when this Webhook is invoked.
    Only `increment` or `decrement` are supported.
    (There is no distinction between upper case and lower case letters.)

#### See also

[https://docs.pixe.la/#/post-webhook](https://docs.pixe.la/#/post-webhook)

#### `$pixela->webhook->hash($webhookhash)`

This is webhookHash.
Used by Pixela's webhook service.

_$webhookhash_ might be:

- `$webhookhash :Str`

    It is a new webhookHash.
    If the graph id is set for an instance, it will be automatically used create method.

#### `$pixela->webhook->get()`

Get all predefined webhooks definitions.
This method return array\_ref or json value(switching decode method).

See also [https://docs.pixe.la/#/get-webhook](https://docs.pixe.la/#/get-webhook)

#### `$pixela->webhook->invoke($webhookhash)`

Invoke the webhook registered in advance.
It is used “timezone” setting as post date if Graph’s “timezone” is specified, if not specified, calculates it in “UTC”.

_$webhookhash_ might be:

- `$webhookhash :Str`

    If the webhookhash is using thid method , it will be automatically used.
    (You do not need to enter it as an argument)

See also [https://docs.pixe.la/#/invoke-webhook](https://docs.pixe.la/#/invoke-webhook)

#### `$pixela->webhook->delete($webhookhash)`

Delete the registered Webhook.

_$webhookhash_ might be:

- `$webhookhash :Str`

    If the webhookhash is using thid method , it will be automatically used.
    (You do not need to enter it as an argument)

See also [https://docs.pixe.la/#/delete-webhook](https://docs.pixe.la/#/delete-webhook)

# LICENSE

Copyright (C) Takahiro SHIMIZU.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takahiro SHIMIZU <anatofuz@gmail.com>
