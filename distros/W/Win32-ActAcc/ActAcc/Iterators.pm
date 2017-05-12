# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)



# iterate through a given set of windows. Performs no AA queries. Ignores aoroot argument (but must be defined).
package Win32::ActAcc::ArrayIterator;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;
use Data::Dumper;

sub new
{
    my $class = shift;
    my $aoroot = shift;
	my $self = Win32::ActAcc::Iterator::new($class, $aoroot);
	$$self{'array'} = shift || +[];
    return $self;
}

sub iterable
{
	1;
}

sub open
{
    my $self = shift;
    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    my $rv = shift(@{$$self{'array'}});
	#print STDERR "Win32::ActAcc::ArrayIterator::nextAO returning $rv\n";
    return $rv;
}

sub close
{
    my $self = shift;
    $self->SUPER::close();
}

package Win32::ActAcc::AONavIterator;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;
use Data::Dumper;

our $AONavFruitsFromNavOnly;

BEGIN
  {
    $AONavFruitsFromNavOnly=0;
  }

sub iterable
{
    my $ao = $_[0]->isa(Win32::ActAcc::Iterator::) ? $_[0]->{'aoroot'} : $_[$#_]; # last argument; so it doesn't matter whether we're invoked as an object or class method
    # Items don't qualify. But (AA weirdness) not all items have a non-CHILDID_SELF id. So you can't tell for sure.
    #warn("No itemID for ".$ao->describe()."\n") unless defined($ao->get_itemID());
    # TBD: If an AO has no child ID, assume it's iterable or not?
    my $id = $ao->get_itemID();
    if (!defined($id)) { $id = Win32::ActAcc::CHILDID_SELF(); }
    return (Win32::ActAcc::CHILDID_SELF() == $id);
}

sub open
{
    my $self = shift;

    my $max = ${$$self{'flags'}}{'max'} || 0;
    $$self{'children'} = +[$$self{'aoroot'}->AccessibleChildren(0,0,$max)];
    my %ch = map(($_->describe(),$_), @{$$self{'children'}});
    my $oi = new Win32::ActAcc::NavIterator($$self{'aoroot'}, $$self{'flags'});
    $oi->open();
    my $oia;
    my $criteria = +{}; 

    while (defined($oia = $oi->nextAO()))
    {
        last if (($max > 0) && (@{$$self{'children'}} >= $max));
        if ($oia->match($criteria))
        {
            my $d = $oia->describe();
            if (!exists($ch{$d}))
            {
                $ch{$d}=$oia;
                push(@{$$self{'children'}}, $oia);
                $AONavFruitsFromNavOnly++;
            }
        }
    }
    $oi->close();
    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    croak "Must call open() before nextAO()" unless exists($$self{'opened'});

    if (exists($$self{'ao'}))
    {
        if (!defined($$self{'ao'}))
        {
            croak "undef has already been returned by nextAO. Hello? Hello?";
        }
    }
    $$self{'ao'} = shift @{$$self{'children'}};
    $self->set_child_source($$self{'ao'});
	#print STDERR "Win32::ActAcc::AONavIterator::nextAO returning $$self{'ao'}\n";    
    return $$self{'ao'};
}

sub close
{
    my $self = shift;

    delete $$self{'ao'};
    $self->SUPER::close();
}


package Win32::ActAcc::NavIterator;
# appears to return only visible items
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;

sub iterable
{
    my $ao = $_[0]->isa(Win32::ActAcc::Iterator::) ? $_[0]->{'aoroot'} : $_[$#_]; # last argument; so it doesn't matter whether we're invoked as an object or class method
    # Items don't qualify. But (AA weirdness) not all items have a non-CHILDID_SELF id. So you can't tell for sure.
    # TBD: If an AO has no child ID, assume it's iterable or not?
    my $id = $ao->get_itemID();
    if (!defined($id)) { $id = Win32::ActAcc::CHILDID_SELF(); }
    return (Win32::ActAcc::CHILDID_SELF() == $id);
}

sub open
{
    my $self = shift;

    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    croak "Must call open() before nextAO()" unless exists($$self{'opened'});

    if (exists($$self{'ao'}))
    {
        if (!defined($$self{'ao'}))
        {
            croak "undef has already been returned by nextAO. Hello? Hello?";
        }
        my $o = $$self{'ao'};
        $$self{'ao'} = $$self{'ao'}->accNavigate(Win32::ActAcc::NAVDIR_NEXT());
        if (defined($$self{'ao'}) && ($o->describe(1) eq $$self{'ao'}->describe(1)))
        {
          #TBD: all these 'describe' too slow? add a 'qnd' or 'unsafe' flag to skip the check?
            warn("NavIterator is ending because of a consecutive duplicate ".$o->describe(1)."\n") unless !$^W;
            $$self{'ao'} = undef;
        }
    }
    elsif ($self->iterable())
    {
        $$self{'ao'} = $$self{'aoroot'}->accNavigate(Win32::ActAcc::NAVDIR_FIRSTCHILD()); 
    }
    else
    {
        $$self{'ao'} = undef;
    }

    $self->set_child_source($$self{'ao'});
	#print STDERR "Win32::ActAcc::NavIterator::nextAO returning $$self{'ao'}\n";   
	
	#print STDERR "     nav:".($$self{'ao'}->describe(1))."\n" unless !defined($$self{'ao'});  
    return $$self{'ao'};
}

sub close
{
    my $self = shift;

    delete $$self{'ao'};
    $self->SUPER::close();
}




package Win32::ActAcc::AOIterator;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;

sub iterable
{
    my $ao = $_[0]->isa(Win32::ActAcc::Iterator::) ? $_[0]->{'aoroot'} : $_[$#_]; # last argument; so it doesn't matter whether we're invoked as an object or class method
    # Items don't qualify. But (AA weirdness) not all items have a non-CHILDID_SELF id. So you can't tell for sure.
    # TBD: If an AO has no child ID, assume it's iterable or not?
    my $id = $ao->get_itemID();
    if (!defined($id)) { $id = Win32::ActAcc::CHILDID_SELF(); }
    return (Win32::ActAcc::CHILDID_SELF() == $id);
}

sub open
{
    my $self = shift;

    my $max = ${$$self{'flags'}}{'max'} || 0;
    $$self{'children'}=+[$$self{'aoroot'}->AccessibleChildren(0,0,$max)];
    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    croak "Must call open() before nextAO()" unless exists($$self{'opened'});

    if (exists($$self{'ao'}))
    {
        if (!defined($$self{'ao'}))
        {
            croak "undef has already been returned by nextAO. Hello? Hello?";
        }
    }
    $$self{'ao'} = shift @{$$self{'children'}};

    $self->set_child_source($$self{'ao'});

	#print STDERR "Win32::ActAcc::AOIterator::nextAO returning $$self{'ao'}\n";    
    return $$self{'ao'};
}

sub close
{
    my $self = shift;
    delete $$self{'ao'};
    $self->SUPER::close();
}



package Win32::ActAcc::DelveClientIterator;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;

# args: class, initial-AO, pkg of iterator to use for client area
sub new
  {
    #print "Arguments to Win32::ActAcc::DelveClientIterator:\n" . Data::Dumper::Dumper(\@_) . "\n";
	my ($class, $aoroot, $flags, $delegateTo) = @_;
    my $self = Win32::ActAcc::Iterator::new($class, $aoroot, $flags);
    $$self{'clientAreaIteratorPkg'} = $delegateTo;
    die("recursive use of DelveClientIterator") if ($$self{'clientAreaIteratorPkg'} eq 'Win32::ActAcc::DelveClientIterator');
    die("Unfortunately $$self{'clientAreaIteratorPkg'} is not an Iterator package") unless UNIVERSAL::isa($$self{'clientAreaIteratorPkg'}, 'Win32::ActAcc::Iterator');
    if (!defined($$self{'clientAreaIteratorPkg'}))
      {
        die("Must specify client-area iterator package");
      }
	return $self;
  }

sub iterable
{
    return 1; # guess
}

sub open
{
    my $self = shift;

    # phases: 1, iterate on the window. 2, iterate on client area. 
    $$self{'phase'} = 1;
    $$self{'client'} = undef;
    
    my $pf = UNIVERSAL::can($$self{'clientAreaIteratorPkg'}, 'new');
    
    $$self{'iter'} = &$pf($$self{'clientAreaIteratorPkg'}, $$self{'aoroot'}, $$self{'flags'}); 
    
    $$self{'iter'}->open();
    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    croak "Must call open() before nextAO()" unless exists($$self{'opened'});
    if ($$self{'phase'} == 3)
    {
        croak "undef has already been returned by nextAO. Hello? Hello?";
    }
    my $rv = $$self{'iter'}->nextAO();
    if (defined($rv) && ($$self{'phase'}==1) && ($rv->get_accRole()==Win32::ActAcc::ROLE_SYSTEM_CLIENT()))
    {
        $$self{'client'} = $rv;
    }
    elsif (!defined($rv) && ($$self{'phase'}==1) && defined($$self{'client'}))
    {
        $$self{'iter'}->close();
        $$self{'phase'} = 2;
        $$self{'iter'} = $$self{'client'}->iterator($$self{'flags'}); # new Win32::ActAcc::AONavIterator($$self{'client'});
        $$self{'iter'}->open();
        $rv = $$self{'iter'}->nextAO();
        if (!defined($rv)) 
        {
            $$self{'phase'} = 3;
        }
    }
    return $rv;
}

sub close
{
    my $self = shift;
    $$self{'iter'}->close();
    $self->SUPER::close();
}

package Win32::ActAcc::get_accChildIterator;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;

sub iterable
{
    my $ao = $_[0]->isa(Win32::ActAcc::Iterator::) ? $_[0]->{'aoroot'} : $_[$#_]; # last argument; so it doesn't matter whether we're invoked as an object or class method
    # Items don't qualify. But (AA weirdness) not all items have a non-CHILDID_SELF id. So you can't tell for sure.
    # TBD: If an AO has no child ID, assume it's iterable or not?
    my $id = $ao->get_itemID();
    if (!defined($id)) { $id = Win32::ActAcc::CHILDID_SELF(); }
    return (Win32::ActAcc::CHILDID_SELF() == $id);
}

sub open
{
    my $self = shift;
    $$self{'idx'} = 1; # 0 is CHILDID_SELF
    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    croak "Must call open() before nextAO()" unless exists($$self{'opened'});
    $$self{'ao'} = $$self{'aoroot'}->get_accChild($$self{'idx'});
    $$self{'idx'} = 1 + $$self{'idx'};

    $self->set_child_source($$self{'ao'});

    return $$self{'ao'};
}

sub close
{
    my $self = shift;

    delete $$self{'ao'};
    $self->SUPER::close();
}







package Win32::ActAcc::TreeTour;
use strict;
use Carp;
use Data::Dumper;

sub new
{
    my $class = shift;
    my $coderef = shift;
    croak "Not a code ref" unless ref($coderef) eq 'CODE';
    my $pflags = shift;
    my $self = +{
                 'code'=>$coderef, 
                 'stop'=>undef, 
                 'level'=>0, 
                 'iterflags'=>+{}};
    if (defined($pflags))
    {
        $$self{'iterflags'} = $pflags;
    }
    bless $self, $class;
    return $self;
}

sub run
{
    my $self = shift;
    my $ao = shift;
    my $ancestors = shift || +[];
	die (ref $ao) unless (UNIVERSAL::isa($ao,'Win32::ActAcc::AO'));

    my $coderef = $$self{'code'};
    undef $$self{'stop'}; 
    $$self{'pin'} = undef;
    $$self{'axis'} = 'child';
    if ($$self{'iterflags'}{'trace'})
      {
        print STDERR ((' ' x (2*$$self{'level'})) . "$ao\n");
      }
    &$coderef($ao, $self);
    if (!$$self{'stop'})
    {
        my $iter;
        if ($$self{'axis'} eq 'child')
		{
			$iter = $ao->iterator($$self{'iterflags'});
			if ($$self{'iterflags'}{'trace'})
			{
				print STDERR 
                  ((' ' x (1+2*$$self{'level'})) 
                   . "Iterator: ".ref($iter)."\n");
			}
			push(@$ancestors, $ao);
		}
		elsif ($$self{'axis'} eq 'parent')
		{
			my $pa = pop(@{$ancestors});
			if (!defined($pa))
			{
				$pa = $ao->parent();
			}
			$iter = new Win32::ActAcc::ArrayIterator($ao, +[$pa]);
		}
		elsif ($$self{'axis'} eq 'prune')
		{
			undef $iter;
		}
		else
		{
			die("don't know what to do with axis $$self{'axis'}\n");
		}
        if (defined($iter) && $iter->iterable())
        {
            $iter->open();
            my $aoi;
            $$self{'level'}++;
            my $pin = undef;
            while (!$$self{'stop'} && defined($aoi = $iter->nextAO()))
            {
				die (ref $aoi) 
                  unless (UNIVERSAL::isa($aoi,'Win32::ActAcc::AO'));
                $self->run($aoi, +[@$ancestors]);
                if ($$self{'pin'})
                {
                    $pin = 1; 
                }
            }
            $$self{'level'}--;
            if ($pin)
            {
                $iter->leaveOpen(1);
            }
            $iter->close();
        }
    }
}

sub level
{
    my $self = shift;
    return $$self{'level'};
}

sub prune
{
    my $self = shift;
    $$self{'axis'} = 'prune';
}

sub axis
{
    my $self = shift;
    my $axis = shift;
    die unless (($axis eq 'parent') || ($axis eq 'child') || ($axis eq 'prune'));
    $$self{'axis'} = $axis;
}

sub stop
{
    my $self = shift;
    $$self{'stop'} = 1;
}

sub pin
{
    my $self = shift;
    $$self{'pin'} = 1;
}

1;
