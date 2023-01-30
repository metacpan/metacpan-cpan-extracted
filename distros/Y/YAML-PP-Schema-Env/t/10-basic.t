#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use File::Temp ();
use Test::More 'no_plan';

use YAML::PP;

my $ypp_nodef    = YAML::PP->new(schema => [qw(+ Env)]);
my $ypp_emptydef = YAML::PP->new(schema => [qw(+ Env defval=)]);
my $ypp_def      = YAML::PP->new(schema => [qw(+ Env defval=N/A)]);
my $ypp_defsep   = YAML::PP->new(schema => [qw(+ Env defsep=! defval=N/A)]);
my $ypp_defseprx = YAML::PP->new(schema => [qw(+ Env defsep=* defval=N/A)]);

my $yaml = <<'EOM';
---
noenv:        noenv
simple:       !ENV ${SIMPLE}
concat:       !ENV before ${ENV1} middle ${ENV2} after
with_default: !ENV ${DEFAULT_TEST:this is the default value}
EOM

{
    local %ENV;
    ok !eval { $ypp_nodef->load_string($yaml) }, 'fails parsing a YAML string because of undefined ENV vars';
    like $@, qr{There's no environment variable 'SIMPLE', and no global or local default value was configured}, 'expected error message';
}

{
    local %ENV = ();
    my($doc) = $ypp_emptydef->load_string($yaml);
    is_deeply $doc, {
	noenv        => 'noenv',
	simple       => '',
	concat       => 'before  middle  after',
	with_default => 'this is the default value',
    }, 'non-existent ENV vars are replaced with the empty string';
}

{
    local %ENV = ();
    my($doc) = $ypp_def->load_string($yaml);
    is_deeply $doc, {
	noenv        => 'noenv',
	simple       => 'N/A',
	concat       => 'before N/A middle N/A after',
	with_default => 'this is the default value',
    }, 'non-existent ENV vars are replaced with the string "N/A"';
}

{
    local %ENV = (
	SIMPLE => 'simple_val',
	ENV1   => 'env1_val',
	ENV2   => 'env2_val',
    );
    my($doc) = $ypp_nodef->load_string($yaml);
    is_deeply $doc, {
	noenv        => 'noenv',
	simple       => 'simple_val',
	concat       => 'before env1_val middle env2_val after',
	with_default => 'this is the default value',
    }, 'using a locally defined default value';
}

{
    local %ENV = (
	SIMPLE       => 'simple_val',
	ENV1         => 'env1_val',
	ENV2         => 'env2_val',
	DEFAULT_TEST => 'default_test_val',
    );
    my($doc) = $ypp_nodef->load_string($yaml);
    is_deeply $doc, {
	noenv        => 'noenv',
	simple       => 'simple_val',
	concat       => 'before env1_val middle env2_val after',
	with_default => 'default_test_val',
    }, 'no need to use locally defined default value';
}

{
    local %ENV = ();
    my($doc) = $ypp_defsep->load_string($yaml);
    is_deeply $doc, {
	noenv        => 'noenv',
	simple       => 'N/A',
	concat       => 'before N/A middle N/A after',
	with_default => 'N/A',
    }, 'change default separator to "!", without using it';
}

{
    my $yaml = <<'EOM';
---
changed_separator: !ENV ${DEFAULT_TEST!this is the default value}
EOM
    local %ENV = ();
    my($doc) = $ypp_defsep->load_string($yaml);
    is_deeply $doc, {
	changed_separator => 'this is the default value',
    }, 'change default separator to "!", and use it';
}

{
    my $yaml = <<'EOM';
---
changed_separator: !ENV ${DEFAULT_TEST*this is the default value}
EOM
    local %ENV = ();
    my($doc) = $ypp_defseprx->load_string($yaml);
    is_deeply $doc, {
	changed_separator => 'this is the default value',
    }, 'change default separator to "*" (regexp meta chars allowed), and use it';
}

{
    my($tmpfh,$tmpfile) = File::Temp::tempfile("yamlppschemaenv-XXXXXXXX", SUFFIX => '.yaml', UNLINK => 1, TMPDIR => 1);
    print $tmpfh <<'EOM';
---
noenv:        noenv
simple:       !ENV ${SIMPLE}
concat:       !ENV before ${ENV1} middle ${ENV2} after
with_default: !ENV ${DEFAULT_TEST:this is the default value}
EOM
    close $tmpfh;

    {
	local %ENV;
	ok !eval { $ypp_nodef->load_file($tmpfile) }, 'fails parsing a YAML file because of undefined ENV vars';
	like $@, qr{There's no environment variable 'SIMPLE', and no global or local default value was configured}, 'expected error message';
    }

    {
	local %ENV = (
	    SIMPLE       => 'simple_val',
	    ENV1         => 'env1_val',
	    ENV2         => 'env2_val',
	    DEFAULT_TEST => 'default_test_val',
	);
	my($doc) = $ypp_nodef->load_file($tmpfile);
	is_deeply $doc, {
	    noenv        => 'noenv',
	    simple       => 'simple_val',
	    concat       => 'before env1_val middle env2_val after',
	    with_default => 'default_test_val',
	}, 'successfully loaded YAML file wth replaced ENV vars';
    }
}

{
    my $yaml = <<'EOM';
test1:
    data0: !ENV ${ENV_TAG1}/somethingelse/${ENV_TAG2}
    data1:  !ENV ${ENV_TAG2}
EOM
    local %ENV = (
	ENV_TAG1 => 'it works!',
	ENV_TAG2 => 'this works too!',
    );
    my($doc) = $ypp_nodef->load_string($yaml);
    is_deeply $doc, {
	test1 => {
	    data0 => 'it works!/somethingelse/this works too!',
	    data1 => 'this works too!',
	}
    }, 'test case from pyaml_env (test_parse_config_more_than_one_env_value)';
}

{
    my $yaml = <<'EOM';
test1:
    data0: !ENV ${ENV_TAG1:defaul^{t1}/somethingelse/${ENV_TAG2:default2}
    data1:  !ENV ${ENV_TAG2}
EOM
    local %ENV = ();
    my($doc) = $ypp_def->load_string($yaml);
    is_deeply $doc, {
	test1 => {
	    data0 => 'defaul^{t1/somethingelse/default2',
	    data1 => 'N/A',
	}
    }, 'test case from pyaml_env (test_parse_config_default_separator_two_env_vars_in_one_line_extra_chars)';
}

{
    my $yaml = <<'EOM';
test1:
    data0: !ENV ${ENV_TAG1:defaul^{}t1}/somethingelse/${ENV_TAG2:default2}
    data1:  !ENV ${ENV_TAG2}
EOM
    local %ENV = ();
    my($doc) = $ypp_def->load_string($yaml);
    is_deeply $doc, {
	test1 => {
	    data0 => 'defaul^{t1}/somethingelse/default2',
	    data1 => 'N/A',
	}
    }, 'test case from pyaml_env (test_parse_config_default_separator_illegal_char_default_value)';
}

__END__

;;; Local Variables:
;;; cperl-indent-parens-as-block: t
;;; cperl-close-paren-offset: -4
;;; End:
