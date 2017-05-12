package WebService::Careerjet;

use warnings;
use strict;

use base qw/Class::AutoAccess/;

use URI::Escape;
use LWP::UserAgent;
use HTTP::Request;
use Carp;
use JSON;

=head1 NAME

WebService::Careerjet - Perl interface to Careerjet's public job offers search API

=head1 VERSION

Version 3.1

=cut

our $VERSION = '3.1';

=head1 SYNOPSIS

This module provides a Perl interface to the public search API of Careerjet,
a vertical search engine for job offers that features job offers in over 60 countries.
(http://www.careerjet.co.uk/?worldwide)

Command line tool:

    jobsearch [ -L <lang> ] [ -d ] [ -p <pagenum> ] [ -n <num offers> ] [ -l <location> ] <keywords>
    jobsearch -h

Example code:

    use WebService::Careerjet;

    # Create Perl interface to API
    my $careerjet = WebService::Careerjet->new('en_GB');

    # Perform a search
    my $result = $careerjet->search({
                                      'keywords'   => 'perl developer',
                                      'location'   => 'london',
                                      'affid'      => '0afaf0173305e4b9',
                                      'user_ip'    => '11.22.33.44',
                                      'user_agent' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0',
                                     });

    # Go through results
    if ($result->{'type'} eq 'JOBS') {
        print "Found ". $result->{'hits'}. " jobs\n";
        my $jobs = $result->{'jobs'};

        foreach my $j(@$jobs) {
          print "URL         :".$j->{'url'}."\n";
          print "TITLE       :".$j->{'title'}."\n";
          print "COMPANY     :".$j->{'company'}."\n";
          print "SALARY      :".$j->{'salary'}."\n";
          print "DATE        :".$j->{'date'}."\n";
          print "DESCRIPTION :".$j->{'description'}."\n";
          print "SITE        :".$j->{'site'}."\n";
          print "LOCATIONS   :".$j->{'locations'}."\n";
          print "\n";
        }
    }

=head2 PROXY SETTINGS
  
 This module uses LWP::UserAgent for web access. Please refer to the LWP documentation
 for proxy settings.

=cut

=head1 FUNCTIONS

=head2 new

Creates a Webservice::Careerjet search object for a given UNIX locale.
Each locale corresponds to an existing Careerjet site and determines
which language job-related information is returned as well
as which default location filter is used. For example, if your users
are primarily Dutch-speaking Belgians use "nl_BE".

First two letters : ISO 639-1 alpha-2 language code

See http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes

Last two letters : ISO 3166-1 alpha-2 country code

See http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2


Usage:
    my $careerjet = WebService::Careerjet->new($locale);

Available locales:

    LOCALE     LANGUAGE         DEFAULT LOCATION     CAREERJET SITE
    cs_CZ      Czech            Czech Republic       http://www.careerjet.cz
    da_DK      Danish           Denmark              http://www.careerjet.dk
    de_AT      German           Austria              http://www.careerjet.at
    de_CH      German           Switzerland          http://www.careerjet.ch
    de_DE      German           Germany              http://www.careerjet.de
    en_AE      English          United Arab Emirates http://www.careerjet.ae
    en_AU      English          Australia            http://www.careerjet.com.au
    en_BD      English          Bangladesh           http://www.careerjet.com.bd
    en_CA      English          Canada               http://www.careerjet.ca
    en_CN      English          China                http://www.career-jet.cn
    en_HK      English          Hong Kong            http://www.careerjet.hk
    en_IE      English          Ireland              http://www.careerjet.ie
    en_IN      English          India                http://www.careerjet.co.in
    en_KW      English          Kuwait               http://www.careerjet.com.kw
    en_MY      English          Malaysia             http://www.careerjet.com.my
    en_NZ      English          New Zealand          http://www.careerjet.co.nz
    en_OM      English          Oman                 http://www.careerjet.com.om
    en_PH      English          Philippines          http://www.careerjet.ph
    en_PK      English          Pakistan             http://www.careerjet.com.pk
    en_QA      English          Qatar                http://www.careerjet.com.qa
    en_SG      English          Singapore            http://www.careerjet.sg
    en_GB      English          United Kingdom       http://www.careerjet.co.uk
    en_US      English          United States        http://www.careerjet.com
    en_ZA      English          South Africa         http://www.careerjet.co.za
    en_SA      English          Saudi Arabia         http://www.careerjet-saudi-arabia.com
    en_TW      English          Taiwan               http://www.careerjet.com.tw 
    en_VN      English          Vietnam              http://www.careerjet.vn
    es_AR      Spanish          Argentina            http://www.opcionempleo.com.ar
    es_BO      Spanish          Bolivia              http://www.opcionempleo.com.bo
    es_CL      Spanish          Chile                http://www.opcionempleo.cl
    es_CO      Spanish          Colombia             http://www.opcionempleo.com.co
    es_CR      Spanish          Costa Rica           http://www.opcionempleo.co.cr
    es_DO      Spanish          Dominican Republic   http://www.opcionempleo.com.do
    es_EC      Spanish          Ecuador              http://www.opcionempleo.ec
    es_ES      Spanish          Spain                http://www.opcionempleo.com
    es_GT      Spanish          Guatemala            http://www.opcionempleo.com.gt
    es_MX      Spanish          Mexico               http://www.opcionempleo.com.mx
    es_PA      Spanish          Panama               http://www.opcionempleo.com.pa
    es_PE      Spanish          Peru                 http://www.opcionempleo.com.pe
    es_PR      Spanish          Puerto Rico          http://www.opcionempleo.com.pr
    es_PY      Spanish          Paraguay             http://www.opcionempleo.com.py
    es_UY      Spanish          Uruguay              http://www.opcionempleo.com.uy
    es_VE      Spanish          Venezuela            http://www.opcionempleo.com.ve
    fi_FI      Finnish          Finland              http://www.careerjet.fi
    fr_CA      French           Canada               http://www.option-carriere.ca
    fr_BE      French           Belgium              http://www.optioncarriere.be
    fr_CH      French           Switzerland          http://www.optioncarriere.ch
    fr_FR      French           France               http://www.optioncarriere.com
    fr_LU      French           Luxembourg           http://www.optioncarriere.lu
    fr_MA      French           Morocco              http://www.optioncarriere.ma
    hu_HU      Hungarian        Hungary              http://www.careerjet.hu
    it_IT      Italian          Italy                http://www.careerjet.it
    ja_JP      Japanese         Japan                http://www.careerjet.jp
    ko_KR      Korean           Korea                http://www.careerjet.co.kr
    nl_BE      Dutch            Belgium              http://www.careerjet.be
    nl_NL      Dutch            Netherlands          http://www.careerjet.nl
    no_NO      Norwegian        Norway               http://www.careerjet.no
    pl_PL      Polish           Poland               http://www.careerjet.pl
    pt_PT      Portuguese       Portugal             http://www.careerjet.pt
    pt_BR      Portuguese       Brazil               http://www.careerjet.com.br
    ru_RU      Russian          Russia               http://www.careerjet.ru
    ru_UA      Russian          Ukraine              http://www.careerjet.com.ua
    sv_SE      Swedish          Sweden               http://www.careerjet.se
    sk_SK      Slovak           Slovakia             http://www.careerjet.sk
    tr_TR      Turkish          Turkey               http://www.careerjet.com.tr
    uk_UA      Ukrainian        Ukraine              http://www.careerjet.ua
    vi_VN      Vietnamese       Vietnam              http://www.careerjet.com.vn
    zh_CN      Chinese          China                http://www.careerjet.cn


=head2 agent

Gets/sets the LWP::UserAgent to be used in the API calls.

Usage:

    $this->agent();
    $this->agent($myAgent);

=cut

sub new {
  my ($class, $locale) = @_;
  $locale ||= 'en_GB';

  my $ua = LWP::UserAgent->new();
  $ua->agent('careerjet-api-client-v' . $VERSION . '-perl-v' . $]);

  my $self = {
    'locale' => $locale,
    'agent'  => $ua,
    'debug'  => 0,
  };

  return bless $self, $class;
}

=head2 debug

Enables/disables debug mode

Usage:

    ## enable debug mode
    $careerjet->debug(1);

    ## disable debug mode
    $careerjet->debug(0);

=cut

sub _call {
  my ($self, $function, $args) = @_;

  my $url = "http://public.api.careerjet.net/$function?locale_code=" . $self->{locale};
  foreach my $k (keys %$args) {
    $url .= '&' . $k . '=' . URI::Escape::uri_escape_utf8($args->{$k});
  }

  print "GETTING " . $url . "\n" if ($self->debug());
  my $req = HTTP::Request->new('GET' => $url);

  my $ret = undef;

  my $res = $self->{'agent'}->request($req);
  if ($res->is_success()) {
    my $content = $res->content();
    my $json    = new JSON;
    $ret = $json->decode($content);
  } else {
    $ret->{'type'}  = 'ERROR';
    $ret->{'error'} = $res->status_line();
  }

  unless (defined $ret) {
    $ret = {
      'type'  => 'ERROR',
      'error' => 'Json parsing error'
    };
  }

  return $ret;

}

=head2 search

Performs a search using Careerjet's public search API.
Search parameters are passed on as a reference to a hash.

The end-users IP address and user agent are mandatory parameters.
Also a Careerjet affiliate ID is required.

Example:
    
    my $result = $api->search({
                                 'keywords' => 'perl developer',
                                 'location' => 'london',
                                 'user_ip'    => '11.22.33.44',
                                 'user_agent' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:37.0) Gecko/20100101 Firefox/37.0',
                              });

    # The result is a job list if the location is not ambiguous
    if ($result->{'type'} eq 'JOBS') {
        print "Found ". $result->{'hits'}. " jobs\n";
        print "Total number of result pages: ". $result->{'pages'}. "\n";
        my $jobs = $result->{'jobs'};
        foreach my $j (@$jobs) {
            print "URL         :".$j->{'url'}."\n";
            print "TITLE       :".$j->{'title'}."\n";
            print "COMPANY     :".$j->{'company'}."\n";
            print "SALARY      :".$j->{'salary'}."\n";
            print "DATE        :".$j->{'date'}."\n";
            print "DESCRIPTION :".$j->{'description'}."\n";
            print "SITE        :".$j->{'site'}."\n";
            print "\n" ;
        }
    
    }

    # If the location is ambiguous, a list of suggested locations
    # is returned
    if ($result->{'type'} eq 'LOCATIONS') {
        print "Suggested locations:\n" ;
        my $locations = $result->{'solveLocations'};
        foreach my $l (@$locations) {
            print $l->{'name'}."\n" ; ## For end-user display
            ## Use $l->{'location_id'} when making next search call
            ## as 'location_id' parameter (see parameters below)
        }
    }

Mandatory parameters:

       affid        :   Affiliate ID provided by Careerjet. Requires to open a Careerjet partner
                        account (http://www.careerjet.com/partners/).

       user_ip      :   IP address of the end-user to whom the search results will be displayed.

       user_agent   :   User agent of the end-user's browser.
   
Options:

   All options have default values and are not mandatory
   
       keywords     :   Keywords to match either title, content or company name of job offer
                        Examples: 'perl developer', 'ibm', 'software architect'
                        Default : none
   
       location     :   Location of requested job postings.
                        Examples: 'London' , 'Yorkshire', 'France' 
                        Default: country specified by country code

       location_id  :   Location ID. Use values comming from the search function when location is ambiguous.
                        Default: none
   
       sort         :   Type of sort. This can be:
                         'relevance'  - sorted by decreasing relevancy (default)
                         'date'       - sorted by decreasing date
                         'salary'     - sorted by decreasing salary
   
       start_num    :   Position of returned job postings within the entire result space.
                        This should be a least 1 but not more than the total number of job offers.
                        Default : 1
   
       pagesize     :   Number of returned results
                        Default : 20

       page         :   Page number of returned job postings within the entire result space.
                        This can be used instead of start_num. The minimum page number is 1.
                        The maximum number of pages is given by $result->{'pages'}
                        If this value is set, it overrides start_num.
   
       contracttype :   Selected contract type. The following codes can be used: 
                         'p'    - permanent
                         'c'    - contract
                         't'    - temporary
                         'i'    - training
                         'v'    - voluntary
                        Default: none (all contract types)
       
       contractperiod : Selected contract period. The following codes can be used: 
                         'f'     - full time
                         'p'     - part time
                        Default: none (all contract periods)

      
=cut

sub search {
  my ($self, $args) = @_;
  my $ret = $self->_call('search', $args);

  if ($ret->{'type'} eq 'ERROR') {
    confess "CAREERJET ERROR: " . $ret->{'error'};
  }
  return $ret;
}

=head1 AUTHORS

Thomas Busch (version 0.13 onwards)

Jerome Eteve (version 0.01-0.12)

=head1 FEEDBACK

Any feedback is welcome. Please send your suggestions to <api at careerjet.com>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2015 Careerjet Ltd. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

1;    # End of WebService::Careerjet
