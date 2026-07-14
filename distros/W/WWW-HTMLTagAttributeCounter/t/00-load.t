#!/usr/bin/env perl

use Test::More tests => 14;

BEGIN {
    use_ok('LWP::UserAgent');
    use_ok('HTML::TokeParser::Simple');
    use_ok('overload');
    use_ok('Class::Data::Accessor');
	use_ok( 'WWW::HTMLTagAttributeCounter' );
}

diag( "Testing WWW::HTMLTagAttributeCounter $WWW::HTMLTagAttributeCounter::VERSION, Perl $], $^X" );

can_ok( 'WWW::HTMLTagAttributeCounter', qw/new ua error result count result_readable/ );

my $c = WWW::HTMLTagAttributeCounter->new;
isa_ok($c, 'WWW::HTMLTagAttributeCounter');
isa_ok($c->ua, 'LWP::UserAgent');

my $html = <<'END';
<div class="foo">
</div>
<span id="bar"></span>
<span id="bar"></span>
<span id="bar"></span>
END

my $result = $c->count( \$html, 'div' );

is_deeply( $result, $c->result, 'return from count() matches result()');
is_deeply( $result, { div => 1 } );

$result = $c->count( \$html, 'id', 'attr' );
is_deeply( $result, { id => 3 } );

$result = $c->count( \$html, [ qw/div span foo/ ] );
is_deeply( $result, { div => 1, span => 3, foo => 0 } );

$c->count( \$html, [ qw/div span foo/ ] );
is( "$c", $c->result_readable );
is( "$c", "1 div, 0 foo and 3 span");















