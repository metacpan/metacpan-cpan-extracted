# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc;

require 5.008_000;
use strict;
use warnings; 
use Carp;
use Text::Trie;
#use Array::Unique;
use Time::HiRes;

use vars qw(
            $VERSION
            %EventName
            $EventName_setup
            %ObjectId
            $ObjectId_setup
            %StateName
            $StateName_setup
            @ISA $VERSION $AUTOLOAD
            @EXPORT @EXPORT_OK %EXPORT_TAGS
            $EMDllFile
            @rolesk %rolesn $rolesn_setup @eventsk @statesk @objidsk @selflagsk @navdirsk
            $IMPLICIT_CLIENT
            $MENU_SLOWNESS
            $LOG_ACTIONS
);

$VERSION = '1.1';
$MENU_SLOWNESS = 1;
$LOG_ACTIONS = 0;

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

require Win32::ActAcc::aaconstlists;

our @export_all = (qw(Desktop 
AccessibleObjectFromEvent 
AccessibleObjectFromWindow 
AccessibleObjectFromPoint
createEventMonitor
GetStateText 
GetRoleText 
GetStateTextComposite
getEvent
waitForEvent
awaitCalm
StateConstantName 
ObjectIdConstantName 
EventConstantName 
clearEvents
GetOleaccVersionInfo
standardEventMonitor
RoleFriendlyNameToNumber
),@rolesk,@eventsk,@statesk,@objidsk,@selflagsk,@navdirsk);

@EXPORT = ();
@EXPORT_OK = @export_all;
%EXPORT_TAGS = 
  ('all'=>+[@export_all],
   'ROLEs'=>+[@rolesk],
   'EVENTs'=>+[@eventsk],
   'STATEs'=>+[@statesk],
   'OBJIDs'=>+[@objidsk],
   'SELFLAGs'=>+[@selflagsk],
   'NAVDIRs'=>+[@navdirsk],
  );

bootstrap Win32::ActAcc $VERSION;

# This AUTOLOAD is used to 'autoload' constants from the constant()
# XS function.  If a constant is not found then control is passed
# to the AUTOLOAD in AutoLoader.
sub AUTOLOAD {
  return if our $AUTOLOAD =~ /::DESTROY$/;
  # Braces used to preserve $1 et al.
  {
    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "'constant' not defined" if $constname eq 'constant';
    $! = undef;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if (($! != 0) || ($val == 0xdeadbeef)) {
      croak "Don't know what to do with $constname";
    }
    return $val;
  }
}

use vars qw(%AO_);

########
our $ieh; # event monitor

sub IEH
{
    if (!defined($ieh))
    {
        $ieh = createEventMonitor(1);
    }
    $ieh;
}

########
# testable('standardEventMonitor')
sub standardEventMonitor
  {
    IEH();
  }

sub createEventMonitor
{
    my $active = shift;
    my $rv = events_register($active);
    die("$^E") unless $rv;
    return $rv;
}

# testable('waitForEvent')
sub waitForEvent
{
    IEH()->waitForEvent(@_);
}

# testable('awaitCalm')
sub awaitCalm
  {
    return IEH()->awaitCalm(@_);
  }

# testable('getEvent')
sub getEvent
  {
    return IEH()->getEvent();
  }

# testable('clearEvents')
sub clearEvents
{
    IEH()->clear();
}

# testable('RoleFriendlyNameToNumber.literal_number')
# testable('RoleFriendlyNameToNumber.role_text')
# testable('RoleFriendlyNameToNumber.constant_name_full')
# testable('RoleFriendlyNameToNumber.constant_name_suffix')
# testable('RoleFriendlyNameToNumber.package_name_full')
# testable('RoleFriendlyNameToNumber.package_name_suffix')

# in: "friendly name" of a role 
#  (number, role text, constant name, package name)
# out: numeric value of role
# error: undef if "friendly name" doesn't ring a bell
sub RoleFriendlyNameToNumber
  {
    my $rolefriendlyname = shift;
    if (!$rolesn_setup)
      {
        # Cache a hash of all possible results.
        $rolesn_setup = 1;
        # loop over ROLE... constant names
        for (@rolesk) 
          {
            # get numeric value
            my $n = eval("$_()");

            # memoize by numeric value
            $rolesn{$n} = $n;
            # memoize result for query by "role text"
            $rolesn{GetRoleText($n)}=$n;
            # memoize result for query by constant-name
            $rolesn{$_}=$n;
            # memoize result by constant-name less standard prefix
            /ROLE_SYSTEM_(.*)$/;
            $rolesn{$1}=$n; 
            # memoize by package name with Win32::ActAcc::
            my $p = GetRolePackage($n);
            $rolesn{$p}=$n;
            # memoize by package name without Win32::ActAcc::
            $p =~ /Win32::ActAcc::(.*)$/;
            $rolesn{$1}=$n; 
        }
    }
    return $rolesn{$rolefriendlyname};
}






my $pStateAbbrev;

sub DistinctAbbreviations
{
	my $min = shift;
	my @whole = @_;
	my @trie = Text::Trie::Trie(@whole);
	my %abbrev;
	my @pfx;
	Text::Trie::walkTrie(
		sub {
			my $tail = shift; 
			my $pfx = join("", @pfx); 
			my $abbr = $pfx . substr($tail,0,1);
			if (length($abbr) < $min)
			{
				$abbr = substr($pfx . $tail, 0, $min);
			}
			$abbrev{$pfx . $tail} = $abbr;
		}, #$singlesub
		sub {my $ad = shift; push(@pfx, $ad); }, #,$headsub
		sub {},#,$notsinglesub
		sub {}, #,$sepsub
		sub {}, #,$opensub
		sub {pop @pfx; }, #,$closesub
		@trie);
	return %abbrev;
}

sub GetStateTextAbbreviations
{
	if (!defined($pStateAbbrev))
	{
		my @statenames;
		#tie @statenames, Array::Unique::; # ActiveState doesn't offer Array::Unique PPM
		push(@statenames, map(Win32::ActAcc::GetStateText(eval("Win32::ActAcc::$_()")), @Win32::ActAcc::statesk));
        my %uniquer = map( ($_,undef), @statenames );
        @statenames = keys(%uniquer);
		my %x = DistinctAbbreviations(1, @statenames);
		$pStateAbbrev = \%x;
	}
	return $pStateAbbrev;
}

# testable('GetStateTextComposite.full')
# testable('GetStateTextComposite.abbrev')
sub GetStateTextComposite
{
	my $bits = shift;
	my $abbrev = shift; #optional
	my @stateTexts;	
	my $abbrevs = GetStateTextAbbreviations() if ($abbrev);
	my $acc = 1;  # bit-0
	for (my $b = 0; $b < 32; $b++)
	{
		if ($bits & $acc)
		{
			my $statename = GetStateText($acc);
			push(@stateTexts, $abbrev && exists($$abbrevs{$statename}) ? $$abbrevs{$statename} : $statename);	
		}
		$acc <<= 1;
	}
	return join('+', @stateTexts);
}

sub mouseop
{
	my $x = shift;
	my $y = shift;
    my $mouseop = shift;
	my $peventMonitorOptional = shift;

    if ($LOG_ACTIONS)
      {
        my $over = AccessibleObjectFromPoint($x, $y) || '';
        print STDERR "Action: Mouse '$mouseop' @ $x,$y  $over\n";
      }

	if (defined($peventMonitorOptional))
	{
		$$peventMonitorOptional->activate(1);
	}
        Win32::ActAcc::IEH()->clear();

	Win32::ActAcc::mouse_button($x, $y, $mouseop);
}

sub click
{
	my $x = shift;
	my $y = shift;
	my $peventMonitorOptional = shift;

    # Delay so two unrelated clicks won't make a double-click.
    my $dct = GetDoubleClickTime();
    #Time::HiRes::usleep(1000 * $dct);

    mouseop($x, $y, 'du', $peventMonitorOptional);
}

sub rightclick
{
	my $x = shift;
	my $y = shift;
	my $peventMonitorOptional = shift;

    mouseop($x, $y, 'DU', $peventMonitorOptional);
}

sub mouseover
{
	my $x = shift;
	my $y = shift;
	my $peventMonitorOptional = shift;

    mouseop($x, $y, 'm', $peventMonitorOptional);
}

# testable('Desktop')
sub Desktop
{
	return AccessibleObjectFromWindow(GetDesktopWindow());
}

# vec_from_rolelist and vec_allroles

sub vec_from_rolelist
{
	my $rolelist = shift;
	croak("rolelist must be an ARRAY") unless ref($rolelist)eq 'ARRAY';
	my $rv = "";
	my $rolespec;
	foreach $rolespec (@$rolelist)
	{
		my $rolenum = RoleFriendlyNameToNumber($rolespec);
		vec($rv, $rolenum, 1) = 1;
	}
	return $rv;
}

sub vec_allroles
{
	# slow the first time
	my $ans = vec_from_rolelist(\@rolesk);
	
	# optimize for next time
    no warnings ('redefine'); # test harness shan't sense failure
	*vec_allroles = sub{ return $ans; };
	
	return $ans;	
}

# deprecated
sub nav
  {
    my $ao = shift;
	my $pChain = shift;

    warn("Win32::ActAcc::nav is deprecated. Please use dig.\n");

	# Default to the desktop window
	$ao = Win32::ActAcc::AccessibleObjectFromWindow(Win32::ActAcc::GetDesktopWindow()) unless defined($ao);

    my $rv = $ao->dig($pChain, +{'max'=>1, 'min'=>0}); 
    return $rv;
  }

# deprecated
sub menuPick
  {
	my $ao = shift;
    my $ppeh = shift; # obsolete.

    warn("Win32::ActAcc::menuPick is deprecated. Please use $ao->menuPick.\n");

    $ao->menuPick(@_);
  }



package Win32::ActAcc::Iterator;
use vars qw(@ISA);
use Carp;
use Scalar::Util qw(weaken);

sub new
{
    my $class = shift;
    my $aoroot = shift;
    my $flags = shift; # optional
    croak "undef iteration root?" unless defined($aoroot);
    my $self = +{'aoroot'=>$aoroot, 'flags'=>+{}};
    if ('HASH' eq ref($flags))
    {
        foreach (keys %$flags)
        {
            ${$$self{'flags'}}{$_} = $$flags{$_};
        }
    }
    bless $self, $class;
    return $self;
}

# in: AO
# out: (none)
sub open
{
    my $self = shift;
    croak("open already") if($$self{'opened'});
    $$self{'opened'} = 1;
}

sub close
{
    my $self = shift;
    croak("Must call open() before close()") unless exists($$self{'opened'});
    delete $$self{'opened'};
}

sub isOpen
{
    my $self = shift;
    return $$self{'opened'};
}

sub all
{
    my $self = shift;
    my @rv;
    my $iopened = !$self->isOpen();
    if ($iopened)
    {
        $self->open();
    }
    my $ao;
    while (defined($ao = $self->nextAO()))
    {
        push @rv, $ao;
    }
    if ($iopened)
    {
        $self->close();
    }
    return @rv;
}

sub leaveOpen
{
    my $self = shift;
    my $lo = shift; # discard
}

sub set_child_source
  {
    my $self = shift;
    my $child = shift;
    if (defined($child)) 
      {
        my $b = $child->baggage();
        die unless 'HASH' eq ref($b);
        $$b{'::source'} = $$self{'aoroot'};
        weaken($$b{'::source'});
      }
  }

require Win32::ActAcc::AO;

require Win32::ActAcc::Event;

require Win32::ActAcc::Outline;

require Win32::ActAcc::Window;

require Win32::ActAcc::Menu;

require Win32::ActAcc::MiscRoles;

require Win32::ActAcc::Iterators;


package Win32::ActAcc;

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

