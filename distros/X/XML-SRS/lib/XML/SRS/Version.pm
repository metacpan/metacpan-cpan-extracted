
package XML::SRS::Version;
BEGIN {
  $XML::SRS::Version::VERSION = '0.09';
}
use Moose::Role;
use PRANG::Graph;
use MooseX::Params::Validate;

has_attr "major" =>
	is => "rw",
	isa => "Int",
	required => 1,
	xml_name => "VerMajor",
	;

has_attr "minor" =>
	is => "rw",
	isa => "Int",
	required => 1,
	xml_name => "VerMinor",
	;

has "version" =>
	is => "ro",
	isa => "Str",
	lazy => 1,
	default => sub {
	my $self = shift;
	$self->major.".".$self->minor;
	},
	;

sub buildargs_version {
      my $inv = shift;
      my ( $version ) = pos_validated_list(
          \@_,
          { isa => 'Str' },
      );    
    
	$version = $XML::SRS::PROTOCOL_VERSION
		if $version eq "auto";
	my ($vmaj, $vmin) = split /\./, $version;
	(major => 0+$vmaj, minor => 0+$vmin);
}

1;
