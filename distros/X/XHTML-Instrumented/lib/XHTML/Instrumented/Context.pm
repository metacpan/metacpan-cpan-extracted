use strict;
use warnings;

package
    XHTML::Instrumented::Context;

use Params::Validate;

sub new
{
    my $class = shift;

    my %p =  Params::Validate::validate( @_, {
            args => 0,
            data => 0,
            flags => 0,
            special => 0,
            loop => 0,
            start => 0,
	    hash => 1,
	}
    );
    bless({ %p }, $class);
}

use Data::Dumper;
sub copy
{
    my $self = shift;

    my %p =  Params::Validate::validate( @_, {
	    merge => 0,
	    form => 0,
	    loop => 0,
	    count => 0,
	}
    );
    if ($p{form}) {
#die 'form ', Dumper $p{form};
    }
    if ($p{merge}) {
        my $merge = $p{merge};
die 'merge';
        delete $p{merge};
	$p{hash} = { %{$self->{hash}}, %$merge };
    }
    my $loop = $self->{loop};

    my $copy = bless({ %$self,  %p }, ref($self));

    if ($loop && ($loop ne $copy->{loop})) {
	push(@{$copy->{loops}}, $loop);
        $copy->{_xcount} = $loop->count + 1;
    }

    $copy;
}

sub get_form
{
    my $self = shift;
    my $id = shift;
    my $ret;

    if (my $loop = $self->{loop}) {
	if ($loop->get_id($id)) {
	    $ret = $loop->get_id($id)->_control;
	    if (my $count = $self->{count} && $ret) {
		$ret->set_id_count($count);
	    }
	}
    }
    if (!$ret) {
	if (UNIVERSAL::isa($self->{hash}{$id}, 'XHTML::Instrumented::Form')) {
	    $ret = $self->{hash}{$id}->_control;
	    if (my $count = $self->{count} && $ret) {
		$ret->set_id_count($count);
	    }
	} else {
	    warn $id, ' is not a form';
	}
    }
    if ($ret && !$ret->is_form) {
	warn $id, ' is not a form';
    }

    return $ret;
}

sub get_name
{
    my $self = shift;
    my $name = shift;
    my $control = shift;
    my $ret;

    if (my $form = $self->{form}) {
	$ret = $form->get_element($name);
    } else {
# this in normal
    }

    if ($ret) {
	$ret->{control} = $control;
	if ($self->{loop}) {
	    $self->set_count($ret);
	}
    }

    $ret || $control;
}

sub set_count
{
    my $self = shift;
    my $ret = shift;

    die caller unless $self->{loop};
    die caller unless $ret->isa('XHTML::Instrumented::Control');

    my $cnt = $self->{loop}->count + 1;

    if (my $x = $self->{_xcount}) {
	$cnt = $x . '.' . $cnt;
    }

    $ret->set_id_count( $cnt );
}

sub get_id
{
    my $self = shift;
    my $id = shift;

    my $ret;

    if (my $loop = $self->{loop}) {
	$ret = $loop->get_id($id);

	if (ref($ret)) {
	    if (my $name = $ret->{args}{name}) {
		$self->{name} = $name;
	    }
	}
    } elsif (my $form = $self->{form}) {
        my $name = $form->{_ids_}{$id};
	my $tmp = $self->{hash}{$id};
        $ret = $form->get_element($name) if $name;
	if ($ret) {
	    if ($tmp && $tmp != $ret) {
die "$tmp $ret";
	    }
	} else {
	    $ret = $tmp;
	}
    } else {
	$ret = $self->{hash}{$id};
    }
    if (defined($ret)) {
	if (!ref($ret)) {
	    $ret = XHTML::Instrumented::Control->new(text => $ret);
	}
    }
    $ret ||= XHTML::Instrumented::Control::Dummy->new();

    if ($self->{loop} && $ret) {
        $self->set_count($ret);
    }
use Data::Dumper;
die "bad control ($id)" . Dumper $self unless UNIVERSAL::isa($ret, 'XHTML::Instrumented::Control');

    return $ret;
}

sub inc_loop
{
    my $self = shift;

    if (my $loop = $self->{loop}) {
        $loop->inc;
    } else {
        warn 'Not in loop';
    }
}

1;
__END__

=head1 NAME

XHTML::Instrumented::Context - Container that holds the current context

=head1 SYNOPSIS

This is used internally by XHTML::Instrumented.

=head1 DESCRIPTION

This is used internally by XHTML::Instrumented.

=head1 API

How this object is used.

=over

=item new

    hash => 1,
    args => 0,
    data => 0,
    flags => 0,
    special => 0,
    loop => 0,
    start => 0,

=back

=head2 Methods

=over

=item copy

Get a deep copy of the context.

=item get_form (I<id>)

Get a form with id I<id>.

=item get_name (I<name>, I<control>)

return the form element named I<name>

=item get_id (I<id>)

Get the control for id I<id>.

=item set_count (I<OBJECT>)

=item inc_loop ()

=back

=head2 Functions

This Object has no functions.

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
