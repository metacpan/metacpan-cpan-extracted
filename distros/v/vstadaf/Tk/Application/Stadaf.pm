#
# PERL Modul
# Tk-Frontend for Stadaf
#
# Copyright (C) 1999 Dirk Tostmann (tostmann@tiss.com)
#
# $rcs = ' $Id: Stadaf.pm,v 1.1 1999/02/22 09:01:35 root Exp $ ' ;	
#
###################################################################################
package Tk::Application::Stadaf;
###################################################################################
#
$VERSION = 0.01;
#
use Tk::Application 0.03;
use Tk::DialogBox;
use Tk::Frame;
use Tk::Label;
use Tk::Optionmenu;
use Tk::Checkbutton;
use Tk::WaitBox;
use Tk::ProgressBar;  
use Tk::FireButton;  
use Tk::ROText;
use STADAF;
use strict;
use vars qw/@ISA/;
#
@ISA = qw(Tk::Application);
#
#
#
###################################################################################
sub QUIT {
  my $self = shift;
  $self->CloseClick;
  $self->FREEZE;  
  $self->SUPER::QUIT;
}


###################################################################################
sub SETUP {
  my $self = shift;
  
  return unless $self->SUPER::SETUP;
  
  $self->THAW;
  
  $self->{OPTS} = {
		   'rs' => "\r\n",
		   'fs' => ";",
		   'qs' => '"',
		   'headers' => 1,
		   'ss' => ' ',
		   'fields' => [],
		  } unless $self->{OPTS};
  
  $self->{FILE} = '' unless $self->{FILE};
  
  my $f1 = $self->{MF}->Frame->pack(-side => 'bottom', -fill => 'x');
  $f1->Button(
	      -text    => q! << !,
	      -command => sub {$self->show_record('f')},
	     )->pack(-side => 'left');
  
  $f1->FireButton(
		  -text    => q!  <  !,
		  -command => sub {$self->show_record('p')},
		 )->pack(-side => 'left');
  
  $f1->FireButton(
		  -text => q!  >  !,
		  -command => sub {$self->show_record('n')},
		 )->pack(-side => 'left');
  
  $self->{MEMO} = $self->{MF}->Scrolled( qw/ROText -setgrid true 
					 -wrap none -highlightthickness 0 -borderwidth 0 -scrollbars osre -background Gray
					 -relief sunken -borderwidth 1 -font/ => $self->{FIXFONT}
				       )->pack(-expand=>'yes', -fill=>'both');
  
  1;
}


###################################################################################
sub RUN { 
  my $self = shift;
  
  $self->SUPER::RUN;
}


######################################################################
sub store($$) {
  my ($self,$vars) = @_;
  $self->SUPER::store($vars);
  push @$vars, $self->{OPTS};
  push @$vars, $self->{FILE};
 
}

######################################################################
sub load($$) {
  my ($self,$vars) = @_;
  $self->SUPER::load($vars);
  $self->{OPTS}     = shift (@$vars) || {};
  $self->{FILE}     = shift (@$vars) || '';
}

###################################################################################
sub create_menubar {
  my $self = shift;
  
  $self->mkmb('File', 0, 'File related stuff',
	      [
	       ['Open',      sub{$self->OpenClick},    0],
	       ['Close',     sub{$self->CloseClick},   0],
	       ['Exit',      sub{$self->QUIT},         0],
	      ]);
  
  $self->mkmb('Dump', 0, 'Dump the file to CSV',
	      [
	       ['Show header info', sub{$self->show_table}, 5],
	       ['-'],
	       ['Dump to screen'  , sub{$self->dump_records}, 8],
	       ['Dump to file'    , sub{$self->dump_records(1)}, 8],
	       ['-'],
	       ['Field selection', sub{$self->Fields_DLG}, 1],
	       ['Export options', sub{$self->Options_DLG}, 0],
	      ]);
  
  
  $self->mkmb('Help', 0, 'There when you need it',
	      [
	       ['About..',   sub{$self->About},     0],
	      ],'right');
  
}

#######################################################
sub CloseClick {
  my $self = shift;
  $self->{DB}->close if $self->{DB};
  delete $self->{DB}; 
  $self->ClearMemo;
  $self->ClearMsg;
}

#######################################################
sub OpenClick {
  my $self = shift;
  
  my $file = $self->{FILE} || '';
  
  $file =~ s/\\/\//g;
  $file =~ s/\/[^\/]*$//;
  
  $file =~ s/\//\\/g if($^O =~ /win/i);
  
  undef $file unless $file;
  
  my $types = undef;		#[];#[['Databases', '.dbf', '']];
  
  my $filename = $self->{TW}->getOpenFile(-filetypes=>$types, -initialdir=>$file, -title=>'Select database');
  
  return unless $filename;
  
  $self->{FILE} = $filename;
  
  $self->open_db;
  
}

#######################################################
sub ClearMemo {
  my $self   = shift;
  $self->{MEMO}->delete('0.0','end');
}

#######################################################
sub SetMemo {
  my $self   = shift;
  $self->{MEMO}->insert('end',@_);
}

#######################################################
sub About {
  my $self   = shift;
  $self->InfoMsgBox("Tk Frontend for Stadaf\n(C) 1999 Dirk Tostmann\ntostmann\@tosti.com\nVersion: $Tk::Application::Stadaf::VERSION");
}

#######################################################
sub open_db {
  my $self = shift;
  
  $self->CloseClick;
  
  my $DB = new STADAF 'name' => $self->{FILE}, %{$self->{OPTS}};
  
  unless (defined $DB) {
    $self->ErrorMsgBox( STADAF->errstr || "Error reading header!\nNot a DAF file?"); 
    return;
  }

  $DB->{NOCACHE} = 1;
  
  $self->{DB} = $DB;
  $self->ShowMsg("Successfully...");
  
  $self->show_table;
}

#######################################################
sub show_table {
  my $self   = shift;
  $self->ClearMemo;

  unless ($self->{DB}) {
    $self->ErrorMsgBox( 'Open a DAF-File first!'); 
    return;
  }
  
  $self->SetMemo($self->{DB}->header_info); 
}

#######################################################
sub show_record {
  my $self   = shift;
  my $mode   = shift;

  unless ($self->{DB}) {
    $self->ErrorMsgBox( 'Open a DAF-File first!'); 
    return;
  }

  my $DAF = $self->{DB};
  my ($i,$key);

  if ($mode eq 'f') {
   $DAF->gotop;
  } elsif ($mode eq 'p') {
   $DAF->seek2rec($DAF->{'record_number'}-2);
  } else {
   return if $DAF->EOF;
  }

  
  $self->ShowMsg("fetching record...");
  my $hash = $DAF->read_record;

  $self->ClearMemo;
  unless ($hash) {
    $self->ErrorMsgBox( $DAF->{'errstr'}); 
    return;
  }


  my $result = sprintf( "%30s : %s\n", 'Record Number', $DAF->{'record_number'});
  my $fields = @{$self->{OPTS}->{fields}} ? $self->{OPTS}->{fields} : $DAF->{'field_names'};

  foreach $i (0..@$fields-1) {
    $key = $fields->[$i];
    $result .= ref($hash->{$key}) ? sprintf( "%30s : %s\n", $key, "@{$hash->{$key}}") : sprintf( "%30s : %s\n", $key, $hash->{$key});
  }

  $self->SetMemo($result); 
  $self->ShowMsg( sprintf("showing record %d of %d (%d %%)", $DAF->{'record_number'}, $DAF->num_rec, $DAF->{'record_number'}*100/$DAF->num_rec));
}


###################################################################################
sub Fields_DLG {
  my $self   = shift;
  
  unless ($self->{DB}) {
    $self->ErrorMsgBox( "Sorry!\nOpen a database first..."); 
    return;
  }
  
  $self->ShowMsg("please select fields you like to export...");
  
  my $DIALOG = $self->{TW}->DialogBox(
				      -title          => 'Fields',
				      -buttons        => ['Ok', 'Cancel'],
				     );
  
  my $root = $DIALOG->Frame()->pack(-fill=>'both',-expand=>1 );
  
  # widget creation 
  
  my($label_1) = $root->Label (
			       -text => 'Selected',
			      );
  my($label_2) = $root->Label (
			       -text => 'Fields',
			      );
  
  my($listbox_1) = $root->Scrolled('Listbox',
				   -scrollbars => 'sw',
				   -selectmode => 'multiple',
				  );
  
  my($listbox_2) = $root->Scrolled ( 'Listbox',
				     -scrollbars => 'se',
				     -selectmode => 'multiple',
				   );
  
  my($button_1) = $root->Button (
				 -text => q!<<!,
				 -command => sub{$self->move_field($listbox_1,$listbox_2)},
				);
  my($button_2) = $root->Button (
				 -text => q!>>!,
				 -command => sub{$self->move_field($listbox_2,$listbox_1)},
				);
  my($button_4) = $root->Button (
				 -text => 'All',
				 -command => sub{$self->set_all_field($listbox_1,$listbox_2)},
				);
  my($button_3) = $root->Button (
				 -text => 'None',
				 -command => sub{$self->set_all_field($listbox_2,$listbox_1)},
				);
  
  
  # Geometry management
  
  $label_1->grid(
		 -in => $root,
		 -column => '1',
		 -row => '1'
		);
  $label_2->grid(
		 -in => $root,
		 -column => '3',
		 -row => '1'
		);
  $listbox_1->grid(
		   -in => $root,
		   -column => '1',
		   -row => '2',
		   -rowspan => '5',
		   -sticky => 'nesw'
		  );
  $button_1->grid(
		  -in => $root,
		  -column => '2',
		  -row => '2'
		 );
  $listbox_2->grid(
		   -in => $root,
		   -column => '3',
		   -row => '2',
		   -rowspan => '5',
		   -sticky => 'nesw'
		  );
  $button_2->grid(
		  -in => $root,
		  -column => '2',
		  -row => '3'
		 );
  $button_4->grid(
		  -in => $root,
		  -column => '2',
		  -row => '5'
		 );
  $button_3->grid(
		  -in => $root,
		  -column => '2',
		  -row => '6'
		 );
  
  # Resize behavior management
  
  # container $root (rows)
  $root->gridRowconfigure(1, -weight  => 0, -minsize  => 30);
  $root->gridRowconfigure(2, -weight  => 0, -minsize  => 30);
  $root->gridRowconfigure(3, -weight  => 0, -minsize  => 30);
  $root->gridRowconfigure(4, -weight  => 0, -minsize  => 50);
  $root->gridRowconfigure(5, -weight  => 0, -minsize  => 30);
  $root->gridRowconfigure(6, -weight  => 0, -minsize  => 30);
  
  # container $root (columns)
  $root->gridColumnconfigure(1, -weight => 0, -minsize => 75);
  $root->gridColumnconfigure(2, -weight => 0, -minsize => 50);
  $root->gridColumnconfigure(3, -weight => 0, -minsize => 75);
  
  # additional interface code
  # end additional interface code
  
  my $curfields = $self->{OPTS}->{fields};
  $listbox_1->insert('0.0', @$curfields);
  
  my $cf = {};
  foreach (@{$curfields}) {
    $cf->{$_} = 1;
  }
  
  my @fields = $self->{DB}->field_names;
  foreach (@fields) {
    $listbox_2->insert('end', $_) unless $cf->{$_};
  }
  
  my $rc = $DIALOG->Show;
  $self->ClearMsg;
  return unless ($rc=~/ok/i);
  
  @fields = $listbox_1->get('0.0','end');
  
  $self->{OPTS}->{fields} = [@fields];
}


###################################################################################
sub set_all_field {
  my $self   = shift;
  my $l1  = shift || return;
  my $l2  = shift || return;
  
  my $DB  = $self->{DB} || return;
  
  my @fields = $DB->field_names;
  
  $l1->delete('0.0','end');
  $l2->delete('0.0','end');
  
  $l1->insert('0.0', @fields);
}

###################################################################################
sub move_field {
  my $self   = shift;
  my $l1  = shift || return;
  my $l2  = shift || return;
  
  my @cur = $l2->curselection;
  return unless(defined @cur);
  
  foreach (@cur) {
    $l1->insert('end',$l2->get($_));
  }
  
  foreach (0..@cur-1) {
    $l2->delete($cur[@cur-$_-1].'.0');
  }
  
}

###################################################################################
sub Options_DLG {
  my $self   = shift;
  
  $self->ShowMsg("please set your options...");
  
  my $headers = $self->{OPTS}->{headers} || 0;
  my $memos   = $self->{OPTS}->{ignorememo} || 0;
  
  my $ss = $self->{OPTS}->{ss} || 'none';
  $ss = 'TAB'   if ($ss eq "\t");
  $ss = 'SPC'   if ($ss eq ' ');
  
  my $rs = $self->{OPTS}->{rs} || 'none';
  $rs = 'LF'   if ($rs eq "\n");
  $rs = 'CRLF' if ($rs eq "\r\n");
  
  my $fs = $self->{OPTS}->{fs} || 'none';
  $fs = 'TAB'  if ($fs eq "\t");
  
  my $qs = $self->{OPTS}->{qs} || 'none';
  
  my $DIALOG = $self->{TW}->DialogBox(
				      -title          => 'Options',
				      -buttons        => ['Ok', 'Cancel'],
				     );
  
  my $root = $DIALOG->Frame()->pack(-fill=>'both',-expand=>1 );
  
  # widget creation 
  
  my($label_2) = $root->Label (
			       -font => '-*-MS Sans Serif-Bold-R-Normal-*-*-200-*-*-*-*-*-*',
			       -text => 'Dumping options',
			      );
  my($label_1) = $root->Label (
			       -text => 'Field separator:',
			      );
  my($entry_1) = $root->Optionmenu(
				   -options => [('none', 'TAB', q!:!, q!,!, q!;!)],
				   -textvariable => \$fs,
				   -font => $self->{FIXFONT},
				  );
  my($label_3) = $root->Label (
			       -text => 'Line separator:',
			      );
  my($button_1) = $root->Optionmenu(
				    -options => [qw/none CRLF LF/],
				    -textvariable => \$rs,
				    -font => $self->{FIXFONT},
				   );
  my($label_4) = $root->Label (
			       -text => 'Quote string char:',
			      );
  my($entry_2) = $root->Optionmenu(
				   -options => [('none', q!"!, q!'!)], #"
				   -textvariable => \$qs,
				   -font => $self->{FIXFONT},
				  );
  
  my($label_5) = $root->Label (
			       -text => 'Struct separator:',
			      );
  my($entry_3) = $root->Optionmenu(
				   -options => [('none', '|', 'SPC', 'TAB', ',', ';', ':', '-', '+')],
				   -textvariable => \$ss,
				   -font => $self->{FIXFONT},
				  );
  
  my($checkbutton_1) = $root->Checkbutton (
					   -text => 'include headers',
					   -variable => \$headers,
					  );
  
  
  # Geometry management
  
  $label_2->grid(
		 -in => $root,
		 -column => '1',
		 -row => '1',
		 -columnspan => '2'
		);
  
  $label_1->grid(
		 -in => $root,
		 -column => '1',
		 -row => '2',
		 -sticky => 'e'
		);
  
  $entry_1->grid(
		 -in => $root,
		 -column => '2',
		 -row => '2'
		);
  
  $label_3->grid(
		 -in => $root,
		 -column => '1',
		 -row => '3',
		 -sticky => 'e'
		);
  
  $button_1->grid(
		  -in => $root,
		  -column => '2',
		  -row => '3'
		 );
  
  $label_4->grid(
		 -in => $root,
		 -column => '1',
		 -row => '4',
		 -sticky => 'e'
		);
  
  $entry_2->grid(
		 -in => $root,
		 -column => '2',
		 -row => '4'
		);
  
  $label_5->grid(
		 -in => $root,
		 -column => '1',
		 -row => '5',
		 -sticky => 'e'
		);
  
  $entry_3->grid(
		 -in => $root,
		 -column => '2',
		 -row => '5'
		);
  
  $checkbutton_1->grid(
		       -in => $root,
		       -column => '1',
		       -row => '6',
		       -columnspan => '2'
		      );
  
  # Resize behavior management
  
  # container $root (rows)
  $root->gridRowconfigure(1, -weight  => 0, -minsize  => 30);
  $root->gridRowconfigure(2, -weight  => 0, -minsize  => 30);
  $root->gridRowconfigure(3, -weight  => 0, -minsize  => 30);
  $root->gridRowconfigure(4, -weight  => 0, -minsize  => 30);
  $root->gridRowconfigure(5, -weight  => 0, -minsize  => 30);
  $root->gridRowconfigure(6, -weight  => 0, -minsize  => 30);
  
  # container $root (columns)
  $root->gridColumnconfigure(1, -weight => 0, -minsize => 30);
  $root->gridColumnconfigure(2, -weight => 0, -minsize => 2);
  
  # additional interface code
  # end additional interface code
  
  my $rc = $DIALOG->Show;
  $self->ClearMsg;
  return unless ($rc=~/ok/i);
  
  $self->{OPTS}->{rs} = $rs;
  $self->{OPTS}->{rs} = ''     if ($rs eq 'none');
  $self->{OPTS}->{rs} = "\n"   if ($rs eq 'LF');
  $self->{OPTS}->{rs} = "\r\n" if ($rs eq 'CRLF');
  
  $self->{OPTS}->{fs} = $fs;
  $self->{OPTS}->{fs} = ''     if ($fs eq 'none');
  $self->{OPTS}->{fs} = "\t"   if ($fs eq 'TAB');
  
  $self->{OPTS}->{ss} = $ss;
  $self->{OPTS}->{ss} = ''     if ($ss eq 'none');
  $self->{OPTS}->{ss} = "\t"   if ($ss eq 'TAB');
  $self->{OPTS}->{ss} = ' '    if ($ss eq 'SPC');
  
  $self->{OPTS}->{qs} = $qs;
  $self->{OPTS}->{qs} = ''     if ($qs eq 'none');
  
  $self->{OPTS}->{headers} = $headers;
  $self->{OPTS}->{ignorememo}   = $memos;
  
}

#######################################################
sub Open_FH {
  my $self = shift;
  
  my $DB   = $self->{DB} || return;
  $self->{MAX} = -1;
  
  my $file = $self->{FILE} || '';
  
  $file =~ s/\\/\//g;
  $file =~ s/\/[^\/]*$//;
  $file =~ s/\//\\/g if($^O =~ /win/i);
  
  undef $file unless $file;
  
  my ($rc,$RC);
  
  if ($self->{FH}) {
    my $rc = $self->{TW}->getSaveFile(-initialdir=>$file, -title=>'Select file to store');
    return 0 unless $rc;
    
    $RC = open(FILE, ">$rc");
    unless ($RC) {
      $self->ErrorMsgBox( "Can not open '$rc' for output!"); 
      return 0;
    }
    
  } else {
    
    if ($DB->last_record>100) {
      $rc = $self->MsgBox('Database contains '.$DB->last_record." records.\nDo you really want to see them all?",'question','YesNoCancel');
      return 0 if ($rc =~ /cancel/i);
      $self->{MAX} = 9 if ($rc =~ /no/i);
    }
    
    $self->ClearMemo;
  }
  $self->ShowMsg("Output handle opened...");
  1;
}
#######################################################
sub Close_FH {
  my $self = shift;
  if ($self->{FH}) {
    close(FILE);
  } else {
    
  }
  $self->ShowMsg("Output handle closed...");
}

#######################################################
sub output_line {
  my $self = shift;
  if ($self->{FH}) {
    print(FILE @_) || return;
  } else {
    $self->SetMemo(@_);
  }
  1;
}

#######################################################
sub dump_records {
  my $self    = shift;
  my $DB      = $self->{DB};
  unless ($DB) {
    $self->ErrorMsgBox( "Sorry!\nOpen a database first..."); 
    return;
  }
  
  $self->{FH} = shift || 0;
  
  my %options   = ( 'rs' => "\n", 'fs' => ':', 'undef' => '', 'ss' => ' ' );
  my %inoptions = %{$self->{OPTS}};
  for my $key (keys %inoptions) {
    my $value = $inoptions{$key};
    my $outkey = lc $key;
    $outkey =~ s/[^a-z]//g;
    $options{$outkey} = $value;
  }
  
  my ($rs, $fs, $undef, $ss, $fields) = @options{ qw( rs fs undef ss fields ) };
  my $qs  = $self->{OPTS}->{qs};
  
  my @fields = ();
  
  if (defined $fields && @$fields>0) {
    @fields = @$fields;
  } else {
    @fields = $DB->field_names;
  }
  
  my ($record,$value,$fn,$txt);
  
  foreach $value (@fields) {
    
    next unless $self->{OPTS}->{headers};
    
    $txt .= $qs.$value.$qs.$fs;
  }
  
  $txt =~  s/$fs$//;
  
  my ($DBH,$cursor,$dir,$table);
  
  $self->Open_FH || return;
  $self->output_line($txt.$rs) if $self->{OPTS}->{headers};
  
  my ($percent_done);
  my $MSG = $self->{FH} ? 'to file...' : 'to screen...';
  
  my $wd = $self->{TW}->WaitBox(
				-title => $self->{TITLE},
				-txt1 => "Exporting records",
				-foreground => 'blue',
				-background => 'white',
				-cancelroutine => sub{$self->{MAX}=1}
			       );
  
  
  my($u) = $wd->{SubWidget}->{uframe};
  $u->pack(-expand => 1, -fill => 'both');
  $u->Label(-textvariable => \$MSG, -background => 'white')->pack(-expand => 1, -fill => 'both');
  
  my $progress = $u->ProgressBar(
				 -width => 200,
				 -height => 20,
				 -from => 0,
				 -to => $DB->last_record,
				 -blocks => 10,
				 -anchor => 'e',
				 -colors => [0, 'blue'],
				 -variable => \$percent_done
				)->pack();
  
  
  $wd->Show;
  
  $self->ShowMsg("dumping records...");
  
  $DB->gotop;
  
  while (!$DB->EOF) {
    $txt = '';
    
    $record = $DB->read_record;
    
    foreach (0..@fields-1) {
      $fn    = $fields[$_];
      $value = ref($record->{$fn}) ? join $ss, @{$record->{$fn}} : $record->{$fn} || '';
      $value =~ s/\n/\\r\\n/g;
      $value = $qs.$value.$qs;
      $txt  .= $value.$fs;
    }
    
    $txt =~  s/$fs$//;
    
    $self->{MAX}=1 unless $self->output_line($txt.$rs);
    $percent_done++;
    $self->{TW}->update;
    
    last if ($self->{MAX}-- == 0);
    
  }
  
  $self->Close_FH;  
  
  $wd->unShow;
  
  if ($self->{MAX} == -1) {
    $self->ErrorMsgBox( "Dump not completed!"); 
  } else {
    $self->InfoMsgBox( "Dump successful done!"); 
  }
  
  $self->ShowMsg("Thank you!");
  $DB->gotop;
  
}







