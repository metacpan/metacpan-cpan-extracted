package Wrangler::Wx::Dialog::Properties;

use strict;
use warnings;

use Wx qw(wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxRESIZE_BORDER wxCAPTION wxEXPAND wxCLOSE_BOX wxTOP wxBOTH wxLEFT wxALIGN_CENTER wxVERTICAL wxBOTTOM wxHORIZONTAL wxALL wxGROW wxCLIP_CHILDREN wxID_OK);
use Wx::Event qw(EVT_BUTTON);
use base 'Wx::Dialog';

sub new {
	my $class = shift;
	my $parent = shift;
	my $selections = shift;

	my $self = $class->SUPER::new($parent, -1, "Properties", wxDefaultPosition, [460,440], wxDEFAULT_DIALOG_STYLE | wxCAPTION | wxRESIZE_BORDER | wxCLOSE_BOX);

	# main sizer
	my $sizer = Wx::FlexGridSizer->new(2, 1, 0, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0);
	$sizer->AddGrowableRow(0);

	# do a notebook
	my $nb = Wx::Notebook->new( $self, -1, wxDefaultPosition, wxDefaultSize, wxCLIP_CHILDREN );
	$nb->{wrangler} = $parent->{wrangler}; # hook-up notebook with $wrangler
	my $tab2 = Wrangler::Wx::Dialog::Properties::General->new($nb,$selections);
	$nb->AddPage( $tab2, "General", 0);

	# a close button in the lower section
	my $button_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
	$button_sizer->Add(Wx::Button->new($self, wxID_OK, "Close", wxDefaultPosition, wxDefaultSize ), 0, wxALL, 2);

	# compose elements
	$sizer->Add($nb, 1, wxGROW|wxALL, 5);
	$sizer->Add($button_sizer, 1, wxGROW|wxTOP|wxEXPAND, 5);

	$self->SetSizer($sizer);

	$self->Centre();

	return $self;
}


package Wrangler::Wx::Dialog::Properties::General;

use strict;
use warnings;

use Wx qw(wxDefaultPosition wxDefaultSize wxDEFAULT_DIALOG_STYLE wxEXPAND wxGROW wxLEFT wxALL wxALIGN_CENTER wxVERTICAL wxBOTTOM);
# use Wx::Event qw();
use base 'Wx::Panel';

sub new {
	my $class = shift;
	my $parent = shift;
	my $selections = shift;

	my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxEXPAND);

	## gather initial dir data
	my $directory_text = '';
	my @dirs_todo;
	for(@$selections){
		if($_->{'Filesystem::Type'} && $_->{'Filesystem::Type'} eq 'Directory'){
			push(@dirs_todo, $_->{'Filesystem::Path'});
			$directory_text++;
		}
	}
	$directory_text = " ($directory_text directories)" if $directory_text;

	## recurse dirs
	for(@dirs_todo){
		# Wrangler::debug(" Properties: entering $_ $parent->{wrangler}");
		my $richlist = $parent->{wrangler}->{fs}->richlist($_);

		for(@$richlist){
			next if $_->{'Filesystem::Filename'} =~ /^\.$|^\.\.$/;
			if($_->{'Filesystem::Type'} && $_->{'Filesystem::Type'} eq 'Directory'){
				push(@dirs_todo, $_->{'Filesystem::Path'});
			}
			push(@$selections, $_);
		}
	}

	my $prop_sizer;
		my $totalBytes;
		for(@$selections){
			$totalBytes += $_->{'Filesystem::Size'};
		}
		my $isLink;
		for(@$selections){
			next unless $_->{'Filesystem::Link'};
			$isLink ||= $_->{'Filesystem::Link'};
			if($isLink ne $_->{'Filesystem::Link'} ){
				$isLink = 'some';
				last;
			}
		}
		my $nodeType;
		for(@$selections){
			next unless $_->{'Filesystem::Type'};
			$nodeType ||= $_->{'Filesystem::Type'};
			if( $nodeType ne $_->{'Filesystem::Type'} ){
				$nodeType = '-';
				last;
			}
		}
		my $mimeType;
		for(@$selections){
			next unless $_->{'MIME::Type'};
			$mimeType ||= $_->{'MIME::Type'};
			if( $mimeType ne $_->{'MIME::Type'} ){
				$mimeType = '-';
				last;
			}
		}
		my $Modified;
		for(@$selections){
			next unless $_->{'Filesystem::Modified'};
			if(!defined($Modified)){
				 $Modified = $_->{'Filesystem::Modified'};
			}elsif( $Modified ne $_->{'Filesystem::Modified'} ){
				$Modified = undef;
				last;
			}
		}
		my $Accessed;
		for(@$selections){
			next unless $_->{'Filesystem::Accessed'};
			if(!defined($Accessed)){
				 $Accessed = $_->{'Filesystem::Accessed'};
			}elsif( $Accessed ne $_->{'Filesystem::Accessed'} ){
				$Accessed = undef;
				last;
			}
		}
		my $Changed;
		for(@$selections){
			next unless $_->{'Filesystem::Changed'};
			if(!defined($Changed)){
				 $Changed = $_->{'Filesystem::Changed'};
			}elsif( $Changed ne $_->{'Filesystem::Changed'} ){
				$Changed = undef;
				last;
			}
		}
		my $Created;
		for(@$selections){
			next unless $_->{'Filesystem::Created'};
			if(!defined($Created)){
				 $Created = $_->{'Filesystem::Created'};
			}elsif( $Created ne $_->{'Filesystem::Created'} ){
				$Created = undef;
				last;
			}
		}
	$prop_sizer = Wx::FlexGridSizer->new(2,2,15,10); # rows,cols,vgap,hgap
	$prop_sizer->Add(Wx::StaticText->new($self, -1, 'Size:', wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, int($totalBytes/1024) .' KB', wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, 'Node-Type:', wxDefaultPosition, wxDefaultSize), 1, );
	$prop_sizer->Add(Wx::StaticText->new($self, -1, ($nodeType || '-'), wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, 'is Link:', wxDefaultPosition, wxDefaultSize), 1, );
	$prop_sizer->Add(Wx::StaticText->new($self, -1, ($isLink || 'no'), wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, 'MIME-Type:', wxDefaultPosition, wxDefaultSize), 1, );
	$prop_sizer->Add(Wx::StaticText->new($self, -1, ($mimeType || '-'), wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, 'Modified (mtime):', wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, ($Modified ? localtime($Modified) : '-')	. ($Modified ? ' ('. $Modified .')' : ''), wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, 'Accessed (atime):', wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, ($Accessed ? localtime($Accessed) : '-')	. ($Accessed ? ' ('. $Accessed .')' : ''), wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, 'Changed (chtime):', wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, ($Changed ? localtime($Changed) : '-')		. ($Changed ? ' ('. $Changed .')' : ''), wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, 'Created (ctime):', wxDefaultPosition, wxDefaultSize), 1);
	$prop_sizer->Add(Wx::StaticText->new($self, -1, ($Created ? localtime($Created) : '-')		. ($Created ? ' ('. $Created .')' : ''), wxDefaultPosition, wxDefaultSize), 1);

	my $text = scalar(@$selections) > 1 ? scalar(@$selections) ." items selected". $directory_text .":" : scalar(@$selections) ." item selected$directory_text:";

	# tab
	my $sizer = Wx::FlexGridSizer->new(2, 1, 20, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(1);
	$sizer->AddGrowableRow(1);
	$sizer->Add(Wx::StaticText->new($self, -1, $text, wxDefaultPosition, wxDefaultSize), 1, wxGROW|wxALL, 10);
	$sizer->Add($prop_sizer, 1, wxGROW|wxALL, 10);

	$self->SetSizer($sizer);

	return $self;
}

1;
