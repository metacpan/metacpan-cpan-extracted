# Copyright 2001-2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility) - An AO for testing 

package Win32::ActAcc::AOFake;

our(@ISA);
@ISA = qw(Win32::ActAcc::AO);

sub new
{
    my $class = shift;
	my $self = +{};
	bless $self, $class;
	$$self{'baggage'} = +{};
	$$self{'accChildren'} = +[];
    return $self;
}

sub init
{
	my $self = shift;
	my $name = shift;
	my $role = shift;
	my $states = shift;
	$$self{'get_accName'} = $name;
	$$self{'get_accRole'} = $role;
	$$self{'get_accState'} = $states;
}

BEGIN
{
	my $da;
	# Methods that return a like-named hash member
	my $mn;
	foreach $mn (qw(
			click Equals Release DESTROY WindowFromAccessibleObject
			get_accRole get_accState get_accName get_accValue get_accDescription
			get_accHelp get_accDefaultAction get_accKeyboardShortcut
			get_accParent get_accFocus accDoDefaultAction_ get_itemID
			accSelect accNavigate baggage get_nativeOM))
	{
		*{$mn}=sub{my $self = shift; return $$self{$mn}; };
	}
}

sub get_accChildCount
{
	my $self = shift;
	return scalar(@{$$self{'accChildren'}});
}

sub get_accChild
{
	my $self = shift;
	my $ix = shift;
	return ${$$self{'accChildren'}}[$ix];
}

sub AccessibleChildren
{
	my $self = shift;
	return @{$$self{'accChildren'}};
}

sub accLocation
{
	my $self = shift;
	return @{$$self{'accLocation'}};
}

1;
