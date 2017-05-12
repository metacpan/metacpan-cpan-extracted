
package XML::SRS::TimeStamp;
BEGIN {
  $XML::SRS::TimeStamp::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;

with 'XML::SRS::TimeStamp::Role', 'XML::SRS::Node';

use Moose::Util::TypeConstraints;
use MooseX::Timestamp qw();
use MooseX::TimestampTZ qw();
use XML::SRS::Types;

coerce __PACKAGE__
	=> from Timestamp
	=> via {
	__PACKAGE__->new(timestamp => $_);
	};

coerce __PACKAGE__
	=> from TimestampTZ
	=> via {
	__PACKAGE__->new(timestamptz => $_);
	};

coerce __PACKAGE__
	=> from "Str"
	=> via {
	__PACKAGE__->new(timestamptz => $_);
	};

coerce __PACKAGE__
	=> from "Int"
	=> via {
	__PACKAGE__->new(epoch => $_);
	};

sub BUILDARGS {
	my $class = shift;
	my %args = @_;
	%args = (%args, $class->buildargs_timestamp($args{timestamp}))
		if $args{timestamp};
	%args = (%args, $class->buildargs_timestamptz($args{timestamptz}))
		if $args{timestamptz};
	%args = (%args, $class->buildargs_epoch($args{epoch}))
		if $args{epoch};
	\%args;
}

1;


__END__

=head1 NAME

XML::SRS::TimeStamp - Class representing an SRS timestamp

=head1 DESCRIPTION

This class represents an SRS timestamp

=head1 ATTRIBUTES

Each attribute of this class has an accessor/mutator of the same name as
the attribute. Additionally, they can be passed as parameters to the
constructor.

=head2 hour

Required. Must be of type XML::SRS::Time::Sexagesimal. Maps to the XML attribute 'Hour'

=head2 month

Required. Must be of type XML::SRS::Number. Maps to the XML attribute 'Month'

=head2 second

Must be of type XML::SRS::Time::Sexagesimal. Maps to the XML attribute 'Second'

=head2 tz_offset

Must be of type XML::SRS::Time::TZOffset. Maps to the XML attribute 'TimeZoneOffset'

=head2 minute

Required. Must be of type XML::SRS::Time::Sexagesimal. Maps to the XML attribute 'Minute'

=head2 day

Required. Must be of type XML::SRS::Number. Maps to the XML attribute 'Day'

=head2 year

Required. Must be of type XML::SRS::Number. Maps to the XML attribute 'Year'

=head1 METHODS

=head2 new(%params)

Construct a new XML::SRS::Request object. %params specifies the initial
values of the attributes.

=head1 COMPOSED OF

L<XML::SRS::Node>, L<XML::SRS::TimeStamp::Role>
