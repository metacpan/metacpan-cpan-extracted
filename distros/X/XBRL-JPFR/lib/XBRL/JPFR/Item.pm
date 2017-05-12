package XBRL::JPFR::Item;

use strict;
use warnings;

use Carp;
use base qw(Class::Accessor);
use Hash::Merge qw(merge);
use Data::Dumper;

our $VERSION = '0.01';

my @fields = qw(
	name prefix localname namespace parentname id
	contextRef periodType unitRef footnoteRef
	value adjValue ixbrlValue 
	decimals scale format sign escape img
	nillable xsi:nil type
	subGroup substitutionGroup
	point thousand
);
XBRL::JPFR::Item->mk_accessors(@fields);

my %default = (
	'point'	=> '.',
	'thousand'	=> ',',
);

sub new() {
	my ($class, $xml, $encoding, $args) = @_;
	$args = {} if !$args;
	my $self = merge($args, \%default);
	bless $self, $class;

	$self->parse($xml, $encoding) if $xml;

	return $self;
}

sub parse() {
	my ($self, $xml, $encoding) = @_;

	foreach (@fields) {
		next if $_ eq 'name';
		$$self{$_} = $xml->getAttribute($_) if $xml->hasAttribute($_);
	}
	$$self{'namespace'} = $xml->namespaceURI();
	my $val = $$self{'value'} = Encode::encode($encoding, $xml->textContent());
	$val =~ s/$$self{'thousand'}//g;
	if (exists $$self{'sign'} && $$self{'sign'} eq '-' && $val > 0) {
		$$self{'value'} = "-$$self{'value'}"
	}
	if ($xml->hasAttribute('name')) {
		# TDNet
		$$self{'parentname'} = $xml->nodeName();
		$$self{'name'} = $xml->getAttribute('name');
		@$self{'prefix', 'localname'} = split /:/, $$self{'name'};
	}
	else {
		$$self{'name'} = $xml->nodeName();
		$$self{'prefix'} = $xml->prefix();
		$$self{'localname'} = $xml->localname();
	}
	$self->add_children($xml);
	$self->adjust();
}

sub add_children {
	my ($self, $xml) = @_;
	my @nodes = $xml->childNodes();
	foreach my $node (@nodes) {
		my $name = $node->nodeName();
		if ($name eq 'img') {
			#my $class = "XBRL::JPFR::". ucfirst $name;
			#$$self{$name} = $class->new($node);
			$$self{$name} = $node;
		}
		elsif ($name eq '#text') {
			# $xml->textContent();
		}
		else {
			#warn "No class($name)  $xml";
		}
	}
}

# XBRL2.1: 4.6.3-4.6.7
# EDINET
#   20130301/02_b.pdf: 8-1
#     no scale
#     if decimals=-3, lower three digits must be zero.
#     decimals={0,-3,-6}, can have another value if unitRef ne Yen.
#   20130821/2b_1.pdf: 5-6-2
# TDnet
#   2014: 02_Summary_instance.pdf: 2-3-9-1
sub adjust() {
	my ($self) = @_;
	my $val = $$self{'value'};
	if (defined $$self{'decimals'}) {
		return $val if $$self{'decimals'} =~ m/INF/;
		if (defined $$self{'scale'}) {
			$$self{'ixbrlValue'} = $val;
			$val =~ s/$$self{'thousand'}//g;
			$$self{'adjValue'} = $val;
			$val *= 10**$$self{'scale'};
			if ($$self{'scale'} + $$self{'decimals'} > 0) {
				if ($$self{'decimals'} >= 0) {
					$val = sprintf "%.$$self{'decimals'}f", $val;
				}
				else {
					$val = sprintf "%.0f", $val;
				}
			}
			$$self{'value'} = $val
		}
		else {
			if (index($val, $$self{'point'}) > 0) {
				# a value of type='num:percentItemType' is adjusted by adjust_percent()
				# see XBRL::JPFR.pm
				$$self{'adjValue'} = $val;
			}
			else {
				if ($val eq '-0' || $val eq '0') {
					$$self{'adjValue'} = $val;
				}
				else {
					if ($$self{'decimals'} < 0) {
						$$self{'adjValue'} = substr $val, 0, $$self{'decimals'};
					}
					elsif ($$self{'decimals'} == 0) {
						$$self{'adjValue'} = $val;
					}
					else {
						if ($self->unitRef() eq "NumberOfPersons") {
							# TDnet CG unitRef="NumberOfPersons"
							# decimals の指定が間違っているのも見られる。
							# <tse-t-cg:NumberOfDirectors decimals="4" contextRef="CG" unitRef="NumberOfPersons">14</tse-t-cg:NumberOfDirectors>
							# 取締役１４万人になってしまう。
							$$self{'value'} = sprintf "%.0f", $val * 10**$$self{'decimals'};
							$$self{'adjValue'} = $val;
						}
						else {
							# 7918/S1002DLP/XBRL/PublicDoc/jpcrp030000-asr-001_E00705-000_2014-03-31_01_2014-06-27.xbrl
							# DividendPaidPerShareClassAPreferredStockSummaryOfBusinessResults
							#   decimals=2 value=25000 unitRef=JPYPerShares
							#   PDFでは 25,000 と表示されてる
							# 6481/S100259P/XBRL/PublicDoc/jpcrp030000-asr-001_E01678-000_2014-03-31_01_2014-06-23.xbrl
							# InterimDividendPaidPerShareSummaryOfBusinessResults
							#   decimals=2 value=11 unitRef=JPYPerShares
							#   PDFでは 11 と表示されてる
							# ...
							warn "No point and positive decimals\n".Dumper($self);
						}
					}
				}
			}
		}
	}
	else {
		$$self{'adjValue'} = $val;
	}
}

# 2700/S1001L44/XBRL/PublicDoc/jpcrp030000-asr-001_E02934-000_2013-12-31_02_2014-04-04.xbrl
#   EquityToAssetRatioSummaryOfBusinessResults
#     decimals=3 value=0.208 -- ratio value
#     decimals=1 value=19.9  -- percent value
sub adjust_percent {
	my ($self) = @_;
	return if !exists $$self{'decimals'};
	if ($$self{'decimals'} == 1) {
		$$self{'value'} = sprintf "%.3f", $$self{'adjValue'} / 100;
	}
	else {
		my $precision = $$self{'decimals'} - 2;
		$$self{'adjValue'} = sprintf "%.${precision}f", $$self{'adjValue'} * 100;
	}
}

sub get_fields {
	my ($self) = @_;
	return @fields;
}

=head1 XBRL::JPFR::Item

XBRL::JPFR::Item - OO Module for Encapsulating XBRL::JPFR Items

=head1 SYNOPSIS

  use XBRL::JPFR::Item;

	my $item = XBRL::JPFR::Item->new($item_xml);

=head1 DESCRIPTION

This module is part of the XBRL::JPFR modules group and is intended for use with XBRL::JPFR.

=over 4

=item new

Object contstructor.  Optionally takes the item XML from the instance document.

=back

=head1 AUTHOR

Tetsuya Yamamoto <yonjouhan@gmail.com>

=head1 SEE ALSO

Modules: XBRL XBRL::JPFR XBRL::Item

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Tetsuya Yamamoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;
