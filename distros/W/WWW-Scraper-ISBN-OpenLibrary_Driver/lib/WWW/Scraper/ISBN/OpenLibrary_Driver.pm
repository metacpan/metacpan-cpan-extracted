package WWW::Scraper::ISBN::OpenLibrary_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.09';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::OpenLibrary_Driver - Search driver for OpenLibrary online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from OpenLibrary online book catalog

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
# Constants

use constant	SEARCH	=> 'http://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:';
use constant	LB2G    => 453.59237;   # number of grams in a pound (lb)
use constant	OZ2G    => 28.3495231;  # number of grams in an ounce (oz)
use constant	IN2MM   => 25.4;        # number of inches in a millimetre (mm)

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the OpenLibrary
server.

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
  binding       (if known)
  pages         (if known)
  weight        (if known) (in grammes)
  width         (if known) (in millimetres)
  height        (if known) (in millimetres)
  depth         (if known) (in millimetres)

The book_link and image_link refer back to the OpenLibrary website.

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
    my $data;
	$self->found(0);
	$self->book(undef);

	my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );

    eval { $mech->get( SEARCH . $isbn ) };
    return $self->handler("OpenLibrary website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

    my $code = decode_json($mech->content());
#use Data::Dumper;
#print STDERR "\n# code=".Dumper($code);

    return $self->handler("Failed to find that book on OpenLibrary website.")
	    unless($code->{'ISBN:'.$isbn});

    $data->{isbn13}         = $code->{'ISBN:'.$isbn}{identifiers}{isbn_13}[0];
    $data->{isbn10}         = $code->{'ISBN:'.$isbn}{identifiers}{isbn_10}[0];

    return $self->handler("Failed to find that book on OpenLibrary website.")
	    unless($isbn eq $data->{isbn13} || $isbn eq $data->{isbn10});

#use Data::Dumper;
#print STDERR "\n# " . Dumper($data);

    $data->{isbn13}         = $code->{'ISBN:'.$isbn}{identifiers}{isbn_13}[0];
    $data->{isbn10}         = $code->{'ISBN:'.$isbn}{identifiers}{isbn_10}[0];
    $data->{image}          = $code->{'ISBN:'.$isbn}{cover}{large};
    $data->{thumb}          = $code->{'ISBN:'.$isbn}{cover}{small};
    $data->{author}         = $code->{'ISBN:'.$isbn}{authors}[0]{name};
    $data->{title}          = $code->{'ISBN:'.$isbn}{title};
    $data->{publisher}      = $code->{'ISBN:'.$isbn}{publishers}[0]{name};
    $data->{pubdate}        = $code->{'ISBN:'.$isbn}{publish_date};
    $data->{pages}          = $code->{'ISBN:'.$isbn}{number_of_pages};
    $data->{url}            = $code->{'ISBN:'.$isbn}{url};
    $data->{weight}         = $code->{'ISBN:'.$isbn}{weight};

    if($data->{weight}&& $data->{weight} =~ /([\d.]+)\s*(?:lbs|pounds)/) {
        $data->{weight} = int($1 * LB2G);
    } elsif($data->{weight} && $data->{weight} =~ /([\d.]+)\s*(?:ozs|ounces)/) {
        $data->{weight} = int($1 * OZ2G);
    } elsif($data->{weight} && $data->{weight} =~ /([\d.]+)\s*(?:g|grams)/) {
        $data->{weight} = int($1);
    } else {
        $data->{weight} = undef;
    }

    eval { $mech->get( $data->{url} ) };
    return $self->handler("OpenLibrary website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

	# The Book page
    my $html = $mech->content();
#print STDERR "\n# html=[\n$html\n]\n";

    # catch any data not in the JSON
    ($data->{height},$data->{width},$data->{depth})    
                                        = $html =~ m!<td class="title"><span class="title">Dimensions</span></td>\s*<td><span class="object">([\d.]+)\s+x\s+([\d.]+)\s+x\s+([\d.]+)\s+inches!i;
    ($data->{binding})                  = $html =~ m!<td class="title"><span class="title">Format</span></td>\s*<td><span class="object">([^<]+)!i;

    $data->{height} = int($data->{height} * IN2MM)  if($data->{height});
    $data->{width}  = int($data->{width}  * IN2MM)  if($data->{width});
    $data->{depth}  = int($data->{depth}  * IN2MM)  if($data->{depth});

#use Data::Dumper;
#print STDERR "\n# " . Dumper($data);

	return $self->handler("Could not extract data from OpenLibrary result page.")
		unless(defined $data);

	# trim top and tail
	foreach (keys %$data) { next unless(defined $data->{$_});$data->{$_} =~ s/^\s+//;$data->{$_} =~ s/\s+$//; }

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
		'pubdate'		=> $data->{pubdate},
		'publisher'		=> $data->{publisher},
		'binding'	    => $data->{binding},
		'pages'		    => $data->{pages},
		'weight'		=> $data->{weight},
		'width'		    => $data->{width},
		'height'		=> $data->{height},
		'depth'		    => $data->{depth},
        'json'          => $code,
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
L<JSON>

=head1 SEE ALSO

L<WWW::Scraper::ISBN>,
L<WWW::Scraper::ISBN::Record>,
L<WWW::Scraper::ISBN::Driver>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-OpenLibrary_Driver).
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
