#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use File::Find;
use Path::Class;
use Test::More tests => 21;

BEGIN {
    use FindBin;
    use lib qq{$FindBin::Bin/lib};
    use Zucchini::TestConfig;
    use Zucchini::Test;
}

BEGIN {
    use_ok 'Zucchini::Template';
}

can_ok(
    'Zucchini::Template',
    qw(
        new

        get_config
        set_config

        get_ttobject
        set_ttobject

        directory_contents
        file_checksum
        file_modified
        ignore_directory
        ignore_file
        item_name
        process_directory
        process_file
        process_site
        relative_path_from_full
        same_file
        show_destination
        template_file
        
        _prepare_template_object
    )
);

# evil globals
my ($zucchini_tpl, $test_config, @input_tree, @output_tree, $zucchini_cfg);
my ($tpl_object, $tt_service);

# get a test_config object
$test_config = Zucchini::TestConfig->new();
isa_ok($test_config, q{Zucchini::TestConfig});

# create a ::Template object
$zucchini_tpl = Zucchini::Template->new(
    {
        config => $test_config->get_config,
    }
);
isa_ok($zucchini_tpl, q{Zucchini::Template});
ok(defined($zucchini_tpl->get_config), q{object has configuration data});

# perform the magic
$zucchini_tpl->process_site;

# make sure we get "what we expect" in the output directory
Zucchini::Test::compare_input_output($zucchini_tpl->get_config);

# the current/default ::Template should NOT have any tt_options
is (
    ref($zucchini_tpl->get_config->get_siteconfig()->{tt_options}),
    q{},
    q{default site has NO tt_options}
);

#
# test tt settings without any overrides in the config
#
# grab the TT object
$tpl_object = $zucchini_tpl->get_ttobject;
isa_ok($tpl_object, 'Template');
# grab the "service"
$tt_service = $tpl_object->service;
isa_ok($tt_service, 'Template::Service');

# we should have nothing in PRE_PROCESS
is(
    scalar @{ $tt_service->{PRE_PROCESS} },
    0,
    q{PRE_PROCESS is empty}
);
# we should have "my_header" in the pre-process
is(
    scalar @{ $tt_service->{POST_PROCESS} },
    0,
    q{POST_PROCESS is empty}
);
# we should have disabled eval perl
is(
    $tt_service->context->{EVAL_PERL},
    0,
    q{EVAL_PERL is enabled}
);

#
# Test: TT_OPTIONS
#
# create a ::Template object
$zucchini_cfg = Zucchini::Config->new(
    {
        config_data => $test_config->site_config,
        site => q{ttoption_site},
    }
);
isa_ok($zucchini_cfg, q{Zucchini::Config});
$zucchini_tpl = Zucchini::Template->new(
    {
        config => $zucchini_cfg,
    }
);
isa_ok($zucchini_tpl, q{Zucchini::Template});
ok(defined($zucchini_tpl->get_config), q{object has configuration data});
# does it have tt_options?
is (
    ref($zucchini_tpl->get_config->get_siteconfig()->{tt_options}),
    q{HASH},
    q{ttoption_site has tt_options}
);
# manually set the ttobject (usually happens "as required" in process_file()
$zucchini_tpl->_prepare_template_object;

# grab the TT object
$tpl_object = $zucchini_tpl->get_ttobject;
isa_ok($tpl_object, 'Template');
# grab the "service"
$tt_service = $tpl_object->service;
isa_ok($tt_service, 'Template::Service');

# we should have "my_header" in the pre-process
ok(
    grep { m{\Amy_header\z} }
        @{ $tt_service->{PRE_PROCESS} },
    q{PRE_PROCESS contains my_header}
);
# we should have "my_header" in the pre-process
ok(
    grep { m{\Amy_footer\z} }
        @{ $tt_service->{POST_PROCESS} },
    q{POST_PROCESS contains my_footer}
);
# we should have enabled eval perl
is(
    $tt_service->context->{EVAL_PERL},
    1,
    q{EVAL_PERL is enabled}
);
