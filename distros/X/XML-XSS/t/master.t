use strict;
use warnings;

use Test::More;                      # last test to print

use lib 't/lib';

use XML::XSS;

my $xss = XML::XSS->new;

my $master = $xss->master;

ok $master, 'master()';

$master->set( 'foo' => { pre => 'X' } );

my $r = XML::XSS->new->render( '<doc><foo>hi</foo></doc>' );

is $r => '<doc>Xhi</doc>', 'stylesheet inherit from master';

use A;
use Beta;

my $xml = "<doc><a/><b/><c/></doc>";

$DB::single = 1;

is( A->new->render( $xml ), '<doc>A<b></b><c></c></doc>' );
is( Beta->new->render( $xml ), '<doc>AB<c></c></doc>' );

my $full_xml = <<'END';
<doc>
    <a>aaa</a>
    <!-- comment -->
    <?foo attr="bar" ?>
    some text
</doc>
END

is( Beta->new->render( $full_xml )."\n", <<'END' );
<doc>[text]
    A[text]
    <comment> comment </comment>[text]
    [pi]<?foo attr="bar" ?>[text]
    some text
</doc>
END

done_testing();
