package WWW::Scraper::ISBN::LibUniverIt_Driver;
use strict;
use warnings;
use LWP::UserAgent;
use WWW::Scraper::ISBN::Driver;
use HTML::Entities qw(decode_entities);

our @ISA = qw(WWW::Scraper::ISBN::Driver);

our $VERSION = '0.13';
                
sub search {
        my $self = shift;
        my $isbn = shift;
        $self->found(0);
        $self->book(undef);
	
	my $post_url = 'http://www.libreriauniversitaria.it/c_power_search.php?shelf=BIT&q=' . $isbn . '&submit=Invia';
        my $ua = new LWP::UserAgent;
        my $res = $ua->get($post_url);
        my $doc = $res->as_string;
        
        my $title = "";
        my $authors = "";
        my $editor = "";
	    my $date = "";
	    my $price = "";
        my $pages = "";
	    my $series = "";
	    my $shelf = "";
	    my $trans = "";
        if ($doc =~ /Nessun prodotto corrisponde ai criteri di ricerca/) {
	    $self->error("book not found.");
	    $self->found(0);
	    return 0;
	} elsif ($doc =~ m|<title>Ricerca - $isbn - libreriauniversitaria\.it</title>|i){
		my $info;
		if ($doc =~ m|<td [^>]+><a [^>]+ class="product_heading_title_link" [^>]+>([^<]+)</a>(.*?)</td>|){
			$title = $1;
			$info = $2;
			$authors = parse_authors($info);
			if ($info =~ m|<a[^>]+ href="libri-editore[^"]+" [^>]+/>([^<]+)</a> - (\d+)|){
			    $editor = $1;
			    $date = $2;
			}
		}
		
		##<span class="product_label">Editore:</span> <span class="product_text"><a href="libri-editore_Einaudi-einaudi.htm" title="Einaudi" >Einaudi</a></span>
		$price = $1 if ($doc =~ /Prezzo: .*?&euro;&nbsp;(\d+)/);
	} elsif ($doc =~ /Dettagli del libro/){
		$price = $1 if ($doc =~ m|<span class="product_price">&euro;&nbsp;([^<]+)</span>|);
		$title = $1 if ($doc =~ m|<span class="product_label">Titolo: </span>\n\t+\s+<span class="product_text">([^>]+)</span>|);
		$authors = parse_authors($1) if ($doc =~ m|<span class="product_label">Autor[ei]: </span>\n\t+\s+(.*?)\n\t+\s+</li>|);
	    $editor = $1 if ($doc =~m|<span class="product_label">Editore: </span>\n\t+\s+<span class="product_text"><a class="publisher_url_html" href="http://www.libreriauniversitaria.it/libri-editore[^>]+>([^<]+)</a>|);
	    $date = $1 if ($doc =~ m|<span class="product_label">Data di Pubblicazione: </span>\n\t+\s+<span class="product_text">(\d+)</span>|);
		$pages = $1 if ($doc =~ m|<span class="product_label">Pagine: </span>\n\t+\s+<span class="product_text">(\d+)</span>|);
        $series = $1 if ($doc =~ m|<span class="product_label">Collana: </span>\n\t+\s+<span class="product_text"><a class="publisher_url_html" href="http://www.libreriauniversitaria.it/libri-collana[^>]+>([^<]+)</a>|);
	    $shelf = $1 if ($doc =~ m|<span class="product_label">Reparto: </span>\n\t+\s+<span class="product_text"><a class="reparto_url_html" href="http://www.libreriauniversitaria.it/libri[^>]+>([^<]+)</a>|);
	    $trans = $1 if ($doc =~ m|<span class="product_label">Traduttore: </span>\n\t+\s+<span class="product_text">([^<]+)</span><li>|);
	    
	} else {
		$self->error("libreriauniversitaria.it answered in an unattended way, book information cannot be found.");
		$self->found(0);
	};

	decode_entities($title);	
	decode_entities($authors);	
	decode_entities($editor);	
	my $bk = {   
                'isbn' => $isbn,
                'author' => $authors,
                'title' => $title,
                'publisher' => $editor,
		'date' => $date,
		'price' => $price,
		'pages' => $pages,
		'series' => $series,
		'shelf' => $shelf,
		'trans' => $trans,
        };
	$self->book($bk);
	$self->found(1);
        return $bk;
}

sub parse_authors {
	my $info = shift;
	my $sep = "";
	my $authors;
	while ($info =~ s|<a class="authors_url_html" href="http://www.libreriauniversitaria.it/libri-autore[^"]+" [^>]+>([^<]+)</a>||){
		$authors .=  $sep . $1;
		$sep = ", ";
	}
	return $authors;
}

1;
__END__

=head1 NAME

WWW::Scraper::ISBN::LibUniverIt - Driver for L<WWW::Scraper::ISBN> that searches L<http://www.libreriauniversitaria.it/>, largely based on code by Angelo Lucia.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 REQUIRES

Requires the following modules be installed:

=over 4

=item L<WWW::Scraper::ISBN::Driver>

=item L<HTML::Entities>

=item L<LWP::UserAgent>

=back

=head1 DESCRIPTION

Searches for more complete book information from http://www.libreriauniversitaria.it

=head1 METHODS

=over 4

=item C<search()>

Searches for an ISBN on L<http://www.libreriauniversitaria.it/>.
If a valid result is returned the following fields are returned:

   isbn
   author
   title
   publisher
   date
   price
   pages
   series
   translator
   shelf

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over 4

=item L<< WWW::Scraper::ISBN >>

=item L<< WWW::Scraper::ISBN::Record >>

=item L<< WWW::Scraper::ISBN::Driver >>

=back

=head1 AUTHOR

Marco Ghezzi, C<< <marcog at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

Regex help from Marco Beri.

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Marco Ghezzi, most of the code originally written by Angelo Lucia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
1; # End of WWW::Scraper::ISBN::LibUniverIt::Driver
