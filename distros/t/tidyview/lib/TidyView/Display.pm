package TidyView::Display;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);

use Data::Dumper;

INIT {
  eval "require Perl::Signature";

  if ($@) {
    undef *_warnSemanticDelta;
  } else {
    *_warnSemanticDelta = \&warnSemanticRuination;
  }
}

sub preview_tidy_changes {
  my ($self, %args) = @_;

  my ($fileToTidy, $DiffTextWidget, $rootWindow) = @args{qw(fileToTidy
							    DiffTextWidget
							    rootWindow
							)};
  $rootWindow->Busy(-recurse => 1);

  my $tidiedText = PerlTidy::Run->execute(file => $fileToTidy);

  $DiffTextWidget->load(a => $fileToTidy);
  $DiffTextWidget->load(b => $tidiedText);
  $DiffTextWidget->compare(-granularity => qr/(\s+|\W)/);

  $rootWindow->Unbusy();

  if (defined *_warnSemanticDelta{CODE}) {
    if (Perl::Signature->source_signature($DiffTextWidget->Subwidget('text_a')->get('1.0', 'end')) ne
	Perl::Signature->source_signature($DiffTextWidget->Subwidget('text_b')->get('1.0', 'end'))) {
      $self->_warnSemanticDelta(widget => $rootWindow);
    }
  }
}


sub warnSemanticRuination {
  my ($self, %args) = @_;

  my ($widget) = @args{qw(widget)};

  $widget->messageBox(
		      -title   => 'Problem tidying File',
		      -icon    => 'warning',
		      -type    => 'Ok',
		      -message => "Semantic change detected on tidied version\nDo not use these options",
		     );
}

1;
