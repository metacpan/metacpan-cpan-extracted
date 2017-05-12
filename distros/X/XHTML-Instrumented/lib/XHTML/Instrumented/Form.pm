use strict;
use warnings;

package XHTML::Instrumented::Form;

our $VERSION = '0.09';

use XHTML::Instrumented::Form::Control;
use XHTML::Instrumented::Form::Select;

use Params::Validate qw( validate SCALAR BOOLEAN HASHREF OBJECT ARRAYREF );

use Carp qw (croak carp);

=head1 NAME

XHTML::Instramented::Form - XHTML::Instramented Form Object

=head1 SYNOPSIS

my $template = XHTML::Instrumented->new(name => 'bob');

my $form = $template->get_form(name => 'myform');

=head1 API

=head2 Constructor

=over

=item new

=back

=cut

sub new
{
    my $class = shift;

    my %p = validate(
       @_, {
          action => 0,
          id => 0,
          required => 0,
          name => 0,
          method => 0,
       }
    );

    bless { %p }, $class;
}

sub add_params
{
    my $self = shift;

    $self->{params} = { @_ };

    for my $name (keys %{$self->{params}}) {
        my $element = $self->get_element($name);
	next unless $element;

	$element->set_value($self->{params}{$name});
    }
}

sub add_defaults
{
    my $self = shift;

    $self->{defaults} = { @_ };

    for my $name (keys %{$self->{defaults}}) {
        my $element = $self->get_element($name);
	if ($element) {
	    $element->set_default($self->{defaults}{$name});
	} else {
	    warn 'add defaults ' . $name;
	}
    }
}

sub element_values
{
    my $self = shift;
    my $key = shift or die;

    my @ret;
    @ret = @{ $self->{defaults}{$key} || [] };

    if ($self->{params}{$key}) {
	@ret = @{$self->{params}{$key} || []};
    }

    @ret;
}

sub element_value
{
    my $self = shift;
    my $key = shift or die;

    my @ret;
    @ret = ($self->{defaults}{$key});

    if ($self->{params}{$key}) {
	@ret = @{$self->{params}{$key} || []};
    }

    $ret[0];
}

sub _control
{
    my $self = shift;

    bless { self => $self, }, 'XHTML::Instrumented::Form::Control';
}

sub set_select_data
{
    my $self = shift;
    my %p = validate(@_, {
        name => 1,
	data => ARRAYREF,
    });

    my $select = $self->get_element($p{name});

    croak('No select element found: ' . $p{name}) unless $select;

    $select->set_select_data(@{$p{data}});
}

sub delete_element
{
    my $self = shift;
    my %p = validate(@_, 
        {
	    name => 1,
	}
    );
    my $name = $p{name} or die 'No name for element';
    my $ret = $self->{elements}->{$name};
    delete $self->{elements}->{$name};

    return $ret;
}

sub add_element
{
    my $self = shift;
    my %p = validate(@_, 
        {
	    name => 1,
	    type => 1,
	    required => 0,
	    optional => 0,
	    default => 0,
	    value => 0,
	    data => 0,
	    values => 0,
	    multiple => 0,
	    remove => 0,
	    onclick => 0,
	    onchange => 0,
	    class => 0,
	    package => {
	        optional => 1,
		isa => 'XHTML::Instrumented::Form::ElementControl',
	    },
	}
    );
    my $name = $p{name} or die 'No name for element';

    if ($self->{elements}->{$name}) {
	die "element $name already defined";
    }

    $p{type} ||= 'text';

    if (my $package = $p{package}) {
        delete $p{package};
	$self->{elements}->{$name} = $package->new(%p);
    } elsif ($p{type} eq 'multiselect' or $p{type} eq 'checkbox') {
	require XHTML::Instrumented::Form::Checkbox;
	$self->{elements}->{$name} = XHTML::Instrumented::Form::Checkbox->new(%p);
    } elsif ($p{type} eq 'select') {
	require XHTML::Instrumented::Form::Select;
	$self->{elements}->{$name} = XHTML::Instrumented::Form::Select->new(%p);
    } elsif ($p{type} eq 'hidden') {
	require XHTML::Instrumented::Form::Hidden;
	$self->{elements}->{$name} = XHTML::Instrumented::Form::Hidden->new(%p);
    } else {
	require XHTML::Instrumented::Form::Element;
	$self->{elements}->{$name} = XHTML::Instrumented::Form::Element->new(%p);
    }

    $self->{elements}->{$name};
}

sub set_element
{
    my $self = shift;
    my $args = { @_ };

    my $name = $args->{name} or die 'No name for element';

    my $element = $self->{elements}->{$name};

    for my $key (keys %$args) {
	$element->{$key} = $args->{$key};
    }

    return $element;
}

sub args
{
    my $self = shift;

    %{$self->{elements} || {}};
}

sub params
{
    my $self = shift;
    my $hash = {};
die;
    $hash->{action} = $self->{action} if $self->{action};
    $hash->{method} = $self->{method} if $self->{method};

    $hash;
}

sub context
{
    {
        action => 'bob',
    };
}

sub is_select
{
    my $self = shift;
    my $id = shift || die 'no id.';
    my $ret = 0;
    if (my $element = $self->{elements}{$id}) {
        if ($element->{type} eq 'select') {
            for my $data (@{$element->{data}}) {
		if (defined($data->{value}) && defined($self->element_value($id))
		 && $self->element_value($id) eq $data->{value}) {
		    $data->{selected} = 'selected';
		}
	    }
	}
	[ @{$element->{data}} ];
    } else {
        [];
    }
}

sub get_element
{
    my $self = shift;
    my $name = shift;

    my $ret = $self->{elements}{$name};

    if ($ret) {
	$ret->{_default} = $self->element_value($name);
	$ret->{default} ||= $self->element_value($name);
    }

    return $ret;
}

sub is_element
{
    my $self = shift;
    my $args = { @_ };
    my $ret = 0;

    if (my $name = $args->{name}) {
        if ($self->{elements}{$name}) {
	    $ret = 1;
	}
    }
    $ret;
}

sub auto
{
    my $self = shift;
    my @ret;

    for my $element (keys %{$self->{elements}}) {
        next unless $self->{elements}{$element}{type} eq 'hidden';
	my $x = $self->get_element($element);

	if (ref($x->{value}) eq 'ARRAY') {
	    push(@ret, map({bless({ type => 'hidden', name => $x->{name}, value => $_ }, ref($x) );} @{$x->{value}} ));
	} else {
	    unless (defined $x->{value}) {
		$x->{value} = $self->element_value($element);
	    }
	    push(@ret, $x);
	}
    }

    @ret;
}

sub update_argumants
{
    my $self = shift;
    my $args = { @_ };

    $args->{args};
}

sub name
{
    my $self = shift;

    $self->{name};
}


1;
__END__

=head2 Methods

=over

=item add_params

=item add_defaults

=item element_values

=item element_value

=item set_select_data

=item add_element

=item delete_element

=item set_element

=item args

=item params

=item context

=item is_select

=item get_element

=item is_element

=item auto

=item update_argumants

=item name

  All forms should have a name.  This C<method> will return the name of the form.

=back

=head2 Functions

This object has no functions

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
