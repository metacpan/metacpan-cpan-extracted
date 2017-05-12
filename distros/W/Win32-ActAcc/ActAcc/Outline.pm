# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::Outline;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

sub iterator
{
    my $self = shift;
    my $pflags = shift; 
    if (defined($pflags) && $$pflags{'active'})
    {
      my $root = $self->getRoot();
        return new Win32::ActAcc::ArrayIterator($self, +[ $root ]);
    }
    else
    {
        return $self->SUPER::iterator($pflags);
    }
}

sub getRoot
{
    my $self = shift;
    my $rv = $self->accNavigate(Win32::ActAcc::NAVDIR_FIRSTCHILD());  
    return $rv;
}

package Win32::ActAcc::OutlineItem;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

use Data::Dumper;
use Carp;

sub iterator
{
    my $self = shift;
    my $pflags = shift; 
    if (defined($pflags) && $$pflags{'active'})
    {
        return new Win32::ActAcc::OutlineIterator($self);
    }
    else
    {
        return $self->SUPER::iterator($pflags);
    }
}

sub open
{
    my $self = shift;
    my $name = $self->get_accName();
    $self->accDoDefaultAction();
    Win32::ActAcc::IEH()->waitForEvent(
	    +{ 'event'=>Win32::ActAcc::EVENT_OBJECT_STATECHANGE(),
	    'name'=>$name,
	    'role'=>Win32::ActAcc::ROLE_SYSTEM_OUTLINEITEM()});
}

sub getLevel
{
    my $self = shift;
    return $self->get_accValue();
}

sub nextSibling
{
    my $ao = shift;
    my $level = $ao->getLevel();
    my $rv = undef;
    for (;;)
    {
        $ao = $ao->accNavigate(Win32::ActAcc::NAVDIR_NEXT());
        last unless defined($ao);
        my $nl = $ao->getLevel();
        if ($nl < $level) 
        {
            last;
        } 
        elsif ($nl == $level)
        {
            $rv = $ao;
            last;
        }
    }
    return $rv;
}

sub findFirstChildItem
{
    my $self = shift;

    my $level = $self->getLevel();
    if ($self->get_accState() & Win32::ActAcc::STATE_SYSTEM_COLLAPSED()) 
    {
        my $name = $self->get_accName();
        $self->accDoDefaultAction();
	Win32::ActAcc::IEH()->waitForEvent(
		+{ 'event'=>Win32::ActAcc::EVENT_OBJECT_STATECHANGE(),
		'name'=>$name,
		'role'=>Win32::ActAcc::ROLE_SYSTEM_OUTLINEITEM()});
    }

    my $rv;
    while(1)
    {
        # maybe nothing there
        last unless ($self->get_accState() & Win32::ActAcc::STATE_SYSTEM_EXPANDED());

        my $ao = $self->accNavigate(Win32::ActAcc::NAVDIR_NEXT());
        last unless defined($ao);

        last unless $ao->getLevel()==(1+$level);

        $rv = $ao;
        last;
    } 

    return $rv;
}

sub findChildItem
{
    my $self = shift;
    my $quarry = shift; 

    my $ao = $self->findFirstChildItem();
    while (defined($ao) && !$ao->match($quarry))
    {
        $ao = $ao->nextSibling();
    }
    if (!defined($ao))
    {
        croak ("No such " .Dumper($quarry). " under ".$self->describe());
    }
    return $ao;
}

# Do not name the root in the path.
sub outlinenav {
    my $self = shift;
    my $pNodeNamePath = shift;

    my $ao = $self;
    my $crit;
    while (defined($ao) && defined($crit = shift(@$pNodeNamePath)))
    {
        $ao = $ao->findChildItem($crit);
    }

    return $ao;
}

package Win32::ActAcc::OutlineIterator;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;

# testable('OutlineIterator')

sub iterable
{
    my $ao = $_[0]->isa(Win32::ActAcc::Iterator::) ? $_[0]->{'aoroot'} : $_[$#_]; # last argument; so it doesn't matter whether we're invoked as an object or class method
    my $state = $ao->get_accState();
    my $interestingbits = Win32::ActAcc::STATE_SYSTEM_COLLAPSED() 
      | Win32::ActAcc::STATE_SYSTEM_EXPANDED();
    my $relevantstate = $state & $interestingbits;
    return !!$relevantstate;
}

sub open
{
    my $self = shift;

    croak "Must use OutlineIterator only with Outline or OutlineItem (not ".ref($$self{'aoroot'}).")" 
        unless $$self{'aoroot'}->isa('Win32::ActAcc::OutlineItem');
    $$self{'rootlevel'}=$$self{'aoroot'}->getLevel();

    # Expand if necessary
    $$self{'leaveOpen'} = undef;
    $$self{'collapseOnClose'} = 
        ($$self{'aoroot'}->get_accState() & Win32::ActAcc::STATE_SYSTEM_COLLAPSED());
    if ($$self{'collapseOnClose'})
    {
        $$self{'aoroot'}->open();
        $$self{'collapseOnClose'} = 1;
    }

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
        $$self{'ao'} = $$self{'ao'}->nextSibling();
    }
    else
    {
        $$self{'ao'} = $$self{'aoroot'}->findFirstChildItem();
    }
    
    return $$self{'ao'};
}

sub close
{
    my $self = shift;
    croak "Must call open() before close()" unless exists($$self{'opened'});

    if ($$self{'collapseOnClose'} &&!$$self{'leaveOpen'})
    {
        my $name = $$self{'aoroot'}->get_accName();
        $$self{'aoroot'}->accDoDefaultAction();
	Win32::ActAcc::IEH()->waitForEvent(
		+{ 'event'=>Win32::ActAcc::EVENT_OBJECT_STATECHANGE(),
		'name'=>$name,
		'role'=>Win32::ActAcc::ROLE_SYSTEM_OUTLINEITEM()});
    }
    
    delete $$self{'ao'};
    $self->SUPER::close();
}

sub leaveOpen
{
    my $self = shift;
    $$self{'leaveOpen'} = shift;
}


1;
