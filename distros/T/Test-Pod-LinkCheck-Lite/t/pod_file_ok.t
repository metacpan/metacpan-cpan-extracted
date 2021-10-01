package main;

use 5.008;

use strict;
use warnings;

use IPC::Cmd qw{ run };
use Module::Load::Conditional qw{ check_install };
use Test::More 0.88;	# Because of done_testing();

# The following is a random 64-character command name generated from
# characters in the set [0-9A-Za-z_-]. My previous try was 'bad cmd',
# which did not work as advertized under FreeBSD. Under that OS, the
# argument appeard to be split on space by C<man -w>, and since C<man>
# is a valid manpage, the returned status was 0. If you change this,
# make sure the link in t/data/man_bad.pod is changed to match.

use constant RANDOM_CMD =>
    '2d8S4rU0svlIoqpA01ntUV1w_NWiKZ8TvSbbhnmYkvLPCHhv8ccYxCLIXNlQcnVv';
use constant CAN_MAN_MAN => run( COMMAND => [ qw{ man -w 1 man } ] ) || 0;

# This mess is because if Devel::Hide or Test::Without::Module is
# specified on the command line or in an enclosing file, a straight
# 'use lib qw{ inc/Mock }' would trump it, and the mocked modules would
# still be loaded. With this mess, the command-line version is
# $ perl -Mlib=inc/Mock -MDevel::Hide=HTTP::Tiny ...,
# and the 'use if' sees inc/Mock already in @INC and does not add it
# again.  'use if' is core as of 5.6.2, so I should be OK unless I run
# into some Linux packager who knows better than the Perl Porters what
# should be in core (and yes, they exist).

use constant CODE_REF	=> ref sub {};
use constant NON_REF	=> ref 0;
use constant REGEXP_REF	=> ref qr{};

# The BEGIN block is for the sake of the import().
BEGIN {
    my $inx = 0;
    OUTER_LOOP: {
	while ( $inx < @INC ) {
	    CODE_REF eq ref $INC[$inx++]
		and last OUTER_LOOP;
	}
	$inx = 0;
    }
    splice @INC, $inx, 0, 'inc/Mock', 't/data/_lib';

    no warnings qw{ once };

    local $Test::Pod::LinkCheck::Lite::DIRECTORY_LEADER = '_';
    require Test::Pod::LinkCheck::Lite;
    Test::Pod::LinkCheck::Lite->import( qw{ :const } );
}

{
    my $t = Test::Pod::LinkCheck::Lite->new();

    diag '';
    diag $t->configuration( 'Default' );
    diag 'CAN_MAN_MAN is ', CAN_MAN_MAN ? 'true' : 'false';
    CAN_MAN_MAN
	or diag <<'EOD';
The man (1) program appears to be available, but man -w man appears not
to work. Tests of man links will be skipped.
EOD

    # Encapsulation violation for testing purposes. DO NOT try this at
    # home.
    $t->{_file_name} = 'File fu.bar';

    is $t->__build_test_msg( '1, 2, 3' ), 'File fu.bar 1, 2, 3',
	'Build test message';

    is $t->__build_test_msg( [ undef, {
		raw => 'Bazzle',
	    },
	], 'checked' ),
	'File fu.bar link L<Bazzle> checked',
	'Test message with link';

    is $t->__build_test_msg( [ undef, {
		line_number	=> 42,
		raw		=> 'Bazzle',
	    },
	], 'checked' ),
	'File fu.bar line 42 link L<Bazzle> checked',
	'Test message with line number and link';

    foreach my $file ( qw{
	Makefile.PL t/basic.t t/data/pod_ok/empty.pod
	lib/Test/Pod/LinkCheck/Lite.pm
	eg/test-pod-links
	} ) {

	ok $t->_is_perl_file( $file ), "$file is a Perl file";
    }

    foreach my $file ( qw{
	t/data/not_ok/nonexistent.pod
	t/data/_cpan/Metadata
	} ) {

	ok ! $t->_is_perl_file( $file ), "$file is not a Perl file";
    }
}

{
    local $ENV{HOME} = 't/data';

    my $t = Test::Pod::LinkCheck::Lite->new();

    my @rslt;

    $t->pod_file_ok( \'' );

    {
	my ( $fail, $pass, $skip );

	TODO: {
	    local $TODO = 'Deliberate failure';
	    ( $fail, $pass, $skip ) = $t->pod_file_ok(
		't/data/not_ok/nonexistent.pod' );
	}
	cmp_ok $fail, '==', 1,
	'Got expected failure checking non-existent file'
	    or diag "Fail = $fail; pass = $pass; skip = $skip";
    }

    $t->pod_file_ok( 't/data/pod_ok/empty.pod' );

    $t->pod_file_ok( 't/data/pod_ok/no_links.pod' );

    @rslt = $t->pod_file_ok( 't/data/pod_ok/url_links.pod' );
    is_deeply \@rslt, [ 0, 1, 0 ],
	'Test of t/data/pod_ok/url_links.pod returned proper data';

    SKIP: {
	$t->man()
	    or skip 'This system does not support the testing of man links', 2;
	CAN_MAN_MAN
	    or skip q<This system is unable to run 'man -w man'>, 2;

	my ( $fail, $pass, $skip );

	( $fail, $pass, $skip ) = $t->pod_file_ok( 't/data/pod_ok/man.pod' );
	if ( $fail ) {
	    diag "Fail = $fail; pass = $pass; skip = $skip; CAN_MAN_MAN = ",
		CAN_MAN_MAN;
	    # TODO ditch the following once I have sorted out the test
	    # failure
	    diag 'Links found: ', explain $t->{_links};
	}

	run( COMMAND => [ qw{ man -w 1 }, RANDOM_CMD ] )
	    and skip "Against all expectation, '@{[ RANDOM_CMD
		]}' is an actual man page; skipping this test", 1;

	TODO: {
	    local $TODO = 'Deliberate failure';
	    ( $fail, $pass, $skip ) = $t->pod_file_ok( 't/data/not_ok/man_bad.pod' );
	}
	cmp_ok $fail, '==', 1,
	'Got expected failure checking non-existent man page'
	    or diag "Fail = $fail; pass = $pass; skip = $skip";
    }

    $t->pod_file_ok( 't/data/pod_ok/internal.pod' );

    # This circumlocution will be used for tests where errors are
    # expected.  Unfortunately it only tests that the correct number of
    # errors are reported, not that the errors reported are the correct
    # ones.

    {
	my ( $fail, $pass, $skip );

	TODO: {
	    local $TODO = 'Deliberate test failures.';
	    ( $fail, $pass, $skip ) = $t->pod_file_ok(
		't/data/not_ok/internal_error.pod' );
	}

	cmp_ok $fail, '==', 2, 't/data/not_ok/internal_error.pod had 2 errors'
	    or diag "Fail = $fail; pass = $pass; skip = $skip";
    }

    $t->pod_file_ok( 't/data/pod_ok/bug_line_break.pod' );

    $t->pod_file_ok( 't/data/pod_ok/external_builtin.pod' );

    $t->pod_file_ok( 't/data/pod_ok/external_installed.pod' );

    SKIP: {

	my $version = 1.40;
	my $rv;
	$rv = check_install(
	    module	=> 'Scalar::Util',
	    version	=> $version,
	) and defined $rv->{version}
	    and $rv->{version} ge $version
	    or skip
	    "External section check needs Scalar::Util version $version", 1;

	# This file is in not_ok/ only to prevent all_pod_files_ok()
	# from finding it.
	$t->pod_file_ok( 't/data/not_ok/external_installed_section.pod' );

    }

    {
	my ( $fail, $pass, $skip );

	TODO: {
	    local $TODO = 'Deliberate test failures.';
	    ( $fail, $pass, $skip ) = $t->pod_file_ok(
		't/data/not_ok/external_installed_bad_section.pod' );
	}

	cmp_ok $fail, '==', 1,
	    't/data/not_ok/external_installed_bad_section.pod had 1 error'
	    or diag "Fail = $fail; pass = $pass; skip = $skip";
    }

    $t->pod_file_ok( 't/data/pod_ok/external_installed_pod.pod' );

    $t->pod_file_ok( 't/data/pod_ok/external_uninstalled.pod' );

    $t->pod_file_ok( 't/data/pod_ok/bug_leading_format_code.pod' );

    $t->pod_file_ok( 't/data/pod_ok/bug_recursion.pod' );

}

{
    my $t = Test::Pod::LinkCheck::Lite->new(
	man	=> CAN_MAN_MAN,
    );

    note '';
    $t->all_pod_files_ok( 't/data/pod_ok' );
    note '';

}

{
    my $t = Test::Pod::LinkCheck::Lite->new(
	check_external_sections	=> 0,
    );

    note 'The following test should pass because check_external_sections => 0';
    $t->pod_file_ok(
	't/data/not_ok/external_installed_bad_section.pod' );

}

{
    my $t = Test::Pod::LinkCheck::Lite->new(
	require_installed	=> 1,
    );

    my ( $fail, $pass, $skip );

    TODO: {
	note 'The following test should fail because require_installed => 1';
	local $TODO = 'Deliberate test failure.';
	( $fail, $pass, $skip ) = $t->pod_file_ok(
	    't/data/pod_ok/external_uninstalled.pod' );
    }

    cmp_ok $fail, '==', 1,
    't/data/pod_ok/external_uninstalled.pod fails without uninstalled module checking'
	or do {
	diag "Fail = $fail; pass = $pass; skip = $skip";
	# TODO ditch the following once I have sorted out the test
	# failure
	diag 'Links found: ', explain $t->{_links};
    };
}

foreach my $check_url ( 0, 1 ) {
    my $t = Test::Pod::LinkCheck::Lite->new(
	check_url	=> $check_url,
    );

    note "Test with explicitly-specified check_url => $check_url";

    if ( $check_url ) {
	$t->pod_file_ok( 't/data/pod_ok/url_links.pod' );
    } else {
	my $errors = $t->pod_file_ok(
	    't/data/pod_ok/url_links.pod' );

	cmp_ok $errors, '==', 0,
	    't/data/pod_ok/url_links.pod error count with url checks disabled';
    }
}

foreach my $skip_server_errors ( 0, 1 ) {
    my $t = Test::Pod::LinkCheck::Lite->new(
	skip_server_errors	=> $skip_server_errors,
    );

    note "Test with explicitly-specified skip_server_errors => $skip_server_errors";

    if ( $skip_server_errors ) {
	$t->pod_file_ok( 't/data/not_ok/server_error.pod' );
    } else {

	my $errors;

	TODO: {
	    local $TODO = 'Deliberate failure';
	    $errors = $t->pod_file_ok( 't/data/not_ok/server_error.pod' );
	}

	cmp_ok $errors, '==', 1,
	    't/data/not_ok/server_error.pod error count with skip_server_errors false';
    }
}

foreach (
    [ 0 => 0 ],
    [ 1 => 1 ],
    [ ALLOW_REDIRECT_TO_INDEX => ALLOW_REDIRECT_TO_INDEX ],
    [ 'Chained custom sub' => sub { return ALLOW_REDIRECT_TO_INDEX } ],
    ) {
    my ( $name, $prohibit_redirect ) = @{ $_ };
    my $t = Test::Pod::LinkCheck::Lite->new(
	prohibit_redirect	=> $prohibit_redirect,
    );

    note '';
    note "Test with explicitly-specified prohibit_redirect => $name";

    my $errors;

    if ( $prohibit_redirect ) {

	TODO: {
	    local $TODO = 'Deliberate failure';
	    $errors = $t->pod_file_ok( 't/data/not_ok/redirect.pod' );
	}
	cmp_ok $errors, '==', 1,
	    "t/data/not_ok/redirect.pod error count with prohibit_redirect $name";;
    } else {
	$t->pod_file_ok( 't/data/not_ok/redirect.pod' );
    }

    if ( $prohibit_redirect && ! ref $prohibit_redirect ) {

	my $errors;

	TODO: {
	    local $TODO = 'Deliberate failure';
	    $errors = $t->pod_file_ok( 't/data/not_ok/redirect_no_path.pod' );
	}
	cmp_ok $errors, '==', 1,
	    "t/data/not_ok/redirect_no_path.pod error count with prohibit_redirect $name";

    } else {
	$t->pod_file_ok( 't/data/not_ok/redirect_no_path.pod' );
    }
}

note '';

{
    my $code = sub { 0 };

    foreach my $ignore (
	[ []	=> {} ],
	[ undef,	   {} ],
	[ 'http://foo.bar/'	=> {
		NON_REF,	{
		    'http://foo.bar/'	=> 1,
		},
	    },
	],
	[ qr< \Q//foo.bar\E \b >smxi	=> {
		REGEXP_REF,	[
		    qr< \Q//foo.bar\E \b >smxi,
		],
	    },
	],
	[ [ undef, qw< http://foo.bar/ http://baz.burfle/ >, qr|//buzz/| ]	=> {
		NON_REF,	{
		    'http://foo.bar/'	=> 1,
		    'http://baz.burfle/'	=> 1,
		},
		REGEXP_REF,	[
		    qr|//buzz/|,
		],
	    },
	],
	[ [ $code, { 'http://foo/' => 1, 'http://bar/' => 0 } ]	=> {
		NON_REF,	{
		    'http://foo/'	=> 1,
		},
		CODE_REF,	[ $code ],
	    }
	],
    ) {
	my $t = Test::Pod::LinkCheck::Lite->new(
	    ignore_url	=> $ignore->[0],
	);

	is_deeply $t->__ignore_url(), $ignore->[1], join( ' ',
	    'Properly interpreted ignore_url => ',
	    defined $ignore->[0] ? explain $ignore->[0] : 'undef',
	);
    }
}

{
    my $t = Test::Pod::LinkCheck::Lite->new(
	ignore_url	=> qr< \Q//metacpan.org/\E >smx,
    );

    my @rslt = $t->pod_file_ok( 't/data/pod_ok/url_links.pod' );
    is_deeply \@rslt, [ 0, 1, 1 ],
	'Test of t/data/pod_ok/url_links.pod returned proper data when ignoring URL';
}

foreach my $mi ( Test::Pod::LinkCheck::Lite->new()->module_index() ) {

    local $ENV{HOME} = 't/data';

    my $t = Test::Pod::LinkCheck::Lite->new(
	module_index	=> $mi,
    );

    note "Test with module_index => $mi";

    $t->pod_file_ok( 't/data/pod_ok/external_uninstalled.pod' );
}

done_testing;

sub Boolean {
    my ( $arg ) = @_;
    return $arg ? 'true' : 'false';
}

1;

# ex: set textwidth=72 :
