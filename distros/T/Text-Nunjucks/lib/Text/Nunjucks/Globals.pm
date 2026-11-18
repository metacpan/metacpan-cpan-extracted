package Text::Nunjucks::Globals;
# ABSTRACT: 1:1 port of Nunjucks src/globals.js -- the built-in global functions

our $VERSION = '0.001';

use strict;
use warnings;
use builtin qw( true false );
use Scalar::Util qw( weaken );
use Text::Nunjucks::Runtime;

no warnings 'experimental::builtin';

# globals.js defines two helpers, cycler and joiner, and exports globals(), a
# function that builds a fresh { range, cycler, joiner } bag on every call, so
# each Environment owns its copy (environment.js: this.globals = globals()).
# The port keeps the three functions, in upstream's order, as class methods
# dispatched through $self, like Filters and Tests; `globals` returns a fresh
# plain hashref, the bag Environment.init stores and add_global writes into.
# range's body stays inline in that bag, where upstream defines it.
#
# A global is called the way call_wrap calls any function (ADR 0009): with the
# template's arguments, keyword arguments as a trailing KwArgs hashref, and no
# `this`. JS operators -- range's <, >, += and !step, joiner's || -- go through
# Runtime (ADR 0001 kinds, ADR 0006 null, ADR 0007 numbers): range('3') counts
# 0, 1, 2 and range('3', 5) is ['3'] ('3' + 1 is '31').
#
# The cycler is a plain JS object with own properties current, reset and next.
# The port builds it with Runtime make_dict, the engine-built object of ADR 0011,
# so it iterates in upstream's order (current;reset;next;), dumps as
# {"current":null}, prints [object Object] and is a mapping. Its methods read
# and write this.current. Here they close over the object instead -- the interim
# choice while decision k93 is open (ADR 0009's no-`this` covers user coderefs
# only). Upstream's memberLookup binds `this` to the cycler on every member read
# (cls.next() and a cls.next read and called later), which is where the two
# agree. They differ for a method reached without memberLookup -- e.g.
# `{% for k, v in cls %}` then `v()`, which upstream calls with the Context as
# `this` (oracle: the cycler's current stays null there; here it moves); k93
# lists the paths. The closures hold a weakened copy of the object, which holds them, so
# the pair is no reference cycle; once the object is gone nothing can read its
# current, and next() still steps through the items.

sub _runtime { 'Text::Nunjucks::Runtime' }

#### cycler

sub cycler {
  my ( $self, $items ) = @_;
  my $rt    = $self->_runtime;
  my $index = -1;
  my $this;    # the object returned below, weakened (see the header)

  my $obj = $rt->make_dict(
    current => $rt->None,
    reset   => sub {
      $index = -1;
      $this->set( current => $rt->None ) if $this;
      return undef;
    },

    next => sub {
      $index++;
      if ( $index >= scalar @$items ) {
        $index = 0;
      }

      # this.current = items[index]; return this.current;
      my $current = $items->[$index];
      $this->set( current => $current ) if $this;
      return $current;
    },
  );
  weaken( $this = $obj );
  return $obj;
}

#### joiner

sub joiner {
  my ( $self, $sep ) = @_;
  $sep = $self->_runtime->op_or( $sep, ',' );
  my $first = true;

  return sub {
    my $val = $first ? '' : $sep;
    $first = false;
    return $val;
  };
}

#### globals

# Making this a function instead so it returns a new object
# each time it's called. That way, if something like an environment
# uses it, they will each have their own copy.
sub globals {
  my ($self) = @_;
  my $rt = $self->_runtime;
  return {
    range => sub {
      my ( $start, $stop, $step ) = @_;
      if ( !defined($stop) ) {    # typeof stop === 'undefined'
        $stop  = $start;
        $start = 0;
        $step  = 1;
      }
      elsif ( $rt->_falsy($step) ) {
        $step = 1;
      }

      my $arr = [];
      if ( $rt->op_gt( $step, 0 ) ) {
        for ( my $i = $start; $rt->op_lt( $i, $stop ); $i = $rt->op_add( $i, $step ) ) {
          push @$arr, $i;
        }
      }
      else {
        for ( my $i = $start; $rt->op_gt( $i, $stop ); $i = $rt->op_add( $i, $step ) ) {
          push @$arr, $i;
        }
      }
      return $arr;
    },

    cycler => sub {
      return $self->cycler( [@_] );    # Array.prototype.slice.call(arguments)
    },

    joiner => sub {
      my ($sep) = @_;
      return $self->joiner($sep);
    },
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Globals - 1:1 port of Nunjucks src/globals.js -- the built-in global functions

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A 1:1 port of Nunjucks C<src/globals.js>: the built-in global functions C<range>,
C<cycler> and C<joiner>. C<globals> returns a fresh hash of them for each
Environment. To add a global use C<add_global> of
L<Text::Nunjucks::Environment>.

Engine-internal: used by L<Text::Nunjucks::Environment> and the code the compiler emits, and
not an interface for applications.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-text-nunjucks/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
