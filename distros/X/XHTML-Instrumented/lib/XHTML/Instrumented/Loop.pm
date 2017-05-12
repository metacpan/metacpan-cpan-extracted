use strict;
use warnings;

package 
    XHTML::Instrumented::Loop;

use base 'XHTML::Instrumented::Control';

use Params::Validate qw (validate ARRAYREF HASHREF);

sub new
{
    my $class = shift;
    my %p = validate(@_, {
       inclusive => 0, 
       headers => {
           optional => 1,
	   type => ARRAYREF,
       },
       data => {
           optional => 1,
	   type => ARRAYREF,
	   depends => [ 'headers' ],
       },
       default => 0,
    } );
    my $self = bless { headers => [], data => [], _count => 0, %p }, $class;

    for (my $x = 0; $x < @{$self->{headers}}; $x++) {
        $self->{hash}{ $self->{headers}[$x] } = $x;
    }

    return $self;
}

sub count
{
    my $self = shift;
    $self->{_count};
}

sub inc
{
    my $self = shift;

    $self->{_count}++;
}

sub _have_data
{
    my $self = shift;
    my @data = @{$self->{data}};
    if ($self->{_count} >= @data) {
        $self->{_count} = 0;
        return 0;
    } else {
        return 1;
    }
}

sub expand_content
{
    my $self = shift;

    my @ret = $self->SUPER::expand_content(@_);

    return @ret;
}

sub get_id
{
    my $self = shift;
    my $id = shift;
    my %hash;
    my $x = 0;

    for my $h (@{$self->{headers}}) {
        $hash{$h} = $x++;
    }

    my $data;

    if (defined $hash{$id}) {
        if ($self->{_count} >= @{$self->{data}}) {
	    if (ref $self->{default} eq 'ARRAY') {
		$data = $self->{default}[$hash{$id}];
	    } else {
		$data = $self->{default} || 'N/A';
	    }
	} else {
	    $data = $self->{data}[$self->{_count}][$hash{$id}];
	}
    }

    return $data;
}

sub if 
{
    my $count = shift->rows;
    $count ? 1 : 0;
}

sub rows
{
    my $self = shift;
    scalar @{$self->{data}};
}

sub children
{
    my $self = shift;

    my %p = validate(@_, {
	context => { isa => 'XHTML::Instrumented::Context' },
	children => ARRAYREF,
    });

    my @ret;

    if ($self->inclusive) {
	my $context = $p{context}->copy;
	@ret = ($self->SUPER::children(@_, context => $context));
    } else {
        while ($self->_have_data) {
	    my $context = $p{context}->copy;
	    push(@ret, $self->SUPER::children(%p, context => $context));
	    $self->inc;
	}
    }
    return @ret;
}

sub to_text
{
    my $self = shift;
    my %p = validate(@_, {
	tag => 1,
        children => ARRAYREF,
        args => HASHREF,
        flags => HASHREF,
	context => { isa => 'XHTML::Instrumented::Context' },
    });
    my @ret;

    my $context = $p{context};

# remove the entire loop element branch if no data
# TODO This may need an option

    my $count = $self->rows;

    die 'if in loop' if (!!$p{flags}->{if});  # A loop never has an if.

    my $inclusive = $self->inclusive;

    if ($p{flags}->{ex}) {
	$inclusive = 0;
    }
    if ($p{flags}->{in}) {
	$inclusive = 1;
    }

    if ($count) {
	if ($inclusive) {
	    my $s = $self->{inclusive};
            $self->{inclusive} = $inclusive;

	    my $x = 1;
	    while (my $q = $self->_have_data) {
                my $x = $context->copy(loop => $self);

		$x->set_count($self);
		push @ret, $self->SUPER::to_text(%p, context => $x);
		$self->inc;
	    }
            $self->{inclusive} = $s;
	} else {
            my $x = $context->copy(loop => $self);

	    push @ret, $self->SUPER::to_text(%p, context => $x);
	}
    }

    return @ret;
}

sub inclusive
{
    my $self = shift;
    $self->{inclusive} || 0;
}

1;
__END__
=head1 NAME

XHTML::Instrumented::Loop - This is I<Control> Object for loop structures

=head1 SYNOPSIS

XHTML::Instrumented::Loop inherits from XHTML::Instrumented::Control;

=head1 API

=head2 Constructor

=over

=item new

  headers => [],
  data => [[]],
  inclusive => I<boolean>,
  default => I<SCALAR>

=back

=head2 Methods

=over

=item count

=item inc

=item _have_data

=item get_id

=item if 

=item rows

=item children

=item to_text

=item inclusive

=item expand_content

=back

=head2 Functions

=over

=back

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
