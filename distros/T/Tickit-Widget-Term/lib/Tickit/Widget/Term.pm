package Tickit::Widget::Term;
# ABSTRACT: terminal emulation for Tickit
use strict;
use warnings;

use parent qw(Tickit::Widget);

our $VERSION = '0.003';

=head1 NAME

Tickit::Widget::Term - runs a process in a window, using terminal emulation that makes VT100 look like advanced technology

=head1 SYNOPSIS

 #!/usr/bin/env perl
 use strict;
 use warnings;
 use Tickit::Async;
 use Tickit::Widget::Term;
 use IO::Async::Loop;
 use Log::Any qw($log);
 use Log::Any::Adapter qw(Stderr), log_level => 'debug';
 use Tickit::Widget::Frame;
 
 binmode STDERR, ':encoding(UTF-8)';
 
 my $loop = IO::Async::Loop->new;
 $loop->add(
 	my $tickit = Tickit::Async->new
 );
 my $frame = Tickit::Widget::Frame->new(
 	child => my $term = Tickit::Widget::Term->new(
 		command => ['/bin/bash'],
 		loop => $loop
 	),
 	title => 'shell',
 	style => {
 		linetype => 'single'
 	},
 );
 $tickit->set_root_widget(
 	$frame
 );
 $term->take_focus;
 $tickit->run;

=head1 DESCRIPTION

In principle, a terminal widget would provide an abstraction for running any terminal application under
L<Tickit>. This would include full support for attributes, cursor movement, scrolling, mouse/keyboard input,
and if used as the root window should be indistinguishable from running the code directly from the parent
terminal itself.

What you get with this module is a minimum-viable implementation for running a tiny subset of the
basic shell commands. It's a hack using cargo-culted L<IO::Pty> pieces, manual forking under L<IO::Async>,
and a vague understanding of terminal control codes based on watching low-budget police shows. It redraws
everything at the slightest excuse. You'd have to run reset(1) before you can even get your own keyboard
input echoing back. The code spends most of its time logging the endless list of features that aren't supported.

Having said that, here are some things you can expect to work:

=over 4

=item * ls (partly)

=item * some of the letters

=item * maybe the enter key

=back

Unlikely scenarios:

=over 4

=item * anything which does more than move the cursor or select one of the 8 colours.

=back

At this point, it's customary to mention that the module and API are experimental and likely to change.
Careful readers will already have noticed that this is a placeholder module and "likely to change" is
somewhat understated.

=head2 Logging

This module uses L<Log::Any> to generate copious amounts of unhelpful diagnostics. Future versions may
add even more!

=cut

use constant WIDGET_PEN_FROM_STYLE => 1;
use constant CAN_FOCUS => 1;
use constant DEBUG => 0;

use Tickit::Style;

use POSIX;
use IO::Async::Stream;
use Variable::Disposition qw(retain_future);
use IO::Tty;
use IO::Pty;
use IO::Termios;
use Tickit::Utils qw(textwidth);
use List::UtilsBy qw(extract_by);

use Log::Any qw($log);

=head1 METHODS

=cut

=head2 new

This creates a new instance. I'd recommend against using it.

 Tickit::Widget::Term->new(
  command => ['/bin/bash'],
  loop => $loop
 )

=cut

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{loop} = delete $args{loop} or die 'need a loop';
    $self->{command} = delete $args{command} or die 'need a command';
    $self->init;
    $self
}

=head2 window_gained

Sets up cursor position and notifies the child process via WINCH when we get a window.

=cut

sub window_gained {
    my ($self, $win) = @_;
    $win->cursor_at(0,0);
    $self->SUPER::window_gained($win)
}

=head2 loop

Accessor for the L<IO::Async::Loop> instance.

=cut

sub loop { shift->{loop} }

=head2 pty

Accessor for the L<IO::Pty> instance.

=cut

sub pty { shift->{pty} }

=head2 lines

How many lines we're expecting to use. This value was carefully researched from a wide selection of
popular terminal applications, and is not just the highest number I can count to on one hand.

=cut

sub lines { 5 }

=head2 cols

Default number of columns. The number 80 seemed appropriate here.

=cut

sub cols { 80 }

=head2 render_to_rb

Renders things. You don't call this, L<Tickit> does.

=cut

sub render_to_rb {
    my ($self, $rb, $rect) = @_;
    my $win = $self->window;
    $rb->clip($rect);
    $rb->clear;

    for my $item (@{$self->{writable}}) {
        if(my $type = $item->{type}) {
            if($type eq 'erase') {
                $rb->eraserect($item->{rect}, $item->{pen});
            } elsif($type eq 'scroll') {
                $rb->eraserect($item->{rect}, $item->{pen});
            } else {
                $log->errorf("Unknown writequeue type %s", $type);
            }
        } else {
            $rb->text_at($item->{line}, $item->{col}, $item->{text}, $item->{pen});
        }
    }
}

=head2 command

Returns the command to execute plus any args, as an arrayref.

=cut

sub command { $_[0]->{command} }

=head2 init

Calling this yourself is probably not needed, so documenting it would be even less useful.

=cut

sub init {
    my ($self) = @_;
    my $loop = $self->loop;
    my $cmd = $self->command;
                    @{$self->{writable}} = ();
                    $self->{terminal_line} = 0;
                    $self->{terminal_col} = 0;
                    $self->update_cursor;
    $loop->later(sub {
        $log->debug("Starting deferred PTY creation");
        $IO::Tty::DEBUG = 1 if DEBUG;
        my $pty = IO::Pty->new;
        $self->{pty} = $pty;
        $log->debugf("New PTY at %s", $pty->ttyname);
        pipe my $reader, my $writer or die "pipe - $!";
        $log->debugf("Controlling pipe at FDs %d and %d", map $_->fileno, $reader, $writer);
        $writer->autoflush(1);
        if(my $pid = fork // die "fork - $!") {
            $log->debugf("Parent process had child pid %d", $pid);
            $writer->close;
            $pty->close_slave;
            $pty->set_raw;
            {
                $loop->add(
                    my $rs = IO::Async::Stream->new(
                        handle => $reader,
                        on_read => sub { 0 }
                    )
                );
                retain_future(
                    $rs->read_until_eof->then(sub {
                        my ($errno) = @_;
                        $log->debugf("had EOF");
                        $rs->close;
                        if($errno) {
                            $! = 0 + $errno;
                            die "exec failed - $! ($errno)";
                        }
                        $pty->autoflush(1);
                        STDOUT->autoflush(1);
                        my $stream = IO::Async::Stream->new(
                            handle => $pty,
                            on_read => do {
                                my $str = '';
                                sub {
                                    my ($stream, $buf, $eof) = @_;
                                    $str .= Encode::decode('UTF-8', $$buf, Encode::FB_QUIET);
                                    1 while $self->handle_terminal_output(\$str);
                                    0
                                }
                            }
                        );
                        $loop->add($stream);
                    })
                );
            }
        } else {
            $log->debugf("Child process active on %d", $$);
            $reader->close;

            $pty->make_slave_controlling_terminal if -T STDIN;
            # somewhere around here I was expecting to need POSIX::setsid, but strace shows
            # that ->make_slave_controlling_terminal does this for us. which is nice.

            my $slave = $pty->slave;
            $pty->close;

            # We'll arbitrarily pick a winsize here, and overwrite it when we obtain a window...
            # BUT! we might already have a window, so use that if available.
            if(my $win = $self->window) {
                $log->debugf("Applying PTY size from window: (%d,%d)", $win->lines, $win->cols);
                $slave->set_winsize($win->lines, $win->cols);
            } else {
                $log->debugf("Applying PTY size from defaults: (%d,%d)", $self->lines, $self->cols);
                $slave->set_winsize($self->lines, $self->cols);
            }
            $slave->set_raw;
            IO::Termios->new($slave)->setflag_echo(1);

            $log->debugf("Redirecting handles and Executing command %s", $cmd);
            # Redirect our STDIO/ERR towards the PTY
            open STDIN, '<&' . $slave->fileno or die "STDIN - $!";
            open STDOUT, '>&' . $slave->fileno or die "STDOUT - $!";
            open STDERR, '>&' . $slave->fileno or die "STDERR - $!";
            # ... and drop the original handle - in an exec scenario, F_CLOEXEC is probably going
            # to take care of this for us. On the other hand, if we're about to wade into a code block
            # instead, we don't really need a stray handle lying around for things to stumble over.
            $slave->close or die "cannot close original PTY? $!";

            exec { $cmd->[0] } @$cmd or $writer->print($! + 0);
            die "cannot exec - $!";
        }
    });
}

=head2 on_key

This will be called when we get a key. Its purpose is mostly to emit unhappy log messages about
how few of those keys we're passing along.

=cut

sub on_key {
    my ($self, $ev) = @_;
    $log->debugf("Had key event %s", $ev);
    if($ev->type eq 'key') {
        if($ev->str eq 'Enter') {
            $self->pty->write("\n");
        } elsif($ev->str eq 'Backspace') {
            $self->pty->write("\x08");
        }
    } elsif($ev->type eq 'text') {
        $self->pty->write($ev->str);
    }
    $self->redraw;
}

=head2 pen

Returns a pen. Probably one that matches the currently-requested attributes.

=cut

sub pen {
    my ($self) = @_;
    $self->{pen} //= $self->get_style_pen;
    $self->{pen} = $self->{pen}->as_mutable unless $self->{pen}->mutable;
    $self->{pen};
}

my %csi_map = (
    m => sub {
        my ($self, @param) = @_;
        push @param, 0 unless @param;
        for(@param) {
            if($_ == 0) {
                $log->debug("SGR reset");
                delete $self->{pen};
            } elsif($_ == 1) {
                $log->debug("SGR bold");
                $self->pen->chattr(b => 1);
            } elsif($_ == 2) {
                $log->debug("SGR halfbright");
            } elsif($_ == 4) {
                $log->debug("SGR underscore");
                $self->pen->chattr(u => 1);
            } elsif($_ == 5) {
                $log->debug("SGR blink");
            } elsif($_ == 7) {
                $log->debug("SGR reverse");
                $self->pen->chattr(rv => 1);
            } elsif($_ == 10) {
                $log->debug("SGR primary font");
            } elsif($_ == 11) {
                $log->debug("SGR first alt");
            } elsif($_ == 12) {
                $log->debug("SGR second alt");
            } elsif($_ == 21) {
                $log->debug("SGR double-underline");
            } elsif($_ == 22) {
                $log->debug("SGR normal intensity");
                $self->pen->chattr(b => 0);
            } elsif($_ == 24) {
                $log->debug("SGR disable underline");
                $self->pen->chattr(u => 0);
            } elsif($_ == 25) {
                $log->debug("SGR disable blink");
            } elsif($_ == 27) {
                $log->debug("SGR disable RV");
                $self->pen->chattr(rv => 0);
            } elsif($_ >= 30 && $_ <= 37) {
                my $fg = $_ - 30;
                $log->debugf("SGR fg = %d", $fg);
                $self->pen->chattr(fg => $fg);
            } elsif($_ == 38) {
                $log->debug("SGR underscore on, default fg");
                $self->pen->chattr(fg => $self->get_style_pen->getattr('fg'));
                $self->pen->chattr(u => 1);
            } elsif($_ == 39) {
                $log->debug("SGR underscore off, default fg");
                $self->pen->chattr(fg => $self->get_style_pen->getattr('fg'));
                $self->pen->chattr(u => 0);
            } elsif($_ >= 40 && $_ <= 47) {
                my $bg = $_ - 30;
                $log->debugf("SGR bg = %d", $bg);
                $self->pen->chattr(bg => $bg);
            } elsif($_ == 49) {
                $log->debug("SGR bg = default");
                $self->pen->chattr(bg => $self->get_style_pen->getattr('bg'));
            } else {
                $log->warnf("SGR unknown parameter %s", $_);
            }
        }
    },
    H => sub {
        my ($self, $line, $col) = @_;
        $line //= 0;
        $col //= 0;
        $log->debugf("SGR CUP %d, %d", $line, $col);
        $self->{terminal_line} = $line - 1;
        $self->{terminal_col} = $col - 1;
        $self->update_cursor;
    },
    J => sub {
        my ($self, $type) = @_;
        $type //= 0;
        $log->debugf("SGR ED %d", $type);
        @{$self->{writable}} = ();
        $self->{terminal_line} = 0;
        $self->{terminal_col} = 0;
        $self->update_cursor;
        $self->redraw;
    },
    K => sub {
        my ($self, $type) = @_;
        $type //= 0;
        $log->debugf("SGR EL %d", $type);
        push @{$self->{writable}}, {
            type => 'erase',
            pen  => $self->pen->as_immutable,
            rect => Tickit::Rect->new(
                top  => $self->terminal_line,
                left => (
                    $type == 0
                    ? $self->terminal_col
                    : 0
                ),
                cols => (
                    $type == 1
                    ? $self->terminal_col
                    : -1
                ),
                lines => 1,
            )
        };
        $self->redraw;
    },
    d => sub {
        my ($self, $line) = @_;
        $line //= 0;
        $log->debugf("SGR VPA %d", $line);
        $self->{terminal_line} = $line - 1;
        $self->update_cursor;
    },
    g => sub {
        my ($self, $type) = @_;
        $log->debugf("CSI TBC %d", $type);
        if($type) {
            if($type == 3) {
                @{$self->{tab_stops}} = ();
            } else {
                $log->warnf("Tab clear requested with unknown parameter (expected 3) - %s", $type);
            }
        } else {
            extract_by { $_ == $self->terminal_col } @{$self->{tab_stops}}
        }
    }
);

=head2 csi_map

Dispatch table thing for handling control sequence introducers. They do things like set
colours, apparently.

=cut

sub csi_map {
    my ($self, $action) = @_;
    return undef unless exists $csi_map{$action};
    sub { $csi_map{$action}->($self, @_) }
}

# let's put the constants in the middle of the file so it's harder to find them
use constant {
    NORMAL => 0,
    ESC => 1,
    CSI => 2,
};

=head2 handle_terminal_output

This takes bytes from the PTY handle, then throws most of them away. Since the method
no longer fits on my screen I have no idea what any of it really does.

=cut

sub handle_terminal_output {
    my ($self, $buf) = @_;
    $log->debugf("We have %d bytes of exciting new PTY data to examine", length $$buf);
    for($$buf) {
        my $mode = NORMAL;
        BREAKOUT:
        while(1) {
            # CAN/SUB abort escape sequence - i.e. switch to normal mode immediately
            if(/\G\x18/gc) {
                $log->debugf("CAN, bail out of escape mode (was %d)", $mode);
                $mode = NORMAL;
                redo BREAKOUT;
            } elsif(/\G\x1A/gc) {
                $log->debugf("SUB, bail out of escape mode (was %d)", $mode);
                $mode = NORMAL;
                redo BREAKOUT;
            } elsif(/\G\x07/gc) {
                $log->debug("BEEP");
                redo BREAKOUT;
            } elsif(/\G\x08/gc) {
                $log->debug("Backspace");
                redo BREAKOUT;
            } elsif(/\G([\x0A\x0B\x0C])/gc) {
                $log->debugf("Linefeed of some description (%s)", ord $1);
                $self->push_text("\n");
                redo BREAKOUT;
            } elsif(/\G\x0D/gc) {
                $log->debug("CR");
                redo BREAKOUT;
            } elsif(/\G\x0E/gc) {
                $log->debug("Activate G1 character set");
                redo BREAKOUT;
            } elsif(/\G\x0F/gc) {
                $log->debug("Activate G0 character set");
                redo BREAKOUT;
            } elsif(/\G\x7F/gc) {
                $log->debug("DEL (ignored)");
                redo BREAKOUT;
            } elsif(/\G\x9B/gc) {
                $log->debug("CSI");
                $mode = CSI;
                redo BREAKOUT;
            }

            if($mode == NORMAL) {
                if(/\G([^\x00-\x1F]+)/gcu) {
                    $log->debugf("Text sequence: %s", $1);
                    $self->push_text($1);
                } elsif(/\G\x1B/gc) {
                    $log->debugf("Escape sequence: %s", sprintf '%v02x', substr $_, pos, 8);
                    $mode = ESC;
                } elsif(/\G\x09/gc) {
                    my $col = $self->find_next_tab;
                    $log->debugf("Tab - will move to %d", $col);
                    $self->{terminal_col} = $col;
                    $self->update_cursor;
                } else {
                    $log->debugf("No characters of interest found, must be text: %s", substr $_, pos() // 0, -1);
                    last BREAKOUT
                }
            } elsif($mode == ESC) {
                if(/\Gc/gc) {
                    $log->debug("ESC: Reset");
                    delete $self->{pen};
                    @{$self->{writable}} = ();
                    $self->{terminal_line} = 0;
                    $self->{terminal_col} = 0;
                    $self->update_cursor;
                    $mode = NORMAL;
                } elsif(/\GD/gc) {
                    $log->debug("ESC: Linefeed");
                    $mode = NORMAL;
                } elsif(/\GE/gc) {
                    $log->debug("ESC: Newline");
                    $mode = NORMAL;
                } elsif(/\GH/gc) {
                    $log->debug("ESC: Set tab stop");
                    @{$self->{tab_stops}} = sort { $a <=> $b } @{$self->{tab_stops} ||= []}, $self->terminal_col;
                    $log->debugf("Tab stops now: %s", join ',', @{$self->{tab_stops}});
                    $mode = NORMAL;
                } elsif(/\GM/gc) {
                    $log->debug("ESC: Reverse line feed");
                    $mode = NORMAL;
                } elsif(/\GZ/gc) {
                    $log->debug("ESC: DEC ident");
                    $mode = NORMAL;
                } elsif(/\G\[/gc) {
                    $log->debug("ESC: CSI");
                    $mode = CSI;
                } elsif(/\G7/gc) {
                    $log->debug("ESC: DECSC");
                    $self->push_state;
                    $mode = NORMAL;
                } elsif(/\G8/gc) {
                    $log->debug("ESC: DECSC");
                    $self->pop_state;
                    $mode = NORMAL;
                } elsif(/\G\(([B0UK])/gc) {
                    $log->debugf("ESC: G0 charset %s", $1);
                    $mode = NORMAL;
                } else {
                    $log->debugf("Some other ESC thing: %s", substr $_, pos() // 0, 1);
                    $mode = NORMAL;
                }
            } elsif($mode == CSI) {
                if(/\G\??([\d;]*)(.)/gc) {
                    my ($action) = $2;
                    my @param = split /;/, $1;
                    $log->debugf("CSI: %s with %d parameters: %s", $action, 0 + @param, join ',', @param);
                    if(my $code = $self->csi_map($action)) {
                        $code->(@param);
                    } else {
                        $log->debugf("Unknown CSI action %s, had parameters: %s", $action, join ',', @param);
                    }
                    $mode = NORMAL;
                } else {
                    $log->debugf("We are unknown CSI! %s (%s)", substr($_, pos()//0, 8), sprintf '%v02x', substr($_, pos()//0, 8));
                    $mode = NORMAL;
                }
            }
        }
    }
    my $data = substr $$buf, 0, length($$buf), '';
#   push @{$self->{writable}}, split /\n/, $data;
    $self->redraw;
    length $$buf;
}

=head2 find_next_tab

Returns the next tab stop after our current position.

=cut

sub find_next_tab {
    my ($self) = @_;
    for(@{$self->{tab_stops} ||= []}) {
        return $_ if $_ > $self->terminal_col;
    }
    return $self->terminal_cols - 1;
}

sub terminal_cols { shift->cols }

=head2 push_state

Stores current state, including things like colours.

=cut

sub push_state {
    my ($self) = @_;
    push @{$self->{dec_state}}, {
        pen => $self->pen->as_mutable,
        line => $self->terminal_line,
        col => $self->terminal_col
    };
    $self
}

=head2 pop_state

Restores the previous state.

=cut

sub pop_state {
    my ($self) = @_;
    return $self unless my $state = pop @{$self->{dec_state}};
    my $pen = $state->{pen};
    $self->{pen} = $pen->mutable ? $pen : $pen->as_mutable;
    $self->{terminal_line} = $state->{line};
    $self->{terminal_col} = $state->{col};
    $self->update_cursor;
    $self
}

=head2 terminal_line

Which line the terminal thinks it's on. Usually zero-based.

=cut

sub terminal_line { $_[0]->{terminal_line} //= 0 }

=head2 terminal_col

Which column the terminal thinks it's on. Also zero-based.

=cut

sub terminal_col { $_[0]->{terminal_col} //= 0 }

=head2 push_text

Takes some text characters and puts them into the write operation queue.

=cut

sub push_text {
    my ($self, $txt) = @_;
    for($txt) {
        if(/\G\n/gc) {
            $self->terminal_next_line
        } elsif(/\G([[:print:]]+)/ugc) {
            my $chunk = $1;
            push @{$self->{writable}}, {
                text => $chunk,
                line => $self->terminal_line,
                col  => $self->terminal_col,
                pen  => $self->pen->as_immutable,
            };
            $self->{terminal_col} += textwidth $chunk;
        } else {
            $log->warnf("Unknown thing in text: %s", substr $_, pos()//0);
        }
    }
    $self->update_cursor;
}

=head2 available_lines

Guesses how many lines we have.

=cut

sub available_lines {
    my ($self) = @_;
    return $self->lines unless my $win = $self->window;
    $win->lines
}

=head2 available_cols

Does the same for columns.

=cut

sub available_cols {
    my ($self) = @_;
    return $self->cols unless my $win = $self->window;
    $win->cols
}

=head2 terminal_next_line

Moves to the next line - if we're at the end of the screen then it'll attempt to scroll.

=cut

sub terminal_next_line {
    my ($self) = @_;
    $self->{terminal_col} = 0;
    if(++$self->{terminal_line} >= $self->available_lines) {
        $log->infof("Scrolling required, line = %d", $self->terminal_line);
        $self->scroll(-1, 0);
    }
    $self->update_cursor
}

=head2 scroll

Does some sort of scrolling.

=cut

sub scroll {
    my ($self, $down, $right) = @_;
    my $win = $self->window or die 'no window, no scroll';
    $win->scroll($down, $right);
    # Move things around a bit
    for my $item (@{$self->{writable}}) {
        $item->{rect}->translate($down, $right) if $item->{rect};
        $item->{line} += $down if exists $item->{line};
        $item->{col} += $right if exists $item->{col};
    }
    # then throw away the bits that no longer fit
    extract_by {
        return 1 if exists $_->{rect} && !$_->{rect}->intersect($win->selfrect);
        return 1 if exists $_->{line} && $_->{line} < 0;
        0
    } @{$self->{writable}};
    $self->{terminal_line} += $down;
    $self->{terminal_col} += $right;
    $self->redraw;
}

=head2 update_cursor

Moves the window cursor to the terminal cursor position.

You might be wondering why there are two cursors - that's possibly due to the misguided notion
that this code should be able to run the PTY quietly in the background even when we have no window.

=cut

sub update_cursor {
    my ($self) = @_;
    return unless my $win = $self->window;
    $win->cursor_at($self->terminal_line, $self->terminal_col);
}


1;

__END__

=head1 SEE ALSO

=over 4

=item * libvterm - if I had the patience for C, I would have started with bindings to this

=item * L<http://invisible-island.net/xterm/xterm.html> - xterm docs

=item * L<console_codes(4)> - Linux console terminal codes

=item * screen, tmux, term.js - they're probably doing it properly. If I wasn't on a plane
while writing this, that's the source code I'd be reading first.

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2015-2017. Licensed under the same terms as Perl itself.

