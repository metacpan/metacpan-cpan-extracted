#
# buildfile.pl <xml file>
#
# build pure XMLBuilder xml files
#
use strict;
use Win32::GUI::XMLBuilder;
use Cwd;
use File::Basename;

my $__FILE__;

our $gui;

if (! -f $ARGV[0]) {
	Win32::GUI::XMLBuilder->new(*DATA);
} else {
	$__FILE__ = basename($ARGV[0]);
	my $__DIR__  = getcwd."/".dirname($ARGV[0]);
	chdir($__DIR__) || die "chdir $__DIR__,$!\n";
	$gui = Win32::GUI::XMLBuilder->new({file=>$__FILE__});
}

Win32::GUI::Dialog;

sub loadGUI {
	$__FILE__ = Win32::GUI::GetOpenFileName(
		-title     => 'Choose XML file...',
		-directory => '.',
		-filter    => [ 
			"XMLBuilder Files (*,xml, *.wgx)" => "*.xml;*.wgx",
			"XML (*.xml)" => "*.xml",
			"WGX (*.wgx)" => "*.wgx",
			"All files" => "*.*",
		],
	);

	&reloadGUI;
}

sub reloadGUI {
	if (-f $__FILE__) {
		foreach (%{$gui}) {
			$gui->{$_}->DESTROY if ref $gui->{$_} eq 'Win32::GUI::Window';
		}
		undef $gui;
		$gui = Win32::GUI::XMLBuilder->new({file=>$__FILE__});
	}
}

__END__
<GUI>
	<Class name='__CLASS__' icon='exec:$Win32::GUI::XMLBuilder::ICON' />
	<Window name='MAIN'
		dim='0, 0, 210, 115'
		title='Build XMLBuilder File'
		class='$self->{__CLASS__}'
		onTerminate='sub { $_[0]->PostQuitMessage(0); return -1; }'
		show='1'
	>
	<WGXExec>$self->{MAIN}->Center;</WGXExec>
		<Label
			dim='20, 10, 220, 30'
			text='CLI Usage: buildfile.pl &lt;xml file&gt;, or'
			/>
		<Button
			dim='20, 30, 100, 20'
			text='Open XML file...'
			onClick='loadGUI'
		/>
		<Checkbox
			dim='135, 30, 100, 20'
			text='Debug'
			onClick='sub { $ENV{WIN32GUIXMLBUILDER_DEBUG} = $_[0]->Checked; }'
		/>
		<Button
			dim='20, 50, 100, 20'
			text='Reload'
			onClick='reloadGUI'
		/>
	</Window>
</GUI>

