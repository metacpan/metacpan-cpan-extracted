use strict;
use warnings;
use Test::More;
use URI::XS qw/uri/;

plan skip_all => 'Data::Recursive required for testing Data::Recursive::clone' unless eval { require Data::Recursive; 1 };

# check that clone hook works
my $uri = uri("http://ya.ru");
my $cloned = Data::Recursive::clone($uri);
is($cloned, "http://ya.ru");
$cloned->host('mail.ru');
is($cloned, "http://mail.ru");
is($uri, "http://ya.ru");

done_testing();
