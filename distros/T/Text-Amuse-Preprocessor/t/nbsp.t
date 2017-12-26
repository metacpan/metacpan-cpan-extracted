#!perl

use strict;
use warnings;
use utf8;


use Test::More tests => 2;
use Data::Dumper;

use Text::Amuse::Preprocessor;

my $in = <<'MUSE';

 hello  there
<verbatim>  </verbatim>

{{{
  
}}}

 hello  there

MUSE

{
    my $exp = <<'MUSE';

~~hello~~~~there
<verbatim>  </verbatim>

{{{
  
}}}

~~hello~~~~there

MUSE
    my $out;

    my $pp = Text::Amuse::Preprocessor->new(input => \$in,
                                            output => \$out,
                                            show_nbsp => 1);
    $pp->process;
    is $out, $exp;
}

{
    my $exp = <<'MUSE';

 hello  there
<verbatim>  </verbatim>

{{{
  
}}}

 hello  there

MUSE
    my $out;

    my $pp = Text::Amuse::Preprocessor->new(input => \$in,
                                            output => \$out,
                                            remove_nbsp => 1,
                                            show_nbsp => 1);
    $pp->process;
    is $out, $exp, "remove_nbsp has the precedence";
}
