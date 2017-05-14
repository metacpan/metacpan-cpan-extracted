=head1 NAME

 vptk_w::EditorServices -- vptk_w generic GUI services

=cut

package vptk_w::EditorServices;
use Tk;
use Exporter 'import';
@EXPORT = qw(NumEntry CodePreview Coloring SetMainPalette GetMainPalette
ShowDialog ShowStatusMessage ShowAboutMessage ShowHelp %pic);

use strict;

my %pic;

my $mwPalette='';
my %palette=(-background=>'gray90',-foreground=>'black');
my $mw=''; # copied from Main module during SetMainPalette

##################### Re-coloring section ######################
sub SetMainPalette
{
  $mw = shift;
  die "$0 - vptk_w::ExtraWidgets - SetMainPalette - ERROR: <$mw> is wrong type or missing\n"
    unless ref $mw;
  my ($bg_color,$fg_color) = @_;
  $mwPalette = $mw->Palette;

  my %new = (background=>$bg_color,foreground=>$fg_color);
  # function available for Perl 5.08 - not available for 5.10 !!!
  if($] <= 5.008008)
  {
    $mw->RecolorTree(\%new);
  }
  # Save the options in the global variable Tk::Palette, for use the
  # next time we change the options.
  foreach my $option (keys %new) 
  { 
    $mwPalette->{$option} = $new{$option};
    $palette{"-$option"} = $new{$option};
  }
  &Coloring($mw);
}

sub GetMainPalette
{
  die "$0 - vptk_w::ExtraWidgets - GetMainPalette - ERROR: <$mw> is wrong type or missing\n"
    unless ref $mw;
  $mwPalette = $mw->Palette;
  $mwPalette->{'background'} = 'gray90' unless $mwPalette->{'background'};
  $mwPalette->{'foreground'} = 'black'  unless $mwPalette->{'foreground'};
  return ($mwPalette->{'background'},$mwPalette->{'foreground'});
}

# this is a recolor trick borrowed from Perl/Tk hacking archive:
sub Coloring
{
  my ($widget)=@_;
  die "$0 FATAL ERROR - empty palette!\n"
    unless length (%palette);
  eval '$widget->configure(%palette)';
  foreach my $child ($widget->children) 
  {
    &Coloring($child);
  }
}

########################### NumEntry emulation #####################
# This code is partially copied from original NumEntry
# Reason: the original widget does not support -textvariable (sic!)
# Problems: No strict syntax control, No FireButton functionality
my $def_bitmaps = 0;

sub NumEntry
{
  my ($parent,%par)=@_;
  my $numentry;
  my $minvalue=delete $par{'-minvalue'};
  my $maxvalue=delete $par{'-maxvalue'};
  unless($def_bitmaps) 
  {
    my $bits = pack("b8"x5,
      "........",
      "...11...",
      "..1111..",
      ".111111.",
      "........"
    );

    $parent->DefineBitmap('INCBITMAP' => 8,5, $bits);

    # And of course, decrement is the reverse of increment :-)
    $parent->DefineBitmap('DECBITMAP' => 8,5, scalar reverse $bits);
    $def_bitmaps=1;
  }
  my $result=$parent->Frame();
  $numentry=$result->Entry(%par)->pack(-anchor=>'w', -side=>'left');
  $numentry->bind('<Up>',
    [\&inc_num_controlled,$par{'-textvariable'},1,$minvalue,$maxvalue]);
  $numentry->bind('<Down>',
    [\&inc_num_controlled,$par{'-textvariable'},-1,$minvalue,$maxvalue]);
  $result->Button(-bitmap=>'INCBITMAP',-cursor=>'left_ptr',-command=>
    [\&inc_num_controlled,$par{'-textvariable'},1,$minvalue,$maxvalue])
    ->pack(-anchor=>'nw', -side=>'top');
  $result->Button(-bitmap=>'DECBITMAP',-cursor=>'left_ptr',-command=>
    [\&inc_num_controlled,$par{'-textvariable'},-1,$minvalue,$maxvalue])
    ->pack(-anchor=>'nw', -side=>'top');
  return $result;
}

sub inc_num_controlled
{
  shift if ref($_[0]) ne 'SCALAR';
  my ($ptr,$inc,$minvalue,$maxvalue)=@_;

  my $value=$$ptr+$inc;
  $$ptr=$value;
  $$ptr=$minvalue if length $minvalue && $value<$minvalue;
  $$ptr=$maxvalue if length $maxvalue && $value>$maxvalue;
}

######################## Service windows section ################
sub ShowDialog
{
  my $d=$mw->Dialog(@_);
  &Coloring($d);
  return $d->Show;
}

sub ShowStatusMessage {
  
  my $d = $mw->DialogBox(-title=>'Status');
  my @text = (
    "Perl interpreter: $^X",
    "Perl version: $]",
    "Tk VERSION: $Tk::VERSION",
    "Tk version: $Tk::version",
    "Tk strictMotif: $Tk::strictMotif",
		"Tk patchLevel: $Tk::patchLevel",
		"Tk library: $Tk::library",
    "Tk paths:",
    sort(grep(/Tk.*\.pm$/,values %INC))
  );
  if(scalar(@text) > 20) {
    splice(@text,20);
    push(@text,'...');
  }
  $d->Label(-text=>join("\n",@text),-justify=>'left')->pack();
  $d->resizable(0,0);
  &Coloring($d);
  $d->Show();
}

sub ShowAboutMessage
{
  die "$0 - vptk_w::ExtraWidgets - ShowAboutMessage - ERROR: <$mw> is wrong type or missing\n"
    unless ref $mw;
  my ($ver) = @_;
  my $d = $mw->DialogBox(-title=>'About');
  $d->Label(-text=>"Visual Perl Tk (widget edition)\n$ver")->pack();
  $d->Label(-text=>"Copyright (c) 2002 Felix Liberman\n\n".
    "e-mail: FelixL\@Rambler.RU\n\n".
    "IDE: GVIM 6.0")->pack();
  $d->resizable(0,0);
  &Coloring($d);
  $d->Show();
}

sub ShowHelp
{
  die "$0 - vptk_w::ExtraWidgets - ShowHelp - ERROR: <$mw> is wrong type or missing\n"
    unless ref $mw;
  my (@html_help) = @_;
  my $hd=$mw->DialogBox(-title=>'Help');
  my $t=$hd->Scrolled(qw/ROText -scrollbars osoe -wrap word/)->pack(-fill=>'both',-expand=>1);
  $t->tag(qw/configure bold -font C_bold/);
  $t->insert('0.0',"");
  foreach (@html_help)
  {
    my ($type,$line)=(/(\S+)\s(.*)/);
    if($type eq 'bold')
    {
      $t->insert('end',"$line\n",'bold');
    }
    elsif($type eq 'gif')
    {
      $t->imageCreate('end',-image=>$::pic{$line});
      $t->insert('end',"\n");
    }
    else
    {
      $t->insert('end',"$line\n");
    }
  }
  $hd->resizable(1,0);
  &Coloring($hd);
  $hd->Show;
}

################## Preview for generated code ###################

sub CodePreview
{
  die "$0 - vptk_w::ExtraWidgets - CodePreview - ERROR: <$mw> is wrong type or missing\n"
    unless ref $mw;
  my (@code) = @_;
  my $failed_to_parse=0;

  my $db=$mw->DialogBox(-title => "Code preview",-buttons=>['Dismiss']);
  &Coloring($db,%palette);
  my $t = $db->Scrolled(qw/ROText -setgrid true -wrap none -scrollbars osoe
  -background white/);
  $t->pack(qw/-expand yes -fill both/);
  # GVIM5 color set for perl:
  $t->tag(qw/configure variable -foreground darkgreen/);
  $t->tag(qw/configure keyword -foreground brown -font C_bold/);
  $t->tag(qw/configure constant -foreground violet/);
  foreach my $line(@code)
  {
    my $line_len = length $line;
    last unless $line_len;
    if($line=~/^\s*my\s+/)
    {
      $t->insert('end','my ','keyword');
      $line=~s/^\s*my\s+//;
    }
    while(length($line))
    {
      if($line=~/^\s*\$\w+/)
      {
        my ($var)=($line=~/^(\s*\$\w+)/);
        $t->insert('end',$var,'variable');
        $line=~s/^\s*\$\w+//;
      }
      elsif($line=~/^\s*-\w+\s*=>\s*sub\s+\{[^}]+\}/)
      {
        my ($txt1,$txt2)=($line=~/^\s*-(\w+)\s*=>\s*sub\s+(\{[^}]+\})/);
        $t->insert('end',"-$txt1",'constant');
        $t->insert('end','=>');
        $t->insert('end','sub ','keyword');
        $t->insert('end',$txt2);
        $line=~s/\s*-(\w+)\s*=>sub\s+\{[^}]+\}//;
      }
      elsif($line=~/^\s*(-\w+|'[^']*')/)
      {
        my ($const)=($line=~/^(\s*(?:-\w+|'[^']*'))/);
        $t->insert('end',$const,'constant');
        $line=~s/^\s*(-\w+|'[^']*')//;
      }
      else
      {
        my ($txt)=($line=~/^(\s*(?:->)?[^-\$']+)/);
        $txt=~s/->\s*/->\n  /;
        $txt=~s/,\s*/,\n    /g;
        $t->insert('end',$txt);
        $line=~s/^\s*(->)?[^-\$']+//;
      }
      if($line_len == length $line)
      {
        $failed_to_parse = 1;
        last;
      }
      $line_len = length $line;
    }
    $t->insert('end', "\n");
    last if $failed_to_parse;
  }
  if($failed_to_parse)
  {
    $t->delete('0.0','end');
    map ( $t->insert('end',"$_\n"), @_ );
  }
  $t->mark(qw/set insert 0.0/);
  $db->resizable(1,0);
  $db->Show();
}

1;
