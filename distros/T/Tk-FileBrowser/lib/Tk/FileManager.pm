package Tk::FileManager;

=head1 NAME

Tk::FileManager - Tk::FileBrowser based filemanager

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = 0.09;

use base qw(Tk::Derived Tk::FileBrowser);
Construct Tk::Widget 'FileManager';

use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';

use File::Basename;
use File::Copy;
require Tk::HList;
require Tk::YADialog;
require Tk::YAMessage;


=head1 SYNOPSIS

 require Tk::FileManager;
 my $m = $window->FileManager(@options)->pack;
 $m->load($folder);

=head1 DESCRIPTION

Inherits L<Tk::FileBrowser>.

Adds some file manager functionality. A clipboard function.

=head1 ADVERTISED SUBWIDGETS

=over 4

=item B<Notifier>

=item B<DeleteDialog>

=item B<DeleteList>

=back

=head1 KEYBINDINGS

=over 4

=item B<CTRL+C>

Copies selected files and folders to the clipboard.

=item B<CTRL+V>

Pastes files and folders in the clipboard to the current location.

=item B<CTRL+X>

Copies selected files and folders to the clipboard. Files are deleted after a paste.

=item B<Delete>

Move selected files and folders to the trash bin. (Not yet functional)

=item B<Shift+Delete>

Permanently delete selected files and folders. Pops a confirm dialog first.

=back

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;

	my $mode = delete $args->{'-selectmode'};
	$mode = 'extended' unless defined $mode;
	$args->{'-selectmode'} = $mode;
	$args->{'-createfolderbutton'} = 1;

	$self->SUPER::Populate($args);
	
	$self->clipboardClear;
	$self->cutOperation(0);

	my $tree = $self->Subwidget('Tree');
	$tree->bind('<Control-c>', [$self, 'clipboardCopy']);
	$tree->bind('<Control-x>', [$self, 'clipboardCut']);
	$tree->bind('<Control-v>', [$self, 'clipboardPaste']);
	$tree->bind('<Delete>', [$self, 'trash']);
	$tree->bind('<Shift-Delete>', [$self, 'delete']);
	
	my $not = $self->Label(
		-anchor => 'w',
	);
	$self->Advertise('Notifier', $not);
	my $fg = $not->cget('-foreground');

	my $deldialog = $self->YADialog(
		-buttons => ['Ok', 'Cancel'],
		-defaultbutton => 'Ok',
	);
	my @padding = (-padx => 2, -pady => 2);
	my $df = $deldialog->Frame->pack(-fill => 'x');
	my $ilab = $df->Label->pack(-side => 'left', @padding);
	$self->after(300, sub { $ilab->configure(-image => $self->cget('-warnimage')) });
	$df->Label(-text => 'Deleting the following files and folders:')->pack(-side => 'left', @padding);
	my $dellist = $deldialog->Scrolled('HList',
		-scrollbars => 'osoe',
		-separator => '`',
		-width => 75,
	)->pack(-expand => 1, -fill =>'both', @padding);
	$self->Advertise('DeleteDialog', $deldialog);
	$self->Advertise('DeleteList', $dellist);

#	$self->ConfigSpecs(
#	);
}

sub clipboard {
	my $self = shift;
	$self->{CLIPBOARD} = \@_ if @_;
	my $c = $self->{CLIPBOARD};
	return @$c
}

sub clipboardClear {
	my $self = shift;
	$self->{CLIPBOARD} = [];
}

sub clipboardCopy {
	my $self = shift;
	$self->clipboardClear;
	$self->cutOperation(0);
	$self->clipboard($self->collect);
}

sub clipboardCut {
	my $self = shift;
	$self->clipboardClear;
	$self->cutOperation(1);
	$self->clipboard($self->collect);
}

sub clipboardPaste {
	my $self = shift;
	my @files = $self->clipboard;
	for (@files ) {
		return 0 unless $self->fileCopy($_);
	}
	if ($self->cutOperation) {
		for (@files ) {
			return 0 unless $self->fileDelete($_);
		}
	}
	$self->clipboardClear;
	$self->reload;
	return 1
}

sub confirmOverwrite {
	my ($self, $destination) = @_;
	my $write = 'Overwrite';
	$write = 'Write into' if -d $destination;
	my $action = $self->popDialog(
		-image => 'warning',
		-text => "Destination exists\n$destination",
		-buttons => ['Skip', $write, 'Cancel'],
		-defaultbutton => $write,
	);
	$self->notifyClear;
	return 0 if $action =~ /Cancel/;
	return 1 if $action eq 'Skip';
	return 2 if $action eq $write;
}

sub cutOperation {
	my $self = shift;
	$self->{CUTOPERATION} = shift if @_;
	return $self->{CUTOPERATION}
}

sub delete {
	my $self = shift;
	my @items = $self->collect;
	if ($self->deleteConfirm(@items)) {
		for (@items) {
			return 0 unless $self->fileDelete($_); 
		}
	}
	$self->reload;
}

sub deleteConfirm {
	my $self = shift;
	my $dd = $self->Subwidget('DeleteDialog');
	my $dl = $self->Subwidget('DeleteList');
	$dl->deleteAll;
	for (@_) {
		my $item = $_;
		my $image;
		if (-d $item) {
			$image = $self->GetDirIcon($item);
		} else {
			$image = $self->GetFileIcon($item);
		}
		$dl->add($item, -itemtype => 'imagetext', -image => $image, -text => $item);
	}
	my $confirm = $dd->show(-popover => $self->toplevel);
	return 1 if $confirm eq 'Ok';
	return 0
}

sub fileCopy {
	my ($self, $source, $destination) = @_;
	$destination = $self->folder unless defined $destination;
	my $sep = $self->cget('-separator');
	my $name = basename($source);
	$self->notify("Copying: $name");
	if (-d $destination) {
		$destination = $destination . $sep . $name;
	}
	if ($source eq $destination) {
		return $self->skipCancel("You can not copy onto itself:\n$source");
	}
	if (-e $destination) {
		my $action = $self->confirmOverwrite($destination);
		return $action if $action < 2;
	}
	my ($atime, $mtime) = (stat($source))[8,9];
	if (-d $source) {
		mkdir $destination unless -e $destination;
		if (-e $destination) {
			my @content = $self->readFolder($source);
			return $self->skipCancel("Can not read directory:\n$source") if (defined $content[0]) and ($content[0] eq 0);
			for (@content) {
				my $item = $source . $sep . $_;
				return 0 unless $self->fileCopy($item, $destination); 
			}
			utime($atime, $mtime, $destination);
			$self->notifyClear;
			return 1
		} else {
			return $self->skipCancel("Can not create directory:\n$destination");
		}
	} else {
		unless (copy $source, $destination) {
			return $self->skipCancel("Copying '$name' failed");
		}
		utime($atime, $mtime, $destination);
		$self->notifyClear;
		return 1
	}
}

sub fileDelete {
	my ($self, $item) = @_;
	my $sep = $self->cget('-separator');
	my $name = basename($item);
	$self->notify("Deleting: $name");
	if (-d $item) {
		my @content = $self->readFolder($item);
		return $self->skipCancel("Can not read directory:\n$item") if (defined $content[0]) and ($content[0] eq 0);
		for (@content) {
			return 0 unless $self->fileDelete($item . $sep . $_); 
		}
		$self->notifyClear;
		return rmdir $item;
	} else {
		$self->notifyClear;
		unless (unlink $item) {
			return $self->skipCancel("Deleting '$item' failed");
		}
		return 1
	}
}

sub notify {
	my ($self, $message) = @_;
	my $not = $self->Subwidget('Notifier');
	$not->configure(-text => $message);
	$not->pack(-fill => 'x');
	$self->update;
}

sub notifyClear {
	my $self = shift;
	my $not = $self->Subwidget('Notifier');
	$not->configure(-text => '');
	$not->packForget;
	$self->update;
}

my %imghash = (
	'error' => '-errorimage',
	'message' => '-msgimage',
	'warning' => '-warnimage',
);

sub popDialog {
	my $self = shift;
	my %args = @_;
	my $image = $args{'-image'};
	if (defined $image) {
		my $option = $imghash{$image};
		if (defined $option) {
			$image = $self->cget($option);
			$args{'-image'} = $image;
		}
	}
	my $dialog = $self->YAMessage(-justify => 'left', %args);
	my $button = $dialog->Show(-popover => $self->toplevel);
	$dialog->destroy;
	return $button
}

sub popMessage {
	my ($self, $text, $image) = @_;
	$image = 'message' unless defined $image;
	my $action = $self->popDialog(
		-image => $image,
		-text => $text,
		-buttons => ['Close'],
		-defaultbutton => 'Close',
	);
}

sub readFolder {
	my ($self, $folder) = @_;
	my @content = ();
	if (opendir my $fh, $folder) {
		while (my $item = readdir $fh) {
			next if $item eq '.';
			next if $item eq '..';
			push @content, $item;
		}
		closedir $fh
	} else {
		push @content, 0
	}
	return @content
}

sub skipCancel {
	my ($self, $text) = @_;
	my $action = $self->popDialog(
		-image => 'warning',
		-text => $text,
		-buttons => ['Skip', 'Cancel'],
		-defaultbutton => 'Skip',
	);
	$self->notifyClear;
	return 0 if $action =~ /Cancel/;
	return 1
}

sub trash {
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=item Add a trash bin.

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::ITree>

=item L<Tk::FileBrowser>

=back

=cut

1;













