package Test::RandomCheck::PRNG;
use strict;
use warnings;

sub new { $_[0] }

sub next_rand { rand() }

sub next_int {
    my $self = shift;
    my ($min, $max) = @_ == 2 ? @_ : (0, @_);
    ($min, $max) = ($max, $min) if $min > $max;
    int($self->next_rand * ($max - $min + 1)) + $min;
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::RandomCheck::PRNG - A thin wrapper of rand()

=head1 SYNOPSIS

  use Test::RandomCheck::PRNG

  my $r = Test::RandomCheck::PRNG->new;
  my $a_float = $r->next_rand
  my $an_int = $r->next_int(1, 6);

=head1 DESCRIPTION

A thin wrapper of rand().

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Masahiro Honma

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
