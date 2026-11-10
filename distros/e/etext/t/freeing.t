#!/usr/bin/perl
# While the -valuecommand runs (the command that called it has not made
# its change yet), the commands that would modify the widget are
# refused; reading commands, and those that only change the view, keep
# working.  While the values a widget command dropped are being freed
# (a DESTROY method of a value runs), they work since 2.05 (2.04
# refused them too, a stopgap until -valuecommand, BUGS 17): each is a
# change of its own for the undo, the values it drops are freed in the
# same pass, and a chain of such changes stops 10 deep.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 132;
$mw->geometry('+10+10');

my $t = $mw->eText(-width => 30, -height => 6, -undo => 1)->pack;
$t->blockConfigure('F');
$t->insert('end', "abcdef\nghijkl\nmnop\n");
$t->blockInsert('F', '2.1', '2.4');
$t->tagAdd('b', '1.1', '1.3');
$t->markSet('m', '1.2');
$t->editReset;

my %result;			# command => error message, or 'ok'
{
  package V;
  sub new { my ($class, $hook) = @_; bless { hook => $hook }, $class }
  sub DESTROY { $_[0]{hook}->() if $_[0]{hook} }
}

my $path = $t->PathName;
my $refused = qr/^cannot modify \Q$path\E while its -valuecommand runs/;

# Commands that modify the widget: each is refused, and nothing changes.
my @modifying = (
  [insert => sub { $t->insert('1.0', 'X') }],
  [delete => sub { $t->delete('1.0') }],
  ['tag add' => sub { $t->tag('add', 'b', '3.0', '3.2') }],
  ['tag remove' => sub { $t->tag('remove', 'b', '1.1') }],
  ['tag delete' => sub { $t->tag('delete', 'b') }],
  ['tag configure (set)' => sub { $t->tag('configure', 'b', -underline => 1) }],
  ['tag raise' => sub { $t->tag('raise', 'b') }],
  ['tag lower' => sub { $t->tag('lower', 'b') }],
  ['tag bind (set)' => sub { $t->tag('bind', 'b', '<1>', sub {}) }],
  ['tag data (set)' => sub { $t->tag('data', 'b', '1.1', 'x') }],
  ['mark set' => sub { $t->mark('set', 'm2', '1.0') }],
  ['mark unset' => sub { $t->mark('unset', 'm') }],
  ['mark gravity (set)' => sub { $t->mark('gravity', 'm', 'left') }],
  ['mark data (set)' => sub { $t->mark('data', 'm', 'x') }],
  ['block insert' => sub { $t->block('insert', 'F', '3.0') }],
  ['block split' => sub { $t->block('split', '2.2', 0) }],
  ['block trim' => sub { $t->block('trim', '2.2') }],
  ['block nodedata (set)' => sub { $t->block('nodedata', '2.2', 0, 'x') }],
  ['block data (set)' => sub { $t->block('data', '2.2', 'x') }],
  ['block configure (query, new type)' => sub { $t->block('configure', 'G') }],
  ['block configure (set)' => sub { $t->block('configure', 'F', -empty => 0) }],
  ['tag configure (query, new tag)' => sub { $t->tag('configure', 'newt') }],
  ['tag bind (query, new tag)' => sub { $t->tag('bind', 'newt2') }],
  ['block delete' => sub { $t->block('delete', 'F') }],
  ['edit undo' => sub { $t->edit('undo') }],
  ['edit redo' => sub { $t->edit('redo') }],
  ['edit reset' => sub { $t->edit('reset') }],
  ['edit separator' => sub { $t->edit('separator') }],
  ['edit modified (set)' => sub { $t->edit('modified', 1) }],
  ['configure (set)' => sub { $t->configure(-width => 31) }],
  ['image create' => sub { $t->image('create', '3.0', -name => 'i') }],
  ['window create' => sub { $t->window('create', '3.0', -create => sub {}) }],
);
# Reading commands, and those that only change the view: they work.
my @reading = (
  [get => sub { $t->get('1.0', 'end') }],
  [index => sub { $t->index('end') }],
  [compare => sub { $t->compare('1.0', '<', 'end') }],
  ['tag ranges' => sub { $t->tag('ranges', 'b') }],
  ['tag names' => sub { $t->tag('names') }],
  ['tag cget' => sub { $t->tag('cget', 'b', '-underline') }],
  ['tag configure (query)' => sub { $t->tag('configure', 'b', '-underline') }],
  ['tag bind (query)' => sub { $t->tag('bind', 'b') }],
  ['block configure (query)' => sub { $t->block('configure', 'F') }],
  ['block cget' => sub { $t->block('cget', 'F', '-empty') }],
  ['tag data (read)' => sub { $t->tag('data', 'b', '1.1') }],
  ['mark names' => sub { $t->mark('names') }],
  ['mark gravity (read)' => sub { $t->mark('gravity', 'm') }],
  ['mark data (read)' => sub { $t->mark('data', 'm') }],
  ['block list' => sub { $t->block('list', '1.0', 'end') }],
  ['block of' => sub { $t->block('of', '2.2') }],
  ['block nodedata (read)' => sub { $t->block('nodedata', '2.2', 0) }],
  ['block data (read)' => sub { $t->block('data', '2.2') }],
  [dump => sub { $t->dump('-all', '1.0', 'end') }],
  [search => sub { $t->search('gh', '1.0') }],
  ['edit modified (read)' => sub { $t->edit('modified') }],
  [cget => sub { $t->cget('-width') }],
  [see => sub { $t->see('3.0') }],
  [yview => sub { $t->yview('moveto', 0) }],
);

my $hook = sub {
  for my $c (@modifying, @reading) {
    $result{$c->[0]} = eval { $c->[1]->(); 1 } ? 'ok' : $@;
  }
};

my $before = $t->get('1.0', 'end');
my @list = $t->block('list', '1.0', 'end');
$t->markData('m', V->new);
my $calls = 0;
$t->configure(-valuecommand => sub { $hook->() unless $calls++ });
$t->markData('m', undef);		# drops the value: the callback runs
$t->configure(-valuecommand => undef);
is($calls, 1, 'the callback ran');
for my $c (@modifying) {
  like($result{$c->[0]}, $refused, "$c->[0] is refused during the -valuecommand");
}
for my $c (@reading) {
  is($result{$c->[0]}, 'ok', "$c->[0] works during the -valuecommand");
}
is($t->get('1.0', 'end'), $before, 'the text is unchanged');
is($t->cget('-width'), 30, 'the configuration too');
ok(!grep({ $_ eq 'm2' } $t->mark('names')), 'no mark was set');
ok(!defined $t->markData('m'), 'the mark has no value');
is($t->index('m'), '1.2', 'and has not moved');
is_deeply([$t->tag('ranges', 'b')], ['1.1', '1.3'], 'the tag is unchanged');
is(join(' ', sort $t->tag('names')), 'b sel', 'no tag was created');
is(join(' ', sort $t->block('names')), 'F', 'no block type either');

# Once the values are freed, the commands work again.
ok(eval { $t->insert('1.0', 'X'); $t->delete('1.0'); 1 },
   'modifying works again afterwards');
is($t->get('1.0', 'end'), $before, 'and did');

# While values are freed, the commands that modify the widget work: all
# of them from one DESTROY method (some fail for reasons of their own,
# none is refused).
%result = ();
$t->markData('m', V->new($hook));
$t->markData('m', undef);
for my $c (@modifying) {
  unlike($result{$c->[0]}, qr/^cannot modify/, "$c->[0] is not refused while values are freed");
}
is($result{insert}, 'ok', 'insert works then');
$t->delete('1.0', 'end');
$t->insert('end', "abcdef\nghijkl\nmnop\n");
$t->blockInsert('F', '2.1', '2.4');
$t->tagAdd('b', '1.1', '1.3');
$t->editReset;

# A value freed by an edit: the DESTROY's insert is made too.
%result = ();
$t->tagData('b', '1.1', V->new(sub { $result{x} = eval { $t->insert('1.0', 'Y'); 1 } ? 'ok' : $@ }));
$t->configure(-undo => 0);
$t->tagRemove('b', '1.0', 'end');		# the run is gone: its value is freed
$t->configure(-undo => 1);
is($result{x}, 'ok', 'an insert from a DESTROY run by tag remove works');
is($t->get('1.0'), 'Y', 'and is made');
$t->delete('1.0');

# The instance data that "block data" replaces is freed when the command
# ends too (BUGS 22: it was freed at once, inside the command), still
# before blockData returns.
for my $how (['replaced', 'other'], ['removed', undef]) {
  my ($what, $new) = @$how;
  %result = ();
  my $text = $t->get('1.0', 'end');
  $t->blockData('2.2', V->new(sub {
    $result{seen} = $t->blockData('2.2');
    $result{x} = eval { $t->insert('end', 'Y'); 1 } ? 'ok' : $@;
  }));
  ok(!exists $result{x}, "block data $what: not freed while set");
  $t->blockData('2.2', $new);
  is($result{seen}, $new, "block data $what: DESTROY sees the new value");
  is($result{x}, 'ok', "block data $what: an insert from its DESTROY works");
  is($t->get('end -2c'), 'Y', "block data $what: once the command is done");
  $t->delete('end -2c');
}
$t->blockData('2.2', undef);
$t->destroy;

# The instance data of a deleted block, kept by the undo step, is freed
# when a discarded step is, at the end of the command too (BUGS 23: the
# step kept it in its block list, released at once): by edit reset, by
# -maxundo, and by a new change dropping the steps that could be redone
# (here the undo of an insertion keeps the data of a block made in it,
# with -undo off, for the redo).
my $deleted = sub {
  my ($u, $v) = @_;
  $u->blockInsert('F', '1.0', '1.2');
  $u->blockData('1.1', $v);
  $u->editReset;
  $u->delete('1.0', '1.end');
};
my $inserted = sub {
  my ($u, $v) = @_;
  $u->insert('1.0', 'XY');
  $u->configure(-undo => 0);
  $u->blockInsert('E', '1.1');		# X.Y: the insertion was 1.0-1.2
  $u->blockData('1.1', $v);
  $u->configure(-undo => 1);
  $u->editUndo;
};
for my $how (
  ['edit reset', [], $deleted, sub { $_[0]->editReset }],
  ['-maxundo', [-maxundo => 1, -autoseparators => 0], $deleted, sub {
     my $u = shift;
     $u->editSeparator;
     $u->insert('2.0', 'q');
     $u->editSeparator;
     $u->insert('2.0', 'r');		# pushes the deletion's step out
     $u->editSeparator;
   }],
  ['a new change after an undo', [], $inserted, sub {
     $_[0]->insert('2.0', 'q');		# drops the step that could be redone
   }]) {
  my ($what, $options, $prepare, $discard) = @$how;
  my $u = $mw->eText(-undo => 1, @$options)->pack;
  $u->blockConfigure('F');
  $u->blockConfigure('E', -empty => 1);
  $u->insert('1.0', "abc\nx\n");
  $u->editReset;
  my $upath = $u->PathName;
  my @r;
  $prepare->($u, V->new(sub {
    push @r, eval { $u->insert('end', 'y'); 1 } ? 'ok' : $@;
    push @r, $u->get('end -2c');
  }));
  ok(!@r, "$what: the block's data is kept by the step");
  $discard->($u);
  is(scalar @r, 2, "$what: discarding the step frees it once");
  is($r[0], 'ok', "$what: an insert from its DESTROY works");
  is($u->get('end -2c'), 'y', "$what: and is made");
  $u->destroy;
}
# A change made from a DESTROY method is an undo step of its own: it does
# not merge into the step of the command that dropped the value, nor
# into the next change.
{
  my $u = $mw->eText(-undo => 1, -autoseparators => 0)->pack;
  $u->insert('1.0', "abc\n");
  $u->editReset;
  $u->markSet('m', '1.1');
  $u->markData('m', V->new(sub { $u->insert('end', 'Y') }));
  $u->insert('1.0', 'A');			# the step open
  $u->markData('m', undef);		# the DESTROY inserts Y
  $u->insert('1.0', 'B');
  is($u->get('1.0', 'end'), "BAabc\nY\n", 'the insert from DESTROY is made');
  $u->editUndo;
  is($u->get('1.0', 'end'), "Aabc\nY\n", 'the next change is a step of its own');
  $u->editUndo;
  is($u->get('1.0', 'end'), "Aabc\n\n", 'so is the change from DESTROY');
  $u->editUndo;
  is($u->get('1.0', 'end'), "abc\n\n", 'and the step before it');
  $u->destroy;
}

# The values a change from a DESTROY method drops are freed in the same
# pass, before the widget command that dropped the first one returns.
{
  my $u = $mw->eText->pack;
  my @order;
  {
    package W;
    sub new { my ($class, $name, $hook) = @_; bless { n => $name, hook => $hook }, $class }
    sub DESTROY { push @order, $_[0]{n}; $_[0]{hook}->() if $_[0]{hook} }
  }
  $u->insert('1.0', "abc\n");
  $u->markSet('p', '1.0');
  $u->markSet('q', '1.1');
  $u->markData('q', W->new('second'));
  $u->markData('p', W->new('first', sub { $u->markUnset('q') }));
  $u->markData('p', undef);
  push @order, 'returned';
  is_deeply(\@order, [qw(first second returned)],
	    'a value dropped by a change from DESTROY: freed in the same pass');
  ok(!grep({ $_ eq 'q' } $u->markNames), 'the change was made');

  # A chain: each DESTROY sets and drops a new value, whose DESTROY does
  # the same.  It stops 10 deep: the 10th DESTROY's change is refused.
  my (@chain, @errors);
  {
    package C;
    our ($w, $chain, $errors);
    sub new { my ($class, $n) = @_; bless { n => $n }, $class }
    sub DESTROY {
      my $self = shift;
      return if $self->{inert};
      push @$chain, $self->{n};
      my $next = C->new($self->{n} + 1);
      unless (eval { $w->markData('p', $next); $w->markData('p', undef); 1 }) {
	push @$errors, $@;
	$next->{inert} = 1;
      }
    }
  }
  local ($C::w, $C::chain, $C::errors) = ($u, \@chain, \@errors);
  $u->markData('p', C->new(1));
  $u->markData('p', undef);
  is_deeply(\@chain, [1 .. 10], 'a chain of changes from DESTROY methods stops 10 deep');
  is(scalar @errors, 1, 'with one refusal');
  like($errors[0] // '', qr/^cannot modify \S+ while its values are being freed, 10 changes deep/,
       'which says so');
  ok(eval { $u->insert('1.0', 'Z'); 1 }, 'the widget works again afterwards');
  $u->destroy;
}
$mw->destroy;
