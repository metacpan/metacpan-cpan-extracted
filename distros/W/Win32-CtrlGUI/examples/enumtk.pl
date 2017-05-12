use Tk;
use Tk::HList;
use Win32::CtrlGUI;

my $mw = MainWindow->new;
my $wintest = Wintest->new($mw);
MainLoop;




package Wintest;

use strict;

sub new {
  my $class = shift;
  my($mw, $parent) = @_;

  my $self = {
    mw => $mw,
    parent => $parent,
  };

  bless $self, $class;
  $self->_init;
  $self->_refresh;
}

sub _init {
  my $self = shift;

  $self->{mw}->Busy;
  $self->{mw}->update;

  $self->{title} = "$self->{parent}" || "All Windows";
  $self->{mw}->title("Tk Window Enumerator: $self->{title}");
  $self->{label} = $self->{mw}->Label(-text => $self->{title}, -anchor => 'w')->pack(-side => 'top');
  $self->{hlist} = $self->{mw}->Scrolled('HList', -scrollbars => 'se', -separator => '|', -font => 'Arial 8',
                   -command => sub {Wintest->new($self->{mw}->Toplevel, $self->{hlist}->info('data', $_[0]))})->pack(
                   -side => 'top', -expand => 1, -fill => 'both');
  $self->{refresh} = $self->{mw}->Button(-text => 'Refresh', -command => sub {$self->_refresh})->pack(-side => 'left');
  $self->{printatom} = $self->{mw}->Button(-text => 'Print Atom', -command => sub {
    if ($self->{parent}) {
      my $parent = &_clean_text($self->{parent});
      my $child = &_clean_text($self->{hlist}->info('data', $self->{hlist}->info('selection')));
      print "\natom => [criteria => [pos => \"$parent\", \"$child\"],\n         action => ''],\n\n";
    } else {
      my $parent = &_clean_text($self->{hlist}->info('data', $self->{hlist}->info('selection')));
      print "\natom => [criteria => [pos => \"$parent\"],\n         action => ''],\n\n";
    }
  })->pack(-side => 'left');
  $self->{mw}->update;
  $self->{mw}->focusForce;
  $self->{mw}->update;
  $self->{mw}->Unbusy;
}

sub _refresh {
  my $self = shift;

  $self->{mw}->Busy;
  $self->{mw}->update;

  $self->{hlist}->delete('all');

  my(@list);
  if ($self->{parent}) {
    @list = $self->{parent}->enum_child_windows;
  } else {
    @list = Win32::CtrlGUI::enum_windows();
  }
  @list = map {$_->[0]} sort {lc($a->[1]) cmp lc($b->[1]) || $a->[1] cmp $b->[1]} grep {$_->[1]} map {[$_, "$_"]} @list;

  my $i = 1;
  foreach my $window (@list) {
    $self->{hlist}->add($i++, -itemtype => 'text', -text => "$window", -data => $window);
  }

  $self->{mw}->Unbusy;
}

sub new_win {
  my $self = shift;
  my($parent) = @_;

  my $new_mw = $self->{mw}->Toplevel;
}

sub _clean_text {
  my($string) = @_;

  $string =~ s/([&\$"\@\\])/\\$1/g;
  $string =~ s/\t/\\t/g;
  $string =~ s/\n/\\n/g;
  return $string;
}
