package WWW::IRail::API::Vehicle;
BEGIN {
  $WWW::IRail::API::Vehicle::AUTHORITY = 'cpan:ESSELENS';
}
BEGIN {
  $WWW::IRail::API::Vehicle::VERSION = '0.003';
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

    croak 'id (or vehicle) is a required argument' unless defined $attr{id} || $attr{vehicle};

    $attr{id} ||= $attr{vehicle};

    my $url = 'http://dev.api.irail.be/vehicle/?'.
                join '&', map { $_.'='.$attr{$_} } 
                qw/id/;

    my $req = new HTTP::Request(GET => $url);

    return $req;
}

sub parse_response {
    my ($http_response, $dataType) = @_;

    my $obj = XMLin($http_response->content,
        NoAttr => $dataType eq 'XML' ? 0 : 1,
        SuppressEmpty => '',
        NormaliseSpace => 2,
        ForceArray => [ 'stop' ],
        GroupTags => { stops => 'stop' },
        KeyAttr => [],
    );

    for ($dataType) {
        /xml/i and return XMLout $obj, RootName=>'vehicleinformation', GroupTags => { stops => 'stop' };
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

WWW::IRail::API::Vehicle - HTTP::Request builder and HTTP::Response parser for the IRail API Vehicle data

=head1 SYNOPSIS

    make_request( id => 'BE.NMBS.CR2089' );

=head1 DESCRIPTION

This module builds a L<HTTP::Request> and has a parser for the
L<HTTP::Response>. It's up to you to transmit it over the wire. If don't want
to do that yourself, don't use this module directly and use L<WWW::IRail::API>
instead.

=head1 METHODS

=head2 make_request( I<key => 'val'> | I<{ key => 'val' }> )

C<from> and C<to> are the only arguments required, all time and date arguments default
to the current time and date on the iRail API side.

    make_request ( id => 'BE.NMBS.CR2089' );

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

=for xml     <vehicleinformation vehicle="BE.NMBS.CR2089">
      <stops>
        <stop station="AALST" time="1291053960" />
        <stop station="EREMBODEGEM" time="1291054200" />
        <stop station="DENDERLEEUW" time="1291054500" />
        <stop station="LIEDEKERKE" time="1291054740" />
        <stop station="ESSENE LOMBEEK" time="1291054860" />
        <stop station="TERNAT" time="1291055160" />
        <stop station="SINT MARTENS BODEGEM" time="1291055340" />
        <stop station="DILBEEK" time="1291055580" />
        <stop station="GROOT BIJGAARDEN" time="1291055760" />
        <stop station="BERCHEM SAINTE AGATHE" time="1291055880" />
        <stop station="JETTE" time="1291056120" />
        <stop station="BOCKSTAEL" time="1291056300" />
        <stop station="BRUSSELS NORD" time="1291056720" />
        <stop station="BRUSSELS CENTRAL" time="1291056960" />
        <stop station="BRUSSELS MIDI" time="1291057140" />
      </stops>
    </vehicleinformation>

=head3 example of output when dataType = 'XML'

=for xml     <vehicleinformation timestamp="1291047055" version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <stops name="stop" number="15">
        <stop id="0" delay="0">
          <station id="BE.NMBS.1" locationX="4.038586" locationY="50.943053">AALST</station>
          <time formatted="2010-11-29T18:06:00Z">1291053960</time>
        </stop>
        <stop id="1" delay="0">
          <station id="BE.NMBS.162" locationX="4.055543" locationY="50.919302">EREMBODEGEM</station>
          <time formatted="2010-11-29T18:10:00Z">1291054200</time>
        </stop>
        <stop id="2" delay="0">
          <station id="BE.NMBS.136" locationX="4.071828" locationY="50.891925">DENDERLEEUW</station>
          <time formatted="2010-11-29T18:15:00Z">1291054500</time>
        </stop>
        <stop id="3" delay="0">
          <station id="BE.NMBS.323" locationX="4.095286" locationY="50.882525">LIEDEKERKE</station>
          <time formatted="2010-11-29T18:19:00Z">1291054740</time>
        </stop>
        <stop id="4" delay="0">
          <station id="BE.NMBS.170" locationX="4.115169" locationY="50.882447">ESSENE LOMBEEK</station>
          <time formatted="2010-11-29T18:21:00Z">1291054860</time>
        </stop>
        <stop id="5" delay="0">
          <station id="BE.NMBS.488" locationX="4.165342" locationY="50.874519">TERNAT</station>
          <time formatted="2010-11-29T18:26:00Z">1291055160</time>
        </stop>
        <stop id="6" delay="0">
          <station id="BE.NMBS.473" locationX="4.205081" locationY="50.867158">SINT MARTENS BODEGEM</station>
          <time formatted="2010-11-29T18:29:00Z">1291055340</time>
        </stop>
        <stop id="7" delay="0">
          <station id="BE.NMBS.142" locationX="4.243389" locationY="50.866731">DILBEEK</station>
          <time formatted="2010-11-29T18:33:00Z">1291055580</time>
        </stop>
        <stop id="8" delay="0">
          <station id="BE.NMBS.220" locationX="4.27455" locationY="50.868231">GROOT BIJGAARDEN</station>
          <time formatted="2010-11-29T18:36:00Z">1291055760</time>
        </stop>
        <stop id="9" delay="0">
          <station id="BE.NMBS.49" locationX="4.290961" locationY="50.872831">BERCHEM SAINTE AGATHE</station>
          <time formatted="2010-11-29T18:38:00Z">1291055880</time>
        </stop>
        <stop id="10" delay="0">
          <station id="BE.NMBS.282" locationX="4.328463" locationY="50.88091">JETTE</station>
          <time formatted="2010-11-29T18:42:00Z">1291056120</time>
        </stop>
        <stop id="11" delay="0">
          <station id="BE.NMBS.65" locationX="4.348507" locationY="50.879428">BOCKSTAEL</station>
          <time formatted="2010-11-29T18:45:00Z">1291056300</time>
        </stop>
        <stop id="12" delay="0">
          <station id="BE.NMBS.100" locationX="4.360854" locationY="50.859658">BRUSSELS NORD</station>
          <time formatted="2010-11-29T18:52:00Z">1291056720</time>
        </stop>
        <stop id="13" delay="0">
          <station id="BE.NMBS.95" locationX="4.357131" locationY="50.845175">BRUSSELS CENTRAL</station>
          <time formatted="2010-11-29T18:56:00Z">1291056960</time>
        </stop>
        <stop id="14" delay="0">
          <station id="BE.NMBS.98" locationX="4.336922" locationY="50.836782">BRUSSELS MIDI</station>
          <time formatted="2010-11-29T18:59:00Z">1291057140</time>
        </stop>
      </stops>
      <vehicle locationX="0" locationY="0">BE.NMBS.CR2089</vehicle>
    </vehicleinformation>

=head3 example of output when dataType = 'JSON'

=for json     {
       "stops" : [
          { "station" : "AALST", "time" : "1291053960" },
          { "station" : "EREMBODEGEM", "time" : "1291054200" },
          { "station" : "DENDERLEEUW", "time" : "1291054500" },
          { "station" : "LIEDEKERKE", "time" : "1291054740" },
          { "station" : "ESSENE LOMBEEK", "time" : "1291054860" },
          { "station" : "TERNAT", "time" : "1291055160" },
          { "station" : "SINT MARTENS BODEGEM", "time" : "1291055340" },
          { "station" : "DILBEEK", "time" : "1291055580" },
          { "station" : "GROOT BIJGAARDEN", "time" : "1291055760" },
          { "station" : "BERCHEM SAINTE AGATHE", "time" : "1291055880" },
          { "station" : "JETTE", "time" : "1291056120" },
          { "station" : "BOCKSTAEL", "time" : "1291056300" },
          { "station" : "BRUSSELS NORD", "time" : "1291056720" },
          { "station" : "BRUSSELS CENTRAL", "time" : "1291056960" },
          { "station" : "BRUSSELS MIDI", "time" : "1291057140" }
       ],
       "vehicle" : "BE.NMBS.CR2089"
    }

=head3 example of output when dataType = 'YAML'

=for YAML     ---
    stops:
      - station: AALST
        time: 1291053960
      - station: EREMBODEGEM
        time: 1291054200
      - station: DENDERLEEUW
        time: 1291054500
      - station: LIEDEKERKE
        time: 1291054740
      - station: ESSENE LOMBEEK
        time: 1291054860
      - station: TERNAT
        time: 1291055160
      - station: SINT MARTENS BODEGEM
        time: 1291055340
      - station: DILBEEK
        time: 1291055580
      - station: GROOT BIJGAARDEN
        time: 1291055760
      - station: BERCHEM SAINTE AGATHE
        time: 1291055880
      - station: JETTE
        time: 1291056120
      - station: BOCKSTAEL
        time: 1291056300
      - station: BRUSSELS NORD
        time: 1291056720
      - station: BRUSSELS CENTRAL
        time: 1291056960
      - station: BRUSSELS MIDI
        time: 1291057140
    vehicle: BE.NMBS.CR2089

=head3 example of output when dataType="perl" (default)

=for perl     $VAR1 = {
          'stops' => [
                     {
                       'station' => 'AALST',
                       'time' => '1291053960'
                     },
                     {
                       'station' => 'EREMBODEGEM',
                       'time' => '1291054200'
                     },
                     {
                       'station' => 'DENDERLEEUW',
                       'time' => '1291054500'
                     },
                     {
                       'station' => 'LIEDEKERKE',
                       'time' => '1291054740'
                     },
                     {
                       'station' => 'ESSENE LOMBEEK',
                       'time' => '1291054860'
                     },
                     {
                       'station' => 'TERNAT',
                       'time' => '1291055160'
                     },
                     {
                       'station' => 'SINT MARTENS BODEGEM',
                       'time' => '1291055340'
                     },
                     {
                       'station' => 'DILBEEK',
                       'time' => '1291055580'
                     },
                     {
                       'station' => 'GROOT BIJGAARDEN',
                       'time' => '1291055760'
                     },
                     {
                       'station' => 'BERCHEM SAINTE AGATHE',
                       'time' => '1291055880'
                     },
                     {
                       'station' => 'JETTE',
                       'time' => '1291056120'
                     },
                     {
                       'station' => 'BOCKSTAEL',
                       'time' => '1291056300'
                     },
                     {
                       'station' => 'BRUSSELS NORD',
                       'time' => '1291056720'
                     },
                     {
                       'station' => 'BRUSSELS CENTRAL',
                       'time' => '1291056960'
                     },
                     {
                       'station' => 'BRUSSELS MIDI',
                       'time' => '1291057140'
                     }
                   ],
          'vehicle' => 'BE.NMBS.CR2089'
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

