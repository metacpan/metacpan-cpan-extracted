#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 50;
use Text::Amuse::Compile::Templates;
use File::Spec::Functions qw/catfile/;
use Data::Dumper;
use File::Temp;

my $templates = Text::Amuse::Compile::Templates->new;

foreach my $method (qw/html css bare_html minimal_html latex bare_latex/) {
    ok($templates->$method);
    is ref($templates->$method), 'SCALAR', "$method returns a scalar ref";
    my $got = $templates->$method;
    $$got .= 'blablabla';
    ok(($$got ne ${$templates->$method}), "Modifing the scalar doesn't change anything");
}

$templates = populate_dir();

ok($templates->ttdir);
ok((! -d $templates->ttdir), "directory was deleted: " . $templates->ttdir);

chdir 't' or die "Couldn't change dir to t $!";

foreach my $method ($templates->names) {
    my $string = ${ $templates->$method };
    ok ($string =~ m/blablabla .* template/, "$method with closure ok");
}


foreach my $method ($templates->names) {
    ok($templates->$method);
    is ref($templates->$method), 'SCALAR', "$method returns a scalar ref";
    my $got = $templates->$method;
    $$got .= 'APPENDED';
    # diag $$got . ' ne ' . ${$templates->$method};
    ok(($$got ne ${$templates->$method}), "Modifing the scalar doesn't change anything");
}



sub populate_dir {
    my $dir = File::Temp->newdir;
    my $dirname = $dir->dirname;
    foreach my $f (qw/html.tt latex.tt bare.html
                      minimal.html bare-latex css/) {
        my $target = catfile($dirname, $f);
        diag "Creating $target";
        open (my $fh, ">:encoding(utf-8)", $target)
          or die "Couldn't open $target $!";
        print $fh "blablabla $f template\n";
        close $fh;
        ok((-f $target), "$target exists");
    }
    my $obj = Text::Amuse::Compile::Templates->new(ttdir => $dirname);
    return $obj;
}
