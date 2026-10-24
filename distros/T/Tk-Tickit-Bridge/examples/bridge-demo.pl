#!/usr/bin/env perl
use v5.36;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Tk;
use IO::Async::Loop;
use IO::Async::Signal;
use Tickit::Async;
use Tickit::Widget::VBox;
use Tickit::Widget::Static;
use Tickit::Widget::Entry;
use Tk::Tickit::Bridge;
use Tk::Tickit::Bridge::Loop;

die "Run this demo in a terminal with an X display.\n" unless -t STDIN && -t STDOUT;
my ($quit, $pump, $bridge, $tickit, $mw);
my $failure;
eval {
    $mw = MainWindow->new(-title => 'Tk / Tickit bridge');
    my $last = 'Nothing submitted yet';
    $mw->Label(-text => 'Type in the terminal; Enter updates this window.')->pack;
    $mw->Label(-textvariable => \$last, -width => 48)->pack;
    $mw->Label(-text => 'This Tk entry forwards keys to the terminal:')->pack;
    my $forward_entry = $mw->Entry(-width => 48)->pack;
    $mw->Label(-text => 'This Tk entry keeps normal Tk editing:')->pack;
    my $native_entry = $mw->Entry(-width => 48)->pack;

    my $vbox = Tickit::Widget::VBox->new;
    $vbox->add(Tickit::Widget::Static->new(
        text => 'Type a line and press Enter. Type /quit to exit; Ctrl-C also quits.',
    ));
    my $status = Tickit::Widget::Static->new(text => 'Waiting for input');
    $vbox->add($status);
    my $entry = Tickit::Widget::Entry->new(on_enter => sub ($widget, $line) {
        if ($line eq '/quit') { $quit = 1; return }
        $last = $line;
        $status->set_text("Submitted: $line");
        $widget->set_text('');
    });
    $vbox->add($entry);
    my $clicks = 0;
    $mw->Button(-text => 'Update terminal', -command => sub {
        $status->set_text('Tk button pressed ' . ++$clicks . ' times');
    })->pack;
    $mw->Button(-text => 'Quit', -command => sub { $quit = 1 })->pack;
    $mw->protocol(WM_DELETE_WINDOW => sub { $quit = 1 });

    my $loop = IO::Async::Loop->new;
    $tickit = Tickit::Async->new(root => $vbox);
    $loop->add($tickit);
    $tickit->bind_key('C-c' => sub { $quit = 1 });
    $loop->add(IO::Async::Signal->new(
        name => 'INT', on_receipt => sub { $quit = 1 },
    ));
    $bridge = Tk::Tickit::Bridge->new(
        widget => $mw, term => $tickit->term,
        # Only this field forwards. The other Tk field edits normally.
        forward => sub ($source, @rest) { $source eq $forward_entry },
    )->install;
    $pump = Tk::Tickit::Bridge::Loop->new(widget => $mw, loop => $loop)->start;
    $vbox->set_window($tickit->rootwin);
    $entry->take_focus;
    $forward_entry->focus;

    # Let callbacks return before dismantling either interface.
    Tk::DoOneEvent(0) while !$quit && Tk::Exists($mw);
    1;
} or $failure = $@ || 'Demo failed';

$pump->stop if $pump;
$bridge->uninstall if $bridge;
$tickit->term->teardown if $tickit;
$mw->destroy if Tk::Exists($mw);
die $failure if $failure;
print "Demo finished.\n";
