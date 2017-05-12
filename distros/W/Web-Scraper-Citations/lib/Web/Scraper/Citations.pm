package Web::Scraper::Citations;

use warnings;
use strict;
use Carp;
use utf8;

use version; our $VERSION = qv('0.0.2');

use Mojo::UserAgent;
use Mojo::DOM;
use Mojo::ByteStream 'b';
use File::Slurp::Tiny qw(read_file);
use Moose;

# Module implementation here
has 'id' => ( is => 'ro', isa => 'Str' );
has 'citations' => ( is => 'ro', isa => 'Int' );
has 'citations_last5' => ( is => 'ro', isa => 'Int' );
has 'h' => ( is => 'ro', isa => 'Int' );
has 'h_last5' => ( is => 'ro', isa => 'Int' );
has 'i10' => ( is => 'ro', isa => 'Int' );
has 'i10_last5' => ( is => 'ro', isa => 'Int' );
has 'name' => ( is => 'ro', isa => 'Str' );
has 'affiliation'=> ( is => 'ro', isa => 'Str' );

use constant STAT_NAMES => qw( citations citations_last5 h h_last5 i10 i10_last5 ); 

# Mojo functions
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
 
    if ( @_ == 1 && $_[0] !~ /file:/ ) {
      my $id;
      if ( $_[0] =~ /user=(\w+)/ ) {
	$id = $1;
      } else {
	$id = $_[0];
      }
      my $url = Mojo::URL->new("http://scholar.google.com/citations?user=$id");
      my $object = scrape_URL( $url );
      return $class->$orig( %$object );
    }
    elsif ( $_[0] =~ /file:/ ) {
      my $url = Mojo::URL->new($_[0]);
      my $object = scrape_URL( $url );

      return $class->$orig(  %$object);
    }
};

sub profile_stats {
    my $self = shift;
    my %stats;
    map( $stats{$_} = $self->$_, STAT_NAMES );
    return \%stats;
}

sub scrape_URL {
  my $url = shift;
  my $object = {};
  my $dom;
  my $text;
  if ( $url =~ /http/ ) {
    my $ua = Mojo::UserAgent->new( max_redirects => 5 );
    my $response = $ua->get( $url )->res;
    if ( $response->code != 200 ) {
      croak "Page not found with code ". $response->code. " and message ".$response->message;
    } 
    $dom = $response->dom;
    $text = $response->text;
  } elsif ( $url =~ /file/ ) {
    my ($fn) = ($url =~ /file:(.+)/);
    $text = read_file( $fn );
    croak "Can't open file $fn" unless $text;
    $dom = Mojo::DOM->new( $text );
  }
    
  croak "Error in downloaded text" if !$dom->at("#gsc_prf_in");
  $object->{'name'} = $dom->at("#gsc_prf_in")->text;
  $object->{'affiliation'} = $dom->at( ".gsc_prf_il" )->all_text;
  ($object->{'id'}) = ($text =~ /citations\?user=(\w+)/ );
  my @dom_stats = $dom->find(".gsc_rsb_std")->map('text')->each;
  for my $stat ( STAT_NAMES ) {
    $object->{$stat} = shift @dom_stats;
  }
  return $object;
}

no Moose;
__PACKAGE__->meta->make_immutable;    
   

"To an infinite H and beyond"; # Magic true value required at end of module
__END__

=head1 NAME

Web::Scraper::Citations - Scrapes Google Scholar profiles for citations and stuff

=head1 VERSION

This document describes Web::Scraper::Citations version 0.0.1

=head1 SYNOPSIS

    use Web::Scraper::Citations;

    my $author_profile = new Web::Scraper::Citations( $url_or_author_id );

    say "This champ has got an h of ", $author_profile->h(), " and ", $author_profile->citations();
  
  
=head1 DESCRIPTION

This scraper downloads information from Google Scholar profiles at
L<http://scholar.google.com/citations>. Scraping is limited by google
to 2500 a day, so be careful with it and don't binge-scrape.


=head1 INTERFACE 

=head2 new ( $url_or_author_id )

Creates a new object from the Google Citations URL or author ID (which is part of the URL anyway)

=head2 h, h_last5, citations, citations_last5, i10, i10_last5, name, affiliation

Returns the h index, citations, and number of papers with more than 10
citations, absolute or in the last 5 years.

=head2 profile_stats

Returns a hashref with all stats above, names as keys.

=head2 scrape_URL( $url )

Scrapes either a real URL or a C<file:> which is used mainly for caching purposes or for offline. 



=head2 STAT_NAMES

Constant with the names of the stats we are interested in.

=head1 CONFIGURATION AND ENVIRONMENT

Web::Scraper::Citations requires no configuration files or environment variables.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-web-scraper-citations@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

JJ  C<< <JMERELO@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, JJ C<< <JMERELO@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the GPL v3.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
