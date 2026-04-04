use strict;
use warnings;
use Test::More;
use Text::Stencil;

my $r = Text::Stencil->new(
    header => '<!DOCTYPE html><html><head><title>Fortunes</title></head>'
            . '<body><table><tr><th>id</th><th>message</th></tr>',
    row    => '<tr><td>{0:int}</td><td>{1:html}</td></tr>',
    footer => '</table></body></html>',
);

my @rows = sort { $a->[1] cmp $b->[1] } (
    [11, '<script>alert("This should not be displayed in a browser alert box.");</script>'],
    [4, 'A bad random number generator: 1, 1, 1, 1, 1, 4.33e+67, 1, 1, 1'],
    [5, 'A computer program does what you tell it to do, not what you want it to do.'],
    [2, "A computer scientist is someone who fixes things that aren't broken."],
    [8, "A list is only as strong as its weakest link. \x{2014} Donald Knuth"],
    [0, 'Additional fortune added at request time.'],
    [3, 'After enough decimal places, nobody gives a damn.'],
    [7, 'Any program that runs right is obsolete.'],
    [10, 'Computers make very fast, very accurate mistakes.'],
    [6, "Emacs is a nice operating system, but I prefer UNIX. \x{2014} Tom Christaensen"],
    [9, 'Feature: A bug with seniority.'],
    [1, 'fortune: No such file or directory'],
    [12, "\x{30D5}\x{30EC}\x{30FC}\x{30E0}\x{30EF}\x{30FC}\x{30AF}\x{306E}\x{30D9}\x{30F3}\x{30C1}\x{30DE}\x{30FC}\x{30AF}"],
);

my $html = $r->render(\@rows);
ok defined $html, 'got output';
like $html, qr/^<!DOCTYPE html>/, 'starts with doctype';
like $html, qr/<\/html>$/, 'ends with html';
like $html, qr/&lt;script&gt;/, 'escapes <';
like $html, qr/&quot;/, 'escapes "';
like $html, qr/&#39;/, "escapes '";
like $html, qr/\x{30D5}\x{30EC}/, 'preserves unicode';
like $html, qr/<td>0<\/td><td>Additional/, 'id=0 fortune present';

my $count = () = $html =~ /<tr><td>/g;
is $count, 13, '13 data rows';

done_testing;
