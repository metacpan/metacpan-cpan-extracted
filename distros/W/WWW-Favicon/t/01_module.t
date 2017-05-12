use Test::Base;
use Test::MockObject::Extends;

plan tests => 1 * blocks;

use WWW::Favicon;

my $f = WWW::Favicon->new;
my $mock = $f->{ua} = Test::MockObject::Extends->new( $f->{ua} );

sub detect {
    my $input = shift;
    my $get = sub {
        my $res = HTTP::Response->new(200);
        $res->content($input);
        $res->headers->header( Base => 'http://example.com/' );
        $res;
    };
    $mock->mock( get => $get );

    $f->detect('http://example.com/');
}

filters { input => 'detect' };

run_is;

__DATA__

=== rel="shortcut icon"
--- input
<html>
<link rel="shortcut icon" href="http://example.com/favicon.ico" type="image/vnd.microsoft.icon" />
</html>
--- expected: http://example.com/favicon.ico

=== rel="icon"
--- input
<html>
<link rel="icon" href="http://example.com/favicon.ico" type="image/vnd.microsoft.icon" />
</html>
--- expected: http://example.com/favicon.ico

=== starting by slash
--- input
<html>
<link rel="shortcut icon" href="/favicon.ico" type="image/vnd.microsoft.icon" />
</html>
--- expected: http://example.com/favicon.ico

=== starting by slash2
--- input
<html>
<link rel="shortcut icon" href="/foo/favicon.ico" type="image/vnd.microsoft.icon" />
</html>
--- expected: http://example.com/foo/favicon.ico

=== upper case attr
--- input
<html>
<link rel="Shortcut icon" href="http://example.com/favicon.ico" type="image/vnd.microsoft.icon" />
</html>
--- expected: http://example.com/favicon.ico

=== upper case tag
--- input
<html>
<LINK rel="Shortcut icon" href="http://example.com/favicon.ico" type="image/vnd.microsoft.icon" />
</html>
--- expected: http://example.com/favicon.ico

=== othrwise use favicon.ico located on root
--- input
<html>
</html>
--- expected: http://example.com/favicon.ico

