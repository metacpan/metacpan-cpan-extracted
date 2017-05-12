
package punctuation;

use B::Utils 'walkoptree_filtered', 'opgrep';
use B::Utils 0.03;
$VERSION = 0.02;

my %punct = (gv => '', gvsv => '$', gvav => '@', gvhv => '%',
             rv2sv => '$', rv2av => '@', rv2hv => '%',
);
my %packages;
my @roots = ();

CHECK {
  my $bad;

  if (%interesting_package) {
    my %all_roots  = B::Utils::all_roots();
    push @roots, $all_roots{'__MAIN__'} if $interesting_package{main};
    for my $k (keys %all_roots) {
      my ($pack, $name) = ($k =~ /(.*)::(.*)/);
      next unless defined $pack && $interesting_package{$pack};
      push @roots, $all_roots{$k};
    }
  }

#  print "List of roots has ", scalar(@roots), " entries.\n";
  walkoptree_filtered(
    $_,
    # filter
    sub { opgrep({name => [qw(gv gvsv gvav gvhv)]}, @_);
        },
    # callback
    sub { my $op = shift;
          my $gv = $op->gv;
          my ($file, $line, $name) = ($gv->FILE, $gv->LINE, $gv->NAME);
          my $safename = $gv->SAFENAME;
#          print STDERR "NAME: $name $safename\n";
          return if $name =~ /^\w/;
          my $punct = $punct{$op->name} || $punct{$op->next->name};
          B::Utils::carp("Illegal punctuation variable $punct$safename");
          $bad++;
        },
    # user
                   )
    for @roots;
  exit 119 if $bad;
}

sub unimport {
  my $pack = shift;
  my $caller = caller;
  for my $arg (@_) {
    if ($arg eq 'anon') {
      push @roots, B::Utils::anon_subs();
    } else {
      require Carp;
      Carp::Croak("$pack: Unknown parameter $_");
    }
  }
  if (@_ == 0) {
#    print "Package ($caller) is now interesting.\n";
    $interesting_package{$caller} = 1;  
  }
}

1;

=head1 NAME

  punctuation - Forbid uses of punctuation variables

=head1 SYNOPSIS

  no punctuation;

  no punctuation 'anon';

=head1 DESCRIPTION

Use of the C<no punctuation> pragma in a package forbids all uses of
punctuation variables such as C<$">, C<$!>, C<$^O>, and so on in
named subroutines defined in that package.

C<no punctuation 'anon'> forbids the use of punctuation variables in all anonymous subroutines in the program.

C<use punctuation> does nothing.

=head2 EXPORT

None by default.

=head1 AUTHOR

Mark Jason Dominus, C<mjd-perl-nopunct+@plover.com>

=head1 PREREQUISITE

Requires C<B::Utils>.  However, the version of C<B::Utils> available
on CPAN at this time of this writing (version 0.02) has many bugs.
You may obtain a corrected copy of 0.02 from
C<http://perl.plover.com/punctuation/> .

=head1 TODO

Probably none of it works the way you wish it would, but as they say:
If a thing's not worth doing at all, it's not worth doing well.

=head1 SEE ALSO

L<B::Utils>

=cut



