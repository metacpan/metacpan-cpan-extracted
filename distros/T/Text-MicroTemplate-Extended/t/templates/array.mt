? extends 'array_base';

? block content => sub {
? while (my $var = shift @$array) {
?= $var
? }
? }
