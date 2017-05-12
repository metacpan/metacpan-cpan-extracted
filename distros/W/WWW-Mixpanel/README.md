# NAME

WWW::Mixpanel

# VERSION

version 0.07

# SYNOPSIS

    use WWW::Mixpanel;
    my $mp = WWW::Mixpanel->new( '1827378adad782983249287292a', 1 );
    $mp->track('login', distinct_id => 'username', mp_name_tag => 'username', source => 'twitter');

or if you also want to access the data api

    my $mp = WWW::Mixpanel->new(<API TOKEN>,1,<API KEY>,<API SECRET>);
    $mp->track('login', distinct_id => 'username', mp_name_tag => 'username', source => 'twitter');
    my $enames = $mp->data( 'events/names', type => 'unique' );
    my $fdates = $mp->data( 'funnels/dates',
                   funnel => [qw/funnel1 funnel2/],
                   unit   => 'week' );

# DESCRIPTION

The WWW::Mixpanel module is an implementation of the [http://mixpanel.com](http://mixpanel.com) API which provides realtime online analytics. [http://mixpanel.com](http://mixpanel.com) receives events from your application's perl code, javascript, email open and click tracking, and many more sources, and provides visualization and publishing of analytics.

Currently, this module mirrors the event tracking API ([http://mixpanel.com/api/docs/specification](http://mixpanel.com/api/docs/specification)), and will be extended to include the powerful data access and platform parts of the api. __FEATURE REQUESTS__ are always welcome, as are patches.

This module is designed to die on failure, please use something like Try::Tiny.

# NAME

WWW::Mixpanel

# VERSION

version 0.07

# NAME

WWW::Mixpanel

# VERSION

version 0.07

# METHODS

## new( $token, \[$use\_ssl\] )

Returns a new instance of this class. You must supply the API token for your mixpanel project. HTTP is used to connect unless you provide a true value for use\_ssl.

## track('<event name>', \[time => timestamp, param => val, ...\])

Send an event to the API with the given event name, which is a required parameter. If you do not include a time parameter, the value of time() is set for you automatically. Other parameters are optional, and are included as-is as parameters in the api.

This method returns 1 or dies with a message.

Per the Mixpanel API, a 1 return indicates the event reached the mixpanel.com API and was properly formatted. 1 does not indicate the event was actually written to your project, in cases such as bad API token. This is a limitation of the service.

You are strongly encouraged to use something like `Try::Tiny` to wrap calls to this API.

Today, there is no way to set URL parameters such as ip=1, callback, img, redirect. You can supply ip as a parameter similar to distinct\_id, to track users.

## data('<path/path>', param => val, param => val ...)

Obtain data from mixpanel.com using the [Data API](http://mixpanel.com/api/docs/guides/api/v2).
The first parameter to the method identifies the path off the api root.

For example to access the `events/top` functionality, found at [http://mixpanel.com/api/2.0/events/top/](http://mixpanel.com/api/2.0/events/top/), you would pass the string `events/top` to the data method.

Some parameters of the data api are of array type, for example `events/retention` parameter `event`. In every case where a parameter is of array type, you may supply the parameter as either an ARRAYREF or a single string.

Unless specified as a parameter, the default return format is json.
This method will then return the result of the api call as a decoded perl object.

If you specify format => 'csv', this method will return the csv return string unchanged.

This method will die on errors, including malformed parameters, indicated by bad return codes from the api. It dies with the text of the api reply directly, often a json string indicating which parameter was malformed.

_To see all API methods at work, look into the module tests._

## people\_set('distinct\_id', param => val, param => val ...)

Sets people properties on a distinct\_id

## people\_increment('distinct\_id', param => val, param => val ...)

Increments people properties on a distinct\_id

## people\_track\_charge('distinct\_id', charge\_amount)

Tracks a revenue event for specific charge amount

# TODO

- /track to accept array of events

    Track will soon be able to accept many events, and will bulk-send them to mixpanel in one call if possible.

- /platform support

    The Platform API will be supported. Let me know if this is a feature you'd like to use.

# FEATURE REQUESTS

Please send feature requests to me via rt or github. Patches are always welcome.

# BUGS

Do your thing on CPAN.

# AFFILIATION

I am not affiliated with mixpanel, I just use and like the service.

# AUTHOR

Tom Eliaz

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Tom Eliaz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# AUTHOR

Tom Eliaz

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Tom Eliaz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# AUTHOR

Tom Eliaz

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Tom Eliaz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
