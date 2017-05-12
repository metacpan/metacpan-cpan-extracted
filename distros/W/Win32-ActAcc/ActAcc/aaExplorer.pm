# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) demo: Traverse window hierarchy

# Usage:  use Win32::ActAcc::aaExplorer; my $e = new Win32::ActAcc::aaExplorer; $e->run($ao);
# Usage:  use Win32::ActAcc::aaExplorer; Win32::ActAcc::aaExplorer::aaExplore($ao);

use strict;

package Win32::ActAcc::aaExplorer;

use vars qw(@ISA);

use Win32::ActAcc qw(:all);
use Win32::ActAcc::MouseTracker;  
use Data::Dumper;
use IO::Tee;
use FileHandle;
use Text::Wrap;
use charnames ':full';  
our $cmds;
our $LIMIT_MENUITEMS;

BEGIN
{
	$LIMIT_MENUITEMS = 1000;
}

sub new
{
    my $class = shift;
    my $self = +{};
    bless $self, $class;
    
    $$self{'menu'} = +[];
    $$self{'ao'} = undef;
    $$self{'showmenu'} = 1;
    $$self{'menuname'} = "";
    $$self{'logname'} = "";
    $$self{'logfh'} = undef;
    $$self{'visibleonly'} = 1;
    
    # Note: commented-out "elide", "unelide", "weed" because 
    # they serve no purpose until ActAcc produces shortcut packages.

	if (!defined($cmds))
	{
		# NOTE: Commands that are prefixes of others, must occur first in the list.
		# A and X arguments must be last in their argument lists since they may be multi-word.
      $cmds = 
        +[
          +{'match'=>'-', 'sub'=>sub{&cmd_collapse},
            'args'=>'N[NNNNNNNNNN',
            'help'=>"menu - remove descendents of #<N>"},
          +{'match'=>'+', 'sub'=>sub{&cmd_expand},
            'args'=>'N[NNNNNNNNNN',
            'help'=>"menu - add descendents of #<N>"},
          #+{'match'=>'..', 'sub'=>sub{&cmd_parent},
          #				'help'=>"pick parent object"},
          +{'match'=>'?', 'sub'=>sub{&cmd_help}},
          +{'match'=>'abbreviations', 'sub'=>sub{&cmd_abbreviations},
            'help'=>"help - define abbreviations used in window-lists"},
          +{'match'=>'ancestors', 'sub'=>sub{&cmd_ancestors},
            'args'=>'A',
            'help'=>"list parent, grandparent, etc."},
          +{'match'=>'children', 'sub'=>sub{&cmd_children},
            'args'=>'A',
            'help'=>"list children"},
          +{'match'=>'details', 'sub'=>sub{&cmd_details},
            'args'=>'A',
            'help'=>"display properties"},
          +{'match'=>'digback', 'sub'=>sub{&cmd_digback},
            'args'=>'NA',
            'help'=>"compose a 'dig' path to the AO from N ancestor-levels back"},
          #				+{'match'=>'elide', 'sub'=>sub{&cmd_elide},
          #								'args'=>'N[NNNNNNNNNN',
          #								'help'=>"elide - treat its children as children of its parent instead"},
          +{'match'=>'eval', 'sub'=>sub{&cmd_eval},
            'args'=>'X',
            'help'=>"evaluate a Perl expression. Use \$ao for the current object, or \$menu[nn] to refer to an object on the menu by its number"},
          +{'match'=>'exit', 'sub'=>sub{&cmd_exit},
            'help'=>"exit"},
          +{'match'=>'followmouse', 'sub'=>sub{&cmd_followmouse},
            'help'=>"pick an object by moving the mouse"},
          +{'match'=>'help', 'sub'=>sub{&cmd_help},
            'help'=>"help - commands"},
          +{'match'=>'iam', 'sub'=>sub{&cmd_iam},
            'args'=>'A'},
          +{'match'=>'invisible', 'sub'=>sub{&cmd_invisible},
            'help'=>"exclude nothing"},
          +{'match'=>'log', 'sub'=>sub{&cmd_log},
            'args'=>'X',
            'help'=>"start recording the session (specify file name)"},
          +{'match'=>'menu', 'sub'=>sub{&cmd_menu},
            'help'=>"redisplay the list of choices"},
          +{'match'=>'motiondetector', 'sub'=>sub{&cmd_motiondetector},
            'help'=>"explore an object (designate by moving it)"},
          +{'match'=>'outline', 'sub'=>sub{&cmd_outline},
            'args'=>'A',
            'help'=>"list children, grandchildren, etc. -- but not menu/list/outline items."},
          +{'match'=>'pick', 'sub'=>sub{&cmd_pick},
            'args'=>'A',
            'help'=>"explore an object (designate by number)"},
          +{'match'=>'quit', 'sub'=>sub{&cmd_quit},
            'help'=>"exit"},
          +{'match'=>'selection', 'sub'=>sub{&cmd_selection},
            'args'=>'A',
            'help'=>"show selected children"},
          +{'match'=>'tree', 'sub'=>sub{&cmd_tree},
            'args'=>'A',
            'help'=>"list children, grandchildren, etc."},
          #				+{'match'=>'unelide', 'sub'=>sub{&cmd_unelide},
          #								'args'=>'N[NNNNNNNNNN',
          #								'help'=>"elide - unelide"},
          +{'match'=>'visible', 'sub'=>sub{&cmd_visible},
            'help'=>"exclude objects with STATE_SYSTEM_INVISIBLE, negative coordinates, or no location"},
          #				+{'match'=>'weed', 'sub'=>sub{&cmd_weed},
          #								'help'=>"elide many items automatically"},
         ];
	}
    return $self;
}

#static
sub aaExplore 
{
  my $startingAO = shift || Win32::ActAcc::Desktop();
	my $e = new Win32::ActAcc::aaExplorer;
	$e->goto($startingAO);
	$e->run(@_);
}

sub lookupcommand
{
	my ($self, $verb) = @_;
	my $chosen = undef;
	my $c;
	foreach $c (@$cmds)
	{
		my $m = $$c{'match'};
		my $s = $$c{'sub'};
		if (substr($m, 0, length($verb)) eq $verb)
		{
			if (length($verb) > length($$chosen{'match'} or '')) { $chosen = $c; }
		}
	}
	return $chosen;
}

# return (sub, arg, ...) replacing any $\d+ arg with an AO object from the menu.
sub parse
{
	my ($self, $t) = @_;
	
	# try interpreting as verb + args.
	my ($verb, $args) = split(/\s+/, $t, 2);
	my $ocmd = $self->lookupcommand($verb);
	
	if (defined($ocmd))
	{
		# check the args and default them if missing
		my @args2;
		my $argtype;
		my $optional = 0;
		foreach $argtype (split(//, ($$ocmd{'args'} or ''))) 
		{
			last if ($optional && ($args eq ''));
			if ($argtype eq '[')
			{
				$optional = 1;
				next;
			}
			elsif ($argtype eq 'A')
			{
				my @words = split(/\s+/, ($args or ''));
				my $given = shift(@words);
                if (!defined($given)) { $given = ''; }
				# interpret 1, 2, etc., as references to menu and change them to AOs.
				if ($given =~ /^\d+$/)
				{
					push(@args2, ${${$$self{'menu'}}[$given]}{'ao'});
				}
				# default to current AO
				elsif (!defined($given))
				{
					push(@args2, $$self{'ao'});
				}
				# maybe it's a dig path
				else
				{
					my $o = $self->path($$self{'ao'}, $args);
					if (defined($o))
					{
						push(@args2, $o);
					}
					else
					{
						print "$args doesn't work as a 'dig' path.\n";
						print "Try 'help'?\n";
						$ocmd = undef;
					}
				}
			}
			elsif ($argtype eq 'N')
			{
				my @words = split(/\s+/, $args);
				my $given = shift(@words);
				if ($given =~ /^\d+$/)
				{
					push(@args2, $given);
				}
				else
				{
					print "$given is not a number\n";
					$ocmd = undef;
				}
			}
			elsif ($argtype eq 'X')
			{
				push(@args2, $args);
			}
			else
			{
				die("argtype is $argtype");
			}
			
			# Peel and discard 1 word from the args list.
			my $toss;
			($toss, $args) = split(/\s+/, ($args or ''), 2);
		}
		if (defined($ocmd))
		{
			return ($$ocmd{'sub'}, @args2);
		}
		else
		{
			return undef;
		}
	}
	# if no command match, maybe the whole thing's a path.
	elsif ($t !~ /^pick /)
	{
		#print "$verb is not a command, so I will look for it using 'dig'.\n";
		my @r = $self->parse("pick $t");
		if (@r && $r[0])
		{
			print "Found it\n";
		}
		return @r;
	}
	# 
	else
	{
		print "Don't know $verb\n";
		return undef;
	}
}

sub path
{
	my ($self, $digstart, $path) = @_;
	my @path = split(qr(/), $path);
	my @digpath;
	# build argument to dig: dispose of leading ../.. and collapse interior ../..
	my $seg;
	while ($seg = shift(@path))
	{
		if ($seg =~ m/^\.\.$/)
		{
			push(@digpath, +{'axis'=>'parent'}); # DOTDOT
		}
		elsif ($seg =~ m/^qr\((.*)\)$/)
		{
			my $r = $1;
            my $rx = qr($r);
			push(@digpath, $rx);
		}
		else
		{
			push(@digpath, $seg);
		}
	}
	my $ao;
	if (@digpath)
	{
		my @ao = $digstart->dig(+[@digpath], +{'min'=>0, 'active'=>0, 'trace'=>1}) ;
		if (@ao == 1)
		{
			$ao = shift(@ao);
		}
		else
		{
			print "Found ".scalar(@ao)."\n";
			undef $ao;
		}
		#print $@;
	}
	else
	{
		$ao = $digstart;
	}
	return $ao;
}

sub dflt
{
	my ($self, $argtype) = @_;
	if ($argtype eq 'A') { return $$self{'ao'}; }
	return undef;
}

sub invoke
{
	my ($self, $t) = @_;
	my ($sub, @args) = $self->parse($t);
	if (defined($sub))
	{
		$self->$sub(@args) unless !defined($sub);
	}
}

sub run
{
	my ($self) = @_;
    my $prompt_msg = "For help, say 'help'.\n";
	while (defined($$self{'ao'}))
	{
		if ($$self{'showmenu'})
		{
			if (@{$$self{'menu'}} > 100)
			{
				print @{$$self{'menu'}} . " items on the menu. Type 'menu' if you really want to see them.\n";
			}
			else
			{
				$self->cmd_menu();
			}
		}
		print "\n";
		$self->cmd_iam($$self{'ao'});
		print "$prompt_msg> ";
        $prompt_msg = '';
		my $fullcmd = <STDIN>;
		if ($$self{'logfh'})
		{
			my $h = $$self{'logfh'};
			print $h $fullcmd;
		}
		chomp $fullcmd;
		$self->invoke($fullcmd);
	}
	$self->logclose();
}

sub goto
{
	my ($self, $ao) = @_;
	$$self{'ao'} = $ao;
	if (defined($ao))
	{
		$self->cmd_children($ao); 
	}
	$$self{'showmenu'} = 1;
}

sub add_menu_item
{
	my ($self, $ao, $level) = @_;
	push(@{$$self{'menu'}}, +{'ao'=>$ao, 'level'=>$level});
}

## Commands

sub cmd_iam
{
	my ($self, $ao) = @_;
	print $ao->describe(1) . "\n";
}

sub printAtt
{
	my $self = shift;
	my $phash = shift;
	my $key = shift;

	my $v = $$phash{$key};
	if (defined($v))
	{
		my @l = split("\n",$v);
		my $l0 = $l[0];
		if (defined($l0) && length($l0))
		{
			print "   ";
			print $key;
			print ' ' x (25-length($key));
			print $l[0];
			print "\n";

                        if ($#l > 0)
                        {
			    print "   ";
                            print " ...plus more. Try:   eval \$ao->${key}()\n"
                        }
		}
	}
}

sub cmd_details
{
	my ($self, $ao) = @_;
	my %i;
	$i{'get_accRole'} = Win32::ActAcc::GetRoleText($ao->get_accRole());
    my $stb = $ao->get_accState();
	$i{'get_accState'} = sprintf("%04x = ", $stb) . Win32::ActAcc::GetStateTextComposite($stb);
	$i{'get_accName'} = $ao->get_accName();
	$i{'get_accDescription'} = $ao->get_accDescription();
	$i{'get_accValue'} = $ao->get_accValue();
	$i{'get_accHelp'} = $ao->get_accHelp();
	$i{'get_accDefaultAction'} = $ao->get_accDefaultAction();
	$i{'get_accKeyboardShortcut'} = $ao->get_accKeyboardShortcut();

	print "=== $i{'get_accRole'}  $i{'get_accName'}\n";
	$self->printAtt(\%i, 'get_accDescription');
	$self->printAtt(\%i, 'get_accValue');
	$self->printAtt(\%i, 'get_accHelp');
	$self->printAtt(\%i, 'get_accDefaultAction');
	$self->printAtt(\%i, 'get_accKeyboardShortcut');
}

sub cmd_menu
{
	my ($self) = @_;
	print $$self{'menuname'} . "\n";
	print "(visible items only - 'visible' command in effect)\n" if ($$self{'visibleonly'});
	
	my $counter = 0;
	my $item;
	foreach $item (@{$$self{'menu'}})
	{
		print sprintf('%4d', $counter++) . ' ' . ('  ' x $$item{'level'}) . ($$item{'elide'}?'>|< ':'') . $$item{'ao'}->describe(1) . 
#			draftProfile($$item{'ao'})
			"\n";
	}
	$$self{'showmenu'} = undef;
}

sub cmd_pick
{
	my ($self, $ao) = @_;
	$self->goto($ao);
}

sub cmd_parent
{
	my ($self) = @_;
	$self->goto($$self{'ao'}->get_accParent());
}

sub cmd_motiondetector
{
	my ($self) = @_;
	print "Please point out the window by wiggling it.\n";
	my $eh = createEventMonitor(1);
	my $cae = $eh->eventLoop(
		+[+{
			'event'=>Win32::ActAcc::EVENT_OBJECT_LOCATIONCHANGE(),
			'ao_profile'=>+{'get_accRole'=>Win32::ActAcc::ROLE_SYSTEM_WINDOW()}
		}], undef, 1);
	my $ao = $$cae{'event'}->getAO();
    print "Got it: $ao\n";
	$self->goto($ao);
}

sub cmd_selection
  {
    my ($self, $ao) = @_;
    my @s = $ao->get_accSelection();
    print join("\n", map("$_\n", @s));
  }

sub cmd_tree
{
	my ($self, $ao) = @_;
	$$self{'menu'} = +[];
	$$self{'menuname'} = "tree from " . $ao->describe(1);
	$| = 1;
	my $ct = 0;
	$ao->tree( 
		sub
		{
			my ($ao, $tree) = @_;
			$ct++;
			print STDERR "\r$ct ";
			if ($ct != 1) # omit root from the tree - otherwise not parallel with cmd_children
			{
				# Prune AND exclude items disqualified because they are invisible.
				if ($$self{'visibleonly'} && !$ao->match(+{'visible'=>1}))
				{
					$tree->prune();
					return undef;
				}
				
				$self->add_menu_item($ao, $tree->level()-1); # sub 1 b/c root omitted
				if (scalar(@{$$self{'menu'}}) > $LIMIT_MENUITEMS)
				{
					print "Whoa! More than $LIMIT_MENUITEMS! I am giving up.\n";
					$tree->stop();
				}
			}
		}, 
		+{'active'=>0});
	print STDERR "\n";
    $$self{'showmenu'} = 1;
}

# Build outline of this AO's immediate children
# and their children,
# but not going deeper than a child movable window
# and not going deeper than a menu or combo-box,
# and excluding outline- and list-items altogether.
sub menulines_for_outline
{
	my ($self, $ao) = @_;
	my $rv = +[];
	
	$| = 1;
	my $ct = 0;
	
	# Do *not* prune on ROLE_SYSTEM_LIST since it is useful to bring back the column headings (which appear to be in a nested list).
	my $prune_profile1 = 
		+{
			'role_in'=>
				+[qw(
					ROLE_SYSTEM_MENUPOPUP ROLE_SYSTEM_MENUBAR ROLE_SYSTEM_MENUITEM 
					ROLE_SYSTEM_DROPLIST ROLE_SYSTEM_TITLEBAR ROLE_SYSTEM_COMBOBOX
					ROLE_SYSTEM_SCROLLBAR ROLE_SYSTEM_OUTLINE)],
		};
	my $prune_profile2 = 
		+{
			'get_accRole'=>ROLE_SYSTEM_WINDOW(),
			'state_has'=>STATE_SYSTEM_MOVEABLE()
		};
	
	my $squelch_profile =
		+{
			'test'=>new Win32::ActAcc::Test_or(+[
				$$self{'visibleonly'} ? new Win32::ActAcc::Test_visible(0) : (),
				new Win32::ActAcc::Test_role_in(+[qw(ROLE_SYSTEM_LISTITEM ROLE_SYSTEM_OUTLINEITEM)])
			])
		};
		
	$ao->tree( 
		sub
		{
			my ($ao, $tree) = @_;
			die unless defined($ao);
			die (ref $ao) unless (UNIVERSAL::isa($ao,'Win32::ActAcc::AO'));
			$ct++;
			print STDERR "\r$ct ";
			if ($ct != 1) # omit root from the tree - otherwise not parallel with cmd_children
			{
				# Prune AND exclude items
				if (($tree->level() > 1) && $ao->match($squelch_profile))
				{
					$tree->prune();
					return undef;
				}
				
				if (0 && $$self{'visibleonly'} && !$ao->match(+{'visible'=>1}))
				{
					$tree->prune();
					return undef;
				}
				
				# Prune (but don't exclude) at menus, lists, etc. - things that have insignificant descendants.
				my $ro = $ao->get_accRole();
				my $st = $ao->get_accState();
				if ($ao->match($prune_profile1) || $ao->match($prune_profile2))
				{
					$tree->prune();
				}
				
				push(@$rv, +{'ao'=>$ao, 'level'=>$tree->level()-1}); # sub 1 b/c root omitted
				
				if (scalar(@{$$self{'menu'}}) > $LIMIT_MENUITEMS)
				{
					print "Whoa! More than $LIMIT_MENUITEMS! I am giving up.\n";
					$tree->stop();
				}
			}
		}, 
		+{'active'=>0});
	print STDERR "\n";

	return $rv; 
}

sub cmd_outline
{
	my ($self, $ao) = @_;
	$$self{'menu'} = +[];
	$$self{'menuname'} = "outline from " . $ao->describe(1);
	$$self{'menu'} = $self->menulines_for_outline($ao); 
    $$self{'showmenu'} = 1;
}

sub cmd_quit
{
	my ($self) = @_;
	$self->goto(undef);
}

sub cmd_visible
{
	my ($self) = @_;
	$$self{'visibleonly'} = 1;
	$$self{'menu'} = +[grep(! ($$_{'ao'}->get_accState() & Win32::ActAcc::STATE_SYSTEM_INVISIBLE()), @{$$self{'menu'}})];
    $$self{'showmenu'} = 1;
}

sub cmd_invisible
{
	my ($self) = @_;
	$$self{'visibleonly'} = 0;
	print "OK\n";
}

sub cmd_eval
{
	my ($self, $x) = @_;
    my $ao = $$self{'ao'};
    my @menu = map($$_{'ao'} , @{$$self{'menu'}});
	print (eval $x) . "\n";
	print "$@\n";
}

sub cmd_followmouse
{
	my ($self) = @_;
	my $timeoutAfterMotionStarts = 2;
	print "I will wait $timeoutAfterMotionStarts seconds after the mouse settles.\n";
	
    my $eh = Win32::ActAcc::createEventMonitor(1);
    my $oldMloc;
    my $e;
    my $timeout = 5; # first time only; then $timeoutAfterMotionStarts
    $| = 1; # so the display of mouse location keeps up
    for (;;)
    {
		$eh->clear();
		last unless $eh->eventLoop(
			+[+{
				'event'=>Win32::ActAcc::EVENT_OBJECT_LOCATIONCHANGE(),
				'role'=>Win32::ActAcc::ROLE_SYSTEM_CURSOR(),
				'code'=>sub{
							$e = shift;
							my $aoCursor = $e->getAO();
							my ($left,$top,$width,$height) = $aoCursor->accLocation();
							print STDERR "\r($left,$top)      ";
							1; # so eventLoop terminates
						}
			}], $timeout);
		$timeout = $timeoutAfterMotionStarts;
	}
	print STDERR "\n"; 
	if (defined($e))
	{
		my $aoCursor = $e->getAO();
		my ($left,$top,$width,$height) = $aoCursor->accLocation();
		my $ao = Win32::ActAcc::AccessibleObjectFromPoint($left,$top);
		$self->goto($ao);
	}
}

sub cmd_ancestors
{
	my ($self, $ao) = @_;
	$$self{'menu'} = +[];
	$$self{'menuname'} = "ancestors of " . $ao->describe(1) . " according to get_accParent()";
	my $level = 0;
	for (my $o = $ao; defined($o); $o=$o->get_accParent())
	{
		$self->add_menu_item($o, $level++);
	}
    $$self{'showmenu'} = 1;
}

sub maxlen
{
	my $max = 0;
	foreach (@_) { $max = length($_) if ($max < length($_)); }
	return $max;
}

sub byHelpString { $$a{'help'} cmp $$b{'help'}} 

sub syntax
{
	my $entry = shift;
	my $pat = $$entry{'args'};
	my $etc = '';
    my @eargs;
    if (defined($pat))
      {
        if ($pat =~ /^([^\[]*)\[/)
          {
            $pat = $1;
            $etc = 1;
          }
        @eargs = split(//,$pat);
      }
    my %xlt = ('A'=>'<AO>', 'X'=>'<x>', 'N'=>'<n>');
    return $$entry{'match'} . 
      join('', map(' '.$xlt{$_}, @eargs)) . ($etc ? '...' : '');
}

sub cmd_help
{
	print "Commands:\n";
    print "('<AO>' indicates an Accessible Object: see below)\n";

	my $cmdWidth = maxlen(map(syntax($_), @$cmds));
	my @cmdsWithHelp = grep($$_{'help'}, @$cmds);
	my @cmdsWithHelpSorted = sort byHelpString @cmdsWithHelp;
    $Text::Wrap::columns = 76-$cmdWidth;
	#my @strings = map('  ' . syntax($_) . (' ' x ($cmdWidth - length(syntax($_)))) . " - $$_{'help'}\n", @cmdsWithHelpSorted);
	my @strings = map('  ' . syntax($_) . (' ' x ($cmdWidth - length(syntax($_)))) . " - " . Text::Wrap::wrap('',' 'x($cmdWidth+5), $$_{'help'})."\n", @cmdsWithHelpSorted);
	print join('', @strings);
	print "\nFor <AO>, you may use\n";
	print "  - nothing: I will assume the current Accessible Object;\n";
	print "  - a menu item number;\n";
	print "  - a /-separated path of 'dig' criteria strings or regexps (using qr() only)\n";
	print "    e.g.,   ..    -- go up to parent\n";
    print "       or   Desktop/qr(\\.*Mozilla)/{client}/{window}\n";

	print "\nEach window-list menu item shows the following fields:\n";
	print ("  " . Win32::ActAcc::AO::describe_meta() . "\n");
    print "  (For a key to the state codes, say 'abbreviations'.)\n";
}

sub cmd_abbreviations
{
    print "State text abbreviations:\n";
    my $abbrevs = Win32::ActAcc::GetStateTextAbbreviations();
	my $width = maxlen(values %$abbrevs);
	my @sorted = sort keys %$abbrevs;
    print join('', map($$abbrevs{$_} . (' ' x ($width - length($$abbrevs{$_}))) . " - $_\n", @sorted));
}

sub ref_leaf
{
	my $perlthing = shift;
	my $r = ref $perlthing;
	$r =~ /([^:]+)$/;
	return $1;
}

sub cmd_children
{
	my ($self, $ao) = @_;
	my $iterator = $ao->iterator();
	$$self{'menuname'} = "children of " . $ao->describe(1) . " according to " . ref_leaf($iterator);
	$$self{'menu'} = $self->menulines_for_outline($ao); 
    $$self{'showmenu'} = 1;
}

sub draftProfile
{
	my $target = shift;
	
	my $prof = new Win32::ActAcc::Test_and
      ( 
       +[
         new Win32::ActAcc::Test_get_accName($target->get_accName()),
         new Win32::ActAcc::Test_role_in
         (
          +[
            $target->get_accRole()
           ]
         ),
         ($target->visible() 
          ? new Win32::ActAcc::Test_visible() 
          : ()
         ),
        ]
      );
	
	return $prof;
}

# it is a crippling problem that children-of-a-parent have a parent-pointer that designates a grandparent or great-grandparent or even undef!
sub digFrom
{
	my $child = shift;
	my $ancestor = shift;
    #print STDERR ("digFrom(\nchild=" . $child->describe(1) . "\nancestor=" . $ancestor->describe(1) . ")\n");
	my $crit = +[];
	my $ao = $child;
	while ($ao->describe(1) ne $ancestor->describe(1))
	{
		my $p = $ao->get_accParent();
		die("No parent: ".$ao->describe()) unless defined($p);
		unshift(@$crit, draftProfile($ao));
		$ao = $p;
	}
	return $crit;
}

sub cmd_digback
{
	my ($self, $levels, $child) = @_;
	my $start = $child;
    if (!$levels)
      {
        print STDERR "Number of steps of dig-path to produce was not specified\n";
        return;
      }
    if (!$child)
      {
        print STDERR "AO, to which to dig, was not specified\n";
        return;
      }
	for (my $i = 0; $i < $levels; $i++)
	{
		my $ps = $start->get_accParent();
		if (!$ps) 
          {
            print STDERR "Unfortunately, can't get parent of ".$start->describe()."\n";
            return;
          }
        $start = $ps;
	}
	my $crit = digFrom($child, $start);
	print Dumper($crit). "\n";
	my @q = $start->dig($crit, +{ 'min'=>0, 'trace'=>0 });
	warn("\nNote: The above path finds " . scalar(@q) ." AOs.\n") unless 1==@q;
}

sub numerically { $a <=> $b };

sub cmd_collapse
{
	my ($self, @i) = @_; 
	@i = reverse sort numerically @i; # ensure descending order
	my $menu = $$self{'menu'};
	my $i;
	foreach $i (@i)
	{
		my $ilev = ${@{$menu}[$i]}{'level'};
		# Remove immediately following items with greater 'level'.
		my $r = 0;
		while ((scalar(@$menu)>($i+$r+1)) && (${$$menu[$i+$r+1]}{'level'} > $ilev))
		{
			$r++;
		}
		splice(@{$menu}, $i+1, $r);
	}
	$$self{'showmenu'} = 1;
}

sub cmd_expand
{
	my ($self, @i) = @_;
	@i = reverse sort numerically @i; # ensure descending order
	my $menu = $$self{'menu'};
	my $i;
	foreach $i (@i)
	{
		my $ilev = ${@{$menu}[$i]}{'level'};
		# Sanity check
		if ((scalar(@$menu)>($i+1)) && (${$$menu[$i+1]}{'level'} > $ilev))
		{
			print "#$i is already expanded\n";
		}
		else
		{
			my $ao = ${@{$menu}[$i]}{'ao'};
			my $nch = $self->menulines_for_outline($ao);
			$nch = +[map(do {$$_{'level'}+=$ilev+1; $_}, @$nch)];
			splice(@{$menu}, $i+1, 0, @$nch);
		}
	}
	$$self{'showmenu'} = 1;
}

sub cmd_elide
{
	my ($self, @i) = @_;
	my $menu = $$self{'menu'};
	my $i;
	foreach $i (@i)
	{
		${$$menu[$i]}{'elide'} = 1;
	}
	$$self{'showmenu'} = 1;
}

sub cmd_unelide
{
	my ($self, @i) = @_;
	my $menu = $$self{'menu'};
	my $i;
	foreach $i (@i)
	{
		delete ${$$menu[$i]}{'elide'};
	}
	$$self{'showmenu'} = 1;
}

sub logclose
{
	my ($self) = @_;
	if ($$self{'logfh'})
	{
		close($$self{'logfh'});
		select STDOUT;
		$$self{'logfh'} = undef;
	}
}

sub cmd_log
{
	my ($self, $fname) = @_;
	if ($$self{'logfname'})
	{
		$self->logclose();
	}
    # ActivePerl 5.8.4 :encoding(UTF-16LE), which would be more natural than UTF-8 in Windows, is unfortunately broken. The \n is written as 00 0d 0a (3 bytes not four!), throwing the whole rest of the file out of kilter.
	if (open($$self{'logfh'}, ">:utf8", $fname))
	{
		$$self{'logfname'} = $fname;
		select($$self{'logfh'});
        print "\N{BYTE ORDER MARK}"; # so reader may distinguish UTF-8, UTF-16LE, and UTF-16BE
		$| = 1;
		my $teeout = IO::Tee->new(*STDOUT{IO}, $$self{'logfh'});
		select($teeout);
		$| = 1;
	}
}

sub menu2tree
{
	my ($self) = @_;
	my $rv = +[];
	my @lev = ($rv);
	my $n = 0;
	foreach (@{$$self{'menu'}}) 
	{
		my $mentry = $_;
		if ($$mentry{'level'} > $#lev)
		{
			my $outerlist = $lev[$#lev];
			my $lastouteritem = ${$lev[$#lev]}[scalar(@{$lev[$#lev]})-1];
			$lev[$$mentry{'level'}] = $$lastouteritem{'rel'} = +[];
		}
		$#lev = $$mentry{'level'};
		#my $treeentry = +{%$mentry};
		#$$treeentry{'n'} = $n;
		$$mentry{'menuitemno'} = $n;
		push(@{$lev[$#lev]}, $mentry);
		$n++;
	}
	return $rv;
}

sub weed_count_visible
{
	my $menuitem = shift;
	my $ct = 0;
	if (!$$menuitem{'elide'})
	{
		$ct = 1;
	}
	else
	{
		foreach (@{$$menuitem{'rel'}})
		{
			$ct += weed_count_visible($_);
		}
	}
	return $ct;
}

sub weed_window_with_nmt_1_child
{
	my $a = shift; # LIST
	my $t;
	foreach $t (@$a)
	{
		# Elide {client} always.
		if ($$t{'ao'}->get_accRole() == Win32::ActAcc::ROLE_SYSTEM_CLIENT())
		{
			$$t{'elide'} = 1;
			print "Eliding client ".$$t{'ao'}->describe()."\n";
		}
		# Elide read-only text.
		if (($$t{'ao'}->get_accRole() == Win32::ActAcc::ROLE_SYSTEM_STATICTEXT())
			&& ($$t{'ao'}->get_accState() == Win32::ActAcc::STATE_SYSTEM_READONLY() ))
		{
			$$t{'elide'} = 1;
			print "Eliding read-only text ".$$t{'ao'}->describe()."\n";
		}
		# Process children. Count non-elided children.
		weed_window_with_nmt_1_child($$t{'rel'});
		# Elide {window} if it has exactly 1 non-elided child.
		if (($$t{'ao'}->get_accRole() == ROLE_SYSTEM_WINDOW()))
		{
			$$t{'elide'} = 1; # trial balloon
			if (2 > weed_count_visible($t))
			{
				$$t{'elide'} = 1;
				print "Eliding useless ".$$t{'ao'}->describe()."\n";
			}
			else
			{
				$$t{'elide'} = 0;
			}
		}
		else 
		{ 
			#print $$t{'ao'}->describe()." has $totalAOs children\n";
		}
	}
}

sub cmd_weed
{
	my ($self) = @_;
	
	my $t = $self->menu2tree();
	weed_window_with_nmt_1_child($t);
    $$self{'showmenu'} = 1;
}

sub nameForAO
{
	my ($ao, $hashOfTakenNames) = @_;
	my $gname = Win32::ActAcc::GetRoleText($ao->get_accRole()) . "_" . $ao->get_accName();
	$gname = substr($gname, 0, 40); # arbitrary/reasonable length limit
	$gname =~ s/[^a-zA-Z0-9_]/_/g; # no chars illegal in Perl function names
	if ($gname =~ /^[0-9]/) { $gname = "_$gname"; } # no leading digit
	my $n = 1;
	my $disamb = $gname;
	while (exists($$hashOfTakenNames{$disamb}))
	{
		$disamb = $gname . ++$n;
	}
	return $disamb;	
}




1;
