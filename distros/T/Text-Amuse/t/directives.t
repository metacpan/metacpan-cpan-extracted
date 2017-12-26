#!perl

use strict;
use warnings;

use Text::Amuse::Document;
use Text::Amuse::Functions qw/muse_fast_scan_header/;
use File::Temp;
use File::Spec::Functions qw/catfile/;
use Test::More tests => 2;

my $wd = File::Temp->newdir;

{
    my $muse = <<'EOF';
#-test-me-
continuation

#__test__me__

#0_test_me

#hello___There

#______________

#--------------

Random stuff

More random stuff
EOF
    my $exp = {
               testme => '',
               '0testme' => '',
               helloThere => '',
              };
    test_directives($muse, $exp, "dash-and-underscore");
}

sub test_directives {
    my ($muse, $exp, $filename) = @_;
    my $file = catfile($wd, $filename . '.muse');
    open (my $fh, '>:encoding(UTF-8)', $file) or die $!;
    print $fh $muse;
    close $fh;
    my $parsed = Text::Amuse::Document->new(file => $file)->parse_directives;
    is_deeply($parsed, $exp, $filename);
    my $parsed2 = muse_fast_scan_header($file);
    is_deeply($parsed2, $exp, "$filename with function");
    
}
