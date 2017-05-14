package ZooZ::Generic;

# this defines some generic functions that can be used by anyone.

use strict;

sub BindMouseWheel {
  my ($top, $w) = @_;

  if ($^O eq 'MSWin32') {
    # not tested!!!
    $top->bind('<MouseWheel>' =>
	       [ sub {
		   my $w2 = ref $w eq 'CODE' ? $w->() : $w;
		   $w2->yview('scroll', -($_[1] / 120) * 3, 'units') },
		 Tk::Ev('D') ]
	      );
  } else {
    $top->bind('<4>' => sub {
		 my $w2 = ref $w eq 'CODE' ? $w->() : $w;
		 $w2->yview('scroll', -3, 'units') unless $Tk::strictMotif;
	       });

    $top->bind('<5>' => sub {
		 my $w2 = ref $w eq 'CODE' ? $w->() : $w;
		 $w2->yview('scroll', +3, 'units') unless $Tk::strictMotif;
	       });
  }
}


########
#
# This method pops up a message for the user.
# The message is contained in a frame that drops down from the middle
# of the top border of the given window, stays there for a few secs, then
# goes back up .. animated .. sort of like the auto-hidden taskbar.
#
########

my @msgFrames;
my @msgLabels;
my (@msgX, @msgY, @stopY);

sub popMessage {
  my %hash     = @_;

  my $over     = delete $hash{-over}  or return undef;
  my $msg      = delete $hash{-msg}   or return undef;
  my $msgDelay = delete $hash{-delay} || 3000;  # 3 secs

  # find first id.
  my $id = 0;
  $id++ while defined $msgX[$id];

  unless ($msgFrames[$id]) {
    my $top = $over->toplevel;

    my $msgFrame = $top->Frame(qw/-bd 1 -relief solid/);
    my $msgLabel = $msgFrame->Label(qw/-padx 20 -pady 20/,
				    %hash,
				   )->pack(qw/-fill both/);

    $msgFrames[$id] = $msgFrame;
    $msgLabels[$id] = $msgLabel;
  }

  $msgLabels[$id]->configure(%hash, -text => $msg);
  $msgFrames[$id]->idletasks;
  $msgFrames[$id]->raise;

  _animateMsgDown($over, $id, $msgDelay);
}

sub _animateMsgDown {
  my ($top, $id, $msgDelay) = @_;

  unless (defined $msgX[$id]) {
    $msgY [$id] = $msgFrames[$id]->reqheight * ($id-1);
    $msgX [$id] = int 0.5 * ($top->width - $msgFrames[$id]->reqwidth);
    $stopY[$id] = $msgY[$id] + $msgFrames[$id]->reqheight;
  } else {
    $msgY[$id]++;
  }

  $msgFrames[$id]->place(-x => $msgX[$id],
			 -y => $msgY[$id]);

  if ($msgY[$id] == $stopY[$id]) {
    $top->after($msgDelay => [\&_animateMsgUp, $top, $id]);
    return;
  }

  $top->after(5 => [\&_animateMsgDown, $top, $id, $msgDelay]);
}

sub _animateMsgUp {
  my ($top, $id) = @_;

  $msgY[$id]--;

  $msgFrames[$id]->place(-x => $msgX[$id],
			 -y => $msgY[$id]);

  if ($msgY[$id] == -$msgFrames[$id]->height) {
    $msgX[$id] = $msgY[$id] = undef;
    $msgFrames[$id]->placeForget;

    return;
  }

  $top->after(5 => [\&_animateMsgUp, $top, $id]);
}

#my $msgFrame;
#my $msgLabel;
#my ($msgX, $msgY, $msgDelay);
#my $msgMoving = 0;

#sub popMessage {
#  return if $msgMoving;

#  my ($over, $msg) = @_;

#  $msgDelay = $_[2] || 3000;  # 3 secs

#  unless ($msgFrame) {
#    $msgFrame = $::MW->Frame(qw/-bd 1 -relief solid/);
#    $msgLabel = $msgFrame->Label(qw/-padx 20 -pady 20/,
#				 -bg   => 'white',
#				 -font => 'Level',
#				)->pack(qw/-fill both/);
#  }

#  $msgLabel->configure(-text => $msg);
#  $msgFrame->update;
#  $msgFrame->raise;

#  $msgMoving = 1;

#  animateMsgDown($over);
#}

#sub animateMsgDown {
#  my $top = shift;

#  unless (defined $msgX) {
#    $msgY = -$msgFrame->reqheight;
#    $msgX = int 0.5 * ($top->width - $msgFrame->reqwidth);
#  } else {
#    $msgY++;
#  }

#  $msgFrame->place(-x => $msgX,
#		   -y => $msgY);

#  if ($msgY == 0) {
#    $top->after($msgDelay => [\&animateMsgUp, $top]);
#    return;
#  }

#  $top->after(5 => [\&animateMsgDown, $top]);
#}

#sub animateMsgUp {
#  my $top = shift;

#  $msgY--;

#  $msgFrame->place(-x => $msgX,
#		   -y => $msgY);

#  if ($msgY == -$msgFrame->height) {
#    $msgX = $msgY = undef;
#    $msgFrame->placeForget;
#    $msgMoving = 0;

#    return;
#  }

#  $top->after(5 => [\&animateMsgUp, $top]);
#}

##########################
#
# This method is used to animate the opening/closing
# of the different hierarchy views.
#
##########################

my $fadeFrame;
my $stepSize = 10;

sub animateOpen_old {
  my ($top, $fx, $fy, $fw, $fh) = @_;

  return unless $top->viewable;

  unless ($fadeFrame) {
    $fadeFrame = $top->Frame(qw/-bg white -relief solid -bd 1/);
    print "Fade Frame is $fadeFrame.\n";
  }

  my $tw = $top->reqwidth;
  my $th = $top->reqheight;
  my $w  = my $h = 0;
  my $x  = $fx;
  my $y  = $fy;

  #$fadeFrame->raise;

  while ($w < $tw || $h < $th) {
    $fadeFrame->place(-x      => $x,
		      -y      => $y,
		      -width  => $w,
		      -height => $h);

    $_ += $stepSize     for $w, $h;
    $_ -= $stepSize / 2 for $x, $y;

    $fadeFrame->raise;
    $fadeFrame->update;
    $top->after(1);
  }

  $fadeFrame->placeForget;
}

sub animateClose_old {
  my ($top, $x, $y) = @_;

  unless ($fadeFrame) {
    $fadeFrame = $top->Frame(qw/-bg white/);
  }
}

my $steps = 10;

sub animateOpen {
  print "Got >>@_<<\n";
  my ($c, $id) = @_;

  my ($midX, $midY) = ($c->width / 2, $c->height / 2);

  $id = 'ANIMATE';

  unless ($c->find(withtag => $id)) {
    $c->createWindow($midX, $midY,
		     -window => $c->Frame,
		     -width  => 0,
		     -height => 0,
		     -tags   => ['ANIMATE'],
		    );
  }

  $c->itemconfigure($id, -width => 10, -height => 10);

  my @oldC = $c->coords($id);

  my $dx = ($midX - $oldC[0]) / $steps;
  my $dy = ($midY - $oldC[1]) / $steps;

  my @cur = @oldC;

  $c->itemconfigure($id, -state => 'normal');

#  for my $i (1 .. $steps) {
#    $cur[0] += $dx;
#    $cur[1] += $dy;
#    $c->coords($id, @cur);
#    $c->update;
#    $c->after(10);
#  }

  my @box = $c->bbox($id);
  my $w = $box[2] - $box[0];
  my $h = $box[3] - $box[1];

  $dx = ($c->width  - $w) / $steps;
  $dy = ($c->height - $h) / $steps;

  for my $i (1 .. $steps) {
    $w += $dx;
    $h += $dy;
    $c->itemconfigure($id, -width => $w, -height => $h);

    $c->update;
    $c->after(80);
  }

  #$c->coords($id, @oldC);
  #$c->itemconfigure($id, -width => 0, -height => 0);
  $c->itemconfigure($id, -state => 'hidden');
}

sub lineUpCommas {
  my $len = (sort {$b <=> $a} map length $_->[0] => @_)[0];
  return join "\n" => map {sprintf "   %-$ {len}s => %s," => @$_} @_;
}

'the truth';
