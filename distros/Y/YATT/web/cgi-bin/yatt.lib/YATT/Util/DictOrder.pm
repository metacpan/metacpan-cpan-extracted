package YATT::Util::DictOrder;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw/Exporter/;

our @EXPORT_OK = qw(&dict_order &dict_sort);
our @EXPORT = @EXPORT_OK;

sub dict_order {
  my ($a, $b, $start) = @_;
  $start = 1 unless defined $start;
  my ($result, $i) = (0);
  for ($i = $start; $i <= $#$a and $i <= $#$b; $i++) {
    if ($a->[$i] =~ /^\d/ and $b->[$i] =~ /^\d/) {
      $result = $a->[$i] <=> $b->[$i];
    } else {
      $result = $a->[$i] cmp $b->[$i];
    }
    return $result unless $result == 0;
  }
  return $#$a <=> $#$b;
}

# a   => ['a', 'a']
# q1a => ['q1a', 'q', 1, 'a']
# q11b => ['q11b', 'q', 11, 'b']
sub dict_sort (@) {
  map {$_->[0]} sort {dict_order($a,$b)} map {[$_, split /(\d+)/]} @_;
}

1;

=head1 NAME

YATT::Util::DictOrder - Dictionary-style ordering and sorting.

=head1 SYNOPSIS

  use YATT::Util::DictOrder;
  print join ",", dict_sort qw(q3-1 q3 q10a q1);
  # prints "q1,q3,q3-1,q10a"

  print join ",",
     map {$$_[0]}
     sort {dict_order($a, $b, 1)}
     map {[$$_[0], split /(\d+)/, $$_[1]]}
    [qw(foo q3-1)],
    [qw(summer q3)],
    [qw(moe q10a)],
    [qw(romantic q1)];
  # prints "romantic,summer,foo,moe"

=head1 DESCRIPTION

=head2 C<dict_sort>

=head2 C<dict_order>

=head1 AUTHOR

KOBAYASI, Hiroaki (C<hkoba@cpan.org>)

=head1 LICENSE

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
