package ctflags::parse;

our $VERSION = '0.01';

use 5.006;
use strict;
use warnings;
use Carp;

use ctflags::memory;
use ctflags::check;

sub complement {
  my $ns=shift;
  my %no; @no{@_}=();
  return grep {!exists($no{$_})} allowed_ctflags($ns);
}

sub parse {
  my ($ns, $flags)=@_;

  if ($flags=~/^!($flagset_re)($value_re)?$/o) {
    my ($flagset, $value)= ($1, (defined $2 ? $2 : 1));
    foreach (complement($ns, split '', $flagset)) {
      set_ctflag($ns, $_, $value);
    }
    return;
  }

  if ($flags=~/^\*($value_re)?$/) {
    my $value=defined($1) ? $1 : 1;
    foreach (complement($ns)) {
      set_ctflag($ns, $_, $value);
    }
    return;
  }

  while ($flags=~/\G($flag_re)(?:-($flag_re))?($value_re)?/go) {
    my ($letter0, $letter1, $value)=( $1,
				      ($2||$1),
				      (defined $3 ? $3 : 1) );
    if (($letter0 cmp uc $letter0) != ($letter1 cmp uc $letter1)) {
      die "invalid ".__PACKAGE__." flag selection specification 'flags',".
	" because in range $letter0-$letter1 case is different\n"
    }
    if ($letter1 lt $letter0) {
      die "invalid ".__PACKAGE__." flag selection specification 'flags',".
	" because in range $letter0-$letter1, $letter0 > $letter1\n"
    }
    for ($letter0 .. $letter1) {
      set_ctflag($ns, $_, $value);
    }
    return if $flags=~/\G$/;
  }

  die "invalid ".__PACKAGE__." flag selection specification '$flags'\n";
}

sub import {
  my $default;
  my @allow=('*');
  my $self=shift;

  eval {
    while (@_) {
      my $key=shift;

      if ($key eq 'namespace' or $key eq 'ns') {
	$default=shift;
	check_ns $default
      }
      elsif ($key eq 'allow') {
	my $nss=shift;
	check_defopt $nss, 'allow';
	if ('ARRAY' eq ref $nss) {
	  @allow = grep { check_ns $_ } @{$nss};
	}
	elsif ($nss eq '*') {
	  @allow=('*');
	}
	else {
	  @allow = grep { check_ns $_ } (split /[\s,]+/, $nss);
	}
      }
      elsif ($key eq 'parse' or $key eq 'env') {
	my $flagsline;
	my $env;
	if ($key eq 'env') {
	  $env=shift;
	  check_envname $env;
	  $flagsline=$ENV{$env};
	  defined $flagsline or $flagsline="";
	}
	else {
	  $flagsline=shift;
	  check_defopt $flagsline, 'parse';
	}
	eval {
	  foreach (split /[\s,]+/, $flagsline) {
	    if (my ($ns, $flags)=
		$_=~m{^
		      (?:($ns_re):)?           # ns, optional
		      (
		       (?:$flag_re(?:-$flag_re)?$value_re?)* # flag and values
		       |
		       (?:!$flag_re*$value_re?)          # or negation and flags
		       |
		       (?:\*$value_re?)        # or asterisk
		      )
		      $
		     }xo) {
	      if (defined $ns) {
		if (!(grep {$_ eq $ns or $_ eq '*'} @allow)) {
		  die "use of namespace '$ns' is not allowed\n";
		}
	      }
	      elsif (defined $default) {
		$ns=$default;
	      }
	      else {
		die "short ".__PACKAGE__." parse selection found ('".
		  $flags."'), but no default namespace defined\n";
	      }

	      parse $ns, $flags;
	    }
	    else {
	      die "invalid flag specification '$_'\n";
	    }
	  }
	};
	if ($@) {
	  if (defined $env) {
	    chomp $@;
	    die $@.
	      ", when parsing ctflags from environment variable '$env'\n\n"
	  }
	  else { die $@ };
	}
      }
      else {
	die "unknow ".__PACKAGE__." option '$key'";
      }
    }
  };
  if ($@) { chomp $@; croak $@}
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

ctflags::parse - configure ctflags from command line or environments

=head1 SYNOPSIS

  use ctflags::parse allow => [qw(myapp yourapp debug)],
                     ns => 'myapp', # or namespace => 'myapp'
                     env => 'MYAPPFLAGS',
                     parse => 'b45ar7yui';
  
  ...
  
  use ctflags 'foo=myapp:B67';

=head1 ABSTRACT

ctflags::parse implementes a simple language that can be used to set
ctflags from specifications obtained from the command line or from
environment variables.

=head1 DESCRIPTION

C<ctflags::parse> define and sets ctflag values from string
declarations.

It does all its work from the use statement C<use ctflags::parse ...>
because this way ctflags are defined early at compile time.

It support diferent options expressed as C<key =E<gt> value> pairs:

=over 4

=item allow => 'foo, bar'

=item allow => [qw(foo bar)]

=item allow => '*'

=item allow => ''

restrict the namespaces that could be latter (but in the same C<use>
statement) included in the declarations. i.e:

  use ctflags::parse allow => 'foo',
                     parse => 'foo:bar', # ok
                     parse => 'app:bar'; # error

Use of the asterisk removes all restrictions (every namespace is
allowed).

Use of an empty string disallows usage of any namespace but implicit
usage of the default (see below).


=item ns => $namespace

=item namespace => $namespace

define implicit namespace to be used when no one appears in the
declaration. i.e:

  use ctflags::parse ns => 'foo',
                     parse => 'a67'; # sets foo:a = 67

Implicit namespace used implicitly is always allowed:

  use ctflags::parse allow => '',        # nothing allowed
                     ns => 'foo',        # implicit ns
                     parse => 'a67',     # ok, foo:a=67
                     parse => 'foo:a67'; # error!

=item env => $environmet_var_name

parses the declaration in the environment variable if
exists. Incorrect declarations will cause your program to die with an
explanation of the error.

=item parse => $declaration

parses the declaration following. Declarations are of the form:

  [namespace:](ctflag[value])*,[namespace:](ctflag[value])*,...

when no value is specified for a flag, 1 is used as the default.

Example1:

  use ctflags::parse ns => 'myapp',
                     parse => foo:b2ar,bee:bas,r56Y7800;

sets ctflags:

  foo:b=2, foo:a=1, foo:r=1

  bee:b=1, bee:a=1, bee:s=1

  myapp:r=56, myapp:Y=7800


Example2:

  use ctflags::parse ns => 'myapp:debug',
                     parse => 'su6jklI1000O';

sets ctflags in namespace C<myapp:debug> C<s>, C<j>, C<k>, C<O> to 1,
C<u> to 6 and C<I> to 1000.

=back

You should be carefull about puting ctflags::parse use statements
before including any module that uses ctflags.

When parsing options from the command line you also have to be
carefull about doing it at compile time, this usually means including
the command line parsing code in a C<BEGIN {...}> block:

  #!/usr/bin/perl
  
  use Getopt::Std;
  BEGIN { getopts('d:o:ther:fla:gs') }
  
  our $opt_d;
  use ctflags::parse allow => '',
                     ns => 'myapp:debug',
                     parse => $opt_d;
  
  use Other::Module; # modules using ctflags internally
  use Another::One;
  
  ...



=head2 EXPORT

None.


=head1 SEE ALSO

L<ctflags>, L<Getopt::Std>, L<Getopt::Long>.

=head1 AUTHOR

Salvador FandiE<241>o Garcia, E<lt>sfandino@yahoo.comE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador FandiE<241>o Garcia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
