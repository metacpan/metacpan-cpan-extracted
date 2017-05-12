package Tk::FilterEntry;

use vars qw($VERSION);
$VERSION = '0.02';

use strict;
use Tk;
use Tk::Entry;

use base qw(Tk::Derived Tk::Entry);

Construct Tk::Widget 'FilterEntry';

sub ClassInit {
	my ($class, $mw) = @_;

	$class->SUPER::ClassInit($mw);

	$mw->bind($class, '<FocusIn>' => \&FocusIn);
	$mw->bind($class, '<FocusOut>' => \&FocusOut);
	$mw->bind($class, '<Visibility>' => \&FocusOut);
}

sub Populate {
	my ($self, $args) = @_;

	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
			-background		=> ['PASSIVE', 'background', undef, 'white'],
			-fg_valid		=> ['PASSIVE', 'fg_valid', undef, 'black'],
			-fg_invalid		=> ['PASSIVE', 'fg_invalid', undef, 'red'],
			-filter			=> ['PASSIVE', 'filter', undef, '.*'],
			-anchors		=> ['PASSIVE', 'anchors', undef, 1],
			-trim			=> ['PASSIVE', 'trim', undef, 1],
	);
}

sub FocusIn {
	my $self = shift;

	my $fg = $self->cget(-fg_valid);
	$self->Tk::Entry::configure(-foreground => $fg);
}

sub FocusOut {
	my $self = shift;

	my $filter = $self->cget(-filter);
	my $trim = $self->cget(-trim);
	my $anchors = $self->cget(-anchors);
	$filter = '\s*' . $filter . '\s*' if ($trim);
	$filter = '^' . $filter . '$' if ($anchors);
	my $value = $self->get();
	my $r_vcmd = $self->cget(-validatecommand);
	my (@vcmd, $vcmd);
	if (defined $r_vcmd) {
		@vcmd = @{$r_vcmd};
		$vcmd = shift @vcmd;
	}

	if (       ( defined $vcmd and ! &{$vcmd}($self, @vcmd) )
			or ( defined $filter   and ( $value !~ /$filter/ ) ) ) {
		my $fg = $self->cget(-fg_invalid);
		$self->Tk::Entry::configure(-foreground => $fg);
		my $r_invcmd = $self->cget(-invalidcommand);
		if (defined $r_invcmd) {
			my @invcmd = @{$r_invcmd};
			my $invcmd = shift @invcmd;
			&{$invcmd}($self, @invcmd);
		}
	}
}

sub validate {
	my $self = shift;

	my $r_vcmd = $self->cget(-validatecommand);
	if (defined $r_vcmd) {
		my @vcmd = @{$r_vcmd};
		my $vcmd = shift @vcmd;
		return &{$vcmd}($self, @vcmd);
	}

	my $filter = $self->cget(-filter);
	my $trim = $self->cget(-trim);
	my $anchors = $self->cget(-anchors);
	$filter = '\s*' . $filter . '\s*' if ($trim);
	$filter = '^' . $filter . '$' if ($anchors);
	my $value = $self->get();
	return ( $value =~ /$filter/ ) if (defined $filter);

	return 1;
}

1;

__END__

=head1 NAME

Tk::FilterEntry - An entry with filter

=head1 SYNOPSIS

	use Tk::FilterEntry;

	$entry = $parent->FilterEntry(?options?);
	$entry->pack;

=head1 DESCRIPTION

This widget is derived from Tk::Entry and it implements an other way of validation.
The input is validate by a callback or more simply by a filter,
when the entry leaves the focus.
And if is invalid, the foreground color is changed.

So, this widget deals well with textVariable.

=head1 OPTIONS

=head2 -fg_valid
(new option)

The color of the input text when it is valid.

The default value is 'black'.

=head2 -fg_invalid
(new option)

The color of the input text when it is not valid.

The default value is 'red'.

=head2 -filter
(new option)

This filter specifies the valid range of the input.

The filter is used if validatecommand is not defined.

The filter is a Perl regular expression.

The default value is '.*' (every is valid).

=head2 -trim
(new option)

If the boolean value specified is true, the leading and trailing whitespace are
skipped before apply the filter.

The default value is 1.

=head2 -anchors
(new option)

If the boolean value specified is true, the two anchors '^' and '$' are added to the
filter.

The default value is 1.

=head2 -validatecommand
(overloaded option)

This Entry callback is called if defined. The boolean value returned defines
if the input is valid.

The validateCommand and invalidCommand are called with first argument:
the reference of the entry (It is a major different with Tk::Entry)
and following by parameters of the closure.

The default value is <undef>.

=head2 -invalidcommand
(overloaded option)

This Entry callback is called if the return of validateCommand is false
or if the input doesn't match with the pattern.

The default value is <undef>.

=head1 METHODS

=head2 $entry->validate()
(overloaded method)

This command is used to force an evaluation of the validateCommand or of the filter.

It returns boolean.

=head1 EXAMPLE

    my $hour;		# with format HH:mm
    my $e_hour = $mw->FilterEntry(
        -filter          => '[0-2]?\d:[0-5]?\d',
        -invalidcommand  => sub { print "invalid ",shift->get(),"\n" },
        -textvariable    => \$hour,
        -width           => 15,
    );

or

    my $hour;		# with format HH:mm
    my $e_hour = $mw->FilterEntry(
        -validatecommand => sub { shift->get() =~ /^\s*[0-2]?\d:[0-5]?\d\s*$/ },
        -invalidcommand  => sub { print "invalid ",shift->get(),"\n" },
        -textvariable    => \$hour,
        -width           => 15,
    );

or

    my $hour;		# with format HH:mm
    my $e_hour = $mw->FilterEntry(
        -validatecommand => [ sub { $_[0]->get() =~ /$_[1]/ },
                              '^\s*[0-2]?\d:[0-5]?\d\s*$' ],
        -invalidcommand  => sub { print "invalid ",shift->get(),"\n" },
        -textvariable    => \$hour,
        -width           => 15,
    );

=head1 SEE ALSO

L<Tk::Entry>

=head1 COPYRIGHT

(c) 2003 Francois PERRAD, France. All rights reserved.

This library is distributed under the terms of the Artistic Licence.

=head1 AUTHOR

Francois PERRAD, francois.perrad@gadz.org

=cut

