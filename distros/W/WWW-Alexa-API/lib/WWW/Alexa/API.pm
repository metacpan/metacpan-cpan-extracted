package WWW::Alexa::API;
use strict;
use warnings FATAL => 'all';

BEGIN {
  use Exporter ();
  use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  $VERSION     = '0.07';
  @ISA         = qw(Exporter);
  #Give a hoot don't pollute, do not export more than needed by default
  @EXPORT      = qw();
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = ();
}

use LWP::UserAgent;
use XML::Hash::LX;

sub new {
  my ($class, %parameters) = @_;
  my $self;

  $self->{ua} = LWP::UserAgent->new(agent => $parameters{agent} || 'Opera 10.0') or return;
  $self->{ua}->proxy('http', $parameters{proxy}) if $parameters{proxy};
  $self->{ua}->timeout($parameters{timeout}) if $parameters{timeout};
  $self->{ua}->default_header('X-Real-IP', $parameters{ip_address}) if $parameters{ip_address};

  $self->{alexa} = ();

  bless ($self, $class);
  return $self;
}

sub get {
  my ($self, $domain_url) = @_;
  return unless defined $domain_url;

  my $res = $self->{ua}->get("http://xml.alexa.com/data?cli=10&dat=snbamz&url=$domain_url");
  return $res->status_line if !$res->is_success;

  my $res_hash = XML::Hash::LX::xml2hash($res->content);

  $self->{alexa} = \%{$res_hash->{ALEXA}} if \%{$res_hash->{ALEXA}};
  return \%{$self->{alexa}};
}


#################### main pod documentation begin ###################

=head1 NAME

WWW::Alexa::API - A class implementation interface for querying Alexa.com for Traffic information.

=head1 SYNOPSIS

  use WWW::Alexa::API;
  my $alexa = WWW::Alexa::API->new();
  my $alexa_response = $alexa->get('example.com');

=head1 DESCRIPTION

The C<WWW::Alexa::API> is a class implementation interface for
querying Alexa.com for Traffic information. This offers the full Alexa
API response in a hash object. See "OUTPUT" for the structure of the response.

To use it, you should create a C<WWW::Alexa::API> object and
use its method to get(), to query information for a domain.

=head1 USAGE

my $alexa = WWW::Alexa::API->new(%options);
my $alexa_response = $alexa->get('alexa.com');
my $alexa_rank = $alexa_response->{SD}[1]->{POPULARITY}->{-TEXT};
if (defined $alexa_response->{DMOZ}) {
  ## Has DMOZ
}

This method constructs a new C<WWW::Alexa::API> object and returns it.
Key/value pair arguments can be provided to set up an initial user agent.
The following options allow specific attributes for C<LWP::UserAgent>

KEY DEFAULT
------------ --------------------
agent "Opera 10.0"
proxy undef
timeout undef
ip_address undef


C<agent> specifies the header 'User-Agent' when querying Alexa. If
the C<proxy> option is passed in, requests will be made through
specified proxy. C<proxy> is the host which serve requests to Alexa.
C<ip_address> allows you to set an X-Real-IP header for C<LWP::UserAgent>.

=head1 OUTPUT

$VAR1 = {
  '-URL' => 'alexa.com/',
  '-VER' => '0.9',
  '-HOME' => '0',
  '-IDN' => 'alexa.com/',
  'RLS' => {
    'RL' => [
      {
        '-TITLE' => 'Open Directory Project',
        '-HREF' => 'dmoz.org/'
      }, {
        '-TITLE' => 'Internet Archive',
        '-HREF' => 'archive.org/'
      }, {
        '-TITLE' => 'Wiki - AboutUs Wiki Page',
        '-HREF' => 'aboutus.org/'
      }, {
        '-TITLE' => 'Ask.com',
        '-HREF' => 'www.ask.com/'
      }, {
        '-TITLE' => 'StatCounter.com',
        'HREF' => 'statcounter.com/'
      }, {
        '-TITLE' => 'Statbrain.com',
        '-HREF' => 'statbrain.com/'
      }, {
        '-TITLE' => 'SiteSell.com',
        '-HREF' => 'sitesell.com/'
      }, {
        '-TITLE' => 'Site Meter - Counter And Statistics Tracker',
        '-HREF' => 'sitemeter.com/'
      }, {
        '-TITLE' => "\x{631}\x{62a}\x{628}: \x{62a}\x{631}\x{62a}\x{64a}\x{628} \x{627}\x{644}\x{645}\x{648}\x{627}\x{642}\x{639} \x{627}\x{644}\x{639}\x{631}\x{628}\x{64a}\x{629}",
        '-HREF' => 'ratteb.com/'
      }, {
        '-TITLE' => 'Quantcast',
        '-HREF' => 'quantcast.com/'
      }, {
        '-TITLE' => 'www.amazon.com/',
        '-HREF' => 'www.amazon.com/'
      }
    ],
   '-more' => '65',
   '-PREFIX' => 'http://'
  },
  '-AID' => '=',
  'KEYWORDS' => {
    'KEYWORD' => [
      { 
        '-VAL' => 'Opportunities' 
      }, {
        '-VAL' => 'Partners Programs'
      }, {
        '-VAL' => 'Amazon Associates Program'
      }
    ]
  },
  'DMOZ' => {
    'SITE' => {
      '-DESC' => 'Alexa is the leading provider of free, global web metrics. Search Alexa to discover the most successful sites on the web by keyword, category, or country. Use our analytics for competitive analysis, benchmarking, market research, or business development. Use Alexa\'s Pro tools to optimize your company\'s presence on the web.',
      '-TITLE' => 'Alexa Internet',
      '-BASE' => 'alexa.com/',
      'CATS' => {
        'CAT' => {
          '-ID' => 'Top/Computers/Internet/Statistics_and_Demographics/Internet_Traffic',
          '-CID' => '374841',
          '-TITLE' => 'Statistics and Demographics/Internet Traffic'
        }
      }
    }
  },
  'SD' => [
    {
      'COUNTRY' => {
        '-CODE' => 'US'
      },
      '-TITLE' => 'A',
      '-FLAGS' => 'DMOZ',
      'CHILD' => {
        '-SRATING' => '0'
      },
      'SPEED' => {
        '-TEXT' => '1611',
        '-PCT' => '52'
      },
      'LINKSIN' => {
        '-NUM' => '358113'
      },
      'ASSOCS' => {
        'ASSOC' => {
          '-ID' => 'alexashopping-9'
        }
      },
      'CREATED' => {
        '-MONTH' => '07',
        '-DAY' => '17',
        '-YEAR' => '1996',
        '-DATE' => '17-Jul-1996'
      },
      'CERTIFIED' => {
        '-DATE' => '2013-12-03T00:00:03Z'
      },
      'ADDR' => {
        '-COUNTRY' => 'USA',
        '-ZIP' => '94129',
        '-STATE' => 'CA',
        '-CITY' => 'San Francisco',
        '-STREET' => 'Presidio of San Francisco,  PO Box 29141'
      },
      'LANG' => {
        '-LEX' => 'en'
      },
      'SITEDATA' => {
        '-DISPLAY' => '7'
      },
      'REVIEWS' => {
        '-NUM' => '939',
        '-AVG' => '4.5'
      },
      'CLAIMED' => {
        '-DATE' => '2013-12-06T11:00:10Z'
      },
      'TICKER' => {
        '-SYMBOL' => 'AMZN'
      },
      'ALEXAPRO' => {
        '-TIER' => 'advanced'
      },
      'LINK' => [
        {
          '-NUM' => '1',
          '-TEXT' => 'Alexa Products',
          '-URL' => 'http://www.alexa.com/products'
        },
        {
          '-NUM' => '2',
          '-TEXT' => 'Alexa Toolbar Creator',
          '-URL' => 'http://www.alexa.com/toolbar-creator'
        }
      ],
      '-HOST' => 'alexa.com',
      'EMAIL' => {
        '-ADDR' => 'Alexa Internet'
      },
      'TITLE' => {
        '-TEXT' => 'Alexa Internet'
      },
      'LOGO' => {
        '-URL' => 'http://s3.amazonaws.com/com.alexa.data/fr_logo_url/205_4c67c060c607f3c93208e7d0f3aa00d1.png'
      },
      'OWNER' => {
        '-NAME' => 'Alexa Internet'
      },
      'PHONE' => {
        '-NUMBER' => 'unlisted'
      }
    },
    {
      'COUNTRY' => {
        '-RANK' => '1700',
        '-NAME' => 'United States',
        '-CODE' => 'US'
      },
      'POPULARITY' => {
        '-TEXT' => '1502',
        '-URL' => 'alexa.com/',
        '-SOURCE' => 'certify'
      },
      'REACH' => {
        '-RANK' => '1458'
      },
      'RANK' => {
        '-DELTA' => '+237'
      }
    }
  ]
};

=head1 BUGS

All bugs can be reported to https://github.com/rijvirajib/WWW-Alexa-API

Some users report issues installing XML::Hash::LX

C<sudo apt-get install libxml-libxml-perl zlib1g-dev>

=head1 SUPPORT

Support requests can be sent to https://github.com/rijvirajib/WWW-Alexa-API

=head1 AUTHOR

    Rijvi Rajib
    CPAN ID: RIJ
    Cyphrd
    cpan @ rij.co
    http:/www.rij.co

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################

1;