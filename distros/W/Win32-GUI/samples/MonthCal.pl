#! perl -w
#
#  MonthCal sample
#
use strict;
use warnings;
use Win32::GUI();

# main Window
my $Window = new Win32::GUI::Window (
    -name     => "Window",
    -title    => "MonthCal Sample",
    -pos      => [100, 100],
    -size     => [440, 400],
) or die "new Window";

# Mono select MonthCal control
$Window->AddMonthCal (
    -name     => "MonthCalMono",
    -pos      => [10, 10],
    -size     => [200, 160],
    -onSelect => \&OnSelect,
    -onSelChange => \&OnSelChange,
);

# Play with color
$Window->MonthCalMono->BackColor(0x7F7F7F);
$Window->MonthCalMono->BackMonthColor(0x7FFFFF);
$Window->MonthCalMono->BackTitleColor(0xFF7F7F);
$Window->MonthCalMono->TextColor(0x7F0000);
$Window->MonthCalMono->TitleTextColor(0x7FFF7F);
$Window->MonthCalMono->TrailingTextColor(0xA0A0A0);

# Multi Select MonthCal control
$Window->AddMonthCal (
    -name     => "MonthCalMulti",
    -pos      => [220, 10],
    -size     => [200, 160],
    -onSelect => \&OnSelectMulti,
    -onSelChange => \&OnSelChangeMulti,
    -onDayState  => \&OnDayState,
    -multiselect => 1,               # Allow multi select 
    -weeknumber => 1,                # Show Week number
    -notoday => 1,                   # Remove Today 
    -daystate => 1,
);

# Change default 7 days select to 14 days select
$Window->MonthCalMulti->SetMaxSelCount(14);

# Init first month daystate (day 15 is bold)
$Window->MonthCalMulti->SetDayState( (1<<(15-1)) );

# Event loop
$Window->Show();
Win32::GUI::Dialog();

# Main window event handler
sub Window_Terminate {
  return -1;
}

# Event handler

sub OnSelect {
  my ($self, $y, $m, $d) = @_;
  my $name = $self->{-name};
  print "$name Select = $d/$m/$y\n";
}

sub OnSelChange {
  my ($self, $y, $m, $d) = @_;
  my $name = $self->{-name};
  print "$name SelChange = $d/$m/$y\n";
}

sub OnSelectMulti {
  my ($self, $yf, $mf, $df, $yt, $mt, $dt) = @_;
  my $name = $self->{-name};
  print "$name Select from $df/$mf/$yf to $dt/$mt/$yt\n";
}

sub OnSelChangeMulti {
  my ($self, $yf, $mf, $df, $yt, $mt, $dt) = @_;
  my $name = $self->{-name};
  print "$name SelChange from $df/$mf/$yf to $dt/$mt/$yt\n";
}

# Change Day state in calendar
sub OnDayState {

  my ($self, $y, $m, $d, $max, $refarray) = @_;
  my $name = $self->{-name};

  print "$name DayState from $d/$m/$y for $max months\n";

  # $refarray is an array reference
  # Each item is an integer value where each bit represent a day.
  for my $i (0..$max-1) {
    $$refarray[$i] |= (1<<(15-1));  # Set day 15 bold for all day
  }
}

