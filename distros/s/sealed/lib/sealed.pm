# SPDX License Identifier: Apache License 2.0
#
# provides ithread-safe :Sealed subroutine attributes: use with care!
#
# Author: Joe Schaefer <joe@sunstarsys.com>

package sealed;
use v5.28;

use strict;
use warnings;
use version;

use B::Generate ();
use B::Deparse  ();
use XSLoader ();
use Filter::Util::Call;

our $VERSION;
our $DEBUG;
our $VERIFY_PREFIX = "use Types::Common -types, -sigs;";

BEGIN {
  our $VERSION = qv(8.4.2);
  XSLoader::load("sealed", $VERSION);
}

my %valid_attrs                  = (sealed => 1);
my $p_obj                        = B::svref_2object(sub {&tweak}); # template sub

# B::PADOP (w/ ithreads) or B::SVOP
my $gv_op                        = $p_obj->START->next->next; # its op of interest

sub tweak :prototype($\@\@\@$$\%) {
  my ($op, $lexical_varnames, $pads, $op_stack, $cv_obj, $pad_names, $processed_op) = @_;
  my $tweaked                    = 0;

  if (${$op->next} and $op->next->name eq "padsv") {
    $op                          = $op->next;
    my $type                     = $$lexical_varnames[$op->targ]->TYPE;
    my $class                    = $type->isa("B::HV") ? $type->NAME : undef;

    while (${$op->next} and $op->next->name ne "entersub") {

      if ($op->next->name eq "pushmark") {
        return $op->next, $tweaked if $$processed_op{+${$op->next}}++;
	# we need to process this arg stack recursively
	splice @_, 0, 1, $op->next;
        ($op, my $t)             = &tweak;
        $tweaked                += $t;
        $op                      = $_[0]->next unless $$op and ${$op->next};
      }

      elsif ($op->next->name eq "method_named" and defined $class) {
        my $methop               = $op->next;

        my ($method_name, $idx, $targ, $gv, $old_pad);

        if (ref($gv_op) eq "B::PADOP") {
          $targ                  = $methop->targ;

          # A little prayer
          # Not sure if this works better pre-ithread cloning, or post-ithread cloning.
          # I've only used it post-ithread cloning, so YMMV.
          # $targ collisions? ordering is a WAG with the @op_stack walker down below.

          $method_name           = $$pads[$idx++][$targ] until defined $method_name and not
            (ref $method_name and warn __PACKAGE__ . ": target collision: targ=$targ");
        }
        else {
          $method_name           = ${$methop->meth_sv->object_2svref};
        }

        warn __PACKAGE__, ": compiling $class->$method_name lookup.\n"
          if $DEBUG;
        my $method               = $class->can($method_name)
          or die __PACKAGE__ . ": invalid lookup: $class->$method_name - did you " .
          "forget to 'use $class' first?\n";

        no warnings 'uninitialized';

        my $mverify = sub {
          goto &$method if $method == $_[0]->can($method_name);
          require Carp;
          $$pads[$idx][$targ] =~ s/:\w+$/:FAILED/ if ref($gv_op) eq "B::PADOP";
          ${$methop->meth_sv->object_2svref} =~ s/:\w+$/:FAILED/
            if ref($gv_op) ne "B::PADOP";
          local $@;
          eval {warn "sub ", $cv_obj->GV->NAME // "__UNKNOWN__", " :sealed ",
                  B::Deparse->new->coderef2text($cv_obj->object_2svref), "\n"};
          Carp::confess ("sealed verify failed: $_[0]->$method_name method lookup differs " .
                         "from $class->$method_name:FAILED lookup");
        };

        # replace $methop
        # in the ithread case, we need to pass an arbitrary typegglob that we will "fix"
        # in the next conditional block. we choose *tweak arbitrarily for this end.
        # the non-ithreaded case needs no additional massaging, so we pass a CodeRef.
        $gv                      = new($gv_op->name, $gv_op->flags,
                                       ref($gv_op) eq "B::PADOP" ? *tweak :
                                       $DEBUG eq "verify" ? $mverify : $method,
                                       $cv_obj->PADLIST);
        $gv->next($methop->next);
        $gv->sibparent($methop->sibparent);
        $op->next($gv);
        $$processed_op{$$_}++ for $op, $gv, $methop;

        no warnings 'uninitialized';

        if (ref($gv) eq "B::PADOP") {
          # we answer the prayer by resetting $$pads[--$idx][$gv->padix], which
          # has the correct semantics (for $method) under assignment.

          my $padix = $gv->padix;
          my (undef, @p)         = $cv_obj->PADLIST->ARRAY; # new() modified PADLIST
          $pads = [ map defined ? $_->object_2svref : $_, @p ];
          $$pads[--$idx][$padix] = $DEBUG eq "verify" ? $mverify : $method;

          # mark our changes for B::Deparse's source code renderer
          $$pads[$idx][$targ]   .= $DEBUG ne "verify" ? ":compiled" : ":verified";
        }
        else {
          # mark our changes for B::Deparse's source code renderer
          ${$methop->meth_sv->object_2svref} .= $DEBUG ne "verify"
            ? ":compiled" : ":verified";
        }

        ++$tweaked;
      }
    }

    continue {
      last unless $$op and ${$op->next};
      $op                        = $op->next;
    }
  }

  push @$op_stack, $op if $$op;
  return ($op, $tweaked);
}

sub MODIFY_CODE_ATTRIBUTES {
  my ($class, $rv, @attrs)       = @_;
  local $@;

  if ((not defined $DEBUG or $DEBUG ne "disabled") and grep $valid_attrs{+lc}, @attrs) {

    my $cv_obj                   = B::svref_2object($rv);
    my @op_stack                 = $cv_obj->START;
    my ($pad_names, @p)          = $cv_obj->PADLIST->ARRAY;
    my @pads                     = map $_->object_2svref, @p;
    my @lexical_varnames         = $pad_names->ARRAY;
    my %processed_op;
    my $tweaked;

    while (my $op = shift @op_stack and not defined $^S) {
      ref $op and $$op and not $processed_op{$$op}++
        or next;

      $op->dump if defined $DEBUG and $DEBUG eq 'dump';

      if ($op->name eq "pushmark") {
        no warnings 'uninitialized';
	$tweaked                += eval {tweak $op, @lexical_varnames, @pads,@op_stack,
                                           $cv_obj, $pad_names, %processed_op};
        warn __PACKAGE__ . ": tweak() aborted: $@" if $@;
      }

      if ($op->isa("B::PMOP")) {
        push @op_stack, $op->pmreplroot, $op->pmreplstart, $op->next;
      }
      elsif ($op->can("first")) {
	for (my $kid = $op->first; ref $kid and $$kid; $kid = $kid->sibling) {
	  push @op_stack, $kid;
	}
	unshift @op_stack, $op->next;
      }
      else {
        unshift @op_stack, $op->next, $op->parent;
      }

    }

    if (defined $DEBUG and $DEBUG eq "deparse" and $tweaked) {
      eval {warn "sub ", $cv_obj->GV->NAME // "__UNKNOWN__", " :sealed ",
              B::Deparse->new->coderef2text($rv), "\n"};
      warn "B::Deparse: coderef2text() aborted: $@" if $@;
    }
  }
  return grep !$valid_attrs{+lc}, @attrs;
}

sub import {
  $DEBUG                         = $_[1];
  our $VERIFY_PREFIX = $_[2] if $DEBUG eq "verify" and defined $_[2];
  filter_add(bless []);
}

sub filter {
  my ($self) = @_;
  my $status = filter_read;
  our $VERIFY_PREFIX;
  our %rcache;

  # handle bare typed lexical declarations
  s/^\s*my\s+(\w[\w:]*)\s+(\$\w+)(.)/$3 eq ";" ? qq(BEGIN{local \$@; eval "require $1"} \
    my $1 $2; {no strict qw!vars subs!; no warnings 'once'; $2 = $1})
    : qq(BEGIN {local \$@; eval "require $1"}my $1 $2$3)/gmse if $status > 0;

  # NEW in v8.x.y: handle signatures
  no warnings 'uninitialized';
  s(^
    ([^\n]*sub\s+(\w[\w:]*)?\s*                               #sub declaration and name
      (?::\s*\w+(?:\(.*?\))?)*\s*:\s*[Ss]ealed\s*(?::\s*\w+(?:\(.*?\))?)#unspaced attrs
      *\s*(?:\(\S+\))?\s*)\((.*?)\)\s+\{         #prototype, signature and open bracket
   )(
     my $prefix = $1; # everything preceding the signature's arglist
     my $name   = $2; # sub name
     local $_   = $3; # signature's arglist
     my $suffix = "";
     my $verify = "";
     my (@types, @vars, @defaults);

     s{(\S+)?\s*(\$\w+)(\s*\S*=\s*[^,]+)?(\s*,\s*)?}{ # comma-separated sig args
       local $@;
       no strict 'refs';
       my $pkg = caller;
       my $is_ext_class = $rcache{"$pkg\::$1"} //= eval "package $pkg; require $1"
         // eval {*{eval "no strict 'vars'; package $pkg; $1"}};
       my $class = $is_ext_class ? $1 : "";

       $suffix .= "my $class $2 = ";

       tr!=!!d for my $default = $3;
       if (($default =~ tr!/!!d)==2) {
         $suffix .= "shift // $default;";
       }
       elsif (($default =~ tr!|!!d)==2) {
         $suffix .= "shift || $default;";
       }
       elsif ($default) {
         $suffix .= "\@_ ? shift : $default;";
       }
       else {
         $suffix .= "shift;"
       }

       my $type = $is_ext_class ? "InstanceOf[$1]" : $1;
       push @types, $type;
       push @defaults, $default;
       push @vars, substr($2,1);

       "$2$3$4" # drop the class/type info
    }gmse;

    if ($DEBUG eq "verify") {
      # implement signature type checks for named subs via Types::Common::signature

      $verify .= "$VERIFY_PREFIX; no strict qw/vars subs/; state \$check = signature multiple => [ { named_to_list => 1, named => [";
      $verify .= "$vars[$_] => $types[$_], " . (length($defaults[$_]) ? "{ default => $defaults[$_] }," : "") for 0..$#vars;
      $verify .= "],},{ positional => [";
      $verify .= "$types[$_], " . (length($defaults[$_]) ? "{ default => $defaults[$_] },":"") for 0..$#types;
      $verify .= "],},]; &\$check;";

      $prefix .= " ($_,\@_dummy)";
    }

    # warn "$prefix { {$verify} $suffix;
    "$prefix { no warnings qw/experimental shadow/; {$verify} $suffix";
  )gmsex if $status > 0;

  return $status;
}

1;

__END__

=head1 NAME

sealed - Subroutine attribute for compile-time method lookups on its typed lexicals.


=head1 SYNOPSIS

    use base 'sealed';
    use sealed 'deparse';

    sub handler :Sealed (Apache2::RequestRec $r) {
      $r->content_type("text/html"); # compile-time method lookup.
    ...

=head2 C<import()> Options

    use sealed 'debug';   # warns about 'method_named' op tweaks
    use sealed 'deparse'; # additionally warns with the B::Deparse output
    use sealed 'dump';    # warns with the $op->dump during the tree walk
    use sealed 'verify';  # verifies all CV tweaks, optional VERIFY_PREFIX arg
    use sealed 'disabled';# disables all CV tweaks
    use sealed;           # disables all warnings

    VERIFY_PREFIX arg defaults to "use Types::Common -types, -sigs;", which
    must export an equivalent API to Types::Common::signature() as "signature()".

=head1 BUGS

You may need to simplify your named method call argument stack,
because this op-tree walker isn't as robust as it needs to be.
For example, any "branching" done in the target method's argument
stack, eg by using the '?:' ternary operator, will break this logic
(pushmark ops are processed linearly, by $op->next walking, in tweak()).


=head2 Compiling perl v5.30+ for functional mod_perl2 w/ithreads and httpd 2.4.x w/event mpm

    % ./Configure -Uusemymalloc -Duseshrplib -Dusedtrace -Duseithreads -des && make -j$(nproc) && sudo make -j$(nproc) install

In an ithread setting, running w/ :sealed subs v4.1+ involves a tuning commitment to
each ithread it is active on, to avoid garbage collecting the ithread until the
process is at its global exit point. For mod_perl, ensure you never reap new ithreads
from the mod_perl portion of the tune, only from the mpm_event worker process tune or
during httpd server (graceful) restart.

=head1 CAVEATS

KISS.

Don't use typed lexicals under a :sealed sub for API method argument
processing, if you are writing a reusable OO module (on CPAN, say). This
module primarily targets end-applications: virtual method lookups and duck
typing are core elements of any dynamic language's OO feature design, and Perl
is no different.

Look into XS if you want peak performance in reusable OO methods you wish
to provide. The only rational targets for :sealed subs with typed lexicals
are methods implemented in XS, where the overhead of traditional OO
virtual-method lookup is on the same order as the actual duration of the
invoked method call. For nontrivial methods implemented entirely in Perl itself,
the op-tree processing overhead involved during execution of those methods will
drown out any performance gains this module would otherwise provide.

=head1 SEE ALSO

L<https://www.iconoclasts.blog/joe/perl7-sealed-lexicals>

=head1 LICENSE

Apache License 2.0
