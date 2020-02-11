package main;

use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::BailOnFail;

note 'Load and default import of Test2::Tools::LoadModule';

# NOTE that this mess is why I think this is a useful module.
{
    local $@ = undef;
    ok eval {
	require Test2::Tools::LoadModule;
	1;
    }, 'Can load Test2::Tools::LoadModule', $@;

    Test2::Tools::LoadModule->import();
}

imported_ok qw{
    load_module_ok
    load_module_or_skip
    load_module_or_skip_all
};

use lib qw{ ./inc };

note 'Load and test ./inc module Test2::Plugin::INC_Jail';

{
    local $@ = undef;
    local @INC = @INC;

    ok eval {
	require Test2::Plugin::INC_Jail;
	Test2::Plugin::INC_Jail->import( 'Module::Under::Test' );
	1;
    }, 'Can load Test2::Plugin::INC_Jail from ./inc';

    ok ! eval {
	require Present;
	1;
    }, 'main can not load Present';

    {
	package
	Module::Under::Test;

	use Test2::V0;	# Have to import test routines

	ok eval {
	    require Present;
	    1;
	}, 'Module::Under::Test can load Present';

	ok ! eval {
	    require Net::Cmd;	# Unlikely to be used by Test2::V0. I hope!
	    1;
	}, 'Module::Under::Test can not load Net::Cmd (core since 5.7.3)';

    }

    ok eval {
	require Net::Cmd;
	1;
    }, 'main can load Net::Cmd (core since 5.7.3)';
}

done_testing;

1;

# ex: set textwidth=72 :
