# NAME

[![Build Status](https://travis-ci.org/binary-com/perl-WWW-OneAll.svg?branch=master)](https://travis-ci.org/binary-com/perl-WWW-OneAll)
[![codecov](https://codecov.io/gh/binary-com/perl-WWW-OneAll/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-WWW-OneAll)

WWW::OneAll - OneAll API

# SYNOPSIS

    use WWW::OneAll;

    my $oneall = WWW::OneAll->new(
        subdomain   => 'your_subdomain',
        public_key  => 'pubkey12-629b-4020-83fe-38af46e27b06',
        private_key => 'prikey12-a7ec-48f5-b9bc-737eb74146a4',
    );
    my $data = $oneall->connection($connection_token) or die $oneall->errstr;

# DESCRIPTION

OneAll provides web-applications with a unified API for 30+ social networks.

# METHODS

## new

- subdomain
- public\_key
- private\_key

    all required. get from API Settings [https://app.oneall.com/applications/application/settings/api/](https://app.oneall.com/applications/application/settings/api/)

## connections

## connection

Connection API [http://docs.oneall.com/api/resources/connections/](http://docs.oneall.com/api/resources/connections/)

## request

    my $res = $oneall->request('GET', "/connections");

native method to create your own API request.

# AUTHOR

Fayland Lam <fayland@gmail.com>

# COPYRIGHT

Copyright 2016- Binary.com

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
