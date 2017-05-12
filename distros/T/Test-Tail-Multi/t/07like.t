use Test::More tests=>4;
use Test::Tail::Multi;

unlink "t/t_file";
open T, ">t/t_file" or die "Can't create t/t_file: $!";
close T;

add_file("t/t_file");
delay(2);
contents_like (sub { system("echo 'this is my test output' >t/t_file") },
               qr/test output/,
               "received what I expected");
contents_like (undef,
               qr/this is/,
               "could look at it twice");
contents_unlike (sub { system("echo 'this is my test output' >t/t_file") },
               qr/TEST output/,
               "didn't match (good)");
contents_unlike (undef,
               qr/This is/,
               "still didn't (good)");
unlink "t/t_file";
