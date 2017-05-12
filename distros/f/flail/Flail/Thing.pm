=pod

=head1 NAME

Flail::Thing - A structured thing

=head1 VERSION

  Time-stamp: <2006-12-01 16:35:16 attila@stalphonsos.com>
  $Id: Thing.pm,v 1.3 2006/04/26 03:52:03 attila Exp $

=head1 SYNOPSIS

  package Something;
  use base qw(Flail::Thing);
  sub _struct {
      return shift->SUPER::_struct,
              ( my_field_1 => default_value,
                my_field_2 => default_value, );
  }

  package main;
  my $obj = Something->new(my_field_1 => 1, my_field_2 => 'blah');
  print $obj->as_string."\n";  ## can turn them into strings
  print $obj->my_field_2."\n"; ## print the value of a field
  $obj->my_field_1(3);         ## set my_field_1 to 3

  sub terlet {
    my($obj,@changes) = @_;
    while (@changes) {
      my($name,$val) = splice(@changes,0,2);
      print "$obj $name => $val\n";
    }
    return undef;
  }

  $obj->FLUSH(\&terlet);      ## will be called with: my_field_1 => 3

=head1 DESCRIPTION

This is a generic thing.  It has slots.  Slots can contain other
things, but swizzling and unswizzling don't happen automagically.

It is derived from a class I wrote a long time ago called just plain
old Thing.  I am pulling it into Flail starting in version 0.2.0.

Things can have options.  Options are not slots, they are used to
specify optional attributes of an object regardless of its particular
structure or behavior.  For instance, the C<autoflush> attribute can
be used to tell the C<DESTROY> method in C<Thing> whether or not to
flush changes to an object that is being garbage-collected by the Perl
interpreter.

=cut

package Flail::Thing;
use strict;
use Carp;
require Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT $AUTOLOAD $MAX_DEPTH);
@ISA = qw(Exporter);
@EXPORT_OK = qw();
@EXPORT = qw();
%EXPORT = ( all => [ @EXPORT_OK ] );

sub DESTROY {
    my $self = shift(@_);
    if ($self->OPTION('autoflush') && defined($self->OPTION('flusher'))) {
        $self->FLUSH(undef);
    }
#+D     print STDERR "# Thing DESTROYed: ".$self->as_string."\n"; #+D
    undef;
}

sub AUTOLOAD {
    my $self = shift(@_);
    my $type = ref($self) or Carp::confess(qq{$self is not an object});
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    my $result = undef;
    if (!exists($self->{__Valid}->{$name})) {
        Carp::croak(qq{Invalid attribute "$name" in a $type object: $self});
    } else {
        $result = $self->{$name};
        if (@_) {
            my $new = shift(@_);
            Carp::croak(qq{Too many arguments to "$name" for $type $self: @_})
                  if @_;
            $self->{$name} = $new;
            ++$self->{__Dirty}->{$name};
            ++$self->{__NDirty};
        }
    }
    return $result;
}

sub _struct {
    return ( );
}

sub _is_dirty {
    return shift->{__NDirty};
}

sub _dirty_slots {
    my $self = shift(@_);
    my @dirt =
        map { $_ => $self->{$_} }
            grep { $self->{__Dirty}->{$_}? 1: 0 } @{$self->{__Order}}
                if $self->_is_dirty;
    return @dirt;
}

sub _sanitize {
    my $self = shift(@_);
    $self->{__Dirty} = {};
    $self->{__NDirty} = 0;
    return $self;
}

$MAX_DEPTH = 10;

sub _as_string1 {
    my($self,$slot) = @_;
    return $self->{$slot};
}

sub _as_string {
    my($self,$depth) = @_;
    return sprintf(q{ ?%d?}, $depth) if $depth > $MAX_DEPTH;
    return join("",
                map {
                    my $v = eval q{$self->}.$_; # PPP
                    my $tmp = undef;
                    if (!defined($v)) {
                        $tmp = 'undef';
                    } elsif (ref($v)) {
                        eval {
                            $tmp = $self->_as_string1($_);
                        };
                        $tmp ||= "$v";
                    }
                    $tmp ||= qq{"$v"};
                    my $n = $_;
                    if ($self->{__Dirty}->{$_}) {
                        $n = '*' . $_;
                    }
                    qq{ $n=$tmp};
                } @{$self->{__Order}});
}

=pod

=head2 as_string()

Return a human-readable string that represents this object.

=cut

sub as_string {
    my $self = shift(@_);
    my $depth = shift(@_) || 1;
    my $type = ref($self);
    $type =~ s/.*:://;
    my $str = "<$self(".$self->{__NDirty}."):";
    $str .= $self->_as_string($depth);
    $str .= ">";
    return $str;
}

sub _eval {
    return undef;
}

=pod

=head2 eval ...

Perform some arbitrary "evaluation" function as per the semantics of
the object.

=cut

sub eval {
    my $self = shift(@_);
    return $self->_eval(@_);
}

sub _FLUSH {
    return undef;
}

=pod

=head2 FLUSH $callback,@args

Invoke the callback function with C<$self>, and one C<$attr> =>
C<$val> pair.  Each invocation represents one state change that has
not yet been stored presistently.  The callback's job is to store this
state change, in whatever way makes sense for the object.

=cut

sub FLUSH {
    my $self = shift(@_);
    my $callback = shift(@_);
    my @args = @_;
    if (!defined($callback)) {
        $callback = $self->OPTION('flusher');
        if (defined($callback)) {
            my $cbargs = $self->OPTION('flusher_closure');
            push(@args, @$cbargs) if ref($cbargs) eq 'ARRAY';
        }
    }
    Carp::confess(qq{Bad arguments to FLUSH: @args}) if @args & 1;
    return undef unless $self->_is_dirty();
    my @changes = $self->_dirty_slots();
    my $result = 0;
    if (defined($callback) && !ref($callback)) {
        $result = eval q{$self->}.$callback.q{(@changes, @args)}; # PPP
    } elsif (ref($callback) eq 'CODE') {
        $result = &$callback($self, @changes, @args);
    } elsif (!defined($callback)) {
        $result = $callback->_FLUSH(@changes, @args);
    } else {
        Carp::confess(qq{FLUSH invoked with no possible callback});
    }
    $self->_sanitize() unless $result != 0;
    return $result;
}

sub _LOAD {
    return undef;
}

=pod

=head2 LOAD $callback,@args...

Invoked to load state from whatever persistent store this object uses.
We are passed a list of slots that are missing.

=cut

sub LOAD {
    my $self = shift(@_);
    my $callback = shift(@_);
    my @args = @_;
    if (!defined($callback)) {
        $callback = $self->OPTION('loader');
        if (defined($callback)) {
            my $cbargs = $self->OPTION('loader_closure');
            push(@args, @$cbargs) if ref($cbargs) eq 'ARRAY';
        }
    }
    unless (@args) {
        Carp::croak(qq{No arguments given to LOAD});
        return undef;
    }
    my $result = 0;
    if (defined($callback) && !ref($callback)) {
        $result = eval q{$self->}.$callback.q{(@args)}; # PPP
    } elsif (ref($callback) eq 'CODE') {
        $result = &$callback($self, @args);
    } elsif (!defined($callback)) {
        $result = $self->_LOAD(@args);
    } else {
        Carp::confess(qq{LOAD invoked with no possible callback});
    }
    $self->_sanitize() unless $result != 0;
    return $result;
}

=pod

=head2 OPTION $opt => $newval

Check optional attributes for this object, or set them.

=cut

sub OPTION {
    my($self,$opt,$newval) = @_;
    my $rez = $self->{__Options}->{$opt} if exists $self->{__Options}->{$opt};
    $self->{__Options}->{$opt} = $newval if @_ == 3;
    return $rez;
}

sub _init_new {
    my $self = shift(@_);
    my @args = @_;
    $self->{__Valid} = {};
    $self->{__Dirty} = {};
    $self->{__NDirty} = 0;
    $self->{__Required} = {};
    $self->{__Order} = [];
    $self->{__Options} = { };
    my @struct = $self->_struct();
    Carp::confess(qq{Malformed object structure: @struct})
          if @struct & 1;
    while (@struct) {
        my($name,$init) = splice(@struct,0,2);
        Carp::croak(qq{Multiple definitions for "$name" ($init)})
              if exists($self->{$name});
        Carp::confess(qq{Invalid name "$name" ($init)})
              if $name =~ /^__/;
#+D         warn "# struct: $name = $init\n"; #+D
        $self->{__Dirty}->{$name} = 0;
        push(@{$self->{__Order}}, $name);
        $self->{__Required}->{$name} = !defined($init);
        $self->{__Valid}->{$name} = 1;
        $self->{$name} = $init;
    }
    if (@args) {
        Carp::croak(qq{Malformed constructor invocation: @args})
              if @struct & 1;
        while (@args) {
            my($name,$init) = splice(@args,0,2);
            if ($name =~ /^-+(\S+)$/) {
                $self->{__Options}->{$1} = $init;
            } else {
                Carp::croak(qq{Invalid slot "$name" in constructor ($init)})
                      unless defined($self->{__Valid}->{$name});
                $self->{$name} = $init;
            }
        }
    }
    my @reqd = keys(%{$self->{__Required}});
    if (@reqd) {
        my $type = ref($self);
        my @missing =
            grep { !exists($self->{$_}) } keys(%{$self->{__Required}});
        if (@missing && !defined($self->OPTION('loader'))) {
            Carp::croak(qq{A new $type is missing required slots: @missing});
        } elsif (@missing) {
            $self->LOAD(undef,@missing);
        }
    }
    return $self;
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    $proto = {} unless ref($proto);
    bless($proto, $class);
    return $proto->_init_new(@_);
}

1;

__END__

=pod

=head1 AUTHOR

Sean Levy <snl@cluefactory.com>

=head1 COPYRIGHT AND LICENSE

(C) 2002-2006 by Sean Levy <snl@cluefactory.com>.  all rights reserved.

This code is released under a BSD license.  Please see the LICENSE
file that came with the source distribution or visit
L<http://flail.org/LICENSE>

=cut

##
# Local variables:
# mode: perl
# tab-width: 4
# perl-indent-level: 4
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# indent-tabs-mode: nil
# comment-column: 40
# time-stamp-line-limit: 40
# End:
##
