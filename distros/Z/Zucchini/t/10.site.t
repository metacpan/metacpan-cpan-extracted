#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Path::Class;
use Test::File::Contents;
use Test::More tests => 16;

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
$test_config = Zucchini::TestConfig->new();
isa_ok($test_config, q{Zucchini::TestConfig});
# create a Zucchini object using our test-config
$zucchini = Zucchini->new(
    {
        config_data => $test_config->site_config,
    }
);
isa_ok($zucchini, q{Zucchini});
ok(defined($zucchini->get_config), q{object has configuration data});

# process / generate the site
$zucchini->process_templates;

# make sure we get "what we expect" in the output directory
Zucchini::Test::compare_input_output($zucchini->get_config);

# make sure that the "swp" file wasn't copied
# 1. make sure it's in the template dir
ok (
    -e file($test_config->get_templatedir,q{_should_be_ignored_.swp}),
    q{'swp' file exists in templatedir}
);
# 2. make sure it's NOT in the ouput dir
ok (
    ! -e $test_config->get_outputdir . q{_should_be_ignored_.swp},
    q{'swp' file not copied to outdir}
);

# make sure the header/footer appear in index.html
file_contents_like(
    file($test_config->get_outputdir, q{index.html}),
    qr{^\(Header\)}ms,
    q{header file inserted correctly}
);
file_contents_like(
    file($test_config->get_outputdir, q{index.html}),
    qr{^\(Footer\)}ms,
    q{footer file inserted correctly}
);

# make sure files have expected content
file_contents_like(
    file($test_config->get_outputdir, q{author.html}),
    qr{^Chisel Wright$},
    q{author tag inserted correctly}
);
file_contents_like(
    file($test_config->get_outputdir, q{copyright.html}),
    qr{^&copy; 2006-2008 Chisel Wright\. All rights reserved\.$},
    q{copyright tag inserted correctly}
);
file_contents_like(
    file($test_config->get_outputdir, q{email.html}),
    qr{^c&#104;isel&#64;chizography.net$},
    q{email tag inserted correctly}
);

# one file with more than one tag; make sure they all appear in it
file_contents_like(
    file($test_config->get_outputdir, q{subdir1}, q{tags.html}),
    qr{^Chisel Wright}ms,
    q{author tag inserted correctly into multi-tag file}
);
file_contents_like(
    file($test_config->get_outputdir, q{subdir1}, q{tags.html}),
    qr{^&copy; 2006-2008 Chisel Wright\. All rights reserved\.$}ms,
    q{copyright tag inserted correctly into multi-tag file}
);
file_contents_like(
    file($test_config->get_outputdir, q{subdir1}, q{tags.html}),
    qr{^c&#104;isel&#64;chizography.net$}ms,
    q{email tag inserted correctly into multi-tag file}
);

# make sure image file is same at both ends
file_contents_identical(
    file($test_config->get_templatedir, q{subdir1}, q{abby.jpg}),
    file($test_config->get_outputdir,   q{subdir1}, q{abby.jpg}),
    q{image file untouched in transit}
);
