use utf8;
use Text::WagnerFischer::Amharic qw(distance);


print distance ( "ፀሐይ", "ጸሀይ" ), "\n";  # prints "2"

print distance ( [0,2,3, 1,2,1, 1,1,1, 1], "ፀሐይ", "ጸሀይ" ), "\n";  # prints "2"

my @words = ( "ፀሐይ",  "ፀሓይ", "ፀሀይ", "ፀሃይ", "ጸሐይ", "ጸሓይ", "ጸሀይ", "ጸሃይ" );

my @distances = distance ( "ፀሐይ", @words );
print "@distances\n"; # prints "0 1 1 1 1 2 2 2"

@distances = distance ( [0,2,3, 1,1,1, 1,1,1, 2], "ፀሐይ", @words );
print "@distances\n"; # prints "0 1 1 2 1 2 2 3"



