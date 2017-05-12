# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) demo: Traverse window hierarchy

use strict;
use Win32::OLE;
use Win32::ActAcc;
use Win32::ActAcc::aaExplorer;
use Data::Dumper;

# main
sub main
{
	Win32::OLE->Initialize();
	my $ao = Win32::ActAcc::Desktop();
	print "\naaDigger - Navigates tree of Accessible Objects\n\n";
	Win32::ActAcc::aaExplorer::aaExplore($ao);

    # Debrief
    print "AONavFruitsFromNavOnly: $Win32::ActAcc::AONavIterator::AONavFruitsFromNavOnly\n";
}

sub digTo
{
	my $target = shift;
	
	# Is target visible? Then consider only visible objects.
	my $state_test_bits = 0;
	my $state_test_value = 0;
	if (!($target->get_accState() & Win32::ActAcc::STATE_SYSTEM_INVISIBLE()))
	{
		$state_test_bits = Win32::ActAcc::STATE_SYSTEM_INVISIBLE();
	}
	
	my $crit = 
		+{
			'rolename'=>Win32::ActAcc::GetRoleText($target->get_accRole()),
			'name'=>$target->get_accName(),
			'state'=>+{'mask'=>$state_test_bits, 'value'=>$state_test_value},
		};
	
	return $crit;
}

sub digFrom
{
	my $child = shift;
	my $ancestor = shift;
print STDERR ("digFrom(\nchild=" . $child->describe() . "\nancestor=" . $ancestor->describe() . "\n");
	my $crit = +[];
	my $ao = $child;
	while ($ao->describe() ne $ancestor->describe())
	{
		my $p = $ao->get_accParent();
		die unless defined($p);
		unshift(@$crit, digTo($ao));
		$ao = $p;
	}
	return $crit;
}

sub digBack
{
	my $child = shift; 
	my $levels = shift;
	my $start = $child;
	for (my $i = 0; $i < $levels; $i++)
	{
		$start = $start->get_accParent();
		die unless defined($start);
	}
	my $crit = digFrom($child, $start);
	print Dumper($crit). "\n";
	#$start = $start->get_accParent();
	my @q = $start->dig($crit, +{ 'min'=>0, 'trace'=>0 });
	warn("Found " . scalar(@q)) unless 1==@q;
}

&main;

__END__

=pod

=head1 SYNOPSIS

Explore the Active Accessibility desktop and hierarchy of accessible objects.

aadigger starts off at the Desktop. It lists the "children" of the
Desktop object.

Pick a "child" by number (and press Enter) to "drill down" and get a
list of its children.

=head1 DESCRIPTION

You can start exploring an Accessible Object in three ways:

1. Starting at the Desktop, pick children by number until you get there.

2. Use the C<motiondetector> command.

3. Use the C<followmouse> command.

You can manipulate your view of the child objects:

1. Use C<invisible> to include invisible objects in the list.

2. Use C<tree> to see not just the immediate children, but the whole hierarchy.

3. Use C<outline> to see the tree, excluding menu- and outline-items.

You can get help composing scripts that use Active Accessibility.

1. Note down the role, title and hierarchical relationship of the relevant AOs and compose your own calls to C<dig> (etc.) manually.

2. Use the C<digback> command and aadigger will draft a C<dig> path
for you.  You must tell it how many levels of dig-path to generate,
and which AO to wind up at.  The C<digback> command only works with
AOs that have an accurate C<get_accParent>.

=cut
