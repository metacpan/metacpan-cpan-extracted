# NAME

WebService::Rollbar::Notifier - send messages to www.rollbar.com service

# SYNOPSIS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use WebService::Rollbar::Notifier;

    my $roll = WebService::Rollbar::Notifier->new(
        access_token => 'YOUR_post_server_item_ACCESS_TOKEN',
    );

    $roll->debug("Testing example stuff!",
        # this is some optional, abitrary data we're sending
        { foo => 'bar',
            caller => scalar(caller()),
            meow => {
                mew => {
                    bars => [qw/1 2 3 4 5 /],
                },
        },
    });

<div>
    </div></div>
</div>

# DESCRIPTION

This Perl module allows for blocking and non-blocking
way to send messages to [www.rollbar.com](http://www.rollbar.com) service.

# HTTPS ON SOLARIS

Note, this module will use HTTPS on anything but Solaris, where it will switch
to use plain HTTP. Based on CPAN Testers, the module fails with HTTPS there,
but since I don't have a Solaris box, I did not bother investigating this
fully. Patches are more than welcome.

# METHODS

## `->new()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $roll = WebService::Rollbar::Notifier->new(
        access_token => 'YOUR_post_server_item_ACCESS_TOKEN',

        # all these are optional; defaults shown:
        environment     => 'production',
        code_version    => undef,
        framework       => undef,
        server          => undef,
        callback        => sub {},
    );

Creates and returns new `WebService::Rollbar::Notifier` object.
Takes arguments as key/value pairs:

### `access_token`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">
</div>

    my $roll = WebService::Rollbar::Notifier->new(
        access_token => 'YOUR_post_server_item_ACCESS_TOKEN',
    );

**Mandatory**. This is your `post_server_item`
project access token.

### `environment`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">
</div>

    my $roll = WebService::Rollbar::Notifier->new(
        ...
        environment     => 'production',
    );

**Optional**. Takes a string **up to 255 characters long**. Specifies
the environment we're messaging from. **Defaults to** `production`.

### `code_version`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">
</div>

    my $roll = WebService::Rollbar::Notifier->new(
        ...
        code_version    => undef,
    );

**Optional**. **By default** is not specified.
Takes a string up to **40 characters long**. Describes the version
of the application code. Rollbar understands these formats:
semantic version (e.g. `2.1.12`), integer (e.g. `45`),
git SHA (e.g. `3da541559918a808c2402bba5012f6c60b27661c`).

### `framework`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">
</div>

    my $roll = WebService::Rollbar::Notifier->new(
        ...
        framework    => undef,
    );

**Optional**. **By default** is not specified.
The name of the framework your code uses

### `server`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-hashref.png">
</div>

    my $roll = WebService::Rollbar::Notifier->new(
        ...
        server    => {
            # Rollbar claims to understand following keys:
            host    => "server_name",
            root    => "/path/to/app/root/dir",
            branch  => "branch_name",
            code_version => "b6437f45b7bbbb15f5eddc2eace4c71a8625da8c",
        }
    );

**Optional**. **By default** is not specified.
Takes a hashref, which is used as "server" part of every Rollbar request made
by this notifier instance. See [https://rollbar.com/docs/api/items\_post/](https://rollbar.com/docs/api/items_post/) for
detailed description of supported fields.

### `callback`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-subref.png">
</div>

    # do nothing in the callback; this is default
    my $roll = WebService::Rollbar::Notifier->new(
        ...
        callback => sub {},
    );

    # perform a blocking call
    my $roll = WebService::Rollbar::Notifier->new(
        ...
        callback => undef,
    );

    # non-blocking; do something usefull in the callback
    my $roll = WebService::Rollbar::Notifier->new(
        ...
        callback => sub {
            my ( $ua, $tx ) = @_;
            say $tx->res->body;
        },
    );

**Optional**. **Takes** `undef` or a subref as a value.
**Defaults to** a null subref. If set to `undef`, notifications to
[www.rollbar.com](http://www.rollbar.com) will be
blocking, otherwise non-blocking, with
the `callback` subref called after a request completes. The subref
will receive in its `@_` the [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent) object that
performed the call and [Mojo::Transaction::HTTP](https://metacpan.org/pod/Mojo::Transaction::HTTP) object with the
response.

## `->notify()`

    $roll->notify('debug', "Message to send", {
        any      => 'custom',
        optional => 'data',
        to       => [qw/send goes here/],
    });

    # if we're doing blocking calls, then return value will be
    # the response JSON

    use Data::Dumper;;
    $roll->callback(undef);
    my $response = $roll->notify('debug', "Message to send");
    say Dumper( $response->res->json );

Takes two mandatory and one optional arguments. Always returns
true value if we're making non-blocking calls (see
`callback` argument to constructor). Otherwise, returns the response
as [Mojo::Transaction::HTTP](https://metacpan.org/pod/Mojo::Transaction::HTTP) object. The arguments are:

### First argument

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">
</div>

    $roll->notify('debug', ...

**Mandatory**. Specifies the type of message to send. Valid values
are `critical`, `error`, `warning`, `info`, and `debug`.
The module provides shorthand methods with those names to call
`notify`.

### Second argument

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">
</div>

    $roll->notify(..., "Message to send",

**Mandatory**. Takes a string
that specifies the message to send to [www.rollbar.com](http://www.rollbar.com).

### Third argument

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-hashref.png">
</div>

    $roll->notify(
        ...,
        ..., {
        any      => 'custom',
        optional => 'data',
        to       => [qw/send goes here/],
    });

**Optional**. Takes a hashref that will be converted to JSON and
sent along with the notification's message.

## `->critical()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png">
</div>

    $roll->critical( ... );

    # same as

    $roll->notify( 'critical', ... );

## `->error()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png">
</div>

    $roll->error( ... );

    # same as

    $roll->notify( 'error', ... );

## `->warning()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png">
</div>

    $roll->warning( ... );

    # same as

    $roll->notify( 'warning', ... );

## `->info()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png">
</div>

    $roll->info( ... );

    # same as

    $roll->notify( 'info', ... );

## `->debug()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png">
</div>

    $roll->debug( ... );

    # same as

    $roll->notify( 'debug', ... );

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-experimental.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Methods listed below are experimental and might change in future!

## `->report_message($message, $additional_parameters)`

Sends "message" type event to Rollbar.

    $roll->report_message("Message to send");

Parameters:

### $message

**Mandatory**. Specifies message text to be sent.

In addition to text your message can contain additional custom metadata fields.
In this case `$message` must be an arrayref, where first element is message
text and second is hashref with metadata.

    $roll->report_message(["Message to send", { some_key => "value" });

### $additional\_parameters

**Optional**. Takes a hashref which may contain any additional top-level fields
that you want to send with your message. Full list of fields supported by
Rollbar is available at [https://rollbar.com/docs/api/items\_post/](https://rollbar.com/docs/api/items_post/).

Notable useful field is `level` which can be used to set severity of your
message. Default level is "error". See ->notify() for list of supported levels.
Other example fields supported by Rollbar include: context, request, person, server.

    $roll->report_message("Message to send", { context => "controller#action" });

## `->report_trace($exception_class,..., $frames, $additional_parameters`

Reports "trace" type event to Rollbar, which is basically an exception.

### $exception\_class

**Mandatory**. This is exception class name (string).

It can be followed by 0 to 2 additional scalar parameters, which are
interpreted as exception message and exception description accordingly.

    $roll->report_trace("MyException", $frames);
    $roll->report_trace("MyException", "Total failure in module X", $frames);
    $roll->report_trace("MyException", "Total failure in module X", "Description", $frames);

### $frames

**Mandatory**. Contains frames from stacktrace. It can be either
[Devel::StackTrace](https://metacpan.org/pod/Devel::StackTrace) object (in which case we extract frames from this object) or
arrayref with frames in Rollbar format (described in
[https://rollbar.com/docs/api/items\_post/](https://rollbar.com/docs/api/items_post/))

### $additional\_parameters

**Optional**. See ["$additional\_parameters"](#additional_parameters) for details. Note that for
exceptions default level is "error".

<div>
    </div></div>
</div>

# ACCESSORS/MODIFIERS

## `->access_token()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    say 'Access token is ' . $roll->access_token;
    $roll->access_token('YOUR_post_server_item_ACCESS_TOKEN');

Getter/setter for `access_token` argument to `->new()`.

## `->code_version()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    say 'Code version is ' . $roll->code_version;
    $roll->code_version('1.42');

Getter/setter for `code_version` argument to `->new()`.

## `->environment()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    say 'Current environment is ' . $roll->environment;
    $roll->environment('1.42');

Getter/setter for `environment` argument to `->new()`.

## `->callback()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-subref.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-subref.png">
</div>

    $roll->callback->(); # call current callback
    $roll->callback( sub { say "Foo!"; } );

Getter/setter for `callback` argument to `->new()`.

# SEE ALSO

Rollbar API docs: [https://rollbar.com/docs/api/items\_post/](https://rollbar.com/docs/api/items_post/)

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/WebService-Rollbar-Notifier](https://github.com/zoffixznet/WebService-Rollbar-Notifier)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/WebService-Rollbar-Notifier/issues](https://github.com/zoffixznet/WebService-Rollbar-Notifier/issues)

If you can't access GitHub, you can email your request
to `bug-webservice-rollbar-notifier at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
