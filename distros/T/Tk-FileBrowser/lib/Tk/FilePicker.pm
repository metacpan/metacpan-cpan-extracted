package Tk::FilePicker;

=head1 NAME

Tk::FilePicker - Tk::FileBrowser based file dialog

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = 0.06;

use base qw(Tk::Derived Tk::YADialog);
Construct Tk::Widget 'FilePicker';

require Tk::FileBrowser;
require Tk::YAMessage;

=head1 SYNOPSIS

 require Tk::FilePicker;
 my $p = $window->FilePicker(@options);
 my @files = $p->pick;

=head1 DESCRIPTION

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-checkoverwrite>

Only works when the '-selectmode' option is set to single.
Checks if the selected file exists and prompts and overwrite dialog.

=item Switch: B<-selectstring>

Text string for the 'Ok' button.

=back

=head1 ADVERTISED SUBWIDGETS

=over 4

=item B<Browser>

=item B<Entry>

=back

=head1 METHODS

=cut

sub Populate {
	my ($self,$args) = @_;

	$args->{'-buttons'} = ['Cancel'];
	
	$self->SUPER::Populate($args);
	
	$self->{LASTFOLDER} = '.';
	
	my $okbutton = $self->Subwidget('buttonframe')->Button(
		-command => ['OkButton', $self],
	);
	$self->ButtonPack($okbutton);
	$self->Advertise('okbutton', $okbutton);
	
	my @padding = (-padx => 2, -pady => 2);

	my $browser = $self->FileBrowser(
		-createfolderbutton => 1,
		-invokefile => ['OkButton', $self],
		-postloadcall => ['entryClear', $self],
		-width => 75,
		-browsecmd => ['GetSelection', $self],
	)->pack(@padding, -expand => 1, -fill => 'both');
	$self->Advertise('Browser', $browser);

	my $entry = $self->Entry(
	)->pack(@padding, -fill => 'x');
	$entry->bind('<Return>', [$self, 'ReturnPressed']);
	$self->Advertise('Entry', $entry);

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-checkoverwrite => ['PASSIVE', undef, undef, 0],
		-selectstring => [{-text => $okbutton}, undef, undef, 'Open'],
		DEFAULT => [ $browser ],
	);
	$self->Delegates(
		pick => $self,
		pickFileOpen => $self,
		pickFileOpenMulti => $self,
		pickFileSave => $self,
		pickFolderSelect => $self,
		DEFAULT => $browser
	);
}

sub confirmOverWrite {
	my ($self, $file) = @_;
	return 1 unless -e $file;
	my $dialog = $self->YAMessage(
		-image => $self->cget('-warnimage'),
		-text => "File exists, overwrite it?\n$file",
		-buttons => ['Ok', 'Cancel'],
	);
	my $button = $dialog->Show(-popover => $self);
	$dialog->destroy;
	return 1 if $button eq 'Ok';
	return 0
}

sub entry {
	return $_[0]->Subwidget('Entry')
}

sub entryClear {
	my $self = shift;
	$self->entry->delete(0, 'end');
}

sub GetSelection {
	my $self = shift;
	my @sel = $self->infoSelection;
	my $e = $self->entry;
	$self->entryClear;
	if ($self->cget('-selectmode') eq 'single') {
		for (@sel) {
			$e->insert('end', $_)
		}
	} else {
		for (@sel) {
			$e->insert('end', "\"$_\" ")
		}
	}
}

sub lastfolder {
	my $self = shift;
	$self->{LASTFOLDER} = shift if @_;
	return $self->{LASTFOLDER}
}

sub OkButton {
	my $self = shift;
	if (($self->cget('-selectmode') eq 'single') and $self->cget('-checkoverwrite')) {
		my $file = $self->GetFullName($self->entry->get);
		$self->Pressed('Ok') if $self->confirmOverWrite($file);
	} else {
		$self->Pressed('Ok');
	}
}

=pod

All the pick methods can be called with these options:

=over 4

=item B<-initialdir>

Directory to load on pop.

=item B<-initialfile>

Suggested file name.

=back

The pick methods always return their results in list context. So
even when you expect only one result you have to do:

 my ($file) = $fp->pickWhatEver(%options);

=over 4

=item B<pick>

The basic pick method. Besides the two options above you can give it many
of the options of Tk::FilePicker and Tk::FileBrowser.

=cut

sub pick {
	my $self = shift;
	my %args = @_;

	my $initialdir = delete $args{'-initialdir'};
	$initialdir = $self->lastfolder unless defined $initialdir;
	my $initialfile = delete $args{'-initialfile'};

	for (keys %args) {
		$self->configure($_, $args{$_})
	}
	my $folder = $self->folder;
	$self->load($initialdir);
	$self->Subwidget('okbutton')->focus;
	my $entry = $self->entry;
	$self->entryClear;
	$entry->insert('end', $initialfile) if defined $initialfile;

	my $pressed = $self->show(-popover => $self->parent->toplevel);

	my @res = ();
	unless ($pressed =~ /Cancel/) {
		$self->lastfolder($self->folder);
		my $string = $entry->get;
		if ($self->cget('-selectmode') eq 'single') {
			if ($string ne '') {
				my $full = $self->GetFullName($string);
				push @res, $full;
			}
		} else {
			my @c = $self->collect;
			if (@c) {
				push @res, @c
			} else {
				push @res, $self->GetFullName($string) if $string ne '';
			}
		}
	}
	return @res;
}

=item B<pickFileOpen>

Calls B<pick> configured to select one file for opening.

=cut

sub pickFileOpen {
	my $self = shift;
	my %args = @_;
	return $self->pick(
		-checkoverwrite => 0,
		-showfolders => 1,
		-showfiles => 1,
		-selectmode => 'single',
		-selectstring => 'Open',
		-title => 'Open file',
		%args,
	);
}

=item B<pickFileOpenMulti>

Calls B<pick> configured to select multiple files for opening.

=cut

sub pickFileOpenMulti {
	my $self = shift;
	my %args = @_;
	return $self->pick(
		-checkoverwrite => 0,
		-showfolders => 1,
		-showfiles => 1,
		-selectmode => 'extended',
		-selectstring => 'Open',
		-title => 'Open files',
		%args,
	);
}

=item B<pickFileSave>

Calls B<pick> configured to select one file for saving. Pops
a dialog for overwrite if the selected file exists.

=cut

sub pickFileSave {
	my $self = shift;
	my %args = @_;
	return $self->pick(
		-checkoverwrite => 1,
		-showfolders => 1,
		-showfiles => 1,
		-selectmode => 'single',
		-selectstring => 'Save',
		-title => 'Save file',
		%args,
	);
}

=item B<pickFolderSelect>

Calls B<pick> configured to select one folder.

=cut

sub pickFolderSelect {
	my $self = shift;
	my %args = @_;
	return $self->pick(
		-checkoverwrite => 0,
		-showfolders => 1,
		-showfiles => 0,
		-selectmode => 'single',
		-selectstring => 'Select',
		-title => 'Select folder',
		%args,
	);
}

sub ReturnPressed {
	my $self = shift;
	my $string = $self->entry->get;
	my $full = $self->GetFullName($string);
	if ((-e $full) and (-d $full)) {
		$self->entryClear;
		$self->load($full);
	} else {
		$self->OkButton;
	}
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

=head1 SEE ALSO

=over 4

=back

=cut

1;

