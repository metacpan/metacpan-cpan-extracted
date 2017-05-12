package Wrangler::Wx::Dialog::MultiRename;

use strict;
use warnings;

use base 'Wx::Dialog';
use Wx qw/:id :misc :sizer :dialog/;
use Wx::Event 'EVT_TEXT';
use Encode;

sub new {
	my $class = shift;
	my $parent = shift;
	my $ref = shift;

	# Set up the dialog
	my $self = $class->SUPER::new($parent, -1, "Rename multiple files", wxDefaultPosition, [-1,130], wxDEFAULT_DIALOG_STYLE);

	## prepend/append gui elements
			$self->{pre} = Wx::TextCtrl->new($self, -1, '', wxDefaultPosition, wxDefaultSize, );
			$self->{fix} = Wx::StaticText->new($self, -1, '<multiple filenames>', wxDefaultPosition, [-1,40]);
			$self->{ins} = Wx::TextCtrl->new($self, -1, '', wxDefaultPosition, wxDefaultSize, );
			$self->{suf} = Wx::StaticText->new($self, -1, '.suffix', wxDefaultPosition, [-1,40]);


		my $prepapp_sizer = Wx::StaticBoxSizer->new( Wx::StaticBox->new($self, -1, " Prepend/ append " ), wxHORIZONTAL);
		$prepapp_sizer->Add($self->{pre}, 0, wxALL, 2);
		$prepapp_sizer->Add($self->{fix}, 0, wxTOP, 7);
		$prepapp_sizer->Add($self->{ins}, 0, wxALL, 2);
		$prepapp_sizer->Add($self->{suf}, 0, wxALL, 7);
		$self->{pre}->SetFocus();

	## clever-multi-file/pattern-based-rename preparation (todo)
	my @pos;
	foreach my $hashref (@{ $ref }){
		my $file = $hashref->{file};

		foreach my $i (0..length($file)){
			if(!defined($pos[$i])){
				$pos[$i] = substr($file,$i,1);	
			}elsif($pos[$i] eq substr($file,$i,1)){
				$pos[$i] = substr($file,$i,1);				
			}else{
				$pos[$i] = '*';
			}
		}		
	}

	## strange: length here counts correctly but when we assemble it back into the textctrl below
	## it introduces spaces, as if a utf8 string was handled incorrectly or so... todo
	$self->{length} = scalar(@pos);

	my $sizer = Wx::BoxSizer->new(wxVERTICAL);
	$sizer->Add($prepapp_sizer, 0, wxALL|wxGROW, 5);

	if($parent->{wrangler}->{debug}){
		$self->SetSize([-1,250]);

		## clever-multi-file/pattern-based-rename gui elements (todo)
		$self->{pattern} = Wx::TextCtrl->new($self, -1, "@pos", wxDefaultPosition, wxDefaultSize, );
		my $pattern_sizer = Wx::StaticBoxSizer->new( Wx::StaticBox->new($self, -1, " Patterns " ), wxVERTICAL);
		$pattern_sizer->Add($self->{pattern}, 0, wxALL|wxGROW, 5);

		$sizer->Add($pattern_sizer, 0, wxALL|wxGROW, 5);
	}

		my $btn_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
		$btn_sizer->Add(Wx::Button->new($self, wxID_OK, 'OK'), 0, wxALL, 2);
		$btn_sizer->Add(Wx::Button->new($self, wxID_CANCEL, 'Cancel'), 0, wxALL, 2);

	$sizer->Add($btn_sizer, 0, wxALL|wxALIGN_RIGHT, 5);

	$self->SetSizer($sizer);
	$self->Layout();
	$self->Centre();
	$self->{pre}->SetFocus(); # so this modal dialog starts catching the keyboard

#	EVT_TEXT($self, $self->{textctrl}, \&OnText);

	return $self;
}

sub OnText {
	my $self = shift;

	$self->{textctrl}->SetInsertionPoint(3);
}

1;
