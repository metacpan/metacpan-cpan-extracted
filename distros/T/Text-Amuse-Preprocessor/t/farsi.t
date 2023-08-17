#!perl

use strict;
use warnings;
use utf8;
use File::Temp;
use Data::Dumper;
eval "use Text::Diff;";
my $use_diff;
if (!$@) {
    $use_diff = 4;
}

use Test::More tests => 5;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";
use Text::Amuse::Preprocessor;
use Text::Amuse::Preprocessor::HTML qw/html_to_muse html_file_to_muse/;

# print Dumper(read_file("t/testfiles/farsi.html"));
like read_file("t/testfiles/farsi.html"), qr/\x{200c}/;
my $semispace = "\x{200c}";
unlike $semispace, qr/\s/, "Semispace is not a perl space";

{
    my $muse = html_file_to_muse("t/testfiles/farsi.html", { lang => "fa" });
    like $muse, qr/\x{200c}/;
}

{
    my $muse = html_file_to_muse("t/testfiles/rtl.html", { lang => "en" });
    diag $muse;
    like $muse, qr{</?right>};
}

{
    my $muse = html_file_to_muse("t/testfiles/rtl.html", { lang => "fa" });
    diag $muse;
    unlike $muse, qr{</?right>}, "Muse has the <right> removed";
}

sub read_file {
    return Text::Amuse::Preprocessor->_read_file(@_);
}

sub write_file {
    return Text::Amuse::Preprocessor->_write_file(@_);
}
