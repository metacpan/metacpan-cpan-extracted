use strict;
use Win32::GUI::XMLBuilder;
my $gui = Win32::GUI::XMLBuilder->new(*DATA);
Win32::GUI::Dialog;

__END__
<GUI>
	<Class name='C' icon='exec:$Win32::GUI::XMLBuilder::ICON'/>
	<Window name='W'
		dim='0, 0, 400, 200'
		title='Wizard Example'
		class='$self->{C}'
		onTerminate='sub { $_[0]->PostQuitMessage(0); return -1; }'
	>
		<WGXExec>$self->{W}->Center</WGXExec>
		<StatusBar name='S' 
			top='exec:$self->{W}->ScaleHeight - $self->{S}->Height if defined $self->{S}'
			height='exec:$self->{S}->Height if defined $self->{S}'
			text='exec:$Win32::GUI::XMLBuilder::AUTHOR'
		/>
		<TabStrip name='Form'
			dim='0, 0, $self->{W}->ScaleWidth, $self->{W}->ScaleHeight - $self->{S}->Height'
			onChanging='sub { return 0; }'
		>
			<Item name='P0' text='Zero'>
				<Label 
					dim='50, 50, $self->{P0}->Width-50, $self->{P0}->Height-50'
					text='Please press "Next" to continue...'
				/>
				<Button
					dim='$self->{P0}->Width-100, $self->{P0}->Height-40, 60, 20'
					text='Next >'
					onClick='sub { $self->{P0}->Hide; $self->{P1}->Show; $self->{Form}->Select(1); }'
				/>
			</Item>
			<Item name='P1' text='One'>
				<Label 
					dim='50, 50, $self->{P0}->Width-50, $self->{P0}->Height-50'
					text='Page 2 - Please press "Next" to continue...' 
				/>
				<Button
					dim='$self->{P1}->Width-170, $self->{P1}->Height-40, 60, 20'
					text='&lt; Back'
					onClick='sub { $self->{P1}->Hide; $self->{P0}->Show; $self->{Form}->Select(0); }'
				/>
				<Button
					dim='$self->{P1}->Width - 100, $self->{P1}->Height-40, 60, 20'
					text='Next >'
					onClick='sub { $self->{P1}->Hide; $self->{P2}->Show; $self->{Form}->Select(2); }'
				/>
			</Item>
			<Item name='P2' text='Two'>
				<Label 
					dim='50, 50, $self->{P0}->Width-50, $self->{P0}->Height-50'
					text='Page 3 - Please press "Next" to continue...' 
				/>
				<Button
					dim='$self->{P2}->Width-170, $self->{P2}->Height-40, 60, 20'
					text='&lt; Back'
					onClick='sub { $self->{P2}->Hide; $self->{P1}->Show; $self->{Form}->Select(1); }'
				/>
				<Button
					dim='$self->{P2}->Width - 100, $self->{P2}->Height-40, 60, 20'
					text='Next >'
					onClick='sub { $self->{P2}->Hide; $self->{P3}->Show; $self->{Form}->Select(3); }'
				/>
			</Item>
			<Item name='P3' text='Three'>
				<Label 
					dim='50, 50, $self->{P0}->Width-50, $self->{P0}->Height-50'
					text='Please press "Finish" to complete.' 
				/>
				<Button
					dim='$self->{P3}->Width-170, $self->{P3}->Height-40, 60, 20'
					text='&lt; Back'
					onClick='sub { $self->{P3}->Hide; $self->{P2}->Show; $self->{Form}->Select(2); }'
				/>
				<Button 
					dim='$self->{P3}->Width - 100, $self->{P3}->Height-40, 60, 20'
					text='Finish'
					onClick='sub { $self->{W}->PostQuitMessage(0); return -1; }'
				/>
			</Item>
		</TabStrip>
	</Window>
</GUI>

