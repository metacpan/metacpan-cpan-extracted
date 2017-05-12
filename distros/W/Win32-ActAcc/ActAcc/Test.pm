# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) - Window tests

package Win32::ActAcc::Test;
use vars qw(@ISA);
@ISA = qw();
use Carp;
use strict;

sub new
{
    my $class = shift;
	my $self = +{};
	bless $self, $class;
    return $self;
}

sub test
{
	my $self = shift;
	my $ao = shift || croak("No AO specified");
	croak("virtual function");
}

sub describe
{
	my $self = shift;
	my $polka = shift;
	croak("virtual function");
}

sub idescribe
{
	my $self = shift;
	undef;
}

package Win32::ActAcc::Test_dig;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Test);
use Carp;
use strict;

sub new
{
    my $class = shift;
    my $digpath = shift || croak("Must specify digpath");
    croak unless (ref($digpath) eq 'ARRAY');
	my $self = Win32::ActAcc::Test::new($class);
	$$self{'digpath'} = $digpath;
    return $self;
}

# testable('Test_dig::test.positive')
# testable('Test_dig::test.negative')
sub test
{
	my $self = shift;
	my $ao = shift || croak("No AO specified");
	my @m = $ao->dig($$self{'digpath'}, +{'max'=>1, 'min'=>0});
	return scalar(@m);
}

sub describe
{
	my $self = shift;
	my $polka = shift;
	return Win32::ActAcc::AO::describeDigPath($$self{'digpath'});
}

package Win32::ActAcc::Test_not;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Test);
use Carp;
use strict;

sub new
{
    my $class = shift;
    my $othertest = shift || croak("Must specify othertest");
    croak unless UNIVERSAL::isa($othertest,'Win32::ActAcc::Test');
	my $self = Win32::ActAcc::Test::new($class);
	$$self{'othertest'} = $othertest;
    return $self;
}

# testable('Test_not::test.positive')
# testable('Test_not::test.negative')
sub test
{
	my $self = shift;
	my $ao = shift || croak("No AO specified");
	return !($$self{'othertest'}->test($ao));
}

sub describe
{
	my $self = shift;
	my $polka = shift;
	my $s = 'not('. $$self{'othertest'}->describe() . ')';
	if ($polka)
	{
		$s = "*[$s]";
	}
	return $s;
}

package Win32::ActAcc::Test_and;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Test);
use Carp;
use Data::Dumper;
use strict;

sub new
{
    my $class = shift;
    my $othertests = shift || croak("Must specify othertests");
    croak unless (ref($othertests) eq 'ARRAY');
    croak "Not enough othertests" unless scalar(@{$othertests})>0;
	my $self = Win32::ActAcc::Test::new($class);
	$$self{'othertests'} = +[];
	my $ot;
	foreach $ot (@$othertests)
	{
		if (ref($ot) eq 'Win32::ActAcc::Test_and')
		{
			push(@{$$self{'othertests'}}, @{$$ot{'othertests'}});
		}
		else
		{
			push(@{$$self{'othertests'}}, $ot);
		}
	}
    return $self;
}

# testable('Test_and::test.all_positive')
# testable('Test_and::test.shortcut')
sub test
{
	my $self = shift;
	my $ao = shift || croak("No AO specified");
	my $t;
	foreach $t (@{$$self{'othertests'}})
	{
		if (!($t->test($ao)))
		{
			return undef;
		}
	}
	return 1; 
}

sub describe
{
	my $self = shift;
	my $polka = shift;
	my @d;
	my @ad;
	my $it;
	my $s;
	if ($polka)
	{
		foreach $it (@{$$self{'othertests'}})
		{
			my @q = $it->idescribe();
			if (scalar(@q)==2)
			{
				$ad[$q[0]] = $q[1];
			}
			else
			{
				push(@d, $it->describe());
			}
		}
		if (!defined($ad[0]))
		{
			$ad[0] = '*';
		}
		$s = (join('',@ad) . (@d ? '[' . join(' && ', @d) . ']' : '')) ;
	}
	else
	{
		foreach $it (@{$$self{'othertests'}})
		{
			push(@d, $it->describe());
		}
		$s = join(' && ', @d);
	}
	return $s;
} 

package Win32::ActAcc::Test_or;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Test);
use Carp;
use strict;

sub new
{
    my $class = shift;
    my $othertests = shift || croak("Must specify othertests");
    croak unless (ref($othertests) eq 'ARRAY');
    croak "Not enough othertests" unless scalar(@{$othertests})>0;
	my $self = Win32::ActAcc::Test::new($class);
	$$self{'othertests'} = +[];
	my $ot;
	foreach $ot (@$othertests)
	{
		if (ref($ot) eq 'Win32::ActAcc::Test_or')
		{
			push(@{$$self{'othertests'}}, @{$$ot{'othertests'}});
		}
		else
		{
			push(@{$$self{'othertests'}}, $ot);
		}
	}
    return $self;
}

sub test
{
	my $self = shift;
	my $ao = shift || croak("No AO specified");
	my $t;
	foreach $t (@{$$self{'othertests'}})
	{
		if ($t->test($ao))
		{
			return 1;
		}
	}
	return undef; 
}

sub describe
{
	my $self = shift;
	my $polka = shift;
	my $s = '('.join(' || ', map($_->describe(), @{$$self{'othertests'}})).')';
	if ($polka)
	{
		$s = "*[$s]";
	}
	return $s;
}

package Win32::ActAcc::Test_true;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Test);
use Carp;
use strict;

sub new
{
    my $class = shift;
	my $self = Win32::ActAcc::Test::new($class);
    return $self;
}

sub test
{
	my $self = shift;
	my $ao = shift || croak("No AO specified");
	return 1; 
}

sub describe
{
	my $self = shift;
	my $polka = shift;
	my $s = '#t';
	if ($polka)
	{
		$s = "*[$s]";
	}
	return $s;
}

package Win32::ActAcc::Test_visible;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Test);
use Carp;

sub new
{
    my $class = shift;
    my $vis = shift;
    if (!defined($vis))
    {
		$vis = 1;
	}
	my $self = Win32::ActAcc::Test::new($class);
	$$self{'vis'} = $vis;
    return $self;
}

# testable('Test_visible::test.positive')
# testable('Test_visible::test.negative')
sub test
{
	my $self = shift;
	my $ao = shift || croak("No AO specified");
	my $vv = $ao->visible();
	return !$vv==!$$self{'vis'};
}

sub describe
{
	my $self = shift;
	my $polka = shift;
	my $s = $$self{'vis'} ? 'visible' : 'invisible';
	if ($polka)
	{
		$s = "*[$s]";
	}
	return $s;
}

package Win32::ActAcc::Test_get_accName;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Test);
use Carp;
use strict;

sub new
{
    my $class = shift;
    my $s_or_re = shift;
	my $self = Win32::ActAcc::Test::new($class);
	$$self{'s_or_re'} = $s_or_re;
    return $self;
}

# testable('Test_get_accName::test.positive')
# testable('Test_get_accName::test.negative')
sub test
{
	my $self = shift;
	my $ao = shift || croak("No AO specified");
	my $n = $ao->get_accName();
	return ((ref($$self{'s_or_re'}) eq 'Regexp') && ($n =~ $$self{'s_or_re'}) || ($n eq $$self{'s_or_re'}));
}

sub describe
{
	my $self = shift;
	my $polka = shift;
	my $s = (ref($$self{'s_or_re'}) eq 'Regexp')? "qr$$self{'s_or_re'}": "'$$self{'s_or_re'}'";
	return $s;
}

sub idescribe
{
	my $self = shift;
	my $d = $self->describe();
	return (1, $d);
}

package Win32::ActAcc::Test_role_in;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Test);
use Carp;
use strict;

sub new
{
    my $class = shift;
    my $rolelist = shift;
    croak("rolelist must be an ARRAY") unless ref($rolelist)eq 'ARRAY';
	my $self = Win32::ActAcc::Test::new($class);
	$$self{'rolelist'} = $rolelist;

    $$self{'rolemask'} = Win32::ActAcc::vec_allroles(); 
    $$self{'rolebits'} = Win32::ActAcc::vec_from_rolelist($$self{'rolelist'});

    return $self;
}

# testable('Test_role_in::test.positive')
# testable('Test_role_in::test.negative')
sub test
{
	my $self = shift;
	my $ao = shift || croak("No AO specified");
    my $rolenum = $ao->get_accRole();
    my $care = vec($$self{'rolemask'}, $rolenum, 1);
    my $req = vec($$self{'rolebits'}, $rolenum, 1);
	return !$care || $req;
}

sub describe
{
	my $self = shift;
	my $polka = shift;
	if (!defined($$self{'description'}))
	{
		$$self{'description'} =
          Win32::ActAcc::AO::explain_rolemask_rolebits
              ($$self{'rolemask'}, $$self{'rolebits'});
	}
	my $s;
	if ($polka)
	{
		my @s = $self->idescribe();
		$s = (2==@s)?$s[1] : $$self{'description'};
	}
	else
	{
		$s=$$self{'description'};
	}
	return $s;
}

sub idescribe
{
	my $self = shift;
	my $d = $self->describe(0);
	if ($d !~ /\|/)
	{
		return (0, "{$d}");
	}
	else
	{
		return undef;
	}
}


package Win32::ActAcc::Test_state;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Test);
use Carp;
use strict;

sub new
{
    my $class = shift;
    my $has_states = shift; # or'd state bits
    croak "has_states must be a number" unless ref($has_states) eq '';
    my $lacks_states = shift; # or'd state bits
    croak "lacks_states must be a number" unless ref($lacks_states) eq '';
    if (($has_states | $lacks_states) != ($has_states ^ $lacks_states))
    {
		croak("has_states and lacks_states must not overlap (or=".($has_states | $lacks_states)." xor=".($has_states ^ $lacks_states).")");
    }
	my $self = Win32::ActAcc::Test::new($class);
	$$self{'has_states'} = $has_states; 
	$$self{'lacks_states'} = $lacks_states; 
    return $self;
}

# testable('Test_state::test.positive')
# testable('Test_state::test.negative')
sub test
{
	my $self = shift;
	my $ao = shift || croak("No AO specified");
    my $state = $ao->get_accState();
	return (($state & ($$self{'has_states'} | $$self{'lacks_states'})) == $$self{'has_states'});
}

sub describe
{
	my $self = shift;
	my $polka = shift;
	if (!defined($$self{'description'}))
	{
		$$self{'description'} = 
			($$self{'has_states'}?'('. Win32::ActAcc::GetStateTextComposite($$self{'has_states'}).')':'') .
			($$self{'lacks_states'}?'not('. Win32::ActAcc::GetStateTextComposite($$self{'lacks_states'}).')':'') 
			;
	}
	my $s = $polka ? "*[$$self{'description'}]" : $$self{'description'};
	return $s;
}

1;
