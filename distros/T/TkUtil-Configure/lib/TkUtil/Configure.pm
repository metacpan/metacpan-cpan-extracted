package TkUtil::Configure;

use warnings;
use strict;
use Perl6::Attributes;
use Time::HiRes qw(gettimeofday);

=head1 NAME

TkUtil::Configure - Trap and act on Tk <Configure> events

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Fairly intelligent trapping of <Configure> events within Perl/Tk.

    use TkUtil::Configure;

    my $conf = TkUtil::Configure->new(top => $mw, callback => ??);

All you currently have is the constructor, because that's all that
is needed. See below for additional information.

=head1 DESCRIPTION

In Perl/Tk programming, you often want to bind to the <Configure> event
so that you can elegantly resize your internal windows when the main
window is resized.

The problem is that a simple resize can generate hundreds of resize
events. And if the job you must do in a window is complex or time
consuming, handling all of these events can be problematic.

That's what this class was written for... to bind the <Configure>
event, and deal with all of the incoming events in a reasonable fashion,
and only call your callback function(s) when we think the user is
done.

The callback function(s) are where you do the necessary redrawing of
the window(s), of course.

This was written (and made available) because too many people struggle
with this issue (me included). Most people simply give up and don't
allow (or deal with) resize at all, because the issue is such a problem. 
Enjoy.

=head1 AUTHOR

X Cramps, C<< <cramps.the at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tkutil-configure at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TkUtil-Configure>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TkUtil::Configure

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TkUtil-Configure>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TkUtil-Configure>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TkUtil-Configure>

=item * Search CPAN

L<http://search.cpan.org/dist/TkUtil-Configure/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 X Cramps, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

our $Class;

=head2 B<new>

  $conf = TkUtil::Configure->new(top => ??, callback => ??, %opts);

%opts can be:

  on      - provide a widget id to trigger the callback for [1]
  timeout - amount of time before a callback is generated (in msec) [2]

I<top> is the toplevel widget upon which to bind the <Configure>
event.

Note that both I<on> and I<callback> can be array references. You can
have multiple widgets specified in I<on> and only a single I<callback>
if you like (since the first argument to the callback is the widget,
the callback can behave differently based upon it).

    [1] callback is called when the top widget is configured (resized). It
    is called with the widget id and the new width and height of the 
    widget under 
    consideration (I<on>). I<on> is the widget id to trigger this
    particular callback for.

    [2] when a widget is resized, we get LOTS of <Configure> events.
    Even with fast computers, you can overload with events if
    you need to do something complex when the user resizes. The
    timeout allows you to build up events until the last event
    was I<timeout> msec ago, and only then trigger a callback.
    The default is 500 msec (1/2 second). Your callback won't
    be called unless I<timeout> msec has elapsed from the last
    <Configure> event.

=cut

sub new {
    my $class = shift;
    $Class = $class;
    my (%opts) = @_;
    my $self = \%opts;
    bless $self, $class;
    $.timeout = 500 unless defined $.timeout;
    $.Pending = 0;
    ./_required('top');
    ./_required('callback');
    $.on = $.top unless defined $.on;
    $.widgets = {};

    # ensure that if both on and callback are array ref's, they
    # have same # of elements
    if (ref($.callback) eq 'ARRAY' && ref($.on) eq 'ARRAY') {
        die "$class - need same number of things in callback and on\n"
            unless @.callback == @.on;
    }

    # many callbacks and a single on => call all callbacks for same
    # widget
    if (ref($.callback) eq 'ARRAY' && ref($.on) ne 'ARRAY') {
        my $n = @{$.callback};
        my @on;
        push(@on, $.on) foreach 1..$n;
        $.on = \@on;
    }

    # one on and a single callback => same callback for all widgets
    if (ref($.on) eq 'ARRAY' && ref($.callback) ne 'ARRAY') {
        my $n = @{$.on};
        my @callback;
        push(@callback, $.callback) foreach 1..$n;
        $.callback = \@callback;
    }

    # ensure both on and callback are arrays
    if (ref($.on) ne 'ARRAY') {
        $.on = [$.on];
    }

    if (ref($.callback) ne 'ARRAY') {
        $.callback = [$.callback];
    }

    # make hashes of the dual on/callback arrays
    my %on;
    for (my $i=0; $i < @{$.on}; $i++) {
        $on{$.on[$i]} = $.callback[$i];
        $.widgets{$.on[$i]} = $.on[$i];
    }

    $.on = \%on;

    # cleanly initialize
    $.events = [];
    ./_init();
    return $self;
}

# test for required args
sub _required {
    my ($self, $name) = @_;
    die "$Class - $name must be defined\n" unless defined $self->{$name};
}

# set things up for binding to <Configure>
sub _init {
    my ($self) = @_;
    my @events = @{$.events};
    $.top->bind('<Configure>',
        sub {
            my ($W, @args) = @_;
            my $event = $W->XEvent;
            return unless defined $event;
            return unless defined $.on && defined $.on{$W};
            my ($w, $h) = ($event->w, $event->h);
            my $t = ./_t();
            push(@{$.events}, [$w, $h, $t]);
            # only trigger timer if one isn't already pending
            if ($.Pending == 0) {
                $.Pending = 1;
                my $timerProc;
                $timerProc = 
                    sub {
                        my ($timeout) = @_;
                        $.top->after($timeout,
                            sub {
                                my @events =  @{$.events};
                                my $t = ./_t();
                                $.Pending = 0;
                                if (@events) {
                                    my $n = $#events;
                                    # get most recent width/height
                                    my $w = $events[$n]->[0];
                                    my $h = $events[$n]->[1];
                                    my $dt = $t - $events[$n]->[2];
                                    #print "dt = $dt, timeout $timeout\n";
                                    if ($dt > $timeout/1000) {
                                        $.culled = scalar(@events);
                                        foreach my $widget (keys(%{$.on})) {
                                            my $ow = $.widgets{$widget};
                                            $w = $ow->width;
                                            $h = $ow->height;
                                            $.on{$widget}->($ow, $w, $h);
                                        }
                                        $.events = [];
                                    }
                                    else {
                                        $.Pending = 1;
                                        $timerProc->($timeout);
                                    }
                                }
                            }
                        );
                    };
                $timerProc->($.timeout);
            }
        }
    );

}

=head2 B<culled>

  $conf->culled();

Find how many events were culled for you.

=cut

sub culled {
    my ($self) = @_;
    return $.culled;
}

sub _t {
    my ($seconds, $microseconds) = gettimeofday;
    my $t = $seconds + $microseconds/1000000;
    return $t;
}
1; # End of TkUtil::Configure
