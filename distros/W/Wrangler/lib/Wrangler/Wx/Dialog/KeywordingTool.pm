package Wrangler::Wx::Dialog::KeywordingTool;

use strict;
use warnings;

use Wx qw/:id :misc :sizer :dialog :textctrl :notebook :treectrl :listctrl :window :radiobutton wxCLOSE_BOX WXK_DELETE/;
use Wx::Event qw(EVT_RADIOBUTTON EVT_BUTTON EVT_CHECKBOX EVT_CHAR);

use base 'Wx::Dialog';

sub new {
	my $class = shift;
	my $parent = shift;

	my $self = $class->SUPER::new($parent, -1, "Keywording Tool", wxDefaultPosition, [460,440], wxDEFAULT_DIALOG_STYLE | wxCAPTION | wxRESIZE_BORDER | wxCLOSE_BOX);

	## element 1: add section
		$self->{add_textctrl} = Wx::TextCtrl->new( $self, -1, '', wxDefaultPosition, [-1,-1] );
		my $btn_add = new Wx::Button($self, -1, 'Add');
	my $add_sizer = Wx::FlexGridSizer->new(1, 3, 0, 0);	# rows,cols,vgap,hgap
	$add_sizer->AddGrowableCol(1); # zerobased
	$add_sizer->Add(Wx::StaticText->new($self, -1, 'Add: '), 0, wxTOP, 7 );
	$add_sizer->Add($self->{add_textctrl}, 0, wxEXPAND);
	$add_sizer->Add($btn_add);

	## element 2: radio buttons
	my %delimiter;
		$delimiter{comma}	= new Wx::RadioButton($self, -1, 'comma');
	#	$delimiter{comma}->SetValue(1);
		$self->{delimiter_space} = Wx::CheckBox->new($self, -1, 'add space');
		$self->{delimiter_space}->SetValue(1);
		$delimiter{space}	= new Wx::RadioButton($self, -1, 'space');
		$delimiter{line_feed}	= new Wx::RadioButton($self, -1, 'line feed \\n');
	my $delimiter_sizer = new Wx::BoxSizer(wxHORIZONTAL);
	$delimiter_sizer->Add(Wx::StaticText->new($self, -1, 'Delimiter: '), 0, wxTOP, 2);
	$delimiter_sizer->Add($delimiter{comma});
	$delimiter_sizer->Add($self->{delimiter_space});
	$delimiter_sizer->Add($delimiter{space});
	$delimiter_sizer->Add($delimiter{line_feed});

	## element 2: checkboxes
		$self->{check_dedupe} = Wx::CheckBox->new($self, -1, 'Deduplicate');
		$self->{check_dedupe}->SetValue(1);
		$self->{check_sort} = Wx::CheckBox->new($self, -1, 'Sort');
		$self->{check_sort}->SetValue(1);
		$self->{check_dquote} = Wx::CheckBox->new($self, -1, 'Double quote');
		$self->{check_dquote}->SetValue(0);
	my $orga_sizer = new Wx::BoxSizer(wxHORIZONTAL);
	$orga_sizer->Add(Wx::StaticText->new($self, -1, 'Organize: '), 0, wxTOP, 2);
	$orga_sizer->Add($self->{check_dedupe});
	$orga_sizer->Add($self->{check_sort});
	$orga_sizer->Add($self->{check_dquote});

	## sizer stage 1
	my $nb = Wx::Notebook->new( $self, -1, wxDefaultPosition, wxDefaultSize, );
	my $nb_raw = Wx::Panel->new( $nb, -1);
	my $nb_struc = Wx::Panel->new( $nb, -1, );
	$nb->AddPage( $nb_raw, "Raw", 0);
	$nb->AddPage( $nb_struc, "Structured", 0);
		my $nb_raw_sizer = Wx::FlexGridSizer->new(1, 1, 0, 0);	# rows,cols,vgap,hgap
	$nb_raw_sizer->AddGrowableCol(0); # zerobased
	$nb_raw_sizer->AddGrowableRow(0); # zerobased
	$nb_raw->SetSizer($nb_raw_sizer);
		my $nb_struc_sizer = Wx::FlexGridSizer->new(1, 1, 0, 0);	# rows,cols,vgap,hgap
	$nb_struc_sizer->AddGrowableCol(0); # zerobased
	$nb_struc_sizer->AddGrowableRow(0); # zerobased
	$nb_struc->SetSizer($nb_struc_sizer);

	## element 3a: a text field for diplaying
	$self->{text} = Wx::TextCtrl->new($nb_raw, -1, '', wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE|wxTE_READONLY );
	$nb_raw_sizer->Add($self->{text}, 0, wxGROW|wxEXPAND);
	## element 2b: a text field for diplaying
	$self->{tree} = Wx::TreeCtrl->new($nb_struc, -1, wxDefaultPosition, wxDefaultSize, wxTR_HIDE_ROOT|wxTR_HAS_BUTTONS|wxTR_EDIT_LABELS|wxSUNKEN_BORDER);
	$nb_struc_sizer->Add($self->{tree}, 0, wxGROW|wxEXPAND);

	## info area
	$self->{info} = Wx::TextCtrl->new($self, -1, '', wxDefaultPosition, wxDefaultSize, wxTE_READONLY );
	$self->{info}->SetBackgroundColour( $self->GetBackgroundColour() );

	## element 4: some buttons
#	my $btn_load = new Wx::Button($self, -1, 'Load');
#	my $btn_save = new Wx::Button($self, -1, 'Save as...');
	my $btn_sizer = new Wx::BoxSizer(wxHORIZONTAL);
#	$btn_sizer->Add($btn_load, 0, wxALL, 2);
#	$btn_sizer->Add($btn_save, 0, wxALL, 2);
	$btn_sizer->Add(new Wx::Button($self, wxID_CANCEL, 'Cancel'), 0, wxALL, 2);

	# sizer stage 2
	my $sizer = Wx::FlexGridSizer->new(6, 1, 0, 0);	# rows,cols,vgap,hgap
	$sizer->AddGrowableCol(0); # zerobased
	$sizer->AddGrowableRow(5); # zerobased
	$sizer->Add($add_sizer, 0, wxALL|wxGROW, 5);
	$sizer->Add(Wx::StaticText->new($self, -1, 'Output'), 0, wxALL, 5);
	$sizer->Add($delimiter_sizer, 0, wxALL|wxGROW, 5);
	$sizer->Add($orga_sizer, 0, wxALL|wxGROW, 5);
	$sizer->Add($self->{info}, 0, wxALL|wxGROW, 5);
	$sizer->Add($nb, 0, wxALL|wxGROW, 5);
	$sizer->Add($btn_sizer, 0, wxALL|wxALIGN_RIGHT, 5);

	EVT_RADIOBUTTON($self, $delimiter{comma},	sub { $self->{delimiter} = ',';	$self->populate_raw(); $self->populate_struc(); });
	EVT_RADIOBUTTON($self, $delimiter{space},	sub { $self->{delimiter} = ' ';	$self->populate_raw(); $self->populate_struc(); });
	EVT_RADIOBUTTON($self, $delimiter{line_feed},	sub { $self->{delimiter} = $Wrangler::Config::env{CRLF}; $self->populate_raw(); $self->populate_struc(); });
	EVT_CHECKBOX($self, $self->{check_dedupe},	sub { $self->populate_raw(); $self->populate_struc(); });
	EVT_CHECKBOX($self, $self->{check_sort},	sub { $self->populate_raw(); $self->populate_struc(); });
	EVT_CHECKBOX($self, $self->{check_dquote},	sub { $self->populate_raw(); $self->populate_struc(); });
	EVT_CHECKBOX($self, $self->{delimiter_space},	sub { $self->populate_raw(); $self->populate_struc(); });
	EVT_BUTTON($self, $btn_add, sub {
		return if $self->{add_textctrl}->IsEmpty();

		my $input = $self->{add_textctrl}->GetValue();
		$self->{add_textctrl}->ChangeValue('');
		Wrangler::debug("KeywordingTool: add: $input");

		$input =~ s/\n|\r/,/g;
		my @list;
		for( split(/,\s*/, $input) ){
			next if $_ eq '';
			next if $_=~ /^\s+$/;

			my $item = $_;	# cleanup leading/trailing space
			$item =~ s/^\s+//;
			$item =~ s/\s+$//;

			push(@list, $item);
		}

		$self->populate_raw(\@list);
		$self->populate_struc(\@list);
	});
#	EVT_BUTTON($self, $btn_load, sub { $self->list_from_file($self->collect_path_load); $self->populate_raw(); $self->populate_struc(); } );
#	EVT_BUTTON($self, $btn_save, \&collect_path_save );
	EVT_CHAR( $self->{tree}, sub {
		my $keycode = $_[1]->GetKeyCode();	# speedup by less calls

		# Wrangler::debug("OnChar: $keycode");

		if($keycode == WXK_DELETE){
			# Wrangler::debug("Delete");

			my @selections = $self->{tree}->GetSelections();

			for(@selections){
				my $pos = $self->{tree}->GetPlData($_);
				Wrangler::debug("KeywordingTool: delete $_, pos:$pos ");
				splice(@{ $self->{list} },$pos,1); # remove pos from array
			}

			$self->populate_raw();
			$self->populate_struc();
		}
	});

	$self->populate_raw();
	$self->populate_struc();

	$self->SetSizer($sizer);
	$self->Layout();
	$self->Centre();
	$self->Show;

	return $self;
}


sub populate_raw {
	my $self = shift;
	my $add_list_ref = shift;

	$self->{info}->ChangeValue('');

	if($add_list_ref){
		for(@$add_list_ref){
			push(@{$self->{list}}, { value => $_ });
			# Wrangler::debug("KeywordingTool::populate_raw: @{$self->{list}} $_");
		}

		$self->{info}->ChangeValue( (scalar(@$add_list_ref) || 0) ." keywords added, ");
	}

	## dedupe?
	my @prepared_list;
	if( $self->{list} && $self->{check_dedupe}->IsChecked() ){
		# Wrangler::debug("KeywordingTool::populate_raw: dedupe");
		my %hash;
		foreach my $item ( @{$self->{list}} ){
			$hash{ $item->{value} } = 1;
		}
		@prepared_list = keys %hash;

		my $diff = scalar(@{$self->{list}}) - scalar(@prepared_list);
		$self->{info}->ChangeValue($self->{info}->GetValue() . ($diff || 0) ." doublettes, ". scalar(@prepared_list) ." keywords, ");
	}else{
		for(@{$self->{list}}){
			push(@prepared_list, $_->{value});
		}
	}

	$self->{info}->ChangeValue($self->{info}->GetValue() . ($self->{list} ? scalar(@{$self->{list}}) : 0) ." total keywords");

	## sort?
	if( $self->{check_sort}->IsChecked() ){
		# Wrangler::debug("KeywordingTool::populate_raw: sort");
		@prepared_list = sort @prepared_list;
	}

	# quote?
	if( $self->{check_dquote}->IsChecked() ){
		for(@prepared_list){ $_ = '"'.$_.'"'; }
	}

	## delimiter?
	my $delimiter = $self->{delimiter} || ',';
	if( ($delimiter eq ',' || $delimiter eq ' ') && $self->{delimiter_space}->IsChecked() ){
		$delimiter .= ' ';
	}

	my $text = join($delimiter, @prepared_list);

	# Wrangler::debug("KeywordingTool::populate_raw: @prepared_list raw_formatted:$text");

	$self->{text}->ChangeValue($text);
}

sub populate_struc {
	my $self = shift;

	## a hidden root node
	if(!$self->{tree}->{root}){
		$self->{tree}->{root} = $self->{tree}->AddRoot( 'Keywords', -1, -1, Wx::TreeItemData->new( 'rootnode' ) );
	}else{
		$self->{tree}->DeleteChildren($self->{tree}->{root});
	}

	my %seen;
	for( 0.. ($#{ $self->{list} }) ){
		my $node = $self->{tree}->AppendItem(
				$self->{tree}->{root},
				$self->{list}->[$_]->{value}, -1, -1,
		);

		$self->{tree}->SetPlData($node, $_); # we store the list-pos as data

		foreach my $key (keys %{ ${ $self->{list} }[$_] }){
			next unless defined( $self->{list}->[$_]->{$key} );

			$self->{tree}->AppendItem(
				$node,
				$key .': '. $self->{list}->[$_]->{$key}, -1, -1,
			);
		}

		if( defined($seen{ $self->{list}->[$_]->{value} }) ){
			$self->{tree}->SetItemTextColour($node, Wx::Colour->new(220,30,30) );
			$self->{tree}->AppendItem(
				$node,
				'note: is duplicate',
			);
		}else{
			$seen{ $self->{list}->[$_]->{value} } = 1;
		}

	#	if(${ $self->{list} }[$_]->{not_in_dictionary}){
	#	}
	}
}

1;

__END__

=pod

=head1 NAME

Wrangler::Wx::Dialog::KeywordingTool - Deduping and sorting of keywords or tags

=head1 DESCRIPTION

This dialog offers a simple tool to ease the task of "keywording" which normally 
involves merging, aggregating, organising, deduping and sorting larger corpora of
keywords or tags associated with images or arbitrary media files. This is helpful
especially while preparing images for stock or microstock agencies.

=head1 COPYRIGHT & LICENSE

This module is part of L<Wrangler>. Please refer to the main module for further
information and licensing / usage terms.

=cut
