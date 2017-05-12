package WWW::Scraper::ISBN::ISBNdb_Driver;

use strict;
use warnings;

our $VERSION = '0.11';

#--------------------------------------------------------------------------

###########################################################################
# Inheritence

use base qw(WWW::Scraper::ISBN::Driver);

###########################################################################
# Modules

use IO::File;
use LWP::UserAgent;
use XML::LibXML;
use Carp;

###########################################################################
# Variables

our $ACCESS_KEY = undef;
our $user_agent = new LWP::UserAgent();

my $API_VERSION = 'v1';
my $IN2MM = 0.0393700787;   # number of inches in a millimetre (mm)
my $LB2G  = 0.00220462;     # number of pounds (lbs) in a gram

my %editions = (
    '(pbk.)'            => 'Paperback',
    '(electronic bk.)'  => 'eBook'
);

my %api_paths = (
    'v1'    => { format => 'http://isbndb.com/api/%s.xml?access_key=%s&index1=%s&results=%s&value1=%s', fields => [ qw( search_type access_key search_field results_type search_param ) ] },
    'v2'    => { format => 'http://isbndb.com/api/v2/xml/%s/%s/%s', fields => [ qw( access_key search_type search_param ) ] }
);

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::ISBNdb_Driver - Search driver for the isbndb.com online book catalog

=head1 SYNOPSIS

  use WWW::Scraper::ISBN;
  my $scraper = new WWW::Scraper::ISBN();
  $scraper->drivers( qw/ ISBNdb / );
  $WWW::Scraper::ISBN::ISBNdb_Driver::ACCESS_KEY = 'xxxx'; # Your isbndb.com access key

  my $isbn = '0596101058';
  my $result = $scraper->search( $isbn );

  if( $result->found ) {
    my $book = $result->book;
    print "ISBN: ",      $book->{isbn},      "\n";
    print "Title: ",     $book->{title},     "\n";
    print "Author: ",    $book->{author},    "\n";
    print "Publisher: ", $book->{publisher}, "\n";
  }

=head1 DESCRIPTION

This is a WWW::Scraper::ISBN driver that pulls data from
L<http://www.isbndb.com>. Consult L<WWW::Scraper::ISBN> for usage
details.

=cut

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

sub search {
    my( $self, $isbn ) = @_;
    $self->found(0);
    $self->book(undef);

    my %book;
    if($API_VERSION eq 'v1') {
        my( $details, $details_url ) = $self->_fetch( 'books', 'isbn' => $isbn, 'details' );
        my( $authors, $authors_url ) = $self->_fetch( 'books', 'isbn' => $isbn, 'authors' );

        return  unless $details && $self->_contains_book_data($details);

        %book = (
            book_link   => $details_url,
        );

        $self->_get_pubdata(\%book,$details);
        $self->_get_details(\%book,$details);
        $self->_get_authors(\%book,$authors);
    } else {
        my( $details, $details_url ) = $self->_fetch( 'book', 'isbn' => $isbn, 'details' );

        return  unless $details && $self->_contains_book_data($details);

        %book = (
            book_link   => $details_url,
        );

        $self->_get_details_v2(\%book,$details);
    }

    $self->_trim(\%book);

    $self->book(\%book);
    $self->found(1);
    return $self->book;
}

###########################################################################
# Private Interface

sub _contains_book_data {
    my( $self, $doc ) = @_;
    return $doc->getElementsByTagName('BookData')->size > 0 if($API_VERSION eq 'v1');
    return $doc->getElementsByTagName('data')->size > 0;
}

#<ISBNdb server_time="2013-08-31T08:52:38Z">
#<BookList total_results="1" page_size="10" page_number="1" shown_results="1">
#<BookData book_id="learning_perl_a03" isbn="0596101058" isbn13="9780596101053">
#<Title>Learning Perl</Title>
#<TitleLong></TitleLong>
#<AuthorsText>Randal L. Schwartz, Tom Phoenix and brian d foy</AuthorsText>
#<PublisherText publisher_id="oreilly">Sebastopol, CA : O\'Reilly, c2005.</PublisherText>
#<Authors>
#<Person person_id="schwartz_randal_l">Schwartz, Randal L.</Person>
#<Person person_id="tom_phoenix">Tom Phoenix</Person>
#<Person person_id="brian_d_foy">brian d foy</Person>
#</Authors>
#</BookData>
#</BookList>
#</ISBNdb>

sub _get_authors {
    my( $self, $book, $authors ) = @_;
    my $people = $authors->findnodes('//Authors/Person');
    my @people;
    for( my $i = 0; $i < $people->size; $i++ ) {
        my $person = $people->get_node($i);
        push @people, $person->to_literal;
    }

    my $str = join '; ', @people;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;

    $book->{author} = $str;
}

sub _get_pubdata {
    my( $self, $book, $doc ) = @_;

    my $pubtext = $doc->findnodes('//PublisherText')->to_literal;
    my $details = $doc->findnodes('//Details/@edition_info')->to_literal;

    my $year = '';
    if( $pubtext =~ /(\d{4})/ ) { $year = $1 }
    elsif( $details =~ /(\d{4})/ ) { $year = $1 }

    $book->{pubdate}   = $year || '';
    $book->{publisher} = '';

    my $pub_id = ($doc->findnodes('//PublisherText/@publisher_id'))[0]->to_literal;

    if($pub_id) {
        my $publisher = $self->_fetch( 'publishers', 'publisher_id', $pub_id, 'details' );
        my $data = ($publisher->findnodes('//PublisherData'))[0];

        $book->{publisher} = ($data->findnodes('//Name'))[0]->to_literal;
    }
}

#<ISBNdb server_time="2013-08-31T08:52:38Z">
#<BookList total_results="1" page_size="10" page_number="1" shown_results="1">
#<BookData book_id="learning_perl_a03" isbn="0596101058" isbn13="9780596101053">
#<Title>Learning Perl</Title>
#<TitleLong></TitleLong>
#<AuthorsText>Randal L. Schwartz, Tom Phoenix and brian d foy</AuthorsText>
#<PublisherText publisher_id="oreilly">Sebastopol, CA : O\'Reilly, c2005.</PublisherText>
#<Details change_time="2009-04-23T07:13:51Z" price_time="2013-01-01T19:03:44Z" edition_info="(pbk.)" language="eng" physical_description_text="283 p. : ill. ; 24 cm." lcc_number="" dewey_decimal_normalized="5.133" dewey_decimal="005.133" />
#</BookData>
#</BookList>
#</ISBNdb>

sub _get_details {
    my( $self, $book, $doc ) = @_;

    my $isbn10 = $doc->findnodes('//BookData/@isbn')->to_literal;
    my $isbn13 = $doc->findnodes('//BookData/@isbn13')->to_literal;

    $book->{isbn}   = $isbn13;
    $book->{ean13}  = $isbn13;
    $book->{isbn13} = $isbn13;
    $book->{isbn10} = $isbn10;

    my $long_title  = eval { ($doc->findnodes('//TitleLong'))[0]->to_literal };
    my $short_title = eval { ($doc->findnodes('//Title'))[0]->to_literal };
    $book->{title} = $long_title || $short_title;

    my $edition = $doc->findnodes('//Details/@edition_info')->to_literal;
    my $desc    = $doc->findnodes('//Details/@physical_description_text')->to_literal;
    my $dewey   = $doc->findnodes('//Details/@dewey_decimal')->to_literal;

    my ($binding,$date) = $edition =~ /([^;]+);(.*)/;
    my (@size)          = $desc =~ /([\d\.]+)"x([\d\.]+)"x([\d\.]+)"/;
    my ($weight)        = $desc =~ /([\d\.]+) lbs?/;
    my ($pages)         = $desc =~ /(\d) pages/;
    ($pages)            = $desc =~ /(\d+) p\./ unless($pages);

    my ($height,$width,$depth) = sort {$b <=> $a} @size;

    $book->{height}  = int($height / $IN2MM)    if($height);
    $book->{width}   = int($width  / $IN2MM)    if($width);
    $book->{depth}   = int($depth  / $IN2MM)    if($depth);
    $book->{weight}  = int($weight / $LB2G)     if($weight);
    $book->{pubdate} = $date    if($date);
    $book->{binding} = $editions{$edition} || $binding || $edition;
    $book->{pages}   = $pages;
    $book->{dewey}   = "$dewey";
}

# <isbndb>
#   <data>
#     <author_data>
#       <id>schwartz_randal_l</id>
#       <name>Schwartz, Randal L.</name>
#     </author_data>
#     <author_data>
#       <id>tom_phoenix</id>
#       <name>Tom Phoenix</name>
#     </author_data>
#     <author_data>
#       <id>brian_d_foy</id>
#       <name>brian d foy</name>
#     </author_data>
#     <awards_text></awards_text>
#     <book_id>learning_perl_a04</book_id>
#     <dewey_decimal>005</dewey_decimal>
#     <dewey_normal>5</dewey_normal>
#     <edition_info>Paperback; 2005-07-01</edition_info>
#     <isbn10>1600330207</isbn10>
#     <isbn13>9781600330209</isbn13>
#     <language></language>
#     <lcc_number></lcc_number>
#     <marc_enc_level>~</marc_enc_level>
#     <notes></notes>
#     <physical_description_text>7.0"x9.2"x0.9"; 1.3 lb; 704 pages</physical_description_text>
#     <publisher_id>oreilly_media</publisher_id>
#     <publisher_name>O\'Reilly Media</publisher_name>
#     <publisher_text>O\'Reilly Media</publisher_text>
#     <subject_ids>computers_internet_programming_introductory_beginning_genera</subject_ids>
#     <subject_ids>computers_internet_programming_languages_tools_general</subject_ids>
#     <subject_ids>computers_internet_programming_general</subject_ids>
#     <subject_ids>computers_internet_web_development_programming_general</subject_ids>
#     <summary>"Learning Perl, better known as "the Llama book," starts the programmer on the way to mastery. Written by three prominent members of the Perl community who each have several years of experience teaching Perl around the world, this edition has been updated to account for all the recent changes to the language up to Perl 5.8. Perl is the language for people who want to get work done. It started as a tool for Unix system administrators who needed something powerful for small tasks. Since then, Perl has blossomed into a full-featured programming language used for web programming, database manipulation, XML processing, and system administration--on practically all platforms--while remaining the favorite tool for the small daily tasks it was designed for. You might start using Perl because you need it, but you\'ll continue to use it because you love it. Informed by their years of success at teaching Perl as consultants, the authors have re-engineered the Llama to better match the pace and scope appropriate for readers getting started with Perl, while retaining the detailed discussion, thorough examples, and eclectic wit for which the Llama is famous. The book includes new exercises and solutions so you can practice what you\'ve learned while it\'s still fresh in your mind. Here are just some of the topics covered: Perl variable types subroutines file operations regular expressions text processing strings and sorting process management using third party modules If you ask Perl programmers today what book they relied on most when they were learning Perl, you\'ll find that an overwhelming majority will point to the Llama. With good reason. Other books mayteach you to program in Perl, but this book will turn you into a Perl programmer.</summary>
#     <title>Learning Perl</title>
#     <title_latin>Learning Perl</title_latin>
#     <title_long>Learning Perl (4th Edition)</title_long>
#     <urls_text></urls_text>
#   </data>
#   <index_searched>isbn</index_searched>
# </isbndb>

sub _get_details_v2 {
    my( $self, $book, $doc ) = @_;

    my $people = $doc->findnodes('//data/author_data/name');
    my @people;
    for( my $i = 0; $i < $people->size; $i++ ) {
        my $person = $people->get_node($i);
        push @people, $person->to_literal;
    }

    my $str = join '; ', @people;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;

    $book->{author} = $str;
    
    $book->{publisher} = ($doc->findnodes('//data/publisher_name'))[0]->to_literal;

    my $isbn10 = $doc->findnodes('//data/isbn10')->to_literal;
    my $isbn13 = $doc->findnodes('//data/isbn13')->to_literal;

    $book->{isbn}   = $isbn13;
    $book->{ean13}  = $isbn13;
    $book->{isbn13} = $isbn13;
    $book->{isbn10} = $isbn10;

    my $long_title  = eval { ($doc->findnodes('//data/title_long'))[0]->to_literal };
    my $short_title = eval { ($doc->findnodes('//data/title'))[0]->to_literal };
    $book->{title} = $long_title || $short_title;

    my $pubtext = $doc->findnodes('//data/publisher_text')->to_literal;
    my $edition = $doc->findnodes('//data/edition_info')->to_literal;
    my $desc    = $doc->findnodes('//data/physical_description_text')->to_literal;
    my $dewey   = $doc->findnodes('//data/dewey_decimal')->to_literal;
    my $summary = $doc->findnodes('//data/summary')->to_literal;

    my ($binding,$date) = $edition =~ /([^;]+);(.*)/;
    my (@size)          = $desc =~ /([\d\.]+)"x([\d\.]+)"x([\d\.]+)"/;
    my ($weight)        = $desc =~ /([\d\.]+) lbs?/;
    my ($pages)         = $desc =~ /(\d+) pages/;
    ($pages)            = $desc =~ /(\d+) p\./ unless($pages);

    if( !$date && $pubtext =~ /(\d{4})/ ) { $date = $1 }
    if( !$date && $edition =~ /(\d{4})/ ) { $date = $1 }

    my ($height,$width,$depth) = sort {$b <=> $a} @size;

    $book->{height}  = int($height / $IN2MM)    if($height);
    $book->{width}   = int($width  / $IN2MM)    if($width);
    $book->{depth}   = int($depth  / $IN2MM)    if($depth);
    $book->{weight}  = int($weight / $LB2G)     if($weight);
    $book->{pubdate} = $date    if($date);
    $book->{binding} = $editions{$edition} || $binding || $edition;
    $book->{pages}   = $pages;
    $book->{dewey}   = "$dewey";

    $book->{description} = $summary;
}

#--------------------------------------------------------------------------

sub _trim {
    my( $self, $book ) = @_;

    for my $key (keys %$book) {
        next unless($book->{$key});
        $book->{$key} =~ s/^\s+//s;  # remove leading spaces
        $book->{$key} =~ s/\s+$//s;  # remove trailing spaces
    }
}

sub _fetch {
    my( $self, @args ) = @_;
    my $parser = new XML::LibXML();
    my $url = $self->_url( @args );
    my $xml = $self->_fetch_data($url);
    return  unless($xml && $xml !~ /^<!DOCTYPE html>/);

    my $doc = $parser->parse_string( $xml );
    return wantarray ? ( $doc, $url ) : $doc;
}

sub _fetch_data {
    my( $self, $url ) = @_;
    my $res = $user_agent->get($url);
    return unless $res->is_success;
#    use Data::Dumper;
#    print STDERR "# data=" . Dumper($res);
    return $res->content;
}

sub _url {
    my $self = shift;

    my $access_key = $self->_get_key();
    croak "no access key provided" unless $access_key;

    my %hash = ( access_key => $access_key );
    ($hash{search_type}, $hash{search_field}, $hash{search_param}, $hash{results_type}) = @_;

    my @values = map { $hash{$_} } @{ $api_paths{$API_VERSION}{fields} };
    my $url = sprintf $api_paths{$API_VERSION}{format}, @values;

#    print STDERR "# url=$url\n";
    return $url;
}

sub _get_key {
    return $ACCESS_KEY  if($ACCESS_KEY);

    if($ENV{ISBNDB_ACCESS_KEY}) {
        $ACCESS_KEY = $ENV{ISBNDB_ACCESS_KEY};
        return $ACCESS_KEY;
    }

    for my $dir ( ".", $ENV{HOME}, '~' ) {
        my $file = join( '/', $dir, ".isbndb" );
        next unless -e $file;

        my $fh = IO::File->new($file,'r') or next;
        my $key;
        $key .= $_  while(<$fh>);
        $key =~ s/\s+//gs;
        $fh->close;

        $ACCESS_KEY = $key;
        return $ACCESS_KEY;
    }
}

sub _api_version {
    my $version = shift;
    $API_VERSION = $version if($version && $api_paths{$version});
    return $API_VERSION;
}

1;

__END__

=head1 METHODS

=over 4

=item C<search()>

Given an ISBN, will attempt to find the details via the ISBNdb.com API. If a 
valid result is returned, the following fields are returned via the book hash:

  isbn          (now returns isbn13)
  isbn10        
  isbn13
  ean13         (industry name)
  title
  author
  dewey
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

The following fields have now been deprecated:

  location
  year          # now pubdate
  _source_url   # now book_link

=cut

=back

=head1 THE ACCESS KEY

To use this driver you will need to obtain an access key from isbndb.com. It is
free to sign-up to isbndb.com, and once registered, you can request an API key.

To set the access key in the driver, within your application you will need to 
set the following, after the driver has been loaded, and before you perform a
search.

  $WWW::Scraper::ISBN::ISBNdb_Driver::ACCESS_KEY = 'xxxx';

You can also set the key in the ISBNDB_ACCESS_KEY environment variable.

Alternatively, you can create a '.isbndb' configuration file in your home
directory, which should only contain the key itself.

Reference material for developers can be found at L<http://isbndb.com/api/v2/docs>.

=head1 SEE ALSO

L<WWW::Scraper::ISBN>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-scraper-isbn-isbndb_driver at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Scraper-ISBN-ISBNdb_Driver>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Scraper::ISBN::ISBNdb_Driver

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Scraper-ISBN-ISBNdb_Driver>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Scraper-ISBN-ISBNdb_Driver>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Scraper-ISBN-ISBNdb_Driver>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Scraper-ISBN-ISBNdb_Driver>

=back

=head1 AUTHOR

  2006-2013 David J. Iberri, C<< <diberri at cpan.org> >>
  2013-2014 Barbie, E<lt>barbie@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

  Copyright 2004-2013 by David J. Iberri
  Copyright 2013-2014 by Barbie

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
