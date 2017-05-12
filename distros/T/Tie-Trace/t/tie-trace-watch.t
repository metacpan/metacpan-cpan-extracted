use Test::More;

local $SIG{__DIE__} = sub {print "ERROR: ", @_;};
use Data::Dumper;

use_ok("Tie::Trace");
#use Tie::Hash;



{
  my $err;
  local *STDERR;

  ok(open(STDERR, ">", \$err), "open");


  
  my %hash = ();
  Tie::Trace::watch(\%hash, r => 1);

  print $@;

  my $s;
  my $x = { hoge => 1, hoge2 => 2, hoge3 => [qw/a b c d e/],  hoge4 => \$s,};

  $hash{1} = $x;            # 1 -- HASH(....)
  like($err, qr/^main:: \%hash => \{1\} => \{/m, '$hash{1} = $x');

  
  $hash{1}->{hoge} = 3;     # hoge -- 3
  like($err, qr/^main:: \%hash => \{1\}\{hoge\} => 3/m, '$hash{1}->{hoge} = 3');

  

  $hash{1}->{hoge} = 4;     # hoge -- 4
  like($err, qr/^main:: \%hash => \{1\}\{hoge\} => 4/m, '$hash{1}->{hoge} = 4');

  close STDERR;

  open STDERR, '>', \$err or die $!;

  $hash{1}->{hoge} = 0;     # hoge -- 0
  like($err, qr/^main:: \%hash => \{1\}\{hoge\} => 0/m, '$hash{1}->{hoge} = 0');

  
  $hash{2}->{hoge} = 222;   # 2 -- HASH(...)
                          # hoge - 222
  like($err, qr/^main:: \%hash => \{2\} => \{/m, '$hash{2} = HASH');
  like($err, qr/^main:: \%hash => \{2\}\{hoge\} => 222/m, '$hash{2}->{hoge} = 222');
 

  push(@{$hash{1}->{hoge3}}, "array");# array
  like($err, qr/^main:: \%hash => \@\{\{1\}\{hoge3\}\} => PUSH\('?array'?\)/m, 'push(@{$hash{1}->{hoge3}}, "array")');

  push(@{$hash{1}->{hoge3}}, "array2");# array
  like($err, qr/^main:: \%hash => \@\{\{1\}\{hoge3\}\} => PUSH\('?array2'?\)/m, 'push(@{$hash{1}->{hoge3}}, "array2")');

  splice(@{$hash{1}->{hoge3}}, 2 , 1 ,2);
  like($err, qr/^main:: \%hash => \{1\}\{hoge3\}\[2\] => \(2\)/m, 'splice');

  is_deeply([sort keys(%hash)], [1,2], "hash key check 1");      # 1, 2, 3, 4
  is_deeply([sort keys %{$hash{1}}], ["hoge", "hoge2", "hoge3", "hoge4"], "hash key check 2"); # hoge
  is_deeply([sort @{$hash{1}->{hoge3}}], [qw/2 a array array2 b d e/], "array check");

  $hash{xxx}->{bless} = bless {};
  like($err, qr/^main:: %hash => \{xxx\}\{bless\} => bless\(/m, '$hash{xxx}->{bless} = bless {}');
  $hash{xxx}->{bless}->{bless_hoge} = 1;
  unlike($err, qr/^{bless_hoge} => 1/m, '$hash{xxx}->{bless}->{bless_hoge} = 1');
  my %tied;

  tie %tied, "Tie::StdHash";
  $hash{xxx}->{tied} = \%tied;
  like($err, qr/^main:: %hash => \{xxx\}\{tied\} => \{/m, '$hash{xxx}->{tied} = HASH');
  $hash{xxx}->{tied}->{a} = 1234;
  like($err, qr/^main:: %hash => \{xxx\}\{tied\}\{a\} => 1234/m, '$hash{xxx}->{tied}->{a} = 1234');
  close STDERR;

  open STDERR, '>', \$err or die $!;

  my %hash4;
  tie(%hash4, 'Tie::Trace', value => ['foo', 'bar'], r => 0) or die $!;

  $hash4{oo} = 'foo';
  like($err, qr/^\s*\{oo\} => 'foo'/m, q{$hash{oo} = 'foo'});
  $hash4{ar} = 'bar';
  like($err, qr/^\s*\{ar\} => 'bar'/m, q{$hash{ar} = 'bar'});
  $hash4{xxx} = {};
  unlike($err, qr/^\s*\{xxx\} => HASH/m, '$hash{xxx} = {}');
  $hash4{xxx}->{ooxx} = 'foo';
  unlike($err, qr/^\s*\{oox\} => 'foo'/m, q{$hash{xxx}->{oo} = 'foo'});
  $hash4{xxx}->{arx} = 'bar';
  unlike($err, qr/^\s*\{arx\} => 'bar'/m, q{$hash{xxx}->{ar} = 'bar'});
  $hash4{xxx}->{xxx} = 'var';
  unlike($err, qr/^\s*\{xxx\} => 'var'/m, q{$hash{xxx}->{xxx} = 'var'});
  $hash4{xxx} = undef;
  my $del = delete $hash4{xxx};
  is($del, undef);
 
=iranai

  my %hash5;
  Tie::Trace::watch(\%hash5);
  $hash5{1} = [1 .. 20];
  unshift @{$hash5{1}}, 1;
  pop @{$hash5{1}};
  splice(@{$hash5{1}}, 0, 9, 'a' .. 'j');
  print "\n => ", join " - ", @{$hash5{1}};
  splice(@{$hash5{1}}, 0, 3, {}, {}, {});
  print "\n => ", join " - ",@{$hash5{1}};
  $hash5{1}->[0]->{a} = 1;
  splice(@{$hash5{1}}, 0, 1, "A", "B");
  print "\n => ", join " - ",@{$hash5{1}};
  $hash5{1}->[2]->{X} = 1;
  delete $hash5{1}->[2];
  print "\n => ", join " - ",@{$hash5{1}};
  $hash5{1}->[3]->{xxxx} = 1;
  delete $hash5{5};
  print $err;
  print "\n => ", join " - ",@{$hash5{1}};

=cut
}

done_testing;
