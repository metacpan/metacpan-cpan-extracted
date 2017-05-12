# Copyright 2001-2004, Phill Wolf.  See README.   -*- perl -*- 

# Win32::ActAcc (Active Accessibility) test suite

use strict;
use Data::Dumper;
use Win32::ActAcc(qw(:all));
use Win32::ActAcc::AOFake;
use Win32::OLE;
use Config;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

my @t;
push(@t, sub{&t_aofake;});
push(@t, sub{&t_testAlgebra;});
push(@t, sub{&t_RoleFriendlyNameToNumber;});
push(@t, sub{&t_Desktop;});
push(@t, sub{&t_AccessibleObjectFromWindow_and_reverse;});
push(@t, sub{&t_AccessibleChildren_all;});
push(@t, sub{&t_AccessibleChildren_dflt;});
push(@t, sub{&t_consts;});
push(@t, sub{&t_get_accName;});
push(@t, sub{&t_get_accRole;});
push(@t, sub{&t_StateConstantName;});
push(@t, sub{&t_EventConstantName;});
push(@t, sub{&t_ObjectIdConstantName;});
push(@t, sub{&t_GetStateTextComposite;});
push(@t, sub{&t_doActionIfDefault;});
push(@t, sub{&t_thrash;});
push(@t, sub{&t_baggage;});

print "1..".@t."\n";

Win32::OLE->Initialize();

for (my $i = 1; $i <= @t; $i++)
{
	my $passed;
	my $comment = "";
	eval { my $r = &{$t[$i-1]}(\$comment); $passed=1; print "$r $i $comment\n"; };
	if (!$passed)
	{
		print "not ok $i\n";
		print STDERR $@."\n";
	}
}


sub t_RoleFriendlyNameToNumber
{   
    for my $friendlyName 
        (
        ROLE_SYSTEM_MENUBAR(),  # test_of('RoleFriendlyNameToNumber.literal_number')
        'menu bar', # test_of('RoleFriendlyNameToNumber.role_text')
        'ROLE_SYSTEM_MENUBAR', # test_of('RoleFriendlyNameToNumber.constant_name_full')
        'MENUBAR', # test_of('RoleFriendlyNameToNumber.constant_name_suffix')
        'Win32::ActAcc::Menubar', # test_of('RoleFriendlyNameToNumber.package_name_full')
        'Menubar' # test_of('RoleFriendlyNameToNumber.package_name_suffix')
    )
    {
    die unless RoleFriendlyNameToNumber($friendlyName) == ROLE_SYSTEM_MENUBAR();
    }
    "ok";
}

sub t_Desktop
{
	my $ia2 = Win32::ActAcc::Desktop(); # test_of('Desktop')
	die unless defined($ia2);
	die unless 'Win32::ActAcc::Window' eq ref($ia2);
	my $ia2p = $ia2->get_accParent(); # test_of('get_accParent.desktop')
	die if(defined($ia2p));
	"ok";
}

sub t_AccessibleObjectFromWindow_and_reverse
{
	my $ia=Win32::ActAcc::Desktop();
	my $h2=$ia->WindowFromAccessibleObject(); # test_of('WindowFromAccessibleObject')
	my $ao = Win32::ActAcc::AccessibleObjectFromWindow($h2); # test_of('AccessibleObjectFromWindow')
	my $h3=$ao->WindowFromAccessibleObject(); 
	die unless ($h3 == $h2);
	"ok";
}

sub t_AccessibleChildren_all
{
	my $ia=Win32::ActAcc::Desktop();
	my @ch = $ia->AccessibleChildren(0,0); # test_of('AccessibleChildren.all')
	die unless 3 < @ch;
    my $nInvisible = grep($_->either_INVISIBLE_or_negative(), @ch);
    my $nVisible = @ch - $nInvisible;
    die unless 1==$nVisible;
	"ok";
}

sub t_AccessibleChildren_dflt
{
	my $ia=Win32::ActAcc::Desktop();
	my @ch = $ia->AccessibleChildren(); # test_of('AccessibleChildren.default')
	die unless 1==@ch;
	# the one visible child is probably: 'Desktop'=>'client',
	"ok";
}

sub t_consts
{
	# confirm the constants mechanism by comparing
	# a couple of values with their H-file values.
	die unless 0==Win32::ActAcc::CHILDID_SELF();
	die unless 1==Win32::ActAcc::ROLE_SYSTEM_TITLEBAR();
	my $v = 0; 
	eval { Win32::ActAcc::FOOBAR(); die; } ;
	"ok";
}

sub t_get_accName
{
	my $ia=Win32::ActAcc::Desktop();
	my $name = $ia->get_accName(); # test_of('get_accName')
	die unless ($name eq "Desktop");
	"ok";
}

sub t_get_accRole
{
	my $ia=Win32::ActAcc::Desktop();
	my $ro = $ia->get_accRole(); # test_of('get_accRole')
	die unless ($ro == Win32::ActAcc::ROLE_SYSTEM_WINDOW());
	"ok";
}

sub t_StateConstantName
{
	my $k = Win32::ActAcc::STATE_SYSTEM_INVISIBLE();
	my $n = Win32::ActAcc::StateConstantName($k);
	#print STDERR "k=$k, n=$n\n".join("\n",keys(%Win32::ActAcc::StateName))."\n";
	die unless 'STATE_SYSTEM_INVISIBLE' eq $n;
	"ok";
}

sub t_EventConstantName
{
	my $k = Win32::ActAcc::EVENT_OBJECT_SHOW();
	my $n = Win32::ActAcc::EventConstantName($k);
	#print STDERR "k=$k, n=$n\n".join("\n",keys(%Win32::ActAcc::EventName))."\n";
	die unless 'EVENT_OBJECT_SHOW' eq $n;
	"ok";
}

sub t_ObjectIdConstantName
{
	my $k = Win32::ActAcc::OBJID_MENU();
	my $n = Win32::ActAcc::ObjectIdConstantName($k);
	die "Wrong name is $n" unless 'OBJID_MENU' eq $n;
	"ok";
}

# test_of('GetStateText')
# test_of('GetStateTextComposite.full')
sub t_GetStateTextComposite
{
	my $k1 = Win32::ActAcc::STATE_SYSTEM_INVISIBLE();
	my $t1 = Win32::ActAcc::GetStateText($k1);
    die unless $t1 eq 'invisible';
	my $k2 = Win32::ActAcc::STATE_SYSTEM_SIZEABLE();
	my $t2 = Win32::ActAcc::GetStateText($k2);
	my $k3 = Win32::ActAcc::STATE_SYSTEM_FOCUSABLE();
	my $t3 = Win32::ActAcc::GetStateText($k3);
    die unless $t3 eq 'focusable';

	my $kc = $k1 | $k2 | $k3;
	my $tc = Win32::ActAcc::GetStateTextComposite($kc);

	$tc =~ /$t1/ or die "Didn't find $t1 in $tc";
	$tc = "$`$'";

	$tc =~ /$t2/ or die "Didn't find $t2 in $tc";
	$tc = "$`$'";

	$tc =~ /$t3/ or die "Didn't find $t3 in $tc";
	$tc = "$`$'";

	die if ($tc =~ /a-z/i);
	"ok";
}

sub t_doActionIfDefault
{
	eval { Desktop()->doActionIfDefault('foo'); }; # test_of('doActionIfDefault.not_default')
	die unless ($@ =~ /Cannot 'foo' when the available action is/);
	"ok";
}

sub t_thrash
  {
    my @a;
    my $d = Desktop();
    for (my $j = 0; $j < 5; $j++)
      {
        print STDERR "\nIteration $j\n";
        # Allocate a lot of objects
        for (my $i = 0; $i < 50; $i++)
          {
            $a[$i] = Desktop();
            $a[$i]->baggage()->{'pickle'} = "$i.$j";
            #$a[$i]->baggage()->{'ockle'} = 'a'x65500;
            
            #$a[$i]->baggage()->{'ickle'} = $a[$i]->accNavigate(NAVDIR_FIRSTCHILD()) or die;
            my @k = $a[$i]->dig(+['{client}']);
            #$a[$i]->baggage()->{'ickle'} = $a[$i]->dig(+['{client}']) or die;
            $a[$i]->baggage()->{'ickle'} = $d->dig(+['{client}']) or die;
          }

        # Free them
        for (my $i = 0; $i <= $#a; $i++)
          {
            undef $a[$i];
          }

        print STDERR "  Thank you.\n";
        sleep(1);
      }

    'ok';
  }

sub t_baggage
{
    my $ao = Desktop();
    my $b = $ao->baggage(); # test_of('baggage')
    die("ref of baggage is improperly ".ref($b)) 
    unless 'HASH' eq ref($b);
    $$b{'penguin'} = 'Opus';
    my $c = $ao->baggage();
    die unless $$c{'penguin'} eq 'Opus';

    $$b{'poppers'} = +{ 'bar'=>'baz' };
    die unless $$c{'poppers'}{'bar'} eq 'baz';

    $ao->baggage()->{'poppers'}{'crane'} = 
    $ao->baggage()->{'poppers'}{'crane2'} = Desktop();
    die unless $$c{'poppers'}{'crane'}->describe() eq $ao->describe();

    'ok';
}


use Data::Dumper;

sub t_aofake
{
	my $f = new Win32::ActAcc::AOFake();
	$f->init('Untitled - SomeApp', ROLE_SYSTEM_WINDOW(), STATE_SYSTEM_MOVEABLE()); 
	#die Dumper($f);
	die unless 'Untitled - SomeApp' eq $f->get_accName();
	die unless ROLE_SYSTEM_WINDOW()== $f->get_accRole();
	die unless UNIVERSAL::isa($f, 'Win32::ActAcc::AO');
	#die ("Symbol table:\n".Dumper(\%Win32::ActAcc::AOFake::) . "\n");
	#die  $f->describe() . "\n";
	"ok";
}

sub t_testAlgebra
{
	my $f = new Win32::ActAcc::AOFake();
	$f->init('Untitled - SomeApp', ROLE_SYSTEM_WINDOW(), STATE_SYSTEM_MOVEABLE()); 
	$$f{'accLocation'} = +[100,200,300,400];
	
	my $n = new Win32::ActAcc::Test_get_accName(qr(SomeApp$));
	die unless $n->test($f); # test_of('Test_get_accName::test.positive')
	die unless ($n->describe() eq 'qr(?-xism:SomeApp$)');
	
	my $r = new Win32::ActAcc::Test_role_in(+[ROLE_SYSTEM_WINDOW()]);
	die unless $r->test($f); # test_of('Test_role_in::test.positive')
	die ($r->describe()) unless ($r->describe() eq 'role(window)');
	
	my $s = new Win32::ActAcc::Test_state(0, STATE_SYSTEM_INVISIBLE());
	die unless $s->test($f); # test_of('Test_state::test.positive')
	die ($s->describe()) unless ($s->describe() eq 'not(invisible)');
	
	my $a = new Win32::ActAcc::Test_and(+[$n, $r, $s]);
	die unless $a->test($f); # test_of('Test_and::test.all_positive')
	die ($a->describe(1)) unless ($a->describe(1) eq '{role(window)}qr(?-xism:SomeApp$)[not(invisible)]');

	my $v = new Win32::ActAcc::Test_visible(1);
	die unless $v->test($f); # test_of('Test_visible::test.positive')
	die ($v->describe()) unless ($v->describe() eq 'visible');

	my $d = new Win32::ActAcc::Test_dig(+[$v]); # test_of('Test_dig::test.negative')
	die if ($d->test($f));
	die ($d->describe()) unless ($d->describe() eq '*[visible]');

	my $o = new Win32::ActAcc::Test_not($d);
	die unless $o->test($f); # test_of('Test_not::test.positive')
	die ($o->describe()) unless ($o->describe() eq 'not(*[visible])');

	my $a2 = new Win32::ActAcc::Test_and(+[$a, $o]);
	die unless $a2->test($f);
	die ($a2->describe(1)) unless ($a2->describe(1) eq '{role(window)}qr(?-xism:SomeApp$)[not(invisible) && not(*[visible])]');
	
	"ok";
}

