use strict;
use warnings;
use inc::Module::Install;
use Module::Install::XSUtil;

my $MIN_VERSION     = '0.4.2';
my $MIN_VERSION_INT = '42';

my $INSTALL_DIR = ExtUtils::MakeMaker::prompt('Input the path to the install directory of KyTea', '/usr/local');
my $LIB_PATH    = "${INSTALL_DIR}/lib";
my $INC_PATH    = "${INSTALL_DIR}/include";
my $BIN_PATH    = "${INSTALL_DIR}/bin";

my $TEST_MODEL_DIR  = './model';
my $TEST_MODEL_FILE = "${TEST_MODEL_DIR}/test.txt";
my $TEST_MODEL      = "${TEST_MODEL_DIR}/test.mod";

all_from    'lib/Text/KyTea.pm';
readme_from 'lib/Text/KyTea.pm';

requires       'Carp';
build_requires 'Devel::CheckLib' => 0.98;
test_requires  'Test::More'      => 0.98;
test_requires  'Test::Base';
test_requires  'Test::Fatal';
test_requires  'Test::Warn';

cc_assert_lib(
    incpath  => $INC_PATH,
    libpath  => $LIB_PATH,
    lib      => 'kytea',
    function => 'return 0;',

    # Devel::CheckLib does not find C++ compilers.
    #header   => [qw|kytea/kytea.h kytea/kytea-struct.h|],

    #debug    => 1,
);

check_version( fetch_version() );
train_kytea();

rewrite_model_path() if $INSTALL_DIR ne '/usr/local';

requires_cplusplus;
cc_src_paths 'xs';
#cc_warnings;
cc_libs "-L$LIB_PATH -lkytea";
cc_include_paths $INC_PATH;

use_ppport 3.20;

tests        't/*.t';
author_tests 'xt';

resources(
    license    => 'http://dev.perl.org/licenses',
    repository => 'https://github.com/pawa-/Text-KyTea',
    bugtracker => 'https://github.com/pawa-/Text-KyTea/issues',
);

WriteAll;


sub train_kytea
{
    unlink $TEST_MODEL;

    print "\n";
    print "Training kytea...\n";

    my $ret = system("$BIN_PATH/train-kytea -full $TEST_MODEL_FILE -model $TEST_MODEL");

    die "Is '$INSTALL_DIR' the correct path to the install directory of KyTea?" if $ret != 0;

    print "Training kytea... done!\n";
    print "\n";
}

sub fetch_version
{
    my $version = qx($BIN_PATH/kytea --version 2>&1);
    chomp $version;

    $version =~ s/[^0-9]//g;
    $version =~ s/^0+//;

    return $version;
}

sub check_version
{
    my $version = shift;

    if ($version < $MIN_VERSION_INT)
    {
        $version = qx($BIN_PATH/kytea --version 2>&1) || 'version not found';
        chomp $version;

        die "This version of Text::KyTea supports KyTea version $MIN_VERSION and later."
          . " The version of your KyTea: $version";
    }
}

sub rewrite_model_path
{
    print "\n";
    print "Setting the path to the default model of KyTea...\n";

    my $pm_path = './lib/Text/KyTea.pm';

    open(my $in, '<', $pm_path) or die $!;
    my @lines = <$in>;
    close($in);

    for my $line (@lines)
    {
        if ($line =~ m|model\s+=>\s+'/usr/local/share/kytea/model.bin'|)
        {
            $line = qq|        model => "$INSTALL_DIR/share/kytea/model.bin",\n|;
            last;
        }
    }

    open(my $out, '>', $pm_path) or die $!;
    print {$out} @lines;
    close($out);

    print "Setting the path to the default model of KyTea... done!\n";
    print "\n";
}
