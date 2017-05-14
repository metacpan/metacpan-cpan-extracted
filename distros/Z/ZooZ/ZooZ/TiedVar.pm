
package ZooZ::TiedVar;

use strict;

# The purpose of this is to automatically apply
# any changes to widget options as soon as those
# changes are made.

1;

sub TIESCALAR {
  my ($class, $w, $d, $m, $o, $l, $p) = @_;

  $p ||= [];

  return bless {
		W => $w,  # the widget
		V => $d,  # default value
		M => $m,  # method to use.
		O => $o,  # the option name
		L => $l,  # the label.
		P => $p,  # pre-options
		C => 0,   # whether it changed or not.
	       } => $class;
}

sub FETCH { $_[0]{V} }

sub STORE {
  my ($self, $v) = @_;

  $self->{V} = $v;
  $self->{C} = 1;

  # don't apply it if it's undefined.
  defined $v or return;

  # try to apply it.
  my $m = $self->{M};

  #print "Evaling $m on $self->{W} with @{$self->{P}} and $self->{O} => $v.\n";
  eval {
    $self->{W}->$m(@{$self->{P}}, $self->{O} => $v);
  };

  if ($@) {
    $self->{L}->configure(-fg => 'red')   if $self->{L};
  } else {
    $self->{L}->configure(-fg => 'black') if $self->{L};
  }
}

sub changed { $_[0]{C} }
