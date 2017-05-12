[![Build Status](https://travis-ci.org/binary-com/perl-WebService-MyAffiliates.svg?branch=master)](https://travis-ci.org/binary-com/perl-WebService-MyAffiliates)
[![codecov](https://codecov.io/gh/binary-com/perl-WebService-MyAffiliates/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-WebService-MyAffiliates)
[![Gitter chat](https://badges.gitter.im/binary-com/perl-WebService-MyAffiliates.png)](https://gitter.im/binary-com/perl-WebService-MyAffiliates)

# NAME

WebService::MyAffiliates - Interface to myaffiliates.com API

# SYNOPSIS

    use WebService::MyAffiliates;

    my $aff = WebService::MyAffiliates->new(
        user => 'user',
        pass => 'pass',
        host => 'admin.example.com'
    );

    my $token_info = $aff->decode_token($token) or die $aff->errstr;

# DESCRIPTION

WebService::MyAffiliates is Perl interface to [http://www.myaffiliates.com/xmlapi](http://www.myaffiliates.com/xmlapi)

It's incompleted. patches are welcome with pull-requests of [https://github.com/binary-com/perl-WebService-MyAffiliates](https://github.com/binary-com/perl-WebService-MyAffiliates)

# METHODS

## new

- user

    required. the Basic Auth username.

- pass

    required. the Basic Auth password.

- host

    required. the Basic Auth url/host.

## get\_users

Feed 1: Users Feed

[https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+1%3A+Users+Feed](https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+1%3A+Users+Feed)

    my $user_info = $aff->get_users(USER_ID => $id);
    my $user_info = $aff->get_users(STATUS => 'new');
    my $user_info = $aff->get_users(VARIABLE_NAME => 'n', VARIABLE_VALUE => 'v');

## get\_user

    my $user_info = $aff->get_user($id); # { ID => ... }

call get\_users(USER\_ID => $id) with the top evel USER key removed.

## decode\_token

Feed 4: Decode Token

[https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+4%3A+Decode+Token](https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+4%3A+Decode+Token)

    my $token_info = $aff->decode_token($token); # $token_info is a HASH which contains TOKEN key
    my $token_info = $aff->decode_token($tokenA, $tokenB);

## encode\_token

Feed 5: Encode Token

[https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+5%3A+Encode+Token](https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+5%3A+Encode+Token)

    my $token_info = $aff->encode_token(
        USER_ID  => 1,
        SETUP_ID => 7
    );

## get\_user\_transactions

Feed 6: User Transactions Feed

[https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+6%3A+User+Transactions+Feed](https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+6%3A+User+Transactions+Feed)

    my $transactions = $aff->get_user_transactions(
        'USER_ID'   => $id,
        'FROM_DATE' => '2011-12-31',
        'TO_DATE'   => '2012-01-31',
    );

# AUTHOR

Binary.com <fayland@binary.com>

# COPYRIGHT

Copyright 2014- Binary.com

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
