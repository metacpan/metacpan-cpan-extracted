package BBB;
use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{BBB});
__PACKAGE__->n_args(1);
__PACKAGE__->dependency('AAA');

sub process {}
1;
