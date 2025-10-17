package WebService::Careerjet;

use strict;
use warnings;

use base qw/Class::AutoAccess/;

use URI::Escape;
use LWP::UserAgent;
use HTTP::Request;
use Carp;
use JSON;

=head1 NAME

WebService::Careerjet - Perl interface to Careerjet's public job search API

=head1 VERSION

Version 4.2

=cut

our $VERSION = '4.2';

=head1 SYNOPSIS

This module provides a Perl interface to the public search API of Careerjet,
a vertical search engine for job offers that features job offers in over 60 countries.
(https://www.careerjet.com/sites)

An API key will be required which you can get when by opening a partner account
with Careerjet ((https://www.careerjet.com/partners/).

Code example:

    use WebService::Careerjet;

    # Create Perl interface to API
    my $careerjet = WebService::Careerjet->new('en_GB', "<API_KEY>");

    # Perform a search
    my $result = $careerjet->query({
                                     'keywords'   => 'perl developer',
                                     'location'   => 'london',
                                     'user_ip'    => '11.22.33.44',
                                     'user_agent' => 'Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0',
                                     'referrer'   => 'https://www.example.com/jobs/search?s=perl+developer&l=london',
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
          print "LOCATIONS   :".$j->{'locations'}."\n";
          print "\n";
        }
    }

=cut

=head1 FUNCTIONS

=head2 new

Creates a Webservice::Careerjet API client object for a given UNIX locale
and API key.

The API key is mandatory and is provided by Careerjet when you open a partner
account (https://www.careerjet.com/partners/).

Each locale corresponds to an existing Careerjet site and determines
which language job-related information is returned as well
as which default location filter is used. For example, if your users
are primarily Dutch-speaking Belgians use "nl_BE".

First two letters : ISO 639-1 alpha-2 language code

See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes

Last two letters : ISO 3166-1 alpha-2 country code

See https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2


Usage:
    my $careerjet = WebService::Careerjet->new($locale, $api_key);

Available locales:

    LOCALE     LANGUAGE         DEFAULT LOCATION     CAREERJET SITE
    cs_CZ      Czech            Czech Republic       https://www.careerjet.cz
    da_DK      Danish           Denmark              https://www.careerjet.dk
    de_AT      German           Austria              https://www.careerjet.at
    de_CH      German           Switzerland          https://www.careerjet.ch
    de_DE      German           Germany              https://www.careerjet.de
    en_AE      English          United Arab Emirates https://www.careerjet.ae
    en_AU      English          Australia            https://www.careerjet.com.au
    en_BD      English          Bangladesh           https://www.careerjet.com.bd
    en_CA      English          Canada               https://www.careerjet.ca
    en_CN      English          China                https://www.career-jet.cn
    en_HK      English          Hong Kong            https://www.careerjet.hk
    en_IE      English          Ireland              https://www.careerjet.ie
    en_IN      English          India                https://www.careerjet.co.in
    en_KW      English          Kuwait               https://www.careerjet.com.kw
    en_MY      English          Malaysia             https://www.careerjet.com.my
    en_NZ      English          New Zealand          https://www.careerjet.co.nz
    en_OM      English          Oman                 https://www.careerjet.com.om
    en_PH      English          Philippines          https://www.careerjet.ph
    en_PK      English          Pakistan             https://www.careerjet.com.pk
    en_QA      English          Qatar                https://www.careerjet.com.qa
    en_SG      English          Singapore            https://www.careerjet.sg
    en_TH      English          Thai                 https://www.career-jet.co.th
    en_GB      English          United Kingdom       https://www.careerjet.co.uk
    en_US      English          United States        https://www.careerjet.com
    en_ZA      English          South Africa         https://www.careerjet.co.za
    en_SA      English          Saudi Arabia         https://www.careerjet.com.sa
    en_TW      English          Taiwan               https://www.careerjet.com.tw 
    en_VN      English          Vietnam              https://www.careerjet.vn
    es_AR      Spanish          Argentina            https://www.opcionempleo.com.ar
    es_BO      Spanish          Bolivia              https://www.opcionempleo.com.bo
    es_CL      Spanish          Chile                https://www.opcionempleo.cl
    es_CO      Spanish          Colombia             https://www.opcionempleo.com.co
    es_CR      Spanish          Costa Rica           https://www.opcionempleo.co.cr
    es_DO      Spanish          Dominican Republic   https://www.opcionempleo.com.do
    es_EC      Spanish          Ecuador              https://www.opcionempleo.ec
    es_ES      Spanish          Spain                https://www.opcionempleo.com
    es_GT      Spanish          Guatemala            https://www.opcionempleo.com.gt
    es_MX      Spanish          Mexico               https://www.opcionempleo.com.mx
    es_PA      Spanish          Panama               https://www.opcionempleo.com.pa
    es_PE      Spanish          Peru                 https://www.opcionempleo.com.pe
    es_PR      Spanish          Puerto Rico          https://www.opcionempleo.com.pr
    es_PY      Spanish          Paraguay             https://www.opcionempleo.com.py
    es_UY      Spanish          Uruguay              https://www.opcionempleo.com.uy
    es_VE      Spanish          Venezuela            https://www.opcionempleo.com.ve
    fi_FI      Finnish          Finland              https://www.careerjet.fi
    fr_CA      French           Canada               https://www.option-carriere.ca
    fr_BE      French           Belgium              https://www.optioncarriere.be
    fr_CH      French           Switzerland          https://www.optioncarriere.ch
    fr_FR      French           France               https://www.optioncarriere.com
    fr_LU      French           Luxembourg           https://www.optioncarriere.lu
    fr_MA      French           Morocco              https://www.optioncarriere.ma
    hu_HU      Hungarian        Hungary              https://www.careerjet.hu
    it_IT      Italian          Italy                https://www.careerjet.it
    ja_JP      Japanese         Japan                https://www.careerjet.jp
    ko_KR      Korean           Korea                https://www.careerjet.co.kr
    nl_BE      Dutch            Belgium              https://www.careerjet.be
    nl_NL      Dutch            Netherlands          https://www.careerjet.nl
    no_NO      Norwegian        Norway               https://www.careerjet.no
    pl_PL      Polish           Poland               https://www.careerjet.pl
    pt_PT      Portuguese       Portugal             https://www.careerjet.pt
    pt_BR      Portuguese       Brazil               https://www.careerjet.com.br
    ru_RU      Russian          Russia               https://www.careerjet.ru
    ru_UA      Russian          Ukraine              https://www.careerjet.com.ua
    sv_SE      Swedish          Sweden               https://www.careerjet.se
    sk_SK      Slovak           Slovakia             https://www.careerjet.sk
    th_TH      Thailand         Thai                 https://www.careerjet.co.th
    tr_TR      Turkish          Turkey               https://www.careerjet.com.tr
    uk_UA      Ukrainian        Ukraine              https://www.careerjet.ua
    vi_VN      Vietnamese       Vietnam              https://www.careerjet.com.vn
    zh_CN      Chinese          China                https://www.careerjet.cn


=head2 agent

Gets/sets the LWP::UserAgent to be used in the API calls.

This is useful for custom proxy, timeout or username settings.

Usage:

    $this->agent();
    $this->agent($myAgent);

=cut

sub new {
  my ($class, $locale, $api_key) = @_;
  $locale ||= 'en_GB';
  $api_key ||= '';

  my $ua = LWP::UserAgent->new();
  $ua->agent('careerjet-api-client-v' . $VERSION . '-perl-v' . $]);

  my $self = {
    'locale' => $locale,
    'agent'  => $ua,
    'api_key' => $api_key,
    'is_legacy_mode' => ($api_key) ? 0 : 1,
  };

  return bless $self, $class;
}

=head2 query

Performs a search query using Careerjet's public search API.
Search parameters are passed on as a reference to a hash.

The end-users IP address and user agent are mandatory parameters.

Example:
    
    my $result = $api->query({
                                 'keywords'   => 'perl developer',
                                 'location'   => 'london',
                                 'user_ip'    => '11.22.33.44',
                                 'user_agent' => 'Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0',
                                 'referrer'   => 'https://www.example.com/jobs/search?s=perl+developer&l=london',
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

       user_ip      :   IP address of the end-user to whom the search results will be displayed.

       user_agent   :   User agent of the end-user's browser.

       referrer     :   Web page that the user is currently viewing and that triggered this job search.
   
Options:

   All options have default values and are not mandatory
   
       keywords     :   Keywords to match either title, content or company name of job offer
                        Examples: 'perl developer', 'ibm', 'software architect'
                        Default : none
   
       location     :   Location of requested job postings.
                        Examples: 'London' , 'Yorkshire', 'France' 
                        Default: country specified by country code

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
   
       contract_type :  Selected contract type. The following codes can be used: 
                         'p'    - permanent
                         'c'    - contract
                         't'    - temporary
                         'i'    - training
                         'v'    - voluntary
                        Default: none (all contract types)
       
       work_hours :     Selected work hours. The following codes can be used: 
                         'f'     - full time
                         'p'     - part time
                        Default: none (all work hours)

      
=cut

sub query {
  my ($self, $args) = @_;

  my $url;
  if ($self->is_legacy_mode) {
    $url = "http://public.api.careerjet.net/search?locale_code=" . $self->{locale};
  } else {
    $url = "http://search.api.careerjet.net/v4/query?locale_code=" . $self->{locale};
  }

  if ($self->is_legacy_mode && !$args->{affid}) {
    return {
      type => 'ERROR',
      error => "You haven't supplied an API key, so legacy mode is assumed. " .
               "In this case your legacy Careerjet affiliate ID needs to be supplied as 'affid' parameter."
    };
  }

  foreach my $k (keys %$args) {
    $url .= '&' . $k . '=' . URI::Escape::uri_escape_utf8($args->{$k});
  }

  my $req = HTTP::Request->new('GET' => $url);
  $req->authorization_basic($self->api_key, '');

  my $res = $self->{'agent'}->request($req);
  my $content = $res->content();

  my $ret;
  eval {
    $ret = decode_json($content);
  };

  if (!$res->is_success() && !defined $ret) {
    $ret->{'type'}  = 'ERROR';
    $ret->{'error'} = $res->status_line();
  }

  return $ret;

}

=head2 search

Alternative name for 'query' for backwards compatibility reasons

=cut

sub search {
  my ($self, $args) = @_;
  return $self->query($args);
}

=head1 AUTHORS

Thomas Busch (version 0.13 onwards)

Jerome Eteve (version 0.01-0.12)

=head1 FEEDBACK

Any feedback is welcome. Please send your suggestions to <api at careerjet.com>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2025 Careerjet Limited. All rights reserved.

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
