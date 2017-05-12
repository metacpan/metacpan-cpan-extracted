package ctflags::memory;

our $VERSION = '0.01';

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# this package is supposed to be private to ctflags and companion
# packages, not used from any other module so it uses directly
# @EXPORT. Anyway, the function names used are not going to cause
# too many namespace pollution problems.
our @EXPORT = qw( set_ctflag
		  get_ctflag
		  restrict_ctflags
		  allowed_ctflags
		  is_ctflag_allowed
		  set_ctflag_alias
		  resolve_ctflag_alias
		  set_ctflag_call
		  get_ctflag_call );


use ctflags::check;

my %memory;
my %meta;
my %alias;
my %call;

# In most of ctflags subrutines, argument checking is done indirectly
# when subrutines here, in ctflags::memory are called, and so all of
# the public subrutines here implement checks for the validity of its
# arguments.
#
# Only helper functions which name begins with an underscore, like
# '_is_allowed' bellow, are exent from these checks and their use is
# discouraged outside this module


# checks that the use of a flag has not been forbided inside a
# namespace or dies.

sub _is_allowed ($$) {
  my ($ns, $flag)=@_;
  !exists $meta{$ns.':restricted'}
    or index($meta{$ns.':restricted'}, $flag)>=0
      or die "ctflag '$flag' is not allowed in namespace '$ns'\n";
}


# public interface for _is_allowed. Just checks for the validity of
# its arguments

sub is_ctflag_allowed ($$) {
  check_ns $_[0];
  check_flag $_[1];
  &_is_allowed
}


# change value of ctflag

sub set_ctflag ($$$ ) {
  my ($ns, $flag, $value)=@_;
  check_ns $ns;
  check_flag $flag;
  check_value $value;
  _is_allowed $ns, $flag;
  $memory{$ns.':'.$flag}=int($value);
}


# retrieve value of ctflag

sub get_ctflag ($$) {
  my ($ns, $flagext)=@_;
  check_ns $ns;
  my ($flag, $default)=$flagext=~/($flag_re)($value_re)?/o;
  check_flag $flag;
  check_value $default;
  _is_allowed $ns, $flag;
  my $m=$memory{$ns.":".$flag};
  int(defined $m ? $m : ($default || 0));
}

sub extend_flagsetext ($$) {
  my ($fse, $ns)=@_;
  check_ns($ns);
  check_flagsetext($fse);

  if ($fse eq '*') {
    return join ('', allowed_ctflags($ns))
  }

  if ($fse=~/^!(.*)/) {
    my $inv=$1;
    return join('',
		(grep {index($inv, $_)<0 } allowed_ctflags($ns)));
  }

  return $fse;
}

# restrict which ctflags are allowed inside a namepace


sub restrict_ctflags ($$) {
  my $ns=shift;
  check_ns $ns;
  my $flagset=extend_flagsetext(shift, $ns);
  $meta{$ns.':restricted'}=$flagset;
}


# returns an array with the allowed ctflags inside a namespace

sub allowed_ctflags ($ ) {
  my $ns=shift;
  check_ns $ns;
  return split('', $meta{$ns.':restricted'})
    if (exists $meta{$ns.':restricted'});
  return ('a'..'z','A'..'Z')
}


# creates an alias (long name composed of more than one letter) for a
# ctflag

sub set_ctflag_alias ($$$ ) {
  my ($ns, $alias, $flag)=@_;
  check_alias $alias;
  check_ns $ns;
  unless (defined $flag) {
    delete $alias{$ns.':'.$alias};
    return
  }
  check_flag $flag;
  _is_allowed $ns, $flag;
  $alias{$ns.':'.$alias}=$flag;
}


# returns the value of an aliased ctflag from its alias name

sub resolve_ctflag_alias ($$) {
  my ($ns, $alias)=@_;
  check_ns $ns;
  check_alias $alias;
  exists $alias{$ns.':'.$alias}
    or die "ctflag alias '$alias' not defined in namespace '$ns'\n";
  return get_ctflag($ns, $alias{$ns.':'.$alias});
}

sub set_ctflag_call ($$$) {
  my ($ns, $flagsetext, $sub)=@_;
  check_ns $ns;
  my $flags=extend_flagsetext($flagsetext, $ns);
  check_sub $sub;
  foreach my $f (split //, $flags) {
    _is_allowed $ns, $f;
    $call{$ns.':'.$f}=$sub;
  }
}

sub get_ctflag_call ($$) {
  my ($ns, $flag) =@_;
  check_ns($ns);
  check_flag($flag);
  my $n=$ns.':'.$flag;
  if (exists $call{$n}) {
    return $call{$n};
  }
  return undef;
}

1;
__END__

=head1 NAME

ctflags::memory - low level functions for ctflags

=head1 SYNOPSIS

  use ctflags::memory;


=head1 ABSTRACT

  ctflags::memory implements low level functions used from ctflags and
  companion packages. Do not use it directly.

=head1 DESCRIPTION

ctflags::memory mantains the internal state of the ctflags and exports
some low level functions used from the rest of the ctflags modules.

You can see the cource code for comments about its functions but do
not use them directly.


=head2 EXPORT

C<set_ctflag>,
C<get_ctflag>,
C<restrict_ctflags>,
C<allowed_ctflags>,
C<is_ctflag_allowed>

=head1 SEE ALSO

L<ctflags>, L<ctflags::parse>, L<ctflags::config>, L<ctflags::long>
and L<ctflags::check>.

=head1 AUTHOR

Salvador FandiE<241>o Garcia, E<lt>sfandino@yahoo.comE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador FandiE<241>o Garcia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
