package WWW::Scraper::ISBN::AmazonDE_Driver;

use warnings;
use strict;

use WWW::Scraper::ISBN::Driver;
use base qw(WWW::Scraper::ISBN::Driver);
use WWW::Mechanize;
use Web::Scraper;

use constant    AMAZON => 'http://www.amazon.de/';
use constant    SEARCH => 'http://www.amazon.de/';
use constant    DIRECT => 'http://www.amazon.de/gp/product/';

our $DEBUG = $ENV{ISBN_DRIVER_DEBUG};

# ABSTRACT: [DEPRECATED] Search driver for the (DE) Amazon online catalog.

our $VERSION = '0.28';


sub search {
    my ($self,$isbn) = @_;
    
    $self->found(0);
    $self->book(undef);

    my $mechanize = WWW::Mechanize->new();
    $mechanize->agent_alias( 'Linux Mozilla' );

#    $mechanize->get( SEARCH );
#    return    $self->handler('Error loading amazon.de form web page (unreachable?)')
#        unless($mechanize->success());
#
    my ($index,$input) = (0,0);

#    $mechanize->form_name('site-search')
#        or return $self->handler('Error parsing amazon.de form');

#    my $keyword ='search-alias=stripbooks';
#    $mechanize->set_fields( 
#        'field-keywords' => $isbn, 
#        'url'            => $keyword 
#    );
#    $mechanize->submit();

#    return    $self->handler('Error about form submission (form changed?)') 
#        unless($mechanize->success());

    (my $norm_isbn = $isbn) =~ s/[^0-9]//g;
    my $url = DIRECT . $norm_isbn;
    $mechanize->get( $url );

    return $self->handler( "No success when trying to get $url" )
        unless $mechanize->success;

    my $content = $mechanize->content();

    #$DEBUG and warn $content;
    
    my $scraper = scraper {
        process "title"                    , title       => 'TEXT';
        process "meta[name=\"description\"]" , content     => '@content';
        process 'script'                   , 'scripts[]' => sub { 
                my $script = join '', @{$_->content_array_ref};
                $script =~ /registerImage\("original_image"/ ? $script : ();
            };
    };
    
    my $sresult = $scraper->scrape( $content );
    
    my ($thumb,$image) = $sresult->{scripts}->[0] =~ /original_image","([^"]+)"\s*,\s*"<a \s href="\+'"'\+"([^"]*)"/;
    my ($pub) = $content =~ m{<li><b>Verlag:</b>\s*(.*?)</li>}msx;

    my $data = {
        content    => $sresult->{content},
        thumb_link => $thumb,
        image_link => $image,
        published  => $pub,
        title      => $sresult->{title},
    };

    return $self->handler("Could not extract data from amazon.de result page.")
        unless(defined $data);

    # trim top and tail
    foreach (keys %$data) { 
        next unless defined $data->{$_};
        $data->{$_} =~ s/^\s+//;
        $data->{$_} =~ s/\s+$//;
    }

#    ($data->{title},$data->{author}) = 
#        ($data->{content} =~ 
#                  /
#                  Amazon.de\s*:\s*
#                  (.+?)
#                  \s*:\s*([^:]+)\s*:
#                  /x);
#                  #\s*(?:(?:English\sBooks?)|Bücher|B&amp;uuml;cher|B&uuml;cher).*
#    #$data->{title} =~ s!\(.*?\)$!!;

     my @tmp_info = map{ s{\A\s*}{}; $_ }split /:/, $data->{content};
     @{ $data }{ qw/title author/ } = @tmp_info[0,-2];

     if ( $data->{author} =~ /\A\d+/ ) {
         my ($index) = grep{ $tmp_info[$_] eq $data->{author} } reverse ( 0 .. $#tmp_info );
         $data->{author} = $tmp_info[$index-1];
     }

     #my @tmp_info = split /:/, $data->{content};
     #@{ $data }{ qw/title author/ } = map{ s/^\s*//; $_ }@tmp_info[0,-3];

    ($data->{publisher},$data->{pubdate}) = 
        ($data->{published} =~ /\s*(.*?)(?:;.*?)?\s+\(([^)]*)/);

    my $bk = {
        'isbn'        => $isbn,
        'author'      => $data->{author},
        'title'       => $data->{title},
        'image_link'  => $data->{image_link},
        'thumb_link'  => $data->{thumb_link},
        'publisher'   => $data->{publisher},
        'pubdate'     => $data->{pubdate},
        'book_link'   => $mechanize->uri()
    };
    
    $self->book($bk);
    $self->found(1);
    return $self->book;
}


1; # End of WWW::Scraper::ISBN::AmazonDE_Driver

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Scraper::ISBN::AmazonDE_Driver - [DEPRECATED] Search driver for the (DE) Amazon online catalog.

=head1 VERSION

version 0.28

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the (DE) Amazon online catalog.
This module is a mere paste and translation of L<WWW::Scraper::ISBN::AmazonFR_Driver>.

=head1 WHY DEPRECATED?

I don't use the module anymore and Amazon seems to change the HTML every now
and then. That makes it hard to maintain the module.

=head1 ADOPT THE MODULE

If you're interested to adopt the module, then go ahead. I will give (co-)maintainership
to the L<ADOPTME|https://metacpan.org/author/ADOPTME> user. I can transfer the
L<Github repository|https://github.com/reneeb/WWW-Scraper-ISBN-AmazonDE_Driver> to you,
if you send me a mail with your Github-ID.

=head1 FUNCTIONS

=head2 search

=head1 AUTHOR

Renee Baecker, C<< <module at renee-baecker.de> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-scraper-isbn-amazonde_driver at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW::Scraper::ISBN::AmazonDE_Driver>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Scraper::ISBN::AmazonDE_Driver

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW::Scraper::ISBN::AmazonDE_Driver>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW::Scraper::ISBN::AmazonDE_Driver>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW::Scraper::ISBN::AmazonDE_Driver>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Scraper-ISBN-AmazonDE_Driver>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 - 2011 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of Artistic License 2.0.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
