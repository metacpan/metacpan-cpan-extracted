# ====================================================================
# Copyright (c) 2002,2003 IBM Corporation 
# All rights reserved.   This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://www.opensource.org/licenses/cpl.php
# 
# =====================================================================
package LS::Authority::WSDL::Bindings;

use strict;
use warnings;

use vars qw(
		%NAMESPACES
	);

use LS::Authority::WSDL::Constants;

#
# %NAMESPACES -
#
%NAMESPACES = (
	

	);




# The following Binding related objects are unused

package LS::Authority::WSDL::Binding;

use strict;
use warnings;

use vars qw( $METHODS );


use LS::Authority::WSDL::Constants;


#
# BEGIN( ) - 
#
sub BEGIN {

	$METHODS = [
			'name',
			'port_type',
			'implementation',
		];
}


# 
# Create the accessor / mutator methods for the bindings class
#
for my $field (@{ $METHODS }) {

	no strict "refs";

	my $slot = __PACKAGE__ . $field;
	
	*$field = sub {

		my $self = shift;
		my $param = shift;
		
		$param ? $self->{ $slot } = $param : return $self->{ $slot };
	}
}


#
# new( %options ) -
#
sub new {
	my $self = shift;
	my %params = @_;

	unless(ref $self) {
		$self = bless {
			operations=> []     # operations
		}, $self;
		
		$self->name($params{name}) if defined $params{name};
		$self->port_type($params{port_type}) if defined $params{port_type};
		$self->implementation($params{implementation}) if defined $params{implementation};
	}
	
	return $self;
}


sub operations {
	my $self = shift;
	
	return $self->{'operations'};
}

sub add_operation {
	my $self = shift;
	my ($op) = @_;
	
	push(@{$self->operations}, $op);
}

sub get_operation_by_name {
	my $self = shift;
	my ($name) = @_;

	foreach my $op (@{$self->operations}) {
		return $op if $op->name eq $name;
	}

	return undef;
}

sub xml {
	my $self = shift;

	require LS::Authority::WSDL;
	
	my $operations_xml = '';
	
	foreach my $operation (@{$self->operations}) {
		$operations_xml .= $operation->xml;
	}
	
	return
		'<binding name="' . $self->name .'" type="' . $LS::Authority::WSDL::_STD_DEFS_PREFIX . ':' . $self->port_type . '">' .
		($self->implementation ? $self->implementation->xml : '') .
		$operations_xml .
		'</binding>';
}

sub from_xpath_node {
	my $self = shift->new;
	my ($node, $xpath) = @_;

	my $name = $node->getAttribute('name') || return;
	my $port_type = $node->getAttribute('type') || return;

	$port_type =~ s/^\w+://;

	my $imp_nodes = $xpath->find('*[local-name() = "binding"]', $node);
	return unless $imp_nodes->size == 1;

	my $imp_node = $imp_nodes->get_node(1);
	my $imp = LS::Authority::WSDL::Implementation->from_xpath_node($imp_node, $xpath);

	return unless $imp;

	$self->name($name);
	$self->port_type($port_type);
	$self->implementation($imp);

	my $op_nodes = $xpath->find('operation', $node);
	
	foreach my $op_node ($op_nodes->get_nodelist) {
		my $op = LS::Authority::WSDL::Binding::Operation->from_xpath_node($op_node, $xpath);
		next unless $op;

		$self->add_operation($op);
	}
	
	return $self;
}


package LS::Authority::WSDL::Binding::Operation;

sub new {
	my $self = shift;
	my %params = @_;

	unless(ref $self) {
		$self = bless [
			undef, # name,
			undef, # implementation,
			undef, # input,
			undef  # output
		], $self;
		
		$self->name($params{name}) if defined $params{name};
		$self->implementation($params{implementation}) if defined $params{implementation};
		$self->input($params{input}) if defined $params{input};
		$self->output($params{output}) if defined $params{output};
	}
	
	return $self;
}

sub name {
	my $self = shift;

	@_ ? $self->[0] = $_[0] : $self->[0];
}

sub implementation {
	my $self = shift;

	@_ ? $self->[1] = $_[0] : $self->[1];
}

sub input {
	my $self = shift;

	@_ ? $self->[2] = $_[0] : $self->[2];
}

sub output {
	my $self = shift;

	@_ ? $self->[3] = $_[0] : $self->[3];
}

sub xml {
	my $self = shift;

	my $input_xml = '';
	my $input = $self->input;

	if ($input) {
		if (ref $input eq 'ARRAY') {
			foreach my $impl (@$input) {
				$input_xml .= $impl->xml;
			}
		}
		else {
			$input_xml = $input->xml;
		}
	}
	
	my $output_xml = '';
	my $output = $self->output;
	
	if ($output) {
		if (ref $output eq 'ARRAY') {
			foreach my $impl (@$output) {
				$output_xml .= $impl->xml;
			}
		}
		else {
			$output_xml = $output->xml;
		}
	}

	return
		'<operation name="' . $self->name . '">' .
		($self->implementation ? $self->implementation->xml : '') .
		($input ? '<input>' . $input_xml . '</input>' : '<input/>') .
		($output ? '<output>' . $output_xml . '</output>' : '<output/>') .
		'</operation>';
}

sub from_xpath_node {
	my $self = shift->new;
	my ($node, $xpath) = @_;

	my $name = $node->getAttribute('name') || return;
	$self->name($name);

	my $imp_nodes = $xpath->find('*[local-name() = "operation"]', $node);
	return unless $imp_nodes->size == 1;

	my $imp_node = $imp_nodes->get_node(1);
	my $imp = LS::Authority::WSDL::Implementation->from_xpath_node($imp_node, $xpath) || return;

	$self->implementation($imp);

	my $input_nodes = $xpath->find('input', $node);
	return if $input_nodes->size > 1;

	if ($input_nodes->size > 0) {
		my $input_node = $input_nodes->get_node(1);
		my $impl_nodes = $xpath->find('*', $input_node);
		
		if ($impl_nodes->size == 1) {
			my $input_imp_node = $impl_nodes->get_node(1);
			my $input_imp = LS::Authority::WSDL::Implementation->from_xpath_node($input_imp_node, $xpath) || return;

			$self->input($input_imp);
		}
		elsif ($impl_nodes->size > 1) {
			my @imp = ();

			for(my $i=1; $i<=$impl_nodes->size; $i++) {
				my $input_imp_node = $impl_nodes->get_node($i);
				my $input_imp = LS::Authority::WSDL::Implementation->from_xpath_node($input_imp_node, $xpath) || return;

				push(@imp, $input_imp);
			}
			
			$self->input(\@imp);
		}
	}

	my $output_nodes = $xpath->find('output', $node);
	return if $output_nodes->size > 1;

	if ($output_nodes->size > 0) {
		my $output_node = $output_nodes->get_node(1);
		my $impl_nodes = $xpath->find('*', $output_node);
		
		if ($impl_nodes->size == 1) {
			my $output_imp_node = $impl_nodes->get_node(1);
			my $output_imp = LS::Authority::WSDL::Implementation->from_xpath_node($output_imp_node, $xpath) || return;

			$self->output($output_imp);
		}
		elsif ($impl_nodes->size > 1) {
			my @imp = ();
			
			for(my $i=1; $i<=$impl_nodes->size; $i++) {
				my $output_imp_node = $impl_nodes->get_node($i);
				my $output_imp = LS::Authority::WSDL::Implementation->from_xpath_node($output_imp_node, $xpath) || return;

				push (@imp, $output_imp);
			}

			$self->output(\@imp);
		}
	}

	return $self;
}


1;

__END__