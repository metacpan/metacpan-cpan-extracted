#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use open ':std', ':encoding(utf8)';
use Test::Most;

use FindBin qw($Bin);
use lib "$Bin/lib";

use XML::Chain qw(xc);

subtest 'auto indent (synopsis of XML::Chain::Selector)' => sub {
    # simple indent
    my $simple = xc('div')->auto_indent(1)->c('div')->t('in')->root;
    eq_or_diff_text($simple->as_string, "<div>\n\t<div>in</div>\n</div>", 'auto indented simple');

    # namespaces && auto indentation
    my $user = xc('user', xmlns => 'http://testns')->auto_indent({chars=>' 'x4})
        ->a('name', '-' => 'Johnny Thinker')
        ->a('username', '-' => 'jt')
        ->c('bio')
            ->c('div', xmlns => 'http://www.w3.org/1999/xhtml')
                ->a('h1', '-' => 'about')
                ->a('p', '-' => '...')
                ->up
            ->a('greeting', '-' => 'Hey')
            ->up
        ->a('active', '-' => '1')
        ->root;
    eq_or_diff_text($user->as_string, user_as_string(), '=head1 SYNOPSIS; auto indented user');
};


done_testing;

sub user_as_string {
    my $usr = <<'__USER_AS_STRING__'
<user xmlns="http://testns">
    <name>Johnny Thinker</name>
    <username>jt</username>
    <bio>
        <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>about</h1>
            <p>...</p>
        </div>
        <greeting>Hey</greeting>
    </bio>
    <active>1</active>
</user>
__USER_AS_STRING__
    ;
    chomp($usr);
    return $usr;
}
