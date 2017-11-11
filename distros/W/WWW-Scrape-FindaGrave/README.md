[![Linux Build Status](https://travis-ci.org/nigelhorne/WWW-Scrape-FindaGrave.svg?branch=master)](https://travis-ci.org/nigelhorne/WWW-Scrape-FindaGrave)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/ra6839k5wpno9xf0?svg=true)](https://ci.appveyor.com/project/nigelhorne/www-scrape-findagrave)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/WWW-Scrape-FindaGrave/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/WWW-Scrape-FindaGrave?branch=master)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/WWW-Scrape-FindaGrave/badge)](https://dependencyci.com/github/nigelhorne/WWW-Scrape-FindaGrave)

# WWW::Scrape::FindaGrave

Scrape the Find a Grave website

# VERSION

Version 0.05

# SYNOPSIS

    use HTTP::Cache::Transparent;  # be nice
    use WWW::Scrape::FindaGrave;

    HTTP::Cache::Transparent::init({
        BasePath => '/var/cache/findagrave'
    });
    my $f = WWW::Scrape::FindaGrave->new({
        firstname => 'John',
        lastname => 'Smith',
        country => 'England',
        date_of_death => 1862
    });

    while(my $url = $f->get_next_entry()) {
        print "$url\n";
    }
}

# SUBROUTINES/METHODS

## new

Creates a WWW::Scrape::FindaGrave object.

It takes two mandatory arguments firstname and lastname.

Also one of either date\_of\_birth and date\_of\_death must be given

There are three optional arguments: middlename, ua and mech.  Mech is a pointer
to an object such as [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize).  If not given it will be created.

ua is a pointer to an object that understands get and env\_proxy messages, such
as [LWP::UserAgent::Throttled](https://metacpan.org/pod/LWP::UserAgent::Throttled).

## get\_next\_entry

Returns the next match as a URL to the Find-A-Grave page.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to `bug-www-scrape-findagrave at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Scrape-FindaGrave](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Scrape-FindaGrave).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

[https://github.com/nigelhorne/gedgrave](https://github.com/nigelhorne/gedgrave)
[https://old.findagrave.com](https://old.findagrave.com)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Scrape::FindaGrave

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Scrape-FindaGrave](http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Scrape-FindaGrave)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/WWW-Scrape-FindaGrave](http://annocpan.org/dist/WWW-Scrape-FindaGrave)

- CPAN Ratings

    [http://cpanratings.perl.org/d/WWW-Scrape-FindaGrave](http://cpanratings.perl.org/d/WWW-Scrape-FindaGrave)

- Search CPAN

    [http://search.cpan.org/dist/WWW-Scrape-FindaGrave/](http://search.cpan.org/dist/WWW-Scrape-FindaGrave/)

# LICENSE AND COPYRIGHT

Copyright 2016-2017 Nigel Horne.

This program is released under the following licence: GPL
