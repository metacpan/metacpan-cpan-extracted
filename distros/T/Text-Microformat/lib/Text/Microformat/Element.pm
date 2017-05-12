package Text::Microformat::Element;
use warnings;
use strict;
use Carp;
use UNIVERSAL::require;

use base qw/Class::Data::Inheritable Class::Accessor/;
__PACKAGE__->mk_classdata('_params' => {});   # the params we were initialized with
__PACKAGE__->mk_classdata('_children' => []); # identifiers of the schema children
__PACKAGE__->mk_accessors(qw/_element/);

sub _init {
    my $class = shift;
	my $params = shift;
	croak "params hashref is required" unless defined $params and ref $params eq 'HASH';
	$class->_params($params);
	my $criteria = $params->{criteria};
	if (defined $criteria) {
	    croak "criteria: hashref expected" unless ref $criteria eq 'HASH';
	    while (my($k,$v) = each %$criteria) {
	        if ($k eq 'class' and defined $v and !ref $v) {
	            $criteria->{$k} = Text::Microformat->class_regex($v);
	        }
	    }
	}
	my $schema = $params->{schema};
	if (defined $schema) {
		my @children;
		if (ref $schema eq 'HASH') {
			@children  = keys %$schema;
		}
		elsif (ref $schema eq 'ARRAY') {
			@children = @$schema;
		}
		elsif (!ref $schema) {
			@children = ();
		}
		else {
			croak "Bad schema $schema";
		}
	    $class->_init_child_class($_) for @children;
		$class->mk_accessors(map _to_identifier($_), @children);
		#print STDERR "_init $class: ", join(', ', @children), "\n";
		$class->_children(\@children);
	}
}

sub _to_identifier {
	(my $thing = shift) =~ s/\W+/_/g;
	$thing =~ s/^_//;
	return $thing;
}

sub _default_child_class {
	my $class = shift;
	my $child = shift;
	my $child_class = _to_identifier($child);
	return $class . '::' . $child_class;
}

sub _init_child_class {
	my $class = shift;
	my $child = shift;
	$class->_get_child_class($child, 1);
}

sub _to_criteria {
    my $child = shift;
    return {class => Text::Microformat->class_regex($child)};
}

sub _get_child_class {
	my $class = shift;
	my $child = shift;
	my $init = shift;
	my $schema = $class->_params->{schema};
	my $child_class = _default_child_class($class, $child);
	my $base_class = 'Text::Microformat::Element';
	my %opts;
	# if a specific class is specified in the schema, use it
	if (ref $schema eq 'HASH' and defined $schema->{$child} and !ref $schema->{$child} and length $schema->{$child}) {
		my $spec_class = 'Text::Microformat::Element::' . _to_identifier($schema->{$child});
		$spec_class->require;
		if ($spec_class->_params->{criteria}) {
			$opts{isa_format}++;
			if ($schema->{$child} =~ /^!/) {
    		    $opts{use_child_criteria}++;
    		}
		}
		$base_class = $spec_class;
	}
	if ($init) {
		no strict 'refs';
		@{$child_class.'::ISA'} = $base_class;
		#print STDERR "$child_class ISA $base_class\n";
		if (ref $schema eq 'HASH') {
			if ($opts{isa_format}) {
			    if ($opts{use_child_criteria}) {
			        $child_class->_init({criteria => $base_class->_params->{criteria}, schema => $base_class->_params->{schema}});
			    }
			    else {
			        $child_class->_init({criteria => _to_criteria($child), schema => $base_class->_params->{schema}});
			    }
			}
			else {
				$child_class->_init({criteria => _to_criteria($child), schema => $schema->{$child}});
			}
		}
		else {
			$child_class->_init({criteria => _to_criteria($child)});
		}
	}
	#print STDERR "_get_child_class($class, $child) = $child_class\n";
	return $child_class;	
}

sub Find {
	my $class = shift;
	my $element = shift;
	my @found;
	my $criteria = $class->_params->{criteria};
	croak "missing criteria" unless defined $criteria and ref $criteria eq 'HASH';
	return map ($class->new($_), $element->look_down(
		%{$class->_params->{criteria}},
		Text::Microformat->element_filter($element),
	));
}

sub new {
	my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
	my $element = shift;
	croak 'element is required' unless $element and UNIVERSAL::isa($element, 'HTML::Element');
	
	# Mixin the local_name method
	if (ref $element eq 'HTML::Element') {
	    $element = bless $element, 'Text::Microformat::HTML::Element';
	}
	elsif (ref $element eq 'XML::Element') {
        $element = bless $element, 'Text::Microformat::XML::Element';
    }
    
	$self->_element($element);
	foreach my $child (@{$class->_children}) {
		my $accessor = _to_identifier($child);
		my $child_class = $class->_get_child_class($child);
		$self->$accessor([$child_class->Find($element)]);
	}
	return $self;
}

sub HumanValue {
	my $self = shift;
	return $self->_element->as_trimmed_text;
}

sub MachineValue {
	my $self = shift;
	return $self->_element->attr('title');
}

sub Value {
	my $self = shift;
	return defined $self->MachineValue ? $self->MachineValue : $self->HumanValue;
}

sub ToHash {
	my $self = shift;
	
	if (@{$self->_children}) {
		my %hash;
		foreach my $child (@{$self->_children}) {
			my $accessor = _to_identifier($child);
			if (@{$self->$accessor}) {
				$hash{$child} = [map $_->ToHash, @{$self->$accessor}];
			}
		}
		return \%hash;
	}
	else {
		return $self->Value;
	}
}

sub ToYAML {
	eval {require YAML};
	warn "YAML not found" if $@;
	return YAML::Dump(shift->ToHash);
}

sub GetM {
	my $self = shift;
	my $path = shift;
	return $self->Get($path, 'MachineValue');
}

sub GetH {
	my $self = shift;
	my $path = shift;
	return $self->Get($path, 'HumanValue');
}

sub Get {
	my $self = shift;
	my $path = shift;
	my $accessor = shift || 'Value';
	my $v;
	my $o = $self;
	my @path = map _to_identifier($_), split(/\./, $path);
	while (my $bit = shift @path) {
		last unless UNIVERSAL::can($o, $bit);
		$o = $o->$bit->[0];
		last unless UNIVERSAL::can($o, $accessor);
		$v = $o->$accessor if !@path;
	}
	return $v
}

package Text::Microformat::ML::Element;

use strict;
use warnings;

our @ISA = qw/HTML::Element/;

sub local_name {
    my $self = shift;
    my $tag = $self->tag;
    return $tag unless defined $tag;
    $tag =~ s/^[\w][\w\.-]*://;
    return $tag;
}

package Text::Microformat::HTML::Element;

use strict;
use warnings;

our @ISA = qw/HTML::Element Text::Microformat::ML::Element/;

package Text::Microformat::XML::Element;

use strict;
use warnings;

our @ISA = qw/XML::Element Text::Microformat::ML::Element/;

=head1 NAME

Text::Microformat::Element - a Microformat element

=head1 SEE ALSO

L<Text::Microformat>, L<http://microformats.org>

=head1 AUTHOR

Keith Grennan, C<< <kgrennan at cpan.org> >>

=head1 BUGS

Log bugs and feature requests here: L<http://code.google.com/p/ufperl/issues/list>

=head1 SUPPORT

Project homepage: L<http://code.google.com/p/ufperl/>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Keith Grennan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;