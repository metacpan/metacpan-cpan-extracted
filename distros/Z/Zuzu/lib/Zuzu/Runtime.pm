package Zuzu::Runtime;

use utf8;

our $VERSION = '0.005000';
our $DEBUG_LEVEL = 0;

use Digest::MD5 qw( md5_hex );
use Encode qw( FB_CROAK decode );
use File::Spec;
use File::Basename qw( dirname );
use File::Path qw( make_path );
use File::ShareDir qw( dist_dir );
use File::Temp qw( tempfile );
use Cwd ();
use Storable qw( nstore retrieve );

use Zuzu::Env;
use Zuzu::Error;
use Zuzu::Lexer;
use Zuzu::Parser;
use Zuzu::Parser::_Impl;
use Zuzu::Runtime::Async::Scheduler;
use Zuzu::Util ();
use Zuzu::AST::Expr::TypeRef;
use Zuzu::AST::Stmt::Class;
use Zuzu::Value::Array;
use Zuzu::Value::Class;
use Zuzu::Value::Dict;
use Zuzu::Value::Function;
use Zuzu::Value::Object;
use Zuzu::Value::PairList;
use Zuzu::Value::Regexp;
use Zuzu::Value::Set;
use Zuzu::Value::Bag;
use POSIX ();
use Zuzu::Value::Boolean;
use Zuzu::Value::BinaryString;
use Zuzu::Value::Task;
use Zuzu::Value::Equality qw(
	equality_type
	stable_value_key
	value_equal
);
use Zuzu::Value::Trait;
use Zuzu::Weak qw( slot_value store_value );

use Moo;
use Scalar::Util qw( blessed refaddr weaken );

no warnings 'recursion';

our %MODULE_AST_CACHE;
our %MODULE_PATH_CACHE;
our $PERSISTENT_AST_CACHE_VERSION = 4;
our $PERSISTENT_AST_CACHE_MAGIC = 'ZUZU-PERL-AST-CACHE';
our $PERSISTENT_AST_CACHE_MAX_SIZE = 100 * 1024 * 1024;
our $PERSISTENT_AST_CACHE_MAX_AGE = 30 * 24 * 60 * 60;
our $PERSISTENT_AST_CACHE_ROOT;
our $PERSISTENT_AST_CACHE_EXPIRY_RAN = 0;
our $EMPTY_HASH = {};
our $EMPTY_ARRAY = [];

my $TRUE  = Zuzu::Value::Boolean->new( value => 1 );
my $FALSE = Zuzu::Value::Boolean->new( value => 0 );
sub _boolify { $_[0] ? $TRUE : $FALSE }
my @BUILTIN_COLLECTION_KINDS = qw( Array Dict PairList Set Bag );
my %ARRAY_MUTATING_METHOD = map { $_ => 1 } qw(
	append push add push_weak pop
	prepend unshift unshift_weak shift
	set set_weak clear remove
);
my %DICT_MUTATING_METHOD = map { $_ => 1 } qw(
	add add_weak set set_weak remove clear
);
my %SET_MUTATING_METHOD = map { $_ => 1 } qw(
	add add_weak push push_weak remove clear remove_if
);
my %BAG_MUTATING_METHOD = map { $_ => 1 } qw(
	add add_weak push push_weak remove remove_first clear remove_if
);

has 'lib' => ( is => 'rw', default => sub { [ @Zuzu::Runtime::DEFAULT_LIB ] } );
has 'deny_modules' => ( is => 'rw', default => sub { [] } );
has 'forbid' => ( is => 'rw', default => sub { [] } );
has 'deny' => ( is => 'rw', default => sub { [] } );
has 'allow' => ( is => 'rw' );
has 'persistent_ast_cache' => ( is => 'rw', default => sub { 1 } );
has 'disabled_visitors' => ( is => 'rw', default => sub { [] } );
has 'builtin' => ( is => 'rw', default => sub {
	return {
		'std/data/json' => 'Zuzu::Module::JSON',
		'std/marshal' => 'Zuzu::Module::Marshal',
		'std/archive' => 'Zuzu::Module::Archive',
		'std/data/csv' => 'Zuzu::Module::CSV',
		'std/data/yaml' => 'Zuzu::Module::YAML',
		'std/math' => 'Zuzu::Module::Math',
		'std/math/bignum' => 'Zuzu::Module::Math::BigNum',
		'std/io' => 'Zuzu::Module::IO',
		'std/time' => 'Zuzu::Module::Time',
		'std/task' => 'Zuzu::Module::Task',
		'std/worker' => 'Zuzu::Module::Worker',
		'std/net/dns' => 'Zuzu::Module::DNS',
		'std/net/http' => 'Zuzu::Module::HTTP',
		'std/net/smtp' => 'Zuzu::Module::Net::SMTP',
		'std/net/url' => 'Zuzu::Module::URL',
		'std/proc' => 'Zuzu::Module::Proc',
		'std/db' => 'Zuzu::Module::DB',
		'std/clib' => 'Zuzu::Module::CLib',
		'std/io/socks' => 'Zuzu::Module::Socks',
		'std/string' => 'Zuzu::Module::String',
		'std/string/base64' => 'Zuzu::Module::Base64',
		'std/string/encode' => 'Zuzu::Module::String::Encode',
		'std/digest/md5' => 'Zuzu::Module::DigestMD5',
		'std/digest/sha' => 'Zuzu::Module::DigestSHA',
		'std/secure' => 'Zuzu::Module::Secure',
		'std/data/xml' => 'Zuzu::Module::XML',
		'std/internals' => 'Zuzu::Module::Internals',
		'std/tui' => 'Zuzu::Module::TUI',
		'std/eval' => 'Zuzu::Module::Eval',
		'std/gui/objects' => 'Zuzu::Module::GUI::Objects',
		'perl' => 'Zuzu::Module::Perl',
	};
} );

our $INITIAL_CWD = Cwd::getcwd();

sub _absolute_module_path {
	my ( $path ) = @_;
	return undef if !defined $path or $path eq '';
	return File::Spec->rel2abs( $path, $INITIAL_CWD );
}

sub _dedup_paths {
	my ( @paths ) = @_;
	my %seen;
	return grep {
		defined $_ and $_ ne '' and !$seen{$_}++
	} @paths;
}

sub _env_path_separator {
	return $^O eq 'MSWin32' ? ';' : ':';
}

sub _user_modules_dir {
	return _absolute_module_path(
		File::Spec->catdir( $ENV{LOCALAPPDATA}, 'Zuzu', 'modules' )
	) if $^O eq 'MSWin32' and defined $ENV{LOCALAPPDATA} and $ENV{LOCALAPPDATA} ne '';

	return _absolute_module_path(
		File::Spec->catdir( $ENV{HOME}, '.zuzu', 'modules' )
	) if defined $ENV{HOME} and $ENV{HOME} ne '';

	return undef;
}

sub _system_modules_dir {
	return _absolute_module_path(
		File::Spec->catdir( $ENV{ProgramData}, 'Zuzu', 'modules' )
	) if $^O eq 'MSWin32' and defined $ENV{ProgramData} and $ENV{ProgramData} ne '';

	return '/var/lib/zuzu/modules';
}

sub _dist_modules_dir {
	my $dir = eval { dist_dir('Zuzu') };
	return undef if !defined $dir or $dir eq '';
	my $modules = File::Spec->catdir( $dir, 'modules' );
	return _absolute_module_path($modules) if -d $modules;
	return _absolute_module_path($dir) if -d File::Spec->catdir( $dir, 'std' );
	return undef;
}

our @DEFAULT_LIB = do {
	my @paths;

	if ( defined $ENV{ZUZULIB} and $ENV{ZUZULIB} ne '' ) {
		my $separator = _env_path_separator();
		push @paths, map {
			_absolute_module_path($_)
		} grep {
			defined $_ and $_ ne ''
		} split /\Q$separator\E/, $ENV{ZUZULIB};
	}

	my $user_dir = _user_modules_dir();
	push @paths, $user_dir if defined $user_dir and -d $user_dir;

	my $system_dir = _system_modules_dir();
	push @paths, $system_dir if defined $system_dir and -d $system_dir;

	if ( defined $ENV{ZUZU_STDLIB} and $ENV{ZUZU_STDLIB} ne '' ) {
		push @paths, _absolute_module_path( $ENV{ZUZU_STDLIB} );
	}
	else {
		push @paths, ( _dist_modules_dir() // () );
	}

	_dedup_paths(@paths);
};

sub BUILD {
	my ($self, $args) = @_;

	$self->lib([
		_dedup_paths(
			map { _absolute_module_path($_) } @{ $self->lib // [] }
		),
	]);
	$self->disabled_visitors([
		Zuzu::Parser->normalize_disabled_visitors(
			@{ $self->disabled_visitors // [] },
		),
	]);
	$self->{_parser} = Zuzu::Parser->new(
		disabled_visitors => $self->disabled_visitors,
	);
	$self->{_global} = Zuzu::Env->_new_fast(undef);
	$self->{_stack} = [ $self->{_global} ];
	$self->{_modules} = {}; # module => env
	$self->{_module_exports} = {}; # module => { name => 1 }
	$self->{_builtin_global_names} = {};
	$self->{_system_readonly_refs} = {};
	$self->{_regexp_cache} = {};
	$self->{_module_candidate_cache} = {};
	$self->{_method_candidate_cache} = {};
	$self->{_bound_method_cache} = {};
	$self->{_per_object_trait_class_cache} = {};
	$self->{_module_builtin_aliases} = [];
	$self->{_module_builtin_slot_set} = {};
	$self->{_demolish_objects} = [];
	$self->{_scheduler} = Zuzu::Runtime::Async::Scheduler->new(
		runtime => $self,
	);
	$self->_normalize_policies;
	$self->_install_builtins;
	$self->_install_special_globals;
	$self->_refresh_module_builtin_alias_cache;

	return;
}

sub finish {
	my ( $self ) = @_;

	return $self if $self->{_finishing};
	local $self->{_finishing} = 1;

	while ( @{ $self->{_demolish_objects} // [] } ) {
		my $object = pop @{ $self->{_demolish_objects} };
		next
			if !blessed($object)
			or !$object->isa('Zuzu::Value::Object')
			or !$object->can('run_demolish_hook');
		$object->run_demolish_hook;
	}

	return $self;
}

sub DEMOLISH {
	my ( $self ) = @_;

	$self->{_scheduler}->shutdown
		if defined $self->{_scheduler}
		and $self->{_scheduler}->can('shutdown');

	return;
}

sub evaluate {
	my ($self, $ast) = @_;

	if (
		blessed($ast)
		and $ast->isa('Zuzu::AST::Program')
		and !$self->_env->{slots}{'__file__'}
	) {
		$self->_declare_file_const( $self->_env, $ast->file, 0 );
	}

	return $ast->evaluate($self);
}

sub parse_with_current_scope {
	my ( $self, $source, $filename ) = @_;

	$filename //= '<eval>';

	my $ast;
	eval {
		my $lexer = Zuzu::Lexer->new( src => $source, filename => $filename );
		my $parser = Zuzu::Parser::_Impl->new(
			lexer => $lexer,
			filename => $filename,
		);

		my %visible;
		my $env = $self->_env;
		while ( defined $env ) {
			for my $name ( CORE::keys %{ $env->slots } ) {
				next if $name eq '__wildcard_import__';
				$visible{$name} = 1;
			}
			$env = $env->parent;
		}

		my $scope = $parser->scopes->[0];
		for my $name ( CORE::keys %visible ) {
			next if exists $scope->{$name};
			$scope->{$name} = {
				kind => 'eval-visible',
				mutable => 1,
			};
		}
		push @{ $parser->scopes }, {};

		$ast = $parser->parse_program;
		$self->{_parser}->apply_visitors($ast);
		1;
	} or do {
		my $error = $@;
		die $error if ref($error) and eval { $error->isa('Zuzu::Error') };
		die $self->{_parser}->_compile_error_from_parse_exception(
			$error,
			$filename,
		);
	};

	return $ast;
}

sub eval_with_current_scope {
	my ( $self, $source, $filename ) = @_;

	my $ast = $self->parse_with_current_scope( $source, $filename );
	my $env = Zuzu::Env->_new_fast( $self->_env );
	$self->_push_env($env);
	my ( $ok, $result, $error );
	$ok = eval {
		$result = $self->evaluate( $ast );
		1;
	};
	$error = $@ if !$ok;
	$self->_pop_env;

	die $error if !$ok;
	return $result;
}

sub eval_with_current_scope_denials {
	my ( $self, $source, $filename, $extra_denials ) = @_;

	my @extra = grep { defined $_ and $_ ne '' } @{ $extra_denials // [] };
	return $self->eval_with_current_scope( $source, $filename )
		if scalar @extra == 0;

	return $self->_with_additional_denials(
		\@extra,
		sub {
			return $self->eval_with_current_scope( $source, $filename );
		},
	);
}

sub _with_additional_denials {
	my ( $self, $extra_denials, $code ) = @_;

	my @extra = grep { defined $_ and $_ ne '' } @{ $extra_denials // [] };
	return $code->() if scalar @extra == 0;

	my @current = @{ $self->deny // [] };
	my %seen = map { $_ => 1 } @current;
	my @combined = ( @current, grep { !$seen{$_}++ } @extra );
	my %restore = (
		deny => [ @current ],
		deny_modules => [ @{ $self->deny_modules // [] } ],
		forbid => [ @{ $self->forbid // [] } ],
		allow => ( defined $self->allow ? [ @{ $self->allow } ] : undef ),
		deny_set => { %{ $self->{_deny_set} // {} } },
	);

	$self->deny( \@combined );
	$self->_normalize_policies;
	$self->_sync_system_policy_flags;

	my ( $ok, $result, $error );
	$ok = eval {
		$result = $code->();
		1;
	};
	$error = $@ if !$ok;

	$self->deny( $restore{deny} );
	$self->deny_modules( $restore{deny_modules} );
	$self->forbid( $restore{forbid} );
	$self->allow( $restore{allow} );
	$self->{_deny_set} = $restore{deny_set};
	$self->_sync_system_policy_flags;

	die $error if !$ok;
	return $result;
}


sub has_function {
	my ($self, $name) = @_;

	my $ref = $self->{_global}->find_ref($name);
	return 0 if !$ref;
	my $fn = $$ref;

	return ( blessed($fn) and $fn->isa('Zuzu::Value::Function') ) ? 1 : 0;
}

sub function_is_async {
	my ($self, $name) = @_;

	my $fn = $self->_global_function($name);
	return $fn->is_async ? 1 : 0;
}

sub call {
	my ($self, $name, @args) = @_;

	my $value = $self->call_unawaited($name, @args);
	return $value->await
		if blessed($value) and $value->isa('Zuzu::Value::Task');
	return $value;
}

sub call_unawaited {
	my ($self, $name, @args) = @_;

	my $fn = $self->_global_function($name);
	return $self->_call_function(
		$fn,
		\@args,
		$EMPTY_HASH,
		$EMPTY_ARRAY,
		'<call>',
		0,
	);
}

sub _global_function {
	my ($self, $name) = @_;

	my $ref = $self->{_global}->find_ref($name);
	die Zuzu::Error->new_runtime(message => "No such function '$name'", file => '<runtime>', line => 0) if !$ref;
	my $fn = $$ref;
	die Zuzu::Error->new_runtime(message => "'$name' is not a function", file => '<runtime>', line => 0) if !blessed($fn) or !$fn->isa('Zuzu::Value::Function');

	return $fn;
}

sub _env { $_[0]->{_stack}[-1] }

sub _var_ref_for_node {
	my ( $self, $node ) = @_;

	my $name = $node->{name};
	if (
		defined $node->{_env_depth}
		and defined $node->{_binding_name}
		and $node->{_binding_name} eq $name
	) {
		my $env = $self->{_stack}[-1];
		for ( 1 .. $node->{_env_depth} ) {
			last if !defined $env;
			$env = $env->{parent};
		}
		return ( $env->{slots}{$name}, $env )
			if defined $env and exists $env->{slots}{$name};
	}

	my $env = $self->{_stack}[-1];
	while ($env) {
		return ( $env->{slots}{$name}, $env )
			if exists $env->{slots}{$name};
		$env = $env->{parent};
	}

	return;
}

sub _push_env { push @{$_[0]->{_stack}}, $_[1] }

sub _pop_env  { pop  @{$_[0]->{_stack}} }

sub _capture_env {
	my ( $self, $env ) = @_;

	return undef if !defined $env;

	my $captured_parent = $self->_capture_env( $env->parent );
	my $captured = Zuzu::Env->_new_fast( $captured_parent );
	for my $name ( keys %{ $env->slots } ) {
		$captured->alias_to_ref(
			$name,
			$env->slots->{$name},
			$env->const->{$name} ? 1 : 0,
			exists $env->types->{$name} ? $env->types->{$name} : 'Any',
		);
	}
	for my $key ( keys %{ $env->special_props } ) {
		$captured->set_special_prop( $key, $env->special_props->{$key} );
	}

	return $captured;
}

sub env_get_special_prop {
	my ( $self, $key ) = @_;

	my $type = $self->_type_name( $key );
	die Zuzu::Error->new_runtime(
		message => "TypeException: getprop key must be String, got $type",
		file => '<runtime>',
		line => 0,
	) if $type ne 'String';

	return $self->_env->get_special_prop( $key );
}

sub env_set_special_prop {
	my ( $self, $key, $value ) = @_;

	my $type = $self->_type_name( $key );
	die Zuzu::Error->new_runtime(
		message => "TypeException: setprop key must be String, got $type",
		file => '<runtime>',
		line => 0,
	) if $type ne 'String';

	return $self->_env->set_special_prop( $key, $value );
}

sub _special_prop_env_at_level {
	my ( $self, $level, $for_name ) = @_;

	my $type = $self->_type_name( $level );
	die Zuzu::Error->new_runtime(
		message => "TypeException: $for_name level must be Number, got $type",
		file => '<runtime>',
		line => 0,
	) if $type ne 'Number';

	my $int_level = int( 0 + $level );
	die Zuzu::Error->new_runtime(
		message => "TypeException: $for_name level must be a non-negative integer",
		file => '<runtime>',
		line => 0,
	) if $int_level != $level or $int_level < 0;

	my $target_index = $#{ $self->{_stack} } - ( $int_level + 1 );
	return undef if $target_index < 0;

	return $self->{_stack}->[$target_index];
}

sub env_get_upper_special_prop {
	my ( $self, $level, $key ) = @_;

	my $type = $self->_type_name( $key );
	die Zuzu::Error->new_runtime(
		message => "TypeException: getupperprop key must be String, got $type",
		file => '<runtime>',
		line => 0,
	) if $type ne 'String';

	my $target_env = $self->_special_prop_env_at_level( $level, 'getupperprop' );
	return undef if not defined $target_env;

	return $target_env->get_special_prop( $key );
}

sub env_set_upper_special_prop {
	my ( $self, $level, $key, $value ) = @_;

	my $type = $self->_type_name( $key );
	die Zuzu::Error->new_runtime(
		message => "TypeException: setupperprop key must be String, got $type",
		file => '<runtime>',
		line => 0,
	) if $type ne 'String';

	my $target_env = $self->_special_prop_env_at_level( $level, 'setupperprop' );
	return $value if not defined $target_env;

	return $target_env->set_special_prop( $key, $value );
}

sub _normalize_policies {
	my ( $self ) = @_;

	my @deny = grep { defined $_ and $_ ne '' } @{ $self->deny // [] };
	my @deny_modules = grep { defined $_ and $_ ne '' } @{ $self->deny_modules // [] };
	push @deny_modules, grep { defined $_ and $_ ne '' } @{ $self->forbid // [] };
	my @known = qw( fs net perl js proc db clib gui worker );
	my %deny_set = map { $_ => 1 } @deny;
	my %seen_module;
	@deny_modules = grep { !$seen_module{$_}++ } @deny_modules;

	if ( defined $self->allow ) {
		my @allow = grep { defined $_ and $_ ne '' } @{ $self->allow // [] };
		my %allow_set = map { $_ => 1 } @allow;
		for my $capability ( @known ) {
			next if $allow_set{$capability};
			$deny_set{$capability} = 1;
		}
		$self->allow( \@allow );
	}
	else {
		$self->allow( undef );
	}

	$self->{_deny_set} = \%deny_set;
	$self->deny( \@deny );
	$self->deny_modules( \@deny_modules );
	$self->forbid( \@deny_modules );

	return;
}

sub is_denied {
	my ( $self, $capability ) = @_;

	return 0 if !defined $capability or $capability eq '';
	return 1 if $capability eq 'js';

	return $self->{_deny_set}{$capability} ? 1 : 0;
}

sub assert_capability {
	my ( $self, $capability, $message, $file, $line ) = @_;

	return if !$self->is_denied( $capability );
	$message //= "Capability '$capability' is denied by runtime policy";
	$file //= '<runtime>';
	$line //= 0;
	die Zuzu::Error->new_runtime(
		message => $message,
		file => $file,
		line => $line,
	);
}

sub _install_builtins {
	my ($self) = @_;

	no warnings;
	my %builtin = (
		say => sub {
			my @items = map { defined($_) ? $self->_to_String($_) : '' } @_;
			print STDOUT join( '', @items ), "\n";
			return undef;
		},
		print => sub {
			my @items = map { defined($_) ? $self->_to_String($_) : '' } @_;
			print STDOUT join( '', @items );
			return undef;
		},
		warn => sub {
			my @items = map { defined($_) ? $self->_to_String($_) : '' } @_;
			print STDERR join( '', @items ), "\n";
			return undef;
		},
		typeof => sub { $self->_type_name($_[0]) },
		to_binary => sub {
			my ( $value ) = @_;
			my $type = $self->_type_name( $value );
			die Zuzu::Error->new_runtime(
				message => "TypeException: to_binary expects String, got $type",
				file => '<runtime>',
				line => 0,
			) if $type ne 'String';

			return Zuzu::Value::BinaryString->from_utf8_string( $value );
		},
		to_string => sub {
			my ( $value ) = @_;
			my $type = $self->_type_name( $value );
			die Zuzu::Error->new_runtime(
				message => "TypeException: to_string expects BinaryString, got $type",
				file => '<runtime>',
				line => 0,
			) if $type ne 'BinaryString';

			return $value->to_utf8_string;
		},
	);

	for my $k (keys %builtin) {
		my $fn = Zuzu::Value::Function->new(
			name => $k,
			params => [],
			vararg => '__args',
			body => undef,
			closure_env => undef,
		);
		$fn->{_native} = $builtin{$k};
		$self->{_global}->declare($k, $fn, 1);
		$self->{_builtin_global_names}{$k} = 1;
	}

	$self->_install_builtin_classes;
}

sub _install_special_globals {
	my ( $self ) = @_;

	my $system = Zuzu::Value::Dict->new(
		map => {
			language_version => 0,
			runtime => 'Zuzu::Runtime',
			runtime_version => $Zuzu::Runtime::VERSION,
			perl_version => sprintf( '%.6f', $] ),
			platform => $^O,
				inc => Zuzu::Value::Array->new(
					items => [ @{ $self->lib // [] } ],
				),
			deny_fs => _boolify( $self->is_denied( 'fs' ) ),
			deny_net => _boolify( $self->is_denied( 'net' ) ),
			deny_perl => _boolify( $self->is_denied( 'perl' ) ),
			deny_js => _boolify( $self->is_denied( 'js' ) ),
			deny_proc => _boolify( $self->is_denied( 'proc' ) ),
			deny_db => _boolify( $self->is_denied( 'db' ) ),
			deny_clib => _boolify( $self->is_denied( 'clib' ) ),
			deny_gui => _boolify( $self->is_denied( 'gui' ) ),
			deny_worker => _boolify( $self->is_denied( 'worker' ) ),
		},
	);
	$self->_protect_system_value( $system );
	$self->{_global}->declare( '__system__', $system, 1 );
	$self->{_builtin_global_names}{'__system__'} = 1;

	my $global = Zuzu::Value::Dict->new( map => {} );
	$self->{_global}->declare( '__global__', $global, 0 );
	$self->{_builtin_global_names}{'__global__'} = 1;

	$self->{_global}->declare( 'DEBUG', 0 + $Zuzu::Runtime::DEBUG_LEVEL, 1 );
	$self->{_builtin_global_names}{'DEBUG'} = 1;

	return;
}

sub _sync_system_policy_flags {
	my ( $self ) = @_;

	my $global = $self->{_global};
	return if !defined $global;
	my $system_ref = $global->find_ref( '__system__' );
	return if !defined $system_ref;
	my $system = ${ $system_ref };
	return if !blessed( $system ) or !$system->isa( 'Zuzu::Value::Dict' );

	$system->map->{deny_fs} = _boolify( $self->is_denied( 'fs' ) );
	$system->map->{deny_net} = _boolify( $self->is_denied( 'net' ) );
	$system->map->{deny_perl} = _boolify( $self->is_denied( 'perl' ) );
	$system->map->{deny_js} = _boolify( $self->is_denied( 'js' ) );
	$system->map->{deny_proc} = _boolify( $self->is_denied( 'proc' ) );
	$system->map->{deny_db} = _boolify( $self->is_denied( 'db' ) );
	$system->map->{deny_clib} = _boolify( $self->is_denied( 'clib' ) );
	$system->map->{deny_gui} = _boolify( $self->is_denied( 'gui' ) );
	$system->map->{deny_worker} = _boolify( $self->is_denied( 'worker' ) );

	return;
}

sub _protect_system_value {
	my ( $self, $value ) = @_;

	return if !blessed $value;

	my $addr = refaddr( $value );
	return if !$addr or $self->{_system_readonly_refs}{$addr};
	$self->{_system_readonly_refs}{$addr} = 1;

	if ( $value->isa( 'Zuzu::Value::Dict' ) ) {
		for my $key ( CORE::keys %{ $value->map } ) {
			$self->_protect_system_value( $value->map->{$key} );
		}
	}
	elsif ( $value->isa( 'Zuzu::Value::Array' ) or $value->isa( 'Zuzu::Value::Set' ) or $value->isa( 'Zuzu::Value::Bag' ) ) {
		for my $item ( @{ $value->items } ) {
			$self->_protect_system_value( $item );
		}
	}
	elsif ( $value->isa( 'Zuzu::Value::PairList' ) ) {
		for my $pair ( @{ $value->list } ) {
			$self->_protect_system_value( $pair->[1] );
		}
	}
	elsif ( $value->isa( 'Zuzu::Value::Object' ) ) {
		for my $slot ( CORE::keys %{ $value->slots } ) {
			$self->_protect_system_value( $value->slots->{$slot} );
		}
	}

	return;
}

sub _is_system_protected_ref {
	my ( $self, $value ) = @_;

	return 0 if !blessed $value;
	my $addr = refaddr( $value );
	return 0 if !$addr;

	return $self->{_system_readonly_refs}{$addr} ? 1 : 0;
}

sub _assert_mutable_collection {
	my ( $self, $value, $file, $line ) = @_;

	return if !$self->_is_system_protected_ref( $value );
	die Zuzu::Error->new_runtime(
		message => "Cannot modify __system__",
		file => $file,
		line => $line,
	);
}

sub _install_builtin_classes {
	my ( $self ) = @_;

	my %classes;
	my @specs = (
		[ 'Any', undef, undef ],
		[ 'Null', 'Any', undef ],
		[ 'Boolean', 'Any', undef ],
		[ 'Number', 'Any', undef ],
		[ 'String', 'Any', undef ],
		[ 'BinaryString', 'Any', undef ],
		[ 'Task', 'Any', undef ],
		[ 'Object', 'Any', undef ],
		[ 'Collection', 'Object', undef ],
		[ 'Array', 'Collection', 'Array' ],
		[ 'Set', 'Collection', 'Set' ],
		[ 'Dict', 'Collection', 'Dict' ],
		[ 'PairList', 'Collection', 'PairList' ],
		[ 'Bag', 'Collection', 'Bag' ],
		[ 'Exception', 'Object', 'Exception' ],
		[ 'TypeException', 'Exception', 'Exception' ],
		[ 'AssertionException', 'Exception', 'Exception' ],
		[ 'ExhaustedException', 'Exception', 'Exception' ],
		[ 'CancelledException', 'Exception', 'Exception' ],
		[ 'TimeoutException', 'CancelledException', 'Exception' ],
		[ 'ChannelClosedException', 'Exception', 'Exception' ],
		[ 'Pair', 'Object', 'Pair' ],
		[ 'Regexp', 'Object', undef ],
		[ 'Function', 'Any', undef ],
		[ 'Trait', 'Any', undef ],
		[ 'Class', 'Any', undef ],
	);

	for my $spec ( @specs ) {
		my ( $name, $parent_name, $kind ) = @{ $spec };
		my $klass = Zuzu::Value::Class->new(
			name => $name,
			parent => ( defined $parent_name ? $classes{ $parent_name } : undef ),
			traits => [],
			field_specs => [],
			methods => {},
			trait_methods => {},
			static_methods => {},
			nested_classes => {},
			closure_env => $self->{_global},
			builtin_kind => $kind,
		);
		$classes{ $name } = $klass;
	}

	$classes{Exception}->native_constructor( sub {
		my ( $runtime, $klass, $positional, $named, $file, $line ) = @_;
		my $message = exists $named->{message} ? $named->{message} : $positional->[0];
		$message = 'Died' if !defined $message;

		return $runtime->_instantiate_builtin_object(
			$klass,
			{
				message => $message,
				file => $file,
				line => $line,
			},
		);
	} );
	$classes{Exception}->methods->{to_String} = Zuzu::Value::Function->new(
		name => 'to_String',
		params => [],
		vararg => undef,
		body => undef,
		closure_env => undef,
	);
	$classes{Exception}->methods->{to_String}{_native} = sub {
		my ( $self_obj ) = @_;
		my $class = $self_obj->class ? $self_obj->class->name : 'Exception';
		my $message = $self_obj->slots->{message} // '';
		return $message
			if $message eq $class or $message =~ /\A\Q$class\E:/;
		return $class if $message eq '';
		return "$class: $message";
	};
	$classes{Exception}->methods->{to_String}{_owner_class} = $classes{Exception};
	$classes{Exception}->methods->{to_String}{_method_name} = 'to_String';
	$classes{Exception}->methods->{to_String}{_method_kind} = 'instance';
	$classes{Exception}->methods->{message} = Zuzu::Value::Function->new(
		name => 'message',
		params => [],
		vararg => undef,
		body => undef,
		closure_env => undef,
	);
	$classes{Exception}->methods->{message}{_native} = sub {
		my ( $self_obj ) = @_;
		return $self_obj->slots->{message};
	};
	$classes{Exception}->methods->{message}{_owner_class} = $classes{Exception};
	$classes{Exception}->methods->{message}{_method_name} = 'message';
	$classes{Exception}->methods->{message}{_method_kind} = 'instance';

	$classes{Array}->native_constructor( sub {
		my ( $runtime, $klass, $positional, $named ) = @_;
		my @items = @{ $positional // [] };
		if ( exists $named->{items} and blessed($named->{items}) and $named->{items}->isa('Zuzu::Value::Array') ) {
			@items = @{ $named->{items}->items };
		}
		my $array = Zuzu::Value::Array->new( items => \@items );

		return $runtime->_wrap_builtin_if_needed( $klass, $array, 'Array' );
	} );

	$classes{Set}->native_constructor( sub {
		my ( $runtime, $klass, $positional, $named ) = @_;
		my @items = @{ $positional // [] };
		if ( exists $named->{items} and blessed($named->{items}) and $named->{items}->isa('Zuzu::Value::Array') ) {
			@items = @{ $named->{items}->items };
		}
		my $set = Zuzu::Value::Set->new( items => [] );
		$set->add( @items );

		return $runtime->_wrap_builtin_if_needed( $klass, $set, 'Set' );
	} );

	$classes{Bag}->native_constructor( sub {
		my ( $runtime, $klass, $positional, $named ) = @_;
		my @items = @{ $positional // [] };
		if ( exists $named->{items} and blessed($named->{items}) and $named->{items}->isa('Zuzu::Value::Array') ) {
			@items = @{ $named->{items}->items };
		}
		my $bag = Zuzu::Value::Bag->new( items => \@items );

		return $runtime->_wrap_builtin_if_needed( $klass, $bag, 'Bag' );
	} );

	$classes{Dict}->native_constructor( sub {
		my ( $runtime, $klass, $positional, $named, $file, $line ) = @_;
		my %map;
		for my $pair ( @{ $positional // [] } ) {
			my $normalized = $runtime->_normalize_pair_argument( $pair, $file, $line );
			my ( $k, $v ) = @{ $normalized };
			$map{$k} = $v;
		}
		if ( exists $named->{pairs} and blessed($named->{pairs}) and $named->{pairs}->isa('Zuzu::Value::Array') ) {
			for my $pair ( @{ $named->{pairs}->items } ) {
				my $normalized = $runtime->_normalize_pair_argument( $pair, $file, $line );
				my ( $k, $v ) = @{ $normalized };
				$map{$k} = $v;
			}
		}
		my $dict = Zuzu::Value::Dict->new( map => \%map );

		return $runtime->_wrap_builtin_if_needed( $klass, $dict, 'Dict' );
	} );

	$classes{PairList}->native_constructor( sub {
		my ( $runtime, $klass, $positional, $named, $file, $line ) = @_;
		my @list;
		for my $pair ( @{ $positional // [] } ) {
			my $normalized = $runtime->_normalize_pair_argument( $pair, $file, $line, 'PairList' );
			push @list, $normalized;
		}
		if ( exists $named->{list} and blessed($named->{list}) and $named->{list}->isa('Zuzu::Value::Array') ) {
			for my $pair ( @{ $named->{list}->items } ) {
				my $normalized = $runtime->_normalize_pair_argument( $pair, $file, $line, 'PairList' );
				push @list, $normalized;
			}
		}
		my $pairlist = Zuzu::Value::PairList->new( list => \@list );

		return $runtime->_wrap_builtin_if_needed( $klass, $pairlist, 'PairList' );
	} );

	$classes{Pair}->native_constructor( sub {
		my ( $runtime, $klass, $positional, $named ) = @_;
		my $pair = exists $named->{pair} ? $named->{pair} : $positional->[0];
		if ( blessed($pair) and $pair->isa('Zuzu::Value::Array') ) {
			$pair = [ @{ $pair->items } ];
		}
		if ( ref($pair) ne 'ARRAY' ) {
			$pair = [ undef, undef ];
		}
		my $pair_value = Zuzu::Value::Array->new( items => [ @{ $pair } ] );
		return $runtime->_instantiate_builtin_object(
			$klass,
			{
				pair => $pair_value,
			},
		);
	} );

	$classes{Pair}->methods->{key} = Zuzu::Value::Function->new(
		name => 'key',
		params => [],
		vararg => undef,
		body => undef,
		closure_env => undef,
	);
	$classes{Pair}->methods->{key}{_native} = sub {
		my ( $self_obj ) = @_;
		my $pair = $self_obj->slots->{pair};

		return undef if !blessed($pair) or !$pair->isa('Zuzu::Value::Array');
		return $pair->items->[0];
	};
	$classes{Pair}->methods->{key}{_owner_class} = $classes{Pair};
	$classes{Pair}->methods->{key}{_method_name} = 'key';
	$classes{Pair}->methods->{key}{_method_kind} = 'instance';

	$classes{Pair}->methods->{value} = Zuzu::Value::Function->new(
		name => 'value',
		params => [],
		vararg => undef,
		body => undef,
		closure_env => undef,
	);
	$classes{Pair}->methods->{value}{_native} = sub {
		my ( $self_obj ) = @_;
		my $pair = $self_obj->slots->{pair};

		return undef if !blessed($pair) or !$pair->isa('Zuzu::Value::Array');
		return $pair->items->[1];
	};
	$classes{Pair}->methods->{value}{_owner_class} = $classes{Pair};
	$classes{Pair}->methods->{value}{_method_name} = 'value';
	$classes{Pair}->methods->{value}{_method_kind} = 'instance';

	$self->{_builtin_classes} = \%classes;
	for my $name ( sort CORE::keys %classes ) {
		$self->{_global}->declare( $name, $classes{$name}, 1 );
		$self->{_builtin_global_names}{$name} = 1;
	}
}

# === AST evaluators ===

sub eval_program {
	my ($self, $node) = @_;

	my $v;
	for my $s (@{$node->statements}) { $v = $s->evaluate($self); }

	return $v;
}

sub eval_block {
	my ($self, $node) = @_;

	my $v;
	if ( $node->{reuse_current_env} ) {
		for ( @{ $node->{statements} } ) { $v = $_->evaluate($self); }
		return $v;
	}

	my $env = Zuzu::Env->_new_fast( $self->{_stack}[-1] ); # inlined $self->_env
	push @{$self->{_stack}}, $env; # inlined $self->_push_env
	eval {
		for ( @{ $node->{statements} } ) { $v = $_->evaluate($self); }
		1;
	} or do {
		my $e = $@;
		pop @{$self->{_stack}}; # inlined $self->_pop_env
		die $e;
	};
	pop @{$self->{_stack}}; # inlined $self->_pop_env

	return $v;
}

sub _new_task {
	my ( $self, %args ) = @_;

	my $task = Zuzu::Value::Task->new(
		name => $args{name} // '<task>',
		thunk => $args{thunk},
		status => $args{status} // 'pending',
		result => $args{result},
		error => $args{error},
		pid => $args{pid},
		reader => $args{reader},
		ready_at => $args{ready_at},
		poll_cb => $args{poll_cb},
		on_cancel => $args{on_cancel},
		cancel_reason => $args{cancel_reason},
		file => $args{file} // $self->{_native_call_file} // '<runtime>',
		line => $args{line} // $self->{_native_call_line} // 0,
		runtime_stack => [ @{ $args{runtime_stack} // $self->{_stack} } ],
	);
	my $scheduler = $self->{_scheduler};
	$task->scheduler($scheduler) if defined $scheduler and !$args{process};
	if ( defined $args{group} ) {
		$task->group( $args{group} );
	}
	elsif ( defined $scheduler ) {
		$task->group( $scheduler->current_group );
	}
	$task->start if $args{start};
	$scheduler->schedule( $task, $task->group )
		if defined $scheduler
		and !$args{process}
		and ( $args{schedule} or ( $task->status // '' ) eq 'pending' );

	return $task;
}

sub _warn_blocking_operation {
	my ( $self, $operation, $file, $line ) = @_;

	my $scheduler = $self->{_scheduler};
	return
		if !defined $scheduler
		or !defined $scheduler->current_task
		or $Zuzu::Runtime::DEBUG_LEVEL <= 0;
	$file //= $self->{_native_call_file} // '<runtime>';
	$line //= $self->{_native_call_line} // 0;
	my $record = $scheduler->trace_task(
		blocked_operation => $scheduler->current_task,
		{
			operation => $operation,
			file => $file,
			line => $line,
		},
	);
	warn "Blocking operation in async task: $operation at $file line $line\n"
		if $Zuzu::Runtime::DEBUG_LEVEL >= 2;

	return $record;
}

sub _task_exception {
	my ( $self, $class_name, $message, $file, $line ) = @_;

	my $class = $self->{_builtin_classes}{$class_name}
		// $self->{_builtin_classes}{Exception};
	return $self->_instantiate_builtin_object(
		$class,
		{
			message => $message,
			file => $file // '<std/task>',
			line => $line // 0,
		},
	);
}

sub _await_value {
	my ( $self, $value, $file, $line ) = @_;

	return $value->await
		if blessed($value) and $value->isa('Zuzu::Value::Task');

	die Zuzu::Error->new_runtime(
		message => 'await block must return a Task',
		file => $file,
		line => $line,
	);
}

sub eval_await {
	my ( $self, $node ) = @_;

	my $value = $node->block->evaluate($self);

	return $self->_await_value( $value, $node->file, $node->line );
}

sub eval_spawn {
	my ( $self, $node ) = @_;

	my $captured_env = $self->_capture_env( $self->_env );
	my $block = $node->block;
	my $scheduler = $self->{_scheduler};
	my $group = $scheduler
		? $scheduler->new_group( $scheduler->current_group )
		: undef;
	return $self->_new_task(
		name => '<spawn>',
		schedule => 1,
		group => $group,
		file => $node->file,
		line => $node->line,
		on_cancel => sub {
			my ( $task ) = @_;
			return if !defined $group;
			for my $child ( values %{ $group->tasks } ) {
				next if !defined $child or $child == $task;
				$child->cancel( $task->error )
					if $child->can('cancel') and !$child->is_done;
			}
		},
		thunk => sub {
			$self->_push_env($captured_env);
			my $ret;
			my $ok = eval {
				$ret = $block->evaluate($self);
				1;
			};
			my $err = $@ if !$ok;
			$self->_pop_env;
			if ( !$ok ) {
				if (
					ref($err)
					and ref($err) eq 'Zuzu::Control'
					and $err->{_control} eq 'return'
				) {
					return $err->{value};
				}
				die $err;
			}
			return $ret;
		},
	);
}

sub eval_let {
	my ($self, $node) = @_;

	my $val = defined($node->init) ? $node->init->evaluate($self) : undef;
	my $declared_type = $node->declared_type // 'Any';
	if ( defined $node->init ) {
		$self->_assert_declared_type( $declared_type, $val, $node->file, $node->line, $node->name )
			if !$node->{_skip_type_check};
	}
	my $ref = $self->{_stack}[-1]->declare( # inlined $self->_env
		$node->name,
		undef,
		$node->is_const ? 1 : 0,
		$declared_type,
		$node->is_weak_storage ? 1 : 0,
	);
	store_value( $ref, $val, $node->is_weak_storage ? 1 : 0 );

	return $val;
}

sub eval_let_unpack {
	my ( $self, $node ) = @_;

	my $source = $node->init->evaluate($self);
	my $dict = $self->_unwrap_builtin_collection( $source, 'Dict' );
	my $pairlist = $self->_unwrap_builtin_collection( $source, 'PairList' );
	if ( !$dict and !$pairlist ) {
		my $type = $self->_type_name($source);
		die Zuzu::Error->new_runtime(
			message => "Declaration unpacking expects Dict or PairList, got $type",
			file => $node->file,
			line => $node->line,
		);
	}

	my @resolved;
	for my $binding ( @{ $node->bindings // [] } ) {
		my $key = $binding->{key_expr}->evaluate($self);
		$key = defined($key) ? "$key" : '';
		my ( $present, $value );
		if ($dict) {
			$present = exists $dict->map->{$key} ? 1 : 0;
			$value = slot_value( \$dict->map->{$key} ) if $present;
		}
		else {
			$present = $pairlist->contains_key($key) ? 1 : 0;
			$value = $pairlist->get($key) if $present;
		}

		if ( !$present and $binding->{has_default} ) {
			$value = $binding->{default_expr}->evaluate($self);
		}
		elsif ( !$present ) {
			$value = undef;
		}

		my $declared_type = $binding->{declared_type} // 'Any';
		$self->_assert_declared_type(
			$declared_type,
			$value,
			$binding->{file} // $node->file,
			$binding->{line} // $node->line,
			$binding->{name},
		) if !$binding->{_skip_type_check};

		push @resolved, [ $binding, $value ];
	}

	for my $item ( @resolved ) {
		my ( $binding, $value ) = @{ $item };
		my $declared_type = $binding->{declared_type} // 'Any';
		my $is_weak_storage = $binding->{is_weak_storage} ? 1 : 0;
		my $ref = $self->_env->declare(
			$binding->{name},
			undef,
			$node->is_const ? 1 : 0,
			$declared_type,
			$is_weak_storage,
		);
		store_value( $ref, $value, $is_weak_storage );
	}

	return $source;
}

sub _target_declared_type {
	my ( $self, $target, $name ) = @_;

	return $target->{declared_type} if defined $target->{declared_type};
	return $target->{env}{types}{$name} // 'Any'
		if defined $name and defined $target->{env};
	return $self->_env->declared_type_for($name) if defined $name;

	return 'Any';
}

sub _target_weak_storage {
	my ( $self, $target, $node ) = @_;

	return 1 if $target->{weak_storage};
	return 1 if $node->is_weak_write;

	return 0;
}

sub _store_target_value {
	my ( $self, $target, $node, $value ) = @_;
	my $weak = $self->_target_weak_storage( $target, $node );

	if ( $target->{kind} && $target->{kind} eq 'array_index' ) {
		$target->{array}->weak->[ $target->{index} ] = $weak ? 1 : 0;
	}
	elsif ( $target->{kind} && $target->{kind} eq 'dict_key' ) {
		$target->{dict}->weak->{ $target->{dict_key} } = $weak ? 1 : 0;
	}

	return store_value( $target->{ref}, $value, $weak );
}

sub _is_path_lvalue_expr {
	my ( $self, $expr ) = @_;

	return 0 if !blessed($expr) or !$expr->isa('Zuzu::AST::Expr::Binary');
	return 1 if defined $expr->op and ( $expr->op eq '@' or $expr->op eq '@@' or $expr->op eq '@?' );
	return 0;
}

sub _assert_path_ref_value {
	my ( $self, $value, $file, $line, $context ) = @_;

	die Zuzu::Error->new_runtime(
		message => "Path object returned invalid reference for $context",
		file => $file,
		line => $line,
	) if !blessed($value) or !$value->isa('Zuzu::Value::Function');

	return $value;
}

sub _call_ref_closure_get {
	my ( $self, $ref_fn, $file, $line ) = @_;

	return $self->_call_function(
		$ref_fn,
		[],
		$EMPTY_HASH,
		$EMPTY_ARRAY,
		$file,
		$line,
	);
}

sub _call_ref_closure_set {
	my ( $self, $ref_fn, $value, $file, $line ) = @_;

	return $self->_call_function(
		$ref_fn,
		[ $value ],
		$EMPTY_HASH,
		$EMPTY_ARRAY,
		$file,
		$line,
	);
}

sub _make_path_replace_callback {
	my ( $self, $replace_expr ) = @_;

	my $captured_env = $self->_env;
	my $fn = Zuzu::Value::Function->new(
		name => '<path-regexp-replace>',
		params => [ 'm' ],
		vararg => undef,
		body => undef,
		closure_env => $captured_env,
	);
	$fn->{_native} = sub {
		my ( $match_value ) = @_;
		my $env = Zuzu::Env->_new_fast( $captured_env );
		$self->_push_env($env);
		$env->declare( 'm', $match_value, 1, 'Any' );
		my $value;
		my $ok = eval {
			$value = $replace_expr->evaluate($self);
			1;
		};
		my $err = $@;
		$self->_pop_env;
		die $err if !$ok;
		return $value;
	};

	return $fn;
}

sub _resolve_lvalue_target {
	my ($self, $expr) = @_;

	if (blessed($expr) and $expr->isa('Zuzu::AST::Expr::Var')) {
		my ( $ref, $env ) = $self->_var_ref_for_node($expr);
		die Zuzu::Error->new_runtime(message => "Undeclared variable '".$expr->name."'", file => $expr->file, line => $expr->line) if !$ref;

		return {
			kind => 'scalar_ref',
			ref => $ref,
			env => $env,
			name => $expr->name,
			weak_storage => defined $env
				? ( $env->{weak}{ $expr->name } ? 1 : 0 )
				: $self->_env->is_weak_slot($expr->name),
			file => $expr->file,
			line => $expr->line,
		};
	}
	if ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Index') ) {
		my $col = $expr->array->evaluate($self);
		my $idx = 0 + ($expr->index->evaluate($self) // 0);
		if ( blessed($col) and $col->isa('Zuzu::Value::Array') ) {
			$self->_assert_mutable_collection( $col, $expr->file, $expr->line );

			return {
				kind => 'array_index',
				array => $col,
				index => $idx,
				ref => \$col->items->[$idx],
				weak_storage => 0,
				file => $expr->file,
				line => $expr->line,
			};
		}
		if ( defined($col) and !ref($col) ) {
			my $target = $self->_resolve_lvalue_target( $expr->array );

			return {
				kind => 'string_index',
				string_ref => $target->{ref},
				name => $target->{name},
				env => $target->{env},
				target_expr => $expr,
				file => $expr->file,
				line => $expr->line,
			};
		}
		if ( blessed($col) and $col->isa('Zuzu::Value::BinaryString') ) {
			$self->_assert_mutable_collection( $col, $expr->file, $expr->line );

			return {
				kind => 'binary_string_index',
				binary_string => $col,
				target_expr => $expr,
				file => $expr->file,
				line => $expr->line,
			};
		}
		die Zuzu::Error->new_runtime(message => "Index assignment expects Array, String, or BinaryString", file => $expr->file, line => $expr->line);
	}
	if ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::DictGet') ) {
		my $dict = $expr->dict->evaluate($self);
		my $key = $expr->key->evaluate($self);
		$key = defined($key) ? "$key" : '';
		if ( blessed($dict) and $dict->isa('Zuzu::Value::Dict') ) {
			$self->_assert_mutable_collection( $dict, $expr->file, $expr->line );

			return {
				kind => 'dict_key',
				dict => $dict,
				dict_key => $key,
				ref => \$dict->map->{ $key },
				weak_storage => 0,
				file => $expr->file,
				line => $expr->line,
			};
		}
		if ( blessed($dict) and $dict->isa('Zuzu::Value::PairList') ) {
			$self->_assert_mutable_collection( $dict, $expr->file, $expr->line );

			return {
				kind => 'pairlist',
				pairlist => $dict,
				pairlist_key => $key,
				file => $expr->file,
				line => $expr->line,
			};
		}
		if ( blessed($dict) and $dict->isa('Zuzu::Value::Object') ) {
			die Zuzu::Error->new_runtime(
				message => "Object assignment expects existing field '$key'",
				file => $expr->file,
				line => $expr->line,
			) if !exists $dict->slots->{$key};

			return {
				kind => 'scalar_ref',
				ref => \$dict->slots->{$key},
				weak_storage => $dict->weak->{$key} ? 1 : 0,
				const => $dict->const->{$key} ? 1 : 0,
				declared_type => $dict->types->{$key} // 'Any',
				file => $expr->file,
				line => $expr->line,
			};
		}
		die Zuzu::Error->new_runtime(message => "Dict assignment expects Dict", file => $expr->file, line => $expr->line);
	}
	if ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Slice') ) {
		my $col = $expr->collection->evaluate($self);
		if ( blessed($col) and $col->isa('Zuzu::Value::Array') ) {
			$self->_assert_mutable_collection( $col, $expr->file, $expr->line );

			return {
				kind => 'slice',
				slice_col => $col,
				target_expr => $expr,
				file => $expr->file,
				line => $expr->line,
			};
		}
		if ( defined($col) and !ref($col) ) {
			my $target = $self->_resolve_lvalue_target( $expr->collection );

			return {
				kind => 'string_slice',
				string_ref => $target->{ref},
				name => $target->{name},
				env => $target->{env},
				target_expr => $expr,
				file => $expr->file,
				line => $expr->line,
			};
		}
		if ( blessed($col) and $col->isa('Zuzu::Value::BinaryString') ) {
			$self->_assert_mutable_collection( $col, $expr->file, $expr->line );

			return {
				kind => 'binary_string_slice',
				binary_string => $col,
				target_expr => $expr,
				file => $expr->file,
				line => $expr->line,
			};
		}
		die Zuzu::Error->new_runtime(message => "Slice assignment expects Array, String, or BinaryString", file => $expr->file, line => $expr->line);
	}
	if ( $self->_is_path_lvalue_expr($expr) ) {
		my $file = $expr->file;
		my $line = $expr->line;
		my $root_value = $expr->left->evaluate($self);
		my $path_value = $expr->right->evaluate($self);
		my $path_obj = $self->_coerce_path_operand( $path_value, $file, $line );

		if ( $expr->op eq '@@' ) {
			my $refs = $self->_call_path_method(
				$path_obj,
				'ref_all',
				[ $root_value ],
				$file,
				$line,
			);
			die Zuzu::Error->new_runtime(
				message => "Path object returned invalid multi-reference result for \@\@ target",
				file => $file,
				line => $line,
			) if !blessed($refs) or !$refs->isa('Zuzu::Value::Array');
			for my $item ( @{ $refs->items } ) {
				$self->_assert_path_ref_value( $item, $file, $line, '@@ target' );
			}
			return {
				kind => 'path_multi_ref',
				refs => $refs,
				file => $file,
				line => $line,
			};
		}

		my $method_name = $expr->op eq '@' ? 'ref_first' : 'ref_maybe';
		my $ref_fn = $self->_call_path_method(
			$path_obj,
			$method_name,
			[ $root_value ],
			$file,
			$line,
		);
		if ( $expr->op eq '@?' and !defined $ref_fn ) {
			return {
				kind => 'path_maybe_ref',
				matched => 0,
				file => $file,
				line => $line,
			};
		}
		$self->_assert_path_ref_value( $ref_fn, $file, $line, $expr->op . ' target' );
		return {
			kind => $expr->op eq '@?' ? 'path_maybe_ref' : 'path_single_ref',
			matched => 1,
			ref_fn => $ref_fn,
			file => $file,
			line => $line,
		};
	}
	die Zuzu::Error->new_runtime(message => "Invalid assignment target", file => $expr->file, line => $expr->line);
}

sub eval_assign {
	my ($self, $node) = @_;

	if ( $self->_is_path_lvalue_expr( $node->target ) ) {
		return $self->_eval_path_assignment($node);
	}

	my $target = $self->_resolve_lvalue_target($node->target);
	my (
		$ref, $name, $target_env, $file, $line, $slice_col, $string_ref,
		$string_index, $binary_string, $binary_string_index, $pairlist,
		$pairlist_key
	)
		= (
			$target->{ref},
			$target->{name},
			$target->{env},
			$target->{file},
			$target->{line},
			$target->{slice_col},
			$target->{string_ref},
			$target->{kind} && $target->{kind} eq 'string_index',
			$target->{binary_string},
			$target->{kind} && $target->{kind} eq 'binary_string_index',
			$target->{pairlist},
			$target->{pairlist_key},
		);
	die Zuzu::Error->new_runtime(
		message => "Cannot assign to const field",
		file => $file,
		line => $line,
	) if $target->{const};

	if ( defined $name ) {
		my $const_here = defined $target_env
			? $target_env->{const}{$name}
			: $self->_env->is_const_here($name);
		if (!defined $const_here and !defined $target_env) {
			# const could be in parent; find by walking
			my $env = $self->_env;
			while ($env) {
				if (exists $env->{slots}{$name}) { $const_here = $env->{const}{$name}; last; }
				$env = $env->{parent};
			}
		}
		die Zuzu::Error->new_runtime(message => "Cannot assign to const '$name'", file => $file, line => $line) if $const_here;
	}

	my $rhs;
	if ( $node->op ne '~=' ) {
		$rhs = $node->expr->evaluate($self);
	}
	if ( $pairlist ) {
		$pairlist->_append(
			$pairlist_key,
			$rhs,
			$node->is_weak_write ? 1 : 0,
		);

		return $rhs;
	}
	if ( $slice_col ) {
		my $start = defined $node->target->start ? 0 + ($node->target->start->evaluate($self) // 0) : 0;
		my $len;
		if ( defined $node->target->length ) {
			$len = 0 + ($node->target->length->evaluate($self) // 0);
		}
		else {
			$len = scalar(@{ $slice_col->items }) - $start;
		}
		die Zuzu::Error->new_runtime(message => "Slice assignment RHS must be Array", file => $file, line => $line)
			if !blessed($rhs) or !$rhs->isa('Zuzu::Value::Array');
		splice @{ $slice_col->items }, $start, $len, @{ $rhs->items };

		return $slice_col;
	}
	if ( $string_ref ) {
		return $string_index
			? $self->_assign_string_index(
				$string_ref,
				$node->target,
				$rhs,
				$name,
				$target_env,
				$file,
				$line,
			)
			: $self->_assign_string_slice(
				$string_ref,
				$node->target,
				$rhs,
				$name,
				$target_env,
				$file,
				$line,
			);
	}
	if ( $binary_string ) {
		return $binary_string_index
			? $self->_assign_binary_string_index(
				$binary_string,
				$node->target,
				$rhs,
				$file,
				$line,
			)
			: $self->_assign_binary_string_slice(
				$binary_string,
				$node->target,
				$rhs,
				$file,
				$line,
			);
	}

	my $op = $node->op;
	if ($op eq ':=') {
		my $declared_type = $self->_target_declared_type( $target, $name );
		$self->_assert_declared_type( $declared_type, $rhs, $file, $line, $name )
			if !$node->{_skip_type_check};
		$self->_store_target_value( $target, $node, $rhs );
	} elsif ($op eq '+=') {
		my $new_value = $self->_to_Number($$ref) + $self->_to_Number($rhs);
		my $declared_type = $self->_target_declared_type( $target, $name );
		$self->_assert_declared_type( $declared_type, $new_value, $file, $line, $name );
		$self->_store_target_value( $target, $node, $new_value );
	} elsif ($op eq '-=') {
		my $new_value = $self->_to_Number($$ref) - $self->_to_Number($rhs);
		my $declared_type = $self->_target_declared_type( $target, $name );
		$self->_assert_declared_type( $declared_type, $new_value, $file, $line, $name );
		$self->_store_target_value( $target, $node, $new_value );
	} elsif ($op eq '*=') {
		my $new_value = $self->_to_Number($$ref) * $self->_to_Number($rhs);
		my $declared_type = $self->_target_declared_type( $target, $name );
		$self->_assert_declared_type( $declared_type, $new_value, $file, $line, $name );
		$self->_store_target_value( $target, $node, $new_value );
	} elsif ($op eq '×=') {
		my $new_value = $self->_to_Number($$ref) * $self->_to_Number($rhs);
		my $declared_type = $self->_target_declared_type( $target, $name );
		$self->_assert_declared_type( $declared_type, $new_value, $file, $line, $name );
		$self->_store_target_value( $target, $node, $new_value );
	} elsif ($op eq '/=') {
		my $new_value = $self->_to_Number($$ref) / $self->_to_Number($rhs);
		my $declared_type = $self->_target_declared_type( $target, $name );
		$self->_assert_declared_type( $declared_type, $new_value, $file, $line, $name );
		$self->_store_target_value( $target, $node, $new_value );
	} elsif ($op eq '÷=') {
		my $new_value = $self->_to_Number($$ref) / $self->_to_Number($rhs);
		my $declared_type = $self->_target_declared_type( $target, $name );
		$self->_assert_declared_type( $declared_type, $new_value, $file, $line, $name );
		$self->_store_target_value( $target, $node, $new_value );
	} elsif ($op eq '**=') {
		my $new_value = $self->_to_Number($$ref) ** $self->_to_Number($rhs);
		my $declared_type = $self->_target_declared_type( $target, $name );
		$self->_assert_declared_type( $declared_type, $new_value, $file, $line, $name );
		$self->_store_target_value( $target, $node, $new_value );
	} elsif ($op eq '_=') {
		my $new_value = $self->_to_OperatorString( $$ref, $file, $line )
			. $self->_to_OperatorString( $rhs, $file, $line );
		my $declared_type = $self->_target_declared_type( $target, $name );
		$self->_assert_declared_type( $declared_type, $new_value, $file, $line, $name );
		$self->_store_target_value( $target, $node, $new_value );
	} elsif ($op eq '?:=') {
		my $new_value = (defined($$ref) ? $$ref : $rhs);
		my $declared_type = $self->_target_declared_type( $target, $name );
		$self->_assert_declared_type( $declared_type, $new_value, $file, $line, $name );
		$self->_store_target_value( $target, $node, $new_value );
	} elsif ( $op eq '~=' ) {
		my $target_text = $self->_to_OperatorString( $$ref, $file, $line );
		my $match_value = $node->match_expr->evaluate($self);
		my $regex = $self->_coerce_regexp( $match_value, $file, $line );
		my $global = $self->_regexp_is_global($match_value);
		my $new_value = $self->_regexp_replace_value(
			$target_text,
			$regex,
			$global,
			$node->replace_expr,
		);
		my $declared_type = $self->_target_declared_type( $target, $name );
		$self->_assert_declared_type( $declared_type, $new_value, $file, $line, $name );
		$self->_store_target_value( $target, $node, $new_value );
	} else {
		die Zuzu::Error->new_runtime(message => "Unsupported assignment operator '$op'", file => $file, line => $line);
	}

	return $$ref;
}

sub _assign_string_slice {
	my ( $self, $string_ref, $target, $value, $name, $target_env, $file, $line ) = @_;

	my $start = defined $target->start
		? 0 + ( $target->start->evaluate($self) // 0 )
		: 0;
	my $current = defined $$string_ref ? "$$string_ref" : '';
	my $size = length($current);
	$start += $size if $start < 0;
	$start = 0 if $start < 0;
	$start = $size if $start > $size;
	my $len = defined $target->length
		? 0 + ( $target->length->evaluate($self) // 0 )
		: $size - $start;
	my $replacement = $self->_to_String($value);
	substr( $current, $start, $len ) = $replacement;
	my $declared_type = defined $name
		? (
			defined $target_env
			? ( $target_env->{types}{$name} // 'Any' )
			: $self->_env->declared_type_for($name)
		)
		: 'Any';
	$self->_assert_declared_type(
		$declared_type,
		$current,
		$file,
		$line,
		$name,
	);
	$$string_ref = $current;

	return $current;
}

sub _assign_string_index {
	my ( $self, $string_ref, $target, $value, $name, $target_env, $file, $line ) = @_;

	my $current = defined $$string_ref ? "$$string_ref" : '';
	my $size = length($current);
	my $idx = 0 + ( $target->index->evaluate($self) // 0 );
	$idx += $size if $idx < 0;
	$idx = 0 if $idx < 0;
	$idx = $size if $idx > $size;
	my $replacement = $self->_to_String($value);
	substr( $current, $idx, 1 ) = $replacement;
	my $declared_type = defined $name
		? (
			defined $target_env
			? ( $target_env->{types}{$name} // 'Any' )
			: $self->_env->declared_type_for($name)
		)
		: 'Any';
	$self->_assert_declared_type(
		$declared_type,
		$current,
		$file,
		$line,
		$name,
	);
	$$string_ref = $current;

	return $current;
}

sub _assign_binary_string_slice {
	my ( $self, $binary, $target, $value, $file, $line ) = @_;

	die Zuzu::Error->new_runtime(
		message => "BinaryString slice assignment RHS must be BinaryString",
		file => $file,
		line => $line,
	) if !blessed($value) or !$value->isa('Zuzu::Value::BinaryString');

	my $start = defined $target->start
		? 0 + ( $target->start->evaluate($self) // 0 )
		: 0;
	my $current = $binary->bytes // '';
	my $size = length($current);
	$start += $size if $start < 0;
	$start = 0 if $start < 0;
	$start = $size if $start > $size;
	my $len = defined $target->length
		? 0 + ( $target->length->evaluate($self) // 0 )
		: $size - $start;
	$len = 0 if $len < 0;
	substr( $current, $start, $len ) = $value->bytes // '';
	$binary->bytes($current);

	return $binary;
}

sub _assign_binary_string_index {
	my ( $self, $binary, $target, $value, $file, $line ) = @_;

	die Zuzu::Error->new_runtime(
		message => "BinaryString index assignment RHS must be BinaryString",
		file => $file,
		line => $line,
	) if !blessed($value) or !$value->isa('Zuzu::Value::BinaryString');

	my $current = $binary->bytes // '';
	my $size = length($current);
	my $idx = 0 + ( $target->index->evaluate($self) // 0 );
	$idx += $size if $idx < 0;
	$idx = 0 if $idx < 0;
	$idx = $size if $idx > $size;
	substr( $current, $idx, 1 ) = $value->bytes // '';
	$binary->bytes($current);

	return $binary;
}

sub _eval_path_assignment {
	my ( $self, $node ) = @_;

	my $target = $node->target;
	my $file = $target->file;
	my $line = $target->line;
	my $op = $node->op;
	my $path_op = $target->op;
	my $root_value = $target->left->evaluate($self);
	my $path_value = $target->right->evaluate($self);
	my $path_obj = $self->_coerce_path_operand( $path_value, $file, $line );
	my $rhs = $op eq '~='
		? Zuzu::Value::Array->new(
			items => [
				$node->match_expr->evaluate($self),
				$self->_make_path_replace_callback( $node->replace_expr ),
			],
		)
		: $node->expr->evaluate($self);
	my $method_name
		= $path_op eq '@'  ? 'assign_first'
		: $path_op eq '@@' ? 'assign_all'
		:                    'assign_maybe';

	return $self->_call_path_method(
		$path_obj,
		$method_name,
		[ $root_value, $rhs, $op, $node->is_weak_write ? 1 : 0 ],
		$file,
		$line,
	);
}

sub eval_if {
	my ($self, $node) = @_;

	my $c = $node->cond->evaluate($self);
	if ( $self->_to_Boolean($c) ) {

		return $node->then_block->evaluate($self);
	}
	if ($node->else_branch) {

		return $node->else_branch->evaluate($self);
	}

	return undef;
}

sub eval_while {
	my ($self, $node) = @_;

	my $v;
	while ( $self->_to_Boolean( $node->cond->evaluate($self) ) ) {
		eval { $v = $node->body->evaluate($self); 1 } or do {
			my $e = $@;
			if (ref($e) && $e->{_control} && $e->{_control} eq 'next') { next; }
			if (ref($e) && $e->{_control} && $e->{_control} eq 'last') { last; }
			die $e;
		};
	}

	return $v;
}

sub eval_for {
	my ($self, $node) = @_;

	my $col = $node->collection->evaluate($self);
	my $iter_fn;

	my @items;
	if (blessed($col) and $col->isa('Zuzu::Value::Array')) {
		@items = $col->resolved_items;
	} elsif (blessed($col) and $col->isa('Zuzu::Value::Dict')) {
		@items = sort keys %{$col->map};
	} elsif (blessed($col) and $col->isa('Zuzu::Value::PairList')) {
		@items = map { $_->[0] } @{ $col->list };
	} elsif (blessed($col) and $col->isa('Zuzu::Value::Set')) {
		@items = $col->resolved_items;
	} elsif (blessed($col) and $col->isa('Zuzu::Value::Bag')) {
		@items = $col->resolved_items;
	} elsif ( blessed($col) and $col->isa('Zuzu::Value::Function') ) {
		$iter_fn = $col;
	} elsif ( blessed($col) and $col->isa('Zuzu::Value::Object') ) {
		my $to_iterator = $self->_lookup_method( $col->class, 'to_Iterator', 0 );
		if ( $to_iterator ) {
			my $iter = $self->_call_method(
				$to_iterator,
				$col,
				[],
				{},
				[],
				$node->file,
				$node->line,
			);
			die Zuzu::Error->new_runtime(
				message => "for(...) to_Iterator must return a Function",
				file => $node->file,
				line => $node->line,
			) if !blessed($iter) or !$iter->isa('Zuzu::Value::Function');
			$iter_fn = $iter;
		} else {
			my $to_array = $self->_lookup_method( $col->class, 'to_Array', 0 );
			if ( $to_array ) {
				my $array = $self->_call_method(
					$to_array,
					$col,
					[],
					{},
					[],
					$node->file,
					$node->line,
				);
				my $array_like = $self->_unwrap_builtin_collection( $array, 'Array' );
				die Zuzu::Error->new_runtime(
					message => "for(...) to_Array must return an Array",
					file => $node->file,
					line => $node->line,
				) if !$array_like;
				@items = $array_like->resolved_items;
			}
		}
	} elsif ( blessed($col) and $col->isa('Zuzu::Value::BinaryString') ) {
		# Iterate byte-by-byte, each as a 1-byte BinaryString.
		@items = map {
			Zuzu::Value::BinaryString->new( bytes => $_ )
		} split //, ( $col->bytes // '' );
	} elsif ( !ref($col) and defined($col) and Zuzu::Value::Equality::equality_type($col) eq 'String' ) {
		# Iterate character-by-character, each as a 1-char String.
		@items = split //, $col;
	} else {
		die Zuzu::Error->new_runtime(message => "for(...) expects Array, Dict, PairList, Set, Bag, Function, String, BinaryString, or convertible Object", file => $node->file, line => $node->line);
	}

	if ( !@items and !defined $iter_fn ) {

		return $node->else_block ? $node->else_block->evaluate($self) : undef;
	}

	my $v;
	my $has_any = 0;
	my $run_body = sub {
		my ( $it ) = @_;

		my $using_inner_loop_scope = $node->declare_loop_var ? 1 : 0;
		if ($using_inner_loop_scope) {
			my $env = Zuzu::Env->_new_fast( $self->{_stack}[-1] ); # inlined $self->_env
			push @{$self->{_stack}}, $env; # inlined $self->_push_env
			my $const_flag = ( defined $node->loop_var_kind and $node->loop_var_kind eq 'const' ) ? 1 : 0;
			$env->declare($node->var, $it, $const_flag);
		}
		else {
			my $ref = $self->_env->find_ref($node->var);
			die Zuzu::Error->new_runtime(
				message => "Use of undeclared variable '".$node->var."'",
				file => $node->file,
				line => $node->line,
			) if !defined $ref;

			my $const_here = $self->_env->is_const_here($node->var);
			if (!defined $const_here) {
				my $env = $self->_env;
				while ($env) {
					if (exists $env->{slots}{ $node->var }) { $const_here = $env->{const}{ $node->var }; last; }
					$env = $env->{parent};
				}
			}
			die Zuzu::Error->new_runtime(
				message => "Cannot assign to const '".$node->var."'",
				file => $node->file,
				line => $node->line,
			) if $const_here;

			my $declared_type = $self->_env->declared_type_for($node->var);
			$self->_assert_declared_type( $declared_type, $it, $node->file, $node->line, $node->var );
			$$ref = $it;
		}

		eval { $v = $node->body->evaluate($self); 1 } or do {
			my $e = $@;
			pop @{$self->{_stack}} if $using_inner_loop_scope; # inlined $self->_pop_env
			return 'next' if ref($e) and $e->{_control} and $e->{_control} eq 'next';
			return 'last' if ref($e) and $e->{_control} and $e->{_control} eq 'last';
			die $e;
		};

		pop @{$self->{_stack}} if $using_inner_loop_scope; # inlined $self->_pop_env
		return 'ok';
	};

	if ( defined $iter_fn ) {
		my $exhausted_class = $self->{_builtin_classes}{ExhaustedException};
		while (1) {
			my $next_item;
			eval {
				$next_item = $self->_call_function(
					$iter_fn,
					[],
					{},
					[],
					$node->file,
					$node->line,
				);
				1;
			} or do {
				my $e = $@;
				if ( ref($e) and $e->{_zuzu_throw} ) {
					my $thrown = $e->{value};
					if ( defined $exhausted_class and $self->_value_matches_class( $thrown, $exhausted_class ) ) {
						last;
					}
				}
				die $e;
			};
			$has_any = 1;
			my $control = $run_body->( $next_item );
			next if $control eq 'next';
			last if $control eq 'last';
		}
	} else {
		for my $it (@items) {
			$has_any = 1;
			my $control = $run_body->($it);
			next if $control eq 'next';
			last if $control eq 'last';
		}
	}

	if ( !$has_any ) {
		return $node->else_block ? $node->else_block->evaluate($self) : undef;
	}

	return $v;
}

sub eval_switch {
	my ( $self, $node ) = @_;

	my $value = $node->value_expr->evaluate($self);
	my $matched = 0;
	my $fell_through = 0;
	my $result;
	my $cases = $node->cases // [];
	my $dispatch = $self->_switch_dispatch_table( $node, $cases, $value );
	if ( $dispatch and exists $dispatch->{case_index} ) {
		my $start_index = $dispatch->{case_index};
		for my $case ( @{$cases}[ $start_index .. $#$cases ] ) {
			$fell_through = 0;

			eval {
				$result = $case->{body}->evaluate($self);
				1;
			} or do {
				my $e = $@;
				if ( ref($e) and $e->{_control} and $e->{_control} eq 'continue' ) {
					$fell_through = 1;
					next;
				}
				die $e;
			};

			return $result if !$fell_through;
		}
		if ( defined $node->default_block ) {
			eval {
				$result = $node->default_block->evaluate($self);
				1;
			} or do {
				my $e = $@;
				if ( ref($e) and $e->{_control} and $e->{_control} eq 'continue' ) {
					return $result;
				}
				die $e;
			};
		}
		return $result;
	}
	if ( $dispatch and $dispatch->{eligible} and defined $node->default_block ) {
		eval {
			$result = $node->default_block->evaluate($self);
			1;
		} or do {
			my $e = $@;
			if ( ref($e) and $e->{_control} and $e->{_control} eq 'continue' ) {
				return $result;
			}
			die $e;
		};
		return $result;
	}

	CASE:
	for my $case ( @$cases ) {
		if ( !$matched ) {
			for my $case_value ( @{ $case->{values} // [] } ) {
				my $operator = $node->comparator;
				my $candidate_expr = $case_value;
				if ( ref($case_value) eq 'HASH' ) {
					$operator = $case_value->{operator} // $operator;
					$candidate_expr = $case_value->{value};
				}
				my $candidate = $candidate_expr->evaluate($self);
				if ( $self->_switch_matches( $operator, $value, $candidate, $node->file, $node->line ) ) {
					$matched = 1;
					last;
				}
			}
		}

		next if !$matched;
		$fell_through = 0;

		eval {
			$result = $case->{body}->evaluate($self);
			1;
		} or do {
			my $e = $@;
			if ( ref($e) and $e->{_control} and $e->{_control} eq 'continue' ) {
				$fell_through = 1;
				next CASE;
			}
			die $e;
		};

		last CASE;
	}

	if ( ( !$matched or $fell_through ) and defined $node->default_block ) {
		eval {
			$result = $node->default_block->evaluate($self);
			1;
		} or do {
			my $e = $@;
			if ( ref($e) and $e->{_control} and $e->{_control} eq 'continue' ) {
				return $result;
			}
			die $e;
		};
	}

	return $result;
}

sub _switch_dispatch_table {
	my ( $self, $node, $cases, $value ) = @_;

	my $header_operator = $node->comparator // '==';
	my %entries;
	my $eligible = 0;
	my $common_operator;
	for my $case_index ( 0 .. $#$cases ) {
		my $case = $cases->[$case_index];
		for my $case_value ( @{ $case->{values} // [] } ) {
			my $operator = $header_operator;
			my $candidate_expr = $case_value;
			if ( ref($case_value) eq 'HASH' ) {
				$operator = $case_value->{operator} // $operator;
				$candidate_expr = $case_value->{value};
			}
			return if $operator ne 'eq' and $operator ne 'eqi' and $operator ne '=';
			$common_operator //= $operator;
			return if $operator ne $common_operator;
			return if !blessed($candidate_expr) or !$candidate_expr->isa('Zuzu::AST::Expr::Literal');
			my $key = $self->_switch_dispatch_key_for_literal( $operator, $candidate_expr->value );
			return if !defined $key;
			return if exists $entries{$key};
			$entries{$key} = $case_index;
			$eligible = 1;
		}
	}
	return if !$eligible;
	my $subject_key = $self->_switch_dispatch_key_for_value( $common_operator, $value );
	return { eligible => 1 } if !defined $subject_key;
	return {
		eligible => 1,
		( exists $entries{$subject_key} ? ( case_index => $entries{$subject_key} ) : () ),
	};
}

sub _switch_dispatch_key_for_literal {
	my ( $self, $operator, $value ) = @_;

	return 'q:' . $value if $operator eq 'eq';
	return 'qi:' . CORE::fc($value) if $operator eq 'eqi';
	if ( $operator eq '=' ) {
		return if !defined $value or $value !~ /\A-?\d+\z/;
		return 'i:' . ( 0 + $value );
	}
	return;
}

sub _switch_dispatch_key_for_value {
	my ( $self, $operator, $value ) = @_;

	return 'q:' . $self->_to_OperatorString($value) if $operator eq 'eq';
	return 'qi:' . CORE::fc( $self->_to_OperatorString($value) ) if $operator eq 'eqi';
	if ( $operator eq '=' ) {
		my $number = $self->_to_Number($value);
		return if $number != int($number);
		return 'i:' . int($number);
	}
	return;
}

sub eval_function_def {
	my ($self, $node) = @_;

	my $ref = $self->_env->find_ref($node->name);
	if ( $node->is_predeclared ) {
		if (!$ref) {
			$self->_env->declare(
				$node->name,
				Zuzu::Value::Function->new(
					name => $node->name,
					params => [],
					return_type => 'Any',
					closure_env => $self->_capture_env( $self->_env ),
					is_bodyless => 1,
					source_node => $node,
				),
				1,
			);
			return ${ $self->_env->find_ref($node->name) };
		}
		die Zuzu::Error->new_runtime(
			message => "Redeclaration of '".$node->name."' in the same scope",
			file => $node->file,
			line => $node->line,
		);
	}
	if (!$ref) {
		$self->_env->declare($node->name, undef, 1);
		$ref = $self->_env->find_ref($node->name);
	}

	my $fn = Zuzu::Value::Function->new(
		name => $node->name,
		params => $node->params,
		vararg => $node->vararg,
		named_vararg => $node->named_vararg,
		param_types => { %{ $node->param_types // {} } },
		vararg_type => $node->vararg_type // 'Any',
		named_vararg_type => $node->named_vararg_type // 'PairList',
		param_optional => { %{ $node->param_optional // {} } },
		param_defaults => { %{ $node->param_defaults // {} } },
		return_type => $node->return_type // 'Any',
		body => $node->body,
		closure_env => $self->_capture_env( $self->_env ),
		is_async => $node->is_async ? 1 : 0,
		source_node => $node,
	);
	$fn->{_default_typecheck_safe} = { %{ $node->{_default_typecheck_safe} // {} } };
	if (
		defined $$ref
		and blessed($$ref)
		and $$ref->isa('Zuzu::Value::Function')
		and $$ref->is_bodyless
	) {
		$self->_complete_bodyless_function( $$ref, $fn );
		return $$ref;
	}
	$$ref = $fn;

	return $fn;
}

sub _complete_bodyless_function {
	my ( $self, $target, $source ) = @_;

	for my $field (
		qw(
			params vararg named_vararg param_types vararg_type named_vararg_type
			param_optional param_defaults return_type body closure_env is_async
			source_node
		)
	) {
		$target->$field( $source->$field );
	}
	$target->is_bodyless(0);
	$target->{_default_typecheck_safe} = { %{ $source->{_default_typecheck_safe} // {} } };
	for my $key (
		qw(
			_owner_class _method_name _method_kind _method_source _uses_super
		)
	) {
		$target->{$key} = $source->{$key} if exists $source->{$key};
	}

	return $target;
}

sub _function_from_method_decl {
	my ( $self, $m, $closure_env ) = @_;

	my $fn = Zuzu::Value::Function->new(
		name => $m->name,
		params => [ @{ $m->params // [] } ],
		vararg => $m->vararg,
		named_vararg => $m->named_vararg,
		param_types => { %{ $m->param_types // {} } },
		vararg_type => $m->vararg_type // 'Any',
		named_vararg_type => $m->named_vararg_type // 'PairList',
		param_optional => { %{ $m->param_optional // {} } },
		param_defaults => { %{ $m->param_defaults // {} } },
		return_type => $m->return_type // 'Any',
		body => $m->body,
		closure_env => $closure_env,
		is_async => $m->is_async ? 1 : 0,
		is_bodyless => $m->is_predeclared ? 1 : 0,
		source_node => $m,
	);
	$fn->{_default_typecheck_safe} = { %{ $m->{_default_typecheck_safe} // {} } };

	return $fn;
}

sub _install_method_function {
	my ( $self, $table, $m, $fn ) = @_;

	if ( exists $table->{ $m->name } ) {
		my $existing = $table->{ $m->name };
		if ( $m->is_predeclared or !$existing->is_bodyless ) {
			die Zuzu::Error->new_runtime(
				message => "Redeclaration of '".$m->name."' in the same scope",
				file => $m->file,
				line => $m->line,
			);
		}
		$self->_complete_bodyless_function( $existing, $fn );
		return $existing;
	}

	$table->{ $m->name } = $fn;
	return $fn;
}

sub eval_function_expr {
	my ($self, $node) = @_;

	my $fn = Zuzu::Value::Function->new(
		name => '<anon>',
		params => [ @{ $node->params // [] } ],
		vararg => $node->vararg,
		named_vararg => $node->named_vararg,
		param_types => { %{ $node->param_types // {} } },
		vararg_type => $node->vararg_type // 'Any',
		named_vararg_type => $node->named_vararg_type // 'PairList',
		param_optional => { %{ $node->param_optional // {} } },
		param_defaults => { %{ $node->param_defaults // {} } },
		return_type => $node->return_type // 'Any',
		body => $node->body,
		closure_env => $self->_capture_env( $self->{_stack}[-1] ), # inlined $self->_env
		is_async => $node->is_async ? 1 : 0,
		source_node => $node,
	);
	$fn->{_default_typecheck_safe} = { %{ $node->{_default_typecheck_safe} // {} } };

	return $fn;
}

sub _install_trait_methods_for_class {
	my ( $self, $klass, $traits ) = @_;

	for my $trait ( @{ $traits // [] } ) {
		for my $mname ( sort keys %{ $trait->methods // {} } ) {
			my $source_method = $trait->methods->{ $mname };
			my $trait_method = Zuzu::Value::Function->new(
				name => $source_method->name,
				params => [ @{ $source_method->params // [] } ],
				vararg => $source_method->vararg,
				named_vararg => $source_method->named_vararg,
				param_types => { %{ $source_method->param_types // {} } },
				vararg_type => $source_method->vararg_type // 'Any',
				named_vararg_type => $source_method->named_vararg_type // 'PairList',
				param_optional => { %{ $source_method->param_optional // {} } },
				param_defaults => { %{ $source_method->param_defaults // {} } },
				return_type => $source_method->return_type // 'Any',
				body => $source_method->body,
				closure_env => $source_method->closure_env,
				is_async => $source_method->is_async ? 1 : 0,
			);
			$trait_method->{_default_typecheck_safe} = { %{ $source_method->{_default_typecheck_safe} // {} } };
			$trait_method->{_owner_class} = $klass;
			$trait_method->{_method_name} = $mname;
			$trait_method->{_method_kind} = 'instance';
			$trait_method->{_method_source} = 'trait';
			$trait_method->{_uses_super} = $source_method->{_uses_super};
			push @{ $klass->trait_methods->{ $mname } }, $trait_method;
		}
	}

	return;
}

sub eval_class_def {
	my ($self, $node) = @_;

	my $parent;
	if ( defined $node->parent ) {
		$parent = $node->parent->evaluate($self);
		die Zuzu::Error->new_runtime(message => "Parent type is not a Class", file => $node->file, line => $node->line)
			if !blessed($parent) or !$parent->isa('Zuzu::Value::Class');
	}
	else {
		$parent = $self->{_builtin_classes}{Object};
	}
	my @traits;
	for my $tref ( @{ $node->traits // [] } ) {
		my $trait = $tref->evaluate($self);
		die Zuzu::Error->new_runtime(message => "Composed type is not a Trait", file => $node->file, line => $node->line)
			if !blessed($trait) or !$trait->isa('Zuzu::Value::Trait');
		push @traits, $trait;
	}

	my $klass = Zuzu::Value::Class->new(
		name => $node->name,
		parent => $parent,
		traits => \@traits,
		field_specs => [ @{ $node->fields // [] } ],
		methods => {},
		trait_methods => {},
		static_methods => {},
		nested_classes => {},
		closure_env => undef,
		source_node => $node,
	);

	for my $m (@{ $node->methods // [] }) {
		my $method_fn = $self->_function_from_method_decl( $m, $self->_env );
		$method_fn->{_owner_class} = $klass;
		$method_fn->{_method_name} = $m->name;
		$method_fn->{_method_kind} = 'instance';
		$method_fn->{_method_source} = 'class';
		$method_fn->{_uses_super} = $m->uses_super;
		$self->_install_method_function( $klass->methods, $m, $method_fn );
	}
	$self->_install_trait_methods_for_class( $klass, \@traits );
	for my $m (@{ $node->static_methods // [] }) {
		my $static_fn = $self->_function_from_method_decl( $m, $self->_env );
		$static_fn->{_owner_class} = $klass;
		$static_fn->{_method_name} = $m->name;
		$static_fn->{_method_kind} = 'static';
		$static_fn->{_method_source} = 'class';
		$static_fn->{_uses_super} = $m->uses_super;
		$self->_install_method_function( $klass->static_methods, $m, $static_fn );
	}

	my $class_env = Zuzu::Env->_new_fast( $self->_env );
	$class_env->declare('self', $klass, 1);
	$self->_push_env($class_env);
	for my $n (@{ $node->classes // [] }) {
		my $inner = $self->eval_class_def($n);
		$inner->name( $klass->name . '{"' . $n->name . '"}' );
		$klass->nested_classes->{ $n->name } = $inner;
	}
	$self->_pop_env;

	for my $method ( values %{ $klass->methods } ) {
		$method->closure_env($class_env);
	}
	for my $method ( values %{ $klass->static_methods } ) {
		$method->closure_env($class_env);
	}
	$klass->closure_env($class_env);

	my $ref = $self->_env->find_ref($node->name);
	if (!$ref) {
		$self->_env->declare($node->name, undef, 1);
		$ref = $self->_env->find_ref($node->name);
	}
	$$ref = $klass;

	return $klass;
}

sub eval_trait_def {
	my ( $self, $node ) = @_;

	my $trait = Zuzu::Value::Trait->new(
		name => $node->name,
		methods => {},
		closure_env => $self->_env,
		source_node => $node,
	);

	for my $m ( @{ $node->methods // [] } ) {
		my $method = $self->_function_from_method_decl( $m, $self->_env );
		$method->{_uses_super} = $m->uses_super;
		$self->_install_method_function( $trait->methods, $m, $method );
	}

	my $ref = $self->_env->find_ref($node->name);
	if ( !$ref ) {
		$self->_env->declare($node->name, undef, 1);
		$ref = $self->_env->find_ref($node->name);
	}
	$$ref = $trait;

	return $trait;
}

sub eval_method_def {
	my ($self, $node) = @_;

	die Zuzu::Error->new_runtime(message => "Method declarations are only valid inside class declarations", file => $node->file, line => $node->line);
}

sub eval_return {
	my ($self, $node) = @_;

	my $v = defined($node->expr) ? $node->expr->evaluate($self) : undef;
	my $sig = bless({ _control => 'return', value => $v, skip_type_check => $node->{_skip_type_check} ? 1 : 0 }, 'Zuzu::Control');
	die $sig;
}

sub eval_next {
	my ($self, $node) = @_;

	die bless({ _control => 'next' }, 'Zuzu::Control');
}

sub eval_continue {
	my ( $self, $node ) = @_;

	die bless( { _control => 'continue' }, 'Zuzu::Control' );
}

sub eval_postfix_if {
	my ($self, $node) = @_;

	my $ok = $self->_to_Boolean( $node->cond->evaluate($self) ) ? 1 : 0;
	$ok = $ok ? 0 : 1 if $node->negate;

	return undef if !$ok;

	return $node->statement->evaluate($self);
}

sub eval_try {
	my ( $self, $node ) = @_;

	my $result;
	eval {
		$result = $node->block->evaluate($self);
		1;
	} or do {
		my $e = $@;
		if ( ref($e) and $e->{_control} ) {
			die $e;
		}
		my $thrown = $e;
		if ( ref($e) and $e->{_zuzu_throw} ) {
			$thrown = $e->{value};
		}
		else {
			$thrown = $self->_exception_value_from_error( $e );
		}
		for my $catch ( @{ $node->catches // [] } ) {
			my $type = $catch->type_expr->evaluate($self);
			next if !$self->_throw_matches_type( $thrown, $type );
			my $env = Zuzu::Env->_new_fast( $self->_env );
			$self->_push_env($env);
			$env->declare( $catch->name, $thrown, 0 );
			my $caught_result;
			eval {
				$caught_result = $catch->block->evaluate($self);
				1;
			} or do {
				my $inner = $@;
				$self->_pop_env;
				die $inner;
			};
			$self->_pop_env;
			return $caught_result;
		}
		die $e;
	};

	return $result;
}

sub _exception_value_from_error {
	my ( $self, $error ) = @_;

	return $error if !blessed($error) or !$error->isa('Zuzu::Error');

	my $class_name = ( $error->message // '' ) =~ /\ATypeException:/
		? 'TypeException'
		: 'Exception';
	my $class = $self->{_builtin_classes}{$class_name}
		// $self->{_builtin_classes}{Exception};

	return $self->_instantiate_builtin_object(
		$class,
		{
			message => $error->message // "$error",
			file => $error->file // '<runtime>',
			line => defined $error->line ? 0 + $error->line : 0,
			code => $error->code // '',
			kind => $error->kind,
		},
	);
}

sub eval_catch {
	my ( $self, $node ) = @_;

	die Zuzu::Error->new_runtime(
		message => "catch clauses are only valid inside try statements",
		file => $node->file,
		line => $node->line,
	);
}

sub eval_throw {
	my ( $self, $node ) = @_;

	my $value = $node->expr->evaluate($self);
	die {
		_zuzu_throw => 1,
		value => $value,
	};
}

sub eval_die {
	my ( $self, $node ) = @_;

	my $value = $node->expr->evaluate($self);
	if ( not blessed($value) ) {
		my $message = defined $value ? $self->_to_String($value) : '';
		$value = $self->_instantiate_builtin_object(
			$self->{_builtin_classes}{Exception},
			{
				message => $message,
				file => $node->file,
				line => $node->line,
			},
		);
	}
	die {
		_zuzu_throw => 1,
		value => $value,
	};
}

sub eval_debug {
	my ( $self, $node ) = @_;

	my $level = 0 + ( $node->level_expr->evaluate($self) // 0 );
	return undef if $level > $Zuzu::Runtime::DEBUG_LEVEL;
	my $message = $node->message_expr->evaluate($self);
	$message = defined $message ? $self->_to_String($message) : '';
	print STDERR "$message\n";

	return undef;
}

sub eval_assert {
	my ( $self, $node ) = @_;

	return undef if $Zuzu::Runtime::DEBUG_LEVEL <= 0;
	my $ok = $self->_to_Boolean( $node->expr->evaluate($self) ) ? 1 : 0;
	return undef if $ok;

	my $assert_class = $self->{_builtin_classes}{AssertionException}
		// $self->{_builtin_classes}{Exception};
	my $error = $self->_instantiate_builtin_object(
		$assert_class,
		{
			message => 'Assertion failed',
		},
	);
	die {
		_zuzu_throw => 1,
		value => $error,
	};
}

sub eval_last {
	my ($self, $node) = @_;

	die bless({ _control => 'last' }, 'Zuzu::Control');
}

sub eval_expr_stmt {
	my ($self, $node) = @_;

	return $node->expr->evaluate($self);
}

sub eval_import {
	my ($self, $node) = @_;

	if ( defined $node->condition_expr ) {
		my $pass = $self->_to_Boolean( $node->condition_expr->evaluate($self) ) ? 1 : 0;
		$pass = $node->condition_positive ? $pass : !$pass;
		if ( !$pass ) {
			$self->_bind_import_null_constants($node);
			return undef;
		}
	}

	my ($mod_env, $exports);
	if ( $node->try_mode ) {
		my $ok = eval {
			$mod_env = $self->_load_module($node->module, $node->file, $node->line);
			$exports = $self->{_module_exports}{ $node->module } // {};
			1;
		};
		if ( !$ok ) {
			$self->_bind_import_null_constants($node);
			return undef;
		}
	}
	else {
		$mod_env = $self->_load_module($node->module, $node->file, $node->line);
		$exports = $self->{_module_exports}{ $node->module } // {};
	}

	# star import excludes leading underscore
	for my $it (@{$node->items}) {
		if ($it->{star}) {
			for my $name ( sort CORE::keys %{ $exports } ) {
				next if $name =~ /\A_/;
				my $ref = $mod_env->{slots}{$name};
				my $is_const = $mod_env->{const}{$name} ? 1 : 0;
				$self->_assert_import_target_available( $name, $ref, $node );
				$self->_env->alias_to_ref($name, $ref, $is_const);
			}
			next;
		}
		my $src = $it->{name};
		my $dst = $it->{alias};
		die Zuzu::Error->new_runtime(message => "Module '".$node->module."' has no export '$src'", file => $node->file, line => $node->line)
			if !$exports->{$src};
		my $ref = $mod_env->find_ref($src);
		die Zuzu::Error->new_runtime(message => "Module '".$node->module."' has no export '$src'", file => $node->file, line => $node->line) if !$ref;
		my $is_const;
		# determine constness at module scope
		$is_const = $mod_env->{const}{$src} ? 1 : 0;
		$self->_assert_import_target_available( $dst, $ref, $node );
		$self->_env->alias_to_ref($dst, $ref, $is_const);
	}

	return undef;
}

sub _bind_import_null_constants {
	my ( $self, $node ) = @_;

	for my $it ( @{ $node->items } ) {
		next if $it->{star};
		my $dst = $it->{alias};
		die Zuzu::Error->new_runtime(
			message => "Import conflict: '$dst' is already declared in this scope",
			file => $node->file,
			line => $node->line,
		) if exists $self->_env->{slots}{$dst};
		$self->_env->declare( $dst, undef, 1 );
	}

	return;
}

sub _assert_import_target_available {
	my ( $self, $target, $ref, $node ) = @_;

	return if !exists $self->_env->{slots}{$target};

	my $existing = $self->_env->{slots}{$target};
	return if defined $existing and defined $ref and $existing == $ref;
	if ( $self->{_builtin_global_names}{$target} ) {
		my $builtin_ref = $self->{_global}{slots}{$target};
		return if defined $existing
			and defined $builtin_ref
			and $existing == $builtin_ref;
	}

	die Zuzu::Error->new_runtime(
		message => "Import conflict: '$target' is already declared in this scope",
		file => $node->file,
		line => $node->line,
	);
}

sub eval_literal { $_[1]->value }

sub eval_regexp_literal {
	my ( $self, $node ) = @_;

	my $pattern = '';
	for my $part ( @{ $node->parts // [] } ) {
		if ( ref $part eq 'HASH' and exists $part->{expr} ) {
			$pattern .= $self->_to_OperatorString(
				$part->{expr}->evaluate($self),
				$node->file,
				$node->line,
			);
		}
		else {
			$pattern .= ref $part eq 'HASH' && exists $part->{text}
				? $part->{text}
				: $part;
		}
	}

	return Zuzu::Value::Regexp->new(
		pattern => $pattern,
		flags => $node->flags // '',
	);
}

sub eval_var {
	my ($self, $node) = @_;

	my $env;
	my $name = $node->{name};
	if (
		defined $node->{_env_depth}
		and defined $node->{_binding_name}
		and $node->{_binding_name} eq $name
	) {
		$env = $self->{_stack}[-1];
		for ( 1 .. $node->{_env_depth} ) {
			last if !defined $env;
			$env = $env->{parent};
		}
		return ${ $env->{slots}{$name} }
			if defined $env and exists $env->{slots}{$name};
	}

	$env = $self->{_stack}[-1];
	while ($env) {
		return ${ $env->{slots}{$name} }
			if exists $env->{slots}{$name};
		$env = $env->{parent};
	}

	die Zuzu::Error->new_runtime(
		message => "Undeclared variable '$name'",
		file => $node->file,
		line => $node->line,
	);
}

sub eval_array {
	my ($self, $node) = @_;

	my @vals;
	for my $item ( @{ $node->items } ) {
		if ( blessed($item) and $item->isa('Zuzu::AST::Expr::Range') ) {
			my $range_values = $item->evaluate($self);
			push @vals, @{ $range_values->items // [] };
			next;
		}
		push @vals, $item->evaluate($self);
	}

	return Zuzu::Value::Array->new(items => \@vals);
}

sub eval_range {
	my ( $self, $node ) = @_;

	my $start = $self->_range_bound_to_int(
		$node->start->evaluate($self),
		$node->file,
		$node->line,
	);
	my $end = $self->_range_bound_to_int(
		$node->end->evaluate($self),
		$node->file,
		$node->line,
	);
	my @values;
	if ( $start <= $end ) {
		@values = ( $start .. $end );
	}
	else {
		@values = reverse( $end .. $start );
	}

	return Zuzu::Value::Array->new( items => \@values );
}

sub _range_bound_to_int {
	my ( $self, $value, $file, $line ) = @_;

	my $num = $self->_to_Number($value);
	my $int = int $num;
	if ( $num != $int ) {
		die Zuzu::Error->new_runtime(
			message => "Range bounds must be integers",
			file => $file,
			line => $line,
		);
	}

	return $int;
}

sub eval_dict {
	my ($self, $node) = @_;

	my %m;
	for my $p (@{$node->pairs}) {
		my ($kexpr, $vexpr) = @$p;
		my $k = $kexpr->evaluate($self);
		$k = defined($k) ? "$k" : '';
		my $v = $vexpr->evaluate($self);
		$m{$k} = $v;
	}

	return Zuzu::Value::Dict->new(map => \%m);
}

sub eval_pairlist {
	my ( $self, $node ) = @_;

	my @list;
	for my $pair ( @{ $node->pairs } ) {
		my ( $key_expr, $value_expr ) = @{ $pair };
		my $key = $key_expr->evaluate($self);
		$key = defined($key) ? "$key" : '';
		my $value = $value_expr->evaluate($self);
		push @list, [ $key, $value ];
	}

	return Zuzu::Value::PairList->new( list => \@list );
}

sub eval_set {
	my ($self, $node) = @_;

	my @vals;
	for my $item ( @{ $node->items } ) {
		if ( blessed($item) and $item->isa('Zuzu::AST::Expr::Range') ) {
			my $range_values = $item->evaluate($self);
			push @vals, @{ $range_values->items // [] };
			next;
		}
		push @vals, $item->evaluate($self);
	}
	my $set = Zuzu::Value::Set->new(items => []);
	$set->add(@vals);

	return $set;
}

sub eval_bag {
	my ($self, $node) = @_;

	my @vals;
	for my $item ( @{ $node->items } ) {
		if ( blessed($item) and $item->isa('Zuzu::AST::Expr::Range') ) {
			my $range_values = $item->evaluate($self);
			push @vals, @{ $range_values->items // [] };
			next;
		}
		push @vals, $item->evaluate($self);
	}

	return Zuzu::Value::Bag->new(items => \@vals);
}

sub _stable_value_key {
	my ( $self, $v ) = @_;

	return stable_value_key( $v );
}

sub _value_equal {
	my ( $self, $a, $b ) = @_;

	return value_equal( $a, $b );
}

sub _collection_items {
	my ( $self, $v ) = @_;

	my $as_array = $self->_unwrap_builtin_collection( $v, 'Array' );
	return $as_array->resolved_items if $as_array;
	my $as_set = $self->_unwrap_builtin_collection( $v, 'Set' );
	return $as_set->resolved_items if $as_set;
	my $as_bag = $self->_unwrap_builtin_collection( $v, 'Bag' );
	return $as_bag->resolved_items if $as_bag;
	my $as_dict = $self->_unwrap_builtin_collection( $v, 'Dict' );
	return CORE::keys %{ $as_dict->map } if $as_dict;
	my $as_pairlist = $self->_unwrap_builtin_collection( $v, 'PairList' );
	return map { $_->[0] } @{ $as_pairlist->list } if $as_pairlist;

	if ( blessed($v) and $v->isa('Zuzu::Value::Array') ) {
		return $v->resolved_items;
	}
	if ( blessed($v) and $v->isa('Zuzu::Value::Set') ) {
		return $v->resolved_items;
	}
	if ( blessed($v) and $v->isa('Zuzu::Value::Bag') ) {
		return $v->resolved_items;
	}
	if ( blessed($v) and $v->isa('Zuzu::Value::Dict') ) {
		return CORE::keys %{ $v->map };
	}
	if ( blessed($v) and $v->isa('Zuzu::Value::PairList') ) {
		return map { $_->[0] } @{ $v->list };
	}

	return ();
}

sub _coerce_set {
	my ( $self, $v, $file, $line ) = @_;

	my $set_like = $self->_unwrap_builtin_collection( $v, 'Set' );
	return $set_like if $set_like;
	my @items = $self->_collection_items($v);
	if (
		!@items
		and !$self->_unwrap_builtin_collection( $v, 'Array' )
		and !$self->_unwrap_builtin_collection( $v, 'Bag' )
		and !$self->_unwrap_builtin_collection( $v, 'Dict' )
		and !$self->_unwrap_builtin_collection( $v, 'PairList' )
	) {
		die Zuzu::Error->new_runtime(
			message => "Set operator expects Array, Dict, Set, or Bag",
			file => $file,
			line => $line,
		);
	}
	my $set = Zuzu::Value::Set->new( items => [] );
	$set->add( @items );

	return $set;
}

sub _in_collection {
	my ( $self, $needle, $col, $file, $line ) = @_;

	my $dict_like = $self->_unwrap_builtin_collection( $col, 'Dict' );
	if ( $dict_like ) {
		my $k = defined($needle) ? "$needle" : '';
		return _boolify( exists $dict_like->map->{$k} );
	}
	my $pairlist_like = $self->_unwrap_builtin_collection( $col, 'PairList' );
	if ( $pairlist_like ) {
		my $k = defined($needle) ? "$needle" : '';
		for my $pair ( @{ $pairlist_like->list } ) {
			return $TRUE if $pair->[0] eq $k;
		}

		return $FALSE;
	}
	for my $v ( $self->_collection_items($col) ) {
		return $TRUE if $self->_value_equal($needle, $v);
	}
	if (
		$self->_unwrap_builtin_collection( $col, 'Array' )
		or $self->_unwrap_builtin_collection( $col, 'Set' )
		or $self->_unwrap_builtin_collection( $col, 'Bag' )
		or $self->_unwrap_builtin_collection( $col, 'Dict' )
		or $self->_unwrap_builtin_collection( $col, 'PairList' )
	) {
		return $FALSE;
	}
	if ( !ref($col) ) {
		my $s = defined($col) ? "$col" : '';
		my $n = defined($needle) ? "$needle" : '';
		return _boolify( index( $s, $n ) >= 0 );
	}
	die Zuzu::Error->new_runtime(
		message => "in expects a collection or string",
		file => $file,
		line => $line,
	);
}

sub _set_union {
	my ( $self, $left, $right, $file, $line ) = @_;
	my $lset = $self->_coerce_set($left, $file, $line);
	my $rset = $self->_coerce_set($right, $file, $line);
	my $out = Zuzu::Value::Set->new( items => [ @{ $lset->items } ] );
	$out->add( @{ $rset->items } );

	return $out;
}

sub _set_intersection {
	my ( $self, $left, $right, $file, $line ) = @_;
	my $lset = $self->_coerce_set($left, $file, $line);
	my $rset = $self->_coerce_set($right, $file, $line);
	my @out;
	for my $v ( @{ $lset->items } ) {
		push @out, $v if $self->_in_collection( $v, $rset, $file, $line );
	}

	return Zuzu::Value::Set->new( items => \@out );
}

sub _set_difference {
	my ( $self, $left, $right, $file, $line ) = @_;
	my $lset = $self->_coerce_set($left, $file, $line);
	my $rset = $self->_coerce_set($right, $file, $line);
	my @out;
	for my $v ( @{ $lset->items } ) {
		push @out, $v if !$self->_in_collection( $v, $rset, $file, $line );
	}

	return Zuzu::Value::Set->new( items => \@out );
}

sub eval_index {
	my ($self, $node) = @_;

	my $target = $node->array->evaluate($self);
	my $idx = 0 + ($node->index->evaluate($self) // 0);
	my $arr = $self->_unwrap_builtin_collection( $target, 'Array' );
	if ( defined $arr ) {
		$idx += scalar @{ $arr->items } if $idx < 0;
		return $arr->get($idx) if exists $arr->items->[$idx];

		return undef;
	}
	if ( blessed($target) and $target->isa('Zuzu::Value::BinaryString') ) {
		my $bytes = $target->bytes // '';
		my $len = length( $bytes );
		$idx += $len if $idx < 0;
		return undef if $idx < 0 or $idx >= $len;

		return Zuzu::Value::BinaryString->new(
			bytes => substr( $bytes, $idx, 1 ),
		);
	}
	if ( defined($target) and !ref($target) ) {
		my $text = "$target";
		my $len = length($text);
		$idx += $len if $idx < 0;
		return undef if $idx < 0 or $idx >= $len;

		return substr( $text, $idx, 1 );
	}
	die Zuzu::Error->new_runtime(message => "Indexing expects Array, String, or BinaryString", file => $node->file, line => $node->line);
}

sub eval_slice {
	my ($self, $node) = @_;

	my $col = $node->collection->evaluate($self);
	my $start = defined $node->start ? 0 + ($node->start->evaluate($self) // 0) : 0;
	my $len = defined $node->length ? 0 + ($node->length->evaluate($self) // 0) : undef;
	my $arr = $self->_unwrap_builtin_collection( $col, 'Array' );
	if ( $arr ) {
		my @vals = @{ $arr->items };
		$start = 0 if $start < 0;
		my @out = defined $len
			? splice( @vals, $start, $len )
			: splice( @vals, $start );

		return Zuzu::Value::Array->new(items => \@out);
	}
	if ( blessed($col) and $col->isa('Zuzu::Value::BinaryString') ) {
		my $bytes = $col->bytes // '';
		my $size = length( $bytes );
		$start += $size if $start < 0;
		$start = 0 if $start < 0;
		$start = $size if $start > $size;
		my $slice = defined $len
			? substr( $bytes, $start, $len )
			: substr( $bytes, $start );

		return Zuzu::Value::BinaryString->new( bytes => $slice );
	}
	if ( defined($col) and !ref($col) ) {
		my $text = defined($col) ? "$col" : '';
		my $size = length($text);
		$start += $size if $start < 0;
		$start = 0 if $start < 0;
		$start = $size if $start > $size;

		return defined $len
			? substr( $text, $start, $len )
			: substr( $text, $start );
	}
	die Zuzu::Error->new_runtime(message => "Slice expects Array, String, or BinaryString", file => $node->file, line => $node->line);
}

sub eval_dict_get {
	my ($self, $node) = @_;

	my $d = $node->dict->evaluate($self);
	my $k = $node->key->evaluate($self);
	$k = defined($k) ? "$k" : '';
	my $dict = $self->_unwrap_builtin_collection( $d, 'Dict' );
	if ( $dict ) {
		return slot_value( \$dict->map->{$k} ) if exists $dict->map->{$k};

		return undef;
	}
	my $pairlist = $self->_unwrap_builtin_collection( $d, 'PairList' );
	if ( $pairlist ) {
		return $pairlist->get( $k );
	}
	if ( blessed($d) and $d->isa('Zuzu::Value::Object') ) {
		return $self->_object_get($d, $k);
	}
	if ( blessed($d) and $d->isa('Zuzu::Value::Class') ) {
		return $d->nested_classes->{$k} if exists $d->nested_classes->{$k};
		my $sm = $self->_lookup_method($d, $k, 1);
		if ($sm) {
			$sm->{_is_method} = 1;

			return $sm;
		}
		my $im = $self->_lookup_method($d, $k, 0);
		if ($im) {
			$im->{_is_method} = 1;

			return $im;
		}
	}
	die Zuzu::Error->new_runtime(message => "Dict-style access expects Dict, PairList, Object, or Class", file => $node->file, line => $node->line);
}

sub eval_unary {
	my ($self, $node) = @_;

	if ( $node->op eq '\\' ) {
		if ( $self->_is_path_lvalue_expr( $node->expr ) ) {
			my $target = $self->_resolve_lvalue_target( $node->expr );
			return $target->{refs}   if $target->{kind} eq 'path_multi_ref';
			return undef             if $target->{kind} eq 'path_maybe_ref' && !$target->{matched};
			return $target->{ref_fn} if exists $target->{ref_fn};
		}
		return $self->_make_lvalue_ref_closure( $node );
	}

	my $v = $node->expr->evaluate($self);
	my $op = $node->op;

	return +$self->_to_Number($v) if $op eq '+';

	return -$self->_to_Number($v) if $op eq '-';

	return _boolify( ! $self->_to_Boolean($v) ) if $op eq '!' || $op eq '¬' || $op eq 'not';
	return $self->_bitwise_not_value( $v, $node->file, $node->line ) if $op eq '~';
	return abs( $self->_to_Number($v) ) if $op eq 'abs';
	return sqrt( $self->_to_Number($v) ) if $op eq 'sqrt' || $op eq '√';
	return int( $self->_to_Number($v) ) if $op eq 'floor' || $op eq 'int';
	return _zuzu_ceil( $self->_to_Number($v) ) if $op eq 'ceil';
	return _zuzu_round( $self->_to_Number($v) ) if $op eq 'round';
	if ( $op eq 'uc' ) {
		if ( blessed($v) and $v->isa('Zuzu::Value::BinaryString') ) {
			die Zuzu::Error->new_runtime(
				message => "TypeException: uc expects String, got BinaryString",
				file => $node->file,
				line => $node->line,
			);
		}
		return uc( $self->_to_OperatorString( $v, $node->file, $node->line ) );
	}
	if ( $op eq 'lc' ) {
		if ( blessed($v) and $v->isa('Zuzu::Value::BinaryString') ) {
			die Zuzu::Error->new_runtime(
				message => "TypeException: lc expects String, got BinaryString",
				file => $node->file,
				line => $node->line,
			);
		}
		return lc( $self->_to_OperatorString( $v, $node->file, $node->line ) );
	}
	if ( $op eq 'length' ) {
		if ( blessed($v) and $v->isa('Zuzu::Value::BinaryString') ) {
			return $v->byte_length;
		}
		return length( $self->_to_OperatorString( $v, $node->file, $node->line ) );
	}
	return $self->_type_name($v) if $op eq 'typeof';
	die Zuzu::Error->new_runtime(message => "Unsupported unary op '$op'", file => $node->file, line => $node->line);
}

sub _make_lvalue_ref_closure {
	my ( $self, $node ) = @_;

	my $captured_env = $self->_env;
	my $target = $node->expr;

	my $fn = Zuzu::Value::Function->new(
		name => '<ref>',
		params => [],
		vararg => '__args',
		body => undef,
		closure_env => $captured_env,
	);
	$fn->{_native} = sub {
		my @args = @_;
		my $call_env = Zuzu::Env->_new_fast( $captured_env );
		$self->_push_env( $call_env );
		$call_env->declare( '__argc__', 0 + scalar @args, 1, 'Number' );

		my $ret;
		eval {
			if ( scalar @args == 0 ) {
				$ret = $target->evaluate($self);
			}
			else {
				my $target_info = $self->_resolve_lvalue_target( $target );
				my (
					$ref, $name, $target_env, $file, $line, $slice_col,
					$string_ref, $string_index, $binary_string,
					$binary_string_index, $pairlist, $pairlist_key
				)
					= (
						$target_info->{ref},
						$target_info->{name},
						$target_info->{env},
						$target_info->{file},
						$target_info->{line},
						$target_info->{slice_col},
						$target_info->{string_ref},
						$target_info->{kind} && $target_info->{kind} eq 'string_index',
						$target_info->{binary_string},
						$target_info->{kind} && $target_info->{kind} eq 'binary_string_index',
						$target_info->{pairlist},
						$target_info->{pairlist_key},
					);
				die Zuzu::Error->new_runtime(
					message => "Cannot assign to const field",
					file => $file,
					line => $line,
				) if $target_info->{const};

				if ( defined $name ) {
					my $const_here = defined $target_env
						? $target_env->{const}{$name}
						: $self->_env->is_const_here($name);
					if ( ! defined $const_here and ! defined $target_env ) {
						my $env = $self->_env;
						while ( $env ) {
							if ( exists $env->{slots}{$name} ) {
								$const_here = $env->{const}{$name};
								last;
							}
							$env = $env->{parent};
						}
					}
					die Zuzu::Error->new_runtime(
						message => "Cannot assign to const '$name'",
						file => $file,
						line => $line,
					) if $const_here;
				}
				my $newval = $args[0];
				my $weak_write = $target_info->{weak_storage}
					|| ( @args > 1 && Zuzu::Util::boolify( $args[1] ) )
					? 1
					: 0;
				if ( $target_info->{kind} && $target_info->{kind} eq 'path_single_ref' ) {
					$ret = $self->_call_ref_closure_set( $target_info->{ref_fn}, $newval, $file, $line );
				}
				elsif ( $target_info->{kind} && $target_info->{kind} eq 'path_maybe_ref' ) {
					$ret = ! $target_info->{matched}
						? undef
						: $self->_call_ref_closure_set( $target_info->{ref_fn}, $newval, $file, $line );
				}
				elsif ( $target_info->{kind} && $target_info->{kind} eq 'path_multi_ref' ) {
					die Zuzu::Error->new_runtime(
						message => "Reference operator expects a single assignable target",
						file => $file,
						line => $line,
					);
				}
				elsif ( $pairlist ) {
					$pairlist->_append( $pairlist_key, $newval, $weak_write );
					$ret = $newval;
				}
				elsif ( $slice_col ) {
					my $start = defined $target->start
						? 0 + ( $target->start->evaluate($self) // 0 )
						: 0;
					my $len;
					if ( defined $target->length ) {
						$len = 0 + ( $target->length->evaluate($self) // 0 );
					}
					else {
						$len = scalar( @{ $slice_col->items } ) - $start;
					}
					die Zuzu::Error->new_runtime(
						message => "Slice assignment RHS must be Array",
						file => $file,
						line => $line,
					) if ! blessed($newval) or ! $newval->isa('Zuzu::Value::Array');
					splice @{ $slice_col->items }, $start, $len, @{ $newval->items };
					$ret = $newval;
				}
				elsif ( $string_ref ) {
					if ( $string_index ) {
						$self->_assign_string_index(
							$string_ref,
							$target,
							$newval,
							$name,
							$target_env,
							$file,
							$line,
						);
					}
					else {
						$self->_assign_string_slice(
							$string_ref,
							$target,
							$newval,
							$name,
							$target_env,
							$file,
							$line,
						);
					}
					$ret = $newval;
				}
				elsif ( $binary_string ) {
					if ( $binary_string_index ) {
						$self->_assign_binary_string_index(
							$binary_string,
							$target,
							$newval,
							$file,
							$line,
						);
					}
					else {
						$self->_assign_binary_string_slice(
							$binary_string,
							$target,
							$newval,
							$file,
							$line,
						);
					}
					$ret = $newval;
				}
				else {
					store_value( $ref, $newval, $weak_write );
					$ret = $newval;
				}
			}
			1;
		} or do {
			my $e = $@;
			$self->_pop_env;
			die $e;
		};

		$self->_pop_env;
		return $ret;
	};

	return $fn;
}

sub _type_name {
	my ( $self, $x ) = @_;

	return 'Null' if !defined $x;

	my ( $array_like, $dict_like, $pairlist_like, $set_like, $bag_like )
		= $self->_builtin_collection_views($x);
	return 'Array' if $array_like;
	return 'Dict' if $dict_like;
	return 'PairList' if $pairlist_like;
	return 'Set' if $set_like;
	return 'Bag' if $bag_like;
	return 'Regexp' if blessed($x) and $x->isa('Zuzu::Value::Regexp');
	return 'Regexp' if ref($x) eq 'Regexp';
	return 'BinaryString' if blessed($x) and $x->isa('Zuzu::Value::BinaryString');
	return 'Task' if blessed($x) and $x->isa('Zuzu::Value::Task');

	return 'Method' if blessed($x) and $x->isa('Zuzu::Value::Function') and $x->{_is_method};
	return 'Function' if blessed($x) and $x->isa('Zuzu::Value::Function');
	return 'Class' if blessed($x) and $x->isa('Zuzu::Value::Class');
	return $x->class->name if blessed($x) and $x->isa('Zuzu::Value::Object') and blessed($x->class);
	return 'Object' if blessed($x) and $x->isa('Zuzu::Value::Object');
	return 'Boolean' if blessed($x) and $x->isa('Zuzu::Value::Boolean');
	return 'Number' if !ref($x) and equality_type( $x ) eq 'Number';

	return 'String' if !ref($x);

	return 'Object';
}

sub _assert_declared_type {
	my ( $self, $declared_type, $value, $file, $line, $name ) = @_;

	$declared_type //= 'Any';
	return if $declared_type eq 'Any';
	return if $self->_value_matches_declared_type( $declared_type, $value );

	my $actual = $self->_type_name($value);
	my $label = defined $name && $name ne '' ? "'$name'" : 'value';
	my $message = "TypeException: $label must be $declared_type, got $actual";
	die Zuzu::Error->new_runtime(
		message => $message,
		file => $file,
		line => $line,
	);
}

sub _value_matches_declared_type {
	my ( $self, $declared_type, $value ) = @_;

	return $TRUE if $declared_type eq 'Any';
	if ( exists $self->{_builtin_classes}{$declared_type} ) {
		return $self->_value_matches_class( $value, $self->{_builtin_classes}{$declared_type} );
	}

	my $ref = $self->_env->find_ref($declared_type);
	return $FALSE if ! $ref;
	my $target = $$ref;

	if ( blessed($target) and $target->isa('Zuzu::Value::Class') ) {
		return $FALSE if ! blessed($value) or ! $value->isa('Zuzu::Value::Object');
		my $klass = $value->class;
		while ($klass) {
			return $TRUE if $klass == $target;
			$klass = $klass->parent;
		}
		return $FALSE;
	}

	if ( blessed($target) and $target->isa('Zuzu::Value::Trait') ) {
		return $FALSE if ! blessed($value) or ! $value->isa('Zuzu::Value::Object');
		my %seen;
		my @queue = ($value->class);
		while (@queue) {
			my $klass = shift @queue;
			next if ! defined $klass;
			next if $seen{$klass}++;
			for my $trait ( @{ $klass->traits // [] } ) {
				return $TRUE if $trait == $target;
			}
			push @queue, $klass->parent if defined $klass->parent;
		}
		return $FALSE;
	}

	return $FALSE;
}

sub _zuzu_ceil {
	my ( $n ) = @_;
	my $i = int($n);
	return $i if $n == $i;
	return $n > 0 ? $i + 1 : $i;
}

sub _zuzu_round {
	my ( $n ) = @_;
	return int($n + ( $n >= 0 ? 0.5 : -0.5 ) );
}

sub eval_incdec {
	my ($self, $node) = @_;

	my $target = $self->_resolve_lvalue_target($node->target);
	my ($ref, $name, $target_env, $file, $line)
		= @{$target}{qw(ref name env file line)};
	my $const_here = defined $target_env
		? $target_env->{const}{$name}
		: $self->_env->is_const_here($name);
	if (!defined $const_here and !defined $target_env) {
		my $env = $self->_env;
		while ($env) {
			no warnings 'uninitialized';
			if (exists $env->{slots}{$name}) { $const_here = $env->{const}{$name}; last; }
			$env = $env->{parent};
		}
	}
	die Zuzu::Error->new_runtime(message => "Cannot assign to const '$name'", file => $file, line => $line) if $const_here;

	if ( $target->{kind} && $target->{kind} eq 'path_maybe_ref' ) {
		return $FALSE if !$target->{matched};
		my $old = $self->_to_Number(
			$self->_call_ref_closure_get( $target->{ref_fn}, $file, $line )
		);
		my $new = ($node->op eq '++') ? ($old + 1) : ($old - 1);
		$self->_call_ref_closure_set( $target->{ref_fn}, $new, $file, $line );
		return $TRUE;
	}

	if ( $target->{kind} && $target->{kind} eq 'path_single_ref' ) {
		my $old = $self->_to_Number(
			$self->_call_ref_closure_get( $target->{ref_fn}, $file, $line )
		);
		my $new = ($node->op eq '++') ? ($old + 1) : ($old - 1);
		$self->_call_ref_closure_set( $target->{ref_fn}, $new, $file, $line );
		return $node->postfix ? $old : $new;
	}

	if ( $target->{kind} && $target->{kind} eq 'path_multi_ref' ) {
		my @old;
		my @new;
		for my $ref_fn ( @{ $target->{refs}->items } ) {
			my $old = $self->_to_Number(
				$self->_call_ref_closure_get( $ref_fn, $file, $line )
			);
			my $new = ($node->op eq '++') ? ($old + 1) : ($old - 1);
			$self->_call_ref_closure_set( $ref_fn, $new, $file, $line );
			push @old, $old;
			push @new, $new;
		}
		return Zuzu::Value::Array->new(
			items => $node->postfix ? \@old : \@new,
		);
	}

	my $old = $self->_to_Number($$ref);
	my $new = ($node->op eq '++') ? ($old + 1) : ($old - 1);
	my $declared_type = defined $name
		? (
			defined $target_env
			? ( $target_env->{types}{$name} // 'Any' )
			: $self->_env->declared_type_for($name)
		)
		: 'Any';
	$self->_assert_declared_type( $declared_type, $new, $file, $line, $name );
	$$ref = $new;

	return $node->postfix ? $old : $new;
}

sub eval_ternary {
	my ($self, $node) = @_;

	my $cond_value = $node->cond->evaluate($self);
	if ( $self->_to_Boolean($cond_value) ) {
		if (defined $node->if_true) {
			return $node->if_true->evaluate($self);
		}

		return $cond_value;
	}

	return $node->if_false->evaluate($self);
}

sub eval_binary {
	my ($self, $node) = @_;

	my $op = $node->op;

	# boolean keywords come as KW tokens in parser; treat them here too
	if ($op eq 'and' || $op eq '⋀') {
		my $l = $node->left->evaluate($self);

		return $self->_to_Boolean($l)
			? _boolify( $self->_to_Boolean( $node->right->evaluate($self) ) )
			: $FALSE;
	}
	if ($op eq 'and?' || $op eq '⋀?') {
		my $l = $node->left->evaluate($self);

		return $self->_to_Boolean($l) ? $node->right->evaluate($self) : $l;
	}
	if ($op eq 'nand' || $op eq '⊼') {
		my $l = $node->left->evaluate($self);

		return $TRUE if !$self->_to_Boolean($l);

		return $self->_to_Boolean( $node->right->evaluate($self) ) ? $FALSE : $TRUE;
	}
	if ($op eq 'nand?' || $op eq '⊼?') {
		my $l = $node->left->evaluate($self);
		my $r = $node->right->evaluate($self);

		return $self->_to_Boolean($l)
			? ( $self->_to_Boolean($r) ? $FALSE : $TRUE )
			: ( $self->_to_Boolean($r) ? $r : $TRUE );
	}
	if ($op eq 'xor' || $op eq '⊻') {
		my $l = $self->_to_Boolean( $node->left->evaluate($self) ) ? 1 : 0;
		my $r = $self->_to_Boolean( $node->right->evaluate($self) ) ? 1 : 0;

		return ($l xor $r) ? $TRUE : $FALSE;
	}
	if ($op eq 'xor?' || $op eq '⊻?') {
		my $l = $node->left->evaluate($self);
		my $r = $node->right->evaluate($self);

		return $self->_to_Boolean($l)
			? ( $self->_to_Boolean($r) ? $FALSE : $l )
			: ( $self->_to_Boolean($r) ? $r : $FALSE );
	}
	if ($op eq 'xnor' || $op eq '↔') {
		my $l = $self->_to_Boolean( $node->left->evaluate($self) ) ? 1 : 0;
		my $r = $self->_to_Boolean( $node->right->evaluate($self) ) ? 1 : 0;

		return $l == $r ? $TRUE : $FALSE;
	}
	if ($op eq 'xnor?' || $op eq '↔?') {
		my $l = $node->left->evaluate($self);
		my $r = $node->right->evaluate($self);

		return $self->_to_Boolean($l)
			? $r
			: ( $self->_to_Boolean($r) ? $l : $TRUE );
	}
	if ($op eq 'nor' || $op eq '⊽') {
		my $l = $node->left->evaluate($self);

		return $FALSE if $self->_to_Boolean($l);

		return $self->_to_Boolean( $node->right->evaluate($self) ) ? $FALSE : $TRUE;
	}
	if ($op eq 'nor?' || $op eq '⊽?') {
		my $l = $node->left->evaluate($self);
		my $r = $node->right->evaluate($self);

		return $self->_to_Boolean($l)
			? ( $self->_to_Boolean($r) ? $FALSE : $r )
			: ( $self->_to_Boolean($r) ? $l : $TRUE );
	}
	if ($op eq 'onlyif' || $op eq '⊨') {
		my $l = $node->left->evaluate($self);

		return $TRUE if !$self->_to_Boolean($l);

		return _boolify( $self->_to_Boolean( $node->right->evaluate($self) ) );
	}
	if ($op eq 'onlyif?' || $op eq '⊨?') {
		my $l = $node->left->evaluate($self);

		return $self->_to_Boolean($l) ? $node->right->evaluate($self) : $TRUE;
	}
	if ($op eq 'butnot' || $op eq '⊭') {
		my $l = $node->left->evaluate($self);

		return $FALSE if !$self->_to_Boolean($l);

		return $self->_to_Boolean( $node->right->evaluate($self) ) ? $FALSE : $TRUE;
	}
	if ($op eq 'butnot?' || $op eq '⊭?') {
		my $l = $node->left->evaluate($self);

		return $l if !$self->_to_Boolean($l);

		return $self->_to_Boolean( $node->right->evaluate($self) ) ? $FALSE : $l;
	}
	if ($op eq 'or' || $op eq '⋁') {
		my $l = $node->left->evaluate($self);

		return $self->_to_Boolean($l) ? $TRUE : _boolify( $self->_to_Boolean( $node->right->evaluate($self) ) );
	}
	if ($op eq 'or?' || $op eq '⋁?') {
		my $l = $node->left->evaluate($self);

		return $self->_to_Boolean($l) ? $l : $node->right->evaluate($self);
	}
	if ( $op eq '▷' or $op eq '|>' or $op eq '◁' or $op eq '<|' ) {
		return $self->_eval_chain_operator($node);
	}

	my $l = $node->left->evaluate($self);
	my $r = $node->right->evaluate($self);

	return $self->_eval_binary_op_values( $op, $l, $r, $node->file, $node->line );
}

sub _eval_chain_operator {
	my ( $self, $node ) = @_;

	my $op = $node->op;
	my ( $value, $expr );
	if ( $op eq '▷' or $op eq '|>' ) {
		$value = $node->left->evaluate($self);
		$expr = $node->right;
	}
	else {
		$value = $node->right->evaluate($self);
		$expr = $node->left;
	}

	my $env = Zuzu::Env->_new_fast( $self->{_stack}[-1] );
	$self->_push_env($env);
	$env->declare( '^^', $value, 1, 'Any' );
	my $result;
	my $ok = eval {
		$result = $expr->evaluate($self);
		1;
	};
	my $err = $@;
	$self->_pop_env;
	die $err if !$ok;

	return $result;
}

sub _switch_matches {
	my ( $self, $op, $left, $right, $file, $line ) = @_;

	my $result = $self->_eval_binary_op_values( $op, $left, $right, $file, $line );

	return $self->_to_Boolean($result) ? $TRUE : $FALSE;
}

sub _eval_binary_op_values {
	my ( $self, $op, $l, $r, $file, $line ) = @_;

	if ( $op eq 'default' ) {
		return $self->_default_collection_values( $l, $r, $file, $line );
	}

	if ($op eq '+' ) { return $self->_to_Number($l) + $self->_to_Number($r); }
	if ($op eq '-' ) { return $self->_to_Number($l) - $self->_to_Number($r); }
	if ($op eq '*' || $op eq '×') { return $self->_to_Number($l) * $self->_to_Number($r); }
	if ($op eq '/' || $op eq '÷') { return $self->_to_Number($l) / $self->_to_Number($r); }
	if ($op eq 'mod') { return POSIX::fmod( $self->_to_Number($l), $self->_to_Number($r) ); }
	if ($op eq '**') { return $self->_to_Number($l) ** $self->_to_Number($r); }
	if ($op eq '&' || $op eq '|' || $op eq '^') {
		return $self->_bitwise_binary_op( $op, $l, $r, $file, $line );
	}
	if ($op eq '<<' || $op eq '«' || $op eq '>>' || $op eq '»') {
		return $self->_shift_binary_op( $op, $l, $r, $file, $line );
	}

		if ( $op eq '_' ) {
			my $left_is_binary = ( blessed($l) and $l->isa('Zuzu::Value::BinaryString') ) ? 1 : 0;
			my $right_is_binary = ( blessed($r) and $r->isa('Zuzu::Value::BinaryString') ) ? 1 : 0;

		if ( $left_is_binary and $right_is_binary ) {
			return Zuzu::Value::BinaryString->new(
				bytes => ( $l->bytes // '' ) . ( $r->bytes // '' ),
			);
		}
		if ( $left_is_binary or $right_is_binary ) {
			my $binary = $left_is_binary ? $l : $r;
			if ( ! $binary->is_ascii ) {
				die Zuzu::Error->new_runtime(
					message => "TypeException: Cannot implicitly concatenate non-ASCII BinaryString with String; use to_string(...)",
					file => $file,
					line => $line,
				);
			}
			my $text = $left_is_binary
				? $self->_to_OperatorString( $r, $file, $line )
				: $self->_to_OperatorString( $l, $file, $line );
			my $ascii = $binary->bytes // '';

			return $left_is_binary ? ( $ascii . $text ) : ( $text . $ascii );
		}

		return $self->_to_OperatorString( $l, $file, $line )
			. $self->_to_OperatorString( $r, $file, $line );
	}

	if ($op eq '∣' || $op eq 'divides' || $op eq '∤') {
		# The left operand is the divisor: a ∣ b tests b mod a.
		my $remainder = POSIX::fmod( $self->_to_Number($r), $self->_to_Number($l) );
		return $remainder if $op eq '∤';
		return _boolify( $remainder == 0 );
	}

	# numeric comparisons
	if ($op eq '=')  { return _boolify( $self->_to_Number($l) == $self->_to_Number($r) ); }
	if ($op eq '≠') { return _boolify( $self->_to_Number($l) != $self->_to_Number($r) ); }
	if ($op eq '<')  { return _boolify( $self->_to_Number($l) <  $self->_to_Number($r) ); }
	if ($op eq '<=' || $op eq '≤') { return _boolify( $self->_to_Number($l) <= $self->_to_Number($r) ); }
	if ($op eq '>')  { return _boolify( $self->_to_Number($l) >  $self->_to_Number($r) ); }
	if ($op eq '>=' || $op eq '≥') { return _boolify( $self->_to_Number($l) >= $self->_to_Number($r) ); }
	if ($op eq '<=>' || $op eq '≶' || $op eq '≷') {
		my $ln = $self->_to_Number($l);
		my $rn = $self->_to_Number($r);

		return ($ln <=> $rn);
	}

	# type-aware equality skeleton: same ref type and same string/num
	if ($op eq '==' || $op eq '≡') {
		return $self->_value_equal( $l, $r ) ? $TRUE : $FALSE;
	}
	if ($op eq '!=' || $op eq '≢') {
		return $self->_value_equal( $l, $r ) ? $FALSE : $TRUE;
	}

	if ( $op eq '~' ) {
		my $target = $self->_to_OperatorString( $l, $file, $line );
		my $regexp = $self->_coerce_regexp( $r, $file, $line );
		if ( $self->_regexp_is_global($r) ) {
			my @all_matches;
			while ( $target =~ /$regexp/g ) {
				push @all_matches, Zuzu::Value::Array->new( items => [ $self->_current_match_values($target) ] );
			}
			return $FALSE if !@all_matches;

			return Zuzu::Value::Array->new( items => \@all_matches );
		}
		my @matches = ( $target =~ $regexp );
		if ( !@matches and $target !~ $regexp ) {
			return $FALSE;
		}

		my $full = $&;
		unshift @matches, $full;

		return Zuzu::Value::Array->new( items => \@matches );
	}
	if ( $op eq '@' or $op eq '@?' or $op eq '@@' ) {
		return $self->_eval_path_operator( $op, $l, $r, $file, $line );
	}

	if (
		$op eq 'eq' or $op eq 'ne' or $op eq 'gt' or $op eq 'ge'
		or $op eq 'lt' or $op eq 'le' or $op eq 'cmp'
		or $op eq 'eqi' or $op eq 'nei' or $op eq 'gti'
		or $op eq 'gei' or $op eq 'lti' or $op eq 'lei'
		or $op eq 'cmpi'
	) {
		my $ls = $self->_to_OperatorString( $l, $file, $line );
		my $rs = $self->_to_OperatorString( $r, $file, $line );

		if ($op eq 'eq')   { return $ls eq $rs ? $TRUE : $FALSE; }
		if ($op eq 'ne')   { return $ls ne $rs ? $TRUE : $FALSE; }
		if ($op eq 'gt')   { return $ls gt $rs ? $TRUE : $FALSE; }
		if ($op eq 'ge')   { return $ls ge $rs ? $TRUE : $FALSE; }
		if ($op eq 'lt')   { return $ls lt $rs ? $TRUE : $FALSE; }
		if ($op eq 'le')   { return $ls le $rs ? $TRUE : $FALSE; }
		if ($op eq 'cmp')  { return $ls cmp $rs; }

		my $lsi = CORE::fc( $ls );
		my $rsi = CORE::fc( $rs );

		if ($op eq 'eqi')  { return $lsi eq $rsi ? $TRUE : $FALSE; }
		if ($op eq 'nei')  { return $lsi ne $rsi ? $TRUE : $FALSE; }
		if ($op eq 'gti')  { return $lsi gt $rsi ? $TRUE : $FALSE; }
		if ($op eq 'gei')  { return $lsi ge $rsi ? $TRUE : $FALSE; }
		if ($op eq 'lti')  { return $lsi lt $rsi ? $TRUE : $FALSE; }
		if ($op eq 'lei')  { return $lsi le $rsi ? $TRUE : $FALSE; }
		if ($op eq 'cmpi') { return $lsi cmp $rsi; }
	}

	if ($op eq 'in' || $op eq '∈') {
		return $self->_in_collection( $l, $r, $file, $line );
	}
	if ($op eq '∉') {
		return $self->_in_collection( $l, $r, $file, $line ) ? $FALSE : $TRUE;
	}
	if ($op eq 'union' || $op eq '⋃') {
		return $self->_set_union( $l, $r, $file, $line );
	}
	if ($op eq 'intersection' || $op eq '⋂') {
		return $self->_set_intersection( $l, $r, $file, $line );
	}
	if ($op eq '\\' || $op eq '∖') {
		return $self->_set_difference( $l, $r, $file, $line );
	}
	if ($op eq 'subsetof' || $op eq '⊂') {
		my $diff = $self->_set_difference( $l, $r, $file, $line );
		return $diff->empty ? $TRUE : $FALSE;
	}
	if ($op eq 'supersetof' || $op eq '⊃') {
		my $diff = $self->_set_difference( $r, $l, $file, $line );
		return $diff->empty ? $TRUE : $FALSE;
	}
	if ($op eq 'equivalentof' || $op eq '⊂⊃') {
		my $a = $self->_set_difference( $l, $r, $file, $line );
		my $b = $self->_set_difference( $r, $l, $file, $line );
		return ( $a->empty and $b->empty ) ? $TRUE : $FALSE;
	}
	if ( $op eq 'instanceof' ) {
		return 0 if !blessed($r) or !$r->isa('Zuzu::Value::Class');
		return $self->_value_matches_class( $l, $r );
	}
	if ( $op eq 'does' ) {
		return $FALSE if !ref($l);
		my $target = $l;
		$target = $l->class if $l->isa('Zuzu::Value::Object');
		return $FALSE if !$target->isa('Zuzu::Value::Class');
		return $FALSE if !blessed($r) or !$r->isa('Zuzu::Value::Trait');
		my $k = $target;
		while ($k) {
			for my $tr ( @{ $k->traits // [] } ) {
				return $TRUE if $tr == $r;
			}
			$k = $k->parent;
		}
		return $FALSE;
	}
	if ( $op eq 'can' ) {
		my $method = defined($r) ? "$r" : '';
		return $FALSE if $method eq '';
		if ( blessed($l) and $l->isa('Zuzu::Value::Object') ) {
			return $self->_lookup_method( $l->class, $method, 0 ) ? $TRUE : $FALSE;
		}
		if ( blessed($l) and $l->isa('Zuzu::Value::Class') ) {
			return $self->_lookup_method( $l, $method, 1 ) ? $TRUE : $FALSE;
		}
		return $FALSE if !ref($l);

		return $l->can($method) ? $TRUE : $FALSE;
	}

	die Zuzu::Error->new_runtime(message => "Unsupported binary op '$op'", file => $file, line => $line);
}

sub _default_collection_values {
	my ( $self, $left, $right, $file, $line ) = @_;

	my $right_dict = $self->_unwrap_builtin_collection( $right, 'Dict' );
	my $right_pairlist = $self->_unwrap_builtin_collection( $right, 'PairList' );
	if ( !$right_dict and !$right_pairlist ) {
		my $type = $self->_type_name($right);
		die Zuzu::Error->new_runtime(
			message => "TypeException: default operator right operand expects Dict or PairList, got $type",
			file => $file,
			line => $line,
		);
	}

	my $left_dict;
	my $left_pairlist;
	if ( defined $left ) {
		$left_dict = $self->_unwrap_builtin_collection( $left, 'Dict' );
		$left_pairlist = $self->_unwrap_builtin_collection( $left, 'PairList' );
		if ( !$left_dict and !$left_pairlist ) {
			my $type = $self->_type_name($left);
			die Zuzu::Error->new_runtime(
				message => "TypeException: default operator left operand expects Dict, PairList, or Null, got $type",
				file => $file,
				line => $line,
			);
		}
	}

	if ($left_dict) {
		my $result = $left_dict->copy;
		if ($right_dict) {
			for my $key ( sort CORE::keys %{ $right_dict->map } ) {
				next if $result->exists($key);
				$result->_store_key(
					$key,
					$right_dict->_value_for_key($key),
					$right_dict->weak->{$key} ? 1 : 0,
				);
			}
		}
		else {
			for ( my $i = 0; $i < @{ $right_pairlist->list }; $i++ ) {
				my $key = $right_pairlist->list->[$i][0];
				next if $result->exists($key);
				$result->_store_key(
					$key,
					$right_pairlist->_value_at($i),
					$right_pairlist->weak->[$i] ? 1 : 0,
				);
			}
		}

		return $result;
	}

	my $source = $left_pairlist // Zuzu::Value::PairList->new( list => [] );
	my $result = $source->copy;
	my %original_key = map { $_->[0] => 1 } @{ $source->list };

	if ($right_dict) {
		for my $key ( sort CORE::keys %{ $right_dict->map } ) {
			next if $original_key{$key};
			$result->_append(
				$key,
				$right_dict->_value_for_key($key),
				$right_dict->weak->{$key} ? 1 : 0,
			);
		}
	}
	else {
		for ( my $i = 0; $i < @{ $right_pairlist->list }; $i++ ) {
			my $key = $right_pairlist->list->[$i][0];
			next if $original_key{$key};
			$result->_append(
				$key,
				$right_pairlist->_value_at($i),
				$right_pairlist->weak->[$i] ? 1 : 0,
			);
		}
	}

	return $result;
}

sub _eval_path_operator {
	my ( $self, $op, $target, $path_value, $file, $line ) = @_;

	my $path_obj = $self->_coerce_path_operand( $path_value, $file, $line );

	if ( $op eq '@' ) {
		return $self->_call_path_method(
			$path_obj,
			'first',
			[ $target, undef ],
			$file,
			$line,
		);
	}
	if ( $op eq '@?' ) {
		my $exists = $self->_call_path_method(
			$path_obj,
			'exists',
			[ $target ],
			$file,
			$line,
		);
		return $self->_to_Boolean( $exists ) ? $TRUE : $FALSE;
	}

	return $self->_call_path_method(
		$path_obj,
		'get',
		[ $target ],
		$file,
		$line,
	);
}

sub _coerce_path_operand {
	my ( $self, $path_value, $file, $line ) = @_;

	if ( blessed($path_value) and $path_value->isa('Zuzu::Value::Object') ) {
		return $path_value;
	}

	if ( !ref($path_value) and $self->_type_name( $path_value ) eq 'String' ) {
		my $path_class = $self->_resolve_path_class_from_props( $file, $line );
		return $self->_instantiate_path_object( $path_class, $path_value, $file, $line );
	}

	my $type = $self->_type_name( $path_value );
	die Zuzu::Error->new_runtime(
		message => "TypeException: path operand must be String or Object, got $type",
		file => $file,
		line => $line,
	);
}

sub _resolve_path_class_from_props {
	my ( $self, $file, $line ) = @_;

	my $prop = $self->_env->get_special_prop('paths');
	if ( defined $prop ) {
		if ( blessed($prop) and $prop->isa('Zuzu::Value::Class') ) {
			return $prop;
		}
		my $type = $self->_type_name( $prop );
		die Zuzu::Error->new_runtime(
			message => "TypeException: paths special property must be Class or null, got $type",
			file => $file,
			line => $line,
		);
	}

	return $self->_default_path_class( $file, $line );
}

sub _default_path_class {
	my ( $self, $file, $line ) = @_;

	return $self->{_default_path_class}
		if blessed( $self->{_default_path_class} )
		and $self->{_default_path_class}->isa('Zuzu::Value::Class');

	my $module_env = $self->_load_module( 'std/path/zz', $file, $line );
	my $class_ref = $module_env->find_ref('ZZPath');
	die Zuzu::Error->new_runtime(
		message => "Cannot resolve default path class 'ZZPath' from std/path/zz",
		file => $file,
		line => $line,
	) if !defined $class_ref;

	my $class_obj = $$class_ref;
	die Zuzu::Error->new_runtime(
		message => "Default path class 'ZZPath' from std/path/zz is not a Class",
		file => $file,
		line => $line,
	) if !blessed($class_obj) or !$class_obj->isa('Zuzu::Value::Class');

	$self->{_default_path_class} = $class_obj;
	return $class_obj;
}

sub _instantiate_path_object {
	my ( $self, $path_class, $path_text, $file, $line ) = @_;

	my %named = ( path => $path_text );
	my ($slots, $const, $types, $weak) = $self->_instantiate_slots($path_class);
	for my $k ( keys %named ) {
		$slots->{$k} = $named{$k};
		$const->{$k} = 0 if !exists $const->{$k};
		$types->{$k} = 'Any' if !exists $types->{$k};
		$weak->{$k} = 0 if !exists $weak->{$k};
	}
	my $object = Zuzu::Value::Object->new(
		class => $path_class,
		slots => $slots,
		const => $const,
		types => $types,
		weak => $weak,
	);
	return $self->_apply_object_lifecycle_hooks( $object, $path_class, $file, $line );
}

sub _call_path_method {
	my ( $self, $path_obj, $method_name, $args, $file, $line ) = @_;

	my $method = $self->_lookup_method( $path_obj->class, $method_name, 0 );
	die Zuzu::Error->new_runtime(
		message => "Path object does not support method '$method_name'",
		file => $file,
		line => $line,
	) if !$method;

	return $self->_call_method(
		$method,
		$path_obj,
		$args,
		$EMPTY_HASH,
		$EMPTY_ARRAY,
		$file,
		$line,
	);
}

sub _bitwise_binary_op {
	my ( $self, $op, $left, $right, $file, $line ) = @_;

	my $left_is_binary = blessed($left) && $left->isa('Zuzu::Value::BinaryString') ? 1 : 0;
	my $right_is_binary = blessed($right) && $right->isa('Zuzu::Value::BinaryString') ? 1 : 0;
	if ( $left_is_binary || $right_is_binary ) {
		if ( !$left_is_binary or !$right_is_binary ) {
			die Zuzu::Error->new_runtime(
				message => "TypeException: BinaryString bitwise '$op' expects BinaryString operands on both sides",
				file => $file,
				line => $line,
			);
		}
		return $self->_bitwise_binary_string_pair( $op, $left, $right, $file, $line );
	}

	my $ln = int( $self->_to_Number( $left ) );
	my $rn = int( $self->_to_Number( $right ) );

	return ( $ln & $rn ) if $op eq '&';
	return ( $ln | $rn ) if $op eq '|';
	return ( $ln ^ $rn ) if $op eq '^';
	die Zuzu::Error->new_runtime(message => "Unsupported bitwise op '$op'", file => $file, line => $line);
}

sub _bitwise_binary_string_pair {
	my ( $self, $op, $left, $right, $file, $line ) = @_;

	my $lhs = $left->bytes // '';
	my $rhs = $right->bytes // '';
	my $llen = length( $lhs );
	my $rlen = length( $rhs );
	if ( $llen != $rlen ) {
		die Zuzu::Error->new_runtime(
			message => "Bitwise '$op' on BinaryString requires equal byte lengths",
			file => $file,
			line => $line,
		);
	}
	my $out = '';
	for ( my $i = 0; $i < $llen; $i++ ) {
		my $lb = ord( substr( $lhs, $i, 1 ) );
		my $rb = ord( substr( $rhs, $i, 1 ) );
		my $xb = $op eq '&'
			? ( $lb & $rb )
			: $op eq '|'
				? ( $lb | $rb )
				: ( $lb ^ $rb );
		$out .= chr( $xb );
	}

	return Zuzu::Value::BinaryString->new( bytes => $out );
}

sub _shift_binary_op {
	my ( $self, $op, $left, $right, $file, $line ) = @_;

	my $left_shift = ( $op eq '<<' || $op eq '«' ) ? 1 : 0;
	my $count = $self->_to_Number( $right );
	$count = int( $count );
	if ( $count < 0 ) {
		die Zuzu::Error->new_runtime(
			message => "shift count must be a non-negative integer",
			file => $file,
			line => $line,
		);
	}

	if ( blessed($left) and $left->isa('Zuzu::Value::BinaryString') ) {
		return Zuzu::Value::BinaryString->new(
			bytes => _shift_bitstream( $left->bytes // '', $count, $left_shift ),
		);
	}

	my $value = int( $self->_to_Number( $left ) );
	my $factor = 2 ** $count;
	return $left_shift
		? $value * $factor
		: POSIX::floor( $value / $factor );
}

# Shift a byte string as one whole bit string: bits carry across byte
# boundaries, length is preserved, vacated bits are 0.
sub _shift_bitstream {
	my ( $bytes, $count, $left ) = @_;

	my $len = length( $bytes );
	return $bytes if $len == 0;
	return "\0" x $len if $count >= $len * 8;

	my $byte_shift = int( $count / 8 );
	my $bit_shift = $count % 8;
	my $out = '';
	for ( my $i = 0; $i < $len; $i++ ) {
		my $value;
		if ( $left ) {
			my $src = $i + $byte_shift;
			my $hi = $src < $len ? ord( substr( $bytes, $src, 1 ) ) : 0;
			my $lo = $src + 1 < $len ? ord( substr( $bytes, $src + 1, 1 ) ) : 0;
			$value = ( ( ( $hi << 8 ) | $lo ) << $bit_shift ) >> 8;
		}
		else {
			if ( $i < $byte_shift ) {
				$out .= "\0";
				next;
			}
			my $lo = ord( substr( $bytes, $i - $byte_shift, 1 ) );
			my $hi = $i > $byte_shift
				? ord( substr( $bytes, $i - $byte_shift - 1, 1 ) )
				: 0;
			$value = ( ( $hi << 8 ) | $lo ) >> $bit_shift;
		}
		$out .= chr( $value & 0xFF );
	}

	return $out;
}

sub _bitwise_not_value {
	my ( $self, $value, $file, $line ) = @_;

	if ( blessed($value) and $value->isa('Zuzu::Value::BinaryString') ) {
		my $bytes = $value->bytes // '';
		my $out = '';
		for ( my $i = 0; $i < length( $bytes ); $i++ ) {
			my $byte = ord( substr( $bytes, $i, 1 ) );
			$out .= chr( ( ~$byte ) & 0xFF );
		}

		return Zuzu::Value::BinaryString->new( bytes => $out );
	}

	return ~int( $self->_to_Number( $value ) );
}

sub _coerce_regexp {
	my ( $self, $value, $file, $line ) = @_;

	if ( blessed($value) and $value->isa('Zuzu::Value::Regexp') ) {
		my $pattern = $value->pattern // '';
		my $flags = $value->flags // '';
		my $mods = $self->_regexp_flags_to_modifiers($flags);

		return $self->_compile_regexp_pattern(
			$pattern,
			$mods,
			'literal',
			'Invalid regexp literal',
			$file,
			$line,
		);
	}
	if ( ref($value) eq 'Regexp' ) {
		return $value;
	}
	my $pattern = $self->_to_OperatorString( $value, $file, $line );

	return $self->_compile_regexp_pattern(
		$pattern,
		'',
		'plain',
		'Invalid regexp value',
		$file,
		$line,
	);
}

sub _regexp_flags_to_modifiers {
	my ( $self, $flags ) = @_;

	return ( $flags // '' ) =~ /i/ ? '(?i)' : '';
}

sub _compile_regexp_pattern {
	my ( $self, $pattern, $mods, $kind, $message, $file, $line ) = @_;

	$pattern //= '';
	$mods //= '';
	my $cache_key = "$kind\x1f$mods\x1f$pattern";
	my $regex = $self->{_regexp_cache}{$cache_key};
	return $regex if defined $regex;
	$regex = eval { qr/$mods$pattern/ };
	if ( !defined $regex ) {
		my $err = $@ || 'unknown regex compile error';
		die Zuzu::Error->new_runtime(
			message => "$message: $err",
			file => $file,
			line => $line,
		);
	}
	$self->{_regexp_cache}{$cache_key} = $regex;

	return $regex;
}

sub _to_RegexpValue {
	my ( $self, $value, $file, $line ) = @_;

	if ( blessed($value) and $value->isa('Zuzu::Value::Regexp') ) {
		my $pattern = $value->pattern // '';
		my $mods = $self->_regexp_flags_to_modifiers( $value->flags );
		$self->_compile_regexp_pattern(
			$pattern,
			$mods,
			'literal',
			'Invalid regexp literal',
			$file,
			$line,
		);

		return $value;
	}

	my $pattern = $self->_to_OperatorString( $value, $file, $line );
	$self->_compile_regexp_pattern(
		$pattern,
		'',
		'plain',
		'Invalid regexp value',
		$file,
		$line,
	);

	return Zuzu::Value::Regexp->new( pattern => $pattern, flags => '' );
}

sub _to_RegexpValue_with_flags {
	my ( $self, $value, $flags, $file, $line ) = @_;

	my $pattern = $self->_to_OperatorString( $value, $file, $line );
	$flags = $self->_to_OperatorString( $flags, $file, $line );
	my $mods = $self->_regexp_flags_to_modifiers($flags);
	$self->_compile_regexp_pattern(
		$pattern,
		$mods,
		'plain',
		'Invalid regexp value',
		$file,
		$line,
	);

	return Zuzu::Value::Regexp->new( pattern => $pattern, flags => $flags );
}

sub _regexp_is_global {
	my ( $self, $value ) = @_;

	return 0 if ! blessed($value) or ! $value->isa('Zuzu::Value::Regexp');
	my $flags = $value->flags // '';

	return $flags =~ /g/ ? 1 : 0;
}

sub _current_match_values {
	my ( $self, $target ) = @_;

	my @captures = ();
	for ( my $i = 0; $i < scalar @-; $i++ ) {
		if ( defined $-[$i] and defined $+[$i] and $-[$i] >= 0 and $+[$i] >= 0 ) {
			push @captures, substr( $target, $-[$i], $+[$i] - $-[$i] );
		}
		else {
			push @captures, undef;
		}
	}

	return @captures;
}

sub _evaluate_regexp_replace_expr {
	my ( $self, $replace_expr, $captures ) = @_;

	my $env = Zuzu::Env->_new_fast( $self->_env );
	$self->_push_env($env);
	$env->declare( 'm', Zuzu::Value::Array->new( items => $captures ), 1 );
	my $value;
	my $ok = eval {
		$value = $replace_expr->evaluate($self);
		1;
	};
	my $err = $@;
	$self->_pop_env;
	die $err if !$ok;

	return $self->_to_String($value);
}

sub _regexp_replace_value {
	my ( $self, $target, $regex, $global, $replace_expr ) = @_;

	my $out = '';
	my $cursor = 0;
	while ( $target =~ /$regex/g ) {
		my $start = $-[0];
		my $end = $+[0];
		$out .= substr( $target, $cursor, $start - $cursor );
		my @captures = $self->_current_match_values($target);
		$out .= $self->_evaluate_regexp_replace_expr( $replace_expr, \@captures );
		$cursor = $end;
		last if !$global;
	}
	if ( $cursor == 0 and $target !~ /$regex/ ) {
		return $target;
	}
	$out .= substr( $target, $cursor );

	return $out;
}

sub eval_type_ref {
	my ( $self, $node ) = @_;

	my $ref = $self->_env->find_ref($node->root);
	die Zuzu::Error->new_runtime(
		message => "Unknown type root '".$node->root."'",
		file => $node->file,
		line => $node->line,
	) if !$ref;

	my $value = $$ref;
	if ( defined $node->member ) {
		die Zuzu::Error->new_runtime(
			message => "Type root '".$node->root."' does not support member type access",
			file => $node->file,
			line => $node->line,
		) if !blessed($value) or !$value->isa('Zuzu::Value::Dict');
		$value = $value->map->{ $node->member };
	}

	return $value;
}

sub eval_call {
	my ($self, $node) = @_;

	my $callee = $node->callee->evaluate($self);
	my ( $positional, $named, $named_pairs ) = $self->_evaluate_invocation_args( $node->args // [] );

	die Zuzu::Error->new_runtime(message => "Call target is not a function", file => $node->file, line => $node->line)
		if !blessed($callee) or !$callee->isa('Zuzu::Value::Function');

	if ($callee->{_bound_self}) {
		return $self->_call_method(
			$callee,
			$callee->{_bound_self},
			$positional,
			$named,
			$named_pairs,
			$node->file,
			$node->line,
			$node->{_arg_static_types},
		);
	}

	return $self->_call_function(
		$callee,
		$positional,
		$named,
		$named_pairs,
		$node->file,
		$node->line,
		$node->{_arg_static_types},
	);
}

sub eval_member_call {
	my ($self, $node) = @_;

	my $obj = $node->object->evaluate($self);
	my ( $positional, $named, $named_pairs ) = $self->_evaluate_invocation_args( $node->args // [] );
	my ( $array_like, $dict_like, $pairlist_like, $set_like, $bag_like )
		= $self->_builtin_collection_views($obj);

	if (blessed($obj) and $obj->isa('Zuzu::Value::Object')) {
		my $m = $self->_lookup_method($obj->class, $node->method, 0);
		if ( $m ) {
			return $self->_call_method(
				$m,
				$obj,
				$positional,
				$named,
				$named_pairs,
				$node->file,
				$node->line,
				$node->{_arg_static_types},
			);
		}
		if ( $array_like ) {
			die Zuzu::Error->new_runtime(message => "Named arguments are not supported for Array methods", file => $node->file, line => $node->line)
				if _named_pairs_count( $named_pairs );
			return $self->_array_method($array_like, $node->method, $positional, $node->file, $node->line);
		}
		if ( $dict_like ) {
			die Zuzu::Error->new_runtime(message => "Named arguments are not supported for Dict methods", file => $node->file, line => $node->line)
				if _named_pairs_count( $named_pairs );
			return $self->_dict_method($dict_like, $node->method, $positional, $node->file, $node->line);
		}
		if ( $pairlist_like ) {
			die Zuzu::Error->new_runtime(message => "Named arguments are not supported for PairList methods", file => $node->file, line => $node->line)
				if _named_pairs_count( $named_pairs );
			return $self->_pairlist_method( $pairlist_like, $node->method, $positional, $node->file, $node->line );
		}
		if ( $set_like ) {
			die Zuzu::Error->new_runtime(message => "Named arguments are not supported for Set methods", file => $node->file, line => $node->line)
				if _named_pairs_count( $named_pairs );
			return $self->_set_method($set_like, $node->method, $positional, $node->file, $node->line);
		}
		if ( $bag_like ) {
			die Zuzu::Error->new_runtime(message => "Named arguments are not supported for Bag methods", file => $node->file, line => $node->line)
				if _named_pairs_count( $named_pairs );
			return $self->_bag_method($bag_like, $node->method, $positional, $node->file, $node->line);
		}
		die Zuzu::Error->new_runtime(message => "Unknown method '".$node->method."'", file => $node->file, line => $node->line);
	}

	# Minimal method support for Array/Dict: expose a few methods like length/empty/clear/append
	if ( $array_like ) {

		die Zuzu::Error->new_runtime(message => "Named arguments are not supported for Array methods", file => $node->file, line => $node->line)
			if _named_pairs_count( $named_pairs );
		return $self->_array_method($array_like, $node->method, $positional, $node->file, $node->line);
	}
	if ( $dict_like ) {

		die Zuzu::Error->new_runtime(message => "Named arguments are not supported for Dict methods", file => $node->file, line => $node->line)
			if _named_pairs_count( $named_pairs );
		return $self->_dict_method($dict_like, $node->method, $positional, $node->file, $node->line);
	}
	if ( $pairlist_like ) {

		die Zuzu::Error->new_runtime(message => "Named arguments are not supported for PairList methods", file => $node->file, line => $node->line)
			if _named_pairs_count( $named_pairs );
		return $self->_pairlist_method( $pairlist_like, $node->method, $positional, $node->file, $node->line );
	}
	if ( $set_like ) {

		die Zuzu::Error->new_runtime(message => "Named arguments are not supported for Set methods", file => $node->file, line => $node->line)
			if _named_pairs_count( $named_pairs );
		return $self->_set_method($set_like, $node->method, $positional, $node->file, $node->line);
	}
	if ( $bag_like ) {

		die Zuzu::Error->new_runtime(message => "Named arguments are not supported for Bag methods", file => $node->file, line => $node->line)
			if _named_pairs_count( $named_pairs );
		return $self->_bag_method($bag_like, $node->method, $positional, $node->file, $node->line);
	}
	if ( blessed($obj) and $obj->isa('Zuzu::Value::Task') ) {
		my $m = $self->_lookup_method(
			$self->{_builtin_classes}{Task},
			$node->method,
			0,
		);
		die Zuzu::Error->new_runtime(message => "Unknown Task method '".$node->method."'", file => $node->file, line => $node->line) if !$m;

		return $self->_call_method(
			$m,
			$obj,
			$positional,
			$named,
			$named_pairs,
			$node->file,
			$node->line,
			$node->{_arg_static_types},
		);
	}
	if ( blessed($obj) and $obj->isa('Zuzu::Value::Class') ) {
		my $m = $self->_lookup_method($obj, $node->method, 1);
		die Zuzu::Error->new_runtime(message => "Unknown static method '".$node->method."'", file => $node->file, line => $node->line) if !$m;

		return $self->_call_method(
			$m,
			$obj,
			$positional,
			$named,
			$named_pairs,
			$node->file,
			$node->line,
			$node->{_arg_static_types},
		);
	}

	die Zuzu::Error->new_runtime(message => "Unknown object type for member call", file => $node->file, line => $node->line);
}

sub eval_dynamic_member_call {
	my ( $self, $node ) = @_;

	my $method = $node->method_expr->evaluate($self);
	if ( blessed($method) and $method->isa('Zuzu::Value::Function') and $method->{_is_method} ) {
		my $obj = $node->object->evaluate($self);
		my ( $positional, $named, $named_pairs ) = $self->_evaluate_invocation_args( $node->args // [] );
		die Zuzu::Error->new_runtime(message => "Dynamic Method call expects Object receiver", file => $node->file, line => $node->line)
			if !blessed($obj) or !$obj->isa('Zuzu::Value::Object');

		return $self->_call_method(
			$method,
			$obj,
			$positional,
			$named,
			$named_pairs,
			$node->file,
			$node->line,
			$node->{_arg_static_types},
		);
	}
	$method = $self->_to_String($method);
	my $resolved = Zuzu::AST::Expr::MemberCall->new(
		file => $node->file,
		line => $node->line,
		object => $node->object,
		method => $method,
		args => $node->args,
	);

	return $self->eval_member_call($resolved);
}

sub eval_new {
	my ($self, $node) = @_;

	my $class_val = $node->class_expr->evaluate($self);
	die Zuzu::Error->new_runtime(message => "new expects a Class", file => $node->file, line => $node->line)
		if !blessed($class_val) or !$class_val->isa('Zuzu::Value::Class');

	if ( @{ $node->traits // [] } ) {
		my @traits;
		for my $tref ( @{ $node->traits // [] } ) {
			my $trait = $tref->evaluate($self);
			die Zuzu::Error->new_runtime(
				message => "Composed type is not a Trait",
				file => $node->file,
				line => $node->line,
			) if !blessed($trait) or !$trait->isa('Zuzu::Value::Trait');
			push @traits, $trait;
		}
		$class_val = $self->_per_object_trait_class(
			$class_val,
			\@traits,
			$node->file,
			$node->line,
		);
	}

	my ( $positional, $named ) = $self->_evaluate_invocation_args( $node->args // [] );

	my $native_constructor = $self->_native_constructor_for( $class_val );
	if ( $native_constructor ) {
		my $object = $native_constructor->(
			$self,
			$class_val,
			$positional,
			$named,
			$node->file,
			$node->line,
		);

		return $self->_apply_object_lifecycle_hooks(
			$object,
			$class_val,
			$node->file,
			$node->line,
		);
	}

	return $self->_make_instance(
		$class_val,
		$named,
		$node->file,
		$node->line,
		1,
	);
}

sub _per_object_trait_class {
	my ( $self, $base_class, $traits, $file, $line ) = @_;

	my @ids = map { refaddr($_) // 0 } ( $base_class, @{ $traits // [] } );
	my $cache_key = join "\x1f", @ids;
	return $self->{_per_object_trait_class_cache}{$cache_key}
		if exists $self->{_per_object_trait_class_cache}{$cache_key};

	my $capture_env = Zuzu::Env->_new_fast( $self->_env );
	$capture_env->declare(
		'__zuzu_per_object_base',
		$base_class,
		1,
		'Class',
	);
	my @trait_refs;
	for my $i ( 0 .. $#{ $traits // [] } ) {
		my $name = "__zuzu_per_object_trait_$i";
		$capture_env->declare( $name, $traits->[$i], 1, 'Trait' );
		push @trait_refs, Zuzu::AST::Expr::TypeRef->new(
			file => $file,
			line => $line,
			root => $name,
			member => undef,
		);
	}

	my $source_node = Zuzu::AST::Stmt::Class->new(
		file => $file,
		line => $line,
		name => $base_class->name,
		parent => Zuzu::AST::Expr::TypeRef->new(
			file => $file,
			line => $line,
			root => '__zuzu_per_object_base',
			member => undef,
		),
		traits => \@trait_refs,
		fields => [],
		methods => [],
		static_methods => [],
		classes => [],
	);

	my $klass = Zuzu::Value::Class->new(
		name => $base_class->name,
		parent => $base_class,
		traits => [ @{ $traits // [] } ],
		field_specs => [],
		methods => {},
		trait_methods => {},
		static_methods => {},
		nested_classes => {},
		closure_env => $capture_env,
		source_node => $source_node,
	);
	$self->_install_trait_methods_for_class( $klass, $traits );

	$self->{_per_object_trait_class_cache}{$cache_key} = $klass;

	return $klass;
}

sub _make_instance {
	my ( $self, $class_val, $named, $file, $line, $call_build ) = @_;

	my $native_constructor = $self->_native_constructor_for( $class_val );
	die Zuzu::Error->new_runtime(
		message => "make_instance cannot instantiate native class '" . $class_val->name . "'",
		file => $file,
		line => $line,
	) if $native_constructor;

	my ( $slots, $const, $types, $weak ) = $self->_instantiate_slots($class_val);
	for my $k ( keys %{ $named // {} } ) {
		my $declared_type = exists $types->{$k} ? $types->{$k} : 'Any';
		$self->_assert_declared_type(
			$declared_type,
			$named->{$k},
			$file,
			$line,
			$k,
		);
		$const->{$k} = 0 if !exists $const->{$k};
		$types->{$k} = 'Any' if !exists $types->{$k};
		$weak->{$k} = 0 if !exists $weak->{$k};
		store_value( \$slots->{$k}, $named->{$k}, $weak->{$k} );
	}

	my $object = Zuzu::Value::Object->new(
		class => $class_val,
		slots => $slots,
		const => $const,
		types => $types,
		weak => $weak,
	);

	$self->_install_object_demolish_hook( $object, $class_val, $file, $line );
	$self->_call_object_build_hook( $object, $class_val, $file, $line )
		if $call_build;

	return $object;
}

sub _make_instance_without_build {
	my ( $self, $class_val, $named, $file, $line ) = @_;

	die Zuzu::Error->new_runtime(
		message => "make_instance expects a Class",
		file => $file,
		line => $line,
	) if !blessed($class_val) or !$class_val->isa('Zuzu::Value::Class');

	return $self->_make_instance(
		$class_val,
		$named,
		$file,
		$line,
		0,
	);
}

sub _install_object_demolish_hook {
	my ( $self, $object, $class_val, $file, $line ) = @_;

	return $object
		if !blessed($object) or !$object->isa('Zuzu::Value::Object');

	my $demolish = $self->_lookup_method( $class_val, '__demolish__', 0 );
	if ( $demolish ) {
		my $runtime = $self;
		weaken($runtime);
		$object->demolish_hook(
			sub {
				my ( $target ) = @_;
				return if !$runtime;
				local $@;
				eval {
					$runtime->_call_method(
						$demolish,
						$target,
						$EMPTY_ARRAY,
						$EMPTY_HASH,
						$EMPTY_ARRAY,
						$file,
						$line,
					);
					1;
				} or return;
				return;
			}
		);
		push @{ $self->{_demolish_objects} }, $object;
		weaken( $self->{_demolish_objects}[-1] );
	}

	return $object;
}

sub _call_object_build_hook {
	my ( $self, $object, $class_val, $file, $line ) = @_;

	return $object
		if !blessed($object) or !$object->isa('Zuzu::Value::Object');

	my $build = $self->_lookup_method( $class_val, '__build__', 0 );
	if ( $build ) {
		$self->_call_method(
			$build,
			$object,
			$EMPTY_ARRAY,
			$EMPTY_HASH,
			$EMPTY_ARRAY,
			$file,
			$line,
		);
	}

	return $object;
}

sub _apply_object_lifecycle_hooks {
	my ( $self, $object, $class_val, $file, $line ) = @_;

	$self->_install_object_demolish_hook( $object, $class_val, $file, $line );
	$self->_call_object_build_hook( $object, $class_val, $file, $line );

	return $object;
}

sub _evaluate_invocation_args {
	my ( $self, $entries ) = @_;

	my $list = $entries // $EMPTY_ARRAY;
	return ( $EMPTY_ARRAY, $EMPTY_HASH, $EMPTY_ARRAY )
		if scalar @{ $list } == 0;

	my $simple_exprs;
	my $simple_addr = refaddr($list) // 0;
	my $simple_cache = $self->{_simple_invocation_arg_cache} //= {};
	my $simple_cached = $simple_cache->{$simple_addr};
	if (
		defined $simple_cached
		and defined $simple_cached->[0]
		and refaddr( $simple_cached->[0] ) == $simple_addr
	) {
		$simple_exprs = $simple_cached->[1];
	}
	else {
		my @exprs;
		$simple_exprs = \@exprs;
		for my $entry ( @{ $list } ) {
			if ( ref($entry) ne 'ARRAY' or defined $entry->[0] or $entry->[2] ) {
				$simple_exprs = 0;
				last;
			}
			my $expr = $entry->[1];
			if ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Spread') ) {
				$simple_exprs = 0;
				last;
			}
			push @exprs, $expr;
		}
		$simple_cache->{$simple_addr} = [ $list, $simple_exprs ];
		weaken( $simple_cache->{$simple_addr}[0] );
	}
	if ($simple_exprs) {
		my @positional;
		push @positional, $_->evaluate($self) for @{ $simple_exprs };
		return ( \@positional, $EMPTY_HASH, $EMPTY_ARRAY );
	}

	my @positional;
	my $named;
	my $named_pairs;
	for my $entry ( @{ $list } ) {
		my ( $name, $expr );
		my $name_expr;
		my $name_is_expr = 0;
		if ( ref($entry) eq 'ARRAY' ) {
			( $name, $expr, $name_is_expr ) = @{ $entry };
			$name_expr = $name if $name_is_expr;
		}
		else {
			$name = undef;
			$expr = $entry;
		}
		if ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Spread') ) {
			my $value = $expr->expr->evaluate($self);
			my ( $array, $dict, $pairlist ) =
				$self->_builtin_collection_views($value);
			if ( $array ) {
				push @positional, $array->resolved_items;
				next;
			}
			if ( $dict ) {
				$named //= {};
				$named_pairs //= [];
				for my $key ( sort CORE::keys %{ $dict->map } ) {
					my $item = $dict->_value_for_key($key);
					$named->{$key} = $item;
					push @{ $named_pairs }, [ $key, $item ];
				}
				next;
			}
			if ( $pairlist ) {
				$named //= {};
				$named_pairs //= [];
				for ( my $i = 0; $i < @{ $pairlist->list }; $i++ ) {
					my $key = $pairlist->list->[$i][0];
					my $item = $pairlist->_value_at($i);
					$named->{$key} = $item;
					push @{ $named_pairs }, [ $key, $item ];
				}
				next;
			}
			my $type = $self->_type_name($value);
			die Zuzu::Error->new_runtime(
				message => "Spread argument expects Array, Dict, or PairList, got $type",
				file => $expr->file,
				line => $expr->line,
			);
		}
		my $value = $expr->evaluate($self);
		if ( $name_is_expr ) {
			$named //= {};
			$named_pairs //= [];
			my $key_value = $name_expr->evaluate($self);
			$name = $self->_to_String($key_value);
		}
		if ( defined $name ) {
			$named //= {};
			$named_pairs //= [];
			$named->{$name} = $value;
			push @{ $named_pairs }, [ $name, $value ];
		}
		else {
			push @positional, $value;
		}
	}

	return (
		( scalar @positional ? \@positional : $EMPTY_ARRAY ),
		( defined $named ? $named : $EMPTY_HASH ),
		( defined $named_pairs ? $named_pairs : $EMPTY_ARRAY ),
	);
}

sub _native_constructor_for {
	my ( $self, $klass ) = @_;

	my $cur = $klass;
	while ( $cur ) {
		return $cur->native_constructor if $cur->native_constructor;
		$cur = $cur->parent;
	}

	return undef;
}

sub _instantiate_builtin_object {
	my ( $self, $klass, $slots ) = @_;

	my $base = Zuzu::Value::Object->new(
		class => $klass,
		slots => {},
		const => {},
		types => {},
		weak => {},
	);
	for my $key ( sort CORE::keys %{ $slots // {} } ) {
		$base->slots->{$key} = $slots->{$key};
		$base->const->{$key} = 0;
		$base->types->{$key} = 'Any';
		$base->weak->{$key} = 0;
	}

	return $base;
}

sub _class_is_or_descends {
	my ( $self, $klass, $target_name ) = @_;

	return $FALSE if !defined $klass;
	my $target = $self->{_builtin_classes}{$target_name};
	return $FALSE if !defined $target;
	my $cur = $klass;
	while ( $cur ) {
		return $TRUE if $cur == $target;
		$cur = $cur->parent;
	}

	return $FALSE;
}

sub _collection_builtin_kind {
	my ( $self, $klass ) = @_;

	while ($klass) {
		my $kind = $klass->{builtin_kind};
		if ( defined $kind ) {
			for my $collection_kind ( @BUILTIN_COLLECTION_KINDS ) {
				return $kind if $kind eq $collection_kind;
			}
		}
		$klass = $klass->{parent};
	}

	return undef;
}

sub _builtin_collection_views {
	my ( $self, $value ) = @_;

	my $class = ref($value);
	if ($class) {
		return ( $value, undef, undef, undef, undef )
			if $class eq 'Zuzu::Value::Array';
		return ( undef, $value, undef, undef, undef )
			if $class eq 'Zuzu::Value::Dict';
		return ( undef, undef, $value, undef, undef )
			if $class eq 'Zuzu::Value::PairList';
		return ( undef, undef, undef, $value, undef )
			if $class eq 'Zuzu::Value::Set';
		return ( undef, undef, undef, undef, $value )
			if $class eq 'Zuzu::Value::Bag';

		if ( $class eq 'Zuzu::Value::Object' ) {
			my $kind = $self->_collection_builtin_kind( $value->{class} );
			if ( defined $kind ) {
				my $wrapped = $value->{slots}{__value};
				if ( ref($wrapped) eq "Zuzu::Value::$kind" ) {
					return ( $wrapped, undef, undef, undef, undef ) if $kind eq 'Array';
					return ( undef, $wrapped, undef, undef, undef ) if $kind eq 'Dict';
					return ( undef, undef, $wrapped, undef, undef ) if $kind eq 'PairList';
					return ( undef, undef, undef, $wrapped, undef ) if $kind eq 'Set';
					return ( undef, undef, undef, undef, $wrapped ) if $kind eq 'Bag';
				}
			}
		}
	}

	return ( undef, undef, undef, undef, undef );
}

sub _unwrap_builtin_collection {
	my ( $self, $value, $kind ) = @_;

	return $value if blessed($value) and $value->isa("Zuzu::Value::$kind");
	if ( blessed($value) and $value->isa('Zuzu::Value::Object') ) {
		return undef if !$self->_class_is_or_descends( $value->class, $kind );
		my $wrapped = $value->slots->{__value};
		return $wrapped if blessed($wrapped) and $wrapped->isa("Zuzu::Value::$kind");
	}

	return undef;
}

sub _wrap_builtin_if_needed {
	my ( $self, $klass, $value, $kind ) = @_;

	my $base = $self->{_builtin_classes}{$kind};
	return $value if defined $base and $klass == $base;

	return $self->_instantiate_builtin_object(
		$klass,
		{
			__value => $value,
		},
	);
}

sub _normalize_pair_argument {
	my ( $self, $pair, $file, $line, $kind ) = @_;

	if ( blessed($pair) and $pair->isa('Zuzu::Value::Object') and $self->_class_is_or_descends( $pair->class, 'Pair' ) ) {
		$pair = $pair->slots->{pair};
	}
	if ( blessed($pair) and $pair->isa('Zuzu::Value::Array') ) {
		$pair = [ @{ $pair->items } ];
	}
	die Zuzu::Error->new_runtime(
		message => ( $kind // 'Dict' ) . " constructor expects Pair values",
		file => $file,
		line => $line,
	) if ref($pair) ne 'ARRAY' or @{ $pair } < 2;

	return [ ( defined $pair->[0] ? "$pair->[0]" : '' ), $pair->[1] ];
}

sub _array_method {
	my ($self, $arr, $m, $args, $file, $line) = @_;
	$self->_assert_mutable_collection( $arr, $file, $line )
		if $ARRAY_MUTATING_METHOD{$m};

	if ($m eq 'append' || $m eq 'push' || $m eq 'add') { return $arr->push( @$args ); }
	if ($m eq 'push_weak') { return $arr->push_weak( @$args ); }
	if ($m eq 'pop') { return $arr->pop; }
	if ($m eq 'prepend' || $m eq 'unshift') { return $arr->unshift( @$args ); }
	if ($m eq 'unshift_weak') { return $arr->unshift_weak( @$args ); }
	if ($m eq 'shift') { return $arr->shift; }
	if ($m eq 'length') { return $arr->length; }
	if ($m eq 'count') { return $arr->count; }
	if ($m eq 'empty') { return $arr->empty; }
	if ($m eq 'is_empty') { return $arr->is_empty; }
	if ($m eq 'copy') { return $arr->copy; }
	if ($m eq 'to_Array') { return $arr->to_Array; }
	if ($m eq 'get') { return $self->_array_get( $arr, $args, $file, $line ); }
	if ($m eq 'set') { return $self->_array_set( $arr, $args, $file, $line, 0 ); }
	if ($m eq 'set_weak') { return $self->_array_set( $arr, $args, $file, $line, 1 ); }
	if ($m eq 'clear') { return $arr->clear; }
	if ($m eq 'join') { return $self->_array_join( $arr, $args, $file, $line ); }
	if ($m eq 'slice') { return $self->_array_slice( $arr, $args, $file, $line ); }
	if ($m eq 'to_Set') { return $arr->to_Set; }
	if ($m eq 'to_Bag') { return $arr->to_Bag; }
	if ($m eq 'to_Iterator') {
		return $self->_iterator_function_from_items(
			[ $arr->resolved_items ],
			$file,
			$line,
		);
	}
	if ($m eq 'sort') { return $arr->sort( $self->_as_compare_callback( $args->[0], $file, $line ) ); }
	if ($m eq 'sortstr') { return $arr->sortstr; }
	if ($m eq 'sortnum') { return $arr->sortnum; }
	if ($m eq 'reverse') { return $arr->reverse; }
	if ($m eq 'head') {
		$self->_require_method_arity_range( 'Array.head', $args, 0, 1, $file, $line );
		return $arr->head( $args->[0] );
	}
	if ($m eq 'tail') {
		$self->_require_method_arity_range( 'Array.tail', $args, 0, 1, $file, $line );
		return $arr->tail( $args->[0] );
	}
	if ($m eq 'sum') { return $arr->sum; }
	if ($m eq 'product') { return $arr->product; }
	if ($m eq 'shuffle') { return $arr->shuffle; }
	if ($m eq 'sample') {
		$self->_require_method_arity_range( 'Array.sample', $args, 0, 1, $file, $line );
		return $arr->sample( $args->[0] );
	}
	if ($m eq 'contains') { return $arr->contains( $args->[0] ); }
	if ($m eq 'map' || $m eq 'grep' || $m eq 'any' || $m eq 'all' || $m eq 'first' || $m eq 'remove' || $m eq 'first_index' || $m eq 'for_each_value') {
		$self->_require_method_arity( "Array.$m", $args, 1, $file, $line )
			if $m eq 'map' || $m eq 'grep' || $m eq 'any' || $m eq 'all' || $m eq 'first';
		return $arr->map( $self->_as_mapper_callback( $args->[0], $file, $line ) ) if $m eq 'map';
		my $cb = $self->_as_predicate_callback( $args->[0], $file, $line );
		return $arr->grep($cb) if $m eq 'grep';
		return $arr->any($cb) if $m eq 'any';
		return $arr->all($cb) if $m eq 'all';
		return $arr->first($cb) if $m eq 'first';
		return $arr->first_index($cb) if $m eq 'first_index';
		return $arr->for_each_value($cb) if $m eq 'for_each_value';
		return $arr->remove($cb);
	}
	if ($m eq 'reduce' || $m eq 'reductions') {
		my $cb = $self->_as_reducer_callback( $args->[0], $file, $line );
		return $arr->reduce($cb) if $m eq 'reduce';
		return $arr->reductions($cb);
	}
	die Zuzu::Error->new_runtime(message => "Unsupported Array method '$m' (skeleton)", file => $file, line => $line);
}

sub _dict_method {
	my ($self, $d, $m, $args, $file, $line) = @_;
	$self->_assert_mutable_collection( $d, $file, $line )
		if $DICT_MUTATING_METHOD{$m};

	if ($m eq 'keys') {
		return $d->keys;
	}
	if ($m eq 'values') { return $d->values; }
	if ($m eq 'enumerate') { return $self->_dict_enumerate($d); }
	if ($m eq 'has') { return $d->contains_key( $args->[0] ); }
	if ($m eq 'contains') { return $d->contains( $args->[0] ); }
	if ($m eq 'exists') { return $d->exists( $args->[0] ); }
	if ($m eq 'defined') { return $d->defined( $args->[0] ); }
	if ($m eq 'copy') { return $d->copy; }
	if ($m eq 'get') { return $d->get( @$args ); }
	if ($m eq 'add') { return $d->add( @$args ); }
	if ($m eq 'add_weak') { return $d->add_weak( @$args ); }
	if ($m eq 'set') { return $d->set( @$args ); }
	if ($m eq 'set_weak') { return $d->set_weak( @$args ); }
	if ($m eq 'kv') { return $d->kv; }
	if ($m eq 'sorted_keys') { return $d->sorted_keys; }
	if ($m eq 'remove') {
		if ( blessed($args->[0]) and $args->[0]->isa('Zuzu::Value::Function') ) {
			my $cb = $self->_as_predicate_callback( $args->[0], $file, $line );
			return $d->remove( sub {
				my ( $pair ) = @_;
				return $cb->( $self->_make_pair_object( $pair->[0], $pair->[1] ) );
			} );
		}
		return $d->remove( $args->[0] );
	}
	if ($m eq 'length') { return $d->length; }
	if ($m eq 'count') { return $d->count; }
	if ($m eq 'empty') { return $d->empty; }
	if ($m eq 'is_empty') { return $d->is_empty; }
	if ($m eq 'clear') { return $d->clear; }
	if ($m eq 'to_Array') { return $self->_dict_to_array($d); }
	if ($m eq 'to_Iterator') {
		return $self->_iterator_function_from_items(
			[ sort CORE::keys %{ $d->map } ],
			$file,
			$line,
		);
	}
	if ($m eq 'for_each_pair' || $m eq 'for_each_key' || $m eq 'for_each_value') {
		my $cb = $self->_as_mapper_callback( $args->[0], $file, $line );
		return $d->for_each_pair( sub {
			my ( $pair ) = @_;
			return $cb->( $self->_make_pair_object( $pair->[0], $pair->[1] ) );
		} ) if $m eq 'for_each_pair';
		return $d->for_each_key($cb) if $m eq 'for_each_key';
		return $d->for_each_value($cb);
	}
	die Zuzu::Error->new_runtime(message => "Unsupported Dict method '$m' (skeleton)", file => $file, line => $line);
}

sub _pairlist_method {
	my ( $self, $pairlist, $m, $args, $file, $line ) = @_;
	$self->_assert_mutable_collection( $pairlist, $file, $line )
		if $DICT_MUTATING_METHOD{$m};

	if ( $m eq 'keys' ) { return $pairlist->keys; }
	if ( $m eq 'values' ) { return $pairlist->values; }
	if ( $m eq 'enumerate' ) { return $self->_pairlist_enumerate($pairlist); }
	if ( $m eq 'has' ) { return $pairlist->contains_key( $args->[0] ); }
	if ( $m eq 'exists' ) { return $pairlist->exists( $args->[0] ); }
	if ( $m eq 'defined' ) { return $pairlist->defined( $args->[0] ); }
	if ( $m eq 'copy' ) { return $pairlist->copy; }
	if ( $m eq 'get' ) { return $pairlist->get( @{ $args } ); }
	if ( $m eq 'get_all' or $m eq 'all' ) { return $pairlist->get_all( $args->[0] ); }
	if ( $m eq 'add' ) { return $pairlist->add( @{ $args } ); }
	if ( $m eq 'add_weak' ) { return $pairlist->add_weak( @{ $args } ); }
	if ( $m eq 'set' ) { return $pairlist->set( @{ $args } ); }
	if ( $m eq 'set_weak' ) { return $pairlist->set_weak( @{ $args } ); }
	if ( $m eq 'kv' ) { return $pairlist->kv; }
	if ( $m eq 'sorted_keys' ) { return $pairlist->sorted_keys; }
	if ( $m eq 'remove' ) {
		if ( blessed( $args->[0] ) and $args->[0]->isa('Zuzu::Value::Function') ) {
			my $cb = $self->_as_predicate_callback( $args->[0], $file, $line );
			return $pairlist->remove( sub {
				my ( $pair ) = @_;
				return $cb->( $self->_make_pair_object( $pair->[0], $pair->[1] ) );
			} );
		}
		return $pairlist->remove( $args->[0] );
	}
	if ( $m eq 'length' ) { return $pairlist->length; }
	if ( $m eq 'count' ) { return $pairlist->count; }
	if ( $m eq 'empty' ) { return $pairlist->empty; }
	if ( $m eq 'is_empty' ) { return $pairlist->is_empty; }
	if ( $m eq 'clear' ) { return $pairlist->clear; }
	if ( $m eq 'to_Array' ) { return $self->_pairlist_to_array($pairlist); }
	if ( $m eq 'to_Iterator' ) {
		return $self->_iterator_function_from_items(
			[ map { $_->[0] } @{ $pairlist->list } ],
			$file,
			$line,
		);
	}
	if ( $m eq 'for_each_pair' or $m eq 'for_each_key' or $m eq 'for_each_value' ) {
		my $cb = $self->_as_mapper_callback( $args->[0], $file, $line );
		return $pairlist->for_each_pair( sub {
			my ( $pair ) = @_;
			return $cb->( $self->_make_pair_object( $pair->[0], $pair->[1] ) );
		} ) if $m eq 'for_each_pair';
		return $pairlist->for_each_key($cb) if $m eq 'for_each_key';
		return $pairlist->for_each_value($cb);
	}
	die Zuzu::Error->new_runtime(message => "Unsupported PairList method '$m'", file => $file, line => $line);
}

sub _dict_enumerate {
	my ( $self, $dict ) = @_;

	my @pair_objects;
	for my $key ( sort CORE::keys %{ $dict->map } ) {
		my $value = $dict->get($key);
		push @pair_objects, $self->_make_pair_object( $key, $value );
	}

	return Zuzu::Value::Bag->new( items => \@pair_objects );
}

sub _require_method_arity {
	my ( $self, $method, $args, $expected, $file, $line ) = @_;

	die Zuzu::Error->new_runtime(
		message => "$method expects $expected argument"
			. ( $expected == 1 ? '' : 's' ),
		file => $file,
		line => $line,
	) if @{ $args } != $expected;
}

sub _require_method_arity_range {
	my ( $self, $method, $args, $min, $max, $file, $line ) = @_;

	die Zuzu::Error->new_runtime(
		message => "$method expects between $min and $max arguments",
		file => $file,
		line => $line,
	) if @{ $args } < $min or @{ $args } > $max;
}

sub _array_index {
	my ( $self, $arr, $index ) = @_;

	my $idx = 0 + ( $index // 0 );
	$idx += $arr->length if $idx < 0;

	return $idx;
}

sub _array_get {
	my ( $self, $arr, $args, $file, $line ) = @_;

	$self->_require_method_arity_range( 'Array.get', $args, 1, 2, $file, $line );
	my $idx = $self->_array_index( $arr, $args->[0] );

	return $arr->get( $idx, $args->[1] );
}

sub _array_set {
	my ( $self, $arr, $args, $file, $line, $weak ) = @_;

	$self->_require_method_arity( $weak ? 'Array.set_weak' : 'Array.set', $args, 2, $file, $line );
	my $idx = $self->_array_index( $arr, $args->[0] );
	die Zuzu::Error->new_runtime(
		message => 'Array index is out of range',
		file => $file,
		line => $line,
	) if $idx < 0;

	return $weak ? $arr->set_weak( $idx, $args->[1] ) : $arr->set( $idx, $args->[1] );
}

sub _pairlist_enumerate {
	my ( $self, $pairlist ) = @_;

	my @pair_objects;
	for ( my $i = 0; $i < @{ $pairlist->list }; $i++ ) {
		my $pair = $pairlist->list->[$i];
		push @pair_objects, $self->_make_pair_object(
			$pair->[0],
			$pairlist->_value_at($i),
		);
	}

	return Zuzu::Value::Array->new( items => \@pair_objects );
}

sub _array_join {
	my ( $self, $arr, $args, $file, $line ) = @_;

	die Zuzu::Error->new_runtime(
		message => 'Array.join expects one or two arguments',
		file    => $file,
		line    => $line,
	) if @{ $args } < 1 or @{ $args } > 2;

	my $separator = $self->_to_OperatorString( $args->[0], $file, $line );
	my $fallback  = $args->[1];
	my $has_fallback = @{ $args } == 2;
	my $fallback_string;
	my @parts;
	for my $value ( $arr->resolved_items ) {
		my $part = eval { $self->_to_OperatorString( $value, $file, $line ) };
		if ( !defined $part and $@ ) {
			die $@ if !$has_fallback;
			if ( blessed($fallback) and $fallback->isa('Zuzu::Value::Function') ) {
				my $replacement = $self->_await_callback_value(
					$self->_call_function(
						$fallback,
						[ $value ],
						$EMPTY_HASH,
						$EMPTY_ARRAY,
						$file,
						$line,
					),
				);
				$part = $self->_to_OperatorString(
					$replacement,
					$file,
					$line,
				);
			}
			else {
				$fallback_string //=
					$self->_to_OperatorString( $fallback, $file, $line );
				$part = $fallback_string;
			}
		}
		push @parts, $part;
	}

	return join $separator, @parts;
}

sub _array_slice {
	my ( $self, $arr, $args, $file, $line ) = @_;

	die Zuzu::Error->new_runtime(
		message => 'Array.slice expects one or two arguments',
		file    => $file,
		line    => $line,
	) if @{ $args } < 1 or @{ $args } > 2;

	return $arr->slice( @{ $args } );
}

sub _make_pair_object {
	my ( $self, $key, $value ) = @_;

	my $pair_class = $self->{_builtin_classes}{Pair};

	return $self->_instantiate_builtin_object(
		$pair_class,
		{
			pair => Zuzu::Value::Array->new(
				items => [ $key, $value ],
			),
		},
	);
}

sub _dict_to_array {
	my ( $self, $dict ) = @_;

	my @pairs;
	for my $key ( sort CORE::keys %{ $dict->map } ) {
		push @pairs, $self->_make_pair_object( $key, $dict->get($key) );
	}

	return Zuzu::Value::Array->new( items => \@pairs );
}

sub _pairlist_to_array {
	my ( $self, $pairlist ) = @_;

	my @pairs;
	for ( my $i = 0; $i < @{ $pairlist->list }; $i++ ) {
		my $pair = $pairlist->list->[$i];
		push @pairs, $self->_make_pair_object(
			$pair->[0],
			$pairlist->_value_at($i),
		);
	}

	return Zuzu::Value::Array->new( items => \@pairs );
}

sub _set_method {
	my ($self, $set, $m, $args, $file, $line) = @_;
	$self->_assert_mutable_collection( $set, $file, $line )
		if $SET_MUTATING_METHOD{$m};

	if ($m eq 'add' || $m eq 'push') { return $set->add( @$args ); }
	if ($m eq 'add_weak' || $m eq 'push_weak') { return $set->add_weak( @$args ); }
	if ($m eq 'remove') { return $set->remove( $args->[0] ); }
	if ($m eq 'length') { return $set->length; }
	if ($m eq 'count') { return $set->count; }
	if ($m eq 'empty') { return $set->empty; }
	if ($m eq 'is_empty') { return $set->is_empty; }
	if ($m eq 'copy') { return $set->copy; }
	if ($m eq 'clear') { return $set->clear; }
	if ($m eq 'contains') { return $set->contains( $args->[0] ); }
	if ($m eq 'to_Array') { return $set->to_Array; }
	if ($m eq 'to_Bag') { return $set->to_Bag; }
	if ($m eq 'to_Iterator') {
		return $self->_iterator_function_from_items(
			[ $set->resolved_items ],
			$file,
			$line,
		);
	}
	if ($m eq 'union' || $m eq 'intersection' || $m eq 'difference' || $m eq 'symmetric_difference' || $m eq 'is_subset' || $m eq 'is_superset' || $m eq 'is_disjoint' || $m eq 'equals') {
		my $other = $self->_as_set_argument( $args->[0], $file, $line );
		return $set->union($other) if $m eq 'union';
		return $set->intersection($other) if $m eq 'intersection';
		return $set->difference($other) if $m eq 'difference';
		return $set->symmetric_difference($other) if $m eq 'symmetric_difference';
		return $set->is_subset($other) if $m eq 'is_subset';
		return $set->is_superset($other) if $m eq 'is_superset';
		return $set->is_disjoint($other) if $m eq 'is_disjoint';
		return $set->equals($other);
	}
	if ($m eq 'sort') { return $set->sort( $self->_as_compare_callback( $args->[0], $file, $line ) ); }
	if ($m eq 'sortstr') { return $set->sortstr; }
	if ($m eq 'sortnum') { return $set->sortnum; }
	if ($m eq 'map' || $m eq 'grep' || $m eq 'any' || $m eq 'all' || $m eq 'first' || $m eq 'remove_if' || $m eq 'for_each_value') {
		return $set->map( $self->_as_mapper_callback( $args->[0], $file, $line ) ) if $m eq 'map';
		my $cb = $self->_as_predicate_callback( $args->[0], $file, $line );
		return $set->grep($cb) if $m eq 'grep';
		return $set->any($cb) if $m eq 'any';
		return $set->all($cb) if $m eq 'all';
		return $set->first($cb) if $m eq 'first';
		return $set->for_each_value($cb) if $m eq 'for_each_value';
		return $set->remove_if($cb);
	}
	die Zuzu::Error->new_runtime(message => "Unsupported Set method '$m'", file => $file, line => $line);
}

sub _bag_method {
	my ($self, $bag, $m, $args, $file, $line) = @_;
	$self->_assert_mutable_collection( $bag, $file, $line )
		if $BAG_MUTATING_METHOD{$m};

	if ($m eq 'add' || $m eq 'push') { return $bag->add( @$args ); }
	if ($m eq 'add_weak' || $m eq 'push_weak') { return $bag->add_weak( @$args ); }
	if ($m eq 'remove') { return $bag->remove( $args->[0] ); }
	if ($m eq 'remove_first') { return $bag->remove_first( $args->[0] ); }
	if ($m eq 'length') { return $bag->length; }
	if ($m eq 'count') { return $bag->count( @$args ); }
	if ($m eq 'empty') { return $bag->empty; }
	if ($m eq 'is_empty') { return $bag->is_empty; }
	if ($m eq 'copy') { return $bag->copy; }
	if ($m eq 'clear') { return $bag->clear; }
	if ($m eq 'contains') { return $bag->contains( $args->[0] ); }
	if ($m eq 'to_Array') { return $bag->to_Array; }
	if ($m eq 'to_Set') { return $bag->to_Set; }
	if ($m eq 'to_Iterator') {
		return $self->_iterator_function_from_items(
			[ $bag->resolved_items ],
			$file,
			$line,
		);
	}
	if ($m eq 'uniq') { return $bag->uniq; }
	if ($m eq 'sum') { return $bag->sum; }
	if ($m eq 'product') { return $bag->product; }
	if ($m eq 'sort') { return $bag->sort( $self->_as_compare_callback( $args->[0], $file, $line ) ); }
	if ($m eq 'sortstr') { return $bag->sortstr; }
	if ($m eq 'sortnum') { return $bag->sortnum; }
	if ($m eq 'map' || $m eq 'grep' || $m eq 'any' || $m eq 'all' || $m eq 'first' || $m eq 'remove_if' || $m eq 'for_each_value') {
		return $bag->map( $self->_as_mapper_callback( $args->[0], $file, $line ) ) if $m eq 'map';
		my $cb = $self->_as_predicate_callback( $args->[0], $file, $line );
		return $bag->grep($cb) if $m eq 'grep';
		return $bag->any($cb) if $m eq 'any';
		return $bag->all($cb) if $m eq 'all';
		return $bag->first($cb) if $m eq 'first';
		return $bag->for_each_value($cb) if $m eq 'for_each_value';
		return $bag->remove_if($cb);
	}
	die Zuzu::Error->new_runtime(message => "Unsupported Bag method '$m'", file => $file, line => $line);
}

sub _iterator_function_from_items {
	my ( $self, $items, $file, $line ) = @_;

	my @values = @{ $items // [] };
	my $idx = 0;
	my $fn = Zuzu::Value::Function->new(
		name => 'iterator',
		params => [],
		vararg => undef,
		body => undef,
		closure_env => undef,
	);
	$fn->{_native} = sub {
		if ( $idx >= @values ) {
			my $exhausted = $self->_instantiate_builtin_object(
				$self->{_builtin_classes}{ExhaustedException},
				{
					message => 'iterator exhausted',
					file => $file,
					line => $line,
				},
			);
			die {
				_zuzu_throw => 1,
				value => $exhausted,
			};
		}
		my $value = $values[$idx];
		$idx++;
		return $value;
	};

	return $fn;
}

sub _as_mapper_callback {
	my ( $self, $fn, $file, $line ) = @_;

	die Zuzu::Error->new_runtime(
		message => "Collection method expects a function callback",
		file => $file,
		line => $line,
	) if !blessed($fn) or !$fn->isa('Zuzu::Value::Function');

	return sub {
		my ( $item ) = @_;
		return $self->_await_callback_value(
			$self->_call_function(
				$fn,
				[ $item ],
				$EMPTY_HASH,
				$EMPTY_ARRAY,
				$file,
				$line,
			),
		);
	};
}

sub _await_callback_value {
	my ( $self, $value ) = @_;

	return $value->await
		if blessed($value) and $value->isa('Zuzu::Value::Task');
	return $value;
}

sub _as_compare_callback {
	my ( $self, $fn, $file, $line ) = @_;

	die Zuzu::Error->new_runtime(
		message => "Collection sort expects a function callback",
		file => $file,
		line => $line,
	) if !blessed($fn) or !$fn->isa('Zuzu::Value::Function');

	return sub {
		my ( $left, $right ) = @_;
		my $result = $self->_await_callback_value(
			$self->_call_function(
				$fn,
				[ $left, $right ],
				$EMPTY_HASH,
				$EMPTY_ARRAY,
				$file,
				$line,
			),
		);
		return 0 + ( $result // 0 );
	};
}

sub _as_reducer_callback {
	my ( $self, $fn, $file, $line ) = @_;

	die Zuzu::Error->new_runtime(
		message => "Collection reduce expects a function callback",
		file => $file,
		line => $line,
	) if !blessed($fn) or !$fn->isa('Zuzu::Value::Function');

	return sub {
		my ( $left, $right ) = @_;
		return $self->_await_callback_value(
			$self->_call_function(
				$fn,
				[ $left, $right ],
				$EMPTY_HASH,
				$EMPTY_ARRAY,
				$file,
				$line,
			),
		);
	};
}

sub _as_set_argument {
	my ( $self, $value, $file, $line ) = @_;
	my $set = $self->_unwrap_builtin_collection( $value, 'Set' );

	die Zuzu::Error->new_runtime(
		message => "Set method expects a Set argument",
		file => $file,
		line => $line,
	) if ! $set;

	return $set;
}

sub _throw_matches_type {
	my ( $self, $value, $type ) = @_;

	if ( blessed($type) and $type->isa('Zuzu::Value::Class') ) {
		return $self->_value_matches_class( $value, $type );
	}
	if ( blessed($type) and $type->isa('Zuzu::Value::Trait') ) {
		return $FALSE if !blessed($value) or !$value->isa('Zuzu::Value::Object');
		my $klass = $value->class;
		while ($klass) {
			for my $trait ( @{ $klass->traits // [] } ) {
				return $TRUE if $trait == $type;
			}
			$klass = $klass->parent;
		}
		return $FALSE;
	}
	my $type_name = $self->_type_name($value);
	my $target_name = ref($type) ? '' : "$type";

	return $type_name eq $target_name ? $TRUE : $FALSE;
}

sub _class_matches_or_descends {
	my ( $self, $klass, $target ) = @_;

	return $FALSE if !defined $klass;
	return $FALSE if !defined $target;
	my $cur = $klass;
	while ( $cur ) {
		return $TRUE if $cur == $target;
		$cur = $cur->parent;
	}

	return $FALSE;
}

sub _value_matches_class {
	my ( $self, $value, $target ) = @_;

	return $FALSE if !defined $target;
	if ( blessed($value) and $value->isa('Zuzu::Error') ) {
		my $name = 'Exception';
		$name = 'TypeException' if ( $value->message // '' ) =~ /\ATypeException:/;
		my $error_class = $self->{_builtin_classes}{$name};
		return $FALSE if !defined $error_class;
		return $self->_class_matches_or_descends( $error_class, $target );
	}
	if ( blessed($value) and $value->isa('Zuzu::Value::Object') ) {
		return $self->_class_matches_or_descends( $value->class, $target );
	}

	my $type_name = $self->_type_name($value);
	my $value_class = $self->{_builtin_classes}{$type_name};
	return $FALSE if !defined $value_class;

	return $self->_class_matches_or_descends( $value_class, $target );
}

sub _as_predicate_callback {
	my ( $self, $fn, $file, $line ) = @_;
	my $map = $self->_as_mapper_callback( $fn, $file, $line );

	return sub {
		my ( $item ) = @_;
		my $result = $map->( $item );
		return $self->_to_Boolean( $result ) ? $TRUE : $FALSE;
	};
}

sub _to_String {
	my ( $self, $value ) = @_;

	return '' if !defined $value;
	if ( blessed($value) ) {
		if ( $value->isa('Zuzu::Value::BinaryString') ) {
			die Zuzu::Error->new_runtime(
				message => 'TypeException: Cannot implicitly convert BinaryString to String; use to_string(...)',
				file => '<runtime>',
				line => 0,
			);
		}
		if ( $value->isa('Zuzu::Value::Boolean') ) {
			return $value->value ? 'true' : 'false';
		}
		if ( $value->isa('Zuzu::Value::Regexp') ) {
			return $value->to_String;
		}
		if ( $value->isa('Zuzu::Value::Object') ) {
			my $method = $self->_lookup_method( $value->class, 'to_String', 0 );
			if ( $method ) {
				my $result = $self->_call_method(
					$method,
					$value,
					[],
					{},
					[],
					'<runtime>',
					0,
				);
				return $self->_to_String($result);
			}
		}
		if ( my $array = $self->_unwrap_builtin_collection( $value, 'Array' ) ) {
			return '['
				. join( ', ', map { $self->_to_String($_) } $array->resolved_items )
				. ']';
		}
		if ( my $set = $self->_unwrap_builtin_collection( $value, 'Set' ) ) {
			return '<< '
				. join( ', ', map { $self->_to_String($_) } $set->resolved_items )
				. ' >>';
		}
		if ( my $bag = $self->_unwrap_builtin_collection( $value, 'Bag' ) ) {
			return '<<< '
				. join( ', ', map { $self->_to_String($_) } $bag->resolved_items )
				. ' >>>';
		}
		if ( my $dict = $self->_unwrap_builtin_collection( $value, 'Dict' ) ) {
			my @parts = map {
				$_ . ': ' . $self->_to_String( $dict->_value_for_key($_) )
			} sort CORE::keys %{ $dict->map };
			return '{' . join( ', ', @parts ) . '}';
		}
		if (
			my $pairlist =
				$self->_unwrap_builtin_collection( $value, 'PairList' )
		) {
			my @parts;
			for ( my $i = 0; $i < @{ $pairlist->list }; $i++ ) {
				push @parts,
					$pairlist->list->[$i][0] . ': '
					. $self->_to_String( $pairlist->_value_at($i) );
			}
			return '{{' . join( ', ', @parts ) . '}}';
		}
		if ( $value->isa('Zuzu::Value::Function') ) {
			return $value->{_is_method}
				? ( $value->name // '<Method>' )
				: '<Function>';
		}
		if ( $value->isa('Zuzu::Value::Class') ) {
			return '<Class ' . ( $value->name // 'Object' ) . '>';
		}
		if ( $value->isa('Zuzu::Value::Trait') ) {
			return '<Trait ' . ( $value->name // 'Trait' ) . '>';
		}
		if ( $value->isa('Zuzu::Value::Object') ) {
			my $class_name = $value->class ? $value->class->name : 'Object';
			return "[$class_name]";
		}
		if ( $value->can('to_String') ) {
			my $result = $value->to_String;
			return $self->_to_String($result);
		}
	}

	return "$value";
}

sub _to_OperatorString {
	my ( $self, $value, $file, $line ) = @_;

	$file //= '<runtime>';
	$line //= 0;
	return '' if !defined $value;
	if ( blessed($value) ) {
		if ( $value->isa('Zuzu::Value::Boolean') ) {
			return $value->value ? 'true' : 'false';
		}
		if ( $value->isa('Zuzu::Value::Regexp') ) {
			return $value->to_String;
		}
		if ( $value->isa('Zuzu::Value::Object') ) {
			my $method = $self->_lookup_method( $value->class, 'to_String', 0 );
			if ( $method ) {
				my $result = $self->_call_method(
					$method,
					$value,
					[],
					{},
					[],
					$file,
					$line,
				);
				return $self->_to_OperatorString( $result, $file, $line );
			}
		}
		if ( $value->can('to_String') and !$self->_is_zuzu_runtime_value($value) ) {
			my $result = $value->to_String;

			return $self->_to_OperatorString( $result, $file, $line );
		}

		$self->_throw_operator_coercion_error( 'String', $value, $file, $line );
	}
	if ( ref($value) ) {
		$self->_throw_operator_coercion_error( 'String', $value, $file, $line );
	}

	return "$value";
}

sub _to_Number {
	my ( $self, $value, $file, $line ) = @_;

	$file //= '<runtime>';
	$line //= 0;
	return 0 if !defined $value;
	if ( blessed($value) ) {
		if ( $value->isa('Zuzu::Value::Boolean') ) {
			return $value->value ? 1 : 0;
		}
		if ( $value->isa('Zuzu::Value::Object') ) {
			my $method = $self->_lookup_method( $value->class, 'to_Number', 0 );
			if ( $method ) {
				my $result = $self->_call_method(
					$method,
					$value,
					[],
					{},
					[],
					$file,
					$line,
				);

				return $self->_to_Number( $result, $file, $line );
			}
		}
		if ( $value->can('to_Number') and !$self->_is_zuzu_runtime_value($value) ) {
			my $result = $value->to_Number;

			return $self->_to_Number( $result, $file, $line );
		}

		$self->_throw_operator_coercion_error( 'Number', $value, $file, $line );
	}

	if ( !ref($value) ) {
		return 0 + $value if equality_type($value) eq 'Number';
		if ( $self->_is_numeric_string($value) ) {
			# Radix-prefixed strings coerce case-insensitively.
			if ( $value =~ /\A([+-]?)(0[xXbB][0-9A-Fa-f]+|0[oO][0-7]+)\z/ ) {
				my ( $sign, $digits ) = ( $1, $2 );
				$digits =~ s/\A0[oO]/0/;
				my $magnitude = oct( lc $digits );
				return $sign eq '-' ? -$magnitude : $magnitude;
			}
			return 0 + $value;
		}
	}

	$self->_throw_operator_coercion_error( 'Number', $value, $file, $line );
}

sub _to_Boolean {
	my ( $self, $value ) = @_;

	return 0 if !defined $value;
	if ( !ref($value) ) {
		my $type = equality_type($value);
		return 0 if $type eq 'Number' && 0 + $value == 0;
		return 0 if $type eq 'String' && $value eq '';
		return 1;
	}
	if ( blessed($value) ) {
		return $value->{value} ? 1 : 0
			if $value->isa('Zuzu::Value::Boolean');
		if ( $value->isa('Zuzu::Value::Object') ) {
			my $method = $self->_lookup_method( $value->class, 'to_Boolean', 0 );
			if ( $method ) {
				my $result = $self->_call_method( $method, $value, [], {}, [], '<runtime>', 0 );
				return $self->_to_Boolean( $result ) ? 1 : 0;
			}
		}
		if ( $value->can('to_Boolean') ) {
			my $result = $value->to_Boolean;
			return $self->_to_Boolean( $result ) ? 1 : 0;
		}
		return $value->is_truthy ? 1 : 0
			if $value->can('is_truthy');
	}

	return Zuzu::Util::boolify( $value ) ? 1 : 0;
}

sub _is_numeric_string {
	my ( $self, $value ) = @_;

	return 0 if ref($value);
	return 1 if $value =~ /\A[+-]?(?:0[xX][0-9A-Fa-f]+|0[bB][01]+|0[oO][0-7]+)\z/;
	return $value =~ /\A[+-]?(?:(?:\d+(?:\.\d*)?)|(?:\.\d+))(?:[eE][+-]?\d+)?\z/
		? 1
		: 0;
}

sub _is_zuzu_runtime_value {
	my ( $self, $value ) = @_;

	return 0 if !blessed($value);
	return 1 if $value->isa('Zuzu::Value::Array');
	return 1 if $value->isa('Zuzu::Value::Bag');
	return 1 if $value->isa('Zuzu::Value::BinaryString');
	return 1 if $value->isa('Zuzu::Value::Boolean');
	return 1 if $value->isa('Zuzu::Value::Class');
	return 1 if $value->isa('Zuzu::Value::Dict');
	return 1 if $value->isa('Zuzu::Value::Function');
	return 1 if $value->isa('Zuzu::Value::Object');
	return 1 if $value->isa('Zuzu::Value::PairList');
	return 1 if $value->isa('Zuzu::Value::Regexp');
	return 1 if $value->isa('Zuzu::Value::Set');
	return 1 if $value->isa('Zuzu::Value::Task');
	return 1 if $value->isa('Zuzu::Value::Trait');

	return 0;
}

sub _throw_operator_coercion_error {
	my ( $self, $target, $value, $file, $line ) = @_;

	my $type = $self->_type_name($value);
	die Zuzu::Error->new_runtime(
		message => "TypeException: Cannot coerce $type to $target",
		file => $file,
		line => $line,
	);
}

sub _instantiate_slots {
	my ($self, $klass) = @_;

	my ( $slots, $const, $types, $weak ) = $klass->parent
		? $self->_instantiate_slots($klass->parent)
		: ( {}, {}, {}, {} );

	for my $spec (@{ $klass->field_specs // [] }) {
		my $name = $spec->{name};
		my $val = undef;
		if ( defined $spec->{init} ) {
			my $init_env = Zuzu::Env->_new_fast( $klass->closure_env // $self->_env );
			$self->_push_env($init_env);
			my $ok = eval {
				$val = $spec->{init}->evaluate($self);
				1;
			};
			my $err = $@;
			$self->_pop_env;
			die $err if !$ok;
		}
		my $declared_type = $spec->{declared_type} // 'Any';
		if ( defined $spec->{init} ) {
			$self->_assert_declared_type( $declared_type, $val, $klass->name, 0, $name );
		}
		$const->{$name} = $spec->{is_const} ? 1 : 0;
		$types->{$name} = $declared_type;
		$weak->{$name} = $spec->{is_weak_storage} ? 1 : 0;
		store_value( \$slots->{$name}, $val, $weak->{$name} );
	}

	return ($slots, $const, $types, $weak);
}

sub _lookup_method {
	my ($self, $klass, $name, $is_static) = @_;

	my $candidates = $self->_collect_method_candidate_refs( $klass, $name, $is_static );

	return $candidates->[0];
}

sub _collect_method_candidates {
	my ( $self, $klass, $name, $is_static ) = @_;

	my $candidates = $self->_collect_method_candidate_refs( $klass, $name, $is_static );

	return @{ $candidates };
}

sub _collect_method_candidate_refs {
	my ( $self, $klass, $name, $is_static ) = @_;

	return [] if !defined $klass;

	my $klass_key = refaddr( $klass ) // 0;
	my $cache_key = join "\x1f", $klass_key, ( $name // '' ), ( $is_static ? 1 : 0 );
	if ( exists $self->{_method_candidate_cache}{$cache_key} ) {
		return $self->{_method_candidate_cache}{$cache_key};
	}

	my @candidates;
	if ( $is_static ) {
		push @candidates, $klass->static_methods->{ $name }
			if exists $klass->static_methods->{ $name };
	}
	else {
		push @candidates, $klass->methods->{ $name }
			if exists $klass->methods->{ $name };
		if ( exists $klass->trait_methods->{ $name } ) {
			push @candidates, @{ $klass->trait_methods->{ $name } };
		}
	}

	if ( $klass->parent ) {
		push @candidates, @{ $self->_collect_method_candidate_refs(
			$klass->parent,
			$name,
			$is_static,
		) };
	}

	$self->{_method_candidate_cache}{$cache_key} = \@candidates;

	return \@candidates;
}

sub _lookup_next_method {
	my ( $self, $klass, $name, $is_static, $current_fn ) = @_;

	my @candidates = $self->_collect_method_candidates( $klass, $name, $is_static );
	for my $i ( 0 .. $#candidates ) {
		next if $candidates[$i] ne $current_fn;
		return $candidates[ $i + 1 ] if $i < $#candidates;
		last;
	}

	return undef;
}

sub _object_get {
	my ($self, $obj, $key) = @_;

	return slot_value( \$obj->slots->{$key} ) if exists $obj->slots->{$key};

	my $m = $self->_lookup_method($obj->class, $key, 0);
	if ($m) {
		my $obj_key = refaddr( $obj ) // 0;
		my $method_key = join "\x1f", $obj_key, $key;
		my $cache_entry = $self->{_bound_method_cache}{$method_key};
		if ( defined $cache_entry and $cache_entry->{method_ref} == $m ) {
			return $cache_entry->{bound};
		}

		return $self->_bind_method( $obj, $key, $m );
	}

	return $obj->class->nested_classes->{$key} if exists $obj->class->nested_classes->{$key};

	return undef;
}

sub _bind_method {
	my ( $self, $obj, $method_name, $method ) = @_;

	my $obj_key = refaddr( $obj ) // 0;
	my $method_key = join "\x1f", $obj_key, $method_name;
	my $cache_entry = $self->{_bound_method_cache}{$method_key};
	if ( defined $cache_entry and $cache_entry->{method_ref} == $method ) {
		return $cache_entry->{bound};
	}

	my $bound = Zuzu::Value::Function->new(
		name => $method->name,
		params => [ @{ $method->params // [] } ],
		vararg => $method->vararg,
		named_vararg => $method->named_vararg,
		param_types => { %{ $method->param_types // {} } },
		vararg_type => $method->vararg_type // 'Any',
		named_vararg_type => $method->named_vararg_type // 'PairList',
		param_optional => { %{ $method->param_optional // {} } },
		param_defaults => { %{ $method->param_defaults // {} } },
		return_type => $method->return_type // 'Any',
		body => $method->body,
		closure_env => $method->closure_env,
		is_async => $method->is_async ? 1 : 0,
		source_node => $method->source_node,
	);
	$bound->{_default_typecheck_safe} =
		{ %{ $method->{_default_typecheck_safe} // {} } };
	$bound->{_bound_self} = $obj;
	$bound->{_is_method} = 1;
	$bound->{_owner_class} = $method->{_owner_class};
	$bound->{_method_name} = $method->{_method_name} // $method_name;
	$bound->{_method_kind} = $method->{_method_kind} // 'instance';
	$bound->{_uses_super} = $method->{_uses_super};
	$self->{_bound_method_cache}{$method_key} = {
		method_ref => $method,
		bound => $bound,
	};

	return $bound;
}


sub _named_pairs_count {
	my ( $named_pairs ) = @_;

	return 0 if !defined $named_pairs;

	return scalar @{ $named_pairs };
}

sub _call_method {
	my ( $self, $fn, $self_value, $args, $named, $named_pairs, $file, $line, $arg_static_types ) = @_;
	if ( defined $named and ref($named) ne 'HASH' ) {
		$arg_static_types = $line;
		$line = $file;
		$file = $named_pairs;
		$named_pairs = [];
		$named = {};
	}
	$named = $EMPTY_HASH if !defined $named;
	$named_pairs = $EMPTY_ARRAY if !defined $named_pairs;

	if ($fn->{_native}) {
		local $self->{_native_call_file} = $file;
		local $self->{_native_call_line} = $line;
		if ( _named_pairs_count( $named_pairs ) ) {
			die Zuzu::Error->new_runtime(message => "Named arguments are not supported for native methods", file => $file, line => $line)
				if !$fn->{_native_accepts_named};
			return $fn->{_native}->(
				$self_value,
				@$args,
				$named,
				$named_pairs,
			);
		}
		return $fn->{_native}->($self_value, @$args);
	}
	if (
		$fn->is_async
		and (
			!defined $self->{_run_async_fn_ref}
			or $self->{_run_async_fn_ref} != refaddr($fn)
		)
	) {
		my @task_args = @{ $args // [] };
		my %task_named = %{ $named // {} };
		my @task_named_pairs = @{ $named_pairs // [] };
		my @task_arg_static_types = @{ $arg_static_types // [] };
		return $self->_new_task(
			name => $fn->name // '<async-method>',
			schedule => 1,
			file => $file,
			line => $line,
			thunk => sub {
				local $self->{_run_async_fn_ref} = refaddr($fn);
				return $self->_call_method(
					$fn,
					$self_value,
					\@task_args,
					\%task_named,
					\@task_named_pairs,
					$file,
					$line,
					\@task_arg_static_types,
				);
			},
		);
	}

	my $call_env = Zuzu::Env->_new_fast( $fn->{closure_env} );
	push @{$self->{_stack}}, $call_env; # inlined $self->_push_env
	$call_env->declare('self', $self_value, 1);
	if ( !defined $fn->{_uses_super} or $fn->{_uses_super} ) {
		# This path runs for methods that reference super; construct the small
		# native wrapper directly instead of paying Moo constructor/default costs.
		my $super_fn = bless {
			name              => 'super',
			params            => [],
			vararg            => '__super_args',
			named_vararg      => undef,
			param_types       => {},
			vararg_type       => 'Any',
			named_vararg_type => 'PairList',
			param_optional    => {},
			param_defaults    => {},
			return_type       => 'Any',
			body              => undef,
			closure_env       => undef,
			is_async          => 0,
		}, 'Zuzu::Value::Function';
		$super_fn->{_native} = sub {
			my (@super_args) = @_;
			my $owner_class = $fn->{_owner_class};
			my $method_name = $fn->{_method_name};
			my $is_static = $fn->{_method_kind} && $fn->{_method_kind} eq 'static'
				? 1
				: 0;
			my $next = $self->_lookup_next_method(
				$owner_class,
				$method_name,
				$is_static,
				$fn,
			);
			die Zuzu::Error->new_runtime(
				message => "No super method available for '$method_name'",
				file => $file,
				line => $line,
			) if !$next;

			return $self->_call_method( $next, $self_value, \@super_args, $EMPTY_HASH, $EMPTY_ARRAY, $file, $line );
		};
		$call_env->declare( 'super', $super_fn, 1 );
	}

	if (blessed($self_value) and $self_value->isa('Zuzu::Value::Object')) {
		my $slots = $self_value->{slots};
		my $call_slots = $call_env->{slots};
		my $call_const = $call_env->{const};
		my $call_types = $call_env->{types};
		my $call_weak = $call_env->{weak};
		my $self_const = $self_value->{const};
		my $self_types = $self_value->{types};
		my $self_weak = $self_value->{weak};
		for my $name ( CORE::keys %{ $slots } ) {
			$call_slots->{$name} = \$slots->{$name};
			$call_const->{$name} = $self_const->{$name} ? 1 : 0;
			$call_types->{$name} = $self_types->{$name} // 'Any';
			$call_weak->{$name} = $self_weak->{$name} ? 1 : 0;
		}
	}

	my $ret;
	eval {
		$self->_bind_function_params(
			$fn,
			$args,
			$named,
			$named_pairs,
			$call_env,
			$file,
			$line,
			$arg_static_types,
		);
		$ret = $fn->{body}->evaluate($self);
		1;
	} or do {
		my $e = $@;
		pop @{$self->{_stack}}; # inlined $self->_pop_env
		if (ref($e) && ref($e) eq 'Zuzu::Control' && $e->{_control} eq 'return') {
			my $value = $e->{value};
			$self->_assert_return_type( $fn, $value, $file, $line )
				if !$e->{skip_type_check};
			return $value;
		}
		die $e;
	};

	pop @{$self->{_stack}}; # inlined $self->_pop_env
	$self->_assert_return_type( $fn, $ret, $file, $line );

	return $ret;
}

sub _call_function {
	my ( $self, $fn, $args, $named, $named_pairs, $file, $line, $arg_static_types ) = @_;
	if ( defined $named and ref($named) ne 'HASH' ) {
		$arg_static_types = $line;
		$line = $file;
		$file = $named_pairs;
		$named_pairs = [];
		$named = {};
	}
	$named = $EMPTY_HASH if !defined $named;
	$named_pairs = $EMPTY_ARRAY if !defined $named_pairs;

	if ($fn->{_native}) {
		local $self->{_native_call_file} = $file;
		local $self->{_native_call_line} = $line;
		if ( _named_pairs_count( $named_pairs ) ) {
			die Zuzu::Error->new_runtime(message => "Named arguments are not supported for native functions", file => $file, line => $line)
				if !$fn->{_native_accepts_named};
			return $fn->{_native}->( @$args, $named, $named_pairs );
		}
		return $fn->{_native}->(@$args);
	}
	if ( $fn->is_bodyless or !defined $fn->body ) {
		die Zuzu::Error->new_runtime(
			message => "Function '".$fn->name."' has no body",
			file => $file,
			line => $line,
		);
	}
	if (
		$fn->is_async
		and (
			!defined $self->{_run_async_fn_ref}
			or $self->{_run_async_fn_ref} != refaddr($fn)
		)
	) {
		my @task_args = @{ $args // [] };
		my %task_named = %{ $named // {} };
		my @task_named_pairs = @{ $named_pairs // [] };
		my @task_arg_static_types = @{ $arg_static_types // [] };
		return $self->_new_task(
			name => $fn->name // '<async>',
			schedule => 1,
			file => $file,
			line => $line,
			thunk => sub {
				local $self->{_run_async_fn_ref} = refaddr($fn);
				return $self->_call_function(
					$fn,
					\@task_args,
					\%task_named,
					\@task_named_pairs,
					$file,
					$line,
					\@task_arg_static_types,
				);
			},
		);
	}

	my $call_env = Zuzu::Env->_new_fast( $fn->{closure_env} );
	push @{$self->{_stack}}, $call_env; # inlined $self->_push_env

	my $ret;
	eval {
		$self->_bind_function_params(
			$fn,
			$args,
			$named,
			$named_pairs,
			$call_env,
			$file,
			$line,
			$arg_static_types,
		);
		$ret = $fn->{body}->evaluate($self);
		1;
	} or do {
		my $e = $@;
		pop @{$self->{_stack}}; # inlined $self->_pop_env
		if (ref($e) && ref($e) eq 'Zuzu::Control' && $e->{_control} eq 'return') {
			my $value = $e->{value};
			$self->_assert_return_type( $fn, $value, $file, $line )
				if !$e->{skip_type_check};
			return $value;
		}
		die $e;
	};

	pop @{$self->{_stack}}; # inlined $self->_pop_env
	$self->_assert_return_type( $fn, $ret, $file, $line );

	return $ret;
}

sub _assert_return_type {
	my ( $self, $fn, $value, $file, $line ) = @_;

	my $declared_type = $fn->{return_type} // 'Any';
	return if $declared_type eq 'Any';

	my $name = $fn->{name} // '<anon>';
	$self->_assert_declared_type( $declared_type, $value, $file, $line, "return value of '$name'" );

	return;
}

sub _validate_arity {
	my ($self, $fn, $args, $named_pairs, $file, $line, $binding_plan) = @_;

	$binding_plan //= $self->_function_binding_plan($fn);
	my $required = $binding_plan->{required};
	my $given = scalar @{ $args // [] };
	my $total = $binding_plan->{total};
	if ( scalar @{ $named_pairs // [] } and ! $binding_plan->{has_named_vararg} ) {
		die Zuzu::Error->new_runtime(
			message => "Function '".$fn->name."' does not accept named arguments",
			file => $file,
			line => $line,
		);
	}

	if ( $binding_plan->{has_vararg} ) {
		if ( $given < $required ) {
			die Zuzu::Error->new_runtime(
				message => "Too few arguments for function '".$fn->name."' (expected at least $required, got $given)",
				file => $file,
				line => $line,
			);
		}

		return;
	}

	if ( $given < $required || $given > $total ) {
		my $expected = $required == $total
			? "$total"
			: "$required to $total";
		die Zuzu::Error->new_runtime(
			message => "Wrong number of arguments for function '".$fn->name."' (expected $expected, got $given)",
			file => $file,
			line => $line,
		);
	}
}

sub _bind_function_params {
	my ( $self, $fn, $args, $named, $named_pairs, $call_env, $file, $line, $arg_static_types ) = @_;

	my $binding_plan = $self->_function_binding_plan( $fn );
	my $params = $binding_plan->{params};
	my $arg_count = scalar @{ $args // [] };
	if ( $binding_plan->{simple_bind} ) {
		if ( $arg_count != $binding_plan->{total} or scalar @{ $named_pairs // [] } ) {
			$self->_validate_arity( $fn, $args, $named_pairs, $file, $line, $binding_plan );
		}
		my $slots = $call_env->{slots};
		my $const = $call_env->{const};
		my $types = $call_env->{types};
		my $weak = $call_env->{weak};
		die "Internal redeclare __argc__" if exists $slots->{__argc__};

		my @values = ( 0 + $arg_count, @{ $args } );
		$slots->{__argc__} = \$values[0];
		$const->{__argc__} = 1;
		$types->{__argc__} = 'Number';
		$weak->{__argc__} = 0;

		for my $i ( 0 .. $#{ $params } ) {
			my $name = $params->[$i];
			die "Internal redeclare $name" if exists $slots->{$name};
			$slots->{$name} = \$values[ $i + 1 ];
			$const->{$name} = 1;
			$types->{$name} = 'Any';
			$weak->{$name} = 0;
		}

		return;
	}
	$self->_validate_arity( $fn, $args, $named_pairs, $file, $line, $binding_plan );
	$call_env->declare( '__argc__', 0 + $arg_count, 1, 'Number' );

	for my $i ( 0 .. $#{ $params } ) {
		my $name = $params->[$i];
		my $declared_type = $binding_plan->{declared_types}[$i];
		my $has_arg = $i < $arg_count ? 1 : 0;
		my $value;
		if ( $has_arg ) {
			$value = $args->[$i];
			if ( defined $value ) {
				my $static_type = defined $arg_static_types ? $arg_static_types->[$i] : undef;
				my $skip_type_check = defined $static_type && $declared_type eq $static_type ? 1 : 0;
				$self->_assert_declared_type( $declared_type, $value, $file, $line, $name )
					if !$skip_type_check;
			}
		}
		elsif ( $binding_plan->{has_defaults}[$i] ) {
			$value = $binding_plan->{default_exprs}[$i]->evaluate($self);
			if ( defined $value ) {
				my $skip_type_check = $binding_plan->{default_typecheck_safe}[$i] ? 1 : 0;
				$self->_assert_declared_type( $declared_type, $value, $file, $line, $name )
					if !$skip_type_check;
			}
		}
		else {
			$value = undef;
		}
		$call_env->declare( $name, $value, 1, $declared_type );
	}

	if ( defined $fn->vararg ) {
		my $param_count = scalar @{ $params };
		my @rest = @$args[$param_count .. $#$args] if @$args > $param_count;
		my $rest_arr = Zuzu::Value::Array->new(items => \@rest);
		my $declared_type = $fn->vararg_type // 'Any';
		$self->_assert_declared_type( $declared_type, $rest_arr, $file, $line, $fn->vararg );
		$call_env->declare( $fn->vararg, $rest_arr, 1, $declared_type );
	}
	if ( defined $fn->named_vararg ) {
		my @pairs = map { [ $_->[0], $_->[1] ] } @{ $named_pairs // [] };
		my $pairlist = Zuzu::Value::PairList->new( list => \@pairs );
		my $declared_type = $fn->named_vararg_type // 'PairList';
		$self->_assert_declared_type( $declared_type, $pairlist, $file, $line, $fn->named_vararg );
		$call_env->declare( $fn->named_vararg, $pairlist, 1, $declared_type );
	}

	return;
}

sub _function_binding_plan {
	my ( $self, $fn ) = @_;

	my $plan = $fn->{_binding_plan};
	return $plan if defined $plan;

	my @params = @{ $fn->{params} // [] };
	my @declared_types;
	my @has_defaults;
	my @default_exprs;
	my @default_typecheck_safe;
	my $required = 0;
	my $all_types_any = 1;
	my $has_any_default = 0;
	my $param_types = $fn->{param_types} // {};
	my $param_optional = $fn->{param_optional} // {};
	my $param_defaults = $fn->{param_defaults} // {};
	my $default_typecheck_safe = $fn->{_default_typecheck_safe} // {};
	for my $name ( @params ) {
		my $has_default = exists $param_defaults->{$name} ? 1 : 0;
		$has_any_default ||= $has_default;
		my $is_optional = $param_optional->{$name} || $has_default;
		$required++ if !$is_optional;
		my $declared_type = $param_types->{$name} // 'Any';
		$all_types_any = 0 if $declared_type ne 'Any';
		push @declared_types, $declared_type;
		push @has_defaults, $has_default;
		push @default_exprs, $has_default ? $param_defaults->{$name} : undef;
		push @default_typecheck_safe, $default_typecheck_safe->{$name} ? 1 : 0;
	}
	my $has_vararg = defined $fn->{vararg} ? 1 : 0;
	my $has_named_vararg = defined $fn->{named_vararg} ? 1 : 0;

	$plan = {
		params => \@params,
		declared_types => \@declared_types,
		has_defaults => \@has_defaults,
		default_exprs => \@default_exprs,
		default_typecheck_safe => \@default_typecheck_safe,
		required => $required,
		total => scalar @params,
		has_vararg => $has_vararg,
		has_named_vararg => $has_named_vararg,
		simple_bind => (
			$all_types_any
			and !$has_any_default
			and !$has_vararg
			and !$has_named_vararg
			and $required == @params
		) ? 1 : 0,
	};
	$fn->{_binding_plan} = $plan;

	return $plan;
}

# === Module loading ===

sub _module_search_paths {
	my ( $self, $module, $from_file ) = @_;

	my @paths;
	if (
		defined $from_file
		and $from_file ne ''
		and $from_file !~ /\A</
		and $from_file ne '(command line)'
	) {
		my $local_lib = File::Spec->catdir( dirname($from_file), 'lib' );
		push @paths, $local_lib if -d $local_lib;
	}
	push @paths, @{$self->lib // []};

	my %seen;
	@paths = grep { defined $_ and !$seen{$_}++ } @paths;

	return @paths;
}

sub _module_candidates {
	my ( $self, $module, $from_file ) = @_;

	my $lib_key = join "\x1e", @{ $self->lib // [] };
	my $from_key = defined $from_file ? $from_file : '';
	my $cache_key = join "\x1f", $module, $from_key, $lib_key;
	if ( exists $self->{_module_candidate_cache}{$cache_key} ) {
		return @{ $self->{_module_candidate_cache}{$cache_key} };
	}

	my @out;
	if ( File::Spec->file_name_is_absolute($module) or $module =~ /\A\.\.?(?:[\/\\]|\z)/ ) {
		my $base = (
			defined $from_file
			and $from_file ne ''
			and $from_file !~ /\A</
		) ? dirname($from_file) : $INITIAL_CWD;
		my $path = File::Spec->file_name_is_absolute($module)
			? $module
			: File::Spec->catfile( $base, $module );
		@out = ( "$path.zzm", "$path.zzs" );
	}
	else {
		my @paths = $self->_module_search_paths( $module, $from_file );
		@out = map {
			my $base = $_;
			(
				File::Spec->catfile( $base, "$module.zzm" ),
				File::Spec->catfile( $base, "$module.zzs" ),
			);
		} @paths;
	}
	$self->{_module_candidate_cache}{$cache_key} = [ @out ];

	return @out;
}

sub _module_not_found_message {
	my ( $self, $module, $from_file ) = @_;

	return "Cannot find module '$module' in lib paths";
}

sub _refresh_module_builtin_alias_cache {
	my ( $self ) = @_;

	my @aliases;
	my %slot_set;
	for my $k ( sort CORE::keys %{ $self->{_builtin_global_names} } ) {
		my $ref = $self->{_global}{slots}{$k};
		next if !defined $ref;
		$slot_set{$k} = 1;
		push @aliases, [
			$k,
			$ref,
			( $self->{_global}{const}{$k} ? 1 : 0 ),
		];
	}
	$self->{_module_builtin_aliases} = \@aliases;
	$self->{_module_builtin_slot_set} = \%slot_set;

	return;
}

sub _file_value_for_path {
	my ( $self, $path, $force_absolute ) = @_;

	return undef if $self->is_denied( 'fs' );
	return undef if !defined $path or $path eq '' or $path =~ /\A</;
	return undef if $path eq '(command line)';

	my $file_path = $force_absolute
		? File::Spec->rel2abs( $path, $INITIAL_CWD )
		: $path;
	my $module_env = eval { $self->_load_module( 'std/io', $file_path, 0 ) };
	return undef if !defined $module_env;
	my $class_ref = $module_env->find_ref('Path');
	return undef if !defined $class_ref;
	my $path_class = ${ $class_ref };
	return undef
		if !blessed($path_class)
		or !$path_class->isa('Zuzu::Value::Class')
		or !$path_class->native_constructor;

	return $path_class->native_constructor->(
		$self,
		$path_class,
		[ $file_path ],
		{},
		$file_path,
		0,
	);
}

sub _declare_file_const {
	my ( $self, $env, $path, $force_absolute ) = @_;

	return if !defined $env or $env->{slots}{'__file__'};
	$env->declare(
		'__file__',
		$self->_file_value_for_path( $path, $force_absolute ),
		1,
	);

	return;
}

sub _module_path_cache_key {
	my ( $self, $module, $from_file ) = @_;

	my $lib_key = join "\x1e", @{ $self->lib // [] };
	my $from_key = defined $from_file ? $from_file : '';

	return join "\x1f", $module, $from_key, $lib_key;
}

sub _resolve_module_file {
	my ( $self, $module, $from_file ) = @_;

	my $cache_key = $self->_module_path_cache_key( $module, $from_file );
	my $cached = $MODULE_PATH_CACHE{ $cache_key };
	if ( defined $cached and -f $cached ) {
		return $cached;
	}

	for my $cand ( $self->_module_candidates( $module, $from_file ) ) {
		next if !-f $cand;
		$MODULE_PATH_CACHE{ $cache_key } = $cand;
		return $cand;
	}

	delete $MODULE_PATH_CACHE{ $cache_key };

	return undef;
}

sub _persistent_ast_cache_root_path {
	return $PERSISTENT_AST_CACHE_ROOT
		if defined $PERSISTENT_AST_CACHE_ROOT
		and $PERSISTENT_AST_CACHE_ROOT ne '';

	if ( $^O eq 'MSWin32' and defined $ENV{LOCALAPPDATA} and $ENV{LOCALAPPDATA} ne '' ) {
		return File::Spec->catdir( $ENV{LOCALAPPDATA}, 'Zuzu', 'cache', 'zuzu-perl' );
	}

	return File::Spec->catdir( $ENV{HOME}, '.zuzu', 'cache', 'zuzu-perl' )
		if defined $ENV{HOME} and $ENV{HOME} ne '';

	return undef;
}

sub _persistent_ast_cache_root {
	my ( $self ) = @_;

	return undef if !$self->persistent_ast_cache;

	return _persistent_ast_cache_root_path();
}

sub clear_persistent_ast_cache {
	my ( $self ) = @_;

	my $root = _persistent_ast_cache_root_path();
	return if !defined $root or $root eq '' or !-d $root;

	eval {
		opendir my $dh, $root
			or return;
		while ( defined( my $name = readdir $dh ) ) {
			next if $name !~ /(?:\.stor\z|\A\.ast-cache-)/;
			my $path = File::Spec->catfile( $root, $name );
			unlink $path if -f $path;
		}
		closedir $dh;
	};

	return;
}

sub _read_module_source_bytes {
	my ( $self, $path, $file, $line ) = @_;

	open my $fh, '<:raw', $path
		or die Zuzu::Error->new_runtime(
			message => "Cannot open '$path': $!",
			file => $file,
			line => $line,
		);
	local $/;
	my $bytes = <$fh>;
	close $fh;

	return $bytes;
}

sub _persistent_ast_cache_path {
	my ( $self, $module, $path, $source_md5 ) = @_;

	my $root = $self->_persistent_ast_cache_root;
	return if !defined $root or $root eq '';

	my $id = md5_hex(
		join "\x1f",
		$PERSISTENT_AST_CACHE_MAGIC,
		$PERSISTENT_AST_CACHE_VERSION,
		$],
		$module,
		$path,
		$source_md5,
		$self->{_parser}->visitor_cache_key,
	);

	return File::Spec->catfile( $root, "$id.stor" );
}

sub _persistent_ast_cache_load {
	my ( $self, $cache_path, $module, $path, $source_md5, $st ) = @_;

	return if !defined $cache_path or !-f $cache_path;

	if ( ( $PERSISTENT_AST_CACHE_MAX_AGE // 0 ) > 0 ) {
		my @cache_st = stat $cache_path;
		if ( @cache_st and time - ( $cache_st[9] // 0 ) > $PERSISTENT_AST_CACHE_MAX_AGE ) {
			unlink $cache_path;
			return;
		}
	}

	my $entry = eval { retrieve($cache_path) };
	return if $@ or ref($entry) ne 'HASH';

	return if ( $entry->{magic} // '' ) ne $PERSISTENT_AST_CACHE_MAGIC;
	return if ( $entry->{version} // -1 ) != $PERSISTENT_AST_CACHE_VERSION;
	return if ( $entry->{perl_version} // '' ) ne $];
	return if ( $entry->{module} // '' ) ne $module;
	return if ( $entry->{path} // '' ) ne $path;
	return if ( $entry->{source_md5} // '' ) ne $source_md5;
	return if ( $entry->{visitor_key} // '' ) ne $self->{_parser}->visitor_cache_key;
	return if ( $entry->{source_size} // -1 ) != ( $st->[7] // -1 );
	return if ( $entry->{source_mtime} // -1 ) != ( $st->[9] // -1 );

	my $ast = $entry->{ast};
	return
		if !blessed($ast)
		or !$ast->isa('Zuzu::AST::Program');

	eval { utime time, time, $cache_path };

	return $ast;
}

sub _persistent_ast_cache_store {
	my ( $self, $cache_path, $module, $path, $source_md5, $st, $ast ) = @_;

	return if !defined $cache_path;

	my $root = $self->_persistent_ast_cache_root;
	return if !defined $root or $root eq '';

	eval {
		make_path( $root, { mode => 0700 } ) if !-d $root;
		return if !-d $root;

		my ( $tmp_fh, $tmp_path ) = tempfile(
			'.ast-cache-XXXXXX',
			DIR => $root,
			UNLINK => 0,
		);
		close $tmp_fh;

		my $entry = {
			magic => $PERSISTENT_AST_CACHE_MAGIC,
			version => $PERSISTENT_AST_CACHE_VERSION,
			perl_version => $],
			module => $module,
			path => $path,
			source_md5 => $source_md5,
			visitor_key => $self->{_parser}->visitor_cache_key,
			source_size => $st->[7] // -1,
			source_mtime => $st->[9] // -1,
			ast => $ast,
		};

		eval {
			nstore( $entry, $tmp_path );
			chmod 0600, $tmp_path;
			rename $tmp_path, $cache_path
				or die "Cannot rename '$tmp_path' to '$cache_path': $!";
			1;
		} or do {
			unlink $tmp_path if defined $tmp_path and -e $tmp_path;
		};
	};

	return;
}

sub _expire_persistent_ast_cache {
	my ( $self ) = @_;

	return if $PERSISTENT_AST_CACHE_EXPIRY_RAN;
	$PERSISTENT_AST_CACHE_EXPIRY_RAN = 1;

	my $root = $self->_persistent_ast_cache_root;
	return if !defined $root or $root eq '' or !-d $root;

	my $now = time;
	my $max_age = $PERSISTENT_AST_CACHE_MAX_AGE // 0;
	my $max_size = $PERSISTENT_AST_CACHE_MAX_SIZE // 0;

	eval {
		opendir my $dh, $root
			or return;

		my @entries;
		while ( defined( my $name = readdir $dh ) ) {
			next if $name !~ /\.stor\z/;
			my $path = File::Spec->catfile( $root, $name );
			my @st = stat $path;
			next if !@st or !-f _;

			if ( $max_age > 0 and $now - $st[9] > $max_age ) {
				unlink $path;
				next;
			}

			push @entries, [ $path, $st[7] // 0, $st[9] // 0 ];
		}
		closedir $dh;

		return if $max_size <= 0;

		my $total = 0;
		$total += $_->[1] for @entries;
		return if $total <= $max_size;

		for my $entry ( sort { $a->[2] <=> $b->[2] } @entries ) {
			last if $total <= $max_size;
			next if !unlink $entry->[0];
			$total -= $entry->[1];
		}
	};

	return;
}

sub _load_module {
	my ($self, $module, $file, $line) = @_;

	if ( $module =~ m{(?:\A|/)\.\.(?:/|\z)} ) {
		die Zuzu::Error->new_compile(
			message => "Import module path cannot contain '..' segments",
			file => $file,
			line => $line,
		);
	}

	if ( $self->_module_denied_as_missing($module) ) {
		die Zuzu::Error->new_compile(
			message => $self->_module_not_found_message( $module, $file ),
			file => $file,
			line => $line,
		);
	}

	if ( $self->_is_denied_module($module) ) {
		die Zuzu::Error->new_compile(
			message => "Module '$module' is denied by runtime policy",
			file => $file,
			line => $line,
		);
	}

	if ( $self->{_module_loading}{$module} ) {
		die Zuzu::Error->new_runtime(
			message => "Circular module loading detected",
			file => $file,
			line => $line,
		);
	}

	return $self->{_modules}{$module} if $self->{_modules}{$module};
	if ( exists $self->builtin->{$module} ) {
		return $self->_load_builtin_module( $module, $file, $line );
	}

	my $found = $self->_resolve_module_file( $module, $file );
	die Zuzu::Error->new_compile(
		message => $self->_module_not_found_message( $module, $file ),
		file => $file,
		line => $line,
	)
		if !$found;

	my @st = stat $found;
	my $ast_cache_key = join "\x1f",
		$found,
		( defined $st[9] ? $st[9] : -1 ),
		( defined $st[7] ? $st[7] : -1 ),
		$self->{_parser}->visitor_cache_key;
	my $ast = $MODULE_AST_CACHE{$ast_cache_key};
	if ( !defined $ast ) {
		my $source_bytes = $self->_read_module_source_bytes( $found, $file, $line );
		my ( $source_md5, $persistent_cache_path );

		if ( $self->persistent_ast_cache ) {
			$source_md5 = md5_hex($source_bytes);
			$persistent_cache_path = $self->_persistent_ast_cache_path(
				$module,
				$found,
				$source_md5,
			);

			$ast = $self->_persistent_ast_cache_load(
				$persistent_cache_path,
				$module,
				$found,
				$source_md5,
				\@st,
			);
			$self->_expire_persistent_ast_cache if defined $ast;
		}

		if ( !defined $ast ) {
			my $src = eval { decode( 'UTF-8', $source_bytes, FB_CROAK ) };
			die Zuzu::Error->new_compile(
				message => "Cannot decode '$found' as UTF-8: $@",
				file => $file,
				line => $line,
			) if $@;

			$ast = $self->{_parser}->parse($src, $found);
			$self->_persistent_ast_cache_store(
				$persistent_cache_path,
				$module,
				$found,
				$source_md5,
				\@st,
				$ast,
			) if defined $persistent_cache_path;
			$self->_expire_persistent_ast_cache if defined $persistent_cache_path;
		}

		$MODULE_AST_CACHE{$ast_cache_key} = $ast;
	}

	my $mod_env = Zuzu::Env->_new_fast(undef);
	# share builtins by aliasing builtin refs into module env
	for my $alias ( @{ $self->{_module_builtin_aliases} } ) {
		$mod_env->alias_to_ref(
			$alias->[0],
			$alias->[1],
			$alias->[2],
		);
	}
	$self->_declare_file_const( $mod_env, $found, 1 );

	$self->{_module_loading}{$module} = 1;
	$self->{_modules}{$module} = $mod_env;
	my $pre_slots = {
		%{ $self->{_module_builtin_slot_set} // {} },
		__file__ => 1,
	};

	$self->_push_env($mod_env);
	eval { $self->evaluate($ast); 1 } or do {
		my $e = $@;
		$self->_pop_env;
		delete $self->{_module_loading}{$module};
		delete $self->{_modules}{$module};
		delete $self->{_module_exports}{$module};
		die $e;
	};
	$self->_pop_env;
	delete $self->{_module_loading}{$module};

	my %exports = map {
		$_ => 1
	} grep {
		!$pre_slots->{$_}
	} sort CORE::keys %{ $mod_env->{slots} };
	$self->{_module_exports}{$module} = \%exports;

	return $mod_env;
}

sub _module_denied_as_missing {
	my ( $self, $module ) = @_;

	return 1 if $self->is_denied( 'fs' ) and $module =~ m{\Astd/io(?:/|\z)};
	return 1 if $self->is_denied( 'net' ) and $module =~ m{\Astd/net(?:/|\z)};
	return 1 if $self->is_denied( 'net' ) and $module eq 'std/io/socks';
	return 1 if $self->is_denied( 'proc' ) and $module eq 'std/proc';
	return 1 if $self->is_denied( 'db' ) and $module eq 'std/db';
	return 1 if $self->is_denied( 'clib' ) and $module eq 'std/clib';
	return 1 if $self->is_denied( 'js' ) and $module eq 'javascript';
	return 1 if $self->is_denied( 'worker' ) and $module eq 'std/worker';

	return 0;
}

sub _is_denied_module {
	my ( $self, $module ) = @_;

	for my $denied ( @{ $self->deny_modules // [] } ) {
		return 1 if defined $denied and $denied eq $module;
	}

	return 0;
}

sub _load_builtin_module {
	my ( $self, $module, $file, $line ) = @_;

	return $self->{_modules}{$module} if $self->{_modules}{$module};

	my $pkg = $self->builtin->{$module};
	die Zuzu::Error->new_compile(
		message => "Builtin module '$module' has no package mapping",
		file => $file,
		line => $line,
	) if !defined $pkg or $pkg eq '';

	eval "require $pkg; 1" or die Zuzu::Error->new_runtime(
		message => "Failed loading builtin module '$module' ($pkg): $@",
		file => $file,
		line => $line,
	);
	die Zuzu::Error->new_runtime(
		message => "Builtin module '$module' ($pkg) does not provide IMPORT",
		file => $file,
		line => $line,
	) if !$pkg->can('IMPORT');

	my $symbols = $pkg->IMPORT( $self );
	die Zuzu::Error->new_runtime(
		message => "Builtin module '$module' ($pkg) returned non-hashref exports",
		file => $file,
		line => $line,
	) if ref($symbols) ne 'HASH';

	my $mod_env = Zuzu::Env->_new_fast(undef);
	for my $name ( sort CORE::keys %{ $symbols } ) {
		$mod_env->declare( $name, $symbols->{$name}, 1 );
	}

	$self->{_modules}{$module} = $mod_env;
	$self->{_module_exports}{$module} = {
		map { $_ => 1 } sort CORE::keys %{ $symbols }
	};

	return $mod_env;
}

1;

=pod

=head1 NAME

Zuzu::Runtime - interpreter and evaluator for ZuzuScript programs

=head1 DESCRIPTION

Creates runtime state, installs built-ins, and evaluates AST nodes produced by the parser.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 lib

Type: B<ArrayRef[Str]>.

Module search paths used by C<import> resolution.

=head1 METHODS

=head2 new

Constructs and returns a new instance of this class.

=head2 evaluate

Dispatches this AST node to the matching runtime evaluator.

=head2 finish

Runs pending object demolition hooks for a completed runtime.

=head2 call

Invokes a global function by name with arguments.

=head2 eval_program

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_block

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_let

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_assign

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_if

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_while

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_for

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_function_def

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_class_def

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_method_def

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_return

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_next

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_last

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_expr_stmt

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_import

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_literal

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_var

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_array

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_dict

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_index

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_dict_get

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_unary

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_binary

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_call

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_member_call

Evaluates the corresponding AST node kind and returns its runtime value.

=head2 eval_new

Evaluates the corresponding AST node kind and returns its runtime value.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Runtime >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
