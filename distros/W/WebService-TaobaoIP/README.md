WebService::TaobaoIP
--------------------

Perl interface to Taobao IP API.

Usage
-----

    use WebService::TaobaoIP;

    my $ti = WebService::TaobaoIP->new('123.123.123.123');

    print $ti->ip;
    print $ti->country;
    print $ti->area;
    print $ti->region;
    print $ti->city;
    print $ti->isp;
