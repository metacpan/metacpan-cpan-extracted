#!perl -w
use strict;
use Text::Clevy;
use FindBin qw($Bin);

my $path = $Bin;
my $tx = Text::Clevy->new(
    path      => [$path],
    cache_dir =>  $path,
);

print $tx->render('hello.tpl', { lang => 'smarty' });
