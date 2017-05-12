package Worlogog::Incident;

use warnings;
use strict;

our $VERSION = '0.02';

use Carp qw(carp);
use Scope::OnExit::Wrap qw(on_scope_exit);
use Return::MultiLevel qw(with_return);
use Worlogog::Restart;
use Dispatch::Class qw(dispatch class_case);

use parent 'Exporter::Tiny';

our @EXPORT_OK = qw(
    handler_bind
    handler_case
    report
    error
    cerror
    warn
);

#our @CARP_NOT = qw(Worlogog::Restart);

our @handlers;
our $barrier;


# hakurei

sub handler_bind (&$) {
    my ($body, $handler) = @_;
    my $limit = @handlers;
    my $guard = on_scope_exit { splice @handlers, $limit };
    if (ref($handler) eq 'ARRAY') {
        $handler = dispatch @$handler;
    }
    push @handlers, \&$handler;
    $body->()
}

sub handler_case (&$) {
    my ($body, $genhandler) = @_;
    my $limit = @handlers;
    my $guard = on_scope_exit { splice @handlers, $limit };
    if (ref($genhandler) eq 'ARRAY') {
        $genhandler = class_case @$genhandler;
    }
    $genhandler = \&$genhandler;
    my $wantlist = wantarray;
    my @v = with_return {
        my ($return) = @_;
        push @handlers, sub {
            my $handler = $genhandler->(@_) or return;
            $return->($handler, @_);
        };
        unless (defined $wantlist) {
            $body->();
            return;
        }
        undef, $wantlist ? $body->() : scalar $body->()
    };
    if (my $f = shift @v) {
        return $f->(@v);
    }
    $wantlist ? @v : $v[0]
}


# reimu

sub report {
    my ($incident) = @_;
    my $limit = defined $barrier ? $barrier : $#handlers;
    for my $i (reverse 0 .. $limit) {
        my $h = $handlers[$i];
        local $barrier = $i - 1;
        $h->($incident);
    }
}

sub error {
    my ($incident) = @_;
    report $incident;
    die $incident;
}

sub cerror {
    my ($incident) = @_;
    Worlogog::Restart::case {
        error $incident;
    } {
        continue => sub {},
    };
}

sub warn {
    my ($incident) = @_;
    Worlogog::Restart::case {
        report $incident;
        carp $incident;
    } {
        muffle_warning => sub {},
    };
}

'ok'

__END__

=head1 NAME

Worlogog::Incident - Lisp-style resumable exceptions (conditions)

=head1 SYNOPSIS

  use Worlogog::Incident -all => { -prefix => 'incident_' };
  use Worlogog::Restart  -all => { -prefix => 'restart_' };
  
  sub log_analyzer {
    incident_handler_bind {
      for my $log (find_all_logs()) {
        analyze_log($log);
      }
    } [
      'MalformedLogEntryError' => sub {
        restart_invoke 'skip_log_entry';  # ignore invalid log entries
        
        # we could also do this:
        #restart_invoke 'use_value' => MalformedLogEntry->new(text => $_[0]);  # use invalid log entries as-is
      },
    ];
  }
  
  sub analyze_log {
    my ($log) = @_;
    for my $entry (parse_log_file($log)) {
      analyze_entry($entry);
    }
  }
  
  sub parse_log_file {
    my ($file) = @_;
    open my $fh, '<', $file or die "$0: $file: $!\n";
    my @results;
    while (my $text = readline $fh) {
      chomp $text;
      my $entry = restart_case {
        parse_log_entry($text)
      } {
        skip_log_entry => sub { undef },
      };
      push @results, $entry if $entry;
    }
    @results
  }
  
  sub parse_log_entry {
    my ($text) = @_;
    if (is_well_formed_log_entry($text)) {
      return LogEntry->new(... $text ...);  # parsing details omitted
    }
    restart_case {
      incident_error MalformedLogEntryError->new(text => $text);
    } {
      use_value     => sub { $_[0] },
      reparse_entry => sub { parse_log_entry($_[0]) },
    }
  }

=head1 DESCRIPTION

This module provides resumable exceptions ("conditions") similar to those found
in Common Lisp. A condition is a bit like an exception where the exception
handler can decide to do other things than unwind the call stack and transfer
control to itself.

A note on naming: This module doesn't follow Common Lisp terminology (there are
I<conditions> and you can I<signal> them) because I think it would be
confusing: The controlling expressions in C<if> or C<while> are also called
conditions, and "signal" is more closely associated with
L<C<%SIG>|perlvar/%SIG> and L<C<kill>|perlfunc/kill>.

Instead I will refer to I<incidents>, which you can I<report>.

=head2 Functions

The following functions are available:

=over

=item handler_bind BLOCK CODEREF

=item handler_bind BLOCK ARRAYREF

Executes I<BLOCK> while registering the incident handler(s) speficied by
I<CODEREF> or I<ARRAYREF> (see below). If (during the execution of I<BLOCK>) an
incident is reported, the innermost registered handler is called with one
argument (the incident object).

An incident handler can either return normally, which causes the incident
machinery to call the next active handler on the stack, or abnormally, which
terminates the incident report. Abnormal returns are possible directly with
L<Return::MultiLevel> or indirectly via L<Worlogog::Restart>. That is, an
incident handler can abort an incident in progress by invoking a restart that
transfers control to an outer point in the running program.

If an I<ARRAYREF> is used, it is passed on to
L<C<dispatch> in C<Dispatch::Class>|Dispatch::Class/dispatch> (which see for
details) to assemble the incident handler. The format of the I<ARRAYREF> is
that of a dispatch table, i.e. a list of C<CLASS, CODEREF> pairs where I<CLASS>
specifies what class of exception objects should be handled (use the
pseudo-class C<:str> to match plain strings), and I<CODEREF> is the actual body
of the handler.

=item handler_case BLOCK CODEREF

=item handler_case BLOCK ARRAYREF

Similar to C<handler_bind> above. The main difference is that an incident
handler established by C<handler_case> has to decide up front whether to handle
the incident, and if it does, the stack is unwound first.

The way this is done depends on the second argument: If it's an I<ARRAYREF>,
the class of the incident object decides whether a handler (and which one) is
entered.

If it's a I<CODEREF>, it is called with the incident object as its first (and
only) argument. If the I<CODEREF> returns another coderef, that is taken to be the
handler (i.e. the stack is unwound, the returned (inner) coderef is called with
the incident object, and the return value of the inner coderef is returned from
C<handler_case>). If the I<CODEREF> returns undef, the search for an incident
handler that feels responsible continues outwards.

=item report INCIDENT

Reports an incident; i.e. it searches the call stack for all appropriate
incident handlers registered with C<handler_bind> or C<handler_case>. It calls
them in order from innermost (closest to the C<report> call) to outermost
(closest to the main program), then returns.

An incident handler can decline to handle a particular incident by returning
normally. Conversely, an incident handler can stop a report in progress by not
returning normally. This can be done by throwing an exception
(L<C<die>|perlfunc/die>), using a non-local return
(L<C<Return::MultiLevel>|Return::MultiLevel>), or invoking a restart that does
one of these things (L<C<Worlogog::Restart>|Worlogog::Restart>).

Incident handlers registered with C<handler_case> implicitly perform a
non-local return.

=item error INCIDENT

Reports I<INCIDENT>. If no handler takes over and handles the incident, throws
I<INCIDENT> as a normal Perl exception. Equivalent to:

  sub error {
    my ($incident) = @_;
    report $incident;
    die $incident;
  }

=item cerror INCIDENT

Works like C<error> with a L<restart|Worlogog::Restart> called C<'continue'>
wrapped around it:

  sub cerror {
    my ($incident) = @_;
    restart_case {
      error $incident;
    } {
      continue => sub {},
    };
  }

This way an incident handler can L<C<invoke>|Worlogog::Restart/invoke-RESTART>
C<'continue'> to prevent the exception that would normally occur from being
thrown.

=item warn INCIDENT

Reports I<INCIDENT>. If no handler takes over and handles the incident, outputs
I<INCIDENT> as a warning via L<C<Carp::carp>|Carp> unless the restart
C<'muffle_warning'> is invoked. Equivalent to:

  sub warn {
    my ($incident) = @_;
    restart_case {
      report $incident;
      carp $incident;
    } {
      muffle_warning => sub {},
    };
  }

=back

This module uses L<C<Exporter::Tiny>|Exporter::Tiny>, so you can rename the
imported functions at L<C<use>|perlfunc/use> time.

=head1 SEE ALSO

L<Exporter::Tiny>, L<Worlogog::Restart>, L<Return::MultiLevel>,
L<Dispatch::Class>

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013, 2014 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
