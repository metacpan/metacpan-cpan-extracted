package foundation;

use strict;
no strict 'refs';
use vars qw($VERSION @ISA @EXPORT);
$VERSION = '0.03';

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(SUPER foundation);


=pod

=head1 NAME

foundation - Inheritance without objects


=head1 SYNOPSIS

  package Foo;

  sub fooble { 42 }

  package Bar;

  sub mooble { 23 }
  sub hooble { 13 }

  package FooBar;
  use foundation;
  foundation(qw(Foo Bar));

  sub hooble { 31 }

  print fooble();       # prints 42
  print moodle();       # prints 23
  print hooble();       # prints 31 (FooBar overrides hooble() from Bar)
  print SUPER('hooble');     # prints 13 (Bar's hooble())


=head1 DESCRIPTION

Haven't drunk the OO Kool-Aid yet?  Think object-oriented has
something to do with Ayn Rand?  Do you eat Java programmers for
breakfast?

If the answer to any of those is yes, than this is the module for you!
C<foundation> adds the power of inheritance without getting into a
class-war!

Simply C<use foundation> and list which libraries symbols you wish to
"inherit".  It then sucks in all the symbols from those libraries into
the current one.

=head2 Functions

=over 4

=item B<foundation>

  foundation(@libraries);

Declares what libraries you are founded on.  Similar to C<use base>.

=cut

#'#
sub foundation {
    my(@libraries) = @_;
    my $caller = caller;

    foreach my $library (@libraries) {
#        next if FOUNDED_ON($library, $caller);
        push @{$caller.'::__FOUNDATION'}, $library;

        eval "require $library";
        # only ignore "Can't locate" errors.
        die if $@ && $@ !~ /^Can't locate .*? at \(eval /; #'

        while( my($name, $stuff) = each %{$library.'::'} ) {
            my $call_glob = ${$caller.'::'}{$name};

            *{$caller.'::'.$name} = \&$stuff 
              unless defined &{$caller.'::'.$name};
            *{$caller.'::'.$name} = \$$stuff;
            *{$caller.'::'.$name} = \@$stuff;
            *{$caller.'::'.$name} = \%$stuff;
        }
    }

    *{$caller.'::SUPER'} = \&SUPER;
}

=pod

=item B<SUPER>

  my @results = SUPER($function, @args);

Calls the named $function of the current package's foundation with the
given @args.

Similar to C<$obj->SUPER::meth();>

=cut

sub SUPER {
    my($func) = shift;
    my($lib) = caller;

    my $super_func;

    # Fortunately, we can do a linear search.
    foreach my $foundation (@{$lib.'::__FOUNDATION'}) {
        if( defined &{$foundation.'::'.$func} ) {
            $super_func = \&{$foundation.'::'.$func};
            last;
        }
    }

    goto &$super_func;
}


=pod

=head1 BUGS

Plenty, I'm sure.  This is a quick proof-of-concept knock off.

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Sex>, L<base>

=cut

1;
