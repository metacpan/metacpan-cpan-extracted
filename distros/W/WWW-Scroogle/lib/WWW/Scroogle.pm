package WWW::Scroogle;

use strict;
use warnings;
use Carp;

use LWP;
use WWW::Scroogle::Result;

our $VERSION = '0.0135';

sub new
{
     my $class = shift;
     my $self = {
                 num_results       => $class->_default_num_results,
                 language          => $class->_default_language,
                };
     bless $self, $class;
     return $self;
}

sub _default_num_results { return 100; }

sub searchstring
{
     ref(my $self = shift)
          or croak 'instance variable needed!';
     defined($self->{searchstring})
          or croak 'no searchstring given yet!';
     return $self->{searchstring};
}

sub set_searchstring
{
     ref(my $self = shift)
          or croak 'instance variable needed!';
     defined(my $searchstring = shift)
          or croak 'no searchstring given!';
     if ($searchstring eq '') { croak 'nullstring given!' }
     $self->{searchstring} = $searchstring;
     return $self;
}

sub _default_language { return ''; }

sub language
{
     ref(my $either = shift)
          or croak 'instance variable needed!';
     if ($either->{language} eq '') {
          return 'all';
     }else {
          return $either->{language};
     }
}

sub set_language
{
     ref(my $self = shift)
          or croak 'instance variable needed!';
     my $language = shift;
     if (not defined $language) {
          $self->{language} = $self->_default_language;
     }else {
          grep{$language eq $_}$self->languages
               or croak($language.' is not a valid language! ');
          if ($language eq 'all') {
               $self->{language} = '';
          }else {
               $self->{language} = $language;
               return $self;
          }
     }
     return $self;
}

sub languages
{
     ref(my $self = shift)
          or croak 'instance variable needed!';
     if (exists $self->{languages}) {             # does $self->{languages} exist?
          return @ {$self->{languages}};          # return the array $self->{languages}
     } else {                                     # if $self->{languages} does not exist, populate it
          @ {$self->{languages}} = qw(
                                          all ar zs zt cs da nl en et fi fr de el iw
                                          hu is it ja ko lv lt no pt pl ro ru es sv tr
                                    );
          return @ {$self->{languages}};          # and return it
     }
}

sub num_results
{
     ref(my $self = shift)
          or croak 'instance variable needed!';
     return $self->{num_results};
}

sub set_num_results
{
     ref(my $self = shift)
          or croak "instance variable needed!";
     my $num_results = shift;
     if (not defined $num_results) {
          $self->{num_results} = $self->_default_num_results;
          return $self;
     }
     if (not $num_results =~ m/^\d+$/) { croak 'odd number expected!'; }
     if ($num_results < 1) { croak 'minimum is 1 result!'}
     $self->{num_results} = $num_results;
     return $self;
}

sub perform_search
{
     ref(my $self = shift)
          or croak 'instance variable needed!';
     my $searchstring = $self->searchstring;
     my $language = $self->language;
     my $num_results = $self->num_results;
     if ($self->has_results) { $self->delete_results };
     my $agent = LWP::UserAgent->new;
     my $request = HTTP::Request->new(POST => 'http://www.scroogle.org/cgi-bin/nbbw.cgi');
     $request->content_type('application/x-www-form-urlencodde');
     my $postdata;
     if ($language ne 'all') {
          $postdata = 'Gw='.$searchstring.'&n=100&l='.$language.'&z=';
     } else {
          $postdata = 'Gw='.$searchstring.'&n=100&z=';
     }
     my $niterate;
     if ($self->num_results <= 100) {
          $niterate = 1;
     }else {
          $niterate = ($num_results - $num_results%100)/100;
          if ($num_results%100 == 0) { $niterate--; }
     }
     my $results_left = $num_results;
     for (0..$niterate) {
          $request->content($postdata.$_);
          my $result = $agent->request($request);
          for (split( '\n', $result->content)) {
               if ($results_left <= 0) { last; }
               if (m/^(\d{1,5})\. <A Href="(.*)">/) {
                    $self->_add_result({
                                        position => $1,
                                        url => $2
                                       });
                    $results_left--;
               }
          }
     }
     return 1;
}

sub _add_result
{
     ref (my $self = shift)
          or croak 'instance variable needed!';
     my $options = shift;
     if (not ref $options eq "HASH") { croak 'no options hash given!'; }
     if (not exists $options->{url}) { croak 'no url given!'; }
     if (not exists $options->{position}) { croak 'no position given!'; }
     my $result = WWW::Scroogle::Result->new({
                                              url            => $options->{url},
                                              position       => $options->{position},
                                              searchstring   => $self->searchstring,
                                              language       => $self->language,
                                             });
     push @ {$self->{results}}, $result;
     return $self;
}

sub nresults
{
     ref (my $self = shift)
          or croak 'instance variable needed!';
     if ($self->has_results) {
          my $nresults = @ {$self->{results}};
          return $nresults;
     }
     croak 'no results avaible';
}

sub get_results
{
     ref (my $self = shift)
          or croak 'instance variable needed!';
     if (not $self->has_results) { croak 'no results avaible' }
     return @ {$self->{results}};
}

sub has_results
{
     ref (my $self = shift)
          or croak 'instance variable needed!';
     if (exists $self->{results}) {
          1;
     }else {
          return;
     }
}

sub delete_results
{
     ref (my $self = shift)
          or croak 'instance variable needed!';
     if ($self->has_results) {
          delete $self->{results};
          1;
     }else {
          return;
     }
}

sub get_result
{
     ref (my $self = shift)
          or croak 'instance variable needed!';
     defined (my $requested_result = shift)
          or croak 'no value given';
     if (not $self->has_results) { croak 'no results avaible'; }
     return $self->{results}[$requested_result - 1];
}

sub position
{
     ref (my $self = shift)
          or croak 'instance variable needed!';
     defined (my $string = shift)
          or croak 'no string given!';
     if (not $self->has_results) { croak 'no results avaible'; }
     for (@ {$self->{results}}) {                 # iterate over all avaible results
          if ($_->url =~ /$string/) {             # does the url match the given pattern?
               return $_->position                # return the position of the result
          }
     }
     return;                                      # return boolean false if no matches were found
}

sub positions
{
     ref (my $self = shift)
          or croak 'instance variable needed!';
     defined (my $string = shift)
          or croak 'no string given!';
     if (not $self->has_results) { croak 'no results avaible'; }
     my @results = $self->get_results_matching($string); # get array of result objects
     my @return;
     for (@results) {                             # iterate array of result objects
          push @return, $_->position;             # push the position number of that array to @return
     }
     if (scalar(@return) == 0) { return; }        # return boolean false if no matches were found
     return @return;                              # return the array of position numbers
}

sub get_results_matching
{
     ref (my $self = shift)
          or croak 'instance variable needed!';
     defined (my $string = shift)
          or croak 'no string given!';
     if (not $self->has_results) { croak 'no results avaible'; }
     my @return;
     for (@ {$self->{results}}) {                 # iterate over all avaible results
          if ($_->url =~ /$string/) {             # does the url match the given pattern?
               push @return, $_;                  # push the result object to @return
          }
     }
     if (scalar(@return) == 0) { return; }        # return boolean false if no matches were found
     return @return;                              # return the array of result objects
}
1;

__END__

=head1 NAME

WWW::Scroogle - Perl Extension for Scroogle

=head1 CAVEAT

Please note that using Scroogle.org - which this module is using (may) be a violation of Google's "Terms of Service", of which scroogle.org has been reminded. You can find the TOS at http://www.google.com/terms_of_service.html

Scroogle.org does violate the "No Automated Query" section.

The Author has searched for some easy way to get google results, he stumbled across the Google SOAP Api to which turned out to be useless because google will not give away keys to it anymore, later he found out about Googles Ajax api which turns out to be useless as you can only get the first 20results for a searchterm, now there was only one possibility left: parsing the html output of google webquerys; but while thinking about that the author realized scroogle.org, those guys have already done that job and do provide nice, clean html output which is much easier to parse than google.

To come to an end: WWW::Scroogle does one job - it provides you with usable scroogle.org search results.

=head1 SYNOPSIS

   use WWW::Scroogle;
   
   # create a new WWW::Scroogle object
   my $scroogle = WWW::Scroogle->new;
   
   # set searchstring
   $scroogle->searchstring('foobar');
   
   # get search_results
   my $results = $scroogle->get_results;
   
   # print rank of the first website whose url matches 'wikipedia'
   print $results->position(qr{wikipedia}).'\n';
   
   # get all results
   my @results = $results->get_results;
   
   # iterate over all results
   for (@results){
       print $_->url."\n";
   }

=head1 DESCRIPTION

WWW::Scroogle uses LWP to fetch the search results from scroogle and parses
the returned html output.

=head1 METHODS

=head2 WWW::Scroogle->new

Returns a new WWW::Scroogle object.

=head2 $searchstring = $scroogle->searchstring

returns the current searchstring

=head2 $scroogle->set_searchstring($searchstring)

sets $searchstring as the current searchstring

=head2 $language = $scroogle->language

returns the current Language - defaults to all

=head2 $scroogle->set_language($language)

sets $language as the current language

=head2 @languages = $scroogle->languages

Returns a list of avaible languages.

=head2 $num_results = $scroogle->num_results

Returns the current number of search results - defaults to 100

=head2 $scroogle->set_num_results

sets the number of results

=head2 $scroogle->perform_search

performs search and stores result. expects that a searchstring was set.

=head2 $scroogle->nresults

returns number of results or false if no results are avaible

=head2 $scroogle->has_results

returns true if there are stored results and false if there are no results avaible

=head2 $scroogle->delete_results

deletes all saved results

=head2 @results = $scroogle->get_results(@list_of_positions)

returns list of WWW::Scroogle::Result objects. or a list of all wanted results if list was provided

=head2 @results = $scroogle->get_results_matching( qr{example.com} )

returns a list of result-objects whose url is matching the given string or regexp

=head2 $result = $scroogle->get_result($position)

returns the requested result

=head2 $position = $scroogle->position( qr{example.com} )

returns the position (counting from 1) of the first result whose url matches the given string or regexp

=head2 @positions = $scroogle->positions( qr{example.com} )

returns a list of the positions (counting from 1) of all results whose url's are matching the given string or regexp

=head1 CREDITS

Tina Müller

Moritz Lenz

=head1 AUTHOR

Written by Lars Hartmann, <lars (at) chaotika (dot) org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Lars Hartmann, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
