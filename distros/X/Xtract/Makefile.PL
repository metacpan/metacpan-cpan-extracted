use inc::Module::Install::DSL 1.04;

all_from       lib/Xtract.pm
requires_from  lib/Xtract.pm
requires_from  lib/Xtract/Publish.pm
requires       Alien::Win32::LZMA      4.65 if winlike
test_requires  Test::More              0.42
test_requires  Test::NoWarnings        0.084
test_requires  Test::Script            1.03
test_requires  Test::Database          1.09
test_requires  File::Spec              0.80
test_requires  File::Remove            1.42
test_requires  IO::Uncompress::Gunzip
test_requires  IO::Uncompress::Bunzip2
install_script xtract
