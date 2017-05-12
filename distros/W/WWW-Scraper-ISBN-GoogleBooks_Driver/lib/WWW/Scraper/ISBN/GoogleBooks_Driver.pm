package WWW::Scraper::ISBN::GoogleBooks_Driver;

use strict;
use warnings;
use utf8;

use vars qw($VERSION @ISA);
$VERSION = '0.30';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::GoogleBooks_Driver - Search driver for Google Books online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from Google Books online book catalog

=cut

#--------------------------------------------------------------------------

###########################################################################
# Inheritence

use base qw(WWW::Scraper::ISBN::Driver);

###########################################################################
# Modules

use HTML::Entities;
use JSON;
use WWW::Mechanize;

###########################################################################
# Constants & Variables

my $DOMAIN = 'http://books.google.com';

use constant	SEARCH	=> '/books?jscmd=viewapi&callback=bookdata&bibkeys=ISBN:';
use constant	LB2G    => 453.59237;   # number of grams in a pound (lb)
use constant	OZ2G    => 28.3495231;  # number of grams in an ounce (oz)
use constant	IN2MM   => 25.4;        # number of inches in a millimetre (mm)

my %LANG = (
    'cz' => { Publisher => 'Vydavatel',     Author => 'Autor',          Title => 'Titul',   Length => [ 'Délka', qr/\QD\x{e9}lka\E/, 'D&eacute;lka' ],
                                                                                                                        Pages => [ 'Počet stran:', qr/\QPo\x{10d}et stran:\E/, 'Po&#x10D;et stran:' ] },
    'de' => { Publisher => 'Verlag',        Author => 'Autor',          Title => 'Titel',   Length => qr{L.+nge},       Pages => 'Seiten' },
    'en' => { Publisher => 'Publisher',     Author => 'Author',         Title => 'Title',   Length => 'Length',         Pages => 'pages'  },
    'es' => { Publisher => 'Editor',        Author => 'Autor',          Title => 'Título',  Length => [ 'N.º de páginas', 'N.&ordm; de p&aacute;ginas' ], 
                                                                                                                        Pages => [ 'páginas', 'p&aacute;ginas' ]  },
    'fr' => { Publisher => '.+diteur',      Author => 'Auteur',         Title => 'Titre',   Length => 'Longueur',       Pages => 'pages'  },
    'fi' => { Publisher => 'Kustantaja',    Author => 'Kirjoittaja',    Title => 'Otsikko', Length => 'Pituus',         Pages => 'sivua'  },
    'nl' => { Publisher => 'Uitgever',      Author => 'Auteur',         Title => 'Titel',   Length => 'Lengte',         Pages => [ q{pagina's}, 'pagina&#39;s' ] },
    'md' => { Publisher => 'Editor',        Author => 'Autor',          Title => 'Titlu',   Length => 'Lungime',        Pages => 'pagini'  },
    'ru' => { Publisher => ['Издатель', qr/\Q\x{418}\x{437}\x{434}\x{430}\x{442}\x{435}\x{43b}\x{44c}\E/, '&#x418;&#x437;&#x434;&#x430;&#x442;&#x435;&#x43B;&#x44C;', '&ETH;&#152;&ETH;&middot;&ETH;&acute;&ETH;&deg;&Ntilde;&#130;&ETH;&micro;&ETH;&raquo;&Ntilde;&#140;' ],
                                            Author => 'Автор',          Title => 'Название',
                                                                                            Length => [ 'Количество страниц', qr/\Q\x{41a}\x{43e}\x{43b}\x{438}\x{447}\x{435}\x{441}\x{442}\x{432}\x{43e} \x{441}\x{442}\x{440}\x{430}\x{43d}\x{438}\x{446}/, '&#x41A;&#x43E;&#x43B;&#x438;&#x447;&#x435;&#x441;&#x442;&#x432;&#x43E; &#x441;&#x442;&#x440;&#x430;&#x43D;&#x438;&#x446;', '&ETH;&#154;&ETH;&frac34;&ETH;&raquo;&ETH;&cedil;&Ntilde;&#135;&ETH;&micro;&Ntilde;&#129;&Ntilde;&#130;&ETH;&sup2;&ETH;&frac34; &Ntilde;&#129;&Ntilde;&#130;&Ntilde;&#128;&ETH;&deg;&ETH;&frac12;&ETH;&cedil;&Ntilde;&#134;' ],
                                                                                                                        Pages => [ 'Всего страниц:', qr/\Q\x{412}\x{441}\x{435}\x{433}\x{43e} \x{441}\x{442}\x{440}\x{430}\x{43d}\x{438}\x{446}:/, '&#x412;&#x441;&#x435;&#x433;&#x43E; &#x441;&#x442;&#x440;&#x430;&#x43D;&#x438;&#x446;:', '&ETH;&#146;&Ntilde;&#129;&ETH;&micro;&ETH;&sup3;&ETH;&frac34; &Ntilde;&#129;&Ntilde;&#130;&Ntilde;&#128;&ETH;&deg;&ETH;&frac12;&ETH;&cedil;&Ntilde;&#134;', '&ETH;&#146;&Ntilde;&#129;&ETH;&micro;&ETH;&sup3;&ETH;&frac34; &Ntilde;&#129;&Ntilde;&#130;&Ntilde;&#128;&ETH;&deg;&ETH;&frac12;&ETH;&cedil;&Ntilde;&#134;:' ] },
    'iw' => { Publisher => [ '\x{5d4}\x{5d5}\x{5e6}\x{5d0}\x{5d4}', '&#x5D4;&#x5D5;&#x5E6;&#x5D0;&#x5D4;' ],
                                            Author => 'Author',         Title => 'Title',   Length => [ qr/\Q\x{5d0}\x{5d5}\x{5e8}\x{5da}\E/, '××•×¨×š', '\x{5d0}\x{5d5}\x{5e8}\x{5da}', '&#x5D0;&#x5D5;&#x5E8;&#x5DA;' ],
                                                                                                                        Pages => [ qr/\Q\x{5e2}\x{5de}\x{5d5}\x{5d3}\x{5d9}\x{5dd}\E/, '×¢×ž×•×“×™×', '\x{5e2}\x{5de}\x{5d5}\x{5d3}\x{5d9}\x{5dd}', '&#x5E2;&#x5DE;&#x5D5;&#x5D3;&#x5D9;&#x5DD;' ]  }
);

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search>

Creates a query string, then passes the appropriate form fields to the
GoogleBooks server.

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
  pubdate
  publisher
  description   (if available)
  pages         (if known)

The book_link and image_link refer back to the GoogleBooks website.

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
    my $data;
	$self->found(0);
	$self->book(undef);

    # validate and convert into EAN13 format
    my $ean = $self->convert_to_ean13($isbn);
    return $self->handler("Invalid ISBN specified")
        unless($ean);

	my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );

    my $search = ($ENV{GOOGLE_DOMAIN} || $DOMAIN) . SEARCH . $ean;
    eval { $mech->get( $search ) };
    return $self->handler("GoogleBooks website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

    my $json = $mech->content();

    return $self->handler("Failed to find that book on GoogleBooks website.")
	    if($json eq 'bookdata({});');

    $json =~ s/^bookdata\(//;
    $json =~ s/\);$//;

    my $code = decode_json($json);
#use Data::Dumper;
#print STDERR "\n# code=".Dumper($code);

    return $self->handler("Failed to find that book on GoogleBooks website.")
	    unless($code->{'ISBN:'.$ean} || $code->{'ISBN:'.$isbn});

    $data->{url}   = $code->{'ISBN:'.$ean }{info_url};
    $data->{url} ||= $code->{'ISBN:'.$isbn}{info_url};

    return $self->handler("Failed to find that book on GoogleBooks website.")
	    unless($data->{url});

    eval { $mech->get( $data->{url} ) };
    return $self->handler("GoogleBooks website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

	# The Book page
    #my $html = $mech->content();
    my $html = encode_entities($mech->content(),'^\n\x20-\x25\x27-\x7e');
    $html =~ s/\&amp;#39;/&#39;/sig;
    $html =~ s/\\x\(([a-z\d]+)\)/\&#$1;/sig;
    $html =~ s/&#55;/7/sig;

	return $self->handler("Failed to find that book on GoogleBooks website. [$isbn]")
		if($html =~ m!Sorry, we couldn't find any matches for!si);

#use Data::Dumper;
#print STDERR "\n# " . Dumper($data);
#print STDERR "\n# html=[$html]\n";

    $data->{url} = $mech->uri();
    my ($ccTLD) = $data->{url} =~ m{^http://[.\w]+\.google\.(\w\w)\b};

    my $lang = 'en';                                                                # English (default)
    $lang = 'de'    if($data->{url} =~ m{^http://[.\w]+\.google\.(de|ch|at)\b});    # German
    $lang = 'iw'    if($data->{url} =~ m{^http://[.\w]+\.google\.co\.il\b});        # Hebrew
    $lang = $ccTLD  if($LANG{$ccTLD});                                              # we have a ccTLD translation

	return $self->handler("Language '".uc $lang."'not currently supported, patches welcome.")
		if($lang =~ m!xx!);

    _match( $html, $data, $lang );

    # remove HTML tags
    for(qw(author)) {
        next unless(defined $data->{$_});
        $data->{$_} =~ s!<[^>]+>!!g;
    }

	# trim top and tail
	for(keys %$data) { next unless(defined $data->{$_});$data->{$_} =~ s/^\s+//;$data->{$_} =~ s/\s+$//; }

    # .com (and possibly others) don't always use Google's own CDN
    if($data->{image} =~ m!^/!) {
        my $domain = $mech->uri();
        $domain = s!^(http://[^/]+).*$!$1!;
        $data->{image} = $domain . $data->{image};
        $data->{thumb} = $data->{image};
    }

    my $url = $mech->uri();

	my $bk = {
		'ean13'		    => $data->{isbn13},
		'isbn13'		=> $data->{isbn13},
		'isbn10'		=> $data->{isbn10},
		'isbn'			=> $data->{isbn13},
		'author'		=> $data->{author},
		'title'			=> $data->{title},
		'book_link'		=> "$url",
		'image_link'	=> $data->{image},
		'thumb_link'	=> $data->{thumb},
		'pubdate'		=> $data->{pubdate},
		'publisher'		=> $data->{publisher},
		'description'   => $data->{description},
		'pages'		    => $data->{pages},
        'html'          => $html
	};

#use Data::Dumper;
#print STDERR "\n# book=".Dumper($bk);

    $self->book($bk);
	$self->found(1);
	return $self->book;
}

=head2 Private Methods

=over 4

=item C<_match>

Pattern matches for book page.

=back

=cut

sub _match {
    my ($html, $data, $lang) = @_;
    my ($publisher);

#print "\n# lang=$lang\n";

    # Some pages can present publisher text in multiple styles
    my @pubs = ref($LANG{$lang}->{Publisher}) eq 'ARRAY' ? @{$LANG{$lang}->{Publisher}} : ($LANG{$lang}->{Publisher});
    for my $pub (@pubs) {
        ($publisher) = $html =~ m!<td class="metadata_label">(?:<span[^>]*>)?$pub(?:</span>)?</td><td class="metadata_value">(?:<span[^>]*>)?([^<]+)(?:</span>)?</td>!si;
        last if($publisher);
    }
    if($publisher) {
        my @publist         = split(qr/\s*,\s*/,$publisher);
        $data->{publisher}  = $publist[0];
        $data->{pubdate}    = $publist[-1];
    }

    # Some pages can present length/pages text in multiple styles
    my @lengths = ref($LANG{$lang}->{Length}) eq 'ARRAY' ? @{$LANG{$lang}->{Length}} : ($LANG{$lang}->{Length});
    my @pages   = ref($LANG{$lang}->{Pages})  eq 'ARRAY' ? @{$LANG{$lang}->{Pages}}  : ($LANG{$lang}->{Pages});
    for my $length (@lengths) {
        for my $page (@pages) {
            ($data->{pages}) = $html =~ m!<td class="metadata_label">(?:<span[^>]*>)?$length(?:</span>)?</td><td class="metadata_value">(?:<span[^>]*>)?(\d+)\s*$page(?:</span>)?</td>!si;
            last    if($data->{pages});
            ($data->{pages}) = $html =~ m!<td class="metadata_label">(?:<span[^>]*>)?$length(?:</span>)?</td><td class="metadata_value">(?:<span[^>]*>)?\s*$page\s+(\d+)(?:</span>)?</td>!si;
            last    if($data->{pages});
        }
        last    if($data->{pages});
    }

    # get ISBN styles
    my ($isbns)         = $html =~ m!<td class="metadata_label">(?:<span[^>]*>)?ISBN(?:</span>)?</td><td class="metadata_value">(?:<span[^>]*>)?([^<]+)(?:</span>)?</td>!i;
    my (@isbns)         = split(qr/\s*,\s*/,$isbns);
    for my $value (@isbns) {
        $data->{isbn13} = $value    if(length $value == 13);
        $data->{isbn10} = $value    if(length $value == 10);
    }

#use Data::Dumper;
#print STDERR "\n# isbns=[$isbns]";
#print STDERR "\n# " . Dumper($data);

    # get other fields
    ($data->{image})                    = $html =~ m!<div class="bookcover"><img src="([^"]+)"[^>]+id=summary-frontcover[^>]*></div>!i;
    ($data->{image})                    = $html =~ m!<div class="bookcover"><a[^>]+><img src="([^"]+)"[^>]+id=summary-frontcover[^>]*></a></div>!i  unless($data->{image});
    ($data->{author})                   = $html =~ m!<td class="metadata_label">(?:<span[^>]*>)?$LANG{$lang}->{Author}(?:</span>)?</td><td class="metadata_value">(.*?)</td>!i;
    ($data->{author})                   = $html =~ m!<td class="metadata_value"><a class="primary" href=".*?"><span dir=ltr>([^<]+)</span></a></td>!si    unless($data->{author});
    ($data->{title})                    = $html =~ m!<td class="metadata_label">(?:<span[^>]*>)?$LANG{$lang}->{Title}(?:</span>)?</td><td class="metadata_value">(?:<span[^>]*>)?([^<]+)(?:</span>)?!i;
    ($data->{title})                    = $html =~ m!<meta name="title" content="([^>]+)"\s*/>! unless($data->{title});
    ($data->{description})              = $html =~ m!<meta name="description" content="([^>]+)"\s*/>!si;

    $data->{author} =~ s/"//g;
    $data->{thumb} = $data->{image};
}

1;

__END__

=head1 REQUIRES

Requires the following modules be installed:

L<WWW::Scraper::ISBN::Driver>,
L<WWW::Mechanize>
L<JSON>

=head1 SEE ALSO

L<WWW::Scraper::ISBN>,
L<WWW::Scraper::ISBN::Record>,
L<WWW::Scraper::ISBN::Driver>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-GoogleBooks_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2010-2015 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
