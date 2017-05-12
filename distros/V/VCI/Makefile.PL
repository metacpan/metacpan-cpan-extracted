use strict;
use inc::Module::Install;

all_from 'lib/VCI.pm';
homepage   'http://vci.everythingsolved.com/';
repository 'bzr://bzr.everythingsolved.com/vci/stable';

requires 'Moose' => '0.27';
requires 'MooseX::Method';
requires 'DateTime';
requires 'Path::Abstract' => '0.093'; # This was when Underload was introduced.
requires 'DateTime::Format::DateParse';
# 0.06 has a bug with diff formats that lack a "diff file1 file2"
# header.
requires 'Text::Diff::Parser' => '0.07';

# These are modules only required by certain VCSes, but
# but into the general requirements to make things simpler
# for people using this module.
requires 'IPC::Cmd' => 0.42; # Error return values changed.
requires 'Module::Load::Conditional' => 0.24; # For taint safety in IPC::Cmd.
requires 'XML::Simple';
requires 'LWP::UserAgent';
# For buffer support in IPC::Cmd under Windows.
if ($^O eq 'MSWin32') {
    requires 'IPC::Run' => 0.55;
}


test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::Warn';

recommends 'SVN::Core' => '1.2.0';
recommends 'Git';

makemaker_args(
    # We have to "touch" because otherwise git dies during tests, complaining
    # that the repo is invalid because there is no refs directory.
    dist => { PREOP => 'touch t/repos/git/test.git/refs/.mft_exists' }
);

WriteAll;
