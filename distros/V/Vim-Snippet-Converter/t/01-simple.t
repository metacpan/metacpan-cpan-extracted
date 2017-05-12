#!perl -T

use Test::More tests => 4;
use lib 'lib/';

BEGIN {
	use_ok( 'Vim::Snippet::Converter' );
}

diag( "Testing Vim::Snippet::Converter $Vim::Snippet::Converter::VERSION, Perl $], $^X" );

my $content =<<SNIPPET;
;dt
use DateTime;
<<>>
;end

;dp
use Data::Dumper::Simple;
<<>>
;end
SNIPPET

my $output='';

open my $in , "<" , \$content;
open my $out , ">" , \$output;

my $scc = Vim::Snippet::Converter->new;

ok( $scc );

$scc->convert( $in , $out );

like( $output , qr{exec "Snippet dt use DateTime;<CR>".st.et."<CR>"} );
like( $output , qr{exec "Snippet dp use Data::Dumper::Simple;<CR>"\.st\.et\."<CR>"} );

close($in);
close($out);

