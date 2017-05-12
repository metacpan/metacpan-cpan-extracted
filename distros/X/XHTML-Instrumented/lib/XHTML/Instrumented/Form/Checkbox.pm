use strict;
use warnings;

package 
    XHTML::Instrumented::Form::Checkbox;

use base 'XHTML::Instrumented::Form::Select';

use Params::Validate qw (validate);

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
	data => 0,
    });

    my $data = $p{data};
    delete $p{data};

    my $self = bless({ %p }, $class);

    $self->set_select_data(@{$data}) if $data;

    $self;
}

sub args
{
    my $self = shift;
    my %hash = @_;

    if ($self->{type} eq 'select') {
    } else {
	if (my $count = $self->{id_count}) {
	    if (my $value = $self->{control}->{args}->{value}) {

		$hash{value} = $value;
	    } elsif ($self->{values}) {
die 'bob';
	    } else {
		$hash{value} = $count;
	    }
	} else {
	    if (my $value = $hash{value}) {
		if ($self->{values}) {
		    if (grep /$value/, @{$self->{values}}) {
			$hash{checked} = 'checked';
		    }
		}
		if ($self->{default}) {
		    if (grep /$value/, @{$self->{default}}) {
			$hash{checked} = 'checked';
		    }
		}
	    } else {
		if (grep /on/, @{$self->{default}}) {
		    $hash{checked} = 'checked';
		}
	    }
	}
   }
   $self->SUPER::args(%hash);
}

sub expand_content
{
    my $self = shift;

    my $value = $self->{value} || $self->{default};
    require XHTML::Instrumented::Entry;

    for my $option (@{$self->{data}}) {
	if ($self->{value} && $option->{value}
	    && $self->{value} eq $option->{value}) {
	    $option->{selected} = 1;
	}
    }

    my %values = map({ ($_ => 1); } @{$value});

    my @ret = ();
    if ($self->{tag} eq 'select') {
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

		    if ($values{$entry_value}) {
			$entry->{args}{selected} = 'selected';
		    }
		    push(@ret, $entry);
		}
	    }
	}
    }

    @ret;
}

sub is_multi
{
    1;
}

sub checked
{
    my $self = shift;
die qq(fixme check boxes don't work.);
    0;
}

sub set_default
{
    my $self = shift;
    my $value = shift;
    die if @_;

    if (my $type = ref($value)) {
        die unless $type eq 'ARRAY';
	$self->{default} = $value;
    } else {
	$self->{default} = [ $value ];
    }

    my %values = map({ ($_ => 1); } @{$self->{default}});

    for my $element (@{$self->{data} || []}) {
        delete $element->{selected};
	if ($values{$element->value}) {
	    $element->{selected} = 1;
	}
    }
}

sub set_value
{
    my $self = shift;
    my $value = shift;
    die if @_;

    if (my $type = ref($value)) {
        die unless $type eq 'ARRAY';
	$self->{value} = $value;
    } else {
	$self->{value} = [ $value ];
    }

    my %values = map({ ($_ => 1); } @{$self->{value}});

    for my $element (@{$self->{data} || []}) {
        delete $element->{selected};
	if ($values{$element->value}) {
	    $element->{selected} = 1;
	}
    }
}

1;
__END__

=head1 NAME

XHTML::Instrumented::Form::Checkbox - XHTML::Instramented::Form checkbox object

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

=item args

=item expand_content

=item is_multi

=item checked

=item set_default

=item set_value

=back

=head2 Functions

This object has no functions

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
