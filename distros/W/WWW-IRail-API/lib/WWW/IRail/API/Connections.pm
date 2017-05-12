package WWW::IRail::API::Connections;
BEGIN {
  $WWW::IRail::API::Connections::AUTHORITY = 'cpan:ESSELENS';
}
BEGIN {
  $WWW::IRail::API::Connections::VERSION = '0.003';
}
use strict;

use Carp qw/croak/;
use Date::Format;
use DateTime::Format::Natural;
use HTTP::Request::Common;
use JSON::XS;
use XML::Simple;
use YAML qw/freeze/;


sub make_request {
    my %attr = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    croak 'from is a required argument' unless defined $attr{from};
    croak 'to is a required argument' unless defined $attr{to};

    # reformat several different date input formats
    if ($attr{date} =~ m/^\d+$/ ) { $attr{date} = time2str( "%d%m%y", $attr{data} ) }
    elsif ($attr{date} =~ m/^\d{2}(\d{2})\W?(\d{2})\W?(\d{2})$/) {  $attr{data} = "$3$2$1" }

    # reformat time input formats
    if ($attr{date} =~ m/(\d{2})\W?(\d{2})/) { $attr{date} = "$1$2" }
    
    # if date contains words, try to parse it as natural language
    if ($attr{date} =~ m/\w/) {
        my $dateparser = new DateTime::Format::Natural(prefer_future => 1);
        my $dt = $dateparser->parse_datetime( $attr{date} );
        if($dateparser->success) { 
            $attr{'date'} = sprintf("%02d%02d%02d", $dt->day, $dt->month, substr($dt->year,2,2) );
            $attr{'time'} = sprintf("%02d%02d", $dt->hour, $dt->min);
        }
    }

    croak 'date could not be parsed' unless $attr{date} =~ m/^\d{6}$/ and int($attr{date}) != 0;

    my $url = 'http://dev.api.irail.be/connections/?'.
                join '&', map { $_.'='.$attr{$_} } 
                qw/from to date time/;

    my $req = new HTTP::Request(GET => $url);

    return $req;
}

sub parse_response {
    my ($http_response, $dataType) = @_;

    my $obj = XMLin($http_response->content,
        NoAttr => $dataType eq 'XML' ? 0 : 1,
        SuppressEmpty => '',
        NormaliseSpace => 2,
        ForceArray => [ 'connection','via' ],
        KeepRoot => $dataType =~ /XML/i ? 0 : 1,
        GroupTags => { connections => 'connection', vias => 'via' },
        KeyAttr => [],
    );

    for ($dataType) {
        /xml/i and return XMLout $obj, RootName=>'connections',KeepRoot => 0, GroupTags => { connections => 'connection', vias => 'via' };
        /json/i and return JSON::XS->new->ascii->pretty->allow_nonref->encode($obj);
        /yaml/i and return freeze $obj;
        /perl/i and return $obj;
    }

    return $obj; # default to perl

}

42;



=pod

=head1 VERSION

version 0.003

=head1 NAME

WWW::IRail::API::Connections - HTTP::Request builder and HTTP::Response parser for the IRail API (Train)Connection data

=head1 SYNOPSIS

    make_request( from => 'brussel noord', to => 'oostende' );

=head1 DESCRIPTION

This module builds a L<HTTP::Request> and has a parser for the
L<HTTP::Response>. It's up to you to transmit it over the wire. If don't want
to do that yourself, don't use this module directly and use L<WWW::IRail::API>
instead.

=head1 METHODS

=head2 make_request( I<key => 'val'> | I<{ key => 'val' }> )

C<from> and C<to> are the only arguments required, all time and date arguments default
to the current time and date on the iRail API side.

    make_request (
        from    => 'oostende',
        to      => 'brussel noord',
        date    => '2010-11-28' || '20101128' || 'tomorrow afternoon',   
        time    => '6:24' || 1290922133,        
    );

=head2 parse_response( I<$http_response>, I<dataType> )

parses the HTTP::Response you got back from the server, which if all went well contains XML.
That XML is then transformed into other data formats

=over 4

=item *

xml

=item *

XML

=item *

YAML

=item *

JSON

=item *

perl (default)

=back

=head3 example of output when dataType = 'xml'

=head1 METHODS

=begin xml

  <connections>
    <connection duration="4860">
      <arrival platform="3" station="OOSTENDE" time="1290932220" vehicle="BE.NMBS.IC529" />
      <departure platform="NA" station="BRUXELLES NORD" time="1290927360" vehicle="BE.NMBS.IC529" />
    </connection>
    <connection duration="5040">
      <arrival platform="7" station="OOSTENDE" time="1290934020" vehicle="BE.NMBS.IC829" />
      <departure platform="4" station="BRUXELLES NORD" time="1290928980" vehicle="BE.NMBS.IC1529" />
      <vias>
        <via station="BRUGGE" timeBetween="300" vehicle="BE.NMBS.IC1529">
          <arrival platform="5" time="1290932940" />
          <departure platform="7" time="1290933240" />
        </via>
      </vias>
    </connection>

    <!-- snip -->

  </connections>

=end xml

=head3 example of output when dataType = 'XML'

=begin xml

    <connections timestamp="1290926300" version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="connections.xsd">
      <connection id="0" duration="4860">
        <arrival delay="0" vehicle="BE.NMBS.IC529">
          <platform normal="1">3</platform>
          <station id="BE.NMBS.410" location="51.226518 2.927904" locationX="2.927904" locationY="51.226518">OOSTENDE</station>
          <time formatted="2010-11-28T08:17:00Z">1290932220</time>
        </arrival>
        <departure delay="0" vehicle="BE.NMBS.IC529">
          <platform normal="1">NA</platform>
          <station id="BE.NMBS.100" location="50.859658 4.360854" locationX="4.360854" locationY="50.859658">BRUXELLES NORD</station>
          <time formatted="2010-11-28T06:56:00Z">1290927360</time>
        </departure>
      </connection>
      <connection id="1" duration="5040">
        <arrival delay="0" vehicle="BE.NMBS.IC829">
          <platform normal="1">7</platform>
          <station id="BE.NMBS.410" location="51.226518 2.927904" locationX="2.927904" locationY="51.226518">OOSTENDE</station>
          <time formatted="2010-11-28T08:47:00Z">1290934020</time>
        </arrival>
        <departure delay="0" vehicle="BE.NMBS.IC1529">
          <platform normal="1">4</platform>
          <station id="BE.NMBS.100" location="50.859658 4.360854" locationX="4.360854" locationY="50.859658">BRUXELLES NORD</station>
          <time formatted="2010-11-28T07:23:00Z">1290928980</time>
        </departure>
        <vias name="via" number="1">
          <via id="0" timeBetween="300" vehicle="BE.NMBS.IC1529">
            <arrival platform="5">
              <time formatted="2010-11-28T08:29:00Z">1290932940</time>
            </arrival>
            <departure platform="7">
              <time formatted="2010-11-28T08:34:00Z">1290933240</time>
            </departure>
            <station id="BE.NMBS.85" location="51.197225 3.216728" locationX="3.216728" locationY="51.197225">BRUGGE</station>
          </via>
        </vias>
      </connection>

      <!-- snip -->
    </connections>

=end xml

=head3 example of output when dataType = 'JSON'

=begin json

  {
   "connections" : [
      {
         "duration" : "4860",
         "departure" : {
            "station" : "BRUXELLES NORD",
            "time" : "1290927360",
            "vehicle" : "BE.NMBS.IC529",
            "platform" : "NA"
         },
         "arrival" : {
            "station" : "OOSTENDE",
            "time" : "1290932220",
            "vehicle" : "BE.NMBS.IC529",
            "platform" : "3"
         }
      },
      {
         "duration" : "5040",
         "departure" : {
            "station" : "BRUXELLES NORD",
            "time" : "1290928980",
            "vehicle" : "BE.NMBS.IC1529",
            "platform" : "4"
         },
         "vias" : [
            {
               "station" : "BRUGGE",
               "timeBetween" : "300",
               "vehicle" : "BE.NMBS.IC1529",
               "departure" : {
                  "time" : "1290933240",
                  "platform" : "7"
               },
               "arrival" : {
                  "time" : "1290932940",
                  "platform" : "5"
               }
            }
         ],
         "arrival" : {
            "station" : "OOSTENDE",
            "time" : "1290934020",
            "vehicle" : "BE.NMBS.IC829",
            "platform" : "7"
         }
      },

      // ... snip ...
   ]
  }

=end json

=head3 example of output when dataType = 'YAML'

=for YAML  ---
 connections:
  - arrival:
      platform: 3
      station: OOSTENDE
      time: 1290932220
      vehicle: BE.NMBS.IC529
    departure:
      platform: NA
      station: BRUXELLES NORD
      time: 1290927360
      vehicle: BE.NMBS.IC529
    duration: 4860
  - arrival:
      platform: 7
      station: OOSTENDE
      time: 1290934020
      vehicle: BE.NMBS.IC829
    departure:
      platform: 4
      station: BRUXELLES NORD
      time: 1290928980
      vehicle: BE.NMBS.IC1529
    duration: 5040
    vias:
      - arrival:
          platform: 5
          time: 1290932940
        departure:
          platform: 7
          time: 1290933240
        station: BRUGGE
        timeBetween: 300
        vehicle: BE.NMBS.IC1529

=head3 example of output when dataType="perl" (default)

=for perl   $VAR1 = {
          'connections' => [
                           {
                             'duration' => '5040',
                             'departure' => {
                                            'station' => 'BRUXELLES NORD',
                                            'time' => '1290928980',
                                            'vehicle' => 'BE.NMBS.IC1529',
                                            'platform' => '4'
                                          },
                             'arrival' => {
                                          'station' => 'OOSTENDE',
                                          'time' => '1290934020',
                                          'vehicle' => 'BE.NMBS.IC829',
                                          'platform' => '7'
                                        }
                             'vias' => [
                                       {
                                         'station' => 'BRUGGE',
                                         'timeBetween' => '300',
                                         'vehicle' => 'BE.NMBS.IC1529',
                                         'departure' => {
                                                        'time' => '1290933240',
                                                        'platform' => '7'
                                                      },
                                         'arrival' => {
                                                      'time' => '1290932940',
                                                      'platform' => '5'
                                                    }
                                       }
                                     ],
                           },
            ]
    };

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Tim Esselens <tim.esselens@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Tim Esselens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

