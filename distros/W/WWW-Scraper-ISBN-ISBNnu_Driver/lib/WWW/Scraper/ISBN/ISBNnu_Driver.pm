package WWW::Scraper::ISBN::ISBNnu_Driver;

use strict;
use warnings;

our $VERSION = '0.24';

#--------------------------------------------------------------------------

###########################################################################
# Inheritence

use base qw(WWW::Scraper::ISBN::Driver);

###########################################################################
# Modules

use WWW::Mechanize;

###########################################################################
# Variables

my $IN2MM = 0.0393700787;   # number of inches in a millimetre (mm)
my $LB2G  = 0.00220462;     # number of pounds (lbs) in a gram
my $OZ2G  = 0.035274;       # number of ounces (oz) in a gram

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

sub trim {
	my ($self,$value) = @_;

    return ''   unless(defined $value);

    $value =~ s/^\s+//;         # trim leading whitespace
    $value =~ s/\s+$//;         # trim trailing whitespace
    $value =~ s/\n//g;          # trim newlines?
    $value =~ s/ +/ /g;         # trim extra middle space
    $value =~ s/<[^>]+>//g;     # remove tags

    return $value;
}
                
sub search {
    my ($self,$isbn) = @_;
    my %data;
    
    $self->found(0);
    $self->book(undef);

    my $post_url = "http://isbn.nu/".$isbn;
	my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );
    $mech->add_header( 'Accept-Encoding' => undef );

    eval { $mech->get( $post_url ) };
    return $self->handler("isbn.nu website appears to be unavailable.")
        if($@ || !$mech->success() || !$mech->content());

    my $html = $mech->content();
    my ($title) = $html =~ /<title>([^<]+)<\/title>/;
    $data{title} = $self->trim($title);

    return $self->handler("Failed to find that book on the isbn.nu website.")
        if (!$data{title} || $data{title} eq "No Title Found");

    ($data{publisher})  = $html =~ m!<span class="bi_col_title">Publisher</span>\s*<span class="bi_col_value">([^<]+)</span></div>!si;
    ($data{pubdate})    = $html =~ m!<span class="bi_col_title">Publication date</span>\s*<span class="bi_col_value">([^<]+)</span></div>!;
    ($data{pages})      = $html =~ m!<span class="bi_col_title">Pages</span>\s*<span class="bi_col_value">([0-9]+)</span></div>!;
    ($data{edition})    = $html =~ m!<span class="bi_col_title">Edition</span>\s*<span class="bi_col_value">([^<]+)</span></div>!;
    ($data{volume})     = $html =~ m!<span class="bi_col_title">Volume</span>\s*<span class="bi_col_value">([^<]+)</span></div>!;
    ($data{binding})    = $html =~ m!<span class="bi_col_title">Binding</span>\s*<span class="bi_col_value">([^<]+)</span></div>!;
    ($data{isbn13})     = $html =~ m!<span class="bi_col_title">ISBN-13</span>\s*<span class="bi_col_value">([0-9]+)</span></div>!;
    ($data{isbn10})     = $html =~ m!<span class="bi_col_title">ISBN-10</span>\s*<span class="bi_col_value">([0-9X]+)</span></div>!;
    ($data{weight})     = $html =~ m!<span class="bi_col_title">Weight</span>\s*<span class="bi_col_value">([0-9\.]+) lbs.</span></div>!;
    ($data{author})     = $html =~ m!<div class="d_descriptive">By\s*(.*?)\s*</div>!;
    ($data{description})= $html =~ m!<div class="bi_annotation_text"><div class="bi_anno_text_head">Summary</div>([^<]+)<!;
    ($data{description})= $html =~ m!<div class="bi_wide bi_annotation_text"><a name="amazondesc"></a><b>Amazon.com description:</b> <b>Product Description</b>:([^<]+)<!   unless($data{description});

    $data{$_} = $self->trim($data{$_})  for(qw(publisher pubdate binding author description));

    if($data{weight}) {
        $data{weight} = int($data{weight} / $LB2G);
    }

    my @size = $html =~ m!<span class="bi_col_title">Dimensions</span>\s*<span class="bi_col_value">([0-9\.]+) by ([0-9\.]+) by ([0-9\.]+) in.</span></div>!;
    if(@size) {
        ($data{depth},$data{width},$data{height}) = sort @size;    
        $data{$_} = int($data{$_} / $IN2MM)  for(qw( height width depth ));
    }

#print STDERR "#html=".Dumper(\%data)."\n";

    $data{book_link} = $mech->uri();

    $data{ean13} = $data{isbn13};
    $data{isbn}  = $data{isbn13} || $isbn;
    $data{html}  = $html;

	$self->book(\%data);

    $self->found(1);
    return $self->book;
}

1;

__END__

=head1 NAME

WWW::Scraper::ISBN::ISBNnu_Driver - Search driver for the isbn.nu online book catalog

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 REQUIRES

Requires the following modules be installed:

=over 4

=item L<WWW::Scraper::ISBN::Driver>

=item L<HTTP::Request::Common>

=item L<LWP::UserAgent>

=back

=head1 DESCRIPTION

Searches for book information from http://www.isbn.nu/.

=head1 METHODS

=over 4

=item C<trim()>

Trims excess whitespace.

=item C<search()>

Grabs page from L<http://www.isbn.nu/>'s handy interface and attempts to 
extract the desired information.  If a valid result is returned the 
following fields are returned:

  isbn          (now returns isbn13)
  isbn10        
  isbn13
  ean13         (industry name)
  title
  author
  edition
  volume
  book_link
  publisher
  pubdate
  binding       (if known)
  pages         (if known)
  weight        (if known) (in grammes)
  width         (if known) (in millimetres)
  height        (if known) (in millimetres)
  depth         (if known) (in millimetres)
  description   (if known)

=back

=head1 SEE ALSO

=over 4

=item L<< WWW::Scraper::ISBN >>

=item L<< WWW::Scraper::ISBN::Record >>

=item L<< WWW::Scraper::ISBN::Driver >>

=back

=head1 AUTHOR

  2004-2013 Andy Schamp, E<lt>andy@schamp.netE<gt>
  2013-2014 Barbie, E<lt>barbie@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright 2004-2013 by Andy Schamp
  Copyright 2013-2014 by Barbie

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
