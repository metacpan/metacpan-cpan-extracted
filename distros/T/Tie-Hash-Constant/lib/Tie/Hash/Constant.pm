package Tie::Hash::Constant;
use strict;
use warnings;
our $VERSION = 0.01;

=head1 NAME

Tie::Hash::Constant - make a hash return a constant for all its members

=head1 SYNOPSIS

  use Tie::Hash::Constant;
  tie my %always_pie, 'Tie::Hash::Constant' => 'PIE!';
  $always_pie{food} = "salad";
  print "My favourite food is $always_pie{food}\n"; # prints "My favourite food is PIE!"
  print "There is no $always_pie{spoon}\n";  # prints "There is no PIE!\n"; !!!

=head1 DESCRIPTION

Tie::Hash::Constant allows you to define a constant to be returned as
all values contained within a hash.

It has marginal use as a debugging tool.

=cut

sub TIEHASH {
    my $class = shift;
    my $constant = shift;
    return bless \$constant, $class;
}

sub FETCH {
    my $self = shift;
    return $$self;
}

sub STORE {}

1;
__END__

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

Copyright Richard Clamp 2004.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie::Hash::Constant>.

=head1 SEE ALSO

Tie::Hash

=cut
