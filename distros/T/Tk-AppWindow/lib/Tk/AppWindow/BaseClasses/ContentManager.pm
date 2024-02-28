package Tk::AppWindow::BaseClasses::ContentManager;

=head1 NAME

Tk::AppWindow::BaseClasses::ContentManager - baseclass for content handling

=cut

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.02";

use Tk;
use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'ContentManager';

use File::Basename;


=head1 SYNOPSIS

 #This is useless
 require Tk::AppWindow::BaseClasses::ContentManager;
 my $handlerplug = $app->ContentManager->pack;

 #This is what you should do
 package MyContentHandler
 use base qw(Tk::Derived Tk::AppWindow::BaseClasses::ContentManager);
 Construct Tk::Widget 'MyContentHandler';

=head1 DESCRIPTION

This is an opaque base class to help you create a content manager for your application.

It is Tk::Frame based and you can inherit it as a Tk mega widget;

The methods below are used by the extensions MDI and SDI. It is for you to make
them do the right stuff by overriding them.

=head1 CONFIG VARIABLES

=over 4

=item B<-extension>

Reference to the document interface extension (MDI, SDI or other) that is creating the 
content handler.

This option is mandatory!

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $ext = delete $args->{'-extension'};
	carp "Option -extension mustt be specified" unless defined $ext;
	
	$self->SUPER::Populate($args);
	$self->{EXT} = $ext;

	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
	$self->after(20, ['ConfigureCM', $self]);
}

=item B<Close>

In the current form it makes a call to B<doclear> and returns 1.
Override it to do the things neede to close your content.
Return a boolean for succes or failure.

=cut

sub Close {
	my $self = shift;
	$self->doClear;
	return 1
}

sub ConfigureCM {
	my $self = shift;
	my $ext = $self->Extension;
	my $cmopt = $ext->configGet('-contentmanageroptions');
	my @o = @$cmopt; #hack, i do not know why this is needed.
	for (@o) {
		my $val = $ext->configGet($_);
		$self->configure($_, $val) if ((defined $val) and ($val ne ''));
	}
}

=item B<CWidg>I<(?$widget?)>

Set or return the widget that is directly responsible
for holding your content.

Do not override this.

=cut

sub CWidg {
	my $self = shift;
	$self->{WIDGET} = shift if @_;
	return $self->{WIDGET};
}

=item B<doClear>

Override this to clear all content in your B<CWidg>.

=cut

sub doClear{
}

=item B<doLoad>I(<$file)>

Override this to load a file from disk.
Make it return a boolean on succes or failure.

=cut

sub doLoad {
	return 1
}

=item B<doSave>I(<$file)>

Override this to save the content to disk.
Make it return a boolean on succes or failure.

=cut

sub doSave {
	return 1
}

=item B<doSelect>

Override this to do what needs to be done
when this content is selected.

=cut

sub doSelect {
}

=item B<Extension>

Returns a reference to the document interface (MDI, SDI or derivative).

Do not override this.

=cut

sub Extension {
   my $self = shift;
   if (@_) { $self->{EXT} = shift; }
   return $self->{EXT};
}

=item B<IsModified>

Override this for checking if the content has been modified.

=cut

sub IsModified {
	my $self = shift;
	return 0
}

=item B<Load>I<($file)>

Makes a call to B<doLoad>

=cut

sub Load {
	my ($self, $file) = @_;
	return $self->doLoad($file);
}

=item B<Save>I<($file)>

Makes a call to B<doSave>

=cut

sub Save {
	my ($self, $file) = @_;
	return $self->doSave($file);
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::Frame>

=item L<Tk::AppWindow::Ext::MDI>

=back

=cut

1;






