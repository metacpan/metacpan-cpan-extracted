package Tk::AppWindow::Ext::Selector;

=head1 NAME

Tk::AppWindow::Ext::Selector - Navigate opened documents and files

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.16";

use base qw( Tk::AppWindow::BaseClasses::Extension );

require Tk::DocumentTree;

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['MDI', 'Selector'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Adds a document list to your application.
Creates a tool panel called navigator panel unless it already exists.

=head1 CONFIG VARIABLES

=over 4

=item B<-documentinterface>

Default value 'MDI'. Sets the extension name for the
multiple docoment interface that B<Selector> communicates with.

=item B<-treeiconsize>

By default undefined. Sets and returns the size of icons
in the document tree.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	
	$self->Require('SideBars');

	my $args = $self->GetArgsRef;
	my $panel = delete $args->{'-selectorpanel'};
	$panel = 'LEFT' unless defined $panel;

	$self->addPreConfig(
		-documentinterface => ['PASSIVE', undef, undef, 'MDI'],
		-treeiconsize => ['PASSIVE'],
	);

	my $sb = $self->extGet('SideBars');
	$sb->nbAdd('navigator panel', $panel, 'left') unless $sb->nbExists('navigator panel');
	if ($sb->canRotateText) {
		$sb->nbTextSide('navigator panel', 'bottom');
		$sb->nbTextRotate('navigator panel', 90);
	}

	$self->addPostConfig('CreateSideBar', $self, $panel);
	return $self;
}

=head1 METHODS

=over 4

=item B<Add>I<($name)>

Adds $name to the document list.

=cut

sub Add {
	my ($self, $name) = @_;
	my $t = $self->Subwidget('NAVTREE');
	$t->entryAdd($name);
}

sub CreateSideBar {
	my ($self, $panel) = @_;
	my $sb = $self->extGet('SideBars');
	my $page = $sb->pageAdd('navigator panel', 'Documents', 'document-open', undef, 'Document list', 250);
	my $dt = $page->DocumentTree(
		-entryselect => ['SelectDocument', $self],
		-diriconcall => ['GetDirIcon', $self],
		-fileiconcall => ['GetFileIcon', $self],
		-saveiconcall => ['GetSaveIcon', $self],
	)->pack(-expand => 1, -fill => 'both');

	$self->Advertise('NAVTREE', $dt);
}

=item B<Delete>I<($name)>

Deletes $name from the document list

=cut

sub Delete {
	my ($self, $name) = @_;
	$self->Subwidget('NAVTREE')->entryDelete($name);
}

=item B<EntryModified>I<($name)>

Changes the icon of $name to the save icon, indicating
the document is modified.

=cut

sub EntryModified {
	my ($self, $name) = @_;
	$self->Subwidget('NAVTREE')->entryModified($name);
}

=item B<EntrySaved>I<($name)>

Changes the icon of $name to the normal file icon.

=cut

sub EntrySaved {
	my ($self, $name) = @_;
	$self->Subwidget('NAVTREE')->entrySaved($name);
}

=item B<GetDirIcon>

Callback for the document tree. Returns the folder icon.

=cut

sub GetDirIcon {
	my ($self, $name) = @_;
	my $icon = $self->getArt('folder', $self->configGet('-treeiconsize'));
	return $icon if defined $icon;
	return $self->Subwidget('NAVTREE')->DefaultDirIcon;
}

=item B<GetFileIcon>I<($name)>

Callback for the document tree. Returns the file icon.

=cut

sub GetFileIcon {
	my ($self, $name) = @_;
	my $art = $self->extGet('Art');
	if (defined $art) {
		my $icon = $art->getFileIcon($name, $self->configGet('-treeiconsize'));
		return $icon if defined $icon;
	}
	return $self->Subwidget('NAVTREE')->DefaultFileIcon;
}

=item B<GetSaveIcon>I<($name)>

Callback for the document tree. Returns the save icon.

=cut

sub GetSaveIcon {
	my ($self, $name) = @_;
	my $icon = $self->getArt('document-save');
	return $icon if defined $icon;
	return $self->Subwidget('NAVTREE')->DefaultSaveIcon;
}

=item B<SelectDocument>I<($name)>

Selects document $name in the multiple document interface.

=cut

sub SelectDocument {
	my ($self, $name) = @_;
	$self->cmdExecute('doc_select', $name);
}

=item B<SelectEntry>I<($name)>

Selects $name in the document tree.

=cut

sub SelectEntry {
	my ($self, $name) = @_;
	$self->Subwidget('NAVTREE')->entrySelect($name);
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

=item L<Tk::AppWindow::Ext::SideBars>

=back

=cut

1;









