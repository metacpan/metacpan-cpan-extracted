use strict;
use Test;

BEGIN { plan tests => 5 }

use IO::File;
use Text::Tmpl;

use constant TEMPLATE => 't/3_huge_input.tmpl';
use constant COMPARE  => 't/3_huge_input.comp';

my($return, $subcontext, $compare, $output);
my $context = new Text::Tmpl;
if (! defined $context) {
    ok(0);
    exit(0);
}

my $comp_fh = new IO::File COMPARE, 'r';
if (! defined $comp_fh) {
    ok(0);
    exit(0);
}

{
    local $/ = undef;
    $compare = <$comp_fh>;
}

$comp_fh->close;

$context->set_strip(0);

$return = $context->set_value( 'var1' => '-' x 40000 );
ok($return);

$return = $context->set_value( '-' x 40000 => 'value1' );
ok($return);

$subcontext = $context->loop_iteration( '-' x 40000 );
ok(defined $subcontext);

my $thing = qq#
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
the quick brown fox jumped over the lazy dog the quick brown fox jumped over
#;

$return = $context->set_value( 'var1' => $thing );
ok($return);

$output = $context->parse_file(TEMPLATE);
if (! defined($output)) {
    print "not ok 5\n";
}

ok($output, $compare);
