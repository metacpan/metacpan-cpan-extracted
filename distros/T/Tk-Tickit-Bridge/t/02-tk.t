use v5.36;
use utf8;
use Test::More;
use Tk::Tickit::Bridge;
use Tk::Tickit::Bridge::Loop;

my $mw = eval { MainWindow->new };
plan skip_all => 'No usable X display (try xvfb-run -a prove -lr t)' unless $mw;
END { $mw->destroy if Tk::Exists($mw) }

{
    package RecordingTerm;
    sub new ($class) { bless { events => [] }, $class }
    sub emit_key ($self, %event) {
        die "injection failed\n" if $self->{fail};
        push $self->{events}->@*, \%event;
        $self->{on_event}->() if $self->{on_event};
    }
    package CountingLoop;
    sub new ($class) { bless {calls => []}, $class }
    sub loop_once ($self, $timeout) {
        push $self->{calls}->@*, $timeout;
        $self->{on_turn}->() if $self->{on_turn};
    }
}

my $term = RecordingTerm->new;
my $field = $mw->Entry->pack;
my @original = $field->bindtags;
my $all_count = 0;
$mw->bind('all', '<KeyPress>' => sub { ++$all_count });
my $bridge = Tk::Tickit::Bridge->new(widget => $mw, term => $term,
    forward => 'always')->install;
$bridge->install;
my @installed = $field->bindtags;
is(scalar(@installed), scalar(@original) + 1, 'install once, prepend private tag');
is_deeply([@installed[1..$#installed]], \@original, 'normal tag order preserved');

$bridge->enqueue(type => 'text', str => 'é');
is($bridge->pending, 1, 'event is queued');
is(scalar($term->{events}->@*), 0, 'no synchronous delivery');
$mw->update;
is_deeply($term->{events}[0], {type => 'text', str => 'é', mod => 0},
    'real Tk idle callback delivers event');
is($bridge->pending, 0, 'queue drained');

$term->{on_event} = sub {
    delete $term->{on_event};
    $bridge->enqueue(type => 'text', str => 'later');
};
$bridge->enqueue(type => 'text', str => 'first');
$bridge->drain;
is($bridge->pending, 1, 'recursive enqueue waits for another batch');
is($term->{events}[-1]{str}, 'first', 'first batch delivered alone');
$mw->update;
is($term->{events}[-1]{str}, 'later', 'next idle turn delivers recursive enqueue');

my @errors;
$bridge->{on_error} = sub ($message) { push @errors, $message };
$term->{fail} = 1;
$bridge->enqueue(type => 'key', str => 'F1');
$bridge->drain;
like($errors[0], qr/injection failed/, 'delivery errors reported');
delete $term->{fail};

$mw->update;
$field->focusForce;
$mw->update;
$field->eventGenerate('<KeyPress>', -keysym => 'a');
$mw->update;
is($term->{events}[-1]{str}, 'a', 'real Tk key reaches bridge');
is($field->get, '', 'consumed key does not edit native field');
is($all_count, 0, 'consumed key stops later all binding');

$bridge->enqueue(type => 'text', str => 'discard');
my $before = scalar $term->{events}->@*;
my @with_extra = ($field->bindtags, 'UnrelatedTag');
$field->bindtags(\@with_extra);
$bridge->uninstall;
$mw->update;
is(scalar($term->{events}->@*), $before, 'uninstall cancels pending delivery');
is_deeply([$field->bindtags], [@original, 'UnrelatedTag'],
    'uninstall preserves unrelated tag changes');
$field->eventGenerate('<KeyPress>', -keysym => 'b');
$mw->update;
is($field->get, 'b', 'native editing restored');
is($all_count, 1, 'existing all binding remains');
$bridge->uninstall;

my $later = $mw->Entry->pack;
$bridge->install->attach($later);
is(scalar(grep { /TkTickitBridge_/ } $later->bindtags), 1,
    'attach is idempotent for new widget');
$bridge->uninstall;

my $selective = Tk::Tickit::Bridge->new(widget => $mw, term => $term,
    forward => sub ($source, @rest) { $source eq $later }, consume => 0)->install;
$field->eventGenerate('<KeyPress>', -keysym => 'c');
$later->focusForce;
$mw->update;
$later->eventGenerate('<KeyPress>', -keysym => 'd');
$mw->update;
is($term->{events}[-1]{str}, 'd', 'custom policy selects source');
is($later->get, 'd', 'consume false retains native handling');
$selective->uninstall;

my $loop = CountingLoop->new;
my $pump = Tk::Tickit::Bridge::Loop->new(widget => $mw, loop => $loop, interval => 1);
is($pump->start, $pump, 'start returns pump');
$pump->start;
my $turns = 0;
$loop->{on_turn} = sub { $pump->stop if ++$turns == 3 };
# Tk waitVariable gives timers a real event loop, with a bounded timeout.
my $done = 0;
$mw->after(50, sub { $done = 1 });
$mw->waitVariable(\$done);
is_deeply($loop->{calls}, [0, 0, 0], 'three nonblocking turns; stop inside callback');
ok(!$pump->running, 'stopped');
$pump->stop;

my $weak;
{
    my $temporary = Tk::Tickit::Bridge::Loop->new(widget => $mw, loop => $loop)->start;
    $weak = $temporary;
    Scalar::Util::weaken($weak);
}
ok(!defined $weak, 'timer does not retain pump');

my $window = $mw->Toplevel;
my $closed = Tk::Tickit::Bridge->new(widget => $window, term => $term)->install;
$closed->enqueue(type => 'text', str => 'not delivered');
$window->destroy;
ok(eval { $closed->uninstall; 1 }, 'safe to uninstall after widget destruction');

# Verify the real XS injection API as well as the recording test double.
require Tickit::Term;
local $ENV{TERM} = 'xterm';
open my $sink, '>', '/dev/null' or die $!;
my $real_term = Tickit::Term->new(writer => $sink, UTF8 => 1);
my @received;
$real_term->bind_event(key => sub ($term, $event, $info, @rest) {
    push @received, { str => $info->str };
    return 1;
});
my $real_bridge = Tk::Tickit::Bridge->new(widget => $mw, term => $real_term);
$real_bridge->enqueue(type => 'text', str => 'hello');
$real_bridge->enqueue(type => 'key', str => 'F2');
$mw->update;
is_deeply([map { $_->{str} } @received], ['hello', 'F2'],
    'idle delivery reaches real Tickit::Term key callbacks');
$real_bridge->uninstall;
done_testing;
