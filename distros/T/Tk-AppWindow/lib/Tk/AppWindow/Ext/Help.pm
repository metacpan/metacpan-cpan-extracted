package Tk::AppWindow::Ext::Help;

=head1 NAME

Tk::AppWindow::Ext::Help - about box and help facilities

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.02";

use base qw( Tk::AppWindow::BaseClasses::Extension );

use Tk;
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

Specify the link to a hash. Possible keys

 version
 license
 author
 http
 email

=item Switch: B<-helpfile>

Point to your help file.

=item Switch: B<-helptype>

Can be B<pod> or B<html>. Default value is B<pod>.

=back

=head1 B<COMMANDS>

The following commands are defined.

=over 4

=item B<about>

Pops the about box.

=item B<help>

Pops the help dialog or initiates the internet browser..

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->Require('WebBrowser');
	$self->addPreConfig(
		-aboutinfo => ['PASSIVE', undef, undef, {
			version => $VERSION,
			license => 'Same as Perl',
			author => 'Some Dude',
			http => 'www.nowhere.com',
			email => 'nobody@nowhere.com',
		}],
		-helptype => ['PASSIVE', undef, undef, 'pod'],
		-helpfile => ['PASSIVE', undef, undef, Tk::findINC('Tk/AppWindow.pm')],
	);

	$self->cmdConfig(
		about => [\&CmdAbout, $self],
		help => [\&CmdHelp, $self],
	);
	return $self;
}

=head1 METHODS

=cut

sub CmdAbout {
	my $self = shift;
	my $inf = $self->configGet('-aboutinfo');
	my $w = $self->GetAppWindow;
	my $db = $w->YADialog(
		-buttons => ['Ok'],
		-defaultbutton => 'Ok',
		-title => 'About ' . $w->appName,
	);
	$db->configure(-command => sub { $db->destroy });
	my @padding = (-padx => 2);
	my $ap;
	if (exists $inf->{licensefile}) {
		my $nb = $db-NoteBook->pack(-expand => 1, -fill => 'both');
		$ap = $nb->add('about', -label =>'About');
		my $lp = $nb->add('licence', -label => 'License');
		my $t = $lp->Scrolled('ROText', -scrollbars => 'osoe')->pack(-expand =>1, -fill => 'both', @padding);
	} else {
		$ap = $db->Frame->pack(-expand => 1, -fill => 'both');;
	}
	my $lg = $self->configGet('-logo');
	if (defined $lg) {
		$ap->Label(-image => $w->Photo(-file => $lg))->pack;
	}
	my $gf = $ap->Frame->pack(-expand => 1, -fill => 'both');
	my $row = 0;
	my @col0 = ( -column => 0, -sticky => 'e', @padding);
	my @col1 = ( -column => 1, -sticky => 'w', @padding);
	if (exists $inf->{version}) {
		$gf->Label(-text => 'Version:')->grid(-row => $row, @col0);
		$gf->Label(-text => $inf->{version})->grid(-row => $row, @col1);
		$row ++;
	}
	if (exists $inf->{author}) {
		$gf->Label(-text => 'Author:')->grid(-row => $row, @col0);
		$gf->Label(-text => $inf->{author})->grid(-row => $row, @col1);
		$row ++;
	}
	if (exists $inf->{email}) {
		$gf->Label(-text => 'E-mail:')->grid(-row => $row, @col0);
		$gf->Label(-text => $inf->{email})->grid(-row => $row, @col1);
		$row ++;
	}
	if (exists $inf->{http}) {
		$gf->Label(-text => 'Website:')->grid(-row => $row, @col0);
		my $url = $gf->Label(
			-text => $inf->{http},
			-cursor => 'hand2',
		)->grid(-row => $row, @col1);
		my $fg = $url->cget('-foreground');
		$url->bind('<Enter>', sub { $url->configure(-foreground => 'blue') });
		$url->bind('<Leave>', sub { $url->configure(-foreground => $fg) });
		$url->bind('<Button-1>', sub { $self->cmdExecute('browser_open', $url->cget('-text')) });
		$row ++;
	}
	if (exists $inf->{license}) {
		$gf->Label(-text => 'License:')->grid(-row => $row, @col0);
		$gf->Label(-text => $inf->{license})->grid(-row => $row, @col1);
		$row ++;
	}
	$db->Show(-popover => $w);
}

sub CmdHelp {
	my $self = shift;
	my $type = $self->configGet('-helptype');
	my $file = $self->configGet('-helpfile');
	if ($type eq 'pod') {
		my $w = $self->GetAppWindow;
		my $db = $w->YADialog(
			-buttons => ['Ok'],
			-title => 'Help',
		);
		$db->configure(-command => sub { $db->destroy });
		my $pod = $db->PodText( 
			-file => $file,
			-scrollbars => 'oe',
		)->pack(-expand => 1, -fill => 'both');
		$db->Show(-popover => $w);
	} elsif ($type eq 'html') {
		$self->cmdExecute('browser_open', $file)
	} else {
		warn "Unknown help type: $type"
	}
}

=item B<MenuItems>

Returns the about and help menu items for the main menu.
Called by the b<MenuBar> extension.

=cut

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


