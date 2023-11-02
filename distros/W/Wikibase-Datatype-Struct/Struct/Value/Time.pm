package Wikibase::Datatype::Struct::Value::Time;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use URI;
use Wikibase::Datatype::Value::Time;

Readonly::Array our @EXPORT_OK => qw(obj2struct struct2obj);

our $VERSION = 0.12;

sub obj2struct {
	my ($obj, $base_uri) = @_;

	if (! defined $obj) {
		err "Object doesn't exist.";
	}
	if (! $obj->isa('Wikibase::Datatype::Value::Time')) {
		err "Object isn't 'Wikibase::Datatype::Value::Time'.";
	}
	if (! defined $base_uri) {
		err 'Base URI is required.';
	}

	my $struct_hr = {
		'value' => {
			'after' => $obj->after,
			'before' => $obj->before,
			'calendarmodel' => $base_uri.$obj->calendarmodel,
			'precision' => $obj->precision,
			'time' => $obj->value,
			'timezone' => $obj->timezone,
		},
		'type' => 'time',
	};

	return $struct_hr;
}

sub struct2obj {
	my $struct_hr = shift;

	if (! exists $struct_hr->{'type'}
		|| $struct_hr->{'type'} ne 'time') {

		err "Structure isn't for 'time' datatype.";
	}

	my $u = URI->new($struct_hr->{'value'}->{'calendarmodel'});
	my @path_segments = $u->path_segments;
	my $calendar_model = $path_segments[-1];
	my $obj = Wikibase::Datatype::Value::Time->new(
		'after' => $struct_hr->{'value'}->{'after'},
		'before' => $struct_hr->{'value'}->{'before'},
		'calendarmodel' => $calendar_model,
		'precision' => $struct_hr->{'value'}->{'precision'},
		'timezone' => $struct_hr->{'value'}->{'timezone'},
		'value' => $struct_hr->{'value'}->{'time'},
	);

	return $obj;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Struct::Value::Time - Wikibase time value structure serialization.

=head1 SYNOPSIS

 use Wikibase::Datatype::Struct::Value::Time qw(obj2struct struct2obj);

 my $struct_hr = obj2struct($obj, $base_uri);
 my $obj = struct2obj($struct_hr);

=head1 DESCRIPTION

This conversion is between objects defined in Wikibase::Datatype and structures
serialized via JSON to MediaWiki.

=head1 SUBROUTINES

=head2 C<obj2struct>

 my $struct_hr = obj2struct($obj, $base_uri);

Convert Wikibase::Datatype::Value::Time instance to structure.
C<$base_uri> is base URI of Wikibase system (e.g. http://test.wikidata.org/entity/).

Returns reference to hash with structure.

=head2 C<struct2obj>

 my $obj = struct2obj($struct_hr);

Convert structure of time to object.

Returns Wikibase::Datatype::Value::Time instance.

=head1 ERRORS

 obj2struct():
         Base URI is required.
         Object doesn't exist.
         Object isn't 'Wikibase::Datatype::Value::Time'.

 struct2obj():
         Structure isn't for 'time' datatype.

=head1 EXAMPLE1

=for comment filename=obj2struct_value_time.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Wikibase::Datatype::Value::Time;
 use Wikibase::Datatype::Struct::Value::Time qw(obj2struct);

 # Object.
 my $obj = Wikibase::Datatype::Value::Time->new(
         'precision' => 10,
         'value' => '+2020-09-01T00:00:00Z',
 );

 # Get structure.
 my $struct_hr = obj2struct($obj, 'http://test.wikidata.org/entity/');

 # Dump to output.
 p $struct_hr;

 # Output:
 # \ {
 #     type    "time",
 #     value   {
 #         after           0,
 #         before          0,
 #         calendarmodel   "http://test.wikidata.org/entity/Q1985727",
 #         precision       10,
 #         time            "+2020-09-01T00:00:00Z",
 #         timezone        0
 #     }
 # }

=head1 EXAMPLE2

=for comment filename=struct2obj_value_time.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Struct::Value::Time qw(struct2obj);

 # Time structure.
 my $struct_hr = {
         'type' => 'time',
         'value' => {
                 'after' => 0,
                 'before' => 0,
                 'calendarmodel' => 'http://test.wikidata.org/entity/Q1985727',
                 'precision' => 10,
                 'time' => '+2020-09-01T00:00:00Z',
                 'timezone' => 0,
         },
 };

 # Get object.
 my $obj = struct2obj($struct_hr);

 # Get calendar model.
 my $calendarmodel = $obj->calendarmodel;

 # Get precision.
 my $precision = $obj->precision;

 # Get type.
 my $type = $obj->type;

 # Get value.
 my $value = $obj->value;

 # Print out.
 print "Calendar model: $calendarmodel\n";
 print "Precision: $precision\n";
 print "Type: $type\n";
 print "Value: $value\n";

 # Output:
 # Calendar model: Q1985727
 # Precision: 10
 # Type: time
 # Value: +2020-09-01T00:00:00Z

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<URL>,
L<Wikibase::Datatype::Value::Time>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Struct>

Wikibase structure serialization.

=item L<Wikibase::Datatype::Value::Time>

Wikibase time value datatype.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Struct>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.12

=cut
