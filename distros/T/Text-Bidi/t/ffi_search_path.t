use 5.010;
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use Symbol qw(gensym);

# Start ffi.t with an unrelated installation ahead of every inherited path.
# The test must select its own distribution before loading Text::Bidi.
my $installed = tempdir(CLEANUP => 1);
mkdir "$installed/Text" or die "Cannot create fixture directory: $!";
open my $old, '>', "$installed/Text/Bidi.pm" or die "Cannot write fixture: $!";
print {$old} "die qq(Unrelated installed Text::Bidi loaded\\n);\n";
close $old or die "Cannot close fixture: $!";

my $test = File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), 'ffi.t'));
my @inc = map { ('-I', $_) } grep { !ref } @INC;
local $ENV{PERL5OPT} = '';
my $err = gensym;
my $pid = open3(my $in, my $out, $err, $^X, '-I', $installed, @inc, $test);
close $in;
local $/;
my $stdout = <$out> // '';
my $stderr = <$err> // '';
waitpid $pid, 0;
is $?, 0, 'ffi.t tests its distribution despite an older installation first in the search path'
    or diag "$stdout$stderr";

done_testing;
