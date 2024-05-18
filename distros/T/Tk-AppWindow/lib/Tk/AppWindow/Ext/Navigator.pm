package Tk::AppWindow::Ext::Navigator;

=head1 NAME

Tk::AppWindow::Ext::Navigator - Navigate opened documents and files

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.04";

use base qw( Tk::AppWindow::BaseClasses::Extension );

require Tk::DocumentTree;

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['MDI', 'Navigator'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Adds a document list to your application.
Loads extension NavigatorPanel if it is not already loaded.

=head1 CONFIG VARIABLES

=over 4

=item B<-documentinterface>

Default value 'MDI'. Sets the extension name for the
multiple docoment interface that B<Navigator> communicates with.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	
	$self->Require('NavigatorPanel');

	$self->addPreConfig(
		-documentinterface => ['PASSIVE', undef, undef, 'MDI'],
	);

	$self->addPostConfig('CreateDocumentList', $self);
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

sub CreateDocumentList {
	my $self = shift;
	my $page = $self->extGet('NavigatorPanel')->addPage('Documents', 'document-open', undef, 'Document list');

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
	my $icon = $self->getArt('folder');
	return $icon if defined $icon;
	return $self->Subwidget('NAVTREE')->DefaultDirIcon;
}

=item B<GetFileIcon>I<($name)>

Callback for the document tree. Returns the file icon.

=cut

sub GetFileIcon {
	my ($self, $name) = @_;
	my $icon = $self->getArt('text-x-plain');
	return $icon if defined $icon;
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

=item L<Tk::AppWindow::Ext::NavigatorPanel>

=back

=cut

1;









