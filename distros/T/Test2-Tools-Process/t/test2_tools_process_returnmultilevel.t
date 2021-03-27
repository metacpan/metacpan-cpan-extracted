use Test2::V0 -no_srand => 1;
use Test2::Tools::Process;
use Test2::Tools::Process::ReturnMultiLevel qw( with_return );

# these tests are forkedfrom Return::MultiLevel, and Test2-ified

subtest basic => sub {

  is with_return {
    my ($ret) = @_;
    42
  }, 42;

  is with_return {
    my ($ret) = @_;
    $ret->(42);
    1
  }, 42;

  is with_return {
    my ($ret) = @_;
    sub {
      $ret->($_[0]);
      2
    }->(42);
    3
  }, 42;

  sub basic_foo {
    my ($f, $x) = @_;
    $f->('a', $x, 'b');
    return 'x';
  }

  is [with_return {
      my ($ret) = @_;
      sub {
          basic_foo $ret, "$_[0] lo";
      }->('hi');
      ()
  }], ['a', 'hi lo', 'b'];

  is [scalar with_return {
    my ($ret) = @_;
    sub {
      basic_foo $ret, "$_[0] lo";
    }->('hi');
    ()
  }], ['b'];

};

subtest nested => sub {

  my @r;
  for my $i (1 .. 10) {
    push @r, with_return {
      my ($ret_outer) = @_;
      100 + with_return {
        my ($ret_inner) = @_;
        sub {
          ($i % 2 ? $ret_outer : $ret_inner)->($i);
          'bzzt1'
        }->();
        'bzzt2'
      }
    };
  }

  is \@r, [1, 102, 3, 104, 5, 106, 7, 108, 9, 110];

};

done_testing;
