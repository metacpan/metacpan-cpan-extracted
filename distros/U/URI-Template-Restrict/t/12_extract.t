use Test::Base;
use Test::Deep;
use URI::Template::Restrict;

plan tests => 1 * blocks;

filters { expected => ['eval'] };

run {
    my $block    = shift;
    my $template = URI::Template::Restrict->new($block->input);

    my %deparse = $template->extract($block->uri);
    cmp_deeply \%deparse => $block->expected, $block->name;
};

__END__
=== simple
--- input: http://example.com/{foo}/{bar}
--- expected: { foo => 'x', bar => 'y' }
--- uri: http://example.com/x/y

=== escaped
--- input: http://example.com/{foo}/{bar}
--- expected: { foo => ' ', bar => '@' }
--- uri: http://example.com/%20/%40

=== unescaped
--- input: http://example.com/{foo}/{bar}
--- expected: { foo => '$', bar => '@' }
--- uri: http://example.com/%24/%40

=== no value
--- input: http://example.com/{foo}/{bar}
--- expected: { foo => 'x', bar => undef }
--- uri: http://example.com/x/

=== no values
--- input: http://example.com/{foo}/{bar}
--- expected: { foo => undef, bar => undef }
--- uri: http://example.com//

=== multiple variables
--- input: http://example.com/{foo}/{foo}
--- expected: { foo => 'x' }
--- uri: http://example.com/x/x

=== simple prefix
--- input: http://example.com{-prefix|/|foo}
--- expected: { foo => 'x' }
--- uri: http://example.com/x

=== empty prefix
--- input: http://example.com{-prefix|/|foo}
--- expected: { foo => undef }
--- uri: http://example.com

=== array prefix
--- input: http://example.com{-prefix|/|foo}
--- expected: { foo => [qw(x y z)] }
--- uri: http://example.com/x/y/z

=== array, omitted prefix
--- input: http://example.com{-prefix|/|foo}
--- expected: { foo => ['', 'y', 'z'] }
--- uri: http://example.com//y/z

=== escaped prefix
--- input: http://example.com{-prefix|/|foo}
--- expected: { foo => [' ', '@'] }
--- uri: http://example.com/%20/%40

=== unescaped prefix
--- input: http://example.com{-prefix|/|foo}
--- expected: { foo => ['$', '@'] }
--- uri: http://example.com/%24/%40

=== simple suffix
--- input: http://example.com/{-suffix|/|foo}
--- expected: { foo => 'x' }
--- uri: http://example.com/x/

=== empty suffix
--- input: http://example.com/{-suffix|/|foo}
--- expected: { foo => undef }
--- uri: http://example.com/

=== array suffix
--- input: http://example.com/{-suffix|/|foo}
--- expected: { foo => [qw(x y)] }
--- uri: http://example.com/x/y/

=== array, omitted suffix
--- input: http://example.com/{-suffix|/|foo}
--- expected: { foo => ['', 'y', 'z'] }
--- uri: http://example.com//y/z/

=== escaped suffix
--- input: http://example.com/{-suffix|/|foo}
--- expected: { foo => [' ', '@'] }
--- uri: http://example.com/%20/%40/

=== escaped suffix
--- input: http://example.com/{-suffix|/|foo}
--- expected: { foo => ['$', '@'] }
--- uri: http://example.com/%24/%40/

=== single join on query part
--- input: http://example.com/?{-join|&|foo}
--- expected: { foo => 'x' }
--- uri: http://example.com/?foo=x

=== multiple join on query part
--- input: http://example.com/?{-join|&|foo,bar,baz,quux}
--- expected: { foo => 'x', bar => 'y', baz => '', quux => undef }
--- uri: http://example.com/?foo=x&bar=y&baz=

=== single escaped join on query part
--- input: http://example.com/?{-join|&|foo}
--- expected: { foo => '@' }
--- uri: http://example.com/?foo=%40

=== single unescaped join on query part
--- input: http://example.com/?{-join|&|foo}
--- expected: { foo => '@' }
--- uri: http://example.com/?foo=@

=== multiple escaped join on query part
--- input: http://example.com/?{-join|&|foo,bar,baz,quux}
--- expected: { foo => ' ', bar => '@', baz => '', quux => undef }
--- uri: http://example.com/?foo=%20&bar=%40&baz=

=== multiple unescaped join on query part
--- input: http://example.com/?{-join|&|foo,bar,baz,quux}
--- expected: { foo => '$', bar => '@', baz => '', quux => undef }
--- uri: http://example.com/?foo=%24&bar=%40&baz=

=== multiple, omitted join on query part
--- input: http://example.com/?{-join|&|foo,bar,baz,quux}
--- expected: { foo => undef, bar => '', baz => 'z', quux => undef }
--- uri: http://example.com/?bar=&baz=z

=== undefined join on query part
--- input: http://example.com/?{-join|&|quux}
--- expected: { quux => undef }
--- uri: http://example.com/?

=== single join on path part
--- input: http://example.com/{-join|;|foo}
--- expected: { foo => 'x' }
--- uri: http://example.com/foo=x

=== multiple join on path part
--- input: http://example.com/{-join|;|foo,bar,baz,quux}
--- expected: { foo => 'x', bar => 'y', baz => '', quux => undef }
--- uri: http://example.com/foo=x;bar=y;baz=

=== single escaped join on path part
--- input: http://example.com/{-join|;|foo}
--- expected: { foo => '@' }
--- uri: http://example.com/foo=%40

=== single unescaped join on path part
--- input: http://example.com/{-join|;|foo}
--- expected: { foo => '@' }
--- uri: http://example.com/foo=@

=== multiple escaped join on path part
--- input: http://example.com/{-join|;|foo,bar,baz,quux}
--- expected: { foo => ' ', bar => '@', baz => '', quux => undef }
--- uri: http://example.com/foo=%20;bar=%40;baz=

=== multiple unescaped join on path part
--- input: http://example.com/{-join|;|foo,bar,baz,quux}
--- expected: { foo => '$foo', bar => '@bar', baz => '', quux => undef }
--- uri: http://example.com/foo=$foo;bar=@bar;baz=

=== multiple, omitted join on path part
--- input: http://example.com/{-join|;|foo,bar,baz,quux}
--- expected: { foo => undef, bar => '', baz => 'z', quux => undef }
--- uri: http://example.com/bar=;baz=z

=== undefined join on path part
--- input: http://example.com/{-join|;|quux}
--- expected: { quux => undef }
--- uri: http://example.com/

=== single list
--- input: http://example.com/{-list|/|foo}
--- expected: { foo => ['y'] }
--- uri: http://example.com/y

=== multiple list
--- input: http://example.com/{-list|/|foo}
--- expected: { foo => [qw(x y z)] }
--- uri: http://example.com/x/y/z

=== single escaped list
--- input: http://example.com/{-list|/|foo}
--- expected: { foo => ['@'] }
--- uri: http://example.com/%40

=== single unescaped list
--- input: http://example.com/{-list|/|foo}
--- expected: { foo => ['@'] }
--- uri: http://example.com/@

=== multiple escaped list
--- input: http://example.com/{-list|/|foo}
--- expected: { foo => [' ', '@'] }
--- uri: http://example.com/%20/%40

=== multiple unescaped list
--- input: http://example.com/{-list|/|foo}
--- expected: { foo => ['$', '@'] }
--- uri: http://example.com/$/@

=== empty value list
--- input: http://example.com/{-list|/|foo}
--- expected: { foo => ['x', '', 'z'] }
--- uri: http://example.com/x//z

=== empty value list
--- input: http://example.com/{-list|/|foo}
--- expected: { foo => ['', 'y', 'z'] }
--- uri: http://example.com//y/z

=== empty array list
--- input: http://example.com/{-list|/|foo}
--- expected: { foo => undef }
--- uri: http://example.com/

=== bugs avatar api of mbga.jp OpenSocial platform
--- input: http://example.com/avatar/{userId}/{groupId}/{-join|;|size,view,emotion,dimension,transparent,type,extension,motion,scene,appId}
--- expected: { userId => '@me', groupId => '@self', size => 'large', view => undef, emotion => 'smile', dimension => undef, transparent => 'true', type => undef, extension => 'png', motion => undef, scene => undef, appId => '@app' }
--- uri: http://example.com/avatar/@me/@self/size=large;transparent=true;appId=@app;extension=png;emotion=smile
