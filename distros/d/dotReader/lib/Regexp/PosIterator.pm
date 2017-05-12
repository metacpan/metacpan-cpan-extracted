package Regexp::PosIterator;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


=head1 NAME

Regexp::PosIterator - a regular expression iterator

=head1 SYNOPSIS

=cut

=head1 TODO

Put this on CPAN

Figure out why it locks, segfaults, and does other silly things with one-character searches depending on what has been said on STDERR recently.

=cut


=head2 new

  my $finder = Regexp::PosIterator->new($regexp, $string);

=cut

sub new {
  my $class = shift;
  ref($class) and croak("not an object method");
  my ($r, $s) = @_;

  ((ref($r) || '') eq 'Regexp') or croak("not a regexp");
  my $self = {regexp => $r, string => $s};

  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 match

  my ($start, $end) = $finder->match;

=cut

sub match {
  my $self = shift;

  my $r = $self->{regexp};

  delete($self->{submatches});
  #pos($self->{string}) = $self->{posi};
  if($self->{string} =~ m/$r/g) {
    my $s = $-[0];
    my $e = $+[0];
    my $count = $#+;
    if($count) { # keeps stuff from exploding
      $self->{submatches} = [
        map({defined($-[$_]) ? [$-[$_], $+[$_]] : []} 1..$count)
      ];
    }
    return($s, $e);
  }
  else {
    # set as done :-/
    return;
  }
} # end subroutine match definition
########################################################################

=head2 submatches

  my @subm = $finder->submatches;

=cut

sub submatches {
  my $self = shift;
  $self->{submatches} or return();
  return(@{$self->{submatches}});
} # end subroutine submatches definition
########################################################################



=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

See L<Regex::Iterator> for an alternate implementation.

=cut

# vi:ts=2:sw=2:et:sta
1;
