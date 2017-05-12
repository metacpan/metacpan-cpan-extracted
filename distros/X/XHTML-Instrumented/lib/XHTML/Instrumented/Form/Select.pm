use strict;
use warnings;

package 
    XHTML::Instrumented::Form::Select;

use base 'XHTML::Instrumented::Form::ElementControl';

use Params::Validate qw( validate ARRAYREF );

use Carp qw(croak);

use XHTML::Instrumented::Form::Option;

sub name
{
    my $self = shift;

    $self->{name};
}

sub new
{
    my $class = shift;
    my %p = validate(@_, {
	name => 1,
	type => 1,
	value => 0,
	required => 0,
	default => 0,
	values => 0,
#	multiple => 0,
	onclick => 0,
	onchange => 0,
	class => 0,
	data => {
	    optional => 1,
	    type => ARRAYREF,
	},
    });

    if ($p{type} eq 'select') {
        my $data = $p{data};
        for my $option (@$data) {
	    unless (defined $option->{value}) {
		$option->{value} = $option->{text};
	    }
	    bless($option, 'XHTML::Instrumented::Form::Option');
	}
    }

    bless({ %p }, $class);
}

sub set_select_data
{
    my $self = shift;

    my @new;
    for my $option (@_) {
	unless (defined $option->{value}) {
	    $option->{value} = $option->{text};
	}
	unless (defined $option->{text}) {
	    $option->{text} = $option->{value};
	}
use Data::Dumper;
	croak Dumper([@_]) .  'set_select_data' unless defined $option->{text};
	push(@new, bless $option,'XHTML::Instrumented::Form::Option');
    }
    $self->{data} = \@new;
}

sub set_default
{
    my $self = shift;

    $self->{default} = shift;
}

sub options
{
    my $self = shift;

    map({ $_; } (@{$self->{data} || []}));
}

sub elements
{
    my $self = shift;

    map({ $_->{value} || $_->{text} } @{$self->{data} || []});
}

sub values
{
    my $self = shift;

    map({ $_->{value} || $_->{text} } @{$self->{values} || []});
}

sub type
{
    my $self = shift;

    $self->{type};
}

sub exp_args
{
    my $self = shift;
    die caller if ref $_[0];
    my @extra = ();

    if ($self->{multiple}) {
	push(@extra, 'multiple', 'multiple');
    }
    if (my $data = $self->{onclick}) {
	push(@extra, 'onclick', $data);
    }

    my $ret = $self->SUPER::exp_args(@_, name => $self->name, @extra);

    $ret;
}

sub expand_content
{
    my $self = shift;

    $self->{value} ||= $self->{default};
    require XHTML::Instrumented::Entry;
    for my $option (@{$self->{data}}) {
	if ($self->{value} && $option->{value}
	    && $self->{value} eq $option->{value}) {
	    $option->{selected} = 1;
	}
    }

    my $value = $self->{value} || $self->{default};

    my @ret;
    if (@{$self->{data}||[]}) {
	@ret = map({ XHTML::Instrumented::Entry->new(
		    tag => 'option',
		    flags => {}, 
		    args => { $_->as_args },
		    data => [ $_->{text} ],
		),
	    } @{$self->{data}}
	);
    } else {
        for my $entry (@_) {
	    if (ref($entry)) {
		my $entry_value = $entry->{args}{value};

                if ($value && $entry_value && $value eq $entry_value) {
		    $entry->{args}{selected} = 'selected';
		}
		push(@ret, $entry);
	    }
	}
    }
    @ret;
}

sub set_value
{
    my $self = shift;
    my $value = shift;
    die if @_;

    if (my $type = ref($value)) {
        die unless $type eq 'ARRAY';
	if (@{$value} == 1) {
	    $self->{value} = $value->[0];
	} elsif (@{$value} == 0) {
	    $self->{value} = '';
	} else {
	    die 'bad data ' . "@{$value}";
	}
    } else {
	$self->{value} = $value;
    }
    $value = $self->{value};
    if (defined $value) {
	for my $element (@{$self->{data} || []}) {
	    delete $element->{selected};
	    if ($value eq ($element->value || '')) {
		$element->{selected} = 1;
	    }
	}
    }
}

sub value
{
    my $self = shift;

    $self->SUPER::value();
}

1;
__END__

=head1 NAME

XHTML::Instrumented::Form::Select - Object to hold select options.

=head1 SYNOPSIS

=head1 API

This normally used by the Form::Select and Form::Checkbox objects
to hold information about the Options available.

=head2 Constructor

=over

=item new

=back

=head2 Methods

=over

=item name

=item set_select_data

=item set_default

=item options

=item elements

=item values

=item type

=item exp_args

=item expand_content

=item set_value

=item value

=back

=head2 Functions

This object has no functions

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
