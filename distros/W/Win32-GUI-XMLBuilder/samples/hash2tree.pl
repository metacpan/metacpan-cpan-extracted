#
# demonstrates how to create a treeview from a hash
#
use strict;
use Data::Dumper;

our %R; # this variable must be global to Win32::GUI::XMLBuilder!
use Win32::TieRegistry(Delimiter=>"|", ArrayValues=>0, TiedHash=>\%R);

use Win32::GUI::XMLBuilder;
Win32::GUI::XMLBuilder->new(*DATA);
Win32::GUI::Dialog;

sub hashwalk {
	my ($T, $node, $HR, $n) = @_;
	$n == 0 ? return : $n--;
	foreach my $k (keys %$HR) {
		my $newnode = $T->InsertItem(-parent => $node, -text=>$k);
		&hashwalk($T, $newnode, $$HR{$k}, $n) if ref($$HR{$k}) ne  '';
		Win32::GUI::DoEvents();
	}
}

__END__
<GUI>
	<Class name='C' icon='exec:$Win32::GUI::XMLBuilder::ICON'/>
	<Window name='W'
		dim='0, 0, 300, 250'
		title='Hash to Treeview Example'
		class='$self->{C}'
	>
		<StatusBar name='S'
			top='$self->{W}->ScaleHeight - $self->{S}->Height if defined $self->{S}'
			height='$self->{S}->Height if defined $self->{S}'
			text='exec:$Win32::GUI::XMLBuilder::AUTHOR'
		/>
		<TreeView name='T'
			height='$self->{W}->ScaleHeight - $self->{S}->Height'
			lines='1' rootlines='1' buttons='1' visible='1'
		/>
	</Window>
	<WGXPost>
		hashwalk($self->{T}, 0, \%R, 2)
	</WGXPost>
</GUI>

