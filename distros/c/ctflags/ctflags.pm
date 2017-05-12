package ctflags;

our $VERSION = '0.04';

use 5.006;

use strict;
use warnings;

use Carp;

use ctflags::memory;
use ctflags::check;

use constant PREFIX => "ctflag_";

# set and get functions are wrappers around
# ctflags::memory::(set|get)_ctflag, wrappers capture errors an report
# them via croak

sub set ($$$ ) {
  eval { &set_ctflag };
  if ($@) { chomp $@; croak $@ };
}

sub get ($$ ) {
  my $r=eval { &get_ctflag };
  if ($@) { chomp $@; croak $@ };
  return $r;
}


# parse_flags breaks a string defining a flag set maybe with default
# values. If strings is '*' it expand it to all the flags allowed in
# the namespace (allowed ctflags are not the flags defined but the
# ones configured with ctflags::memory::restrict_ctflags() subrutine).

sub parse_flags ($$) {
  my ($ns, $flags)=@_;
  return allowed_ctflags($ns)
    if $flags eq '*';

  return ($flags=~/\G$flag_re$value_re?/go)
}


# export_sub creates the constant subrutine in the given package

sub export_sub ($$$ ) {
  my $qname=$_[0].'::'.$_[1];
  my $value=$_[2];

  no strict 'refs';
  *$qname = sub () { $value };
}

sub export_subsub ($$$ ) {
  my $qname=$_[0].'::'.$_[1];
  my $sub=$_[2];

  no strict 'refs';
  *$qname = $sub
}

# export_ctflags_as combine ctflag set with arithmetic or and export
# constant with the resulting value

sub export_ctflags_as ($$$$) {
  my ($package, $ns, $flags, $name)=@_;
  my $acu=0;
  $acu|=get_ctflag($ns, $_) foreach (parse_flags $ns, $flags);
  export_sub $package, $name, $acu;
}


# export every flag specified in $flags as package::prefix_flag

sub export_ctflags ($$$$) {
  my ($package, $ns, $flags, $prefix)=@_;
  foreach my $fe (parse_flags $ns, $flags) {
    my ($f)=split '', $fe;
    my $v=get_ctflag($ns, $fe);
    my $sub=get_ctflag_call($ns, $f);
    if ($sub) {
      export_subsub $package, $prefix,
	sub () {&$sub($ns, $f, $v); $v}
    }
    else {
      export_sub $package, $prefix.$f, $v;
    }
  }
}


# see pod docs below for import description.

sub import {
  my $self=shift;
  my $prefix=PREFIX; # prefix to use until another one is defined.
  my ($package)=caller; # by default constants are exported to calling
                        # package
  eval {
    while (@_) {
      my $key=shift;
      if (my ($name, $ns, $flags)=
	  $key=~m{^              # all the string should match.
	  (?:($identifier_re)=)? # name for the constant, optional.
	  ($ns_re)               # namespace.
	  :                      # namespace/flags separator ':'
	  (
	   \*                    # asterisk
	   |                     # or
	   (?:$flag_re           # flag name
	    $value_re?)          # maybe with default value,
	   *                     # several allowed
	  )$
	  }xo ) {
	# option is a ctflags -> constants conversion specification.
	if ($name) {
	  export_ctflags_as($package, $ns, $flags, $name)
	}
	else {
	  export_ctflags($package, $ns, $flags, $prefix)
	}
      }
      elsif ($key eq 'prefix') {
	$prefix=shift;
	check_cntprefix $prefix;
      }
      elsif ($key eq 'package') {
	$package=shift;
	check_package $package;
      }
      else {
	die "unknow option or invalid ctflags specification '$key'\n";
      }
    }
  };
  if ($@) { chomp $@; croak $@ };
}


1;
__END__

=head1 NAME

ctflags - Perl extension for compile time flags configuration

=head1 SYNOPSIS

  use ctflags qw(foo=myapp:f76 debug=myapp:debug:aShu);

  if (foo > 45) {
    ...
  }

  debug and warn "hey!, debugging...";


  use ctflags package=>'foo', prefix=>'bar',
              'myapp:danKE',
              'mycnt=yours:Y6';

  print "foo::bar_d=".foo::bar_d."\n";
  print "foo::bar_K=".foo::bar_K."\n";
  print "foo::mycnt=".foo::mycnt."\n";


=head1 ABSTRACT

ctflags module (and ctflags::parse) allow to easily define flags as
perl constant whose values are specified from comand line options or
environment variables.

=head1 DESCRIPTION

C<ctflags> and C<ctflags::parse> packages allow to dynamically set
constants values at compile time (every time the perl script is run)
based on environment variables or command line options.

Conceptually, ctflags are unsigned integer variables named with a
single letter ('a'..'z', 'A'..'Z', case matters), and structured in
namespaces.

Several ctflags with the same name can coexist as long as
they live in different namespaces (as perl variables with the same
name but living in different packages are different variables).

Namespace names have to be valid perl identifiers composed of letters,
the underscore char (C<_>) and numbers. The colon (C<:>) can also be
used to simulate nested namespaces.

Examples of valid qualified ctflags names are...

  myapp:a        # ctflag a in namespace myapp
  myapp:A        # ctflag A in namespace myapp
  myapp:debug:c  # ctflag c in namespace myapp:debug
  otherapp:C     # ctflag C in namespace otherapp
  App3:A         # ctflag A in namespace App3

A property of ctflags is that they do not need to be predefined to be
used and their default value is 0.

=head2 FUNCTIONS

Package C<ctflags> offers a set of utilities to convert ctflags to
constants. Basic functionality to set and retrieve ctflag values is
also offered but the C<ctflags::parse> package should be preferred for
this task.

=over 4

=item ctflags::set $ns, $name, $value

sets value of ctflag $name in namespace $ns to be $value.

This function will be useless unless you are able to call it before
ctflags are converted to constants, and this means early at compile
time, and this means that you will have to use C<BEGIN {...}>
blocks. i.e.:

  # at the beginning of your script;
  use ctflags;
  BEGIN {
    use Getopt::Std;
    our ($opt_v)
    getopts ("v:")
    ctflags::set('myapp', 'v', $opt_v);
  }
  use Any::Module
  ...


  # in Any::Module
  package Any::Module;
  use ctflags 'verbose=myapp:v';

=item ctflags::get $ns, $name

retrieves value of ctflag $name in namespace $ns.

=item ctflags->import(@options) or...

=item use ctflags @options;

creates perl constants from ctflag values.

@options can be a combination of key => value option pairs and
ctflags-to-constants-conversion-specifications.

Currently supported options are:

=over 4

=item prefix => $prefix

When no name is explicitly set for the constant to be created, one is
automatically generated as C<$prefix.$ctflag_name>. Default prefix is
C<ctflag_> and this option lets to change it. i.e.:

  use ctflags prefix=>'debug_', 'myapp:debug:abc';

exports ctflags C<a>, C<b> and C<c> in namespace C<myapp:debug> as
constants C<debug_a>, C<debug_b> and C<debug_c>.



=item package => $package

exports the constants to package $package instead of to the current
one. i.e.:

  use ctflags package=>'foo', 'flag=myapp:f',
              package=>'bar', 'flag=myapp:b';

exports ctflag C<f> in namespace C<myapp> as perl constant
C<foo::flag> and ctflag C<b> in namespace C<myapp> as perl constant
C<bar::flag>.

=back

ctflags to constants conversions are specified as:

  [cnt_name=]namespace:(*|ctflag_names)

this expand to a small set of rules:

=over 4

=item foo:*

export all ctflags in namespace C<foo> as constants C<ctflag_a>,
C<ctflag_b>,...,C<ctflag_Z>.

(unless C<prefix> option has been used to change generated constant
names to say C<myprefix_a>, C<myprefix_b>, etc.)

=item foo:bar

export ctflags C<b>, C<a>, C<r> in namespace C<foo> as C<ctflag_b>,
C<ctflag_a>, C<ctflag_r>.

=item cnt=foo:b

export ctflag C<b> in namespace C<foo> as constant C<cnt>

=item cnt=foo:bar

=item cnt=foo:*

when the constant name appears explicitly and more than one ctflag are
specified in any way, the value of the constant is the result of
combining all the ctflags values with the arithmetic or operator
(C<|>). i.e:

  use ctflags qw(anydebug=myapp:debug:*);
  ...
  if (anydebug) { open DEBUG, ">/tmp/output" }

=back

Default values can be specified to be used when no value has been
previosly assigned explicitly to a ctflag.

They should be composed of digits and appear in the conversion
specification just after the ctflag name letter to be affected. i.e.:

  use ctflags qw(foo:bar67)

C<ctflag_r> will return 67 unless C<foo:r> had been previouly defined
in any way.

The specification of the default value do B<not> assign it to the
ctflag. i.e:

  use ctflags qw(cnt1=foo:r67)
  use ctflags qw(cnt2=foo:r)

if ctflag C<foo:r> was not previusly set, C<cnt1> will return 67 and
C<cnt2> will return 0.

=back

=head2 EXPORT

Uff... well, it depends, see the C<import> function in the previous
section.

=head1 BUGS

This is version 0.01, and I am sure that several bugs are going to
appear.

Also I reserve the rigth to change the public interface of the module
in an incompatible manner if deficiencies in the current one are
found (this will not be this way forever, just for some time).

I will really apreciate any correction to the documentation prose,
English is not my native tongue and so...

=head1 SEE ALSO

Companion package L<ctflags::parse>, L<constant> package and
L<perlsub> for a discusion about how perl constants can be implemented
as inlined subrutines.

=head1 AUTHOR

Salvador FandiE<241>o Garcia, E<lt>sfandino@yahoo.comE<gt>

(please, revert to "Salvador Fandino Garcia" if your display charset
is not latin-1 compatible :-(

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador FandiE<241>o Garcia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
