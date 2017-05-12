Just add the inc/ directory to your Module::Build-based file, and then in
Build.PL write something like:

<<<<<<<<<
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    .
    .
    .
)
>>>>>>>>>

Then you'll be able to type "./Build runtest" and "./Build distruntest"
to test using Test::Run::CmdLine.
