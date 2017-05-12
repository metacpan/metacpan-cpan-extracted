###########################################################################
# Copyright 2000, 2001, 2004 Toby Ovod-Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
##########################################################################
package Win32::CtrlGUI::Criteria;

use 5.006;
use strict;

use Win32::CtrlGUI;

use overload
	'""'  => sub {$_[0]->stringify};

our $VERSION = '0.32'; # VERSION from OurPkgVersion

# ABSTRACT: OO interface for expressing state criteria


sub new {
	my $class = shift;
	my $type = shift;

	$class = "Win32::CtrlGUI::Criteria::".$type;
	return $class->new(@_);
}


sub stringify {
	my $self = shift;

	my $subclass = ref $self;
	$subclass =~ s/^.*:://;
	my $retval = "$subclass:[";

	if (ref $self->{criteria} eq 'Regexp') {
		$retval .= "/".$self->{criteria}."/";
	} elsif (ref $self->{criteria} eq 'CODE') {
		$retval .= 'CODE';
	} elsif (ref $self->{criteria} eq 'SCALAR') {
		$retval .= "\\'".${$self->{criteria}}."'";
	} else {
		$retval .= "'$self->{criteria}'";
	}

	if (defined $self->{childcriteria}) {
		if (ref $self->{childcriteria} eq 'Regexp') {
			$retval .= ", /".$self->{childcriteria}."/";
		} elsif (ref $self->{childcriteria} eq 'CODE') {
			$retval .= ', CODE';
		} else {
			$retval .= ", '$self->{childcriteria}'";
		}
	}

	$retval .= "]";
	return $retval;
}

sub tagged_stringify {
	my $self = shift;

	return [$self->stringify, 'default'];
}


sub is_recognized {
	my $self = shift;

	die "Win32::CtrlGUI::Criteria::is_recognized is an abstract method and needs to be overriden.\n";
}

sub reset {
	my $self = shift;

}

# FIXME: Should these be documented?


###########################################################################
# Win32::CtrlGUI::Criteria::arbitrary
###########################################################################

package Win32::CtrlGUI::Criteria::arbitrary;
@Win32::CtrlGUI::Criteria::arbitrary::ISA = 'Win32::CtrlGUI::Criteria';

sub new {
	my $class = shift;

	my $self = {
		code => shift,
		@_
	};

	bless $self, $class;
	return $self;
}

sub is_recognized {
	my $self = shift;

	return $self->{code}->($self);
}

sub stringify {
	my $self = shift;

	return 'arbitrary';
}


###########################################################################
# Win32::CtrlGUI::Criteria::neg
###########################################################################

package Win32::CtrlGUI::Criteria::neg;
@Win32::CtrlGUI::Criteria::neg::ISA = 'Win32::CtrlGUI::Criteria';

sub new {
	my $class = shift;

	my $self = {
		criteria => $_[0],
		childcriteria => $_[1]
	};

	bless $self, $class;
	return $self;
}

sub is_recognized {
	my $self = shift;

	return scalar(Win32::CtrlGUI::get_windows($self->{criteria}, $self->{childcriteria}, 1)) ? 0 : 1;
}


###########################################################################
# Win32::CtrlGUI::Criteria::pos
###########################################################################

package Win32::CtrlGUI::Criteria::pos;
@Win32::CtrlGUI::Criteria::pos::ISA = 'Win32::CtrlGUI::Criteria';

sub new {
	my $class = shift;

	my $self = {
		criteria => $_[0],
		childcriteria => $_[1]
	};

	bless $self, $class;
	return $self;
}

sub is_recognized {
	my $self = shift;

	return Win32::CtrlGUI::get_windows($self->{criteria}, $self->{childcriteria}, 1);
}




###########################################################################
# Win32::CtrlGUI::Criteria::multi
###########################################################################

package Win32::CtrlGUI::Criteria::multi;

our @ISA = ('Win32::CtrlGUI::Criteria');

our $VERSION = '0.32'; # VERSION from OurPkgVersion

sub new {
	my $class = shift;

	$class eq 'Win32::CtrlGUI::Criteria::multi' and die "$class is an abstract parent class.\n";

	my $self = {
		criteria => [],
		criteria_status => [],
	};

	bless $self, $class;

	while (my $i = shift) {
		if (ref $i eq 'ARRAY') {
			push(@{$self->{criteria}}, Win32::CtrlGUI::Criteria->new(@{$i}));
		} elsif (UNIVERSAL::isa($i, 'Win32::CtrlGUI::Criteria')) {
			push(@{$self->{criteria}}, $i);
		} else {
			my $value = shift;
			if (grep {$_ eq $i} $self->_options) {
				$self->{$i} = $value;
			} else {
				ref $value eq 'ARRAY' or
						die "$class demands ARRAY refs, Win32::CtrlGUI::Criteria objects, or class => [] pairs.\n";
				push(@{$self->{criteria}},  Win32::CtrlGUI::Criteria->new($i, $value));
			}
		}
	}

	scalar(@{$self->{criteria}}) or die "$class demands at least one sub-criteria.\n";

	$self->init;

	return $self;
}

#### _options is a class method that returns a list of known "options" that the
#### class accepts - options are considered to be paired with their value.

sub _options {
	return qw(timeout);
}

#### init gets called when a multi is initialized (i.e. by new) and when it is
#### reset.  It should set the subclass statuses appropriately.

sub init {
	my $self = shift;

	delete($self->{end_time});
}

sub stringify {
	my $self = shift;

	(my $subclass = ref($self)) =~ s/^.*:://;
	return "$subclass(".join(", ", grep(/\S/, $self->{timeout} ? "timeout => $self->{timeout}" : undef), map {$_->stringify} @{$self->{criteria}}).")";
}

sub tagged_stringify {
	my $self = shift;

	(my $subclass = ref($self)) =~ s/^.*:://;
	my $tag = $self->_is_recognized ? 'active' : 'default';

	my(@retval);
	push(@retval, ["$subclass(", $tag]);

	if ($self->{timeout}) {
		my $timeout;
		if ($self->{end_time}) {
			$timeout = ($self->{end_time}-Win32::GetTickCount())/1000;
			$timeout < 0 and $timeout = 0;
			$timeout = sprintf("%0.3f", $timeout);
		} else {
			$timeout = 'wait';
		}
		push(@retval, ["timeout => $timeout", $tag]);
		push(@retval, [", ", $tag]);
	}

	foreach my $i (0..$#{$self->{criteria}}) {
		if (UNIVERSAL::isa($self->{criteria}->[$i], 'Win32::CtrlGUI::Criteria::multi')) {
			push(@retval, $self->{criteria}->[$i]->tagged_stringify);
		} else {
			push(@retval, [$self->{criteria}->[$i]->stringify, $self->{criteria_status}->[$i] ? 'active' : 'default']);
		}
		push(@retval, [", ", $tag]);
	}
	$retval[$#retval]->[0] eq ", " and pop(@retval);

	push(@retval, [")", $tag]);

	return @retval;
}

sub is_recognized {
	my $self = shift;

	$self->_update_criteria_status;

	if ($self->{timeout}) {
		my $rcog = $self->_is_recognized;
		if (ref $rcog || $rcog) {
			if ($self->{end_time}) {
				Win32::GetTickCount() >= $self->{end_time} and return $rcog;
			} else {
				$self->{end_time} = Win32::GetTickCount() + $self->{timeout} * 1000;
			}
		} else {
			delete($self->{end_time});
		}
	} else {
		return $self->_is_recognized;
	}
	return;
}

#### _is_recognized returns whether the state is actively recognized,
#### independent of the timeout. It should be overriden by the subclasses.

sub _is_recognized {
	my $self = shift;

	die "Win32::CtrlGUI::Criteria::multi::_is_recognized is an abstract method and needs to be overriden.\n";
}

sub _update_criteria_status {
	my $self = shift;

	foreach my $i (0..$#{$self->{criteria}}) {
		$self->{criteria_status}->[$i] = $self->{criteria}->[$i]->is_recognized;
	}
}

sub reset {
	my $self = shift;

	$self->SUPER::reset;

	foreach my $crit (@{$self->{criteria}}) {
		$crit->reset;
	}

	$self->init;
}

###########################################################################
# Win32::CtrlGUI::Criteria::and
###########################################################################

package Win32::CtrlGUI::Criteria::and;
@Win32::CtrlGUI::Criteria::and::ISA = ('Win32::CtrlGUI::Criteria::multi');

sub _is_recognized {
	my $self = shift;

	scalar( grep {!$_} @{$self->{criteria_status}} ) and return 0;
	return $self->{criteria_status}->[0];
}

###########################################################################
# Win32::CtrlGUI::Criteria::nand
###########################################################################

package Win32::CtrlGUI::Criteria::nand;
@Win32::CtrlGUI::Criteria::nand::ISA = ('Win32::CtrlGUI::Criteria::multi');

sub _is_recognized {
	my $self = shift;

	return scalar( grep {$_} @{$self->{criteria_status}} ) ? 0 : 1;
}

###########################################################################
# Win32::CtrlGUI::Criteria::or
###########################################################################

package Win32::CtrlGUI::Criteria::or;
@Win32::CtrlGUI::Criteria::or::ISA = ('Win32::CtrlGUI::Criteria::multi');

sub _is_recognized {
	my $self = shift;

	foreach my $status (@{$self->{criteria}}) {
		$status and return $status;
	}
	return 0;
}

###########################################################################
# Win32::CtrlGUI::Criteria::xor
###########################################################################

package Win32::CtrlGUI::Criteria::xor;
@Win32::CtrlGUI::Criteria::xor::ISA = ('Win32::CtrlGUI::Criteria::multi');

sub _is_recognized {
	my $self = shift;

	my $retval;
	my $state;
	foreach my $status (@{$self->{criteria_status}}) {
		$status and $state = !$state;
		defined $retval or $retval = $status;
	}
	$state and return $retval;
	return 0;
}



1;

__END__

=head1 NAME

Win32::CtrlGUI::Criteria - OO interface for expressing state criteria

=head1 VERSION

This document describes version 0.32 of
Win32::CtrlGUI::Criteria, released January 10, 2015
as part of Win32-CtrlGUI version 0.32.

=head1 SYNOPSIS

  use Win32::CtrlGUI::Criteria

  my $criteria = Win32::CtrlGUI::Criteria->new(pos => qr/Notepad/);


  use Win32::CtrlGUI::State

  my $state = Win32::CtrlGUI::State->new(atom => criteria => [pos => qr/Notepad/], action => "!fo");

=head1 DESCRIPTION

C<Win32::CtrlGUI::Criteria> objects represent state criteria, and are used by
the C<Win32::CtrlGUI::State> system to determine when a state has been entered.
There are three main subclasses - C<Win32::CtrlGUI::Criteria::pos>,
C<Win32::CtrlGUI::Criteria::neg>, and C<Win32::CtrlGUI::Criteria::arbitrary>.
These will be discussed in the documentation for C<Win32::CtrlGUI::Criteria>,
rather than in the implementation classes.

=head1 METHODS

=head2 new

The first parameter to the C<new> method is the subclass to create - C<pos>,
C<neg>, or C<arbitrary>. The remaining parameters are passed to the C<new>
method for that class.  Thus, C<Win32::CtrlGUI::Criteria-E<gt>new(pos =>
qr/Notepad/)> is the same as
C<Win32::CtrlGUI::Criteria::pos-E<gt>new(qr/Notepad/)>.

The passed parameters for the C<pos> and C<neg> subclasses are the window
criteria and childcriteria, with the same options available as for
C<Win32::CtrlGUI::wait_for_window>.  The C<pos> subclass will return true (i.e.
the criteria are met) when a window matching those criteria exists.  The C<neg>
subclass will return true when no windows matching the passed criteria exist.
The C<pos> subclass will return a C<Win32::CtrlGUI::Window> object for the
matching window when it returns true.

The C<arbitrary> subclass takes a code reference and a list of hash parameters.
The hash parameters will be added to the C<Win32::CtrlGUI::Criteria::arbitrary>
object, and the code reference will be passed a reference to the
C<Win32::CtrlGUI::Criteria::arbitrary> object at run-time.  This enables the
code reference to use the C<Win32::CtrlGUI::Criteria::arbitrary> to store
state.  The code reference should return true when evaluated if the state
criteria have been met.

=head2 stringify

The C<stringify> method is called by the overloaded stringification operator
and should return a printable string suitable for debug work.

=head2 is_recognized

The C<is_recognized> method is called to determine if the criteria are
currently being met.

=for Pod::Coverage
reset
tagged_stringify

=head1 CONFIGURATION AND ENVIRONMENT

Win32::CtrlGUI::Criteria requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Toby Ovod-Everett  S<C<< <toby AT ovod-everett.org> >>>

Win32::CtrlGUI is now maintained by
Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Win32-CtrlGUI AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Win32-CtrlGUI >>.

You can follow or contribute to Win32-CtrlGUI's development at
L<< http://github.com/madsen/win32-ctrlgui >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Toby Ovod-Everett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
