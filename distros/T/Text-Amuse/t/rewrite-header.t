use strict;
use warnings;
use utf8;
use Test::More tests => 2;
use File::Temp;
use File::Spec::Functions qw/catfile/;
use Text::Amuse::Functions qw/muse_rewrite_header/;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

BEGIN {
    if (!eval q{ use Test::Differences; 1 }) {
        *eq_or_diff = \&is_deeply;
    }
}

my $wd = File::Temp->newdir;

{
    my $orig = <<'MUSE';
#title Hello there
#--author-- Hey
#__notes__ First
second
and
third

#hello
there

#edit
#replace 1

Prova
MUSE

    my $file = catfile($wd, "first.muse");

    write_file($file, $orig);

    my $exp = <<'MUSE';
#title Hello there
#author Hey
#notes First
second
and
third
#hello there
#edit Hello
#replace 2
#append 10

Prova

MUSE

    muse_rewrite_header($file, {
                                edit => 'Hello',
                                replace => 2,
                                append => 10,
                               });
    eq_or_diff(read_file($file), $exp);

    $exp = <<'MUSE';
#title Rewritten ćiao
#author Hey
#notes First
second
and
third
#hello there
#edit Hello
#replace 3
#append 12

Prova


MUSE

    muse_rewrite_header($file, {
                                edit => 'Hello',
                                replace => 3,
                                append => 12,
                                title => 'Rewritten ćiao',
                               });
    eq_or_diff(read_file($file), $exp);



}

sub write_file {
    my ($file, $body) = @_;
    open (my $fh, ">:encoding(UTF-8)", $file) or die $!;
    print $fh $body;
    close $fh;
    return $file;
}

sub read_file {
    my ($file) = @_;
    open (my $fh, "<:encoding(UTF-8)", $file) or die $!;
    local $/ = undef;
    my $body = <$fh>;
    close $fh;
    return $body;
}
