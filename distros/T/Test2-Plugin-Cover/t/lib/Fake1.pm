package Fake1;

sub fake { 'fake' }

my $x;
sub lfake :lvalue { $x }

sub gfake { goto \&inner_gfake }

sub inner_gfake { 'fake' }

1;
