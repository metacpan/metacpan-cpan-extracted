package Wrangler::Wx::Dialog::ListingToText;

use strict;
use warnings;

use Wx qw/:id :misc :sizer :dialog :textctrl :filedialog wxTheClipboard/;
use Wx::Event qw(EVT_RADIOBUTTON EVT_BUTTON);
# use Wx::DND;

use base 'Wx::Dialog';

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self = $class->SUPER::new( $parent, -1, "Export file-listing as text", wxDefaultPosition, [500,300],
		wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER
	);

	# hook-up access to $wrangler
	$self->{wrangler} = $parent->{wrangler};

	## element 1: radio buttons
	 my $btn_radio1 = new Wx::RadioButton($self, -1, 'filenames only');
	 my $btn_radio2 = new Wx::RadioButton($self, -1, 'prepend full path');
	 my $btn_radio3 = new Wx::RadioButton($self, -1, 'prepend relative dir-up');
	 my $radio_sizer = new Wx::BoxSizer(wxHORIZONTAL);
	$radio_sizer->Add($btn_radio1);
	$radio_sizer->Add($btn_radio2);
	$radio_sizer->Add($btn_radio3);

	## element 2: a text field for diplaying
	 $self->{text} = Wx::TextCtrl->new($self, -1, '', wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE);

	## element 3: some buttons
	 my $btn_clipboard = new Wx::Button($self, -1, 'Copy to Clipboard');
	 my $btn_save = new Wx::Button($self, -1, 'Save as...');
	 my $btn_sizer = new Wx::BoxSizer(wxHORIZONTAL);
	$btn_sizer->Add($btn_clipboard, 0, wxRIGHT, 15);
	$btn_sizer->Add($btn_save, 0, wxRIGHT, 2);
	$btn_sizer->Add(new Wx::Button($self, wxID_CANCEL, 'Cancel'), 0, wxRIGHT, 5);

	my $sizer = Wx::FlexGridSizer->new(3, 1, 0, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0); # zerobased
	$sizer->AddGrowableRow(1); # zerobased
	$sizer->Add($radio_sizer, 0, wxALL|wxGROW, 5);
	$sizer->Add($self->{text}, 0, wxALL|wxGROW, 5);
	$sizer->Add($btn_sizer, 0, wxTOP|wxALIGN_RIGHT, 10);

	EVT_RADIOBUTTON($self, $btn_radio1, sub { $self->{mode} = 1; $self->populate_display(); });
	EVT_RADIOBUTTON($self, $btn_radio2, sub { $self->{mode} = 2; $self->populate_display(); });
	EVT_RADIOBUTTON($self, $btn_radio3, sub { $self->{mode} = 3; $self->populate_display(); });
	EVT_BUTTON($self, $btn_save, \&collect_path );
	EVT_BUTTON($self, $btn_clipboard, sub {
		Wrangler::debug("ListingToText: copy to clipboard");

		my $tdo = Wx::TextDataObject->new();
		$tdo->SetText( $self->{text}->GetValue() );

		wxTheClipboard->Open();
		wxTheClipboard->SetData( $tdo );
		wxTheClipboard->Close();
	});

	$self->populate_display();

	$self->SetSizer($sizer);
	$self->Layout();
	$self->Centre();
	$self->Show;

	return $self;
}

sub populate_display {
	my $self = shift;

	my $richlist;
	if($self->{wrangler}->{main}->{filebrowser}->{current_selection}){
		$richlist = $self->{wrangler}->{main}->{filebrowser}->{current_selection};
	}else{
		$richlist = $self->{wrangler}->{fs}->richlist( $self->{wrangler}->{main}->{filebrowser}->{current_dir}, ['Filesystem'] );
		$self->{wrangler}->{main}->{filebrowser}->sort_richlist($richlist);
	}

	my $text;
	if($self->{mode} == 3){		# prepend relative dir-up
		for( @$richlist ){
			next if $_->{'Filesystem::Filename'} eq '.';
			next if $_->{'Filesystem::Filename'} eq '..';
			$text .= '..' . $Wrangler::Config::env{PathSeparator} . $_->{'Filesystem::Filename'} ."\n";
		}
	}elsif($self->{mode} == 2){	# prepend full path
		for( @$richlist ){
			next if $_->{'Filesystem::Filename'} eq '.';
			next if $_->{'Filesystem::Filename'} eq '..';
			$text .= $_->{'Filesystem::Path'} ."\n";
		}
	}else{				# filenames only
		for( @$richlist ){
			next if $_->{'Filesystem::Filename'} eq '.';
			next if $_->{'Filesystem::Filename'} eq '..';
			$text .= $_->{'Filesystem::Filename'} ."\n";
		}
	}

	$self->{text}->SetValue($text);
}

sub collect_path {
	my $self = shift;
	my $event = shift;

	Wrangler::debug("ListingToText::collect_path: collect output path");

	my $file_dialog = Wx::FileDialog->new($self,
			"Save file-listing as", "$self->{outputDir}", "$self->{outputFile}",
			"Text files (*.txt)|*.txt",
			wxFD_SAVE );

	if( $file_dialog->ShowModal == wxID_CANCEL ) {
		# nothing
		$file_dialog->Destroy;
	}else{
		if(-e $file_dialog->GetPaths){
			# $file_dialog->Destroy;

			my $warn_dialog = Wx::MessageDialog->new( $self, "This file exists! (Overwriting currently disabled.)",
				"Save file-listing to", wxOK );
			$warn_dialog->ShowModal;
			$warn_dialog->Destroy;

			$file_dialog->Destroy;
		}else{
			## replace newlines with system-default, for example \r on MAC (untested)
			if($Wrangler::Config::env{CRLF} ne "\n"){		# TextCtrl uses \n (also on MAC?)
				my $text = $self->{text}->GetValue();
				$text =~ s/\n/$Wrangler::Config::env{CRLF}/g;
			}

			open(my $fh, '>', $file_dialog->GetPath );
			binmode($fh);
			print $fh $self->{text}->GetValue();
			close($fh);

			Wrangler::debug("ListingToText::collect_path: written to ".$file_dialog->GetPaths );

			$file_dialog->Destroy;
			$self->Destroy;
		}
	}
}

1;
