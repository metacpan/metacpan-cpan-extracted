#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More tests => 10;

use Path::Class;
use File::Temp qw(tempdir);

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/lib};
    use Zucchini::Test;
    use Zucchini::TestConfig;
}

BEGIN {
    use_ok 'Zucchini';
}

# evil globals
my ($test_config, $zucchini);

# get a test_config object
$test_config = Zucchini::TestConfig->new(
    {
        templatedir =>
            dir(
                $FindBin::Bin,
                'testdata',
                'impressum'
            )
    }
);
isa_ok($test_config, q{Zucchini::TestConfig});
# create a Zucchini object using our test-config
$zucchini = Zucchini->new(
    {
        config_data => $test_config->site_config,
        site => 'impressum',
    }
);
isa_ok($zucchini, q{Zucchini});
ok(defined($zucchini->get_config), q{object has configuration data});

my %testinfo_of = (
    'normal.html' => {
        always_process => 0,
    },
    'impressum.html' => {
        always_process => 1,
    },
    'special.imp' => {
        always_process => 1,
    },
);

# process the site once
$zucchini->process_templates;

# make sure our file(s) of interest exist, and make a note of their last
# modified time
my $directory = $zucchini->get_config->get_siteconfig->{output_dir};
diag $directory;
foreach my $file (keys %testinfo_of) {
    my $filename = file($directory, $file);
    ok(
        -f $filename,
        qq{$file exists in output_dir}
    );

    # store last modified time
    $testinfo_of{$file}->{mtime_1} = (stat($filename))[9];
}

# process the site a second time
sleep(1); # make sure there's at least 1 second difference for modified files
$zucchini->process_templates;

foreach my $file (keys %testinfo_of) {
    my $filename = file($directory, $file);
    $testinfo_of{$file}->{mtime_2} = (stat($filename))[9];

    # make sure a "special" file has
    if ($testinfo_of{$file}->{always_process}) {
        ok(
            $testinfo_of{$file}->{mtime_1}
            <
            $testinfo_of{$file}->{mtime_2},
            qq{$file has been updated}
        );
    }

    # make sure a "normal" file hasn't been re-written
    else {
        ok(
            $testinfo_of{$file}->{mtime_1}
            ==
            $testinfo_of{$file}->{mtime_2},
            qq{$file is unchanged}
        );
    }
}
