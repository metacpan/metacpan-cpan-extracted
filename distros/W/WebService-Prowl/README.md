# NAME

WebService::Prowl - a interface to Prowl Public API

# SYNOPSIS

    use WebService::Prowl;

# DESCRIPTION

WebService::Prowl is a interface to Prowl Public API

# SYNOPSIS

This module aims to be a implementation of a interface to the Prowl Public API (as available on http://www.prowlapp.com/api.php)

    use WebService::Prowl;
    my $ws = WebService::Prowl->new(apikey => '40byteshexadecimalstring');
    $ws->verify || die $ws->error();
    $ws->add(application => "Favotter App",
             event       => "new fav",
             description => "your tweet saved as sekimura's favorite",
             url         => "https://github.com/sekimura");

# METHODS

- new(apikey => 40byteshexadecimalstring, providerkey => yetanother40byteshex)

    Call new() to create a Prowl Public API client object. You must pass the apikey, which you can generate on "settings" page https://www.prowlapp.com/settings.php

        my $apikey = 'cf09b20df08453f3d5ec113be3b4999820341dd2';
        my $ws = WebService::Prowl->new(apikey => $apikey);

    If you have been whitelisted, you may want to use 'providerkey' like this:

        my $apikey      = 'cf09b20df08453f3d5ec113be3b4999820341dd2';
        my $providerkey = '68b329da9893e34099c7d8ad5cb9c94010200121';

        my $ws = WebService::Prowl->new(apikey => $apikey, providerkey => $providerkey);

- verify()

    Sends a verify request to check if apikey is valid or not. return 1 for success.

        $ws->verify();

- add(application => $app, event => $event, description => $desc, priority => $pri)

    Sends a app request to api and return 1 for success.

        application: [256] (required)
            The name of your application

        event: [1024] (required)
            The name of the event

        description: [10000] (required)
            A description for the event

        url: [512] Optional
            *Requires Prowl 1.2* The URL which should be attached to the notification.

        priority: An integer value ranging [-2, 2]
            a priority of the notification: Very Low, Moderate, Normal, High, Emergency
            default is 0 (Normal)

        $ws->add(application => "Favotter App",
                 event       => "new fav",
                 description => "your tweet saved as sekimura's favorite");

- retrieve\_token()

    Get a registration token for use in retrieve/apikey and the associated URL for the user to approve the request.
    See example/retrieve to learn how to use retrieve\_token() and retrieve\_apikey()

    success return value looks like this:

        $VAR1 = {
            'success' => {
                'remaining' => '999',
                'resetdate' => '1296803193',
                'code' => '0'
            },
            'retrieve' => {
                'url' => 'https://www.prowlapp.com/retrieve.php?token=fe645f043ce20f7f179c909df062334c14c51a8b',
                'token' => 'fe645f043ce20f7f179c909df062334c14c51a8b'
            }
        };

- retrieve\_apikey(token => $token)

    Get an API key from a registration token retrieved in retrieve/token. The user must have approved your request first, or you will get an error response.
    See example/retrieve to learn how to use retrieve\_token() and retrieve\_apikey()

    success return value looks like this:

        $VAR1 = {
            'success' => {
                'remaining' => '999',
                'resetdate' => '1296803193',
                'code' => '200'
            },
            'retrieve' => {
                'apikey' => 'd17e9cfffcb0a0c3091beda69cc31b6134c875c8'
            }
        };

- error()

    Returns any error messages as a string.

        $ws->verify() || die $ws->error();

# AUTHOR

Masayoshi Sekimura <sekimura@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[http://www.prowlapp.com/](http://www.prowlapp.com/), [https://itunes.apple.com/us/app/prowl-easy-push-notifications/id320876271?mt=8](https://itunes.apple.com/us/app/prowl-easy-push-notifications/id320876271?mt=8)
