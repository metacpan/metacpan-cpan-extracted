package WWW::Scraper::ISBN::LibUniIt_Driver;

use strict;
use warnings;
use LWP::UserAgent;
use WWW::Scraper::ISBN::Driver;
use HTML::Entities qw(decode_entities);

our @ISA = qw(WWW::Scraper::ISBN::Driver);

our $VERSION = '0.2';
                
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
		$price = $1 if ($doc =~ /Prezzo: .*?&euro;&nbsp;(\d+)/);
	} elsif ($doc =~ /Dettagli del libro/){
		$price = $1 if ($doc =~ m|<span class="product_price">&euro;&nbsp;([^<]+)</span>|);
		$title = $1 if ($doc =~ m|<span class="product_label">Titolo:</span> <span class="product_text">([^>]+)</span>|);
		$authors = parse_authors($1) if ($doc =~ m|<span class="product_label">Autor[ei]:</span>(.*?)<li>|);
		$editor = $1 if ($doc =~ m|<span class="product_label">Editore:</span>.*?<a href="libri-editore[^"]+"[^>]+/>([^<]+)</a></span><li>|);
		$date = $1 if ($doc =~ m|<span class="product_label">Data di Pubblicazione:</span>\s+<span class="product_text">(\d+)</span><li>|);
		
	} else {
		$self->error("liberiauniversitaria.it answered in an unattended way, book information cannot be found.");
		$self->found(0);
	};

	decode_entities($title);	
	decode_entities($authors);	
	decode_entities($editor);	
	my $bk = {   
                'isbn' => $isbn,
                'author' => $authors,
                'title' => $title,
                'editor' => $editor,
		'date' => $date,
		'price' => $price,
        };
	$self->book($bk);
	$self->found(1);
        return $bk;
}

sub parse_authors {
	my $info = shift;
	my $sep = "";
	my $authors;
	while ($info =~ s|<a href="libri-autore[^"]+" [^>]+>([^<]+)</a>||){
		$authors .=  $sep . $1;
		$sep = ", ";
	}
	return $authors;
}

1;
__END__

=head1 NAME

WWW::Scraper::ISBN::LibUniIt - Driver for L<WWW::Scraper::ISBN> that searches L<http://www.libreriauniversitaria.it/>.

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

Searches for book information from http://www.libreriauniversitaria.it

=head1 METHODS

=over 4

=item C<search()>

Searches for an ISBN on L<http://www.libreriauniversitaria.it/>.
If a valid result is returned the following fields are returned:

   isbn
   author
   title
   editor
   date
   price

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over 4

=item L<< WWW::Scraper::ISBN >>

=item L<< WWW::Scraper::ISBN::Record >>

=item L<< WWW::Scraper::ISBN::Driver >>

=back

=head1 AUTHOR

Angelo Lucia, E<lt>angelo.lucia@email.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Angelo Lucia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
