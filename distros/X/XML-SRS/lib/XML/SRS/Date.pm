
package XML::SRS::Date;
BEGIN {
  $XML::SRS::Date::VERSION = '0.09';
}

use Moose::Role;
use PRANG::Graph;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;

BEGIN {
	subtype "XML::SRS::Date::ymd"
		=> as "Str"
		=> where {
		m{^(\d{4})-(\d{1,2})-(\d{1,2})$};
		};

	subtype 'XML::SRS::Date::Year'
		=> as "Int",
		=> where {
		length(0+$_) == 4;
		};
	subtype 'XML::SRS::Date::Month'
		=> as "Int",
		=> where {
		$_ >= 1 and $_ <= 12;
		};
	subtype 'XML::SRS::Date::Day'
		=> as "Str",
		=> where {
		$_ >= 1 and $_ <= 31;
		};
}

has_attr 'year' =>
	is => "rw",
	isa => "XML::SRS::Number",
	required => 1,
	xml_name => "Year",
	;

has_attr 'month' =>
	is => "rw",
	isa => "XML::SRS::Number",
	required => 1,
	xml_name => "Month",
	;

has_attr 'day' =>
	is => "rw",
	isa => "XML::SRS::Number",
	required => 1,
	xml_name => "Day",
	;

sub buildargs_date {
      my $inv = shift;
      my ( $ymd ) = pos_validated_list(
          \@_,
          { isa => 'XML::SRS::Date::ymd' },
      );    
    
	my @buildargs;
	my ($y, $m, $d) = split "-", $ymd;
	push @buildargs, year => $y, month => $m, day => $d;
	@buildargs;
}

sub date {
    my $self = shift;
    
	return sprintf(
		"%.4d-%.2d-%.2d",
		$self->year, $self->month, $self->day,
	);
}

1;
