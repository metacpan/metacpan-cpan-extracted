# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::MenuPopup;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);
use Carp;

# testable('MenuPopup::menuPick')
sub menuPick
{
    Win32::ActAcc::MenuItem::menuPick(@_);
}

sub close
{
  my $self = shift;
  #print "Aha! close() on ".$self->describe()."\n";
  my $skf = UNIVERSAL::can('Win32::GuiTest','SendKeys');
  if ($skf)
    {
      if ($Win32::ActAcc::LOG_ACTIONS)
        {
          print STDERR "Pressing ESC to dismiss menu ".$self->get_accName()."\n";
        }
      &$skf('{ESCAPE}');
    }
  else
    {
      warn("Please 'use Win32::GuiTest' so I can cancel menus using SendKeys.\n");
    }
}


package Win32::ActAcc::Menubar;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);
use Carp;
use Data::Dumper;

sub menuPick
{
    Win32::ActAcc::MenuItem::menuPick(@_);
}

sub open
{
    my $self = shift;
    return $self;
}

sub close
{
  my $self = shift;
  # nop
}

sub iterator
{
    my $self = shift;
    my $pflags = shift; 
    if (defined($pflags) && $$pflags{'active'})
    {
        return new Win32::ActAcc::MenuIterator($self);
    }
    else
    {
        return $self->SUPER::iterator($pflags);
    }
}

package Win32::ActAcc::MenuItem;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);
use Carp;

our $BetweenClicksToCloseThenOpen = 0.25; # seconds
our $MenuPopupRetrospective = 750; # milliseconds
our $MenuStartTimeout = 4; # seconds

sub menuPick
{
    my $self = shift;
    my $pCriteriaList = shift;
    my $pflags = shift;
    if (!defined($pflags)) { $pflags = +{}; }
    croak "flags must be a HASH" unless ref($pflags)eq'HASH';

    my %flags = (%$pflags, 'max'=>1);
    # Do not override min. Let caller decide.
    my $mi = $self->dig($pCriteriaList, \%flags);
    if (defined($mi))
    {
        $mi->accDoDefaultAction();
    }
}

sub open
  {
    my $self = shift;
    my $rv;
    for (my $i = 0; !$rv && ($i < 2); $i++)
      {
        if ($i)
          {
            if ($Win32::ActAcc::LOG_ACTIONS)
              {
                print STDERR "open is going to try again\n";
              }
          }
        $rv = $self->open2();
      }
    return $rv;
  }

sub open2
  {
    my $self = shift;
    
    #print "open: " . $self->describe() . "\n";
    
    my $popup;
    
    # See if MENUPOPUPSTART has already just happened
    Win32::ActAcc::IEH()->dropHistory($MenuPopupRetrospective * $Win32::ActAcc::MENU_SLOWNESS);
    $popup = Win32::ActAcc::IEH()->waitForEvent
      ( +{ 'event'=>Win32::ActAcc::EVENT_SYSTEM_MENUPOPUPSTART() }, 0);
    
    if (defined($popup))
      {
        if ($Win32::ActAcc::LOG_ACTIONS)
          {
            print "Menu was already open\n";
          }
      }
    else
      {
        my $defact = $self->get_accDefaultAction()||"";
        #print "default action = $defact\n";
        if (("Open" ne $defact) && ("Select" ne $defact))
          {
            # close it so we can reopen it and catch the event
            if ($Win32::ActAcc::LOG_ACTIONS)
              {
                print STDERR "open is going to dda to close a presumably-already-open menu...\n";
              }
            $self->accDoDefaultAction(); # HRESULT 80020003, "member not found" ???!
            select(undef,undef,undef,
                   $BetweenClicksToCloseThenOpen * $Win32::ActAcc::MENU_SLOWNESS); #delay
          }
        
        $self->accDoDefaultAction(); # HRESULT 80020003, "member not found" ???!
        if ($@)
          {
            print STDERR " Trying the default action, something happened: $@\n";
          }
        # wait for menu to start. timeout is important since nonfocused windows may ignore menu-start request.
        $popup = Win32::ActAcc::IEH()->waitForEvent
          (
           +{ 'event'=>Win32::ActAcc::EVENT_SYSTEM_MENUPOPUPSTART() }, 
           +{ 'timeout'=>$MenuStartTimeout * $Win32::ActAcc::MENU_SLOWNESS,
              'trace'=>0
            });
        # attempt to focus the popup fails sometimes in XP Explorer.
        #if ($popup)
        #  {
        #    my $pfc = $popup->accNavigate(Win32::ActAcc::NAVDIR_FIRSTCHILD());
        #    print "  popup first child: ".$pfc->describe()."\n";
        #    if ($pfc->get_accState() & Win32::ActAcc::STATE_SYSTEM_FOCUSABLE())
        #      {
        #        $pfc->accSelect(Win32::ActAcc::SELFLAG_TAKEFOCUS());
        #      }
        #  }
        
      }
    return $popup; # which is undef if timeout expired
  }

sub close
{
  my $self = shift;
  #print "Aha! close() on ".$self->describe()."\n";
  my $defact = $self->get_accDefaultAction();
  if ( ($defact eq 'Close') || ($defact eq 'Select')) # bug in Mozilla: action=Select whether menu item is open or closed.
    {
      # $self->Close(); # in XP this works on menubar-items but not popup-menu items
      my $skf = UNIVERSAL::can('Win32::GuiTest','SendKeys');
      if ($skf)
        {
          &$skf('{ESCAPE}');
        }
      else
        {
          warn("Please 'use Win32::GuiTest' so I can cancel menus using SendKeys.\n");
        }
    }
}


sub iterator
{
    my $self = shift;
    my $pflags = shift; 
    if (defined($pflags) && $$pflags{'active'})
    {
        return new Win32::ActAcc::MenuIterator($self);
    }
    else
    {
        return $self->SUPER::iterator($pflags);
    }
}

# Note: accDoDefaultAction wouldn't be needed here except
# that I see "file not found" error in Win XP.
# So reimplement as click.
sub accDoDefaultAction
  {
    my $ao = shift;

    # If it's clickable, click it instead of using DDA. 
    # But if it's not clickable, use DDA.
    if ($ao->visible())
      {
        $ao->mouseover();
        Time::HiRes::sleep(0.2);
        if (defined($Win32::ActAcc::AO::accDoDefaultActionHook))
          {
            &$Win32::ActAcc::AO::accDoDefaultActionHook($ao);
          }
        $ao->click();
      }
    else
      {
        $ao->SUPER::accDoDefaultAction();
      }
  }


package Win32::ActAcc::ButtonMenu;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

package Win32::ActAcc::MenuIterator;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::Iterator);
use Carp;
use Data::Dumper;

our $HoverDwell = 0.25; # seconds

sub iterable
{
    my $ao = $_[0]->isa(Win32::ActAcc::Iterator::) ? $_[0]->{'aoroot'} : $_[$#_]; # last argument; so it doesn't matter whether we're invoked as an object or class method
    my $rv;

    # MS Word 2002 occludes MDI doc-window system-menu behind app toolbar.
    # Crude occlusion check:
    my $center = $ao->center();
    my $whosthere;
    # "Windows Explorer" XP divulges NO LOCATION for its app menubar.
    if ($center)
      {
        $whosthere = Win32::ActAcc::AccessibleObjectFromPoint(@$center);
      }
    if (!$ao->visible())
      {
        $rv = 0;
      }
    elsif (
           $center 
           && !(
                $whosthere->isa(Win32::ActAcc::MenuPopup::) 
                || $whosthere->isa(Win32::ActAcc::Menubar::) 
                || $whosthere->isa(Win32::ActAcc::MenuItem::) ))
      {
        $rv = 0;
        print STDERR "Nonmenu at purported menu location (of $ao) namely $whosthere\n";
      }
    elsif ($ao->isa(Win32::ActAcc::Menubar::))
      {
        $rv = 1;
      }
    # Word 2002 uses 'Open' default action *but not* HASPOPUP state.
    elsif  ($ao->get_accState() & Win32::ActAcc::STATE_SYSTEM_HASPOPUP())
      {
        $rv = 1;
      }
    # Opening the cascading menu now lets us make sure it can be done.
    # OTOH the caller might not choose to open an iterator on it.
    # In Mozilla this causes the popup to be orphaned and remain zombied on the desktop!
    elsif ($ao->visible())
      {
        Win32::ActAcc::mouseover(@$center);
        my $itemDefAct = $ao->get_accDefaultAction()||"";
        $rv = ("Open" eq $itemDefAct) || ("Close" eq $itemDefAct); # Avoid "Execute" and "Select"!
      }
    return $rv;
}

sub open
{
    my $self = shift;
    my $actualMenu = $$self{'aoroot'}->open();
    if (defined($actualMenu))
    {
        $$self{'actualMenu'} = $actualMenu;
        $$self{'iter'} = new Win32::ActAcc::AONavIterator($actualMenu);
        $$self{'iter'}->open();
    }
    $self->SUPER::open();
}

sub nextAO
{
    my $self = shift;
    croak "Must call open() before nextAO()" unless exists($$self{'opened'});

    my $rv;
    if (defined($$self{'iter'}))
    {
        $rv = $$self{'iter'}->nextAO();
    }
    return $rv;
}

sub close
{
    my $self = shift;
    if (defined($$self{'iter'}))
    {
      if (!$$self{'leaveOpen'})
        {
          $$self{'actualMenu'}->close();
        }
      $$self{'iter'}->close();
    }
    $self->SUPER::close();
}

sub leaveOpen
{
    my $self = shift;
    $$self{'leaveOpen'} = shift;
}

1;


__END__

=head1 MENU MODELS

=over 4

=item Notepad (XP)

 menu bar:System {focusable,(116,614,18,25),id=0,00060536}:
  menu item:System {focusable+has popup,(116,614,18,25),id=0,00060536}: Open
   menu item:Restore {unavailable,(119,642,140,21),id=1,(no HWND)}:
   menu item:Move {,(119,663,140,17),id=2,(no HWND)}: Execute
   menu item:Size {,(119,680,140,17),id=3,(no HWND)}: Execute
   menu item:Minimize {,(119,697,140,21),id=4,(no HWND)}: Execute
   menu item:Maximize {,(119,718,140,21),id=5,(no HWND)}: Execute
   separator:(undef) {unavailable,(119,739,140,9),id=6,(no HWND)}:
   menu item:Close {default,(119,748,140,21),id=7,(no HWND)}: Execute

  --- Menubar: menu bar:Application {focusable,(116,640,1466,19),id=0,00060536}:
 menu bar:Application {focusable,(116,640,1466,19),id=0,00060536}:
  menu item:File {focusable+has popup,(116,640,28,19),id=0,00060536}: Open
   menu item:New Ctrl+N {,(119,662,144,17),id=1,(no HWND)}: Execute
   menu item:Open...     Ctrl+O {,(119,679,144,17),id=2,(no HWND)}: Execute
   menu item:Save        Ctrl+S {,(119,696,144,17),id=3,(no HWND)}: Execute
   menu item:Save As... {,(119,713,144,17),id=4,(no HWND)}: Execute
   separator:(undef) {unavailable,(119,730,144,9),id=5,(no HWND)}:
   menu item:Page Setup... {,(119,739,144,17),id=6,(no HWND)}: Execute

=item XEmacs

 menu bar:System {focusable,(715,8,18,25),id=0,00040262}:
  menu item:System {focusable+has popup,(715,8,18,25),id=0,00040262}: Open
   menu item:Restore {unavailable,(718,36,140,21),id=1,(no HWND)}:
   menu item:Move {,(718,57,140,17),id=2,(no HWND)}: Execute
   ...

 menu bar:Application {focusable,(715,34,864,19),id=0,00040262}:
  menu item:File {focusable+has popup,(715,34,28,19),id=0,00040262}: Open  ...
   menu item:Open in Other Window...     C-x 4 f {,(718,73,223,17),id=2,(no HWND)}: Execute
   menu item:Open in New Frame...        C-x 5 f {,(718,90,223,17),id=3,(no HWND)}: Execute
   menu item:Hex Edit File... {,(718,107,223,17),id=4,(no HWND)}: Execute
   menu item:JDE New {has popup,(718,124,223,17),id=0,00e904b6}: Open
    menu item:Class... {,(941,124,95,17),id=1,(no HWND)}: Execute
    menu item:Interface... {,(941,141,95,17),id=2,(no HWND)}: Execute
    menu item:Console... {,(941,158,95,17),id=3,(no HWND)}: Execute
    menu item:EJB {has popup,(941,175,95,17),id=0,00540434}: Open
     menu item:Session Bean {,(1036,175,101,17),id=1,(no HWND)}: Execute
     menu item:Entity Bean {,(1036,192,101,17),id=2,(no HWND)}: Execute
    menu item:Other... {,(941,192,95,17),id=5,(no HWND)}: Execute
    unknown object:(undef) {,(941,192,95,17),id=5,(no HWND)}:
   menu item:Insert File...      C-x i {,(718,141,223,17),id=6,(no HWND)}: Execute

=item Windows Explorer (XP)

  --- Menubar: menu bar:System {focusable,(515,87,18,25),id=0,00050344}: 
 menu bar:System {focusable,(515,87,18,25),id=0,00050344}: 
  menu item:System {focusable+has popup,(515,87,18,25),id=0,00050344}: Open
   menu item:Move {,(526,123,140,17),id=2,(no HWND)}: Execute
   ...
   separator:(undef) {unavailable,(526,199,140,9),id=6,(no HWND)}: 
   menu item:Close {default,(526,208,140,21),id=7,(no HWND)}: Execute

  --- Menubar: menu bar:Application {focusable,(,,,),id=0,(no HWND)}: Close
 menu bar:Application {focusable,(,,,),id=0,(no HWND)}: Close
  menu item:File {focused+focusable+selectable+has popup,(517,114,32,19),id=0,(no HWND)}: Open
   menu item:Open {default,(520,136,165,17),id=1,(no HWND)}: Execute
   ...
   menu item:Open With {has popup,(520,187,165,17),id=0,001b03ca}: Open
    menu item:(undef) {,(685,187,203,19),id=1,(no HWND)}: Execute
    ...
    menu item:(undef) {,(685,282,203,19),id=6,(no HWND)}: Execute
    separator:(undef) {unavailable,(685,301,203,9),id=7,(no HWND)}: 
    menu item:Choose Program... {,(685,310,203,17),id=8,(no HWND)}: Execute

=item Microsoft Word 2002

