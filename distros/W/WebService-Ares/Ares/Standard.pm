package WebService::Ares::Standard;

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use English;
use Error::Pure qw(err);
use Readonly;
use XML::Parser;

# Constants.
Readonly::Array our @EXPORT_OK => qw(parse);
Readonly::Scalar my $EMPTY_STR => q{};

# Version.
our $VERSION = 0.02;

# Parse XML string.
sub parse {
	my $xml = shift;

	# XML::Parser object.
	my $data_hr = {};
	my $parser = XML::Parser->new(
		'Handlers' => {
			'Start' => \&_xml_tag_start,
			'End' => \&_xml_tag_end,
			'Char' => \&_xml_char,
		},
		'Non-Expat-Options' => {
			'data' => $data_hr,
			'stack' => [],
		},
	);

	# Parse.
	eval {
		$parser->parse($xml);
	};
	if ($EVAL_ERROR) {
		my $err = $EVAL_ERROR;
		$err =~ s/^\n+//msg;
		chomp $err;
		err 'Cannot parse XML string.',
			'XML::Parser error', $err;
	}

	# Return structure.
	return $data_hr;
}

# Parsed data stack check function.
sub _check_stack {
	my ($expat, $tag) = @_;
	my $stack_ar = $expat->{'Non-Expat-Options'}->{'stack'};
	foreach my $i (reverse (0 .. $#{$stack_ar})) {
		if ($stack_ar->[$i]->{'tag'} eq $tag) {
			return $stack_ar->[$i]->{'attr'};
		}
	}
	return;
}

# Parsed data stack peek function.
sub _peek_stack {
	my $expat = shift;
	if (defined $expat->{'Non-Expat-Options'}->{'stack'}->[-1]) {
		my $tmp_hr = $expat->{'Non-Expat-Options'}->{'stack'}->[-1];
		return ($tmp_hr->{'tag'}, $tmp_hr->{'attr'});
	} else {
		return ($EMPTY_STR, {});
	}
}

# Parsed data stack pop function.
sub _pop_stack {
	my $expat = shift;
	my $tmp_hr = pop @{$expat->{'Non-Expat-Options'}->{'stack'}};
	return ($tmp_hr->{'tag'}, $tmp_hr->{'attr'});
}

# Parsed data stack push function.
sub _push_stack {
	my ($expat, $tag, $attr) = @_;
	my $tmp_hr = {};
	$tmp_hr->{'tag'}  = $tag;
	$tmp_hr->{'attr'} = $attr;
	push @{$expat->{'Non-Expat-Options'}->{'stack'}}, $tmp_hr;
	return;
}

# Characters handler.
sub _xml_char {
	my ($expat, $text) = @_;

	# Drop empty strings.
	if ($text =~ m/^\s*$/sm) {
		return;
	}

	# Get actual tag name.
	my ($tag_name) = _peek_stack($expat);

	# Process data.
	if ($tag_name eq 'are:ICO') {
		_save($expat, $text, 'ic');
	} elsif ($tag_name eq 'are:Obchodni_firma') {
		_save($expat, $text, 'company');		
	} elsif ($tag_name eq 'are:Datum_vzniku') {
		_save($expat, $text, 'create_date');
	} elsif ($tag_name eq 'dtt:Nazev_ulice') {
		_save_address($expat, $text, 'street');
	} elsif ($tag_name eq 'dtt:PSC') {
		_save_address($expat, $text, 'psc');
	} elsif ($tag_name eq 'dtt:Cislo_domovni') {
		_save_address($expat, $text, 'num');
	} elsif ($tag_name eq 'dtt:Cislo_orientacni') {
		_save_address($expat, $text, 'num2');
	} elsif ($tag_name eq 'dtt:Nazev_obce') {
		_save_address($expat, $text, 'town');
	} elsif ($tag_name eq 'dtt:Nazev_casti_obce') {
		_save_address($expat, $text, 'town_part');
	} elsif ($tag_name eq 'dtt:Nazev_mestske_casti') {
		_save_address($expat, $text, 'town_urban');
	} elsif ($tag_name eq 'dtt:Nazev_okresu') {
		_save_address($expat, $text, 'district');
	}

	return;
}

# End tags handler.
sub _xml_tag_end {
	my ($expat, $tag_name) = @_;
	_pop_stack($expat);
	return;
}

# Start tags handler.
sub _xml_tag_start {
	my ($expat, $tag_name, @params) = @_;
	_push_stack($expat, $tag_name, {});
	return;
}

# Save common data.
sub _save {
	my ($expat, $text, $key) = @_;

	# Data.	
	my $data_hr = $expat->{'Non-Expat-Options'}->{'data'};

	# Save text.
	$data_hr->{$key} = $text;

	return;
}

# Save address data.
sub _save_address {
	my ($expat, $text, $key) = @_;

	# Data.	
	my $data_hr = $expat->{'Non-Expat-Options'}->{'data'};

	# Save text.
	$data_hr->{'address'}->{$key} = $text;

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::Ares::Standard - Perl XML::Parser parser for ARES standard XML file.

=head1 SYNOPSIS

 use WebService::Ares::Standard qw(parse);
 my $data_hr = parse($xml);

=head1 DESCRIPTION

 This module parses XML file from ARES system.
 Module parse these information from XML file:
 - company
 - create_date
 - district
 - ic
 - num
 - num2
 - psc
 - street
 - town
 - town_part
 - town_urban

=head1 SUBROUTINES

=over 8

=item C<parse($xml)>

 Parse XML string.
 Returns reference to hash with data.

=back

=head1 ERRORS

 parse():
         Cannot parse XML string.
                 XML::Parser error: %s

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Data::Printer;
 use WebService::Ares::Standard qw(parse);

 # Fake XML.
 my $xml = <<'END';
 <?xml version="1.0" encoding="UTF-8"?>
 <are:Ares_odpovedi
 xmlns:are="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer/v_1.0.1"
 xmlns:dtt="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_datatypes/v_1.0.4"
 xmlns:udt="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/uvis_datatypes/v_1.0.1"
 odpoved_datum_cas="2014-08-18T07:43:50" odpoved_pocet="1" odpoved_typ="Standard"
 vystup_format="XML" xslt="klient"
 validation_XSLT="/ares/xml_doc/schemas/ares/ares_answer/v_1.0.0/ares_answer.xsl"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xsi:schemaLocation="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer/v_1.0.1
 http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer/v_1.0.1/ares_answer_v_1.0.1.xsd"
 Id="ares">
 <are:Odpoved>
 <are:Pocet_zaznamu>1</are:Pocet_zaznamu>
 <are:Typ_vyhledani>FREE</are:Typ_vyhledani>
 <are:Zaznam>
 <are:Shoda_ICO>
 <dtt:Kod>9</dtt:Kod>
 </are:Shoda_ICO>
 <are:Vyhledano_dle>ICO</are:Vyhledano_dle>
 <are:Typ_registru>
 <dtt:Kod>3</dtt:Kod>
 <dtt:Text>RES</dtt:Text>
 </are:Typ_registru>
 <are:Datum_vzniku>1992-07-01</are:Datum_vzniku>
 <are:Datum_platnosti>2014-08-18</are:Datum_platnosti>
 <are:Pravni_forma>
 <dtt:Kod_PF>801</dtt:Kod_PF>
 </are:Pravni_forma>
 <are:Obchodni_firma>Statutární město Brno</are:Obchodni_firma>
 <are:ICO>44992785</are:ICO>
 <are:Identifikace>
 <are:Adresa_ARES>
 <dtt:ID_adresy>314885828</dtt:ID_adresy>
 <dtt:Kod_statu>203</dtt:Kod_statu>
 <dtt:Nazev_okresu>Brno-město</dtt:Nazev_okresu>
 <dtt:Nazev_obce>Brno</dtt:Nazev_obce>
 <dtt:Nazev_casti_obce>Brno-město</dtt:Nazev_casti_obce>
 <dtt:Nazev_mestske_casti>Brno-střed</dtt:Nazev_mestske_casti>
 <dtt:Nazev_ulice>Dominikánské náměstí</dtt:Nazev_ulice>
 <dtt:Cislo_domovni>196</dtt:Cislo_domovni>
 <dtt:Typ_cislo_domovni>1</dtt:Typ_cislo_domovni>
 <dtt:Cislo_orientacni>1</dtt:Cislo_orientacni>
 <dtt:PSC>60200</dtt:PSC>
 <dtt:Adresa_UIR>
 <udt:Kod_oblasti>60</udt:Kod_oblasti>
 <udt:Kod_kraje>116</udt:Kod_kraje>
 <udt:Kod_okresu>3702</udt:Kod_okresu>
 <udt:Kod_obce>582786</udt:Kod_obce>
 <udt:Kod_casti_obce>411582</udt:Kod_casti_obce>
 <udt:Kod_mestske_casti>550973</udt:Kod_mestske_casti>
 <udt:PSC>60200</udt:PSC>
 <udt:Kod_ulice>22829</udt:Kod_ulice>
 <udt:Cislo_domovni>196</udt:Cislo_domovni>
 <udt:Typ_cislo_domovni>1</udt:Typ_cislo_domovni>
 <udt:Cislo_orientacni>1</udt:Cislo_orientacni>
 <udt:Kod_adresy>19095597</udt:Kod_adresy>
 <udt:Kod_objektu>18945341</udt:Kod_objektu>
 <udt:PCD>649906</udt:PCD>
 </dtt:Adresa_UIR>
 </are:Adresa_ARES>
 </are:Identifikace>
 <are:Priznaky_subjektu>NNAANANANNAANNNNNNNNPNNNANNNNN</are:Priznaky_subjektu>
 </are:Zaznam>
 </are:Odpoved>
 </are:Ares_odpovedi>
 END

 # Parse.
 my $data_hr = parse($xml);

 # Print.
 p $data_hr;

 # Output:
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
 #     company       "Statutární město Brno",
 #     create_date   "1992-07-01",
 #     ic            44992785
 # }

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Data::Printer;
 use Perl6::Slurp qw(slurp);
 use WebService::Ares::Standard qw(parse);

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 xml_file\n";
         exit 1;
 }
 my $xml_file = $ARGV[0];

 # Get XML.
 my $xml = slurp($xml_file);

 # Parse.
 my $data_hr = parse($xml);

 # Print.
 p $data_hr;

 # Output like:
 # Usage: /tmp/WfgYq5ttuP xml_file

=head1 DEPENDENCIES

L<English>,
L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<XML::Parser>.

=head1 SEE ALSO

=over

=item L<WebService::Ares>

Perl class to communication with Ares service.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/WebService-Ares>

=head1 AUTHOR

Michal Špaček L<skim@cpan.org>

=head1 LICENSE AND COPYRIGHT

 © Michal Špaček 2009-2015
 BSD 2-Clause License

=head1 VERSION

0.02

=cut
