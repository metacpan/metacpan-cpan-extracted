
=pod

Test the regexp modifier flags, only C<xim> work

=cut

use strict;

use Test::More tests => 11;

use re::engine::TRE;

# No flag
ok "foo" =~ /\(.*\)/ => 'foo matches /\(.*\)/';
is $1, "foo" => 'foo captured into $1 with no flags';

ok "foo" =~ /\(.*\)/ => 'foo matches /\(.*\)/';
is $1, "foo" => 'foo captured into $1 with no flags';

# x
ok "foo" =~ /([fo]{3})/x => 'foo matches /([fo]{3})/';
is $1, "foo" => 'foo captured into $1 with no flags';

# i
ok "FOO" =~ /\(foo\)/i => 'FOO matches /(foo)/i';
is $1, "FOO" => 'FOO captured into $1 with /i';

# m
ok "FOO" =~ /\(foo\)/i => 'FOO matches /(foo)/i';
is $1, "FOO" => 'FOO captured into $1 with /i';

# g
is_deeply [ "a" =~ /\(a\)/g ], [ "a" ] => '/g with no continue';

#print for "aa" =~ /a/g;
