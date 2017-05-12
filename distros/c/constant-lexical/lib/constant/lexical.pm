use 5.008;

package constant::lexical;

our $VERSION = '2.0003'; # Update POD, too!!!!!

my $old = '#line ' . (__LINE__+1) . " " . __FILE__ . "\n" . <<'__';

no constant 1.03 ();
use constant hufh => eval 'require Hash::Util::FieldHash';
use Sub::Delete;
BEGIN {
 0+$] eq 5.01
  and VERSION Sub::Delete >= .03
  and VERSION Sub::Delete 1.00001 # %^H scoping bug
}
hufh and eval '
  Hash::Util::FieldHash::fieldhash %hh;
  use Tie::Hash;
  {
   package constant::lexical::_hhfh;
   @ISA = "Tie::StdHash";
   sub DELETE { constant::lexical::DESTROY(SUPER::DELETE{@_}) }
  }
  tie %hh, constant::lexical::_hhfh::;;
';

sub import {
	$^H |= 0x20000; # magic incantation to make %^H work before 5.10
	shift;
	return unless @ '_;
	my @const = @_ == 1 && ref $_[0] eq 'HASH' ? keys %{$_[0]} : $_[0];
	my $stashname = caller()."::"; my $stash = \%$stashname;
	push @{hufh ? $hh{\%^H} ||= [] : ($^H{+__PACKAGE__} ||= bless[])},
	 map {
		my $fqname = "$stashname$_"; my $ref;
		if(exists $$stash{$_} && defined $$stash{$_}) {
			$ref = ref $$stash{$_} eq 'SCALAR'
				? $$stash{$_}
				: *$fqname{CODE};
			delete_sub($fqname);
		}
		[$fqname, $stashname, $_, $ref]
	} @const;
	unshift @_, 'constant';
	goto &{can constant 'import'}
}

sub DESTROY { for(@{+shift}) {
	delete_sub(my $fqname = $$_[0]);
	next unless defined (my $ref = $$_[-1]);
	ref $ref eq 'SCALAR' or *$fqname = $ref, next;
	my $stash = \%{$$_[1]}; my $subname = $$_[2];
	if(exists $$stash{$subname} &&defined $$stash{$subname}) {
		my $val = $$ref;
		*$fqname = sub(){$val}
	} else { $$stash{$subname} = $ref }
}}

1;
__

my $new = '#line ' . (__LINE__+1) . " " . __FILE__ . "\n" . <<'__';

BEGIN { $constant::lexical::{lexsubs} = \($] >= 5.022) }

if (lexsubs) {
 require XSLoader;
  XSLoader::load(__PACKAGE__, $VERSION);
}
else {
 require Lexical'Sub;
}

sub import {
  shift;
  return unless @ '_;
  my @args;
  if(@_ == 1 && ref $_[0] eq 'HASH') {
   _validate(keys %{$_[0]});
    while(my($k,$v) = each %{$_[0]}) {
     push @args, $k, sub(){ $v };
    }
  }
  elsif(@_ == 2) {
   _validate($_[0]);
    my $v = pop;
    @args = ($_[0], sub(){ $v });
  }
  else {
   _validate($_[0]);
    @args = (shift, do { my @v = @'_; sub(){ @v } });
  }
  if (lexsubs) {
    install_lexical_sub(splice @args, 0, 2) while @args;
  }
  else {
    import Lexical'Sub @args;
  }
 _:
}

# Plagiarised from constant.pm

# Some names are evil choices.
my %keywords
 = map +($_, 1), qw{ BEGIN INIT CHECK END DESTROY AUTOLOAD UNITCHECK };

my $normal_constant_name = qr/^_?[^\W_0-9]\w*\z/;
my $tolerable = qr/^[A-Za-z_]\w*\z/;
my $boolean = qr/^[01]?\z/;

sub _validate {
 for(@_) {
  defined or require Carp, Carp'croak("Can't use undef as constant name");
  # Normal constant name
  if (/$normal_constant_name/ and !$keywords{$_}) {
      # Everything is okay

  # Starts with double underscore. Fatal.
  } elsif (/^__/) {
      require Carp;
      Carp::croak("Constant name '$_' begins with '__'");

  # Maybe the name is tolerable
  } elsif (/$tolerable/) {
      # Then we'll warn only if you've asked for warnings
      if (warnings::enabled()) {
          if ($keywords{$_}) {
              warnings::warn("Constant name '$_' is a Perl keyword");
          }
      }

  # Looks like a boolean
  # use constant FRED == fred;
  } elsif (/$boolean/) {
      require Carp;
      if (@_) {
          Carp::croak("Constant name '$_' is invalid");
      } else {
          Carp::croak("Constant name looks like boolean value");
      }

  } else {
     # Must have bad characters
      require Carp;
      Carp::croak("Constant name '$_' has invalid characters");
  }
 }
}

1;
__

eval($] < 5.011002 ? $old : $new) or die $@;

__END__

=head1 NAME

constant::lexical - Perl pragma to declare lexical compile-time constants

=head1 VERSION

2.0003

=head1 SYNOPSIS

  use constant::lexical DEBUG => 0;
  {
          use constant::lexical PI => 4 * atan2 1, 1;
          use constant::lexical DEBUG => 1;

          print "Pi equals ", PI, "...\n" if DEBUG;
  }
  print "just testing...\n" if DEBUG; # prints nothing
                                        (DEBUG is 0 again)
  use constant::lexical \%hash_of_constants;
  use constant::lexical WEEKDAYS => @weekdays; # list

  use constant::lexical { PIE        => 4 * atan2(1,1),
                          CHEESECAKE => 3 * atan2(1,1),
                         };

=head1 DESCRIPTION

This module creates compile-time constants in the manner of
L<constant.pm|constant>, but makes them local to the enclosing scope.

=head1 WHY?

I sometimes use these for objects that are blessed arrays, which are
faster than hashes. I use constants instead of keys, but I don't want them
exposed as methods, so this is where lexical constants come in handy.

=head1 PREREQUISITES

This module requires L<perl> 5.8.0 or later.  If you are using a version of
perl lower than 5.22.0, then you will need one of the following modules,
which you
can
get from the CPAN:

=over

=item *

For perl 5.12.0 and higher: L<Lexical::Sub> 

=item *

For lower perl versions: L<Sub::Delete>

=back

=head1 BUGS

The following three bugs have been fixed for perl 5.12.0 and higher, but
are still present for older versions of perl:

=over

=item *

These constants are no longer available at run time, so they won't work
in a string C<eval> (unless, of course, the C<use> statement itself is 
inside the
C<eval>).

=item *

These constants actually are accessible to other scopes during
compile-time, as in the following example:

  sub foo { print "Debugging is on\n" if &{'DEBUG'} }
  {
          use constant::lexical DEBUG => 1;
          BEGIN { foo }
  }

=item *

If you switch to another package within a constant's scope, it (the 
constant) will
apparently disappear.

=for comment
I tried fixing this in perl 5.10 by detecting ‘package’ statements. 
Detecting those is
difficult. I tried using the approach in B::Hooks::OP::Check::StashChange,
which is to install a custom PL_check routine for every op and then see
when an op belonging to a different package is compiled, but that applies
also to string evals in other packages. What would happen is that the
constants would be visible to every eval that occurs while the scope to
which the constants belong is being compiled. That type of leak is worse
than the current situation.

=back

If you find any other bugs, please report them to the author via e-mail.

=head1 ACKNOWLEDGEMENTS

The idea of using objects in C<%^H> (in the pre-5.10 code) was stolen
from L<namespace::clean>.  The idea of doing cleanup in a DELETE method on
a tied field hash (in the 5.10 code) was likewise stolen from
L<namespace::clean>.

Some of the code for the perl 5.12.0+ version is plagiarised from
L<constant.pm|constant> by Tom Phoenix.

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2008, 2010, 2012, 2016 Father Chrysostomos (sprout at, um,
cpan dot
org)

This program is free software; you may redistribute or modify it (or both)
under the same terms as perl.

=head1 SEE ALSO

L<constant>, L<Sub::Delete>, L<namespace::clean>, L<Lexical::Sub>

=cut
