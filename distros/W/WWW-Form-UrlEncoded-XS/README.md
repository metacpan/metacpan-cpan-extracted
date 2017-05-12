[![Build Status](https://travis-ci.org/kazeburo/WWW-Form-UrlEncoded-XS.svg?branch=master)](https://travis-ci.org/kazeburo/WWW-Form-UrlEncoded-XS)
# NAME

WWW::Form::UrlEncoded::XS - XS implementation of parser and builder for application/x-www-form-urlencoded

# SYNOPSIS

    use WWW::Form::UrlEncoded::XS qw/parse_urlencoded build_urlencoded/;
    
    my $query_string = "foo=bar&baz=param";
    my @params = parse_urlencoded($query_string);
    # ('foo','bar','baz','param')
    
    my $query_string = build_urlencoded('foo','bar','baz','param');
    # "foo=bar&baz=param";

# DESCRIPTION

WWW::Form::UrlEncoded::XS provides application/x-www-form-urlencoded parser and builder 
that is implemented by XS. see [WWW::Form::UrlEncoded](https://metacpan.org/pod/WWW::Form::UrlEncoded)'s document.

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>
