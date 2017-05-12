use strict;
use Test;

use constant MAXVARNAMESIZE => 100;
use constant MAXCONTENTSIZE => 100;

BEGIN { plan tests => MAXVARNAMESIZE }

use Text::Tmpl;

foreach my $varnamesize ( 1 .. MAXVARNAMESIZE ) {
    my $varname  = 'a' x $varnamesize;
    my $template = '<!--#loop "l"--><!--#echo $' . $varname
                 . '--><!--#endloop-->';
    my $ctx = new Text::Tmpl;

    foreach my $contentsize ( 1 .. MAXCONTENTSIZE ) {
        my $ictx = $ctx->loop_iteration('l');
        $ictx->set_value($varname, 'v' x $contentsize);
    }

    my $output = $ctx->parse_string($template);

    ok($output, 'v' x numo(MAXCONTENTSIZE));
}

sub numo {
    my $sum = 0;

    foreach ( 1 .. shift ) {
        $sum += $_;
    }
    return $sum;
}
