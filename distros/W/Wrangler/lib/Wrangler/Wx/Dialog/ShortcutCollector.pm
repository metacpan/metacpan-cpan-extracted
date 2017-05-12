package Wrangler::Wx::Dialog::ShortcutCollector;

use strict;
use warnings;

use base 'Wx::Dialog';
use Wx qw(:id :misc :sizer :dialog :keycode);
use Wx::Event qw(EVT_TEXT EVT_BUTTON EVT_TOGGLEBUTTON EVT_CHAR);
use Encode;

sub new {
	my $class = shift;
	my $parent = shift;
	my $ref = shift;

	# Set up the dialog
	my $self = $class->SUPER::new($parent, -1, "Define a Shortcut", wxDefaultPosition, [-1,170], wxDEFAULT_DIALOG_STYLE);

	## keyboard buttons
		$self->{shift} = Wx::ToggleButton->new($self, -1, 'SHIFT' );
		$self->{ctrl} = Wx::ToggleButton->new($self, -1, 'CTRL' );
		$self->{alt} = Wx::ToggleButton->new($self, -1, 'ALT' );
		$self->{key} = Wx::TextCtrl->new($self, -1, '', wxDefaultPosition, wxDefaultSize);
#		$self->{key}->SetMaxLength(1);

	my $topsizer = Wx::FlexGridSizer->new(2, 4, 1, 1); # rows, cols, vgap, hgap
	$topsizer->Add($self->{shift}, 0, wxALL, 5);
	$topsizer->Add(Wx::Panel->new($self), 0, wxALL, 5);
	$topsizer->Add(Wx::Panel->new($self), 0, wxALL, 5);
	$topsizer->Add(Wx::Panel->new($self), 0, wxALL, 5);
	$topsizer->Add($self->{ctrl}, 0, wxALL, 5);
	$topsizer->Add($self->{alt}, 0, wxALL, 5);
	$topsizer->Add(Wx::StaticText->new($self, -1, '+', wxDefaultPosition, wxDefaultSize), 0, wxALL, 5);
	$topsizer->Add($self->{key}, 0, wxALL, 5);

	# a results display
	$self->{result} = Wx::TextCtrl->new($self, -1, '', wxDefaultPosition, wxDefaultSize);
	$self->{result}->SetEditable(0);
	$self->{result}->SetBackgroundColour( Wx::Colour->new( 222, 222, 222 ) );

	## control buttons
#			my $capture = Wx::ToggleButton->new($self, -1, 'Capture');

		my $button_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
#		$button_sizer->Add($capture, 0, wxALL, 2);
		$button_sizer->Add(Wx::Button->new($self, wxID_OK, 'OK'), 0, wxALL, 2);
		$button_sizer->Add(Wx::Button->new($self, wxID_CANCEL, 'Cancel'), 0, wxALL, 2);

	my $sizer = Wx::BoxSizer->new(wxVERTICAL);
	$sizer->Add($topsizer, 0, wxALL|wxGROW, 5);
	$sizer->Add($self->{result}, 0, wxALL|wxGROW, 5);
	$sizer->Add($button_sizer, 0, wxALL|wxALIGN_RIGHT, 5);

	$self->SetSizer($sizer);
	$self->Layout();
	$self->Centre();
#	$capture->SetFocus(); # so this modal dialog starts catching the keyboard; compare OnChar, as events are based on this $button

	EVT_TOGGLEBUTTON($self, $self->{shift}, sub { Wrangler::debug("ShortcutCollector: SHIFT: @_"); $self->{keycodes}->[0] = $self->{keycodes}->[0] ? undef : 3; $self->Calculate(); });
	EVT_TOGGLEBUTTON($self, $self->{ctrl}, sub {Wrangler::debug("ShortcutCollector: CTRL: @_"); $self->{keycodes}->[1] = $self->{keycodes}->[1] ? undef : 2; $self->Calculate(); });
	EVT_TOGGLEBUTTON($self, $self->{alt}, sub { Wrangler::debug("ShortcutCollector: ALT: @_"); $self->{keycodes}->[2] = $self->{keycodes}->[2] ? undef : 1; $self->Calculate(); });
	EVT_TEXT($self, $self->{key}, sub {
		$_[0]->{key}->ChangeValue(substr($_[0]->{key}->GetValue(),1,1)) if length($_[0]->{key}->GetValue()) > 1;
		if(my $content = $_[0]->{key}->GetValue()){
			$_[0]->{key}->ChangeValue(uc($content));
		}
		$self->{keycodes}->[3] = $_[0]->{last_keycode};
		$self->{'keys'}->[3] = $_[0]->{key}->GetValue();
		$self->Calculate();
	});
#	EVT_TOGGLEBUTTON($self, $capture, sub { print "OnCapture: @_ \n"; $_[0]->{capturing} = $_[0]->{capturing} ? undef : 1; });
#	EVT_CHAR($capture, \&OnChar );
	EVT_CHAR($self->{key}, sub { Wrangler::debug("ShortcutCollector: TextCtrl OnChar"); $_[0]->GetParent()->{last_keycode} = $_[1]->GetKeyCode(); $_[1]->Skip(1); });

	return $self;
}

# sub OnChar {
#	my $button = shift; # shift is $button, because we use the "capture" button for tapping into the onchar events
#	my $dialog = $button->GetParent();
#	my $event = shift;
#
#	print "OnChar: @_ \n";
#
#	if($dialog->{capturing}){
#		my $keycode = $event->GetKeyCode();
#		print " capturing: $keycode \n";
#		$event->Skip(0);
#		return;
#	}
#
#	$event->Skip(1);
# };

sub Calculate {
	my $dialog = shift;

	# simple mapping instead of WXK constants XORing
	my $result = '';
	$result .= 'ALT + ' if $dialog->{keycodes}->[2];
	$result .= 'CTRL + ' if $dialog->{keycodes}->[1];
	$result .= 'SHIFT + ' if $dialog->{keycodes}->[0];
	$result .= uc($dialog->{'keys'}->[3]) if $dialog->{'keys'}->[3];
	$dialog->{result_human} = $result;

	$dialog->{result_keycodes} = '';
	$dialog->{result_keycodes} .= $dialog->{keycodes}->[2].'-' if $dialog->{keycodes}->[2];
	$dialog->{result_keycodes} .= $dialog->{keycodes}->[1].'-' if $dialog->{keycodes}->[1];
	$dialog->{result_keycodes} .= $dialog->{keycodes}->[0].'-' if $dialog->{keycodes}->[0];
	$dialog->{result_keycodes} .= $dialog->{keycodes}->[3] if $dialog->{keycodes}->[3];

	$dialog->{result}->SetValue($result);
}

1;
