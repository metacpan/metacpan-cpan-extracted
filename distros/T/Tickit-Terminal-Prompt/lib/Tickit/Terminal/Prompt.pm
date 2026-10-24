package Tickit::Terminal::Prompt;

use v5.36;
use Carp qw(croak);
use IO::Async::Loop;
use Tickit::Async;
use Tickit::Widget::Entry;
use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;

our $VERSION = '0.003';

# A scroller item reserves one line for an Entry in a floating child window.
{
    package Tickit::Terminal::Prompt::_EntryItem;

    sub new ($class, $on_render) { bless { on_render => $on_render }, $class }
    sub height_for_width ($self, $width) { 1 }
    sub render ($self, $rb, %args) {
        for my $line ($args{firstline} .. $args{lastline}) {
            $rb->goto($line, 0);
            $rb->erase_to($args{width});
        }
        $self->{on_render}->();
    }
}

sub new ($class, %args) {
    my $on_enter = delete $args{on_enter};
    croak 'on_enter must be a code reference' unless ref $on_enter eq 'CODE';
    my $prompt = delete $args{prompt} // '> ';
    croak 'prompt must be a single line' if $prompt =~ /[\r\n]/;
    croak 'unknown constructor arguments: ' . join(', ', sort keys %args) if %args;

    my $scroller = Tickit::Widget::Scroller->new;
    my $tickit = Tickit::Async->new(root => $scroller);
    my $loop = IO::Async::Loop->new;
    $loop->add($tickit);

    my $self = bless {
        prompt => $prompt,
        on_enter => $on_enter,
        scroller => $scroller,
        tickit => $tickit,
        loop => $loop,
        stopped => 0,
        entry_attached => 0,
        partial => '',
    }, $class;

    my $entry = Tickit::Widget::Entry->new(
        text => $prompt,
        on_enter => sub ($widget, $text) { $self->_accept_line($text) },
    );
    $self->{entry} = $entry;
    $self->{entry_item} = Tickit::Terminal::Prompt::_EntryItem->new(
        sub { $self->_position_entry },
    );
    $scroller->set_on_scrolled(sub { $self->_position_entry });
    $self->_bind_prompt_keys;
    $tickit->bind_key('C-c' => sub { $self->stop });
    $entry->set_position(length $prompt);
    $tickit->later(sub { $self->_attach_entry });
    return $self;
}

sub _bind_prompt_keys ($self) {
    my $entry = $self->{entry};
    my $start = sub { length $self->{prompt} };
    my $back = sub {
        $entry->text_delete($entry->position - 1, 1)
            if $entry->position > $start->();
    };
    my $left = sub {
        $entry->set_position($entry->position - 1)
            if $entry->position > $start->();
    };
    my $home = sub { $entry->set_position($start->()) };
    my $kill_to_end = sub {
        $entry->text_delete($entry->position, length($entry->text) - $entry->position);
    };
    my $kill_to_start = sub {
        $entry->text_delete($start->(), $entry->position - $start->());
    };
    my $word_back = sub {
        return if $entry->position <= $start->();
        my $before = substr($entry->text, $start->(), $entry->position - $start->());
        $before =~ /(?:\s*\S+\s*|\s+)\z/;
        my $count = length($& // '');
        $entry->text_delete($entry->position - $count, $count) if $count;
    };
    $entry->bind_keys(
        Backspace => $back,
        'C-h' => $back,
        Left => $left,
        Home => $home,
        'C-a' => $home,
        'C-u' => $kill_to_start,
        'C-k' => $kill_to_end,
        'C-w' => $word_back,
        'C-Backspace' => $word_back,
        'C-Left' => sub {
            my $pos = $entry->find_bow_backward($entry->position);
            $entry->set_position($pos < $start->() ? $start->() : $pos);
        },
        'C-c' => sub { $self->stop },
    );
}

sub _attach_entry ($self) {
    return if $self->{entry_attached};
    my $scroller = $self->{scroller};
    unless ($scroller->window) {
        $self->{tickit}->later(sub { $self->_attach_entry });
        return;
    }
    $scroller->push($self->{entry_item});
    $self->{entry_attached} = 1;
    $scroller->scroll_to_bottom;
    $self->_position_entry;
}

sub _position_entry ($self) {
    return unless $self->{entry_attached};
    my $parent = $self->{scroller}->window or return;

    if (!defined $self->{scroller_window} || "$self->{scroller_window}" ne "$parent") {
        if (my $old = $self->{scroller_window}) {
            $old->unbind_event_id($self->{geometry_event}) if defined $self->{geometry_event};
        }
        if (my $old = delete $self->{entry_window}) {
            $self->{entry}->set_window(undef);
            $old->close;
        }
        $self->{scroller_window} = $parent;
        $self->{geometry_event} = $parent->bind_event(
            geomchange => sub { $self->_position_entry },
        );
    }

    my ($line, $offscreen) = $self->{scroller}->item2line($self->{entry_item}, 0, 1);
    if (!defined $line || defined $offscreen) {
        $self->{entry_window}->hide
            if $self->{entry_window} && $self->{entry_window}->is_visible;
        return;
    }
    if (!$self->{entry_window}) {
        my $win = $parent->make_float($line, 0, 1, $parent->cols);
        $self->{entry_window} = $win;
        $self->{entry}->set_window($win);
        $self->{entry}->take_focus;
        return;
    }
    my $win = $self->{entry_window};
    my $was_visible = $win->is_visible;
    $win->change_geometry($line, 0, 1, $parent->cols);
    unless ($was_visible) {
        $win->show;
        $self->{entry}->take_focus;
    }
}

sub _accept_line ($self, $text) {
    my $prompt = $self->{prompt};
    my $line = substr($text, length $prompt);
    $self->print($prompt, $line, "\n");
    $self->{entry}->set_text($prompt);
    $self->{entry}->set_position(length $prompt);
    $self->{on_enter}->($self, $line);
}

sub print ($self, @parts) {
    my $text = join '', map { defined($_) ? $_ : '' } @parts;
    return $self unless length $text;
    my $scroller = $self->{scroller};
    if ($self->{entry_attached}) {
        $scroller->pop(1);
        $self->{entry_attached} = 0;
    }
    $scroller->pop(1) if length $self->{partial};
    my @lines = split /\n/, $self->{partial} . $text, -1;
    $self->{partial} = pop @lines;
    $scroller->push(Tickit::Widget::Scroller::Item::Text->new($_)) for @lines;
    $scroller->push(Tickit::Widget::Scroller::Item::Text->new($self->{partial}))
        if length $self->{partial};
    if ($scroller->window) {
        $scroller->push($self->{entry_item});
        $self->{entry_attached} = 1;
        $scroller->scroll_to_bottom;
        $self->_position_entry;
    }
    return $self;
}

sub say ($self, @parts) { $self->print(@parts, "\n") }

sub set_prompt ($self, $prompt) {
    croak 'prompt must be a single line' if !defined($prompt) || $prompt =~ /[\r\n]/;
    my $entry = $self->{entry};
    my $command = substr($entry->text, length $self->{prompt});
    $self->{prompt} = $prompt;
    $entry->set_text($prompt . $command);
    $entry->set_position(length($prompt . $command));
    return $self;
}

sub run ($self) {
    local $SIG{INT} = sub { $self->stop };
    $self->{tickit}->run;
    # Flush Tickit's teardown before writing a newline for the shell.
    $self->{tickit}->term->flush;
    CORE::print STDOUT "\n";
    return $self;
}

sub stop ($self) {
    return $self if $self->{stopped}++;
    $self->{scroller}->scroll_to_bottom;
    $self->_position_entry;

    # Scroller and window redraws are queued with Tickit->later. Allow both
    # rounds to run before restoring the shell at the bottom of the display.
    my $tickit = $self->{tickit};
    $tickit->later(sub {
        $tickit->later(sub {
            my $term = $tickit->term;
            $term->goto($term->lines - 1, 0);
            $term->flush;
            $tickit->stop;
        });
    });
    return $self;
}

1;

=head1 NAME

Tickit::Terminal::Prompt - a scrolling terminal command prompt

=head1 SYNOPSIS

my $ui = Tickit::Terminal::Prompt->new(
    prompt => 'demo> ',
    on_enter => sub ($ui, $line) {
        $ui->say("You entered: $line");
        $ui->stop if $line eq 'quit';
    },
);
$ui->run;

=head1 DESCRIPTION


A shell-like terminal interface with a command prompt and a
scrolling output. The command line allows editing using
Backspace, Left, Home, Ctrl-A, Ctrl-E, Ctrl-H, Ctrl-K,
Ctrl-U and Ctrl-W as in ReadLine. Ctrl-C stops the
interface. 

The application supplies a callback that receives the
command text when the user presses Enter.

With a small amount of additional code this library can be
used to build a command processor for terminal applications,
or an actual unix shell. 

=head1 METHODS

=head2 new

Requires C<on_enter =E<gt> sub ($ui, $line) { ... }>. The optional C<prompt>
defaults to C<< > >>. Prompts must fit on one line.

=head2 print, say

Append text to the scroller. C<say> adds a newline. Calls to C<print> without
a newline continue the current output line.

=head2 set_prompt

Replace the prompt while retaining any command currently being edited.

=head2 run, stop

Start or stop the event loop. C<stop> scrolls to the bottom, lets the final
redraw complete, and places the terminal cursor on the bottom row before
stopping. After Tickit restores the terminal, C<run> flushes and prints a
newline so the shell prompt appears on the next line. Ctrl-C calls C<stop>.

=head1 AUTHOR

Joel Roth <joelz@pobox.com>

=head1 LICENSE

Copyright (C) 2026 Joel Roth. 

This is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. 

=cut
