use utf8;
use strict;
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

use Text::WagnerFischer::Amharic qw(distance);


# Calculate distance with the default penalty costs (weights):
print distance ( "ፀሐይ", "ጸሀይ" ), " is the distance between 'ፀሐይ' and 'ጸሀይ'\n"; # prints "2"

# Calcualte distance with a supplied costs array:
print distance ( [0,2,3, 1,2,1, 1,1,1, 1], "ፀሐይ", "ጸሀይ" ), " is the distance between 'ፀሐይ' and 'ጸሀይ' (supplied costs array)\n";  # prints "2"



# Calcualte distances between a word and a list of comparison words:

my @words = ( "ፀሐይ",  "ፀሓይ", "ፀሀይ", "ፀሃይ", "ጸሐይ", "ጸሓይ", "ጸሀይ", "ጸሃይ" );

my @distances = distance ( "ፀሐይ", @words );
print "@distances are the distance between 'ፀሐይ' and comparison list [ @words ]\n"; # prints "0 1 1 1 1 2 2 2"

@distances = distance ( [0,2,3, 1,1,1, 1,1,1, 2], "ፀሐይ", @words );
print "@distances are the distance between 'ፀሐይ' and comparison list [ @words ] with a supplied costs array\n"; # prints "0 1 1 2 1 2 2 3"

