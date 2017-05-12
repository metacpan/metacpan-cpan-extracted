# Translator.pm
# by Jim Smyser
# Copyright (C) 2000 by Jim Smyser 
# $Id: Translator.pm,v 1.02 2000/06/08 11:09:07 jims Exp $


package WWW::Search::Translator;

=head1 NAME

WWW::Search::Translator - class for Translating languages 


=head1 SYNOPSIS

  use WWW::Search;
  %opts = (
  lp => param(en_de),
  );
 $query = "a whole bunch of english text to be translated to german";
 my $search = new WWW::Search('Translator');
 $search->native_query(WWW::Search::escape_query($query),\%opts);
  while (my $result = $search->next_result())
    { 
    $p = $result->raw;
    print "$p"; 
    }

=head1 DESCRIPTION

This is a simple no thrills class enabling users to translate
text through AV Translations F<http://babel.altavista.com>.
This translating via this method seems much faster than thru
browser interface. Makes a neat addition to any web page. 
Translated text is returned thru $result->raw, there is no
url's or title $results like typical WWW::Search results, just
a stream of text that was translated from the query text entered.

SEE TRANSLATION OPTIONS and TIPS.

This class exports no public interface; all interaction should
be done through WWW::Search objects.

=head1 TRANSLATION OPTIONS

Pass either of the below listed value options along with the 
query. There is only one $result returnd by this backend: raw. 
Thus, translated text will be returnd via $result->raw

<option value="en_fr" >English to French</option>
<option value="en_de" >English to German</option>
<option value="en_it" >English to Italian</option>
<option value="en_pt" >English to Portuguese</option>
<option value="en_es" >English to Spanish</option>
<option value="fr_en" >French to English</option>
<option value="de_en" >German to English</option>
<option value="it_en" >Italian to English</option>
<option value="pt_en" >Portuguese to English</option>
<option value="es_en" >Spanish to English</option>
<option value="de_fr" >German to French</option>
<option value="fr_de" >French to German</option>
<option value="ru_en" >Russian to English</option>

=head1 TIPS

I would use textarea for both user input and printing 
$result->url into. This way users can scroll the returned
text and have large area to type/paste text for input.

=head1 CHANGES

VERSION 1.02

Got time to go back and look at what was needed to parse multi
lines of the text area. Everything looks OK now and this 
backend will parse single and multi lines of translated text.

=head1 AUTHOR

C<WWW::Search::Translator> is written and maintained
by Jim Smyser - <jsmyser@bigfoot.com>.

=head1 COPYRIGHT

WWW::Search Copyright (c) 1996-1998 University of Southern California.
All rights reserved.                                            
                                                               
THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut
#'

#####################################################################
require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw();
@ISA = qw(WWW::Search Exporter);
$VERSION = '1.02';

use Carp ();
use WWW::Search(qw(generic_option strip_tags));
use URI::Escape;

require WWW::SearchResult;

sub native_setup_search {

        my($self, $native_query, $native_options_ref) = @_;
        $self->{_debug} = $native_options_ref->{'search_debug'};
        $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
        $self->{_debug} = 0 if (!defined($self->{_debug}));
        $self->{agent_e_mail} = 'jsmyser@bigfoot.com';
        $self->user_agent('user');
        $native_query =~ s/\n+/ /g;
        if (!defined($self->{_options})) {
        $self->{_options} = {
              'search_url' => 'http://babel.altavista.com/translate.dyn',
              'urltext' =>  $native_query,
              'user' => 'avworld',
              'lp'=> 'en_fr' # default
              };
              }
        my $options_ref = $self->{_options};
        if (defined($native_options_ref))
              {
        # Copy in new options.
        foreach (keys %$native_options_ref)
              {
        $options_ref->{$_} = $native_options_ref->{$_};
              }
              }
        # Process the options.
        my($options) = '';
        foreach (sort keys %$options_ref)
              {
        next if (generic_option($_));
        $options .= $_ . '=' . $options_ref->{$_} . '&';
              }
        chop $options;
        $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $self->hash_to_cgi_string($self->{_options});
              }

sub native_retrieve_some {
        my ($self) = @_;
        print STDERR "**Translating......\n" if $self->{_debug};
            
        # Fast exit if already done:
        return undef if (!defined($self->{_next_url}));
            
        # Get some:
        print STDERR "**Requesting (",$self->{_next_url},")\n" if $self->{_debug};
        my($response) = $self->http_request('POST', $self->{_next_url});
        $self->{response} = $response;
        if (!$response->is_success)
              {
           return undef;
              }
        $self->{'_next_url'} = undef;
        print STDERR "**Found Some\n" if $self->{_debug};
        # parse the output
        my ($HEADER, $HITS, $HIT1, $GET, $END) = qw(HE HI H1 GT EN);
        my $state = $HEADER;
        my $hit = ();
        my($raw) = '';
        my $hits_found = 0;
        foreach ($self->split_lines($response->content()))
              {
        next if m@^$@; # short circuit for blank lines
        print STDERR " * $state ===$_=== " if 2 <= $self->{'_debug'};

     # If AV returning many lines we have to do it this way
     if (m|</font></b></td>|i) {
       #print STDERR "**Beginning Line...\n" ;
       $state = $HITS;
       # if AV returning single line then it will have to be picked 
       #  up this way
  } elsif (m@^<form action=.*?method=get>@i) {
       $state = $HIT1;
              } 
        if ($state eq $HIT1 && m@^<font face=fixed><textarea.*?name="q">@i) 
              {
         $state = $GET;
              } 
        elsif ($state eq $GET && m@^(.+)@i) 
              {
           if (defined($hit))
              {
            push(@{$self->{cache}}, $hit);
              };
        $hit = new WWW::SearchResult;
        $raw .= $_;
        $hit->raw($raw);
        $state = $END;
        # If results are multi lines we have to do this
  } elsif ($state eq $HITS && m@^<td bgcolor=white>(.*)@i) {
       if (defined($hit)) 
         {
        push(@{$self->{cache}}, $hit);
         };
        $hit = new WWW::SearchResult;
        $raw .= $_ . " ";
        $raw =~ s/<.*?>//g;
        $hit->raw($raw);
        $state = $HITS;
        # Pick up all the text lines till we encounter a tag
  } elsif ($state eq $HITS && m@^(.*?)@i) {
        $raw .= $_ . " " if (not $raw =~ /<\//);
        $hit->raw($raw) if (not $raw =~ /<\//);
        $state = $HITS;
  } elsif ($state eq $HITS && m/^<\//) {
        #done
             } 
          else 
              {
        print STDERR "Nothing Seems Translated\n" if 2 <= $self->{_debug};
              }
              } 
           if (defined($hit)) 
              {
   push(@{$self->{cache}}, $hit);
              }
            return $hits_found;
              } 
1;

