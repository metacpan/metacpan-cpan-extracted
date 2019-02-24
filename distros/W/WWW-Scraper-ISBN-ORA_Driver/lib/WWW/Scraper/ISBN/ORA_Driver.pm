package WWW::Scraper::ISBN::ORA_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.23';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::ORA_Driver - Search driver for O'Reilly Media's online catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the O'Reilly Media's online catalog.

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

use constant ORA    => 'https://www.oreilly.com';
use constant SEARCH => 'https://search.oreilly.com';
use constant QUERY  => '?submit.x=17&submit.y=8&q=%s';

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the 
O'Reilly Media server.

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
  thumb_link
  description
  pubdate
  publisher
  binding       (if known)
  pages         (if known)
  weight        (if known) (in grammes)
  width         (if known) (in millimetres)
  height        (if known) (in millimetres)

The book_link and image_link refer back to the O'Reilly US website.

=back

=cut

sub search {
    my $self = shift;
    my $isbn = shift;
    $self->found(0);
    $self->book(undef);

    my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );

    my $url = SEARCH . sprintf(QUERY,$isbn);
    eval { $mech->get( $url ) };
    return $self->handler("O'Reilly Media website appears to be unavailable.")
        if($@ || !$mech->success() || !$mech->content());

    # The Search Results page
    my $content = $mech->content();
    my ($book) = $content =~ m!<div class="book_text">\s*<p class="title">\s*<a href="([^"]+)"!;

    unless(defined $book) {
        #print STDERR "\n#url=$url\n";
        #print STDERR "\n#content=".$mech->content();
        return $self->handler("Could not extract data from the O'Reilly Media search page [".($mech->uri())."].");
    }

    eval { $mech->get( $book ) };
    return $self->handler("O'Reilly Media website appears to be unavailable.")
        if($@ || !$mech->success() || !$mech->content());

    my $html = $mech->content();
    my $data = {};

    for my $name ('book.isbn','ean','target','reference','isbn','graphic','graphic_medium','graphic_large','book_title','author','keywords','description','date') {
        if($html =~ m!<meta name="$name" content="([^"]+)"\s*/>!i) {
            $data->{$name} = $1;
        } elsif($html =~ m!<meta content="([^"]+)" name="$name"\s*/>!i) {
            $data->{$name} = $1;
        }
    }

    #my (@isbns) = split(',',$data->{target});
    if($data->{target}) {
        for my $isbn ( split(',',$data->{target}) ) {
            $isbn =~ s/\D+//g;
            next unless($isbn);
            $data->{isbn10} = $isbn if(length($isbn) == 10);
            $data->{isbn13} = $isbn if(length($isbn) == 13);
        }
    }

    #($data->{isbn13},$data->{isbn10}) = $html =~ m!<dt>(?:Print )?ISBN:</dt><dd[^>]+>([\d-]+)</dd>\s*<dt class="isbn-10"> \| ISBN 10:</dt> <dd>([\d-]+)</dd>!;
    ($data->{pages}) = $html =~ m!<p><strong>Pages:</strong>\s*(\d+)\s*</p>!;

    for ('graphic_medium','graphic_large') {  # alternative graphic fields
        next unless($data->{$_});
        $data->{graphic} ||= $data->{$_};
    }
    $data->{graphic} ||= '';
        

    unless(defined $data) {
        #print STDERR "\n#url=$book\n";
        #print STDERR "\n#content=".$mech->content();
        return $self->handler("Could not extract data from the O'Reilly Media result page [".($mech->uri())."].");
    }

    # trim top and tail
    foreach (keys %$data) { next unless(defined $data->{$_});$data->{$_} =~ s/^\s+//;$data->{$_} =~ s/\s+$//; }

    my $bk = {
        'ean13'       => $data->{ean},
        'isbn13'      => $data->{ean},
        'isbn10'      => $data->{isbn10},
        'isbn'        => $data->{ean},
        'author'      => $data->{author},
        'title'       => $data->{book_title},
        'book_link'   => $mech->uri(),
        'image_link'  => ($data->{graphic} !~ /^http/ ? ORA : '') . $data->{graphic},
        'thumb_link'  => ($data->{graphic} !~ /^http/ ? ORA : '') . $data->{graphic},
        'description' => $data->{description},
        'pubdate'     => $data->{date},
        'publisher'   => q!O'Reilly Media!,
        'binding'     => $data->{binding},
        'pages'       => $data->{pages},
        'weight'      => $data->{weight},
        'width'       => $data->{width},
        'height'      => $data->{height}
    };
    $self->book($bk);
    $self->found(1);
    return $self->book;
}

1;

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
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-ORA_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2004-2019 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
