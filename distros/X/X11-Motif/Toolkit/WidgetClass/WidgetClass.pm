package X11::Toolkit::WidgetClass;

# Copyright 1997 by Ken Fox

use vars qw($VERSION);

$VERSION = 1.0;

package X::Toolkit::WidgetClass;

use Carp;

use strict;

sub add_to_class_registry {
    my $self = shift;
    my $type_name = shift;

    if (defined $X::Toolkit::Widget::class_registry{$type_name}) {
	carp "widget class '$type_name' already defined";
    }
    else {
	if (scalar @_ > 0) {
	    $X::Toolkit::Widget::class_registry{$type_name} = [ $self, @_ ];
	}
	else {
	    $X::Toolkit::Widget::class_registry{$type_name} = $self;
	}
    }
}

sub register {
    my $self = shift;
    my $name = $self->name();

    # ------------------------------------------------------------
    # initialize the widget class registry

    $self->add_to_class_registry($name);
    my $lc_name = lc $name;
    if ($name ne $lc_name) {
	$self->add_to_class_registry($lc_name);
    }

    my $registry = { };
    my $alias = { };

    $X::Toolkit::Widget::resource_registry{$name} = $registry;
    $X::Toolkit::Widget::resource_alias{$name} = $alias;

    # ------------------------------------------------------------
    # inherit any resource aliases from the parent(s).  A special
    # scan is made up the tree in case aliases are defined on
    # unregistered widget classes.  This trades scanning speed
    # for storage space because unregistered widgets don't have
    # any entries in the resource registry.

    my $parent = $self->parent();
    my @parent_list = ();
    my $parent_name;

    while (defined $parent) {
	$parent_name = $parent->name();
	if (defined $X::Toolkit::Widget::resource_alias{$parent_name}) {
	    unshift @parent_list, $parent_name;
	    last if (defined $X::Toolkit::Widget::resource_alias{$parent_name}{'*combined*'});
	}
	$parent = $parent->parent();
    }

    foreach $parent_name (@parent_list) {
	my($key, $value);
	while (($key, $value) = each %{$X::Toolkit::Widget::resource_alias{$parent_name}}) {
	    $alias->{$key} = $value;
	}
    }

    $alias->{'*combined*'} = 1;

    # ------------------------------------------------------------
    # fetch all the resources available for this widget class

    my @raw = $self->resources();
    my $num = scalar @raw;
    my $i;
    my($res_name, $res_class, $res_type, $res_size);

    for ($i = 0; $i < $num; $i += 4) {
	$res_name = $raw[$i];
	$res_class = $raw[$i + 1];
	$res_type = $raw[$i + 2];
	$res_size = $raw[$i + 3];

	if (!defined $registry->{$res_name}) {
	    $registry->{$res_name} = [ $res_class, $res_type, $res_size ];
	    $alias->{lc $res_name} = $res_name;

	    if (!defined $X::Toolkit::Widget::class_converter_to{$res_class}) {
		$X::Toolkit::Widget::class_converter_to{$res_class} = [ ];
	    }

	    if (!defined $X::Toolkit::Widget::type_converter_to{$res_type}) {
		$X::Toolkit::Widget::type_converter_to{$res_type} = [ ];
	    }
	}

	# cache the sizes of resource types so that sub-resources
	# can be registered later without hard-coding resource sizes.

	if (!defined $X::Toolkit::Widget::type_registry{$res_type}) {
	    $X::Toolkit::Widget::type_registry{$res_type} = $res_size;
	}
    }

    # ------------------------------------------------------------
    # register resource aliases defined on this widget class

    $num = scalar @_;
    $i = 0;

    while ($i < $num) {
	$res_name = $_[$i++];
	$alias->{$res_name} = $_[$i++];
    }

    # ------------------------------------------------------------
    # fetch all the constraint resources available for this widget class

    @raw = $self->constraint_resources();

    if (defined @raw)
    {
	$num = scalar @raw;

	$registry = { };
	$alias = { };

	$X::Toolkit::Widget::constraint_resource_registry{$name} = $registry;
	$X::Toolkit::Widget::constraint_resource_alias{$name} = $alias;

	for ($i = 0; $i < $num; $i += 4) {
	    $res_name = $raw[$i];
	    $res_class = $raw[$i + 1];
	    $res_type = $raw[$i + 2];
	    $res_size = $raw[$i + 3];

	    if (!defined $registry->{$res_name}) {
		$registry->{$res_name} = [ $res_class, $res_type, $res_size ];
		$alias->{lc $res_name} = $res_name;

		if (!defined $X::Toolkit::Widget::class_converter_to{$res_class}) {
		    $X::Toolkit::Widget::class_converter_to{$res_class} = [ ];
		}

		if (!defined $X::Toolkit::Widget::type_converter_to{$res_type}) {
		    $X::Toolkit::Widget::type_converter_to{$res_type} = [ ];
		}
	    }
	}
    }
}

sub register_alias {
    my $self = shift;
    my $type_name = shift;

    $type_name = lc $type_name;
    $type_name =~ s|^-||;

    $self->add_to_class_registry($type_name, @_);
}

sub register_subresource {
    my $self = shift;
    my($res_class, $res_name, $res_type) = @_;
    my $name = $self->name();

    my $registry = $X::Toolkit::Widget::resource_registry{$name};

    if (defined($registry) && !defined($registry->{$res_name})) {
	$registry->{$res_name} = [ $res_class, $res_type, $X::Toolkit::Widget::type_registry{$res_type} ];
	$X::Toolkit::Widget::resource_alias{$name}{lc $res_name} = $res_name;
    }
}

1;
