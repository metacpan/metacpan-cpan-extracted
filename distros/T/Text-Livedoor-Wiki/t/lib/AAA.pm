package AAA ;
use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{AAA});
__PACKAGE__->n_args(1);

sub process {}
1;
