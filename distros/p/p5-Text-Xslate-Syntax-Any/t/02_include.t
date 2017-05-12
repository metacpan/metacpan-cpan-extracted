use strict;
use warnings;

use Test::More;
use Text::Xslate;

my $tx = Text::Xslate->new(syntax => 'Any', cache => 0, path => [ 't/template', ]);

foreach my $case ({ name => 'Kolon',     file => 'parent.tx', },
                  { name => 'Metakolon', file => 'parent.mtx', },
                  { name => 'TTerse',    file => 'parent.tt', }){
    is($tx->render($case->{file}, { foo => 'Hello World'}), <<'END;', qq{Parent is $case->{name}});
Kolon {Hello World}
Metakolon {Hello World}
TT {Hello World,Hello World,Hello World}
END;
}

done_testing;

