package Tk::Zinc::Text;

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);


sub new {
  my $proto = shift;
  my $type = ref($proto) || $proto;
  my ($zinc) = @_;
  my $self = {};

  $zinc->bind('text', '<1>' => sub {startSel($zinc)});
  $zinc->bind('text', '<2>' => sub {pasteSel($zinc)});
  $zinc->bind('text', '<B1-Motion>' => sub {extendSel($zinc)});
  $zinc->bind('text', '<Shift-B1-Motion>' => sub {extendSel($zinc)});
  $zinc->bind('text', '<Shift-1>' => sub {
		my $e = $zinc->XEvent();
		my($x, $y) = ($e->x, $e->y);
		$zinc->select('adjust', 'current', "\@$x,$y"); });
  $zinc->bind('text', '<Left>' => sub {moveCur($zinc, -1);});
  $zinc->bind('text', '<Right>' => sub {moveCur($zinc, 1);});
  $zinc->bind('text', '<Up>' => sub {setCur($zinc, 'up');});
  $zinc->bind('text', '<Down>' => sub {setCur($zinc, 'down');});
  $zinc->bind('text', '<Control-a>' => sub {setCur($zinc, 'bol');});
  $zinc->bind('text', '<Home>' => sub {setCur($zinc, 'bol');});
  $zinc->bind('text', '<Control-e>' => sub {setCur($zinc, 'eol');});
  $zinc->bind('text', '<End>' => sub {setCur($zinc, 'eol');});
  $zinc->bind('text', '<Meta-less>' => sub {setCur($zinc, 0);});
  $zinc->bind('text', '<Meta-greater>' => sub {setCur($zinc, 'end');});
  $zinc->bind('text', '<KeyPress>' => sub {insertKey($zinc);});
  $zinc->bind('text', '<Shift-KeyPress>' => sub {insertKey($zinc);});
  $zinc->bind('text', '<Return>' => sub { insertChar($zinc, chr(10)); });
  $zinc->bind('text', '<BackSpace>' => sub {textDel($zinc, -1)});
  $zinc->bind('text', '<Control-h>' => sub {textDel($zinc, -1)});
  $zinc->bind('text', '<Delete>' => sub {textDel($zinc, 0)});

  bless ($self, $type);
  return $self;
}


sub pasteSel {
  my ($w) = @_;
  my $e = $w->XEvent;
  my($x, $y) = ($e->x(), $e->y());
  my @it = $w->focus();

  if (@it != 0) {
    eval { $w->insert(@it, "\@$x,$y", $w->SelectionGet()); };
  }
}


sub insertChar {
  my ($w, $c) = @_;
  my @it = $w->focus();
  my @selit = $w->select('item');

  if (@it == 0) {
    return;
  }

  if ((scalar(@selit) == scalar(@it)) &&
      ($selit[0] eq $it[0]) && ($selit[1] eq $it[1])) {
    $w->dchars(@it, 'sel.first', 'sel.last');
  }
  $w->insert(@it, 'insert', $c);
}


sub insertKey {
  my ($w) = @_;
  my $c = $w->XEvent->A();

  if ((ord($c) < 32) || (ord($c) == 128)) {
    return;
  }

  insertChar($w, $c);
}


sub setCur {
  my ($w, $where) = @_;
  my @it = $w->focus();

  if (@it != 0) {
    $w->cursor(@it, $where);
  }
}


sub moveCur {
  my ($w, $dir) = @_;
  my @it = $w->focus();
  my $index;

  if (@it != 0) {
    $index = $w->index(@it, 'insert');
    $w->cursor(@it, $index + $dir);
  }
}


sub startSel {
  my($w) = @_;
  my $e = $w->XEvent;
  my($x, $y) = ($e->x(), $e->y());
  my $part = $w->currentpart(1);

  $w->cursor('current', $part, "\@$x,$y");
  $w->focus('current', $part);
  $w->Tk::focus();
  $w->select('from', 'current', $part, "\@$x,$y");
}


sub extendSel {
  my($w) = @_;
  my $e = $w->XEvent;
  my($x, $y) = ($e->x, $e->y);
  my $part = $w->currentpart(1);

  $w->select('to', 'current', $part, "\@$x,$y");
}


sub textDel {
  my($w, $dir) = @_;
  my @it = $w->focus();
  my @selit = $w->select('item');
  my $ind;

  if (@it == 0) {
    return;
  }

  if ((scalar(@selit) == scalar(@it)) &&
      ($selit[0] eq $it[0]) && ($selit[1] eq $it[1])) {
    $w->dchars(@it, 'sel.first', 'sel.last');
  }
  else {
    $ind = $w->index(@it, 'insert') + $dir;
    $w->dchars(@it, $ind, $ind) if ($ind >= 0);
  }
}

1;
__END__

=head1 NAME

Tk::Zinc::Text - Zinc extension for easing text input on text item or on fields

=head1 SYNOPSIS

 use Tk::Zinc::Text;

 $zinc = $mw->Zinc();
 new Tk::Zinc::Text ($zinc);
 ....
 $zinc->addtag('text', 'withtag', $a_text);
 $zinc->addtag('text', 'withtag', $a_track);
 $zinc->addtag('text', 'withtag', $a_waypoint);
 $zinc->addtag('text', 'withtag', $a_tabular);

=head1 DESCRIPTION

This module implements text input with the mouse and keyboard 'a la emacs'.
Text items must have the 'text' tag and must of course be sensitive.
Track, waypoint and tabular items have fields and these fields can
be edited the same way. Only sensitive fields can be edited. the following
interactions are supported:

=over 2

=item B<click 1>

To set the cursor position

=item B<click 2>

To paste the current selection

=item B<drag 1>

To make a selection

=item B<shift drag 1>

To extend the current selection

=item B<shift 1>

To extend the current selection

=item B<left arrow>, B<right arrow>

To move the cursor to the left or to the right

=item B<up arrow>, B<down arrow>

To move the cursor up or down a line

=item B<ctrl+a>, B<home>

To move the cursor at the begining of the line

=item B<ctrl+e>, B<end>

To move the cursor at the end of the line

=item B<meta+<>, B<meta+E<gt>>

To move the cursor at the beginning / end of the text

=item B<BackSpace>, B<ctrl+h>

To delete the char just before the cursor

=item B<Delete>

To delete the char just after the cursor

=item B<Return>

To insert a return char. This does not validate the input!

=back

=head1 BUGS

No known bugs at this time. If you find one, please report them to the authors.

=head1 SEE ALSO

perl(1), Tk(1), Tk::Zinc(3), zinc-demos(1)

=head1 AUTHORS

Patrick Lecoanet <lecoanet@cena.fr>
(and some documentation by Christophe Mertz <mertz@cena.fr>)

=head1 COPYRIGHT

CENA (C) 2002

Tk::Zinc::Text is part of Zinc and has been developed by the CENA (Centres d'Etudes de la Navigation Aérienne)
for its own needs in advanced HMI (Human Machine Interfaces or Interactions). Because we are confident
in the benefit of free software, the CENA delivered this toolkit under the GNU
Library General Public License.

This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
the implied warranty of MER­CHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Library
General Public License for more details.

=head1 HISTORY

June 2002 : initial release with Zinc-perl 3.2.6

=cut
