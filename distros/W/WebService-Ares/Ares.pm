package WebService::Ares;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use HTTP::Request;
use LWP::UserAgent;

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# User agent.
	$self->{'agent'} = 'WebService::Ares/'.$VERSION;

	# Debug.
	$self->{'debug'} = 0;

	# Params.
	set_params($self, @params);

	# Commands.
	$self->{'commands'} = {
		'standard' => {
			'attr' => [
				'ic',
			],
			'method' => 'GET',
			'url' => 'http://wwwinfo.mfcr.cz/cgi-bin/ares'.
				'/darv_std.cgi',
		},
	};

	# Error string.
	$self->{'error'} = undef;

	# User agent.
	$self->{'ua'} = LWP::UserAgent->new;
	$self->{'ua'}->agent($self->{'agent'});

	# Object.
	return $self;
}

# Get web service commands.
sub commands {
	my $self = shift;
	return sort keys %{$self->{'commands'}};
}

# Get error.
sub error {
	my ($self, $clean) = @_;
	my $error = $self->{'error'};
	if ($clean) {
		$self->{'error'} = undef;
	}
	return $error;
}

# Get data.
sub get {
	my ($self, $command, $def_hr) = @_;

	# Get XML data.
	my $data = $self->get_xml($command, $def_hr);

	# Parse XML.
	my $data_hr;
	if ($command eq 'standard') {
		require WebService::Ares::Standard;
		$data_hr = WebService::Ares::Standard::parse($data);
	}

	# Result.
	return $data_hr;
}

# Get XML file.
sub get_xml {
	my ($self, $command, $def_hr) = @_;

	# Command structure.
	my $c_hr = $self->{'commands'}->{$command};

	# Create url.
	my $url = $c_hr->{'url'};
	foreach my $key (keys %{$def_hr}) {
		# TODO Control
		# TODO Better create.
		if ($key eq 'ic') {
			$url .= '?ico='.$def_hr->{$key};
		}
	}

	# Get XML data.
	return $self->_get_page($c_hr->{'method'}, $url);
}

# Get page.
sub _get_page {
	my ($self, $method, $url) = @_;

	# Debug.
	if ($self->{'debug'}) {
		print "Method: $method\n";
		print "URL: $url\n";
	}

	# Request.
	my $req;
	if ($method eq 'GET') {
		$req = HTTP::Request->new('GET' => $url);
	} else {
		err "Method '$method' is unimplemenited.";
	}

	# Response.
	my $res = $self->{'ua'}->request($req);

	# Get page.
	if ($res->is_success) {
		return $res->content;
	} else {
		$self->{'error'} = $res->status_line;
		return;
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::Ares - Perl class to communication with ARES service.

=head1 SYNOPSIS

 use WebService::Ares;

 my $obj = WebService::Ares->new(%parameters);
 my @commands = $obj->commands;
 my $error = $obj->error($clean);
 my $data_hr = $obj->get($command, $def_hr);
 my $xml_data = $obj->get_xml($command, $def_hr);

=head1 DESCRIPTION

 ARES - "Administrativní registr ekonomických subjektů" is Czech information system of Ministry of Finance.

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor.

=over 8

=item * C<agent>

 User agent setting.
 Default is 'WebService::Ares/$VERSION'.

=item * C<debug>

 Debug mode flag.
 Default is 0.

=back

=item C<commands()>

 Get web service commands.
 Returns array of commands.

=item C<error($clean)>

 Get error.
 When $clean variable is present, cleans internal error variable.
 Returns string with error or undef.

=item C<get($command, $def_hr)>

 Get data for command '$command' and definitition defined in $dev_hr reference of hash.
 Possible definition keys are:
 - ic - company identification number.
 Returns reference to hash with data or undef as error.

=item C<get_xml($command, $def_hr)>

 Get XML data for command '$command' and definition defined in $dev_hr reference to hash.
 Possible definition keys are:
 - ic - company identification number.
 Returns string with XML data or undef as error.

=back

=head1 ERRORS

 get():
         Method '%s' is unimplemented.

 get_xml():
         Method '%s' is unimplemented.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use WebService::Ares;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 ic\n";
         exit 1;
 }
 my $ic = $ARGV[0];

 # Object.
 my $obj = WebService::Ares->new;

 # Get data.
 my $data_hr = $obj->get('standard', {'ic' => $ic});

 # Print data.
 p $data_hr;

 # Output:
 # Usage: /tmp/8PICXQSYF3 ic

 # Output with (44992785) arguments:
 # \ {
 #     address       {
 #         district     "Brno-město",
 #         num          196,
 #         num2         1,
 #         psc          60200,
 #         street       "Dominikánské náměstí",
 #         town         "Brno",
 #         town_part    "Brno-město",
 #         town_urban   "Brno-střed"
 #     },
 #     create_date   "1992-07-01",
 #     firm          "Statutární město Brno",
 #     ic            44992785
 # }

=head1 EXAMPLE2

 use strict;
 use warnings;

 use WebService::Ares;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 ic\n";
         exit 1;
 }
 my $ic = $ARGV[0];

 # Object.
 my $obj = WebService::Ares->new;

 # Get data.
 my $data_xml = $obj->get_xml('standard', {'ic' => $ic});

 # Print data.
 print $data_xml."\n";

 # Output:
 # Usage: /tmp/8PICXQSYF3 ic

 # Output with (44992785) arguments:
 # <?xml version="1.0" encoding="UTF-8"?>
 # <are:Ares_odpovedi
 # xmlns:are="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer/v_1.0.1"
 # xmlns:dtt="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_datatypes/v_1.0.4"
 # xmlns:udt="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/uvis_datatypes/v_1.0.1"
 # odpoved_datum_cas="2014-08-18T07:43:50" odpoved_pocet="1" odpoved_typ="Standard"
 # vystup_format="XML" xslt="klient"
 # validation_XSLT="/ares/xml_doc/schemas/ares/ares_answer/v_1.0.0/ares_answer.xsl"
 # xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 # xsi:schemaLocation="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer/v_1.0.1
 # http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer/v_1.0.1/ares_answer_v_1.0.1.xsd"
 # Id="ares">
 # <are:Odpoved>
 # <are:Pocet_zaznamu>1</are:Pocet_zaznamu>
 # <are:Typ_vyhledani>FREE</are:Typ_vyhledani>
 # <are:Zaznam>
 # <are:Shoda_ICO>
 # <dtt:Kod>9</dtt:Kod>
 # </are:Shoda_ICO>
 # <are:Vyhledano_dle>ICO</are:Vyhledano_dle>
 # <are:Typ_registru>
 # <dtt:Kod>3</dtt:Kod>
 # <dtt:Text>RES</dtt:Text>
 # </are:Typ_registru>
 # <are:Datum_vzniku>1992-07-01</are:Datum_vzniku>
 # <are:Datum_platnosti>2014-08-18</are:Datum_platnosti>
 # <are:Pravni_forma>
 # <dtt:Kod_PF>801</dtt:Kod_PF>
 # </are:Pravni_forma>
 # <are:Obchodni_firma>Statutární město Brno</are:Obchodni_firma>
 # <are:ICO>44992785</are:ICO>
 # <are:Identifikace>
 # <are:Adresa_ARES>
 # <dtt:ID_adresy>314885828</dtt:ID_adresy>
 # <dtt:Kod_statu>203</dtt:Kod_statu>
 # <dtt:Nazev_okresu>Brno-město</dtt:Nazev_okresu>
 # <dtt:Nazev_obce>Brno</dtt:Nazev_obce>
 # <dtt:Nazev_casti_obce>Brno-město</dtt:Nazev_casti_obce>
 # <dtt:Nazev_mestske_casti>Brno-střed</dtt:Nazev_mestske_casti>
 # <dtt:Nazev_ulice>Dominikánské náměstí</dtt:Nazev_ulice>
 # <dtt:Cislo_domovni>196</dtt:Cislo_domovni>
 # <dtt:Typ_cislo_domovni>1</dtt:Typ_cislo_domovni>
 # <dtt:Cislo_orientacni>1</dtt:Cislo_orientacni>
 # <dtt:PSC>60200</dtt:PSC>
 # <dtt:Adresa_UIR>
 # <udt:Kod_oblasti>60</udt:Kod_oblasti>
 # <udt:Kod_kraje>116</udt:Kod_kraje>
 # <udt:Kod_okresu>3702</udt:Kod_okresu>
 # <udt:Kod_obce>582786</udt:Kod_obce>
 # <udt:Kod_casti_obce>411582</udt:Kod_casti_obce>
 # <udt:Kod_mestske_casti>550973</udt:Kod_mestske_casti>
 # <udt:PSC>60200</udt:PSC>
 # <udt:Kod_ulice>22829</udt:Kod_ulice>
 # <udt:Cislo_domovni>196</udt:Cislo_domovni>
 # <udt:Typ_cislo_domovni>1</udt:Typ_cislo_domovni>
 # <udt:Cislo_orientacni>1</udt:Cislo_orientacni>
 # <udt:Kod_adresy>19095597</udt:Kod_adresy>
 # <udt:Kod_objektu>18945341</udt:Kod_objektu>
 # <udt:PCD>649906</udt:PCD>
 # </dtt:Adresa_UIR>
 # </are:Adresa_ARES>
 # </are:Identifikace>
 # <are:Priznaky_subjektu>NNAANANANNAANNNNNNNNPNNNANNNNN</are:Priznaky_subjektu>
 # </are:Zaznam>
 # </are:Odpoved>
 # </are:Ares_odpovedi>

=head1 EXAMPLE3

 use strict;
 use warnings;

 use WebService::Ares;

 # Object.
 my $obj = WebService::Ares->new;

 # Get commands.
 my @commands = $obj->commands;

 # Print commands.
 print join "\n", @commands;
 print "\n";

 # Output:
 # standard

=head1 DEPENDENCIES

L<Ares::Standard>,
L<Class::Utils>,
L<Error::Pure>,
L<HTTP::Request>,
L<LWP::UserAgent>.

=head1 SEE ALSO

=over

=item L<WebService::Ares::Standard>

Perl XML::Parser parser for Ares standard XML file.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/WebService-Ares>

=head1 AUTHOR

Michal Josef Špaček L<skim@cpan.org>

=head1 LICENSE AND COPYRIGHT

 © Michal Josef Špaček 2009-2020
 BSD 2-Clause License

=head1 VERSION

0.03

=cut
