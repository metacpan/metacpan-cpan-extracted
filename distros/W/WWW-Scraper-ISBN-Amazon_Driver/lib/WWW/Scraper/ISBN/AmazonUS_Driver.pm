package WWW::Scraper::ISBN::AmazonUS_Driver;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.41';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::AmazonUS_Driver - Search driver for Amazon.com

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the (US) Amazon online catalog.

=cut

#--------------------------------------------------------------------------

###########################################################################
# Inheritence

use base qw(WWW::Scraper::ISBN::Driver);

###########################################################################
# Modules

use WWW::Mechanize;
use JSON;

###########################################################################
# Variables

my $AMA_SEARCH = 'http://www.amazon.com/s/ref=nb_sb_noss?url=search-alias=us-stripbooks-tree&field-keywords=%s';
my $AMA_URL    = 'http://www.amazon.com/[^/]+/dp/[\dX]+/ref=sr_1_1.*?sr=1-1';
my $IN2MM = 0.0393700787;   # number of inches in a millimetre (mm)
my $LB2G  = 0.00220462;     # number of pounds (lbs) in a gram
my $OZ2G  = 0.035274;       # number of ounces (oz) in a gram

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the
Amazon (US) server.

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
  thumb_link
  image_link
  pubdate
  publisher
  binding       (if known)
  pages         (if known)
  weight        (if known) (in grams)
  width         (if known) (in millimetres)
  height        (if known) (in millimetres)
  depth         (if known) (in millimetres)

The book_link, thumb_link and image_link refer back to the Amazon (US) website.

=back

=cut

sub search {
    my $self = shift;
    my $isbn = shift;
    $self->found(0);
    $self->book(undef);

    # validate and convert into EAN13 format
    my $ean = $self->convert_to_ean13($isbn);
    return $self->handler("Invalid ISBN specified [$isbn]")
        if(!$ean || (length $isbn == 13 && $isbn ne $ean)
                 || (length $isbn == 10 && $isbn ne $self->convert_to_isbn10($ean)));

    my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );

    my $search = sprintf $AMA_SEARCH, $ean;

    eval { $mech->get( $search ) };
    return $self->handler("Amazon US website appears to be unavailable.")
        if($@ || !$mech->success() || !$mech->content());

    my $content = $mech->content();
    my ($link) = $content =~ m!($AMA_URL)!s;
    return $self->handler("Failed to find that book on Amazon US website.")
        unless($link);

    eval { $mech->get( $link ) };
    return $self->handler("Amazon US website appears to be unavailable.")
        if($@ || !$mech->success() || !$mech->content());

    return $self->_parse($mech);
}

sub _parse {
    my $self = shift;
    my $mech = shift;

    # The Book page
    my $html = $mech->content;
    my $data = {};

#print STDERR "\n# html=[$html]\n";

    my @patterns = (
        qr/<meta name="description" content="(.*?) \[(.*?)\] on Amazon.com/si,
        qr/<meta name="description" content="(.*?): (.*?): (\d+): Amazon.com: Books/si,
        qr/<meta name="description" content="(?:Amazon.com:)?\s*(.*?).\d+.:\s+([^:]+): Books/si,
        qr/<meta name="description" content="(?:Amazon.com: Books: )?\s*(.*?)(?:\s+by|,)\s+(.*)/si,
        qr/<meta name="description" content="(?:Amazon.com:)?\s*(.*?)(?:\s+by|,|:)\s+([^:]+): Books/si
    );

    for my $pattern (@patterns) {
        my ($title,$author) = $html =~ $pattern;
        $data->{title}  ||= $title;
        $data->{author} ||= $author;
#print STDERR "\n# title=[$data->{title}], author=[$data->{author}] pattern=[$pattern]\n";

        last    if($data->{title} && $data->{author});
    }

    ($data->{binding},$data->{pages})   = $html =~ m!<li><b>(Paperback|Hardcover):</b>\s*([\d.]+)\s*pages</li>!si;
    ($data->{published})                = $html =~ m!<li><b>Publisher:</b>\s*(.*?)</li>!si;
    ($data->{isbn10})                   = $html =~ m!<li><b>ISBN-10:</b>\s*(.*?)</li>!si;
    ($data->{isbn13})                   = $html =~ m!<li><b>ISBN-13:</b>\s*(.*?)</li>!si;
    ($data->{content})                  = $html =~ m!<meta name="description" content="([^"]+)"!si;

    @patterns = (
        qr!<h2>Book Description</h2>.*?<div id="postBodyPS"[^>]+>\s*<div[^>]*>\s*<p>\s*(.*?)\s*</p>\s*</div!si,
        qr!<h2>Book Description</h2>.*?<div id="postBodyPS"[^>]+>\s*<div[^>]*>\s*(.*?)\s*</div!si,
        qr!<h3 class="productDescriptionSource">(?:Product Description|From the Back Cover)</h3>\s*<div class="productDescriptionWrapper">\s*<p>([^<]+)!si,
        qr!<h3 class="productDescriptionSource">(?:Product Description|From the Back Cover)</h3>\s*<div class="productDescriptionWrapper">\s*(.*?)<div!si,
        qr!<div id="bookDescription_feature_div"[^>]+>\s*<script[^>]*>.*?</script>\s*<noscript>(.*?)</noscript>!si
    );

    for my $pattern (@patterns) {
        my ($desc) = $html =~ $pattern;
        $desc =~ s/\s+$//s   if($desc);
        $data->{description}  ||= $desc;

        last    if($data->{description});
    }

    for my $key (qw(description)) {
        next unless($data->{$key});
        $data->{$key} =~ s/<[^>]*>//gs;
    }

    # amazon use both ounces and pounds
    my $weight;
    ($data->{weight},$weight)                   = $html =~ m!<li><b>Shipping Weight:</b>\s*([\d.]+)\s*(ounces|pounds)!si;
    $data->{weight} = int($data->{weight} / $OZ2G)  if($data->{weight} && $weight eq 'ounces');
    $data->{weight} = int($data->{weight} / $LB2G)  if($data->{weight} && $weight eq 'pounds');

    # amazon change this regularly
    my @size                            = $html =~ m!<li><b>\s*Product Dimensions:\s*</b>\s*([\d.]+) x ([\d.]+) x ([\d.]+) (cm)\s*</li>!si;
    @size                               = $html =~ m!<li><b>\s*Product Dimensions:\s*</b>\s*([\d.]+) x ([\d.]+) x ([\d.]+) (inches)\s*</li>!si unless(@size);
    if(@size) {
        my $type = pop @size;
        ($data->{depth},$data->{width},$data->{height}) = sort @size;
        if($type eq 'cm') {
            $data->{$_}  = int($data->{$_} * 10)  for(qw( height width depth ));
        } elsif($type eq 'inches') {
            $data->{$_}  = int($data->{$_} / $IN2MM)  for(qw( height width depth ));
        }
    }

    # The images
    my ($json) = $html =~ /var colorImages = ([^;]+);/si;
    if($json) {
        my $code = decode_json($json);
        my @order = grep {$_} $code->{initial}[0]{thumb}, $code->{initial}[0]{landing}, @{$code->{initial}[0]{main}}, $code->{initial}[0]{large};
        $data->{thumb_link} = $order[0]     if(@order);
        $data->{image_link} = $order[-1]    if(@order);
    } else {
        ($data->{thumb_link}) = $html =~ m!imageGalleryData.*?thumbUrl":"([^"]+)"!;
        ($data->{image_link}) = $html =~ m!imageGalleryData.*?mainUrl":"([^"]+)"!;
    }

    ($data->{publisher},$data->{pubdate}) = ($data->{published} =~ /\s*(.*?)(?:;.*?)?\s+\((.*?)\)/) if($data->{published});
    $data->{isbn10} =~ s/[^\dX]+//g if($data->{isbn10});
    $data->{isbn13} =~ s/\D+//g     if($data->{isbn13});


    return $self->handler("Could not extract data from Amazon US result page.")
        unless(defined $data->{isbn13});

    # trim top and tail
    foreach (keys %$data) { next unless(defined $data->{$_});$data->{$_} =~ s/^\s+//;$data->{$_} =~ s/\s+$//; }

    my $bk = {
        'ean13'         => $data->{isbn13},
        'isbn13'        => $data->{isbn13},
        'isbn10'        => $data->{isbn10},
        'isbn'          => $data->{isbn13},
        'author'        => $data->{author},
        'title'         => $data->{title},
        'image_link'    => $data->{image_link},
        'thumb_link'    => $data->{thumb_link},
        'publisher'     => $data->{publisher},
        'pubdate'       => $data->{pubdate},
        'book_link'     => $mech->uri(),
        'content'       => $data->{content},
        'binding'       => $data->{binding},
        'pages'         => $data->{pages},
        'weight'        => $data->{weight},
        'width'         => $data->{width},
        'height'        => $data->{height},
        'depth'         => $data->{depth},
        'description'   => $data->{description},
        'html'          => $html
    };
    $self->book($bk);
    $self->found(1);
    return $self->book;
}

q{currently reading: 'Soul Music' by Terry Pratchett};

__END__

=head1 REQUIRES

Requires the following modules be installed:

L<WWW::Scraper::ISBN::Driver>,
L<WWW::Mechanize>,

=head1 SEE ALSO

L<WWW::Scraper::ISBN>,
L<WWW::Scraper::ISBN::Record>,
L<WWW::Scraper::ISBN::Driver>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-Amazon_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2004-2014 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
