use strict;
use warnings;
use Moo;
use Method::Signatures;
use Test::More;
use_ok('XML::Lenient');
no warnings "uninitialized";

my $p = XML::Lenient->new();
ok ('<' eq $p->{tagl}, "Correct left tag default");
ok ('>' eq $p->{tagr}, "Correct right tag default");
ok ('/' eq $p->{tagc}, "Correct close tag default");
ok (4 == scalar @{$p->{verbatim}}, "Correct default number of verbatim tags");
my $q = XML::Lenient->new(
     tagl => '<',
     tagr => '>',
     tagc => '/',
     verbatim => ['applet', 'code', 'pre', 'script']
);
is_deeply($q, $p, 'Explicit properties equal defaults');

done_testing;