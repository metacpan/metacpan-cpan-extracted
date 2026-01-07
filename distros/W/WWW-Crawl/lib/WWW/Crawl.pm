package WWW::Crawl;

use strict;
use warnings;

use HTTP::Tiny;
use URI;
use JSON::PP;
use Carp qw(croak);

our $VERSION = '0.3';
# $VERSION = eval $VERSION;

# TODO:
# 1  - Use HTML Parser instead of regexps
#    - we don't do this as it doesn't parse JS scripts and files
#

sub new {
    my $class = shift;
    my %attrs = @_;
    
    $attrs{'agent'} //= "Perl-WWW-Crawl-$VERSION";
    
    $attrs{'http'}    = HTTP::Tiny->new(
        'agent' => $attrs{'agent'},
    );
    
    return bless \%attrs, $class;
}
    
sub crawl {
    my ($self, $url, $callback) = @_;
    
    $url = "https://$url" if $url =~ /^www/;
    my $uri = URI->new($url);
    croak "WWW::Crawl: No valid URI" unless $uri;
    
    my (%links, %parsed);
    $links{$url} = 1;
    
    my $page;
    my $flag = 1;
    while (scalar keys %links and $flag) {
        my $url = (keys(%links))[0];
        delete $links{$url};
        
        next if $parsed{$url};
        $parsed{$url}++;
        
        my $resp = $self->_fetch_page($url);
        next if $resp->{'status'} == 404;
        if (!$resp->{'success'}) {
            croak "WWW::Crawl: HTTP Response " . $resp->{'status'} . " - " . $resp->{'reason'} . "\n" . $resp->{'content'};
        }

        $page = $resp->{'content'};
        
        while ($page =~ /href *?= *?("|')(.*?)('|")/gc) {
            my $link = URI->new($2)->abs($uri)->canonical;
            if ($link->scheme   =~ /^http/ and $link->authority eq $uri->authority) {
                my $address     = $link->as_string;
                while ($address =~ s/(\/|#)$//) {}
                $links{$address}++ unless $link->path =~ /\.(pdf|css|png|jpg|svg|webmanifest)/ or $address =~ /#/;
            }
        }
        # Find forms
        pos($page) = 0;
        while ($page =~ /<form .*?action *?= *?("|')(.*?) *('|")/gc) {
            my $link = URI->new($2)->abs($uri)->canonical;
            if ($link->scheme =~ /^http/ and $link->authority eq $uri->authority) {
                my $address   = $link->as_string;
                $links{$address}++ ;
            }
        }
        # Find external JS files
        pos($page) = 0;
        while ($page =~ /<script .*?src *?= *?("|')(.*?) *('|")/gc) {
            my $link = URI->new($2)->abs($uri)->canonical;
            if ($link->scheme =~ /^http/ and $link->authority eq $uri->authority) {
                my $address   = $link->as_string;
                my $timestamp = $self->{'timestamp'};
                $timestamp    = '' unless $timestamp;
                $address      =~ s/(\?|\&)$timestamp=.*(\?|\&|$)//;
                $links{$address}++;
            }
        }
        # Find JS window.open links
        pos($page) = 0;
        while ($page =~ /(window|document).open\( *("|')(.*?)('|")/gc) {
            my $link = URI->new($3)->abs($uri)->canonical;
            if ($link->scheme   =~ /^http/ and $link->authority eq $uri->authority) {
                my $address     = $link->as_string;
                while ($address =~ s/(\/|#)$//) {}
                $links{$address}++ unless $link->path =~ /\.(pdf|css|png|jpg|svg)/;
            }
        }
        
        &$callback($url) if $callback;
        $flag = 0 if $self->{'nolinks'};
    }
    
    return keys %links if $self->{'nolinks'};
    return keys %parsed;
}

sub _fetch_page {
    my ($self, $url) = @_;

    return $self->{'http'}->request('GET', $url);
}

1;


=head1 NAME

WWW::Crawl - A simple web crawler for extracting links and more from web pages

=head1 VERSION

This documentation refers to WWW::Crawl version 0.2.

=head1 SYNOPSIS

    use WWW::Crawl;

    my $crawler = WWW::Crawl->new();
    
    my $url = 'https://example.com';
    
    my @visited = $crawler->crawl($url, \&process_page);

    sub process_page {
        my $url = shift;
        print "Visited: $url\n";
        # Your processing logic here
    }

=head1 DESCRIPTION

The C<WWW::Crawl> module provides a simple web crawling utility for extracting links and other resources from web pages within a single domain. It can be used to recursively explore a website and retrieve URLs, including those found in HTML href attributes, form actions, external JavaScript files, and JavaScript window.open links.

C<WWW::Crawl> will not stray outside the supplied domain.

=head1 CONSTRUCTOR

=head2 new(%options)

Creates a new C<WWW::Crawl> object. You can optionally provide the following options as key-value pairs:

=over 4

=item *

C<agent>: The user agent string to use for HTTP requests. Defaults to "Perl-WWW-Crawl-VERSION" where VERSION is the module version.

C<timestamp>: If a timestamp is added to external JavaScript files to ensure the latest version is loaded by the browser, this option prevents multiple copied of the same file being indexed by ignoring the timestamp query parameter.

C<nolinks>: Don't follow links found in the starting page.  This option is provided for testing and prevents C<WWW::Crawl> following the links it finds.  It also affects the return value of the L<crawl|WWW::Crawl#crawl($url,-[$callback])> method.

=back

=head1 METHODS

=head2 crawl($url, [$callback])

Starts crawling the web starting from the given URL. The C<$url> parameter specifies the starting URL.

The optional C<$callback> parameter is a reference to a subroutine that will be called for each visited page. It receives the URL of the visited page as an argument.

The C<crawl> method will explore the provided URL and its linked resources. It will also follow links found in form actions, external JavaScript files, and JavaScript window.open links. The crawling process continues until no more unvisited links are found.

In exploring the website, C<crawl> will ignore links to the following types of file C<.pdf>, C<.css>, C<.png>, C<.jpg>, C<.svg> and C<.webmanifest>

Returns an array of URLs that were parsed during the crawl. Unless the C<nolinks> option is passed to L<new|WWW::Crawl#new(%options)>, then it returns an array of links found on the intial page.

=head1 AUTHOR

Ian Boddison, C<< <bod at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-crawl at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Crawl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Crawl


You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/IanBod/WWW-Crawl>

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Crawl>

=item * Search CPAN

L<https://metacpan.org/release/WWW-Crawl>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023-2026 by Ian Boddison.

This program is released under the following license:

  Perl


=cut

1; # End of WWW::Crawl


