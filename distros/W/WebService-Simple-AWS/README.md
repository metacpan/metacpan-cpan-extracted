# NAME

WebService::Simple::AWS - Simple Interface to Amazon Web Service using WebService::Simple

# SYNOPSIS

    use WebService::Simple::AWS;

    my $service = WebService::Simple::AWS->new(
        base_url => 'http://webservices.amazon.com/onca/xml',
        params   => {
            Version => '2009-03-31',
            Service => 'AWSECommerceService',
            id      => $ENV{'AWS_ACCESS_KEY_ID'},
            secret  => $ENV{'AWS_ACCESS_KEY_SECRET'},
        },
    );

    my $res = $service->get(
        {
            Operation     => 'ItemLookup',
            ItemId        => '0596000278',       # Larry's book
            ResponseGroup => 'ItemAttributes',
        }
    );
    my $ref = $res->parse_response();
    print "$ref->{Items}{Item}{ItemAttributes}{Title}\n";

# DESCRIPTION

WebService::Simple::AWS is Simple Interface to Amazon Web Service using WebService::Simple.
Add "Signature" and "Timestamp" parameters if accessing to API.
Currently this API supports only "Signature Version 2".

See ["product\_advertising.pl" in eg](https://metacpan.org/pod/eg#product_advertising.pl).

# AUTHOR

Yusuke Wada  `<yusuke@kamawada.com>`

# SEE ALSO

[WebSercie::Simple](https://metacpan.org/pod/WebSercie::Simple)

http://docs.amazonwebservices.com/AWSECommerceService/latest/DG/index.html?rest-signature.html

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
