use Test::Base;
use URI::Template::Restrict;

plan tests => 4 * blocks;

filters { params => ['eval'] };

run {
    my $block    = shift;
    my $name     = $block->name;
    my $template = URI::Template::Restrict->new($block->input);
    my $params   = $block->params;

    my $str = $template->process_to_string(defined $params ? $params : ());
    is $str => $block->expected, "process_to_string: $name";
    ok !ref $str, "is not reference";

    my $uri = $template->process($params ? $params : ());
    is $uri => $block->expected, "process: $name";
    isa_ok $uri => 'URI';
};

__END__
=== simple
--- input: http://example.com/{foo}/{bar}
--- params: { foo => 'x', bar => 'y' }
--- expected: http://example.com/x/y

=== escaped
--- input: http://example.com/{foo}/{bar}
--- params: { foo => ' ', bar => '@' }
--- expected: http://example.com/%20/%40

=== no value
--- input: http://example.com/{foo}/{bar}
--- expected: http://example.com//

=== no valid keys
--- input: http://example.com/{foo}/{bar}
--- params: { baz => 'x', quux => 'y' }
--- expected: http://example.com//

=== multiple variables
--- input: http://example.com/{foo}/{foo}
--- params: { foo => 'x' }
--- expected: http://example.com/x/x

=== default value
--- input: http://example.com/{foo=x}/{bar=y}
--- expected: http://example.com/x/y

=== simple prefix
--- input: http://example.com{-prefix|/|foo}
--- params: { foo => 'x' }
--- expected: http://example.com/x

=== empty prefix
--- input: http://example.com{-prefix|/|foo}
--- expected: http://example.com

=== array prefix
--- input: http://example.com{-prefix|/|foo}
--- params: { foo => [qw(x y)] }
--- expected: http://example.com/x/y

=== empty array prefix
--- input: http://example.com{-prefix|/|foo}
--- params: { foo => [] }
--- expected: http://example.com

=== simple suffix
--- input: http://example.com/{-suffix|/|foo}
--- params: { foo => 'x' }
--- expected: http://example.com/x/

=== empty suffix
--- input: http://example.com/{-suffix|/|foo}
--- expected: http://example.com/

=== array suffix
--- input: http://example.com/{-suffix|/|foo}
--- params: { foo => [qw(x y)] }
--- expected: http://example.com/x/y/

=== empty array suffix
--- input: http://example.com/{-suffix|/|foo}
--- params: { foo => [] }
--- expected: http://example.com/

=== single join
--- input: http://example.com/?{-join|&|foo}
--- params: { foo => 'x' }
--- expected: http://example.com/?foo=x

=== multiple join
--- input: http://example.com/?{-join|&|foo,bar,baz,quux}
--- params: { foo => 'x', bar => 'y', baz => '' }
--- expected: http://example.com/?foo=x&bar=y&baz=

=== undefined join
--- input: http://example.com/?{-join|&|quux}
--- expected: http://example.com/?

=== single list
--- input: http://example.com/{-list|/|foo}
--- params: { foo => ['y'] }
--- expected: http://example.com/y

=== multiple list
--- input: http://example.com/{-list|/|foo}
--- params: { foo => [qw(x y z)] }
--- expected: http://example.com/x/y/z

=== empty value list
--- input: http://example.com/{-list|/|foo}
--- params: { foo => ['x', '', 'z'] }
--- expected: http://example.com/x//z

=== empty array list
--- input: http://example.com/{-list|/|foo}
--- params: { foo => [] }
--- expected: http://example.com/

=== undefined list
--- input: http://example.com/{-list|/|foo}
--- expected: http://example.com/
