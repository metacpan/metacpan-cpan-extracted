package Test::Fixture::KyotoTycoon;
use strict;
use warnings;
use 5.008000;
use parent qw(Exporter);
use Carp;
use Kwalify;
use Storable qw(nfreeze);
use YAML::XS qw(LoadFile);

our @EXPORT = qw(construct_fixture);
our $VERSION = '0.13';

sub construct_fixture {

	my %args = @_;
	my $fixture;

	if (!ref($args{kt}) || ref($args{kt}) && !$args{kt}->isa("Cache::KyotoTycoon")) {
		croak "kt must be Cache::KyotoTycoon instance";
	}

	if (-f $args{fixture}) {
		$fixture = LoadFile($args{fixture});
	} elsif (ref($args{fixture}) eq "ARRAY") {
		$fixture = $args{fixture};
	} else {
		croak "fixture must be YAML file path or ARRAY";
	}
	_validate_fixture($fixture);

	if (ref($args{serializer}) eq "CODE") {
		_override_serializer($args{serializer});
	}

	_delete_all($args{kt});
	return _insert($args{kt}, $fixture);
}

sub _delete_all {

	my $kt = shift;
	$kt->clear;
}

sub _insert {

	my($kt, $fixture) = @_;

	my $data = {};
	foreach my $ref (@{$fixture}) {

		my @values;
		push @values, (exists $ref->{namespace} ? sprintf("%s%s", $ref->{namespace}, $ref->{key}) : $ref->{key});
		push @values, (ref($ref->{value}) ? _serializer($ref->{value}) : $ref->{value});
		push @values, $ref->{xt} if exists $ref->{xt};
		#$kt->set($key, $value, $xt);
		$kt->set(@values);
		$data->{$values[0]} = $values[1];
	}
	return $data;
}

sub _override_serializer {

	my $serializer = shift;
	no strict "refs";
	no warnings "redefine";
	*_serializer = $serializer; ## no critic
}

sub _serializer {

	my $ref = shift;
	return nfreeze $ref;
}

sub _validate_fixture {

	my $stuff = shift;
	Kwalify::validate({
		type     => 'seq',
		sequence => [{
			type    => 'map',
			mapping => {
				namespace => { type => 'str' },
				key       => { type => 'str', required => 1 },
				value     => { type => 'any', required => 1 },
				xt        => { type => 'int' }
			},
		}]
	},
	$stuff
	);
	return $stuff;
}


1;
__END__

=head1 NAME

Test::Fixture::KyotoTycoon - load fixture data to kyototycoon

=head1 VERSION

0.13

=head1 SYNOPSIS

  # in your t/fixture.yaml
  ---
  -
    key: foo
    value: bar
  -
    key: array
    value:
      - 1
      - 2
      - 3
      - 4
      - 5
  -
    key: hash
    value:
      apple: red
      banana: yellow
  -
    namespace: "app:"
    key: nirvana
    value: smells like teen split
  -
    key: xt
    value: bar
    xt: 3
  
  # in your t/*.t
  use Test::Fixture::KyotoTycoon;
  ## $kt is Cache::KyotoTycoon instance
  my $data = construct_fixture kt => $kt, fixture => "t/fixture.yaml";

=head1 DESCRIPTION

Test::Fixture::KyotoTycoon is fixture data loader for Cache::KyotoTycoon.

=head1 METHODS

=head2 construct_fixture

load to ktserver

Example:

  use Cache::KyotoTycoon;
  use Test::Fixture::KyotoTycoon;
  
  # basic sample
  my $kt = Cache::KyotoTycoon->new(host = "127.0.0.1");
  my $fixture = "/path/to/fixture.yaml";
  my $data = construct_fixture kt => $kt, fixture => $fixture;

Options:

  kt           Cache::KyotoTycoon instance
  fixture      fixture yaml path or ARRAY reference
  serializer   custom serializer(optional. default Storable::nfreeze)

Custom Serializer Example(using Data::MessagePack) 
  
  use Cache::KyotoTycoon;
  use Test::Fixture::KyotoTycoon;
  use Data::MessagePack;
  
  my $kt = Cache::KyotoTycoon->new(host = "127.0.0.1");
  my $fixture = "/path/to/fixture.yaml";
  my $data = construct_fixture kt => $kt, fixture => $fixture, serializer => sub { Data::MessagePack->pack(+shift) };

=head1 FIXTURE

YAML format or ARRAY reference

Fields:

  namespace  namespace. type:str(optional)
  key        key name. type:str
  value      value. type:any
  xt         expiration time. see Cache::KyotoTycoon manual

=head1 AUTHOR

holly E<lt>emperor.kurt@gmail.comE<gt>

=head1 SEE ALSO

L<Cache::KyotoTycoon> L<Kwalify> L<YAML::XS>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
