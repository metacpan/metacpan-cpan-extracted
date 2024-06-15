package Tk::AppWindow::Ext::Help;

=head1 NAME

Tk::AppWindow::Ext::Help - about box and help facilities

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.08";

use base qw( Tk::AppWindow::BaseClasses::Extension );

use Tk;
use File::Basename;
require Tk::YADialog;
require Tk::NoteBook;
require Tk::ROText;
require Tk::Pod::Text;


=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Help'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Adds a help facility and an about box to your application. Initiates
menu entries for them.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-aboutinfo>

Specify the link to a hash. Possible keys:

=over 4

=item B<author>

Your name

=item B<components>

Specify a list of modules you want the version numbers displayed.
Opens a new tab.

=item B<email>

Who to contact

=item B<http>

The website that supports this application

=item B<license>

Specify your license. By default it is set to I<Same as Perl>.
Set it to I<undef> if you do not want it to show.

=item B<licensefile>

Specify a plain text file as your license file. It is displayed in a new
tab with a L<Tk::ROText> widget.

=item B<licenselink>

Works only if the I<license> key is defined. Specify the weblink to your license. By default it 
is set to L<https://dev.perl.org/licenses/>.
Set it to I<undef> if you do not want it to show.

=item B<version>

Specify the version of your application. By default it is set to the
version numer of the main window widget. Set it to undef if you do not
want it to show.

=back

=item Switch: B<-helpfile>

Point to your help file. Can be a weblink.
If it is a I<.pod> file it will launch a dialog box with
a I<PodText> widget.

=back

=head1 B<COMMANDS>

The following commands are defined.

=over 4

=item B<about>

Pops the about box.

=item B<help>

Loads the helpfile in your system's default application or browser.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->{ABOUTDEFAULTS} = {
		version => $self->GetAppWindow->VERSION,
		license => 'Same as Perl',
		licenselink => 'https://dev.perl.org/licenses/',
	};
	$self->addPreConfig(
		-aboutinfo => ['PASSIVE', undef, undef, {	}],
		-helpfile => ['PASSIVE'],
	);

	$self->cmdConfig(
		about => ['CmdAbout', $self],
		help => ['CmdHelp', $self],
	);
	return $self;
}

=head1 METHODS

=over 4

=cut

sub CmdAbout {
	my $self = shift;
	my $inf = $self->configGet('-aboutinfo');
	my $defaults = $self->{ABOUTDEFAULTS};
	for (keys %$defaults) {
		$inf->{$_} = $defaults->{$_} unless exists $inf->{$_}
	}

	my $db = $self->YADialog(
		-buttons => ['Ok'],
		-defaultbutton => 'Ok',
		-title => 'About ' . $self->appName,
	);

	my @padding = (-padx => 2);
	my $nb; #NoteBookWidget;
	my $ap; #About frame widget
	my $addnb = sub {
		unless (defined $nb) {
			$nb = $db->NoteBook->pack(-expand => 1, -fill => 'both') ;
			$ap = $nb->add('about', -label =>'About');
		}
	};
	my @col0 = ( -column => 0, -sticky => 'e', @padding);
	my @col1 = ( -column => 1, -sticky => 'w', @padding);

	if (my $file = $inf->{licensefile}) {
		&$addnb;
		my $lp = $nb->add('licence', -label => 'License');
		my $t = $lp->Scrolled('ROText', 
			-width => 8, 
			-height => 8, 
			-scrollbars => 'osoe'
		)->pack(-expand =>1, -fill => 'both', @padding);
		if (open(my $fh, '<', $file)) {
			while (my $line = <$fh>) {
				$t->insert('end', $line)
			}
			close $fh
		}
	} else {
		$ap = $db->Frame->pack(-expand => 1, -fill => 'both') unless defined $ap;
	}

	if (exists $inf->{components}) {
		&$addnb;
		my $lp = $nb->add('components', -label => 'Components');
		my $cf = $lp->Frame->pack(-fill => 'x', @padding);
		my $components = $inf->{components};
		my $row = 0;
		for (@$components) {
			my $module = $_;
			my $version = $self->moduleVersion($module);
			if (defined $version) {
				$cf->Label(-text => "$module :")->grid(-row => $row, @col0);
				$cf->Label(-text => $version)->grid(-row => $row, @col1);
				$row++
			}
		}
	} else {
		$ap = $db->Frame->pack(-expand => 1, -fill => 'both') unless defined $ap;
	}

	my $lg = $self->configGet('-logo');
	if (defined $lg) {
		$ap->Label(-image => $self->Photo(-file => $lg))->pack;
	}
	my $gf = $ap->Frame->pack(-expand => 1, -fill => 'both');
	my $row = 0;
	my $ver = $inf->{version};
	if (defined $ver) {
		$gf->Label(-text => 'Version:')->grid(-row => $row, @col0);
		my $l = $gf->Label(-text => $ver)->grid(-row => $row, @col1);
		$row ++;
	}
	my $aut = $inf->{author};
	if (defined $aut) {
		$gf->Label(-text => 'Author:')->grid(-row => $row, @col0);
		$gf->Label(-text => $aut)->grid(-row => $row, @col1);
		$row ++;
	}
	my $mail = $inf->{email};
	if (defined $mail) {
		$gf->Label(-text => 'E-mail:')->grid(-row => $row, @col0);
		my $url = $gf->Label(
			-text => $mail,
		)->grid(-row => $row, @col1);
		$self->ConnectURL($url, "mailto:$mail"); 
		$row ++;
	}
	my $web = $inf->{http};
	if (defined $web) {
		$gf->Label(-text => 'Website:')->grid(-row => $row, @col0);
		my $url = $gf->Label(
			-text => $web,
		)->grid(-row => $row, @col1);
		$self->ConnectURL($url, $web); 
		$row ++;
	}
	my $lc = $inf->{license}; 
	if (defined $lc) {
		if (defined $lc) {
			$gf->Label(-text => 'License:')->grid(-row => $row, @col0);
			my $l = $gf->Label(-text => $lc)->grid(-row => $row, @col1);
			my $lcu = $inf->{licenselink};
			if (defined $lcu) {
				$self->ConnectURL($l, $lcu) if defined $lcu;
			}
		}
		$row ++;
	}
	$db->Show(-popover => $self->GetAppWindow);
	$db->destroy;
}

sub CmdHelp {
	my $self = shift;
	my $file = $self->configGet('-helpfile');
	if (defined $file) {
		if ($file =~ /\.pod$/) { #is pod
			my $db = $self->YADialog(
				-buttons => ['Close'],
				-title => 'Help',
			);
			my $pod = $db->PodText( 
				-file => $file,
				-scrollbars => 'oe',
			)->pack(-expand => 1, -fill => 'both');
			$db->Show(-popover => $self->GetAppWindow);
			$db->destroy;
		} else {
			$self->openURL($file);
		}
	}
}

sub ConnectURL {
	my ($self, $widget, $url) = @_;
	$widget->configure(-cursor => 'hand2');
	$widget->bind('<Enter>', sub { $widget->configure(-foreground => 'blue') });
	$widget->bind('<Leave>', sub { $widget->configure(-foreground => $self->configGet('-foreground')) });
	$widget->bind('<Button-1>', sub { $self->openURL($url) });
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath				label					cmd			icon					keyb			config variable
		[	'menu_normal',		'appname::Quit',	"~About", 			'about',		'help-about',		'SHIFT+F1'	], 
		[	'menu_normal',		'appname::Quit',	"~Help", 			'help',		'help-browser',	'F1',			], 
		[	'menu_separator',	'appname::Quit',	'h1'], 

	)
}

=item B<moduleVersion>I<($module)>

Returns the version number of I<$module>. Returns undef if the module is not found.

=cut

sub moduleVersion {
	my ($self, $module) = @_;
	my $version;
	my $s = '->VERSION';
	eval "use $module; \$version = $module$s";
	return $version
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::BaseClasses::Extension>

=back

=cut


1;




