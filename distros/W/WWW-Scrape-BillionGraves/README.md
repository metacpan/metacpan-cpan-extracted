# NAME

WWW::Scrape::BillionGraves - Scrape the BillionGraves website

# VERSION

Version 0.02

# SYNOPSIS

    use WWW::Scrape::BillionGraves;

    my $bg = WWW::Scrape::BillionGraves->new({
        firstname => 'John',
        lastname => 'Smith',
        country => 'England',
        date_of_death => 1862
    });

    while(my $url = $bg->get_next_entry()) {
        print "$url\n";
    }
}

# SUBROUTINES/METHODS

## new

Creates a WWW::Scrape::BillionGraves object.

It takes two mandatory arguments firstname and lastname.

Also one of either date\_of\_birth and date\_of\_death must be given.

There are two optional arguments: middlename and host.

host is the domain of the site to search, the default is billiongraves.com.

## get\_next\_entry

Returns the next match as a URL to the BillionGraves page.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to `bug-www-scrape-billiongraves at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Scrape-BillionGraves](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Scrape-BillionGraves).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

[https://github.com/nigelhorne/gedcom](https://github.com/nigelhorne/gedcom)
[https://billiongraves.com](https://billiongraves.com)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Scrape::BillionGraves

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Scrape-BillionGraves](http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Scrape-BillionGraves)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/WWW-Scrape-BillionGraves](http://annocpan.org/dist/WWW-Scrape-BillionGraves)

- CPAN Ratings

    [http://cpanratings.perl.org/d/WWW-Scrape-BillionGraves](http://cpanratings.perl.org/d/WWW-Scrape-BillionGraves)

- Search CPAN

    [https://metacpan.org/release/WWW-Scrape-BillionGraves](https://metacpan.org/release/WWW-Scrape-BillionGraves)

# LICENSE AND COPYRIGHT

Copyright 2018 Nigel Horne.

This program is released under the following licence: GPL2
