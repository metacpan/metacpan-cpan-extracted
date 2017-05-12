use strict;
use warnings;

package 
    XHTML::Instrumented::Entry;

use XHTML::Instrumented::Control;
use Params::Validate qw(validate HASHREF);

our @unused;

sub new
{
    my $class = shift;

    my %p =  Params::Validate::validate( @_, {
            args => HASHREF,
            flags => HASHREF,
            tag => 1,
            id => 0,
	    name => 0,
	    data => 0,
	    for => 0,
#	    ids => HASHREF,
	}
    );

    bless({ data => [], %p }, $class);
}

sub copy()
{
    my $self = shift;
    my %p =  Params::Validate::validate( @_, {
            args => 0,
            control => { optional => 1, isa => 'XHTML::Instrumented::Control' },
	    data => 0,
	    extra => 0,
            flags => 0,
            form => 0,
	    id => 0,
            special => 0,
            tag => 0,
	}
    );

    bless({
        date => [],
	%{$self},
	args => {%{$self->{args}}},
	%p 
    }, ref($self));
}

sub split_char
{
    '\.';
}

sub child
{
    my $self = shift;
    my %p = Params::Validate::validate(@_,
	{
	    args => 1,
            tag => 1,
	    form => 0,
        }
    );

    my $args = $p{args};
    my $id;
    my $for;
    my @flags;
    if (my $id_full = $args->{id}) {
	($id, @flags) = split($self->split_char, $id_full);
    }
    if (my $id_full = $args->{for}) {
	my @fflags;
	($for, @fflags) = split($self->split_char, $id_full);
    }

    my $ret = ref($self)->new(
        %p,
	flags => { map({ my ($x, @x) = split(':', $_); $x => [@x]} @flags) },
	id => $id,
        name => $args->{name},
	('for' => $for) x!! $for,
    );

    return $ret;
}

sub prepend
{
    my $self = shift;

    for my $child (@_) {
	unshift(@{$self->{data}}, $child);
    }
}

sub id
{
    my $self = shift;
    $self->{id};
}

sub name
{
    my $self = shift;
    $self->{name};
}

# elements that have no id or name can be converted to text here
# or that can happen latter.

sub append
{
    my $self = shift;

    for my $child (@_) {
	push(@{$self->{data}}, $child);
    }

    return;
}

# accesor methods

sub context
{
    my $self = shift;

    die caller;

    $self->{contextu};
}

sub tag
{
    my $self = shift;

    $self->{tag};
}

sub args
{
    my $self = shift;

    %{$self->{args}};
}

sub flags
{
    my $self = shift;

    $self->{flags};
}

# methods

sub are_if
{
    my $self = shift;

    exists $self->{flags}{eq} || exists $self->{flags}{if};
}

sub if
{
    my $self = shift;
    my $ret = 1;

    if (exists $self->{flags}{eq}) {
        $ret = $self->control->eq(@{$self->{flags}{eq}});
    }
    if (exists $self->{flags}{if}) {
	$ret = $self->control->if;
    }

    return $ret;
}

sub control
{
    my $self = shift;

    $self->{control} or die;
}

sub children
{
    my $self = shift;
    my @ret;
    my %p =  Params::Validate::validate( @_, {
            context => { isa => 'XHTML::Instrumented::Context' },
	}
    );

    return @{$self->{data}};
}

# we enter here with the complete parsed datastructure.

sub is_form
{
    my $self = shift;

    $self->{tag} eq 'form';
}

sub is_label
{
    my $self = shift;
    $self->{tag} eq 'label';
}

sub expand
{
    my $self = shift;

    my %p =  Params::Validate::validate( @_, {
            context => { isa => 'XHTML::Instrumented::Context' },
	}
    );
    my $context = $p{context};

    my @ret;
    my $control;

    if ($self->{args}{class}) {

    }

    my $id;

    if ($self->name || $self->id) {
        if ($self->is_form) {
	    if (my $name = $self->name) {
		$control = $context->get_form($name);
		$id = $name;
		if ($control) {
		    $control->{id} = $id;
		    $control->{_ids_} = $self->{_ids_};
		    $control->{_names_} = $self->{_names_};
		}
	    }
	    $context = $context->copy(form => $control);
	    if ($control) {
		die unless $control->is_form;
	    }
	} else {
	    if (my $id = $self->id) {
		$control = $context->get_id($id);
		if ($control->has_name) {
		    $self->{name} = $control->name;
		}
		if (ref $control eq 'XHTML::Instrumented::Control::Dummy') {
		    $control = $context->get_name($id, $control);
		}
	    }
	    if (my $name = $self->name) {
		$control = $context->get_name($name, $control);
	    }
        }
	$control ||= $context->get_id('__dummy__');
    } else {
	$control = $context->get_id('__dummy__');
    }

    $control->set_tag(
	tag => $self->{tag},
	args => $self->{args},
    );
    die unless $control;

    die "no control ($id)" . $control unless UNIVERSAL::isa($control, 'XHTML::Instrumented::Control');

    $self->{control} = $control;

    my $if = $self->if;
    if ($self->{args}{class}) {
	if (grep({ $_ eq ':even'} split('\s', $self->{args}{class}))) {
	    if ($context->{loop}->count % 2 == 0) {
		$if = 0;
	    }
	}
	if (grep({ $_ eq ':odd'} split('\s', $self->{args}{class}))) {
	    if ($context->{loop}->count % 2 == 1) {
		$if = 0;
	    }
	}
    }
   
    if ($self->are_if) {
	$self->{control} = $control = XHTML::Instrumented::Control::Dummy->new(id_count => $control->{id_count});
    }

    if ($if) {
	if ($self->is_label) {
	    if (my $for = $self->{for}) {
		my $control = $context->get_id($for);
		if ($control->required) {
		    $self->{args}{style} .= "color: red;";
		}
	    }
	}

	my @asdf = $control->to_text(
	    tag => $self->{tag},
	    children => [ $self->children(context => $context->copy(form => $control->form)) ],
	    args => { $self->args },
	    flags => $self->flags,
	    context => $context,
	    (special => $self->{flags}{sp}) x!! defined $self->{flags}{sp},
	);

	for (@asdf) {
	    use Data::Dumper;
	    warn Dumper $control, \@asdf unless defined $_;
	}

	push(@ret, @asdf);
    } else {
	my $tag = $self->{tag};
        push(@ret, "<!-- $tag -->");   # Fixme need verbose flag
    }

    if ($self->{args}{class}) {
	if (grep({ $_ eq ':data'} split('\s', $self->{args}{class}))) {
	    $context->inc_loop;
	}
    }

    join('', @ret);
}

1;
__END__

=head1 NAME

XHTML::Instrumented::Entry - This object represents an XHTML element

=head1 SYNOPSIS

This is used internally by XHTML::Instrumented.

=head1 DESCRIPTION

This is used internally by XHTML::Instrumented.

=head1 API

How this object is used.

=over

=back

=head2 Constructors

=over

=item new

This object is normally created by the XHTML::Instrumented parser.

=back

=head2 Methods

=over

=item copy

=item split_char

=item child

=item prepend

=item id

=item name

=item in_loop

=item append

=item context

=item tag

=item args

=item flags

=item if

=item control

=item children

=item is_form

=item is_label

=item expand

=item are_if

=back

=head2 Functions

This Object has no functions.

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
