# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

package Win32::ActAcc::AO;
use strict;

use Win32::ActAcc qw(:ROLEs :EVENTs :STATEs :SELFLAGs);
use Data::Dumper;
use Carp;
use Time::HiRes;

use overload ( '""'=>\&describe );

our $accDoDefaultActionHook; # coderef

# "Memoizing" means saving an accessible object's
# contained-objects in its baggage for quick reference.
# But if circular references result, 
# you may wish to turn off the memoizing.
our $MEMOIZE_MEMBERS = 1;

sub accDoDefaultAction
{
    my $ao = shift;
    if (defined($accDoDefaultActionHook))
    {
        &$accDoDefaultActionHook($ao);
    }
    if ($Win32::ActAcc::LOG_ACTIONS)
      {
        print STDERR "Action: default of  $ao\n";
      }

    $ao->accDoDefaultAction_();
}

# testable('doActionIfDefault.not_default')
# testable('doActionIfDefault.is_default')
# in: AO, action name (as reported by get_accDefaultAction)
# side_effect: performs action if default, else dies.
sub doActionIfDefault
{
    my $ao = shift;
	my $action = shift;
	my $defact = $ao->get_accDefaultAction() || '';
	if ($action eq $defact) 
	{
		$ao->accDoDefaultAction();
	}
	else
	{
		croak("Cannot '$action' when the available action is '$defact'\n");
	}
}

sub describe_meta
{
	return "role:name {state,(location),id,hwnd}: defaultAction"; # keep synchronized with describe()
}

# format==1 suppresses location if AO is invisible.
# format==1 suppresses ID if ID is 0.
sub describe
  {
	my $ao = shift;
	my $format = shift || 0; # default to 0 if not specified
	my $name = $ao->get_accName();
	my $role = "?";
    my $outlineprefix = "";
    my $ir = $ao->get_accRole();
    $role = Win32::ActAcc::GetRoleText($ir); 
    if ($ir == ROLE_SYSTEM_OUTLINEITEM()) 
      { $outlineprefix='>'x($ao->get_accValue()); }
	my $state = "?";
	my $allstate = $ao->get_accState(); 
	if (!defined($allstate)) { $allstate = 0; }
	$state = Win32::ActAcc::GetStateTextComposite($allstate, ($format>0)); 
	my $location;
	if (!($allstate & STATE_SYSTEM_INVISIBLE()))
      {
		my ($left, $top, $width, $height);
		($left, $top, $width, $height) = $ao->accLocation();
		if(defined($height))
          {
            $location = "($left,$top,$width,$height)";
          }
      }
	else
      {
		$location = "";
      }
	my $hwnd = "(no HWND)";
	my $h = $ao->WindowFromAccessibleObject();
	if (defined($h))
      {
        $hwnd = sprintf("HWND=%lx",$h);
      }
	my $itemID = ($format==0)?"(no ID)":"";
	if (defined($ao->get_itemID()) && ($ao->get_itemID()>0))
      {
		$itemID = 'id=' . $ao->get_itemID();
      }
    my $dfltAction = $ao->get_accDefaultAction() || "";
    if (defined($dfltAction)) { $dfltAction=": " . $dfltAction;}
	if ($format==0)
      {
		$name = "(undef)" unless defined($name);
      }
	else
      {
		$name = "" unless defined($name);
      }
	$location = "(location error)" unless defined($location);
	
	# keep the string composition synchronized with describe_meta()
	return 
      "$role:$outlineprefix$name {$state,$location,$itemID,$hwnd}$dfltAction";
  }


use Carp qw(croak verbose carp);
use Data::Dumper;

sub axis_iterator
  {
    my $self = shift;
    my $axis = shift || 'child';
    my $pflags = shift || +{};

    if ('child' eq $axis)
      {
        return $self->iterator($pflags);
      }
    elsif ('parent' eq $axis)
      {
        return new 
          Win32::ActAcc::ArrayIterator($self, +[$self->parent()]);
      }
    elsif ('prune' eq $axis)
      {
        return undef;
      }
    else
      {
        die("Don't know what to do with axis $axis");
      }
  }

sub dig_R
  {
    my $ao = shift;
    my $pCriteriaList = shift;
    my $indent = shift;
    my $pflags = shift;
    my $pfound = shift;
    my $max = shift; # may be undef
    my $iterflags = shift;
    my $guard = shift;
    die unless defined($pfound);
    die if (defined($guard));

    my ($crit, @morecrit) = @{$pCriteriaList};
    my $axis = $$crit{'axis'} || 'child';
    if ($$pflags{'trace'}) {
      print STDERR "${indent}Seeking $axis ".describeCriteria($crit)."\n";
    }
    my $it = $ao->axis_iterator($axis, $iterflags);
    if (!$it || !$it->iterable())
      {
        return;
      }

    $it->open();
    while ( my $aoi = $it->nextAO() ) {
      my $expl = '?';
      my $m = $aoi->match($crit, \$expl);
      if ($$pflags{'trace'}) {
        print STDERR 
          (
           "${indent}Match $aoi? " 
           . ($m ? "yes":"no:$expl") 
           ."\n"
          );
      }
      # "match" should take options hash and do its own trace output.
      if ($m) {
        if (@morecrit) {
          $aoi->dig_R(\@morecrit, '  '.$indent, $pflags, $pfound, $max, $iterflags);
        } else {
          push(@{$pfound}, $aoi);
        }
        if (defined($max) && (@{$pfound} >= $max)) {
          if ($$pflags{'trace'}) {
            print STDERR "${indent}Got enough ($max).. cutting dig short\n";
          }
          last;
        }
      }
    }
    if (defined($max) && 1==$max && 1==@{$pfound})
      {
        $it->leaveOpen(1);
      }
    $it->close();
  }

# testable('dig.1_step') ##
# testable('dig.N_step') ##
# testable('dig.backtrack')

# testable('dig.scalar_context.positive') ##
# testable('dig.scalar_context.negative') ##
# testable('dig.scalar_context.min0.negative')
# testable('dig.scalar_context.outline') ##

# testable('dig.array_context.none') ##
# testable('dig.array_context.capped')
# testable('dig.array_context.min_met') ## 
# testable('dig.array_context.min_not_met') ##

sub dig
  {
    my $self = shift;
    my $path = shift;
    my $pflags = shift || +{};

    croak "Criteria must be a list" unless ref($path) eq 'ARRAY';
    croak "Flags must be a hash" unless ref($pflags) eq 'HASH';

    my $min = defined($$pflags{'min'}) ? $$pflags{'min'} : 1;
    my $max = !wantarray ? 1 : $$pflags{'max'}; # undef for no limit
    my @path = map((ref eq 'HASH' || (UNIVERSAL::isa($_, 'Win32::ActAcc::Test'))) ? $_ : matchHashUpCriteria($_)
                   , ref($path)eq'ARRAY' ? @$path : ((),$path));

    if ($$pflags{'trace'})
      {
        print STDERR "dig: path=\n";
        print STDERR map(describeCriteria($_)."\n", @path);
      }

    my $iterflags = 
      +{
        # Infer 'active' flag if caller didn't specify it.
        'active'=>(exists($$pflags{'active'}) ? $$pflags{'active'} : 1),

        # Convey 'nav' and 'perfunctory' if caller specified them.
        map(
            ((exists($$pflags{$_}) ? ($_=>$$pflags{$_}) : ()),)
            , ('nav', 'perfunctory'))
       };

    my @found;

    $self->dig_R(\@path, ' ', $pflags, \@found, $max, $iterflags);

    if (@found < $min)
      {
        croak("Fewer than $min found (".(0+@found).")");
      }

    if (wantarray)
      {
        return @found;
      }
    else
      {
        return $found[0];
      }
  }

sub center
{
	my $self = shift;
	my $rv = undef;

	my ($left, $top, $width, $height) = $self->accLocation();
    if (defined($left) && defined($top) && defined($width) && defined($height))
      {
        my $centerX = $left + int($width/2);
        my $centerY = $top + int($height/2);
        
        $rv = +[ $centerX, $centerY ];
      }
	return $rv;
}

sub has_clickable_location
  {
    my $self = shift;
    my $rv = undef;
    if ($self->visible())
      {
        my ($left, $top, $width, $height) = $self->accLocation();
        $rv = (defined($left) && $width && $height);
      }
    return $rv;
  }

# testable('AO::click')
# die if AO invisible
sub click
{
	my $self = shift;
	my $peventMonitorOptional = shift;
    croak("Can't click an invisible AO") 
      unless $self->has_clickable_location();
	my $c = $self->center();
	Win32::ActAcc::click(@$c,$peventMonitorOptional);
}

# testable('AO::rightclick')
# die if AO invisible
sub rightclick
{
	my $self = shift;
	my $peventMonitorOptional = shift;
    die if (!$self->has_clickable_location());
	my $c = $self->center();
	Win32::ActAcc::rightclick(@$c,$peventMonitorOptional);
}

# testable('AO::mouseover')
# harmless/no action if the AO is not visible.
sub mouseover
{
	my $self = shift;
	my $peventMonitorOptional = shift;

    if ($self->has_clickable_location())
      {
        my $c = $self->center();
        Win32::ActAcc::mouseover($$c[0]-2, $$c[1]-2, undef);
        # pause ever-so-briefly - so app might tend to the mousemove
        Time::HiRes::sleep(0.01);
        Win32::ActAcc::mouseover(@$c,$peventMonitorOptional);
        # pause ever-so-briefly - so app might tend to the mousemove
        Time::HiRes::sleep(0.01);
      }
}

# testable('AO::context_menu')
sub context_menu
  {
	my $self = shift;
    $self->rightclick();
    my $cxmenu = Win32::ActAcc::waitForEvent(+{'event'=>EVENT_SYSTEM_MENUPOPUPSTART()}, 5);
    croak("No context menu found") unless defined($cxmenu);
    return $cxmenu;
  }

sub debug_tree
{
	my $ao = shift;
        $ao->tree(sub{my $ao=shift;my $tree=shift;print ' 'x($tree->level()).$ao->describe."\n";});
}

# TODO - Convert all matching to use the Test packages.

sub match
{
    my $self = shift;
    my $crit = shift; # string(name OR {role}name) OR regexp OR coderef 
                      # OR hash{code,name(string/regexp),role (numeric),state}
    my $mismatch = shift;
    my $rv = $self->match_($crit,$mismatch ) || '';
    #print STDERR "match OF ".$self->describe() ." AGAINST " .Dumper($crit). " YIELDS ".$rv ."\n";
    return $rv;
}

sub matchHashUpCriteria
{
    my $crit = shift; # string(name OR {role}name) OR regexp OR coderef 
                      # OR hash{code,name(string/regexp),role (numeric),state}
    my $rcrit = ref($crit);

    if ($rcrit eq 'HASH')
    {
        if (exists($$crit{'rolename'}))
        {
            $$crit{'role'}=Win32::ActAcc::RoleFriendlyNameToNumber($$crit{'rolename'});
            delete $$crit{'rolename'};
        }
        return $crit;
    }
    elsif ($rcrit eq 'Regexp')
    {
        return +{'name'=>$crit, 'visible'=>1};
    }
    elsif ($rcrit eq 'CODE')
    {
        return +{'code'=>$crit, 'visible'=>1};
    }
    elsif ($rcrit eq '')
    {
	my $seekingRole = undef;
	my $seekingName = $crit || '';
	if ($seekingName =~ /^\{(.*)\}(.*)/)
	{
      my $rolefrn = $1;
		$seekingRole = Win32::ActAcc::RoleFriendlyNameToNumber($rolefrn);
                croak "No such role as $rolefrn" unless defined($seekingRole);
		$seekingName = $2;
	}
	if (0==length($seekingName)) { $seekingName = undef; }
        my %h;
        $h{'name'}=$seekingName unless !defined($seekingName);
        $h{'role'}=$seekingRole unless !defined($seekingRole);
        $h{'visible'}=1;
        return \%h;
    }
    else
    {
        croak "Don't know what to do with criteria ref $rcrit";
    }
}

sub describeDigPath
{
	my $path = shift;
	return join('/', map(describeCriteria($_), @$path));
}

sub describeCriteria
{
    my $nhcrit = shift; 
	my $rv;
    if (UNIVERSAL::isa($nhcrit, 'Win32::ActAcc::Test'))
	{
		$rv = $nhcrit->describe(1);
	}
    else
    {
		my @rv;
		my $crit = matchHashUpCriteria($nhcrit);
		foreach (qw(name get_accRole rolename get_accName get_accValue get_accDescription get_accHelp get_accDefaultAction axis nonnegative_coordinates))
		{
			if (exists($$crit{$_}))
			{
				push @rv, "$_='$$crit{$_}'";
			}
		}
		foreach (qw(WindowFromAccessibleObject HWND))
		{
			if (exists($$crit{$_}))
			{
				push @rv, sprintf("$_=%08x", $$crit{$_});
			}
		}
		if (exists($$crit{'role'}))
		{
			push @rv, "role=". Win32::ActAcc::GetRoleText($$crit{'role'});
		}
		if (exists($$crit{'state'}) && exists(${$$crit{'state'}}{'value'}))
		{
			push @rv, "state-value=". Win32::ActAcc::GetStateTextComposite(${$$crit{'state'}}{'value'});
		}
		if (exists($$crit{'rolemask'}))
		{
          push @rv, explain_rolemask_rolebits($$crit{'rolemask'}, 
                                              $$crit{'rolebits'});
		}
		if (exists($$crit{'code'}))
		{
			push @rv, "code(...)";
		}
		if (exists($$crit{'test'}))
		{
			push @rv, ('['.$$crit{'test'}->describe().']');
		}

		$rv = join(',',@rv);
		if ($rv eq '' )
		{
			$rv = "match anything (no restrictions)"
		}
	}
    return $rv;
}

sub explain_rolemask_rolebits
  {
    my $rolemask = shift;
    my $rolebits = shift;
    my @allow;
    my @deny;
    my $maskt = unpack('b*', $rolemask);
    my $bitst = unpack('b*', $rolebits);
    my $imax = length($maskt);
    for (my $i = $imax-1; $i >= 0; $i--)
      {
        if ('1'eq substr($maskt,$i,1))
          {
            if ((length($bitst)>$i) && 
                ('1'eq substr($bitst,$i,1)))
              {
                push @allow, $i;
              }
            else
              {
                push @deny, $i;
              }
          }
      }
    my $rv;
    if (@allow <= @deny)
      {
        $rv = "role(".
          join(',',
               map(Win32::ActAcc::GetRoleText($_), @allow))
            .")";
      }
    else
      {
        $rv = "role-NOT(".
          join(',',
               map(Win32::ActAcc::GetRoleText($_), @deny))
            .")";
      }
    return $rv;
  }

sub match_string_or_re
{
    my $candidate = shift || ''; # string
    my $pattern = shift; # string or regexp
    if (ref($pattern) eq 'Regexp')
    {
        return ($candidate =~ /$pattern/);
    }
    else
    {
        return ($candidate eq $pattern);
    }
}

sub match_
{
    my $self = shift;
    my $crit = shift; # string(name OR {role}name) OR regexp OR coderef 
                      # OR hash{code,name(string/regexp),role (numeric),state}
    my $mismatch = shift;
    my $rcrit = ref($crit);

	if (UNIVERSAL::isa($crit, 'Win32::ActAcc::Test'))
	{
		return $crit->test($self);
	}
    elsif ($rcrit eq 'HASH')
    {
		# Normalize.  Translate rolename->role, visible->state.
		# We *alter the hash we were given* so if it's reused,
		# this step doesn't need to be done again.
        if (exists($$crit{'rolename'}))
        {
            $$crit{'role'}=Win32::ActAcc::RoleFriendlyNameToNumber($$crit{'rolename'});
            delete $$crit{'rolename'};
        }
        if (exists($$crit{'get_accRole'}))
        {
            $$crit{'role'}=$$crit{'get_accRole'};
            delete $$crit{'get_accRole'};
        }
        if (exists($$crit{'get_accName'}))
        {
            $$crit{'name'}=$$crit{'get_accName'};
            delete $$crit{'get_accName'};
        }
        if (exists($$crit{'WindowFromAccessibleObject'}))
        {
            $$crit{'HWND'}=$$crit{'WindowFromAccessibleObject'};
            delete $$crit{'WindowFromAccessibleObject'};
        }
        if (exists($$crit{'state_has'}))
        {
			if (!exists($$crit{'state'}))
			{
				$$crit{'state'} = +{ 'mask'=>0, 'value'=>0 };
			}
			${$$crit{'state'}}{'mask'} |= $$crit{'state_has'};
			${$$crit{'state'}}{'value'} |= $$crit{'state_has'};
            delete $$crit{'state_has'};
        }
        if (exists($$crit{'state_lacks'}))
        {
			if (!exists($$crit{'state'}))
			{
				$$crit{'state'} = +{ 'mask'=>0, 'value'=>0 };
			}
			${$$crit{'state'}}{'mask'} |= $$crit{'state_lacks'};
			${$$crit{'state'}}{'value'} &= ~$$crit{'state_lacks'};
            delete $$crit{'state_lacks'};
        }
        if (exists($$crit{'role'}))
        {
          # Note: hard-coded limit on number of roles. 
			$$crit{'rolemask'} = pack('b*', '1'x100);
            if (!exists($$crit{'rolebits'})) { $$crit{'rolebits'}=''; }
			vec($$crit{'rolebits'}, $$crit{'role'}, 1) = 1;
            delete $$crit{'role'};
        }
        if (exists($$crit{'role_in'}))
        {
			my $rolespec;
			foreach $rolespec (@{$$crit{'role_in'}})
			{
				my $rolenum = Win32::ActAcc::RoleFriendlyNameToNumber($rolespec);
                if (!exists($$crit{'rolebits'}))
                  {
                    $$crit{'rolebits'} = 0;
                  }
				vec($$crit{'rolebits'}, $rolenum, 1) = 1;
			}
			$$crit{'rolemask'} = pack('b*', '1'x100);
			delete $$crit{'role_in'};
        }
        if (exists($$crit{'role_not_in'}))
        {
			my $rolespec;
			foreach $rolespec (@{$$crit{'role_not_in'}})
			{
				my $rolenum = Win32::ActAcc::RoleFriendlyNameToNumber($rolespec);
				vec($$crit{'rolebits'}, $rolenum, 1) = 0;
			}
			$$crit{'rolemask'} = pack('b*', '1'x100);
			delete $$crit{'role_not_in'};
        }
       
        # Match.
        if (exists($$crit{'rolebits'}) && exists($$crit{'rolemask'}))
        {
            my $rolenum = $self->get_accRole();
            my $care = vec($$crit{'rolemask'}, $rolenum, 1);
            my $req = vec($$crit{'rolebits'}, $rolenum, 1);
            
            if (!(!$care || $req))
            {
				if (defined($mismatch)) { $$mismatch="role"; }
				return undef;
            }
        }
        if (exists($$crit{'name'}))
        {
			if (!match_string_or_re($self->get_accName(), $$crit{'name'}))
            {
                if (defined($mismatch)) { $$mismatch='name'; }
                return undef;
            }
        }
        if (exists($$crit{'state'}))
        {
            croak unless exists(${$$crit{'state'}}{'mask'});
            croak unless exists(${$$crit{'state'}}{'value'});
            my $s = $self->istate(); 
            if (!defined($s))
            {
                if (defined($mismatch)) { $$mismatch='state-value(ao state not available)'; }
                return undef;
            }
            my $mask = ${$$crit{'state'}}{'mask'};
            my $val = ${$$crit{'state'}}{'value'};
            $s = $s & $mask;
            if ($s != $val)
            {
                if (defined($mismatch)) { $$mismatch='state-value'; }
                return undef;
            }
        }
        if (exists($$crit{'visible'}))
          {
            my $vv = $self->visible();
            return (!$vv == !$$crit{'visible'});
          }
        if (exists($$crit{'get_accHelp'}))
        {
			if (!match_string_or_re($self->get_accHelp(), $$crit{'get_accHelp'}))
            {
                if (defined($mismatch)) { $$mismatch='get_accHelp'; }
                return undef;
            }
        }
        if (exists($$crit{'get_accValue'}))
        {
			if (!match_string_or_re($self->get_accValue(), $$crit{'get_accValue'}))
            {
                if (defined($mismatch)) { $$mismatch='get_accValue'; }
                return undef;
            }
        }
        if (exists($$crit{'get_accDescription'}))
        {
			if (!match_string_or_re($self->get_accDescription(), $$crit{'get_accDescription'}))
            {
                if (defined($mismatch)) { $$mismatch='get_accDescription'; }
                return undef;
            }
        }
        if (exists($$crit{'get_accDefaultAction'}))
        {
			if (!match_string_or_re($self->get_accDefaultAction(), $$crit{'get_accDefaultAction'}))
            {
                if (defined($mismatch)) { $$mismatch='get_accDefaultAction'; }
                return undef;
            }
        }
        if (exists($$crit{'HWND'}))
        {
			if ($self->WindowFromAccessibleObject() != $$crit{'HWND'})
            {
                if (defined($mismatch)) { $$mismatch='HWND'; }
                return undef;
            }
        }
        if (exists($$crit{'nonnegative_coordinates'}))
        {
			my ($left, $top, $width, $height) = $self->accLocation();
			my $nonneg = defined($height) && ($left + $width > -1) && ($top + $height > -1);
			if (!!$nonneg != !!$$crit{'nonnegative_coordinates'})
            {
                if (defined($mismatch)) { $$mismatch='nonnegative_coordinates'; }
                return undef;
            }
        }
        if (exists($$crit{'test'}))
        {
			if (!$$crit{'test'}->test($self))
			{
                if (defined($mismatch)) { $$mismatch='test'; }
                return undef;
            }
        }
        if (exists($$crit{'code'}))
        {
            $_=$self; 
            my $rv = &{$$crit{'code'}}($self, $crit, $mismatch);
            if (!$rv && defined($mismatch) && !defined($$mismatch))
            {
                $$mismatch='code';
            }
            return $rv;
        }
        return 1;
    }
    else
    {
        return $self->match_(matchHashUpCriteria($crit), $mismatch);
    }
}

# in: AO (known to be child of a *visible* AO)
# out: a true value if the AO's state and/or location indicates it's invisible or offscreen. 
#   specifically: 'INVISIBLE' (state bit), 'OFFSCREEN' (state bit), 
#                 'nolocation', 'negative' (right/bottom has negative coordinate), 
#                 'zero' (zero-size).
#             But, state bit FOCUSABLE trumps the lack of a location.
sub either_INVISIBLE_or_negative
{
	my $self = shift;
    my $state = $self->istate();
	return 'INVISIBLE' 
      if ($state & STATE_SYSTEM_INVISIBLE());
	return 'OFFSCREEN' 
      if ($state & STATE_SYSTEM_OFFSCREEN());
	my ($left, $top, $width, $height) = $self->accLocation();
    # Explorer XP's app menubar has no location, but focusable state.
    return undef
      if (!defined($height) && ($state & STATE_SYSTEM_FOCUSABLE()));
	return 'nolocation' unless defined($height);
	return 'negative' if (($left + $width < 0) || ($top + $height < 0));
	return 'zero' if (($width ==0) || ($height == 0));
	return undef;
}

# testable('visible')
sub visible
  {
    my $self = shift;
    return !($self->either_INVISIBLE_or_negative());
  }

# testable('tree')
sub tree
{
    my $self = shift;
    my $coderef = shift;
    croak "Not a code ref" unless ref($coderef) eq 'CODE';
    my $pflags = shift;

    my $v = new Win32::ActAcc::TreeTour($coderef, $pflags);

    $v->run($self);
}

sub iterator
{
    my $self = shift;
    my $pflags = shift; 
    if (defined($pflags) && $$pflags{'perfunctory'})
    {
        return new Win32::ActAcc::AOIterator($self, $pflags);
    }
    elsif (defined($pflags) && $$pflags{'nav'})
    {
        return new Win32::ActAcc::NavIterator($self, $pflags);
    }
    else
    {
        return new Win32::ActAcc::AONavIterator($self, $pflags);
    }
}

sub waitForEvent
{
    my $self = shift;
    my $pQuarry = shift;
    croak "Must use HASH" if 'HASH' ne ref($pQuarry);
    my $timeoutSecs = shift; # optional
    $$pQuarry{'aoToEqual'} = $self;
    return Win32::ActAcc::IEH()->waitForEvent($pQuarry, $timeoutSecs);
}

sub memoize_member
  {
    my $self = shift;
    my $digpath = shift;
    my $mnemonic = shift;
    if ($MEMOIZE_MEMBERS) 
      {
        my $bag = $self->baggage();
        if (!exists($$bag{$mnemonic}))
          {
            $$bag{$mnemonic} = $self->dig($digpath, +{'min'=>1});
          }
        return $$bag{$mnemonic};
      }
    else
      {
        return $self->dig($digpath, +{'min'=>1});
      }
  }

sub drill
{
    my $self = shift;
    my $crit = shift;
    my $pflags = shift;

    $pflags = +{} if (!defined($pflags));
    croak "Criteria must not be a list" if (ref($crit) eq 'ARRAY'); # confused with dig
    croak "Flags must be a hash" unless ref($pflags) eq 'HASH';
    if (!exists($$pflags{'min'})) { $$pflags{'min'}=1; }
    if (!exists($$pflags{'max'})) { $$pflags{'max'}=-1; }
    if (!exists($$pflags{'pruneOnMatch'})) { $$pflags{'pruneOnMatch'}=1; }
    if (!exists($$pflags{'prunes'})) 
    { 
        $$pflags{'prunes'}=+[
            +{'role'=>ROLE_SYSTEM_MENUBAR()},
            +{'role'=>ROLE_SYSTEM_BUTTONMENU()},
            +{'role'=>ROLE_SYSTEM_OUTLINE()}
        ]; 
    }
    if ('HASH' ne ref($crit)) { $crit = matchHashUpCriteria($crit); };
    # if visible window is wanted, it can't be within an invisible window...
    if (exists($$crit{'state'}))
    {
        my $mask = ${$$crit{'state'}}{'mask'};
        my $val = ${$$crit{'state'}}{'value'};
        if ($mask & STATE_SYSTEM_INVISIBLE())
        {
            if (0 == ($val & STATE_SYSTEM_INVISIBLE()))
            {
                push(@{$$pflags{'prunes'}}, +{'state'=>+{'mask'=>STATE_SYSTEM_INVISIBLE(), 'value'=>STATE_SYSTEM_INVISIBLE()}});
            }
        }
    }

    my @found;

    $self->tree(
        sub 
        {
            my $ao = shift;
            my $treeTour = shift;

            my $level = $treeTour->level();
            if ($level > 0)
            {
                print "Matching " . $ao->describe() . "..." . ($ao->match($crit)) . "\n" if ($$pflags{'trace'});
                if ($ao->match($crit))
                {
                    $treeTour->prune() unless !$$pflags{'pruneOnMatch'};
                    push(@found,$ao);
                    if ($$pflags{'max'}==@found)
                    {
                        $treeTour->stop();
                    }
                }
                if (exists($$pflags{'prunes'}))
                {
                    if (grep($ao->match($_),@{$$pflags{'prunes'}}))
                    {
                        $treeTour->prune();
                    }
                }
            }
        }
        , $$pflags{'iterflags'} || +{});
    
    croak "Fewer than ".$$pflags{'min'}." found" if (0+@found < $$pflags{'min'});

    if ($$pflags{'max'}==1)
    {
        return $found[0];
    }
    else
    {
        return @found;
    }
}

# Return the subset of an AO's state-bits (including bits inheritable
# from its parent) that affect its children also.

sub inheritable_state
 {
   my $self = shift;
   my $state = $self->istate() || 0; 
   $state &= (
              STATE_SYSTEM_READONLY() |
              STATE_SYSTEM_OFFSCREEN() |
              STATE_SYSTEM_INVISIBLE() |
              STATE_SYSTEM_UNAVAILABLE());
   return $state;
 }

# Return an AO's state, including inheritable state-bits from its
# parent.  Uses $$bag{'::source'} (set by iterators) instead of
# parent, b/c parent is buggy in some cases.

# testable('iparent')
sub iparent
  {
    my $self = shift;
    my $bag = $self->baggage(0);
    my $src = $bag ? $$bag{'::source'} : undef;
    return $src;
  }

# testable('parent')
sub parent
  {
    my $self = shift;
    return $self->iparent() || $self->get_accParent();
  }

# testable('istate')
sub istate
  {
    my $self = shift;
    my $src = $self->iparent();
    my $inh = $src ? $src->inheritable_state() : 0;
    my $sta = $self->get_accState() || 0;
    return $sta | $inh;
  }

# testable('dda_Switch')
# testable('dda_Press')
BEGIN
{
	# Create convenient sub for each default action.
	my $da;
	foreach $da ('Check','Click','Close','Collapse','Double Click','Execute','Expand','Press','Switch','Uncheck')
	{
		my $m = $da; $m =~ s/\s//g;
      no strict 'refs';
		*{"dda_$m"}=sub{my $ao = shift; $ao->doActionIfDefault($da)};
	}
}

sub baggage
  {
    my $self = shift;
    my $alloc = shift; # whether to allocate if not already; default is 1
    if (!defined($alloc)) { $alloc = 1; }
    my $b = $self->baggage_get();
    if ($alloc && (ref($b) ne 'HASH'))
      {
        $self->baggage_put(+{});
        $b = $self->baggage_get();
        die unless (ref($b) eq 'HASH');
      }
    return $b;
  }


sub focus
  {
    my $self = shift;
    my $parent = $self->get_accParent();
    if (defined($parent))
      {
        $parent->focus();
      }
    if (STATE_SYSTEM_FOCUSABLE() & $self->get_accState())
      {
        $self->accSelect(SELFLAG_TAKEFOCUS());
      }
  }

use Win32::ActAcc::Test;

1;
