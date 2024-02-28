package TestTextManager;

use Tk;
use base qw(Tk::Derived Tk::AppWindow::BaseClasses::ContentManager);
Construct Tk::Widget 'TestTextManager';
require Tk::TextUndo;

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);
	my $text = $self->Scrolled('TextUndo',
	)->pack(-expand => 1, -fill => 'both');
	$self->CWidg($text);

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => [$text],
	);
}

sub doClear {
	my $self = shift;
	my $t = $self->CWidg;
	$t->delete('0.0', 'end');
	$t->editReset;
}

sub doLoad {
	my ($self, $file) = @_;
	my $t = $self->CWidg;
	$t->Load($file);
	$t->editModified(0);
	return 1
}

sub doSave {
	my ($self, $file) = @_;
	my $t = $self->CWidg;
	$t->Save($file);
	$t->editModified(0);
	return 1
}

sub doSelect {
	$_[0]->CWidg->focus
}

sub IsModified {
	my $self = shift;
	my $t = $self->CWidg;
	return $t->editModified;	
}

1;

