use Test::More;
use_ok 'Tie::FileSection';
use File::Basename qw( dirname );

# index of line start at 1, let's undef for last_line for file-oef
my @tests = (
      [ -3, 5,  "three four", "first negative last positive" ],
      [ 1, 1,  "one", "header" ],
      [ -1, undef,  "five", "footer" ],
      [ 2, -2,  "two three four", "content" ],
      [ undef, undef,  "one two three four five", "slurp" ],
      [ -3, -2,  "three four", "both negative" ],
   );
   
my %pos = (
   one => 5,
   two => 10,
   three => 17,
   four => 23,
   five => 27,
);
#~ my %index = (
   #~ one => 1, two => 2, three => 3, four => 4, five => 5
#~ );
my $pos_orig = tell( *DATA );

for my $test ( @tests ) {
   my $F = Tie::FileSection->new( file => \*DATA, first_line => $test->[0], last_line => $test->[1] );
   cmp_ok join(' ', map{ s/[\r\n]+//; $_; } <$F>), 'eq', $test->[2], $test->[3].' data';
   ok eof($F), $test->[3] . ' EOF';
   seek(*DATA, $pos_orig, 0);
   
   #test current line and pos
   #pos are considered to be relative to the whole file, not to the section.(okay, a bit weired)
   $F = Tie::FileSection->new( file => \*DATA, first_line => $test->[0], last_line => $test->[1] );
   while(defined( my $line = <$F>)){
      $line =~ s/[\r\n]+//;
      cmp_ok( (tell($F)//0) - $pos_orig, '==', $pos{$line}, $test->[3] . " tell for '$line'");
      #~ cmp_ok $.//0, '==', $index{$line}, $test->[3] . " \$. for '$line'";
   }
   seek(*DATA, $pos_orig, 0);
}

done_testing( );

__DATA__
one
two
three
four
five