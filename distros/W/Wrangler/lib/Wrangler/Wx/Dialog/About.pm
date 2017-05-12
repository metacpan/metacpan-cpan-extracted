package Wrangler::Wx::Dialog::About;

use strict;
use warnings;

use Wx qw(wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER wxCAPTION wxEXPAND wxCLOSE_BOX wxTOP wxBOTH wxLEFT wxALIGN_CENTER wxVERTICAL wxBOTTOM wxTE_RICH wxALIGN_CENTER wxTE_READONLY wxTE_MULTILINE wxRB_GROUP wxGROW wxALL wxRESIZE_BORDER wxCLIP_CHILDREN);
use Wx::Event qw(EVT_BUTTON);
use base 'Wx::Dialog';

sub new {
	my $class = shift;
	my $parent = shift;
	my $preselect = shift;

	my $self = $class->SUPER::new($parent, -1, "About", wxDefaultPosition, [460,440], wxDEFAULT_DIALOG_STYLE | wxCAPTION | wxRESIZE_BORDER | wxCLOSE_BOX);

	# main sizer
	my $sizer = Wx::FlexGridSizer->new(2, 1, 0, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0);
	$sizer->AddGrowableRow(0);

	# do a notebook
	my $nb = Wx::Notebook->new( $self, -1, wxDefaultPosition, wxDefaultSize, wxCLIP_CHILDREN );
	my $tab1 = Wrangler::Wx::Dialog::About::About->new($nb);
	my $tab2 = Wrangler::Wx::Dialog::About::Purchase->new($nb,$self);
	my $tab3 = Wrangler::Wx::Dialog::About::License->new($nb);
	my $tab4 = Wrangler::Wx::Dialog::About::Changes->new($nb);
	$nb->AddPage( $tab1, "&About", 0);
	$nb->AddPage( $tab2, "&Purchase", 0);
	$nb->AddPage( $tab3, "&License and User Agreement", 0);
	$nb->AddPage( $tab4, "&Changelog", 0);

	$nb->SetSelection($preselect) if $preselect;

	# a close button in the lower section
		my $buttontext	= Wx::StaticText->new($self, -1, 'Wrangler', wxDefaultPosition, wxDefaultSize);
		$buttontext->SetForegroundColour(Wx::Colour->new(128,128,128));
		my $buttonclose	= Wx::Button->new($self, -1, "Close", wxDefaultPosition, wxDefaultSize );
	my $buttonsizer = Wx::FlexGridSizer->new(1, 2, 0, 0);	# rows,cols,vgap,hgap
	$buttonsizer->AddGrowableCol(0);
	$buttonsizer->AddGrowableRow(0);
	$buttonsizer->Add($buttontext, 1, wxGROW|wxLEFT|wxTOP, 8);
	$buttonsizer->Add($buttonclose, 1, wxALL, 5);

	# compose elements
	$sizer->Add($nb, 1, wxGROW|wxALL, 5);
	$sizer->Add($buttonsizer, 1, wxGROW|wxTOP|wxEXPAND, 5);

	$self->SetSizer($sizer);

	$self->Centre();

	EVT_BUTTON($self, $buttonclose, sub { $self->Destroy(); } );

	$self->ShowModal();

	$self->Destroy();

	return $self;
}


package Wrangler::Wx::Dialog::About::About;

use strict;
use warnings;

use Wx qw(wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxEXPAND wxGROW wxLEFT wxALL wxALIGN_CENTER );
use Wx::Event qw(EVT_PAINT);
use base 'Wx::Panel';

use utf8; # text here is utf8 ("looking at you, (c)..!")

sub new {
	my $class = shift;
	my $parent = shift;

	my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxEXPAND);

	# our ImagePanelPanel (we attach the Bitmap OnPaint)
	$self->{panel} = Wx::Panel->new($self, -1, wxDefaultPosition, [425,251], wxGROW);
	$self->{bmp} = Wx::Bitmap->newFromXPM($Wrangler::Images::image{'logo_2.x_splash425'});

	my $wrangler_version = $Wrangler::VERSION;
	$wrangler_version =~ s/,/\./;
	my $text = Wx::StaticText->new($self, -1, "This is Wrangler.\nVersion ". $wrangler_version ."\n\n© 2009-2015 Clipland GmbH. All rights reserved.");
	$text->SetForegroundColour(Wx::Colour->new(45,45,45) );

	my $sizer = Wx::FlexGridSizer->new(2, 1, 0, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0);
	$sizer->AddGrowableRow(0);
	$sizer->Add($self->{panel}, 0, wxALIGN_CENTER|wxALL, 10);
	$sizer->Add($text, 0, wxLEFT, 10);

	$self->SetSizer($sizer);

	EVT_PAINT($self, \&OnPaint );

	return $self;
}

sub OnPaint {
	my ($self, $event) = @_;

	my $dc = Wx::PaintDC->new($self->{panel});
	$dc->DrawBitmap($self->{bmp}, 0,0 , 0);
}


package Wrangler::Wx::Dialog::About::Purchase;

use strict;
use warnings;

use Wx qw(wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxID_OK wxEXPAND wxGROW wxLEFT wxALL wxALIGN_CENTER wxVERTICAL wxBOTTOM);
use Wx::Event qw(EVT_BUTTON);
use base 'Wx::Panel';

sub new {
	my $class = shift;
	my $parent = shift;
	my $about_dialog = shift;

	my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxEXPAND);

	my @license = ReadLicense();

	my @text = (
		"Wrangler is free ONLY for for non-commercial use. If you are using Wrangler at work, or if you are planning to generate revenue from the files you are managing with Wrangler, then you'll need to buy a license.\n\nIf you're still not certain, contact us and we'll help you find out whether you require a commercial license. As a general rule, if you need to ask, you probably have to buy a commercial license.\n\nVisit: http://www.clipland.com/wrangler",
		"\n\n\n\nThis installation of Wrangler is licensed for commercial use."
	);

	# tab 2 Purchase
		my $purchase = Wx::StaticText->new($self, -1, (@license ? $text[1] : $text[0]), wxDefaultPosition, wxDefaultSize );
		$purchase->SetForegroundColour(Wx::Colour->new(45,45,45) );
		my $reg_box = Wx::StaticBox->new($self, -1, "Registration information" );
		my $reg_sizer  = Wx::StaticBoxSizer->new($reg_box, wxVERTICAL);
		my $LicensedTo = Wx::StaticText->new($self, -1, "Licensed to", wxDefaultPosition, wxDefaultSize, );
		my $LicenseKey = Wx::StaticText->new($self, -1, "License Key", wxDefaultPosition, wxDefaultSize, );

			my $reg_subsizer = Wx::FlexGridSizer->new(2, 2, 0, 0);	# rows,cols,vgap,hgap
			if(@license){
				$self->{License}->{Name} = Wx::TextCtrl->new($self, -1, ($license[1] ? $license[1] : ''), wxDefaultPosition, [250, -1], );
				$self->{License}->{Name}->Disable();
				$self->{License}->{Key} = Wx::TextCtrl->new($self, -1, ($license[0] ? $license[0] : ''), wxDefaultPosition, [250, -1], );
				$self->{License}->{Key}->Disable();
				$reg_subsizer->Add($LicensedTo, 1, wxGROW|wxALL, 10);
				$reg_subsizer->Add($self->{License}->{Name}, 1, wxGROW|wxALL, 10);
				$reg_subsizer->Add($LicenseKey, 1, wxGROW|wxALL, 10);
				$reg_subsizer->Add($self->{License}->{Key}, 1, wxGROW|wxALL, 10);
			}else{
				## register button
				$self->{License}->{Name} = Wx::Button->new($self, -1, 'Enter registration key');
				$reg_subsizer->Add($LicensedTo, 1, wxGROW|wxALL, 10);
				$reg_subsizer->Add($self->{License}->{Name}, 1, wxGROW);
				$reg_subsizer->Add($LicenseKey, 1, wxGROW|wxALL, 10);
				$reg_subsizer->Add($self->{License}->{Key} = Wx::Panel->new($self), 1, wxGROW|wxALL, 10);

				EVT_BUTTON($self, $self->{License}->{Name}, sub {
					my $dialog = Wx::TextEntryDialog->new($self, "Please enter the name on your license key:", "Wrangler Registration", '' );
					return unless $dialog->ShowModal() == wxID_OK;
					my $name = $dialog->GetValue();
					$dialog->Destroy();

					$dialog = Wx::TextEntryDialog->new($self, "Please enter your license key:", "Wrangler Registration", '' );
					return unless $dialog->ShowModal() == wxID_OK;
					my $reg_key = $dialog->GetValue();
					$dialog->Destroy();

					my $path = $Wrangler::Config::env{UserConfigDir} . $Wrangler::Config::env{PathSeparator} . "LICENSE-KEY";
					open(my $fh, '>', $path) or Wrangler::debug("Could not open license file for writing: $path: $!");
					binmode($fh);
					print $fh $reg_key ."\n". $name;
					close($fh);

					$reg_subsizer->Detach($self->{License}->{Name});
					$self->{License}->{Name}->Destroy();
					$reg_subsizer->Detach($self->{License}->{Key});
					$self->{License}->{Key}->Destroy();

					$self->{License}->{Name} = Wx::TextCtrl->new($self, -1, $name, wxDefaultPosition, [250, -1], );
					$self->{License}->{Name}->Disable();
					$self->{License}->{Key} = Wx::TextCtrl->new($self, -1, $reg_key, wxDefaultPosition, [250, -1], );
					$self->{License}->{Key}->Disable();

					$reg_subsizer->Insert(1, $self->{License}->{Name}, 1, wxGROW|wxALL, 10);
					$reg_subsizer->Insert(3, $self->{License}->{Key}, 1, wxGROW|wxALL, 10);

					$purchase->SetLabel($text[1]);

					$self->Layout();
				});
			}

		$reg_sizer->Add($reg_subsizer, 0, wxLEFT|wxBOTTOM, 5);

	my $sizer = Wx::FlexGridSizer->new(2, 1, 0, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0);
	$sizer->AddGrowableRow(0);
	$sizer->Add($purchase, 1, wxGROW|wxALL, 10);
	$sizer->Add($reg_sizer, 1, wxGROW|wxALL, 10);

	$self->SetSizer($sizer);

	return $self;
}

sub ReadLicense {
	my @license;

	my $commercial_package;
	if($commercial_package){
		$license[0] = 'generic license'; # commercial_package_reg_key
		$license[1] = 'unspecified user'; # commercial_package_name
	}elsif( my $path = $Wrangler::Config::env{UserConfigDir} ){
		$path .= $Wrangler::Config::env{PathSeparator} . "LICENSE-KEY";
		if(-f $path){
			open(my $fh, "<", $path) or Wrangler::debug("Error opening license file: $!");
			 @license = <$fh>;
			close($fh);
			chomp($license[0]); chomp($license[1]);
		}
	}

	return @license;
}


package Wrangler::Wx::Dialog::About::License;

use strict;
use warnings;

use Wx qw(wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxEXPAND wxGROW wxLEFT wxALL wxALIGN_CENTER wxVERTICAL wxBOTTOM wxTE_RICH wxTE_READONLY wxTE_MULTILINE);
use base 'Wx::Panel';

sub new {
	my $class = shift;
	my $parent = shift;

	my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxEXPAND);

	# load the license
	require Wrangler::License;
	my $license = $Wrangler::License::text;

		# tab 3 EULA
		my $textctrl = Wx::TextCtrl->new($self, -1, $license, wxDefaultPosition, wxDefaultSize, wxTE_RICH|wxTE_READONLY|wxTE_MULTILINE);

	my $sizer = Wx::FlexGridSizer->new(1, 1, 0, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0);
	$sizer->AddGrowableRow(0);
	$sizer->Add($textctrl, 1, wxGROW|wxALL, 10);

	$self->SetSizer($sizer);

	return $self;
}


package Wrangler::Wx::Dialog::About::Changes;

use strict;
use warnings;

use Wx qw(wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxEXPAND wxGROW wxLEFT wxALL wxALIGN_CENTER wxVERTICAL wxBOTTOM wxTE_RICH wxTE_READONLY wxTE_MULTILINE);
use base 'Wx::Panel';

sub new {
	my $class = shift;
	my $parent = shift;

	my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxEXPAND);

	# load the changelog
	require Wrangler::Changes;
	my $changes = $Wrangler::Changes::text;

		# tab 4 changelog
		my $textctrl = Wx::TextCtrl->new($self, -1, $changes, wxDefaultPosition, wxDefaultSize, wxTE_RICH|wxTE_READONLY|wxTE_MULTILINE);

	my $sizer = Wx::FlexGridSizer->new(1, 1, 0, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0);
	$sizer->AddGrowableRow(0);
	$sizer->Add($textctrl, 1, wxGROW|wxALL, 10);

	$self->SetSizer($sizer);

	return $self;
}

1;
