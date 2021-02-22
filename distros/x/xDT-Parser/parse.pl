#!/usr/bin/perl -w

use Moose;
use v5.10;
use Time::Piece;
use Data::Dumper;

use xDT::Parser;

my $xdt_file    = shift // croak('Error: no xDT file given');
my $config_file = shift;

my $parser = xDT::Parser->new($config_file);
$parser->open($xdt_file);

while (my $object = $parser->next_object) {
	last if $object->is_empty;
	
	say _extract_core_data($object);
	say _extract_measurements($object);
}

$parser->close();


sub _extract_core_data {
	my $object = shift // croak('Error: parameter $object missing.');
	
	return sprintf(
		'%s: %s %s (%s, %s)',
		$object->get_value('patient_number'),
		$object->get_value('firstname'),
		$object->get_value('surname'),
		Time::Piece->strptime($object->get_value('birthdate'), '%d%m%Y')->ymd,
		$object->get_value('sex')
	);
}

sub _extract_measurements {
	my $object = shift // croak('Error: parameter $object missing.');
	my @measurements = ();
	my $measurement = ();

	while (my $record = $object->next_record) {
		last unless defined $record;

		if ($record->get_accessor eq 'test_identification') {
			push @measurements, $measurement if defined $measurement->{test_identification};
			$measurement = ();
			$measurement->{test_identification} = $record->get_value;
		} else {
			foreach my $accessor ('collection_date', 'collection_time', 'result', 'unit') {
				next unless $record->get_accessor eq $accessor;
				$measurement->{$accessor} = $record->get_value;
			}	
		}
	}
	push @measurements, $measurement;

	return join "\n", map {
		my $date = Time::Piece->strptime($_->{collection_date} // '', '%d%m%Y')->ymd;
		sprintf(
			'%s - %s: %s %s',
			$date,
			$_->{test_identification},
			$_->{result},
			$_->{unit}
		);
	} @measurements;
}