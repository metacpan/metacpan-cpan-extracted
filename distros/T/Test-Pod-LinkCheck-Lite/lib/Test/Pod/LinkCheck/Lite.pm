package Test::Pod::LinkCheck::Lite;

use 5.008;

use strict;			# Core since 5.0
use warnings;			# Core since 5.6.0

use utf8;			# Core since 5.6.0

use B::Keywords ();		# Not core
use Carp ();			# Core since 5.0
use Exporter ();		# Core since 5.0
use File::Find ();		# Core since 5.0
use File::Spec;			# Core since 5.4.5
use HTTP::Tiny;			# Core since 5.13.9
use IPC::Cmd ();		# Core since 5.9.5
use Module::Load::Conditional ();	# Core since 5.9.5
use Pod::Perldoc ();		# Core since 5.8.1
use Pod::Simple ();		# Core since 5.9.3
use Pod::Simple::LinkSection;	# Core since 5.9.3 (part of Pod::Simple)
use Scalar::Util ();		# Core since 5.7.3
use Storable ();		# Core since 5.7.3
use Test::Builder ();		# Core since 5.6.2

our $VERSION = '0.008';

our @ISA = qw{ Exporter };

our @EXPORT_OK = qw{
    ALLOW_REDIRECT_TO_INDEX
};

our %EXPORT_TAGS = (
    const	=> [ grep { m/ \A [[:upper:]_]+ \z /smx } @EXPORT_OK ],
);

use constant ON_DARWIN		=> 'darwin' eq $^O;
use constant ON_VMS		=> 'VMS' eq $^O;

our $DIRECTORY_LEADER;	# FOR TESTING ONLY -- may be retracted without notice
defined $DIRECTORY_LEADER
    or $DIRECTORY_LEADER = ON_VMS ? '_' : '.';

my $DOT_CPAN		= "${DIRECTORY_LEADER}cpan";

use constant ARRAY_REF	=> ref [];
use constant CODE_REF	=> ref sub {};
use constant HASH_REF	=> ref {};
use constant NON_REF	=> ref 0;
use constant REGEXP_REF	=> ref qr<x>smx;
use constant SCALAR_REF	=> ref \0;

# Pod::Simple versions earlier than this were too restrictive in
# recognizing 'man' links, so some valid ones ended up classified as
# 'pod'. We conditionalize fix-up code on this constant so that, if the
# fix-up is not needed, the optimizer ditches it.
use constant NEED_MAN_FIX	=> Pod::Simple->VERSION lt '3.24';

use constant ALLOW_REDIRECT_TO_INDEX => sub {
    my ( undef, $resp, $url ) = @_;
    # Does not apply to non-hierarchical URLs. This list is derived from
    # the URI distribution, and represents those classes that do not
    # inherit from URI::_generic.
    $url =~ m/ \A (?: data | mailto | urn ) : /smxi
	and return $resp->{url} ne $url;
    $url =~ m| / \z |smx
	or return $resp->{url} ne $url;
    ( my $resp_url = $resp->{url} ) =~ s| (?<= / ) [^/]* \z ||smx;
    return $resp_url ne $url;
};

# NOTE that Test::Builder->new() gets us a singleton. For this reason I
# use $Test::Builder::Level (localized) to get tests reported relative
# to the correct file and line, rather than setting the 'level'
# attribute.
my $TEST = Test::Builder->new();

sub new {
    my ( $class, %arg ) = @_;
    my $self = bless {}, ref $class || $class;
    return _init( $self, %arg );
}

{
    my %dflt;
    local $_ = undef;
    foreach ( keys %Test::Pod::LinkCheck::Lite:: ) {
	m/ \A _default_ ( .+ ) /smx
	    and my $code = __PACKAGE__->can( $_ )
	    or next;
	$dflt{$1} = $code;
    }

    sub _init {
	my ( $self, %arg ) = @_;
	foreach my $key ( keys %dflt ) {
	    exists $arg{$key}
		or $arg{$key} = $dflt{$key}->();
	}
	foreach my $name ( keys %arg ) {
	    if ( my $code = $self->can( "_init_$name" ) ) {
		$code->( $self, $name, $arg{$name} );
	    } elsif ( defined $arg{$name} ) {
		Carp::croak( "Unknown argument $name" );
	    }
	}
	return $self;
    }
}

sub _default_agent {
    return HTTP::Tiny->new()->agent();
}

sub _default_allow_man_spaces {
    return 0;
}

sub _default_check_external_sections {
    return 1;
}

sub _default_cache_url_response {
    return 1;
}

sub _default_check_url {
    return 1;
}

sub _default_ignore_url {
    return [];
}

{
    my $checked;
    my $rslt;

    sub _default_man {
	unless ( $checked ) {
	    $checked = 1;
	    # I had hoped that just feeling around for an executable
	    # 'man' would be adequate, but ReactOS (which identifies
	    # itself as MSWin32) has a MAN.EXE that will not work. If
	    # the user has customized the system he or she can always
	    # specify man => 1. The hash is in case I find other OSes
	    # that have this problem. OpenVMS might end up here, but I
	    # have no access to it to see.
	    if ( {
		    DOS		=> 1,
		    MSWin32	=> 1,
		}->{$^O}
	    ) {
		$rslt = 0;
		$TEST->diag( "Can not check man pages by default under $^O" );
	    } else {
		$rslt = IPC::Cmd::can_run( 'man' )
		    or $TEST->diag(
		    q<Can not check man pages; 'man' not installed> );
	    }
	}
	return $rslt;
    }
}

sub _default_module_index {
    my @handlers;
    foreach ( keys %Test::Pod::LinkCheck::Lite:: ) {
	m/ \A _get_module_index_ ( .+ ) /smx
	    and __PACKAGE__->can( $_ )
	    or next;
	push @handlers, $1;
    }
    @handlers = sort @handlers;
    return \@handlers;
}

sub _default_prohibit_redirect {
    return 0;
}

sub _default_require_installed {
    return 0;
}

sub _default_skip_server_errors {
    return 1;
}

sub _init_agent {
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value;
    return;
}

sub _init_allow_man_spaces {
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value ? 1 : 0;
    return;
}

sub _init_cache_url_response {
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value ? 1 : 0;
    return;
}

sub _init_check_external_sections {
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value ? 1 : 0;
    return;
}

sub _init_check_url {
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value ? 1 : 0;
    return;
}

{
    my %handler;

    %handler = (
	ARRAY_REF,	sub {
	    my ( $spec, $value ) = @_;
	    $handler{ ref $_ }->( $spec, $_ ) for @{ $value };
	    return;
	},
	CODE_REF,	sub {
	    my ( $spec, $value ) = @_;
	    push @{ $spec->{ CODE_REF() } }, $value;
	    return;
	},
	HASH_REF,	sub {
	    my ( $spec, $value ) = @_;
	    $spec->{ NON_REF() }{$_} = 1 for
		grep { $value->{$_} } keys %{ $value };
	    return;
	},
	NON_REF,	sub {
	    my ( $spec, $value ) = @_;
	    defined $value
		or return;
	    $spec->{ NON_REF() }->{$value} = 1;
	    return;
	},
	REGEXP_REF,	sub {
	    my ( $spec, $value ) = @_;
	    push @{ $spec->{ REGEXP_REF() } }, $value;
	    return;
	},
	SCALAR_REF,	sub {
	    my ( $spec, $value ) = @_;
	    $spec->{ NON_REF() }->{$$value} = 1;
	    return;
	},
    );

    sub _init_ignore_url {
	my ( $self, $name, $value ) = @_;

	my $spec = $self->{$name} = {};
	eval {
	    $handler{ ref $value }->( $spec, $value );
	    1;
	} or Carp::confess(
	    "Invalid ignore_url value '$value': must be scalar, regexp, array ref, hash ref, code ref, or undef" );
	return;
    }
}

sub _init_man {
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value ? 1 : 0;
    return;
}

sub _init_module_index {
    my ( $self, $name, $value ) = @_;
    my @val = map { split qr{ \s* , \s* }smx } ARRAY_REF eq ref $value ?
    @{ $value } : $value;
    my @handlers;
    foreach my $mi ( @val ) {
	my $code = $self->can( "_get_module_index_$mi" )
	    or Carp::croak( "Invalid module_index value '$mi'" );
	push @handlers, $code;
    }
    $self->{$name} = \@val;
    $self->{"_$name"} = \@handlers;
    return;
}

sub _init_prohibit_redirect {
    my ( $self, $name, $value ) = @_;
    if ( CODE_REF eq ref $value ) {
	$self->{$name} = $self->{"_$name"} = $value;
    } elsif ( $value ) {
	$self->{$name} = 1;
	$self->{"_$name"} = sub {
	    my ( undef, $resp, $url ) = @_;
	    return $resp->{url} ne $url;
	};
    } else {
	$self->{$name} = 0;
	$self->{"_$name"} = sub {
	    return 0;
	};
    }
    return;
}

sub _init_require_installed {
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value ? 1 : 0;
    return;
}

sub _init_skip_server_errors {
    my ( $self, $name, $value ) = @_;
    $self->{$name} = $value ? 1 : 0;
    return;
}

sub agent {
    my ( $self ) = @_;
    return $self->{agent};
}

sub all_pod_files_ok {
    my ( $self, @dir ) = @_;

    @dir
	or push @dir, 'blib';

    my $note = sprintf 'all_pod_files_ok( %s )',
	join ', ', map { "'$_'" } @dir;

    $TEST->note( "Begin $note" );

    my ( $fail, $pass, $skip ) = ( 0 ) x 3;

    File::Find::find( {
	    no_chdir	=> 1,
	    wanted	=> sub {
		if ( $self->_is_perl_file( $_ ) ) {
		    $TEST->note( "Checking POD links in $File::Find::name" );
		    my ( $f, $p, $s ) = $self->pod_file_ok( $_ );
		    $fail += $f;
		    $pass += $p;
		    $skip += $s;
		}
		return;
	    },
	},
	@dir,
    );

    $TEST->note( "End $note" );

    return wantarray ? ( $fail, $pass, $skip ) : $fail;
}

sub allow_man_spaces {
    my ( $self ) = @_;
    return $self->{allow_man_spaces}
}

sub cache_url_response {
    my ( $self ) = @_;
    return $self->{cache_url_response}
}

sub check_external_sections {
    my ( $self ) = @_;
    return $self->{check_external_sections}
}

sub check_url {
    my ( $self ) = @_;
    return $self->{check_url}
}

sub configuration {
    my ( $self, $leader ) = @_;

    defined $leader
	or $leader = '';
    $leader =~ s/ (?<= \S ) \z / /smx;

    my ( $ignore_url ) = $TEST->explain( scalar $self->ignore_url() );
    chomp $ignore_url;

    return <<"EOD";
${leader}'agent' is '@{[ $self->agent() ]}'
${leader}'allow_man_spaces' is @{[ _Boolean(
    $self->allow_man_spaces() ) ]}
${leader}'cache_url_response' is @{[ _Boolean(
    $self->cache_url_response() ) ]}
${leader}'check_external_sections' is @{[ _Boolean(
    $self->check_external_sections() ) ]}
${leader}'check_url' is @{[ _Boolean( $self->check_url() ) ]}
${leader}'ignore_url' is $ignore_url
${leader}'man' is @{[ _Boolean( $self->man() ) ]}
${leader}'module_index' is ( @{[ join ', ', map { "'$_'" }
    $self->module_index() ]} )
${leader}'prohibit_redirect' is @{[ _Boolean( $self->prohibit_redirect() ) ]}
${leader}'require_installed' is @{[ _Boolean( $self->require_installed() ) ]}
${leader}'skip_server_errors' is @{[ _Boolean( $self->skip_server_errors() ) ]}
EOD
}

sub _Boolean {
    my ( $value ) = @_;
    return $value ? 'true' : 'false';
}

sub ignore_url {
    my ( $self ) = @_;
    my $spec = $self->__ignore_url();
    my @rslt = (
	sort keys %{ $spec->{ ( NON_REF ) } || {} },
	@{ $spec->{ ( REGEXP_REF ) } || [] },
	@{ $spec->{ ( CODE_REF ) } || [] },
    );
    return wantarray ? @rslt : \@rslt;
}

# This method returns the internal value of the ignore_url attribute. It
# is PRIVATE to this package, and may be changed or revoked at any time.
# If called with an argument, it returns a true value if that argument
# is a URL that is to be ignored, and false otherwise.
sub __ignore_url {
    my ( $self, $url ) = @_;
    @_ > 1
	or return $self->{ignore_url};
    my $spec = $self->{ignore_url};
    $spec->{ NON_REF() }{$url}
	and return 1;
    foreach my $re ( @{ $spec->{ REGEXP_REF() } } ) {
	$url =~ $re
	    and return 1;
    }
    local $_ = $url;
    foreach my $code ( @{ $spec->{ CODE_REF() } } ) {
	$code->()
	    and return 1;
    }
    return 0;
}

sub man {
    my ( $self ) = @_;
    return $self->{man};
}

sub module_index {
    my ( $self ) = @_;
    wantarray
	and return @{ $self->{module_index} };
    local $" = ',';
    return "@{ $self->{module_index} }";
}

sub pod_file_ok {
    my ( $self, $file ) = @_;

    delete $self->{_section};
    $self->{_test} = {
	pass	=> 0,
	fail	=> 0,
	skip	=> 0,
    };

    if ( SCALAR_REF eq ref $file ) {
	$self->{_file_name} = ${ $file } =~ m/ \n /smx ?
	    "String $file" :
	    "String '${ $file }'";
    } elsif ( -f $file ) {
	$self->{_file_name} = "File $file";
    } else {
	$self->{_file_name} = "File $file";
	$self->_fail(
	    'does not exist, or is not a normal file' );
	return wantarray ? ( 1, 0, 0 ) : 1;
    }

    ( $self->{_section}, $self->{_links} ) = My_Parser->new()->run(
	$file, \&_any_errata_seen, $self );

    @{ $self->{_links} }
	or do {
	$self->_pass();
	return wantarray ? ( 0, 1, 0 ) : 0;
    };

    my $errors = 0;

    foreach my $link ( @{ $self->{_links} } ) {
	my $code = $self->can( "_handle_$link->[1]{type}" )
	    or Carp::confess(
	    "TODO - link type $link->[1]{type} not supported" );
	$errors += $code->( $self, $link );
    }

    $errors
	or $self->_pass();
    return wantarray ?
	( @{ $self->{_test} }{ qw{ fail pass skip } } ) :
	$self->{_test}{fail};
}

sub prohibit_redirect {
    my ( $self ) = @_;
    return $self->{prohibit_redirect};
}

sub require_installed {
    my ( $self ) = @_;
    return $self->{require_installed};
}

sub skip_server_errors {
    my ( $self ) = @_;
    return $self->{skip_server_errors};
}

sub _user_agent {
    my ( $self ) = @_;
    return( $self->{_user_agent} ||= HTTP::Tiny->new(
	    agent	=> $self->agent(),
	) );
}

sub _pass {
    my ( $self, @msg ) = @_;
    @msg
	or @msg = ( 'contains no broken links' );
    local $Test::Builder::Level = _nest_depth();
    $TEST->ok( 1, $self->__build_test_msg( @msg ) );
    $self->{_test}{pass}++;
    return 0;
}

sub _fail {
    my ( $self, @msg ) = @_;
    local $Test::Builder::Level = _nest_depth();
    $TEST->ok( 0, $self->__build_test_msg( @msg ) );
    $self->{_test}{fail}++;
    return 1;
}

sub _skip {
    my ( $self, @msg ) = @_;
    local $Test::Builder::Level =  _nest_depth();
    $TEST->skip( $self->__build_test_msg( @msg ) );
    $self->{_test}{skip}++;
    return 0;
}

sub _any_errata_seen {
    my ( $self, $file ) = @_;
    $file = defined $file ? "File $file" : $self->{_file_name};
    $TEST->diag( "$file contains POD errors" );
    return;
}

# This method formats test messages. It is PRIVATE to this package, and
# can be changed or revoked without notice.
sub __build_test_msg {
    my ( $self, @msg ) = @_;
    my @prefix = ( $self->{_file_name} );
    if ( ARRAY_REF eq ref $msg[0] ) {
	my $link = shift @msg;
	my $text = defined $link->[1]{raw} ?
	    "link L<$link->[1]{raw}>" :
	    'Link L<>';
	defined $link->[1]{line_number}
	    and push @prefix, "line $link->[1]{line_number}";
	push @prefix, $text;
    }
    return join ' ', @prefix, join '', @msg;
}

# Get the information on installed documentation. If the doc is found
# the return is a reference to a hash containing key {file}, value the
# path name to the file containing the documentation. This works both
# for module documentation (whether in the .pm or a separate .pod), or
# regular .pod documentation (e.g. perldelta.pod).
sub _get_installed_doc_info {
    my ( undef, $module ) = @_;
    my $pd = Pod::Perldoc->new();

    # Pod::Perldoc writes to STDERR if the module (or whatever) is not
    # installed, so we localize STDERR and reopen it to the null device.
    # The reopen of STDERR is unchecked because if it fails we still
    # want to run the tests. They just may be noisy.
    local *STDERR;
    open STDERR, '>', File::Spec->devnull();	## no critic (RequireCheckedOpen)

    # NOTE that grand_search_init() is undocumented.
    my ( $path ) = $pd->grand_search_init( [ $module ] );

    close STDERR;

    defined $path
	and return {
	file	=> $path,
    };

    # See the comment above (just below where _get_installed_doc_info is
    # called) for why this check is done.
    Module::Load::Conditional::check_install( module	=> $module )
	and return {
	file		=> $path,
	undocumented	=> 1,
    };

    return;
}

# POD link handlers

# Handle a 'man' link.

sub _handle_man {
    my ( $self, $link ) = @_;

    $self->man()
	or return $self->_skip( $link, 'not checked; man checks disabled' );

    $link->[1]{to}
	or return $self->_fail( $link, 'no man page specified' );

    my ( $page, $sect ) = $link->[1]{to} =~ m/
	    ( [^(]+ ) (?: [(] ( [^)]+ ) [)] )? /smx
	or return $self->_fail( $link, 'not recognized as man page spec' );

    $page =~ s/ \s+ \z //smx;

    $page =~ m/ \s /smx
	and not $self->allow_man_spaces()
	and return $self->_fail( $link, 'contains embedded spaces' );

    my @pg = (
	$sect ? $sect : (),
	$page,
    );

    ( $self->{_cache}{man}{"@pg"} ||= IPC::Cmd::run( COMMAND => [
		qw{ man -w }, @pg ] ) || 0 )
	and return 0;

    return $self->_fail( $link, 'refers to unknown man page' );
}

# Handle pod links. This is pretty much everything, except for 'man'
# (see above) or 'url' (see below).
sub _handle_pod {
    my ( $self, $link ) = @_;

    if ( $link->[1]{to} ) {
	return $self->_check_external_pod_info( $link )

    } elsif ( my $section = $link->[1]{section} ) {
	$section = "$section";	# Stringify object
	# Internal links (no {to})
	$self->{_section}{$section}
	    and return 0;

	# Before 3.24, Pod::Simple was too restrictive in parsing 'man'
	# links, and they end up here. The regex is verbatim from
	# Pod::Simple 3.24.
	if ( NEED_MAN_FIX && $section =~ m{^[^/|]+[(][-a-zA-Z0-9]+[)]$}s ) {
	    # The misparse left the actual link text in {section}, but
	    # an honest-to-God Pod link has it in {to}.
	    $link->[1]{to} = delete $link->[1]{section};
	    # While we're at it, we might as well make it an actual
	    # 'man' link.
	    $link->[1]{type} = 'man';
	    goto &_handle_man;
	}

	return $self->_fail( $link, 'links to unknown section' );

    } else {
	# Links to nowhere: L<...|> or L<...|/>
	return $self->_fail( $link, 'links to nothing' );
    }
    return 0;
}

sub _check_external_pod_info {
    my ( $self, $link ) = @_;

    # Stringify overloaded objects
    my $module = $link->[1]{to} ? "$link->[1]{to}" : undef;
    my $section = $link->[1]{section} ?  "$link->[1]{section}" : undef;

    # If there is no section info it might be a Perl builtin. Return
    # success if it is.
    unless ( $section ) {
	$self->_is_perl_function( $module )
	    and return 0;
    }

    # If it is installed, handle it
    if ( my $data = $self->{_cache}{installed}{$module} ||=
	$self->_get_installed_doc_info( $module ) ) {

	# This check is the result of an Andreas J. König (ANDK) test
	# failure under Perl 5.8.9. That version ships with Pod::Perldoc
	# 3.14, which is undocumented. Previously the unfound
	# documentation caused us to fall through to the 'uninstalled'
	# code, which succeeded because all it was doing was looking for
	# the existence of the module, and _assuming_ that it was
	# documented.
	$data->{undocumented}
	    and return $self->_fail( $link,
	    "$module is installed but undocumented" );

	# If we get this far it is an installed module with
	# documentation. We can return success at this point unless the
	# link specifies a section AND we are checking them. We test the
	# link rather than the section name because the latter could be
	# '0'.
	$link->[1]{section}
	    and $self->check_external_sections()
	    or return 0;

	# Find and parse the section info if needed.
	$data->{section} ||= My_Parser->new()->run( $data->{file},
	    \&_any_errata_seen, $self, "File $data->{file}" );

	$data->{section}{$section}
	    and return 0;

	return $self->_fail( $link, 'links to unknown section' );
    }

    # If we're requiring links to be to installed modules, flunk now.
    $self->require_installed()
	and return $self->_fail( $link,
	'links to module that is not installed' );

    # It's not installed on this system, but it may be out there
    # somewhere

    $self->{_cache}{uninstalled} ||= $self->_get_module_index();

    return $self->{_cache}{uninstalled}->( $self, $link );

}

sub _get_module_index {
    my ( $self ) = @_;
    my @inxes = sort { $a->[1] <=> $b->[1] }
	map { $_->( $self ) } @{ $self->{_module_index} };
    if ( @inxes ) {
	my $modinx = $inxes[-1][0];
	return sub {
	    my ( $self, $link ) = @_;
	    my $module = $link->[1]{to};
	    $modinx->( $module )
		or return $self->_fail( $link, 'links to unknown module' );
	    $link->[1]{section}
		or return 0;
	    return $self->_skip( $link, 'not checked; ',
		'module exists, but unable to check sections of ',
		'uninstalled modules' );
	};
    } else {
	return sub {
	    my ( $self, $link ) = @_;
	    return $self->_skip( $link, 'not checked; ',
		'not found on this system' );
	};
    }
}

# In all of the module index getters, the return is either nothing at
# all (for inability to use this indexing mechanism) or a refererence to
# an array. Element [0] of the array is a reference a piece of code that
# takes the module name as its only argument, and returns a true value
# if that module exists and a false value otherwise. Element [1] of the
# array is a Perl time that is characteristic of the information in the
# index (typically the revision date of the underlying file if that's
# the way the index works).

# NOTE that Test::Pod::LinkCheck loads CPAN and then messes with it to
# try to prevent it from initializing itself. After trying this and
# thinking about it, I decided to go after the metadata directly.
sub _get_module_index_cpan {
#   my ( $self ) = @_;

    # The following code reproduces
    # CPAN::HandleConfig::cpan_home_dir_candidates()
    # as of CPAN::HandleConfig version 5.5011.
    my @dir_list;

    if ( _has_usable( 'File::HomeDir', 0.52 ) ) {
	ON_DARWIN
	    or push @dir_list, File::HomeDir->my_data();
	push @dir_list, File::HomeDir->my_home();
    }

    $ENV{HOME}
	and push @dir_list, $ENV{HOME};
    $ENV{HOMEDRIVE}
	and $ENV{HOMEPATH}
	and push @dir_list, File::Spec->catpath( $ENV{HOMEDRIVE},
	$ENV{HOMEPATH} );
    $ENV{USERPROFILE}
	and push @dir_list, $ENV{USERPROFILE};
    $ENV{'SYS$LOGIN'}
	and push @dir_list, $ENV{'SYS$LOGIN'};

    # The preceding code reproduces
    # CPAN::HandleConfig::cpan_home_dir_candidates()

    foreach my $dir ( @dir_list ) {
	defined $dir
	    or next;
	my $path = File::Spec->catfile( $dir, $DOT_CPAN, 'Metadata' );
	-e $path
	    or next;
	my $rev = ( stat _ )[9];
	my $hash = Storable::retrieve( $path )
	    or return;
	$hash = $hash->{'CPAN::Module'};
	return [
	    sub { return $hash->{$_[0]} },
	    $rev,
	];
    }

    return;
}

sub _get_module_index_cpan_meta_db {
    my ( $self ) = @_;

    my $user_agent = $self->_user_agent();

    my %hash;

    return [
	sub {
	    exists $hash{$_[0]}
		and return $hash{$_[0]};
	    my $resp = $user_agent->head(
		"https://cpanmetadb.plackperl.org/v1.0/package/$_[0]" );
	    return ( $hash{$_[0]} = $resp->{success} );
	},
	time - 86400 * 7,
    ];
}

# Handle url links. This is something like L<http://...> or
# L<...|http://...>.
sub _handle_url {
    my ( $self, $link ) = @_;

    $self->check_url()
	or return $self->_skip( $link, 'not checked; url checks disabled' );

    my $user_agent = $self->_user_agent();

    my $url = "$link->[1]{to}"	# Stringify object
	or return $self->_fail( $link, 'contains no url' );

    $self->__ignore_url( $url )
	and return $self->_skip( $link, 'not checked; explicitly ignored' );

    my $resp;
    if ( $self->cache_url_response() ) {
	$resp = $self->{_cache_url_response}{$url} ||=
	    $user_agent->head( $url );
    } else {
	$resp = $user_agent->head( $url );
    }

    if ( $resp->{success} ) {

	my $code = $self->{_prohibit_redirect};
	while ( $code = $code->( $self, $resp, $url ) ) {
	    CODE_REF eq ref $code
		or return $self->_fail( $link, "redirected to $resp->{url}" );
	}

	return 0;

    } else {

	$self->skip_server_errors()
	    and $resp->{status} =~ m/ \A 5 /smx
	    and return $self->_skip( $link,
		"not checked: server error $resp->{status} $resp->{reason}" );

	return $self->_fail( $link,
	    "broken: $resp->{status} $resp->{reason}" );

    }
}

{
    my %checked;

    sub _has_usable {
	my ( $module, $version ) = @_;

	unless ( exists $checked{$module} ) {
	    local $@ = undef;
	    ( my $fn = "$module.pm" ) =~ s| :: |/|smxg;
	    eval {
		require $fn;
		$checked{$module} = 1;
		1;
	    } or do {
		$checked{$module} = 0;
	    };
	}

	$checked{$module}
	    or return;

	if ( defined $version ) {
	    my $rslt = 1;
	    local $SIG{__DIE__} = sub { $rslt = undef };
	    $module->VERSION( $version );
	    return $rslt;
	}

	return 1;
    }
}

sub _is_perl_file {
    my ( undef, $path ) = @_;
    -e $path
	and -T _
	or return;
    $path =~ m/ [.] (?: (?i: pl ) | pm | pod | t ) \z /smx
	and return 1;
    open my $fh, '<', $path
	or return;
    local $_ = <$fh> || '';
    close $fh;
    return m/ perl /smx;
}

{
    my $bareword;

    sub _is_perl_function {
	my ( undef, $word ) = @_;
	$bareword ||= {
	    map { $_ => 1 } @B::Keywords::Functions, @B::Keywords::Barewords };
	return $bareword->{$word};
    }
}

{
    my %ignore;
    BEGIN {
	%ignore = map { $_ => 1 } __PACKAGE__, qw{ DB File::Find };
    }

    sub _nest_depth {
	my $nest = 0;
	$nest++ while $ignore{ caller( $nest ) || '' };
	return $nest;
    }
}

package My_Parser;		## no critic (ProhibitMultiplePackages)

use Pod::Simple::PullParser;	# Core since 5.9.3 (part of Pod::Simple)

@My_Parser::ISA = qw{ Pod::Simple::PullParser };

my %section_tag = map { $_ => 1 } qw{ head1 head2 head3 head4 item-text };

sub new {
    my ( $class ) = @_;
    my $self = $class->SUPER::new();
    $self->preserve_whitespace( 1 );
    return $self;
}

sub run {
    my ( $self, $source, $err, @err_arg ) = @_;
	defined $source
	    and $self->set_source( $source );
    my $attr = $self->_attr();
    @{ $attr }{ qw{ line links sections } } = ( 1, [], {} );
    while ( my $token = $self->get_token() ) {
	if ( my $code = $self->can( '__token_' . $token->type() ) ) {
	    $code->( $self, $token );
	}
    }
    $err
	and $self->any_errata_seen()
	and $err->( @err_arg );
    return wantarray ?
	( $attr->{sections}, $attr->{links} ) :
	$attr->{sections};
}

sub _attr {
    my ( $self ) = @_;
    return $self->{ ( __PACKAGE__ ) } ||= {};
}

sub _normalize_text {
    my ( $text ) = @_;
    defined $text
	or $text = '';
    $text =~ s/ \A \s+ //smx;
    $text =~ s/ \s+ \z //smx;
    $text =~ s/ \s+ / /smxg;
    return $text;
}

sub __token_start {
    my ( $self, $token ) = @_;
    my $attr = $self->_attr();
    if ( defined( my $line = $token->attr( 'start_line' ) ) ) {
	$attr->{line} = $line;
    }
    my $tag = $token->tag();
    if ( 'L' eq $tag ) {
	$token->attr( line_number => $self->{My_Parser}{line} );
	foreach my $name ( qw{ section to } ) {
	    my $sect = $token->attr( $name )
		or next;
	    @{ $sect }[ 2 .. $#$sect ] = ( _normalize_text( "$sect" ) );
	}
	push @{ $attr->{links} }, [ @{ $token }[ 1 .. $#$token ] ];
    } elsif ( $section_tag{$tag} ) {
	$attr->{text} = '';
    }
    return;
}

sub __token_text {
    my ( $self, $token ) = @_;
    my $attr = $self->_attr();
    my $text = $token->text();
    $attr->{line} += $text =~ tr/\n//;
    $attr->{text} .= $text;
    return;
}

sub __token_end {
    my ( $self, $token ) = @_;
    my $attr = $self->_attr();
    my $tag = $token->tag();
    if ( $section_tag{$tag} ) {
	$attr->{sections}{ _normalize_text( delete $attr->{text} ) } = 1;
    }
    return;
}

1;

__END__

=encoding utf8

=head1 NAME

Test::Pod::LinkCheck::Lite - Test POD links

=head1 SYNOPSIS

 use Test::More 0.88;   # for done_testing();
 use Test::Pod::LinkCheck::Lite;
 
 my $t = Test::Pod::LinkCheck::Lite->new();
 $t->all_pod_files_ok();

 done_testing;

=head1 DESCRIPTION

This Perl module tests POD links. A given file generates one failure for
each broken link found. If no broken links are found, one passing test
is generated. This all means that there is no way to know how many tests
will be generated, and you will need to use L<Test::More|Test::More>'s
C<done_testing()> (or something equivalent) at the end of your test.

By its nature this module should be used only for author testing. The
problem with using it in an installation test is that the validity of
links external to the distribution being tested varies with things like
operating system type and version, Perl version, installed Perl modules
and their versions, and the Internet at large. I<Caveat user.>

This module should probably be considered alpha-quality code at this
point. It checks most of my modest corpus (correctly, I hope), but
beyond that deponent sayeth not.

One thing L<perlpod|perlpod> is silent on (at least, I could not find
anything about it) is how (or even whether) to normalize links and
section names. Maybe I looked in the wrong place?

Anyhow, because Meta CPAN has been observed to link

 L<SOME
 SECTION>

to C<=head1 SOME SECTION>, this module normalizes both link and section
names by removing leading and trailing white space, and replacing
embedded white space with a single space. Yes, I know that Meta CPAN's
observed handling of POD is B<far> from being definitive.

This module started its life as a low-dependency version of
L<Test::Pod::LinkCheck|Test::Pod::LinkCheck>. Significant
differences from that module include:

=over

=item Minimal use of the shell

This module shells out only to check C<man> links.

=item Unchecked links are explicitly skipped

That is, a skipped test is generated for each. Note that
L<Test::Pod::LinkCheck|Test::Pod::LinkCheck> appears to fail the link in
at least some such cases.

=item URL links are checked

This seemed to be an easy enough addition.

=item Dependencies are minimized

Given at least Perl 5.13.9, the only non-core module used is
L<B::Keywords|B::Keywords>.

=back

POD links come in the following flavors:

=over

=item * man

These links are of the form C<< LE<lt>manpage (section)E<gt> >>. They
will only be checked if the C<man> attribute is true, and can only be
successfully checked if the C<man> command actually displays man pages,
and C<man -w> can be executed.

=item * url

These links are of the form C<< LE<lt>http://...E<gt> >> (or C<https:>
or whatever). They will only be checked if the C<check_url> attribute is
true, and can only be successfully checked if Perl has access to the
specified URL.

=item * pod (internal)

These links are of the form C<< LE<lt>text|/sectionE<gt> >>. They are
checked using the parse tree in which the link was found.

=item * pod (external)

This is pretty much everything else. There are a number of cases, and
the only way to distinguish them is to run through them.

=over

=item Perl built-ins

These links are of the form C<< LE<lt>text|builtin>E<gt> >> or
C<< LE<lt>builtinE<gt> >>, and are checked against the lists in
L<B::Keywords|B::Keywords>.

=item Installed modules and pod files

These are resolved to a file using L<Pod::Perldoc|Pod::Perldoc>. If a
section was specified, the file is parsed to determine whether the
section name is valid.

=item Uninstalled modules

These are checked against F<modules/02packages.details.txt.gz>, provided
that (or some reasonable facsimile) can be found. Currently we can look
for this information in the following places:

=over

=item File F<Metadata> in the directory used by the C<CPAN> client;

=item Website L<https://cpanmetadb.plackperl.org/>, a.k.a. the CPAN Meta DB.

=back

If more than one of these is configured (by default they all are), we
look in the newest one.

Sections can not be checked. If a link to a valid (but uninstalled)
module has a section, a skipped test is generated.

=back

=back

The C<::Lite> refers to the fact that a real effort has been made to
reduce non-core dependencies. Under Perl 5.14 and up, the only known
non-core dependency is L<B::Keywords|B::Keywords>.

An effort has also been made to minimize the spawning of system
commands.

=head1 METHODS

This class supports the following public methods:

=head2 new

 my $t = Test::Pod::LinkCheck::Lite->new();

This static method instantiates an object. Optional arguments are passed
as name/value pairs.

The following arguments are supported:

=over

=item agent

This argument is the user agent string to use for web access.

The default is that of L<HTTP::Tiny|HTTP::Tiny>.

=item allow_man_spaces

This Boolean argument is set true to allow internal spaces in a 'man'
link. B<Note> that such links can not be checked under some operating
systems (e.g. FreeBSD) because the L<man (1)> program splits its
arguments on spaces.

The default is false.

=item cache_url_response

This Boolean argument is set true to cache the responses from URL links.
This means each URL is queried only once, no matter how many times it
appears.

The default is true.

=item check_external_sections

This Boolean argument is true if the sections of links outside the
current Pod are to be checked. If it is false, such sections are not
checked, and the link is considered valid if the external Pod exists at
all.

The default is true.

=item check_url

This Boolean argument is true if C<url> links are to be checked, and
false if not.

The default is true.

=item ignore_url

This argument specifies one or more URLs to ignore when checking C<url>
links. It can be specified as:

=over

=item A C<Regexp> object

Any URL that matches this Regexp is ignored.

=item C<undef>

No URLs are ignored.

=item a scalar

This URL is ignored.

=item a SCALAR reference

The URL referred to is ignored.

=item a HASH reference

The URL is ignored if the hash contains a true value for the URL.

=item a CODE reference

The code is called with the URL to ignore in the topic variable (a.k.a.
C<$_>). The URL is ignored if the code returns a true value.

=item an C<ARRAY> reference

The array can contain any legal ignore specification, and any URL that
matches any value in the array is ignored. Nested arrays are flattened.

=back

The default is C<[]>.

B<Note> that the order in which the individual checks are made is
B<undefined>. OK, the implementation is deterministic, but the order of
evaluation is an implementation detail that the author reserves the
right to change without warning.

=item man

This Boolean argument is true if C<man> links are to be checked, and
false if not.

The default is false (with a diagnostic) if C<$^O> is C<'DOS'> or
C<'MSWin32'>. Under any other operating system the default is the value
of C<IPC::Cmd::can_run( 'man' )>. If this returns false a diagnostic is
generated, and C<man> links are not checked.

In case you're wondering: the Windows testing was done under ReactOS,
and that appears to come with a F<MAN.EXE> which (at least under 0.4.11)
causes C<can_run()> to return true, but which does, as far as I can
tell, nothing useful.

=item module_index

This argument specifies a list of module indices to consult, as either a
comma-delimited string or an array reference. Even if specified a given
index will only be used if it is actually available for use. If more
than one index is found, the most-recently-updated index will be used.
Possible indices are:

=over

=item cpan

Use the module index found in the L<CPAN|CPAN> working directory.

=item cpan_meta_db

Use the CPAN Meta database. Because this is an on-line index it is
considered to be current, but its as-of time is offset to favor local
indices.

=back

By default all indices are considered.

=item prohibit_redirect

Added in version 0.004

This argument controls whether redirects are allowed in the resolution
of a URL link.

If a code reference is specified, it is called whenever a URL link is
successfully resolved. The arguments are the
C<Test::Pod::LinkCheck::Lite> object, the L<HTTP::Tiny> response hash,
and the URL from the link. The code returns true to declare the link in
error, false to allow it, or a code reference to defer the decision to
that code. This latter is provided because I found the case where I
wanted to do a little pre-processing and then defer to
L<ALLOW_REDIRECT_TO_INDEX|/ALLOW_REDIRECT_TO_INDEX>, but could not find
a clean way to use a manifest constant in a C<goto>.

Any other value is interpreted as a Boolean. If the argument is true,
any redirect is an error. If false, redirects are allowed.

This argument is ignored unless L<check_url|/check_url> is true.

The default is false, for historical reasons.

=item require_installed

This Boolean argument is true to disable the uninstalled module checks.
This means links to modules not installed on the system will fail, even
if the module exists.

By default this is false.

=item skip_server_errors

Added in version 0.002.

This Boolean argument is true to generate skips rather than failures if
an attempt to check a URL link fails with a server error (status
C<5xx>).

By default this is true; it can be made false by passing value C<0> or
C<''>.

The default represents a change in the default behaviour from version
C<0.001>, which failed a URL link if the check returned a server error.
The logic (if any) in changing the default behaviour is that C<5xx>
errors can represent actual server problems rather than errors in the
link being checked, so changing the default behaviour eliminates
possible false positives.

=back

=head2 agent

This method returns the value of the C<'agent'> attribute.

=head2 all_pod_files_ok

 $t->all_pod_files_ok();

This method takes as its arguments the names of one or more files, and
tests any such that are deemed to be Perl files. Directories are
recursed into.

Perl files are considered to be all text files whose names end in
F<.pod>, F<.pm>, or F<.PL>, plus any text files with a shebang line
containing C<'perl'>. File name suffixes are case-sensitive except for
F<.PL>.

If no arguments are specified, the contents of F<blib/> are tested. This
is the recommended usage.

If called in scalar context, this method returns the number of test
failures encountered. If called in list context it return the number of
failures, passes, and skipped tests, in that order.

=head2 allow_man_spaces

 $t->allow_man_spaces()
   and say 'Embedded spaces are allowed in man page names';

This method returns the value of the C<'allow_man_spaces'> attribute.

=head2 cache_url_response

 $t->cache_url_response()
   and say 'URL responses are cached';

This method returns the value of the C<'cache_url_response'> attribute.

=head2 check_external_sections

 $t->check_external_sections()
     and say 'Sections in external links are checked';

This method returns the value of the C<'check_url'> attribute.

=head2 check_url

 $t->check_url() and say 'URL links are checked';

This method returns the value of the C<'check_url'> attribute.

=head2 configuration

 say $t->configuration( '    ' );

This convenience method returns a string containing all attributes of
the object in human-readable form. The argument, if any, is prefixed to
each line of the returned string.

=head2 ignore_url

 print 'Ignored URLs ', join ', ', $t->ignore_url();

This method returns the value of the C<'ignore_url'> attribute. If
called in scalar context, it returns an array reference. If called in
list context it returns an array. Either way, the results will B<not> be
in the same order as originally specified to L<new()|/new>.

=head2 man

 $t->man() and say 'man links are checked';

This method returns the value of the C<'man'> attribute.

=head2 module_index

 say 'Module indices: ', join ', ', $self->module_index();

This method returns the value of the C<'module_index'> attribute. If
called in scalar context it returns a comma-delimited string.

=head2 pod_file_ok

 my $failures = $t->pod_file_ok( 'lib/Foo/Bar.pm' );

This method tests the links in the given file. Each failure appears in
the TAP output as a test failure. If no failures are found, a passing
test will appear in the TAP output.

If called in scalar context, this method returns the number of test
failures encountered. If called in list context it return the number of
failures, passes, and skipped tests, in that order.

=head2 prohibit_redirect

 $t->prohibit_redirect()
     and say 'All URL links must resolve without redirection';

Added in version 0.004

This method returns the value of the C<'prohibit_redirect'> attribute.

=head2 require_installed

 $t->require_installed()
    and say 'All POD links must be to installed modules';

This method returns the value of the C<'require_installed'> attribute.

=head2 skip_server_errors

 $t->skip_server_errors()
    and say 'URL links that return status 5xx are skipped';

Added in version 0.002.

This method returns the value of the C<'skip_server_errors'> attribute.

=head1 MANIFEST CONSTANT

The following manifest constant can be imported by name, or using the
C<:const> tag:

=head2 ALLOW_REDIRECT_TO_INDEX

This manifest constant is intended to be used as a value of the
C<'prohibit_redirect'> attribute. It is a reference to a piece of code
that accepts old-style redirects of an hierarchical URL ending in a
C<'/'> to an index of that leaf of the hierarchy.

Because this is a minimal-dependency module, the code referred to by
this constant works by hand-checking for an hierarchical scheme
(anything but C<'data:'>, C<'mailto:'>, or C<'urn:'>). If a URL with an
hierarchical scheme ends in C<'/'>, the URL in the response has
everything after the last C<'/'> removed before comparison to the
original URL.

This mess exists because of my bias that old-style redirection to an
index is a different beast than indirection in general, and ought to be
allowed. If you disagree you can ignore this functionality, or
re-implement to suit yourself.

=head1 SEE ALSO

L<Test::Pod::LinkCheck|Test::Pod::LinkCheck> by Apocalypse (C<APOCAL>)
checks all POD links except for URLs. It is L<Moose|Moose>-based.

L<Test::Pod::Links|Test::Pod::Links> by Sven Kirmess (C<SKIRMESS>)
checks all URLs or URL-like things in the document, whether or not they
are actual POD links.

L<Test::Pod::No404s|Test::Pod::No404s> by Apocalypse (C<APOCAL>) checks
URL POD links.

=head1 ACKNOWLEDGMENTS

The author would like to acknowledge the following, without whom this
module would not exist -- at least, not in anything like its current
form.

Mohammed Anwar (C<MANWAR>) who submitted the "broken POD link" ticket
that started me thinking about testing for this kind of thing.

The CPAN Testers who, by testing my code under such a broad range of
configurations, gave me an opportunity to make this module much more
robust than it would otherwise have been. It is probably unfair to
single out individual testers, but as the luck of the testing cycle
would have it, results from Andreas J. König (C<ANDK>), Slaven Rezić
(C<SREZIC>), Chris Williams (C<BINGOS>), and Alceu Rodrigues de Freitas
Junior were particularly useful to me.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Pod-LinkCheck-Lite>,
L<https://github.com/trwyant/perl-Test-Pod-LinkCheck-Lite/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
