# NAME

Webservice::OVH  - A perl representation of the ovh-api

# SYNOPSIS

    use Webservice::OVH;

    my $ovh = Webservice::OVH->new("credentials.json");

    my $ovh = Webservice::OVH->new(application_key => $key, application_secret => $secret, consumer_key => $token);

    my $services = $ovh->domain->services;

    foreach my $service (@$services) {
    
        my $last_update = $service->last_update;
        print $last_update->datetime;
    }

# DESCRIPTION

This module reflects the path structure of the ovh web-api.
This is the base object from where all api calls originate.

This module uses the perl api module provided by ovh.

<div>
    <p><center><img src="https://raw.githubusercontent.com/itnode/Webservice-OVH/master/inc/API_HowTo.png"></center></p>
</div>

# METHODS

## new\_from\_json

Creates an api Object based on credentials in a json File

- Parameter: $file\_json - dir to json file
- Return: [Webservice::OVH](https://metacpan.org/pod/Webservice::OVH)
- Synopsis: Webservice::OVH->new\_from\_json("path/file");

- application\_key      is generated when creating an application via ovh web interface
- application\_secret   is generated when creating an application via ovh web interface
- consumer\_key         must be requested through ovh authentification
- timeout              timeout in milliseconds, warning some request may take a while

## new

Create the api object. Credentials are given directly via %params
Credentials can be generated via ovh web interface and ovh authentification

- Parameter: %params - application\_key => value, application\_secret => value, consumer\_key => value
- Return: [Webservice::OVH](https://metacpan.org/pod/Webservice::OVH)
- Synopsis: Webservice::OVH->new(application\_key => $key, application\_secret => $secret, consumer\_key => $token);

## set\_timeout

Sets the timeout of the underlying LWP::Agent

- Parameter: timeout - in milliseconds default 120
- Synopsis: Webservice::OVH->set\_timeout(120);

## domain

Main access to all /domain/ api methods 

- Return: [Webservice::OVH::Domain](https://metacpan.org/pod/Webservice::OVH::Domain)
- Synopsis: $ovh->domain;

## me

Main access to all /me/ api methods 

- Return: [Webservice::OVH::Me](https://metacpan.org/pod/Webservice::OVH::Me)
- Synopsis: $ovh->me;

## order

Main access to all /order/ api methods 

- Return: [Webservice::OVH::Order](https://metacpan.org/pod/Webservice::OVH::Order)
- Synopsis: $ovh->order;

## email

Main access to all /email/ api methods 

- Return: [Webservice::OVH::Email](https://metacpan.org/pod/Webservice::OVH::Email)
- Synopsis: $ovh->email;

## cloud

Main access to all /cloud/ api methods 

- Return: [Webservice::OVH::Cloud](https://metacpan.org/pod/Webservice::OVH::Cloud)
- Synopsis: $ovh->cloud;

# AUTHOR

Patrick Jendral

# COPYRIGHT AND LICENSE

This library is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
