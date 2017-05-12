package WWW::TasteKid;

#$Id$
# /* vim:et: set ts=4 sw=4 sts=4 tw=78: */

use 5.008001;    # require perl 5.8.1 or later
use warnings;
use strict;

#use criticism 'brutal';

use version; our $VERSION = qv('0.1.3');

use Readonly;
use XML::LibXML ();    # qw/:libxml/; # :all :libxml, :encoding :w3c
use Carp qw/croak/;
use Encode qw/encode/;
use LWP::Simple qw/get/;
use Data::Dumper qw/Dumper/;
use Scalar::Util qw/refaddr/;
use URI::Escape qw/uri_escape/;
use HTML::Entities qw/decode_entities/;
use Class::InsideOut qw/public private/;

# should probably be using moose, just seems like
# overkill for a module this simple/small

use WWW::TasteKidResult;

Readonly my $API_URL => 'http://www.tastekid.com/ask/ws?q=';

private query_store      => my %query_store;
public set_xml_result    => my %xml_result;
public get_xml_result    => %xml_result;
public get_encoded_query => my %encoded_query;

sub new {
    my $class = shift;
    my $self = bless \do { my $s }, $class;

    Class::InsideOut::register($self);

    $xml_result{ refaddr $self }    = undef;
    $encoded_query{ refaddr $self } = undef;
    $query_store{ refaddr $self }   = undef;

    return $self;
}

sub query {
    my ( $self, $arg_ref ) = @_;

    if ( !$arg_ref->{'name'} ) {
        croak 'name argument is mandatory';
    }

    if ( !exists $query_store{'query'} ) {
        $query_store{'query'} = [];
    }

    push @{ $query_store{'query'} }, $arg_ref;

    return;
}

sub query_inspection {
    print Dumper $query_store{'query'};
}

sub ask {
    my ( $self, $arg_ref ) = @_;

    my $query_str = q{};
    foreach my $q ( @{ $query_store{'query'} } ) {
        my $t = $q->{'type'} || q{};
        my $n = $q->{'name'} || q{};

        if ($t) {
            $query_str .= "$t:";
        }

        if ($n) {
            $query_str .= "$n,";
        }
    }

    # purge queries list
    delete $query_store{ refaddr $self };

    $query_str =~ s/\,\z//xms;

    my $query = $API_URL . uri_escape($query_str);

    if ( $arg_ref->{'filter'} )  { $query .= "//$arg_ref->{'filter'}" }
    if ( $arg_ref->{'verbose'} ) { $query .= '&verbose=1' }

    $encoded_query{ refaddr $self } = $query;

    my $r = get($query);

    if ( !$r ) { croak qq{unable to get $query} }

    $self->set_xml_result($r);

    return;

}

sub info_resource {
    my ($self) = @_;
    return $self->_common_resource('info');
}

sub results_resource {
    my ($self) = @_;
    return $self->_common_resource('results');
}

sub _common_resource {
    my ( $self, $elem ) = @_;

    if ( caller ne 'WWW::TasteKid' ) { croak 'private method'; }

    my @return_req = ();

    my $parser = XML::LibXML->new();

    my $tstkd_xml = $parser->parse_string( $self->get_xml_result );

    my $xml_root = $tstkd_xml->documentElement;

    if (  !$xml_root
        || $xml_root->nodeName ne 'similar' )
    {
        croak 'unknown file format recieved, cannot continue';
    }

    return _parse_response( $xml_root, $elem );
}

sub _parse_response {
    my ( $xml_root, $elem ) = @_;

    if ( caller ne 'WWW::TasteKid' ) { croak 'private method'; }

    my $results_ref = [];

    #TODO 3 nested foreach?! geez, refactor me
    foreach my $node ( $xml_root->childNodes ) {

        #warn $node->toString;

        #next unless $node->nodeName eq $elem;
        if ( $node->nodeName ne $elem ) { next }

        foreach my $c_node ( $node->childNodes ) {
            if ( $c_node->nodeName eq 'resource' ) {

                my $tkr = WWW::TasteKidResult->new;
                foreach my $cc_node ( $c_node->childNodes ) {

                    #next unless $tkr->can( lc $cc_node->nodeName );
                    if ( !$tkr->can( lc $cc_node->nodeName ) ) { next }

                    my $text_content = $cc_node->textContent;
                    $text_content = encode( 'utf8', $text_content );

                    $text_content = decode_entities($text_content);

                    my $method_name = lc $cc_node->nodeName;
                    $tkr->$method_name($text_content);

                }
                push @{$results_ref}, $tkr;
            }
        }
    }
    return $results_ref;
}

1;

__END__

=head1 NAME

WWW::TasteKid - A Perl interface to the API of TasteKid.com

=head1 VERSION

Version 0.1.3


=head1 SYNOPSIS

    NOTE: Their terms of service have changed you need to send them a 
    API use request first: http://www.tastekid.com/ask/page/api_request

    use WWW::TasteKid;

    my $tskd = WWW::TasteKid->new;

    # let's find new music to explore based on our interest in Bach (music)
    $tskd->query({ type => 'music', name => 'bach' });
    $tskd->ask;

    my $res = $tc->results_resource;

    foreach my $r (@{$res}){
        print $r->name,"\n";
    }

    #output: (something similiar to)
    George Frideric Handel
    Joseph Haydn
    Johannes Brahms
    Franz Schubert
    Claudio Monteverdi
    Arcangelo Corelli
    Antonio Vivaldi
    Robert Schumann
    Henry Purcell
    Felix Mendelssohn
    Wolfgang Amadeus Mozart
    Gustav Mahler
    Thomas Tallis
    Richard Strauss
    Richard Wagner
    Edvard Grieg
    Giuseppe Verdi
    Igor Stravinsky
    Franz Liszt
    Maurice Ravel
    Olivier Messiaen
    Sergei Prokofiev

=head1 DESCRIPTION

   TasteKid.com, Get suggestions of similar or related music
   (mainly bands), movies (titles mostly, some directors and actors)
   and books. Simply put, "I can help you explore your taste". 

   Potentially discover a new band (movie/book) in the 
   same 'ilk' as a currently known one.

(From the TasteKid.com website)

TasteKid suggests similar or related music (mainly bands), movies (titles mostly,
some directors and actors) and books. 

Recommendations you might be interested in if you like what you tell me 
that you like :P 

Simply put, I can help you explore your taste.

How to search?

The simplest way is to write down in the big text input your favorite band,
artist, movie or book, and hit "Enter" or click "Suggest".


  Via WWW::TasteKid API:

  my $tskd = WWW::TasteKid->new;

  $tskd->query({ name => 'bach' });

  $tskd->ask;

  foreach my $r (@{ $tskd->results_resource }){
      print $r->name,"\n";
  }


Telling me about more than one thing.
You can search by giving me as input more that one band, movie or book,
using the "," operator. Example: harry potter, lord of the rings.


  Via WWW::TasteKid API:

  $tskd->query({ name => 'harry potter' });

  $tskd->query({ name => 'lord of the rings' });

  $tskd->query({ name => 'bach' });

  $tskd->ask;



The remember/forget option
Especially if you've entered many bands, movies and books, to better
describe your taste and get more recommendations, it is likely you would
prefer to save your search, so you wouldn't have to re-type it next time you
visit me. For this purpose, each search can be remembered, if you click the
"Remember" link underneath the big search text input. One thing though, you
can only have me remember one search at a time.


  Via WWW::TasteKid API;
  Not (Yet) Implemented


Telling me the type of your input
Sometimes you might want to specify the type of your input (is it a band, is
it a movie, is it a book). You can do this by using the "band:" (music), 
"movie:" or "book:: operators.
Examples: band:underworld, movie:harry potter, book:trainspotting.


  Via WWW::TasteKid API:

  $tskd->query({ type => 'music', name => 'underworld' });

  $tskd->query({ type => 'movie', name => 'harry potter' });

  $tskd->query({ type => 'book', name => 'trainspotting' });

  $tskd->ask;


Telling me the type of results you prefer
If you want me to provide a certain type of results, you can tell me this by
using the "//bands", "//movies" and "//books" operators, at the end of your
query.
Examples: the beatles//movies, fight club//music, pulp fiction//books.


  Via WWW::TasteKid API:

  $tskd->query({ name => 'the beatles' });

  $tskd->ask({ filter => 'movies' });

  #process results,...

  # new query

  $tskd->query({ name => 'fight club' });

  $tskd->ask({ filter => 'music' });

  #process results,...

  # new query

  $tskd->query({ name => 'pulp fiction' });

  $tskd->ask({ filter => 'books', verbose => 1 });

  #process results,...


Of course, you can combine all these parameters, in order to better describe
your taste and help me come up with more relevant recommendations.
Example: movie:harry potter, book:harry potter//music.


  Via WWW::TasteKid API:

  # one query
  $tskd->query({ type => 'movie', name => 'the beatles' });

  $tskd->query({ type => 'music', name => 'fight club' });

  $tskd->query({ type => 'books', name => 'pulp fiction' });

  $tskd->ask({ filter => 'music', verbose => 1 });



additional info: 
L<http://www.tastekid.com/ask/aboutme>

=head1 OVERVIEW

TasteKid.com - Potentially discover a new band (movie/book) in the same 
ilk as a current favorite

(Similar 'in theory' to pandora.com and Apple's iTunes 'Genius')

See 'Description' above

=head1 USAGE

See Synopsis

Also see examples/examples.pl and t/06* included with the distribution.
(available from the CPAN if not included on your system)

=head1 SUBROUTINES/METHODS

An object of this class represents an TasteKid API query

=head2 new

  my $taste_kid = WWW::TasteKid->new; 

  Create a new WWW::TasteKid Object; 

  Takes no arguments

=head2 ask 

  $taste_kid->ask( $opts_hash_ref );

  queries the TasteKid API

  arguments are optional. if supplied, is a hash reference.

  verbose - boolean  // $taste_kid->ask( { verbose => 1 });

  filter - only return results who's 'type' (see query) matches the filter

           possibilites are: music, movies or books.

          // $taste_kid->ask( { filter => 'music' });

=head2 query 

  arguments: (a hash reference)

  'name' is required. 
  'type' argument is optional.
         if specified can be one of: 'music, movie, book'

  name specifies the term you are sending to TasteKid to get related
  suggestions about.

  There can only be one name per query, however you can have many queries
  per single request, example:

   $tskd->query({ name => 'bach' }); # 'bach' is obvious, type will default
                                     # to music

   $tskd->query({ type => 'movie', name => 'amadeus' });

   $tskd->query({ type => 'book',  name => 'star trek' });

   $tskd->query({ type => 'movie',  name => 'star wars' });

   $tskd->astk({ verbose => 1 });


=head2 get_xml_result

  $tastekid->get_xml_result;

  will return the most recent request from 'ask' (see above) in 
  the TasteKid XML format.

  this method is public but not really useful to the end user unless you want 
  to parse the xml result yourself ;)

=head2 info_resource

    takes no arguments.

    returns the info part of your request. 
    (i.e. what was determined to be your query and was sent to 
      'ask' as your query requst)

    the results returned are a L<TasteKidResult> object. 
    (see L<TasteKidResult> for available methods. 
    Current available public methods are: name, type, wteaser, 
    wurl, ytitle, yurl)

    my $tastekid = WWW::TasteKid->new;

    # single requst example
    $tastekid->query({ name => 'bach' });

    $tastekid->ask;

    my $res = $tastekid->info_resource;

    #output
    print $res->[0]->name # Johann Sebastian Bach
    print $res->[0]->type # music

    # a multi requst example
    $tastekid->query({ name => 'bach' });

    $tastekid->query({ name => 'haydn' });

    $tastekid->query({ name => 'brahms' });

    $tastekid->ask({ verbose => 1 });

    $res = $tastekid->info_resource;

    print $res->[1]->name; # 'Joseph Haydn';

    print $res->[2]->name; # 'Johannes Brahms';

    print $res->[2]->type; # 'music';

    print $res->[2]->wteaser; # wikipedia page if exists

    print $res->[2]->wurl; # wikipedia link used

    print $res->[2]->ytitle; # youtube title of video if exists

    print $res->[2]->yurl; # youtube video if exists


=head2 results_resource

    identical usage as info_resource except returns the actual 
    suggestions returned by the TasteKid API. These are the results
    you are probably most interested in ;)

    my $tastekid = WWW::TasteKid->new;

    $tastekid->query({ name => 'bach' });

    $tastekid->ask;

    my $results = $tastekid->results_resource;

    foreach my $tkr (@{$results}) {
        print $tkr->name,"\n";
        print $tkr->type,"\n";
        print $tkr->wteaser,"\n";
        print $tkr->wurl,"\n";
        print $tkr->ytitle,"\n";
        print $tkr->yurl,"\n";
    }

=head2 query_inspection

     used for debugging. 'dump' the query that will be sent to the TasteKid
     API.

=head1 DIAGNOSTICS

None currently known


=head1 CONFIGURATION AND ENVIRONMENT

if you are running perl > 5.8.1 and have access to
install cpan modules, you should have no problem installing this module

no special configuration used

=head1 DEPENDENCIES

WWW::TasteKid uses the following modules:

L<XML::LibXML>

L<LWP::Simple>

L<URI::Escape>

L<Readonly>

L<Carp>

L<Data::Dumper>

L<criticism> (pragma - enforce Perl::Critic if installed)

L<version>(pragma - version numbers)

L<Test::More>

L<File::Basename>

L<Scalar::Util>

L<Encode>

L<Class::InsideOut>

L<WWW::TasteKidResult> (comes bundled)


there shouldn't be any restrictions on versions of the above modules, as long
as you have a relatively new perl > 5.0008
most of these are in the standard Perl distribution, otherwise they are common 
enough to be pre packaged for your operating systems package system or easily
downloaded and installed from the CPAN.


=head1 INCOMPATIBILITIES


none known of

=head1 SEE ALSO

L<http://www.tastekid.com/>


=head1 AUTHOR

David Wright, C<< <david_v_wright at yahoo.com> >>


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-www-tastekid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-TasteKid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::TasteKid


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-TasteKid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-TasteKid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-TasteKid>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-TasteKid>

=back

=head1 TODO

potentially a remember/forget option

=begin comment

  do this by env/$ENV{HOME} maybe,... (and windows)
  keep a history file of saved searches when the 'remember' param passed
  would clean it out with 'forget' (for same search term)
  would have a 'load_cache', or 'search_memory' or something to display
  the remembered history, not sure... just brainstorming

=end comment

addtl features, possibly some sort of 'enable send' suggestions?


=head1 ACKNOWLEDGEMENTS

Some acronyms utilized while making of this module:

PBP

TDD

OOP

vim

this module was created with module-starter

module-starter --module=WWW::TasteKid \
        --author="David Wright" --email=david_v_wright@yahoo.com


=head1 LICENSE AND COPYRIGHT

Copyright 2009 David Wright, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::TasteKid




