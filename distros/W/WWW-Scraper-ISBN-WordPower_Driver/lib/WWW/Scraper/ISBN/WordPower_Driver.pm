package WWW::Scraper::ISBN::WordPower_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.10';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::WordPower_Driver - Search driver for Word Power online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from Word Power online book catalog

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

use constant	SEARCH	=> 'http://www.word-power.co.uk/searchBook.php?options=isbn&imageField.x=19&imageField.y=9&keywords=';
my ($URL1,$URL2,$URL3) = ('http://www.word-power.co.uk','/books/[^>]+-I','/');

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the Word 
Power server.

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

The book_link and image_link refer back to the Word Power website.

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
    $mech->add_header('Accept-Encoding' => undef);

    eval { $mech->get( SEARCH . $isbn ) };
    return $self->handler("WordPower website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

    my $content = $mech->content;
    my ($link) = $content =~ m!($URL2$ean$URL3)!si;
#print STDERR "\n# link1=[$URL2$ean$URL3]\n";
#print STDERR "\n# link2=[$URL1$link]\n";
#print STDERR "\n# content1=[\n$content\n]\n";
#print STDERR "\n# is_html=".$mech->is_html().", content type=".$mech->content_type()."\n";
#print STDERR "\n# dump headers=".$mech->dump_headers."\n";

	return $self->handler("Failed to find that book on WordPower website.")
	    unless($link);

    eval { $mech->get( $URL1 . $link ) };
    return $self->handler("WordPower website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

	# The Book page
    my $html = $mech->content();

	return $self->handler("Failed to find that book on WordPower website. [$isbn]")
		if($html =~ m!Sorry, we couldn't find any matches for!si);
    
#print STDERR "\n# content2=[\n$html\n]\n";

    my $data;
    ($data->{isbn10})           = $self->convert_to_isbn10($ean);
    ($data->{publisher})        = $html =~ m!<td[^>]+>Publisher</td>\s*<td[^>]+><a[^>]+>([^<]+)</a></td>!i;
    ($data->{pubdate})          = $html =~ m!<td[^>]+>Publication date</td>\s*<td[^>]+>([^<]+)</td>!i;

    $data->{publisher} =~ s!<[^>]+>!!g  if($data->{publisher});
    $data->{pubdate} =~ s!\s+! !g       if($data->{pubdate});

    ($data->{isbn13})           = $html =~ m!<td[^>]+>ISBN13</td>\s*<td[^>]+>([^<]+)</td>!i;
    ($data->{isbn10})           = $html =~ m!<td[^>]+>ISBN</td>\s*<td[^>]+>([^<]+)</td>!i;
    ($data->{image})            = $html =~ m!"(http://.*?/product_images/$data->{isbn13}.jpg)"!i;
    ($data->{thumb})            = $html =~ m!"(http://.*?/product_images/$data->{isbn13}.jpg)"!i;
    ($data->{author})           = $html =~ m!by\s*<a href="/author/[^/]+/">([^<]+)</a>!i;
    ($data->{title})            = $html =~ m!<p class="p_bookTitle"><b>([^<]+)</b>!i;
    ($data->{description})      = $html =~ m!<div class="TabbedPanelsContentGroup">\s*<div class="TabbedPanelsContent">([^~]+)</div>!si;
    ($data->{binding})          = $html =~ m!<td[^>]+>Format</td>\s*<td[^>]+>([^<]+)</td>!s;
    ($data->{pages})            = $html =~ m!<tr valign="top">\s*<td valign="middle">Pages</td>\s*<td valign="middle">([\d.]+)</td>\s*</tr>!s;
    ($data->{weight})           = $html =~ m!<tr valign="top">\s*<td valign="middle">Weight .grammes.</td>\s*<td valign="middle">([\d.]+)</td>\s*</tr>!s;
    ($data->{width})            = $html =~ m!<td[^>]+>Width \(mm\)</td>\s*<td[^>]+>([^<]+)</td>!s;
    ($data->{height})           = $html =~ m!<td[^>]+>Height \(mm\)</td>\s*<td[^>]+>([^<]+)</td>!s;

    for my $key (qw(weight width height)) {
        next    unless($data->{$key});
        $data->{$key} =~ s/\.0+$//;
    }

    $data->{author} =~ s!<[^>]+>!!g                     if($data->{author});
    if($data->{description}) {
        $data->{description} =~ s!<script.*!!si;
        $data->{description} =~ s!<(p|br\s*/)>!\n!g;
        $data->{description} =~ s!<[^>]+>!!gs;
        $data->{description} =~ s! +$!!gm;
        $data->{description} =~ s!\n\n!\n!gs;
    }

#use Data::Dumper;
#print STDERR "\n# " . Dumper($data);

	return $self->handler("Could not extract data from WordPower result page.")
		unless(defined $data);

	# trim top and tail
	foreach (keys %$data) { 
        next unless(defined $data->{$_});
        $data->{$_} =~ s!&nbsp;! !g;
        $data->{$_} =~ s/^\s+//;
        $data->{$_} =~ s/\s+$//;
    }

	my $bk = {
		'ean13'		    => $data->{isbn13},
		'isbn13'		=> $data->{isbn13},
		'isbn10'		=> $data->{isbn10},
		'isbn'			=> $data->{isbn13},
		'author'		=> $data->{author},
		'title'			=> $data->{title},
		'book_link'		=> $mech->uri(),
		'image_link'	=> $data->{image},
		'thumb_link'	=> $data->{thumb},
		'description'	=> $data->{description},
		'pubdate'		=> $data->{pubdate},
		'publisher'		=> $data->{publisher},
		'binding'	    => $data->{binding},
		'pages'		    => $data->{pages},
		'weight'		=> $data->{weight},
		'width'		    => $data->{width},
		'height'		=> $data->{height},
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
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-WordPower_Driver).
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
