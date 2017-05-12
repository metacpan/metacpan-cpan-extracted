package Worlogog::Restart;

use warnings;
use strict;

our $VERSION = '0.03';

use Carp qw(croak);
use Scope::OnExit::Wrap qw(on_scope_exit);
use Return::MultiLevel qw(with_return);

use parent 'Exporter::Tiny';
our @EXPORT_OK = qw(
    case
    bind
    invoke
    find
    compute
);

our @restarts;

sub bind (&$) {
    my ($body, $handlers) = @_;
    my $limit = @restarts;
    my $guard = on_scope_exit { splice @restarts, $limit };
    push @restarts, \%$handlers;
    $body->()
}

sub case (&$) {
    my ($body, $handlers) = @_;
    my $limit = @restarts;
    my $guard = on_scope_exit { splice @restarts, $limit };
    my $wantlist = wantarray;
    my @v = with_return {
        my ($return) = @_;
        push @restarts, {
            map {
                my $v = $handlers->{$_};
                $_ => sub { $return->($v, @_) }
            } keys %$handlers
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

sub _find {
    my ($k) = @_;
    for my $rs (reverse @restarts) {
        my $v = $rs->{$k};
        return $v if $v;
    }
    undef
}

sub invoke {
    my $proto = shift;
    my $code = ref $proto ? $proto->code : _find($proto) || croak qq{No restart named "$proto" is active};
    $code->(@_)
}

sub find {
    my ($name) = @_;
    my $code = _find($name) or return undef;
    require Worlogog::Restart::Restart;
    Worlogog::Restart::Restart->new(
        name => $name,
        code => $code,
    )
}

sub compute {
    my @r;
    for my $rs (reverse @restarts) {
        for my $k (sort keys %$rs) {
            my $v = $rs->{$k};
            require Worlogog::Restart::Restart;
            push @r, Worlogog::Restart::Restart->new(
                name => $k,
                code => $v,
            );
        }
    }
    @r
}

'ok'

__END__

=head1 NAME

Worlogog::Restart - Lisp-style dynamic restarts

=head1 SYNOPSIS

  use Worlogog::Restart -all => { -prefix => 'restart_' };
  
  my $x = restart_case {
    restart_invoke 'foo', 21;
    die;  # not reached
  } {
    foo => sub {
      return $_[0] * 2;
    },
  };
  print "$x\n";  # 42

  my $y = restart_bind {
    my $x = restart_invoke 'bar', 20;
    return $x + 2;
  } {
    bar => sub {
      return $_[0] * 2;
    },
  };
  print "$y\n";  # 42

=head1 DESCRIPTION

This module provides dynamic restarts similar to those found in Common Lisp. A
restart is a bit like an exception handler or a dynamically scoped function. It
can be invoked (by name) from any subroutine call depth as long as the restart
is active.

=head2 Functions

The following functions are available:

=over

=item invoke RESTART

=item invoke RESTART, ARGUMENTS

Invokes I<RESTART>, passing it I<ARGUMENTS> (if any) in C<@_>. Returns whatever
I<RESTART> returns (provided it returns normally, which restarts established by
C<case> never do).

I<RESTART> can be either a restart object (such as those returned by C<find> or
C<compute>) or a restart name (a string). Names are looked up dynamically by
searching outwards through all handlers established by C<bind> or C<case>. If
no matching restart is found, this is an error and C<invoke> L<C<die>s|perlfunc/die>.

=item bind BLOCK HASHREF

Executes I<BLOCK> with the restarts specified by I<HASHREF>, which maps
restart names (strings) to handlers (subroutine references). Returns whatever
I<BLOCK> returns.

=item case BLOCK HASHREF

Executes I<BLOCK> with the restarts specified by I<HASHREF>, which maps
restarts names (strings) to handlers (subroutine references). Returns whatever
I<BLOCK> returns (or what the corresponding restart returns if C<invoke> is
used to return from C<case>).

Unlike C<bind>, the restarts it establishes always unwind the stack first
before running and thus ultimately return from C<case> itself, not from
C<invoke>. That is, a restart established by C<case> will implicitly return
from all subroutines between C<case> and C<invoke>, then execute the handler
body specified in I<HASHREF>, then return from C<case>.

=item find RESTART

Finds the restart that would be called by C<invoke> at this point. Returns a
restart object representing the restart or C<undef> if no corresponding restart
is active. I<RESTART> must be a name (string).

Restart objects returned by C<find> have the following methods:

=over

=item $restart->name

Returns the name of the restart.

=item $restart->code

Returns the subroutine reference of the restart handler.

=back

=item compute

Searches outwards and returns a list of restart objects representing all
currently active restarts. The innermost restarts will be listed first.

The returned list may contain restarts that you can't normally invoke because
they're shadowed by a more recent restart with the same name:

  # prints "9" because the innermost 'foo' is listed first
  print bind {
    bind {
      my @restarts = compute;
      #
      # $restarts[0]->name = 'foo'
      # $restarts[0]->code = sub { $_[0] + 2 }
      #
      # $restarts[1]->name = 'foo'
      # $restarts[1]->code = sub { $_[0] * 3 }
  
      my $x = 1;
      $x = invoke($_, $x) for @restarts;
      # $x = $x + 2
      # $x = $x * 3
  
      $x
    } {
      foo => sub { $_[0] + 2 },
    };
  } {
    foo => sub { $_[0] * 3 },
  };

=back

This module uses L<C<Exporter::Tiny>|Exporter::Tiny>, so you can rename the
imported functions at L<C<use>|perlfunc/use> time.

=head1 SEE ALSO

L<Exporter::Tiny>, L<Return::MultiLevel>

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013, 2014 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
