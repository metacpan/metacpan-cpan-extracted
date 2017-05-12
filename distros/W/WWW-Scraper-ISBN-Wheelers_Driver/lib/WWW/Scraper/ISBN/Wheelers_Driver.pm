package WWW::Scraper::ISBN::Wheelers_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.14';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::Wheelers_Driver - Search drivers for the Wheelers' online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the Wheelers' online book catalog.

=cut

#--------------------------------------------------------------------------

###########################################################################
# Inheritence

use base qw(WWW::Scraper::ISBN::Driver);

###########################################################################
# Modules

use WWW::Mechanize;

###########################################################################
# Constants

use constant    SEARCH  => 'http://www.wheelers.co.nz/search/results/?query=';

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the
Wheelers server.

The returned page should be the correct catalog page for that ISBN. If not the
function returns zero and allows the next driver in the chain to have a go. If
a valid page is returned, the following fields are returned via the book hash:

  isbn          (now returns isbn13)
  isbn10
  isbn13
  ean13         (industry name)
  author
  title
  book_link
  image_link
  description
  pubdate
  publisher
  binding       (if known)
  pages         (if known)
  weight        (if known) (in grammes)
  width         (if known) (in millimetres)
  height        (if known) (in millimetres)

The book_link and image_link refer back to the Wheelers website.

=back

=cut

sub search {
    my $self = shift;
    my $isbn = shift;
    $self->found(0);
    $self->book(undef);

    my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );

    eval { $mech->get( SEARCH . $isbn ) };
    return $self->handler("Wheelers website appears to be unavailable.")
        if($@ || !$mech->success() || !$mech->content());

    # The Book page
    my $html = $mech->content();

    return $self->handler("Failed to find that book on Wheelers website.")
        if($html =~ m!Your search returned <b>0 results</b>!si);

#print STDERR "\n# html=[\n$html\n]\n";

    my $data;
    ($data->{image})                    = $html =~ m!href="(.*?/large/\d+/\d+.jpg)!i;
    ($data->{thumb})                    = $html =~ m!src="(.*?/small/\d+/\d+.jpg)!i;
    ($data->{author})                   = $html =~ m!<title>\s*.*?by ([^-]+)- ISBN:[^<]+</title><!i;
    ($data->{title})                    = $html =~ m!<a id="title" name="title"></a>\s*<h1>([^,<]+)</h1>!i;
    ($data->{publisher})                = $html =~ m!<th>Publisher</th>\s*<td><a[^>]+>([^<]+)</a></td>!i;
    ($data->{pubdate})                  = $html =~ m!<th>International Publication Date</th>\s*<td>([^<]+)</td>!i;
    ($data->{isbn13})                   = $html =~ m!<th>ISBN-13</th>\s*<td>(\d+)</td>!i;
    ($data->{isbn10})                   = $html =~ m!<th>ISBN-10</th>\s*<td>(\d+)</td>!i;
    ($data->{binding})                  = $html =~ m!<th>Format</th>\s*<td>([^<]+)<!s;
    ($data->{pages})                    = $html =~ m!<th>Number of Pages</th>\s*<td>([^<]+)</td>!s;
    ($data->{width},$data->{height})    = $html =~ m!<tr>\s*<th>Dimensions</th>\s*<td>Width:\s*([\d.]+)mm<br />Height:\s*([\d.]+)mm<br />(?:Spine:\s*([\d.]+)mm)?</td>\s*</tr>!s;
    ($data->{weight})                   = $html =~ m!<tr>\s*<th>Weight</th>\s*<td>(\d+)g</td>\s*</tr>!s;
    ($data->{description})              = $html =~ m!<h2>Description of this book</h2>\s*<p>([^<]+)</p>!i;

    $data->{binding} =~ s/,.*//;
    for(qw(image thumb)) {
        next unless(defined $data->{$_});
        next if($data->{$_} =~ m!^http://!);
        $data->{$_} =~ s!^//!http://!;
    }

    my $base = $mech->uri();
    $base =~ s!(http://[^/]+).*!$1!;

#use Data::Dumper;
#print STDERR "\n# " . Dumper($data);

    return $self->handler("Could not extract data from Wheelers result page.")
        unless(defined $data);

    # trim top and tail
    foreach (keys %$data) { next unless(defined $data->{$_});$data->{$_} =~ s/^\s+//;$data->{$_} =~ s/\s+$//; }

    my $bk = {
        'ean13'         => $data->{isbn13},
        'isbn13'        => $data->{isbn13},
        'isbn10'        => $data->{isbn10},
        'isbn'          => $data->{isbn13},
        'author'        => $data->{author},
        'title'         => $data->{title},
        'book_link'     => $mech->uri(),
        'image_link'    => $data->{image},
        'thumb_link'    => $data->{thumb},
        'description'   => $data->{description},
        'pubdate'       => $data->{pubdate},
        'publisher'     => $data->{publisher},
        'binding'       => $data->{binding},
        'pages'         => $data->{pages},
        'weight'        => $data->{weight},
        'width'         => $data->{width},
        'height'        => $data->{height},
        'html'          => $html
    };

#use Data::Dumper;
#print STDERR "\n# book=".Dumper($bk);

    $self->book($bk);
    $self->found(1);
    return $self->book;
}

1;
__END__

=head1 REQUIRES

Requires the following modules be installed:

L<WWW::Scraper::ISBN::Driver>,
L<WWW::Mechanize>

=head1 SEE ALSO

L<WWW::Scraper::ISBN>,
L<WWW::Scraper::ISBN::Record>,
L<WWW::Scraper::ISBN::Driver>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-Wheelers_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2010-2014 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
