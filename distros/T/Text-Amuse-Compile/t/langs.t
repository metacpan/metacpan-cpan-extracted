#!perl

use strict;
use warnings;
use Test::More tests => 68;

use Text::Amuse::Compile::Utils qw/read_file write_file/;
use File::Spec::Functions qw/catfile catdir/;
use File::Temp;
use Text::Amuse::Compile;

my $temp = File::Temp->newdir;

my $wd = $temp->dirname;
diag "Working in $wd";

my $c = Text::Amuse::Compile->new(html => 1);

foreach my $code (qw/cs de en es fi fr hr it
                     ar fa he
                     sr ru nl pt tr mk/) {
    my $target = catfile($wd, $code . '.muse');
    write_file($target, "#title test\n#lang $code\n\nBlablabla\n");
    $c->compile($target);
    is $c->parse_muse_header($target)->language, $code;
    my $html = catfile($wd, $code . '.html');
    ok(-f $html, "$html produced");
    my $content = read_file($html);
    my $exp =
      qq{<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$code" lang="$code"};
    like $content, qr/\Q$exp\E/, "lang $code found ok";
    my $fake = $code . 'x';
    write_file($target, "#title test\n#lang $fake\n\nBlablabla\n");
    $c->compile($target);
    $content = read_file($html);
    $exp = qq{<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en"};
    like $content, qr/\Q$exp\E/, "lang en found ok for fake docs";
}
