=pod

=head1 NAME

WSDL::Generator::Base - Base class for WSDL::Generator::*

=head1 SYNOPSIS

  use base 'WSDL::Generator::Base';

=cut
package WSDL::Generator::Base;

use strict;
use warnings::register;
use Carp;

our $VERSION = '0.01';

our %WSDL = (
			ELEMENT  => [ '<xsd:element name="[%name%]" type="xsd:[%type%]" />' ],
			ARRAYREF => [ '<xsd:element minOccurs="[%min_occur%]" maxOccurs="[%max_occur%]" name="[%name%]" wsdl:arrayType="xsd:[%type%][]" />' ],
			HASHREF  =>	[
			             '<xsd:complexType name="[%name%]">',
				         	[
				         	'<xsd:sequence>',
				        		['@[%elements%]'],
				        	'</xsd:sequence>',
				        	],
				         '</xsd:complexType>',
				        ],
			TYPES =>	[
							'<types>',
							[
								'<xsd:schema targetNamespace="[%schema_namesp%]">',
									['@[%schema%]'],
					   			'</xsd:schema>',
					   		],
						   '</types>',
						],
			MESSAGE  => [
						   '<message name="[%methodRe%]">',
								[ '<part name="[%methodRe%]SoapMsg" element="xsdl:[%type%]"/>' ],
						   '</message>',
			            ],
			PORTTYPE_OPERATION =>
			            [ '<operation name="[%method%]">',
							[
							  '<input message="tns:[%request%]" />',
							  '<output message="tns:[%response%]" />',
							],
						   '</operation>',
						],
			PORTTYPE => [
							'<portType name="[%services%][%service_name%]PortType">',
								['@[%porttype_operation%]'],
							'</portType>',
						],
			BINDING_OPERATION =>
						[
						  '<operation name="[%method%]">',
								[
								  '<soap:operation style="document" soapAction=""/>',
								  '<input>',
									[ '<soap:body use="literal"/>' ],
								  '</input>',
								  '<output>',
									[ '<soap:body use="literal"/>' ],
								  '</output>',
								],
						  '</operation>',
						],
			BINDING =>
			            [
			              '<binding name="[%services%][%service_name%]Binding" type="tns:[%services%][%service_name%]PortType">',
			              	[
								'<soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>',
			              		['@[%binding_operation%]'],
			              	],
			              '</binding>',
			            ],
			SERVICE =>
						[
						  '<service name="[%service_name%]">',
						  	[
						  	'<documentation>',
						  		[
									'[%documentation%]',
								],
						  	'</documentation>',
						  	'<port name="[%services%][%service_name%]Port" binding="tns:[%services%][%service_name%]Binding">',
						  		[
						  			'<soap:address location="[%location%]"/>',
						  		],
						  	'</port>',
						  	],
						  '</service>',
						],
			DEFINITIONS =>
						[
							'<definitions name="[%service_name%]" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" targetNamespace="[%target_namesp%]" xmlns:tns="[%target_namesp%]" xmlns="http://schemas.xmlsoap.org/wsdl/" xmlns:xsdl="[%schema_namesp%]">',
								['@[%schema%]'],
								['@[%message%]'],
								['@[%porttype%]'],
								['@[%binding%]'],
								['@[%service%]'],
							'</definitions>',
						],
			WSDL =>
						[
							'<?xml version="1.0"?>',
							'@[%definitions%]',
						],
			);

=pod

=head1 METHODS

=head2 get_wsdl_element($param, $tab)

$param contains the parameters to parse the element template.
$tab is the depth of the structure - optional - useful for indented display.
Returns an array of elements ready to be displayed.

=cut

sub get_wsdl_element {
	my ($self, $param, $depth) = @_;
	$param->{min_occur} = 1 unless (exists $param->{min_occur} and defined $param->{min_occur});
	$param->{max_occur} = 1 unless (exists $param->{max_occur} and defined $param->{max_occur});
	$depth ||= 0;
	my $element = $WSDL{$param->{wsdl_type}};
	my @return = $self->get_wsdl_element_recurse($param, $element, $depth - 1);
	return bless \@return => ref($self);
}

=pod

=head2 to_string()

Returns a string containing lines of WSDL data

=cut
sub to_string {
	my ($self) = @_;
	my $string = '';
	foreach ( @$self ) {
		$string .= "\t" x $_->{depth} . $_->{content} . "\n";
	}
	return $string;
}


=pod

=head2 dumper($struct)

Extends the data structure received by adding data type infos at each branch

=cut
sub dumper {
	my ($self, $param) = @_;
	my $branch = {};
	my $ref    = ref($param);
	if (! $ref) {
		$branch->{type}  = 'SCALAR';
		$branch->{value} = $param;
	}
	elsif ($ref eq 'ARRAY') {
		if (@$param) {
			$branch->{type}  = 'ARRAYREF';
			foreach my $elem (@$param) {
				push @{$branch->{value}}, $self->dumper($elem);
			}
		}
		else {
			$branch->{type}  = 'SCALAR';
			$branch->{value} = undef;
		}
	}
	else {
		$branch->{type} = 'HASHREF';
		foreach my $key (keys %$param) {
			$branch->{value}->{$key} = $self->dumper($param->{$key});
		}
	}
	return $branch;
}


sub get_wsdl_element_recurse {
	my ($self, $param, $array, $depth) = @_;
	$depth++;
	my @lines = ();
	foreach my $elt (@$array) {
		if (ref $elt) {
			push @lines, $self->get_wsdl_element_recurse($param, $elt, $depth);
		}
		else {
			my $parsed = $elt;
			if ($parsed =~ /^\@\[%(.+?)%\]/ and ref $param->{$1}) {
				foreach my $element ( @{$param->{$1}} ) {
					my $parsed2 = $parsed;
					$parsed2 =~ s/\@\[%(.+?)%\]/$element->{content}/gi;
					push @lines, { content => $parsed2,
					               depth   => $element->{depth}+$depth };
				}
				$parsed =~ s/\@\[%(.+?)%\]//g;
				if ($parsed =~ s/\[%(.+?)%\]/$param->{$1}/gi) {
					push @lines, { content => $parsed,
						           depth   => $depth };
				}
			}
			else {
				$parsed =~ s/\[%(.+?)%\]/$param->{$1}/gi;
				push @lines, { content => $parsed,
					           depth   => $depth };
			}
		}
	}
	return @lines;
}

1;

=pod

=head1 SEE ALSO

  WSDL::Generator

=head1 AUTHOR

"Pierre Denis" <pdenis@fotango.com>

=head1 COPYRIGHT

Copyright (C) 2001, Fotango Ltd - All rights reserved.
This is free software. This software may be modified and/or distributed under the same terms as Perl itself.

=cut
