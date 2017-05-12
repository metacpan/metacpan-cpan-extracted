# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::Titlebar;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

use Carp;

sub btnMaximize
{
    my $self = shift;
    my $rv = $self->dig([ "{push button}Maximize" ], +{'max'=>1,'min'=>1} );
    croak unless defined($rv);
    return $rv;
}

sub btnMinimize
{
    my $self = shift;
    my $rv = $self->dig([ "{push button}Minimize" ], +{'max'=>1,'min'=>1} );
    croak unless defined($rv);
    return $rv;
}

sub btnClose
{
    my $self = shift;
    my $rv = $self->dig([ "{push button}Close" ], +{'max'=>1,'min'=>1} );
    croak unless defined($rv);
    return $rv;
}

sub btnRestore
{
    my $self = shift;
    my $rv = $self->dig([ "{push button}Restore" ], +{'max'=>1,'min'=>1} );
    croak unless defined($rv);
    return $rv;
}

package Win32::ActAcc::Window;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);
use Carp;

# If 'lax' flag is set, wrap the default iterator with DelveClientIterator: 
# so the AO's grandchildren (children of the client area) appear to be 
# children of the AO (peers of the client). 
# This is for compatibility with ActAcc 1.0 - it was not a good idea
# to paper over the client area, since it often introduces ambiguity into
# digging for scrollbars, and it doesn't abstract away the red tape of
# Windows as much as the red tape needs to be abstracted away.
sub iterator
{
    my $self = shift;
    my $pflags = shift; 
    my $iter = $self->SUPER::iterator($pflags);
    if (
        ('HASH' eq ref($pflags))
        && $$pflags{'lax'}
        && (ref($iter) ne 'Win32::ActAcc::DelveClientIterator'))
      {
        $iter = new Win32::ActAcc::DelveClientIterator($self, $pflags, ref($iter));
      }
    return $iter;
}

sub mainMenu
{
    my $self = shift;
    # Try menu bar named "Application" (the standard)
    # or, failing that, "Menu Bar" (Office 2002).
    my $menubar = 
      $self->dig([ "{menu bar}Application" ], +{'max'=>1,'min'=>0} ) || 
        $self->dig([ "{menu bar}Menu Bar" ], +{'max'=>1,'min'=>1} );
    croak unless defined($menubar);
    return $menubar;
}

sub systemMenu
{
    my $self = shift;
    my $sysmenu = $self->dig([ "{menu bar}System" ], +{'max'=>1,'min'=>1} );
    croak unless defined($sysmenu);
    return $sysmenu;
}

sub titlebar
{
    my $self = shift;
    my $tbar = $self->dig([ "{title bar}" ], +{'max'=>1,'min'=>1} );
    croak unless defined($tbar);
    return $tbar;
}

# testable('Window::menuPick')
sub menuPick
{
    my $self = shift;
    $self->mainMenu()->menuPick(@_);
}

package Win32::ActAcc::Client;
use strict;
use vars qw(@ISA);
@ISA = qw(Win32::ActAcc::AO);

1;
