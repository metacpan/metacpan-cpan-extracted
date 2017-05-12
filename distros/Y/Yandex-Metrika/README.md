# NAME

Yandex::Metrika - It's module to get access to Yandex.Metrika API via OAuth

# SYNOPSIS

    use Yandex::Metrika;

    my $metrika = Yandex::Metrika->new( token => '*******************************', counter => 1234567 );

    $metrika->set_per_page( 20 ); # optional, default 100
    $metrika->set_pretty( 1 ); # optional, default 1

    $metrika->user_vars({ date1 => '20150501', date2 => '20150501', table_mode => 'tree', group => 'all' });

    # if answer contains {links}->{next} you can load next page by

    $metrika->user_vars({ next => 1});
    
    # show next link

    say $metrika->next_url;

# DESCRIPTION

Yandex::Metrika is using Yandex::OAuth::Client as base class to get access.
API methods are mapped to object methods.
See api docs for parameters and response formats at https://tech.yandex.ru/metrika/doc/ref/stat/api-stat-method-docpage/

Looking for contributors for this and other Yandex.APIs

# METHODS

- **traffic()**
- **conversion()**
- **sites()**
- **search\_engines()**
- **phrases()**
- **social\_networks()**
- **marketing()**
- **direct\_summary()**
- **direct\_platforms\_all()**
- **direct\_platform\_types()**
- **direct\_regions()**
- **tags()**
- **geo()**
- **interest()**
- **demography\_age()**
- **demography\_gender()**
- **demography\_structure()**
- **deepness\_time()**
- **deepness\_depth()**
- **hourly()**
- **popular()**
- **entrance()**
- **exit()**
- **titles()**
- **url\_param()**
- **share\_services()**
- **share\_titles()**
- **links()**
- **downloads()**
- **user\_vars()**
- **ecommerce()**
- **browsers()**
- **os()**
- **display\_all()**
- **display\_groups()**
- **mobile\_devices()**
- **mobile\_phones()**
- **flash()**
- **silverlight()**
- **java()**
- **cookies()**
- **javascript()**
- **load()**
- **load\_minutely\_24()**
- **load\_minutely\_all()**
- **robots\_all()**
- **robot\_types()**

# LICENSE

Copyright (C) Andrey Kuzmin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Andrey Kuzmin <chipsoid@cpan.org>
