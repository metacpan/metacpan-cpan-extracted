#!/usr/local/bin/perl -w

# Wizard for new class definition

use strict;

#===vptk user code before tk===< THE CODE BELOW WILL RUN BEFORE TK STARTED >===
use IPC::Open3;
my $VPTK_Path = $ENV{PWD} || '.';
unless (-d "$VPTK_Path/vptk_w/VPTK_Widget")
{
  ($VPTK_Path) = $0 =~ m#^(.*)[\\/]#;
}
die "VPTK path not found ($VPTK_Path)!" unless -d $VPTK_Path;
my $changes=0;
use Tk;
use Tk::BrowseEntry;
use Tk::Button;
use Tk::Checkbutton;
use Tk::Frame;
use Tk::LabEntry;
use Tk::LabFrame;
use Tk::Label;
use Tk::Listbox;
use Tk::Menu;
use Tk::Menubutton;
use Tk::Message;
use Tk::NoteBook;
use Tk::ROText;
use Tk::Text;

my $mw=MainWindow->new(-title=>'VPTK_W new widget class definition');
my @code=();
my %switches;
my %pic;
opendir(P,"$VPTK_Path/toolbar");
foreach my $pic(grep(/(gif|xpm)$/,readdir(P)))
{
  my $pic_file="$VPTK_Path/toolbar/$pic";
  next if $pic_file =~ /\.gif/ && -s $pic_file > 300;
  next if $pic_file =~ /\.xpm/ && -s $pic_file > 1000;
  $pic =~ s/\..+$//;
  $pic{$pic} = $mw->Photo(-file=>$pic_file)
    unless defined $pic{$pic};
}
closedir(P);
my $sel_pic='undef';

use Tk::Dialog;
#===vptk widgets definition===< DO NOT WRITE UNDER THIS LINE >===
use Tk::Balloon;
my $vptk_balloon=$mw->Balloon(-background=>"lightyellow",-initwait=>550);
use vars qw/$class_path $have_geometry $scrollable $sel_pic $default_parameters $class_name $prop_name $prop_value/;

my $w_NoteBook_main = $mw -> NoteBook (  ) -> pack(-anchor=>'nw', -fill=>'both', -expand=>1);
my $w_Frame_Controls = $mw -> Frame ( -relief=>'flat' ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'x', -expand=>1);
my $w_Button_Previous = $w_Frame_Controls -> Button ( -command=>\&prev_tab, -state=>'normal', -width=>10, -relief=>'raised', -text=>'<< Previous', -compound=>'none' ) -> pack(-anchor=>'nw', -fill=>'y', -side=>'left', -padx=>10);
my $w_Button_Next = $w_Frame_Controls -> Button ( -command=>\&next_tab, -state=>'normal', -width=>10, -relief=>'raised', -text=>'Next >>', -compound=>'none' ) -> pack(-anchor=>'nw', -fill=>'y', -side=>'left', -padx=>10);
my $w_Button_Ok = $w_Frame_Controls -> Button ( -command=>\&on_ok, -width=>10, -state=>'normal', -relief=>'raised', -text=>'Ok', -compound=>'none' ) -> pack(-anchor=>'nw', -fill=>'y', -side=>'left', -padx=>10);
my $w_Button_Cancel = $w_Frame_Controls -> Button ( -command=>sub {exit}, -state=>'normal', -width=>60, -relief=>'raised', -text=>'Cancel', -compound=>'right', -bitmap=>'error' ) -> pack(-anchor=>'nw', -side=>'left', -padx=>10);
my $w_NoteBookFrame_intro = $w_NoteBook_main -> add ( 'w_NoteBookFrame_intro', -label=>'Hello', -state=>'normal', -justify=>'left' );
my $w_Message_Hello = $w_NoteBookFrame_intro -> Message ( -justify=>'left', -relief=>'flat', -text=>'"This is a VPTK_W add-on. You can define here new widget class for VPTK_W. The new class definition will appear in available widgets list next time you run vptk_w.pl; Respective file will be created under $VPTK_Path/vptk_w/VPTK_Widget"', -aspect=>500 ) -> pack(-pady=>10, -padx=>10);
my $w_NoteBook_WidgetClass = $w_NoteBook_main -> add ( 'w_NoteBook_WidgetClass', -wraplength=>80, -label=>'Widget Class selection', -state=>'normal', -justify=>'left' );
my $w_LabEntry_Class = $w_NoteBook_WidgetClass -> LabEntry ( -label=>'Class:', -labelPack=>[-side=>'left',-anchor=>'n'], -state=>'normal', -justify=>'left', -relief=>'sunken', -textvariable=>\$class_path ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'x', -padx=>10);
my $w_Listbox_Classes = $w_NoteBook_WidgetClass -> Scrolled ( 'Listbox', -selectmode=>'single', -relief=>'sunken', -scrollbars=>'osoe' ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'both', -expand=>1, -padx=>10);
my $w_NoteBookFrame_help = $w_NoteBook_main -> add ( 'w_NoteBookFrame_help', -label=>'Perldoc Help', -state=>'normal', -justify=>'left' );
my $w_ROText_Help = $w_NoteBookFrame_help -> Scrolled ( 'ROText', -width=>30, -state=>'normal', -height=>10, -relief=>'sunken', -scrollbars=>'osoe', -wrap=>'none' ) -> pack(-pady=>5, -fill=>'both', -expand=>1, -padx=>5);
my $w_NoteBook_WidgetVPTK = $w_NoteBook_main -> add ( 'w_NoteBook_WidgetVPTK', -wraplength=>100, -label=>'VPTK-related properties', -state=>'normal', -justify=>'left' );
my $w_LabFrame_icon = $w_NoteBook_WidgetVPTK -> LabFrame ( -label=>'Icon', -relief=>'ridge', -labelside=>'acrosstop' ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'x', -padx=>5);
my $w_Checkbutton_HaveGeom = $w_NoteBook_WidgetVPTK -> Checkbutton ( -anchor=>'nw', -indicatoron=>1, -state=>'normal', -justify=>'left', -relief=>'flat', -text=>'Have geometry', -variable=>\$have_geometry ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'x', -padx=>5);
my $w_Checkbutton_037 = $w_NoteBook_WidgetVPTK -> Checkbutton ( -anchor=>'nw', -overrelief=>'flat', -indicatoron=>1, -state=>'normal', -justify=>'left', -offrelief=>'flat', -relief=>'flat', -text=>'Scrollable', -variable=>\$scrollable ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'x', -padx=>5);
my $w_Label_icon = $w_LabFrame_icon -> Label ( -justify=>'left', -text=>[], -relief=>'flat', -image=>$pic{"undef"} ) -> pack(-anchor=>'nw', -pady=>5, -side=>'left', -padx=>5);
my $w_LabEntry_IconNm = $w_LabFrame_icon -> LabEntry ( -label=>'Icon name:', -labelPack=>[-side=>'left',-anchor=>'n'], -state=>'normal', -justify=>'left', -relief=>'sunken', -textvariable=>\$sel_pic ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'x', -side=>'left', -expand=>1, -padx=>5);
my $w_Menubutton_icons = $w_LabFrame_icon -> Menubutton ( -state=>'normal', -justify=>'left', -relief=>'raised', -compound=>'none', -text=>'...' ) -> pack(-anchor=>'nw', -pady=>5, -side=>'left', -padx=>5);
my $w_Menu_pic = $w_Menubutton_icons -> Menu ( -tearoff=>0 ); $w_Menubutton_icons->configure(-menu=>$w_Menu_pic);
my $w_LabEntry_DefltParam = $w_NoteBook_WidgetVPTK -> LabEntry ( -label=>'Default parameters:', -labelPack=>[-side=>'left',-anchor=>'n'], -state=>'normal', -justify=>'left', -relief=>'sunken', -textvariable=>\$default_parameters ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'x', -padx=>5);
my $w_LabEntry_ClsName = $w_NoteBook_WidgetVPTK -> LabEntry ( -label=>'Class name:', -labelPack=>[-side=>'left',-anchor=>'n'], -state=>'normal', -justify=>'left', -relief=>'sunken', -textvariable=>\$class_name ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'x', -padx=>5);
my $w_NoteBook_TkProperties = $w_NoteBook_main -> add ( 'w_NoteBook_TkProperties', -wraplength=>90, -label=>'Tk-related properties', -state=>'normal', -justify=>'left' );
my $w_Listbox_TkProp = $w_NoteBook_TkProperties -> Scrolled ( 'Listbox', -selectmode=>'single', -relief=>'sunken', -scrollbars=>'osoe' ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'y', -side=>'left', -padx=>5);
my $w_Frame_TkProp = $w_NoteBook_TkProperties -> Frame ( -relief=>'flat' ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'both', -side=>'left', -expand=>1, -padx=>5);
my $w_LabEntry_PropName = $w_Frame_TkProp -> LabEntry ( -label=>'Property:', -labelPack=>[-side=>'left',-anchor=>'n'], -state=>'normal', -justify=>'left', -relief=>'sunken', -textvariable=>\$prop_name ) -> pack(-anchor=>'nw', -fill=>'x', -padx=>5);
my $w_BrowseEntry_PropValue = $w_Frame_TkProp -> BrowseEntry ( -label=>'Value:', -labelPack=>[-side=>'left',-anchor=>'n'], -state=>'normal', -justify=>'left', -relief=>'sunken', -variable=>\$prop_value ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'x', -padx=>5);
my $w_Lbl_descr = $w_Frame_TkProp -> Label ( -anchor=>'nw', -pady=>5, -justify=>'left', -text=>'Description:', -relief=>'flat' ) -> pack(-anchor=>'nw', -fill=>'x', -padx=>5);
my $w_Text_PropHelp = $w_Frame_TkProp -> Scrolled ( 'Text', -width=>36, -state=>'normal', -height=>10, -relief=>'sunken', -scrollbars=>'osoe', -wrap=>'none' ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'both', -padx=>5);
my $w_Frame_PropButtons = $w_Frame_TkProp -> Frame ( -relief=>'flat' ) -> pack(-anchor=>'nw', -pady=>10, -fill=>'x');
my $w_Button_PrAdd = $w_Frame_PropButtons -> Button ( -command=>\&add_property, -state=>'normal', -relief=>'raised', -compound=>'none', -text=>'Add' ) -> pack(-anchor=>'nw', -fill=>'x', -side=>'left', -expand=>1);
my $w_Button_PrChange = $w_Frame_PropButtons -> Button ( -command=>\&update_property, -state=>'normal', -relief=>'raised', -compound=>'none', -text=>'Change' ) -> pack(-anchor=>'nw', -fill=>'x', -side=>'left', -expand=>1);
my $w_Button_PrDel = $w_Frame_PropButtons -> Button ( -command=>\&del_property, -state=>'normal', -relief=>'raised', -compound=>'none', -text=>'Delete' ) -> pack(-anchor=>'nw', -fill=>'x', -side=>'left', -expand=>1);
my $w_NoteBook_ResultCode = $w_NoteBook_main -> add ( 'w_NoteBook_ResultCode', -label=>'Result Code', -state=>'normal', -justify=>'left' );
my $w_Button_ReGenerate = $w_NoteBook_ResultCode -> Button ( -command=>\&regenerate_code, -state=>'normal', -relief=>'raised', -compound=>'none', -text=>'Re-generate code' ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'x', -padx=>5);
my $w_Text_GeneratedCode = $w_NoteBook_ResultCode -> Scrolled ( 'Text', -width=>30, -state=>'normal', -height=>10, -relief=>'sunken', -scrollbars=>'osoe', -wrap=>'none' ) -> pack(-anchor=>'nw', -pady=>5, -fill=>'both', -expand=>1, -padx=>5);

$w_Listbox_Classes->bind('<Button-1>',\&path_sel);
$w_Listbox_TkProp->bind('<<ListboxSelect>>',\&prop_sel);
#===vptk user code before main===< THE CODE BELOW WILL RUN BEFORE GUI STARTED >===

my @tabs = $w_NoteBook_main->pages();
my %cnf_dlg_balloon = &ReadCnfDlgBalloon("$VPTK_Path/toolbar/balloon_cnf_dlg.txt");
my @Tk_Paths = sort(grep(/Tk.*\.pm$/,values %INC));
my @Tk_Classes;
map (s/\w+\.pm$//,@Tk_Paths);
my $curr=-1;
foreach my $p(sort @Tk_Paths)
{
  if ($p ne $curr) 
  {
    opendir(T,$p);
    push(@Tk_Classes,map("$p$_",grep(/\.pm$/,readdir(T))));
    closedir T;
  }
  $curr = $p;
}
map(
  $w_BrowseEntry_PropValue->insert("end",$_),
  qw/color int+ float relief justify variable anchor text side menu(0|1) callback bitmap/);
opendir(D,"$VPTK_Path/vptk_w/VPTK_Widget");
foreach my $f(grep(/\.pm/,readdir(D)))
{
  @Tk_Classes = grep(!/\W$f$/i,@Tk_Classes);
}
closedir(D);
$w_Listbox_Classes -> insert('end'=> @Tk_Classes );

my $i=0;
foreach my $name(sort keys %pic)
{
  $w_Menu_pic->command(-image=>$pic{$name},-columnbreak=>($i%7)?0:1,-command=>
    sub{$changes=1;$sel_pic=$name;$w_Label_icon->configure(-image=>$pic{$name});});
  $i++;
}

$default_parameters = "";

my $db=$mw->Dialog(-title=>"Warning!",-text=>"The class definition procedure is for experienced users only! Are you sure you want to continue?",-buttons=>["Yes","No"]);
my $reply=$db->Show();
exit if $reply eq "No";
MainLoop;

#===vptk end===< DO NOT CODE ABOVE THIS LINE >===
sub path_sel
{
  $class_path = $w_Listbox_Classes->get('anchor');
  ($class_name) = $class_path =~ m#[\\/]([^\\/]+)\.pm$#; #
  my $pod_path = $class_path; $pod_path =~ s/\.pm$//;
  $pod_path .= '.pod' if -e "$pod_path.pod";
  $pod_path .= '.pm' if -e "$pod_path.pm";
  $pod_path = "Tk::$class_name" unless -e $pod_path;

  $mw->Busy;
  open3(\*WTRFH, \*POD, \*PODERR, "perldoc -t $pod_path");
  my @POD=<POD>;
  push(@POD,<PODERR>);
  close WTRFH; close POD; close PODERR;
  $mw->Unbusy;

  $w_ROText_Help->delete('0.0','end');
  map($w_ROText_Help->insert('end',$_),@POD);
  my $switches = '';
  foreach (@POD)
  {
    chomp;
    s/[\r\n]//g;
    if(/STANDARD OPTIONS|SYNOPSIS/ .. /WIDGET-SPECIFIC OPTIONS|DESCRIPTION/)
    {
      $switches .= $_ if / -\w/;
      $switches =~ s/-$//;
    }
    elsif(/Switch: (-\w+)/)
    {
      $switches .= " $1";
    }
    elsif(/(-\w+) => /)
    {
      $switches .= " $1";
    }
  }
  %switches = ();
  foreach my $sw( split(/\s+/,$switches) )
  {
    next unless $sw;
    next unless $sw=~/^-/;
    next if exists $switches{$sw};
    if($sw=~/color|background|foreground/)
    {
      $switches{$sw} = 'color';
    }
    elsif($sw=~/command|cmd/)
    {
      $switches{$sw} = 'callback';
    }
    elsif($sw=~/width|height|width|thickness|columns|rows|padx|pady|underline/)
    {
      $switches{$sw} = 'int+';
    }
    elsif($sw=~/justify/)
    {
      $switches{$sw} = 'justify';
    }
    elsif($sw=~/relief/)
    {
      $switches{$sw} = 'relief';
    }
    elsif($sw=~/var/)
    {
      $switches{$sw} = 'variable';
    }
    elsif($sw=~/anchor/)
    {
      $switches{$sw} = 'anchor';
    }
    elsif($sw=~/bitmap/)
    {
      $switches{$sw} = 'bitmap';
    }
    else
    {
      $switches{$sw} = 'text';
    }
    # complete missing help messages
    unless ( exists $cnf_dlg_balloon{$sw} )
    {
      my %default_baloon = (
        'callback' => "callback routine for $sw event",
        'bitmap'   => "bitmap related to $sw",
        'variable' => "variable pointer associated with $sw",
        'int+'     => "positive integer measuring the value of $sw",
        'color'    => "the color to be used for $sw"
      );
      if(exists $default_baloon{$switches{$sw}})
      {
        $cnf_dlg_balloon{$sw} = " $sw => $switches{$sw}\n$default_baloon{$switches{$sw}}";
      }
    }
    
  }
  # clean listbox
  $w_Listbox_TkProp->delete(0,'end');
  # put values into listbox
  map($w_Listbox_TkProp->insert('end'=>"$_ $switches{$_}"),sort keys %switches);
  $changes=1;
}

sub switch_tab
{
  my ($d) = @_;
  my $i = 0;
  foreach (@tabs)
  {
    last if $_ eq $w_NoteBook_main->raised();
    $i++;
  }
  $i += $d;
  $i = 0 unless $tabs[$i];
  $i += $d if $tabs[$i] eq 'w_NoteBookFrame_help';
  # activate tab named $tabs[$i];
  $w_NoteBook_main -> raise($tabs[$i]); 
}


sub next_tab
{
  switch_tab(1);
}

sub prev_tab
{
  switch_tab(-1);
}

sub WriteCnfDlgBalloon
{
  my ($fPath,$pCnf) = (@_);

  open(F,">$fPath") or return;
  foreach my $opt(sort keys %$pCnf)
  {
    if($pCnf->{$opt} !~ /^\s+$opt/)
    {
      $pCnf->{$opt} = " $opt => value\n$pCnf->{$opt}";
    }
    print F "$pCnf->{$opt}\n\n";
  }
  close F;
}

sub ReadCnfDlgBalloon
{
  my ($file_name) = @_;
  return unless open(BF,$file_name);
  my $key='';
  my %cnf_dlg_balloon = ();
  while(<BF>)
  {
    my $descr='';
    chomp;
    next if /^\s*$/;
    if(/^\s*-/)
    {
      ($key,$descr) = (/^\s*(-\S+)\s*=>\s*(\S.*)/);
    }
    next unless $key;
    if (defined $cnf_dlg_balloon{$key})
    {
      $cnf_dlg_balloon{$key}.="\n$_";
    }
    else
    {
      $cnf_dlg_balloon{$key}=" $key => $descr";
    }
  }
  close BF;
  return (%cnf_dlg_balloon);
}

sub on_ok
{
  # check, do we have any changes?
  if($changes)
  {
    # activate tab with generated text if any changes
    $w_NoteBook_main -> raise('w_NoteBook_ResultCode'); 
    return;
  }
  open(F,">$VPTK_Path/vptk_w/VPTK_Widget/$class_name.pm");
  print F $w_Text_GeneratedCode->get('0.0','end');
  close F;
  &WriteCnfDlgBalloon("$VPTK_Path/toolbar/balloon_cnf_dlg.txt",\%cnf_dlg_balloon);
  $mw->Dialog(-title=>"Class $class_name generated",-text=>"The result will be visible at next VPTK_W run")->Show(); 
  exit;
}

sub regenerate_code
{
  @code=();
  $have_geometry = $have_geometry?'1':'0';
  unless($class_name)
  {
    $mw->Dialog(-title=>"Error",-text=>"No class selected!")->Show();
    $w_NoteBook_main -> raise('w_NoteBook_WidgetClass'); 
    return;
  }
  push(@code,
"# This is automatically generated code, but you are welcome to modify it",
"# The class defined below describes how to handle widgets of type Tk::$class_name by vptk_w.pl",
"# Original Tk code of this class could be found here:",
"# $class_path",
"package vptk_w::VPTK_Widget::$class_name;",
"",
"use strict;",
"use base qw(vptk_w::VPTK_Widget);",
"",
"sub HaveGeometry  { $have_geometry }",
"sub DefaultParams { [ $default_parameters ] }",
"sub TkClassName   { 'Tk::${class_name}' }",
"sub PrintTitle    { '${class_name}' }",
"sub AssociatedIcon{ '$sel_pic' }",
"sub EditorProperties {",
"  return {",
map("$_=> '$switches{$_}',",sort keys %switches),
($scrollable?"-scrollbars=>'scrolled'":""),
"  }",
"}",
"",
"sub JustDraw {",
"  my (\$this,\$parent,\%args) = \@_;",
"  return \$parent->${class_name}(\%args);",
"}",
"",
"1;#)"

);
  $w_Text_GeneratedCode->delete('0.0','end');
  map(
  $w_Text_GeneratedCode->insert('end',"$_\n"),@code);
  $changes=0;
}

sub prop_sel
{
  # update fields according to selected property
  my $prop = $w_Listbox_TkProp->get('anchor');
  if($prop)
  {
    ($prop_name,$prop_value) = $prop =~ /^(\S+) (.*)/;
    $w_Text_PropHelp->delete('0.0','end');
    $w_Text_PropHelp->insert('end',$cnf_dlg_balloon{$prop_name})
      if exists $cnf_dlg_balloon{$prop_name};
  }
}

sub add_property
{
  # check, does this property exist
  return unless $prop_name =~ /^-\w+/;
  return if exists $switches{$prop_name};
  # insert it if not exist
  $switches{$prop_name} = $prop_value;
  # update list of properties
  $w_Listbox_TkProp->insert('end'=>"$prop_name $switches{$prop_name}");
  # store new description value
  $cnf_dlg_balloon{$prop_name} = $w_Text_PropHelp->get('0.0','end');

  $changes=1;
}

sub del_property
{
  # check, does this property exist
  return unless $prop_name =~ /^-\w+/;
  return unless exists $switches{$prop_name};
  # delete if exist
  delete $switches{$prop_name};
  # clean listbox
  $w_Listbox_TkProp->delete(0,'end');
  # put values into listbox
  map($w_Listbox_TkProp->insert('end'=>"$_ $switches{$_}"),sort keys %switches);
  $changes=1;
}

sub update_property
{
  # if property exist
  return unless $prop_name =~ /^-\w+/;
  return unless exists $switches{$prop_name};
  # update switches
  $switches{$prop_name} = $prop_value;
  # update listbox
  # clean listbox
  $w_Listbox_TkProp->delete(0,'end');
  # put values into listbox
  map($w_Listbox_TkProp->insert('end'=>"$_ $switches{$_}"),sort keys %switches);
  # store new description value
  $cnf_dlg_balloon{$prop_name} = $w_Text_PropHelp->get('0.0','end');
  $changes=1;
}

=head1 NAME

 wizard_vptk_w.pl - wizard for new VPTK widget class definition

=head1 DESCRIPTION

 This is an example of Perl/Tk application that was developed
 entirely by vptk_w.pl

 The goal of this apllication is to add support for new widget class
 to vptk_w.pl itself. Just select desired Perl/Tk module and change
 it's options (when needed).

=cut
