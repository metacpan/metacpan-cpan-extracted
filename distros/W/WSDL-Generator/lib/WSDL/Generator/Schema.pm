=pod

=head1 NAME

WSDL::Generator::Schema - Generate wsdl schema for WSDL::Generator

=head1 SYNOPSIS

  use WSDL::Generator::Schema;
  my $schema = WSDL::Generator::Schema->new('mytargetNamespace');
  $schema->add($struct);
  $schema->add($struct2);
  print $schema->get->to_string;

=cut
package WSDL::Generator::Schema;

use strict;
use warnings::register;
use Carp;
use base	qw(WSDL::Generator::Base);

our $VERSION = '0.01';


=pod

=head1 CONSTRUCTOR

=head2 new($namespace)

$namespace is optional.
Returns WSDL::Generator::Schema object

=cut
sub new {
	my ($class, $namespace) = @_;
	my $self = { 'schema_namesp' => $namespace,
	             'counter'       => 0 };
	return bless $self => $class;
}

=pod

=head1 METHODS

=head2 add($struct)

Generate a wsdl schema for the structure sent

=cut
sub add : method {
	my ($self, $struct, $name) = @_;
	push @{$self->{schema}}, $self->make_types($self->dumper($struct), $name);
}

=pod

=head2 get($namespace)

$namespace is optional (it must be specified here or in new method).
Returns the Schema wsdl array of lines

=cut
sub get : method {
	my ($self, $namespace) = @_;
	$self->{schema_namesp} = $namespace if (defined $namespace);
	unless ($self->{schema}) {
		carp 'No schema defined';
		return 0;
	}
	my $schema = $self->get_wsdl_element( { wsdl_type => 'TYPES',
														%$self,
				                                     } );
	return $schema;
}


#
# Create wsdl types declations
#
sub make_types {
	my $self   = shift;
	my $struct = shift;
	my $name   = shift || 'myelement'.$self->{counter}++;
	my @wsdl   = ();
	if ($struct->{type} eq 'SCALAR' ) {
		push @wsdl, @{$self->get_wsdl_element( { wsdl_type => 'ELEMENT',
  		                                       	 name      => $name,
			                                   	 type      => 'string',
		                                     } )};
	}
	elsif ($struct->{type} eq 'HASHREF' ) {
		my @sub_wsdl = ();
		foreach my $key ( keys %{$struct->{value}} ) {
			if ($struct->{value}->{$key}->{type} eq 'SCALAR') {
				push @sub_wsdl, @{$self->get_wsdl_element( { wsdl_type => 'ELEMENT',
				                                        	 type      => 'string',
				                                        	 name      => $key,
				                                        	 min_occur => $struct->{value}->{$key}->{min_occur} } )};
			}
			else {
				my $type = 'myelement'.$self->{counter}++;
				push @sub_wsdl, @{$self->get_wsdl_element( { wsdl_type => 'ELEMENT',
				                                        	 type      => "xsdl:$type",
				                                        	 name      => $key,
				                                        	 min_occur => $struct->{value}->{$key}->{min_occur} } )};
				push @wsdl, $self->make_types($struct->{value}->{$key}, $type);
			}
		}
		push @wsdl, @{$self->get_wsdl_element( { wsdl_type => 'HASHREF',
  		                                         name      => $name,
			                                     elements  => \@sub_wsdl,
		                                       } )};
	}
	elsif ($struct->{type} eq 'ARRAYREF') {
		$struct->{value} = [ array_reduction($struct->{value}) ];
		my $type = $struct->{value}->[0]->{type};
		if ($type eq 'SCALAR') {
			push @wsdl, @{$self->get_wsdl_element( { wsdl_type => 'ARRAYREF',
		                                             name      => $name,
		                                             max_occur => 'unbounded',
				                                     type      => 'string',
			                                       } )};
		}
		elsif ($type eq 'ARRAYREF') {
			my $new_name = 'myelement'.$self->{counter}++;
			push @wsdl, $self->make_types($struct->{value}->[0], $new_name);
			push @wsdl, @{$self->get_wsdl_element( { wsdl_type => 'ARRAYREF',
		                                             name      => $name,
		                                             max_occur => 'unbounded',
				                                     type      => "xsdl:$new_name",
			                                       } )};
		}
		elsif ($type eq 'HASHREF') {
			my $new_name = 'myelement'.$self->{counter}++;
			push @wsdl, $self->make_types($struct->{value}->[0], $new_name);
			push @wsdl, @{$self->get_wsdl_element( { wsdl_type => 'ARRAYREF',
		                               				 name      => $name,
		                                     		 max_occur => 'unbounded',
				                            		 type      => "xsdl:$new_name",
			                                       } )};
		}
	}
	return @wsdl;
}


#
# Merge all elements of an array into 1 element
# Array of scalar => 1 scalar
# Array of hashref => 1 hashref containing all keys + a counter for each
sub array_reduction {
	my $array = shift;
	return $array->[0] if (@$array == 1);
	my $first_type = $array->[0]->{type};
	my $branch = {};
	if ($first_type eq 'SCALAR') {
		$branch->{type}  = 'SCALAR';
		$branch->{value} = $array->[0]->{value};
	}
	elsif ($first_type eq 'ARRAYREF') {
		my @fields    = ();
		foreach my $element (@$array) {
			$element->{type} eq 'ARRAYREF' or croak "Expected arrayrefs only in the array";
			my $i = 0;
			foreach my $sub_element (@{$element->{value}}) {
				push @{$fields[$i++]}, $sub_element;
			}
		}
		foreach my $element (@fields) {
			$element = array_reduction($element);
		}
		$branch->{value} = \@fields;
		$branch->{type}  = 'ARRAYREF';
	}
	elsif ($first_type eq 'HASHREF') {
		my %fields    = ();
		foreach my $element (@$array) {
			$element->{type} eq 'HASHREF' or croak "Expected hashrefs only in the array";
			foreach my $key (keys %{$element->{value}}) {
				push @{$fields{$key}}, $element->{value}->{$key};
			}
		}
		# Calculates min_occur
		foreach my $key (keys %fields) {
			my $min_occur = (@{$fields{$key}} == scalar @$array) ? 1 : 0;
			$fields{$key} = array_reduction($fields{$key});
			$fields{$key}->{min_occur} = $min_occur;
		}
		$branch->{value} = \%fields;
		$branch->{type}  = 'HASHREF';
	}
	return $branch;
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
