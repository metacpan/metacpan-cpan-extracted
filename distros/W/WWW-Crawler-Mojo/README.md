# WWW-Crawler-Mojo

WWW::Crawler::Mojo is a web crawling framework written in Perl on top of mojo toolkit, allowing you to write your own crawler rapidly. 

***This software is considered to be alpha quality and isn't recommended for regular usage.***

## Features

* Easy to rule your crawler.
* Allows to use [Mojo::URL] for URL manipulations, [Mojo::Message::Response] for response manipulation and [Mojo::DOM] for DOM inspection.
* Internally uses [Mojo::UserAgent] which is a full featured non-blocking I/O HTTP and WebSocket user agent, with IPv6, TLS, SNI, IDNA, HTTP/SOCKS5 proxy, Comet (long polling), keep-alive, connection pooling, timeout, cookie, multipart, gzip compression and multiple event loop.
* Throttle the connection with max connection and max connection per host options.
* Depth detection.
* Tracks 301 HTTP redirects.
* Detects network errors and retry with your own rules.
* Shuffles queue periodically if indicated.
* Crawls beyond basic authentication.
* Crawls even error documents.
* Form submitting emulation.

[Mojo::URL]:http://mojolicio.us/perldoc/Mojo/URL
[Mojo::DOM]:http://mojolicio.us/perldoc/Mojo/DOM
[Mojo::Message::Response]:http://mojolicio.us/perldoc/Mojo/Message/Response
[Mojo::UserAgent]:http://mojolicio.us/perldoc/Mojo/UserAgent

## Requirements

* Perl 5.16 or higher
* Mojolicious 8.12 or higher

## Installation

    $ curl -L cpanmin.us | perl - -n WWW::Crawler::Mojo

## Synopsis

    use WWW::Crawler::Mojo;
    
    my $bot = WWW::Crawler::Mojo->new;
    
    $bot->on(res => sub {
        my ($bot, $scrape, $job, $res) = @_;
        
        for my $child_job ($scrape->($css_selector)) {
            if (...) {
                $bot->enqueue($child_job);
            }
        }
    });
    
    $bot->enqueue('http://example.com/');
    $bot->crawl;

## Documentation

* [WWW::Crawler::Mojo](http://search.cpan.org/perldoc?WWW%3A%3ACrawler%3A%3AMojo)
* [WWW::Crawler::Mojo::Job](http://search.cpan.org/perldoc?WWW%3A%3ACrawler%3A%3AMojo%3A%3AJob)
* [WWW::Crawler::Mojo::UserAgent](http://search.cpan.org/perldoc?WWW%3A%3ACrawler%3A%3AMojo%3A%3AUserAgent)
* [WWW::Crawler::Mojo::Queue](http://search.cpan.org/perldoc?WWW%3A%3ACrawler%3A%3AMojo%3A%3AQueue)
* [WWW::Crawler::Mojo::Queue::Memory](http://search.cpan.org/perldoc?WWW%3A%3ACrawler%3A%3AMojo%3A%3AQueue%3A%3AMemory)
* [WWW::Crawler::Mojo::ScraperUtil](http://search.cpan.org/perldoc?WWW%3A%3ACrawler%3A%3AMojo%3A%3AScraperUtil)

## Examples

Restricting scraping URLs by status code.

    $bot->on(res => sub {
        my ($bot, $scrape, $job, $res) = @_;
        return unless ($res->code == 200);
        $bot->enqueue($_) for $scrape->();
    });

Restricting scraping URLs by host.

    $bot->on(res => sub {
        my ($bot, $scrape, $job, $res) = @_;
        return unless if ($job->url->host eq 'example.com');
        $bot->enqueue($_) for $scrape->();
    });

Restrict following URLs by depth.

    $bot->on(res => sub {
        my ($bot, $scrape, $job, $res) = @_;
        
        for my $child_job ($scrape->()) {
            next unless ($child_job->depth < 5)
            $bot->enqueue($child_job);
        }
    });

Restrict following URLs by host.

    $bot->on(res => sub {
        my ($bot, $scrape, $job, $res) = @_;
        
        for my $child_job ($scrape->()) {
            $bot->enqueue($child_job) if $child_job->url->host eq 'example.com';
        }
    });

Excepting following URLs by path.

    $bot->on(res => sub {
        my ($bot, $scrape, $job, $res) = @_;
        
        for my $child_job ($scrape->()) {
            $bot->enqueue($child_job)
                                unless ($child_job->url->path =~ qr{^/foo/});
        }
    });

Crawl only preset URLs.

    $bot->on(res => sub {
        my ($bot, $scrape, $job, $res) = @_;
        # DO SOMETHING
    });
    
    $bot->enqueue(
        'http://example.com/1',
        'http://example.com/3',
        'http://example.com/5',
    );
    
    $bot->crawl;

Speed up.

    $bot->max_conn(5);
    $bot->max_conn_per_host(5);

Authentication. The user agent automatically reuses the credential for the host.

    $bot->enqueue('http://jamadam:password@example.com');

You can fulfill any prerequisites such as login form submittion so that a login session will be established with cookie or something which you don't have to worry about.

    my $bot = WWW::Crawler::Mojo->new;
    $bot->ua->post('http://example.com/admin/login', form => {
        username => 'jamadam',
        password => 'password',
    });
    $bot->enqueue('http://example.com/admin/');
    $bot->crawl

## Other examples

* [WWW-Flatten](https://github.com/jamadam/WWW-Flatten)
* See the scripts under the example directory.

## Broad crawling

Althogh the module is only well tested for "focused crawling" at this point,
you can also use it for endless crawling by taking special care of memory usage including;

* Restrict queue size by yourself.
* Replace redundant detecter code.

    $bot->queue->redundancy(sub {...});

## Copyright

Copyright (C) jamadam

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
