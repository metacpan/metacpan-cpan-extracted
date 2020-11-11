use 5.008008;
use strict;
use warnings;

package Zydeco::Lite::App;

use Getopt::Kingpin 0.10;
use Path::Tiny 'path';
use Type::Utils 'english_list';
use Types::Path::Tiny -types;
use Types::Standard -types;
use Zydeco::Lite qw( -all !app );

use parent 'Zydeco::Lite';
use namespace::autoclean;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

our @EXPORT = (
	@Zydeco::Lite::EXPORT,
	qw( arg flag command run ),
);
our @EXPORT_OK = @EXPORT;

sub make_fake_call ($) {
	my $pkg = shift;
	eval "sub { package $pkg; my \$code = shift; &\$code; }";
}

our %THIS;

sub app {
	local $THIS{MY_SPEC} = {};
	
	my $orig = Zydeco::Lite::_pop_type( CodeRef, @_ ) || sub { 1 };
	
	my $commands;
	my $wrapped = sub {
		$orig->( @_ );
		
		while ( my ( $key, $spec ) = each %{ $Zydeco::Lite::THIS{'APP_SPEC'} } ) {
			if ( $key =~ /^(class|role):(.+)$/ ) {
				if ( $spec->{"-IS_COMMAND"} ) {
					( my $cmdname = lc $2 ) =~ s/::/-/g;
					push @{ $spec->{with} ||= [] }, '::Zydeco::Lite::App::Trait::Command';
					$spec->{can}{command_name} ||= sub () { $cmdname };
				}
				if ( $spec->{"-IS_COMMAND"} || $spec->{"-FLAGS"} || $spec->{"-ARGS"} ) {
					my $flags = delete( $spec->{"-FLAGS"} ) || {};
					my $args  = delete( $spec->{"-ARGS"} )  || [];
					push @{ $spec->{symmethod} ||= [] }, (
						_flags_spec => sub { $flags },
						_args_spec  => sub { $args },
					);
				}
				
				delete $spec->{"-IS_COMMAND"};
				delete $spec->{"-FLAGS"};
				delete $spec->{"-ARGS"};
			} #/ if ( $key =~ /^(class|role):(.+)$/)
		} #/ while ( my ( $key, $spec ...))
		
		my $spec = $Zydeco::Lite::THIS{'APP_SPEC'};
		push @{ $spec->{with} ||= [] }, '::Zydeco::Lite::App::Trait::Application';
		$spec->{can}{'commands'} = sub { @{ $commands or [] } }
	};
	
	my $app =
		make_fake_call( caller )->( \&Zydeco::Lite::app, @_, $wrapped ) || $_[0];
	$commands = $THIS{MY_SPEC}{"-COMMANDS"};
	
	return $app;
} #/ sub app

sub flag {
	$Zydeco::Lite::THIS{CLASS_SPEC}
		or Zydeco::Lite::confess( "cannot use `flag` outside a role or class" );
		
	my $name = Zydeco::Lite::_shift_type( Str, @_ )
		or Zydeco::Lite::confess( "flags must have a string name" );
	my %flag_spec = @_ == 1 ? %{ $_[0] } : @_;
	
	my $app   = $Zydeco::Lite::THIS{APP};
	my $class = $Zydeco::Lite::THIS{CLASS};
	$flag_spec{kingpin} ||= sub {
		__PACKAGE__->_kingpin_handle( $app, $class, flag => $name, \%flag_spec, @_ );
	};
	
	$Zydeco::Lite::THIS{CLASS_SPEC}{"-FLAGS"}{$name} = \%flag_spec;
	
	my %spec = %flag_spec;
	delete $spec{short};
	delete $spec{env};
	delete $spec{placeholder};
	delete $spec{hidden};
	delete $spec{kingpin};
	delete $spec{kingpin_type};
	@_ = ( $name, \%spec );
	goto \&Zydeco::Lite::has;
} #/ sub flag

sub arg {
	$Zydeco::Lite::THIS{CLASS_SPEC}
		or Zydeco::Lite::confess( "cannot use `arg` outside a class" );
	
	my $name = Zydeco::Lite::_shift_type( Str, @_ )
		or Zydeco::Lite::confess( "args must have a string name" );
	my %arg_spec = @_ == 1 ? %{ $_[0] } : @_;
	
	my $app   = $Zydeco::Lite::THIS{APP};
	my $class = $Zydeco::Lite::THIS{CLASS};
	$arg_spec{name} = $name;
	$arg_spec{kingpin} ||= sub {
		__PACKAGE__->_kingpin_handle( $app, $class, arg => $name, \%arg_spec, @_ );
	};
	
	push @{ $Zydeco::Lite::THIS{CLASS_SPEC}{"-ARGS"} ||= [] }, \%arg_spec;
	
	return;
} #/ sub arg

sub _kingpin_handle {
	my ( $me, $factory, $class, $kind, $name, $spec, $kingpin ) = ( shift, @_ );
	
	my $flag = $kingpin->$kind(
		$spec->{init_arg}      || $name,
		$spec->{documentation} || 'No description available.',
	);
	
	if ( not ref $spec->{kingpin_type} ) {
	
		my $reg = 'Type::Registry'->for_class( $class );
		$reg->has_parent or $reg->set_parent( 'Type::Registry'->for_class( $factory ) );
		
		my $type =
			$spec->{kingpin_type} ? $reg->lookup( $spec->{kingpin_type} )
			: ref( $spec->{type} or $spec->{isa} ) ? ( $spec->{type} or $spec->{isa} )
			: $spec->{type}                        ? $reg->lookup( $spec->{type} )
			: $spec->{isa} ? $factory->type_library->get_type_for_package(
			$factory->get_class( $spec->{isa} ) )
			: $spec->{does} ? $factory->type_library->get_type_for_package(
			$factory->get_role( $spec->{does} ) )
			: Str;
			
		$spec->{kingpin_type} = $type;
	} #/ if ( not ref $spec->{kingpin_type...})
	
	my $type = $spec->{kingpin_type};
	
	if ( $type <= ArrayRef ) {
		if ( $type->is_parameterized and $type->parent == ArrayRef ) {
			my $type_parameter = $type->type_parameter;
			if ( $type_parameter <= File ) {
				$flag->existing_file_list;
			}
			elsif ( $type_parameter <= Dir ) {
				$flag->existing_dir_list;
			}
			elsif ( $type_parameter <= Path ) {
				$flag->file_list;
			}
			elsif ( $type_parameter <= Int ) {
				$flag->int_list;
			}
			elsif ( $type_parameter <= Num ) {
				$flag->num_list;
			}
			else {
				$flag->string_list;
			}
		} #/ if ( $type->is_parameterized...)
		else {
			$flag->string_list;
		}
	} #/ if ( $type <= ArrayRef)
	elsif ( $type <= HashRef ) {
		if ( $type->is_parameterized and $type->parent == ArrayRef ) {
			my $type_parameter = $type->type_parameter;
			if ( $type_parameter <= File ) {
				$flag->existing_file_hash;
			}
			elsif ( $type_parameter <= Dir ) {
				$flag->existing_dir_hash;
			}
			elsif ( $type_parameter <= Path ) {
				$flag->file_hash;
			}
			elsif ( $type_parameter <= Int ) {
				$flag->int_hash;
			}
			elsif ( $type_parameter <= Num ) {
				$flag->num_hash;
			}
			else {
				$flag->string_hash;
			}
		} #/ if ( $type->is_parameterized...)
		else {
			$flag->string_hash;
		}
		$flag->placeholder( 'KEY=VAL' ) if $flag->can( 'placeholder' );
	} #/ elsif ( $type <= HashRef )
	elsif ( $type <= Bool ) {
		$flag->bool;
	}
	elsif ( $type <= File ) {
		$flag->existing_file;
	}
	elsif ( $type <= Dir ) {
		$flag->existing_dir;
	}
	elsif ( $type <= Path ) {
		$flag->file;
	}
	elsif ( $type <= Int ) {
		$flag->int;
	}
	elsif ( $type <= Num ) {
		$flag->num;
	}
	else {
		$flag->string;
	}
	
	if ( $spec->{required} ) {
		$flag->required;
	}
	
	if ( $spec->{hidden} ) {
		$flag->hidden;
	}
	
	if ( exists $spec->{short} ) {
		$flag->short( $spec->{short} );
	}
	
	if ( exists $spec->{env} ) {
		$flag->override_default_from_envar( $spec->{env} );
	}
	
	if ( exists $spec->{placeholder} ) {
		$flag->placeholder( $spec->{placeholder} );
	}
	
	if ( $kind eq 'arg' ) {
		if ( Types::TypeTiny::CodeLike->check( $spec->{default} ) ) {
			my $cr = $spec->{default};
			
			# For flags, MooX::Press does this prefilling
			if ( blessed $cr and $cr->isa( 'Ask::Question' ) ) {
				$cr->_set_type( $type )                           unless $cr->has_type;
				$cr->_set_text( $spec->{documentation} || $name ) unless $cr->has_text;
				$cr->_set_title( $name )                          unless $cr->has_title;
				$cr->_set_spec( $spec )                           unless $cr->has_spec;
			}
			$flag->default( sub { $cr->( $class ) } );
		} #/ if ( Types::TypeTiny::CodeLike...)
		elsif ( exists $spec->{default} ) {
			$flag->default( $spec->{default} );
		}
		elsif ( my $builder = $spec->{builder} ) {
			$builder = "_build_$name" if is_Int( $builder ) && $builder eq 1;
			$flag->default( sub { $class->$builder } );
		}
	} #/ if ( $kind eq 'arg' )
	
	return $flag;
} #/ sub _kingpin_handle

sub command {
	my $definition = Zydeco::Lite::_pop_type( CodeRef, @_ ) || sub { 1 };
	my $name       = Zydeco::Lite::_shift_type( Str, @_ )
		or Zydeco::Lite::confess( "commands must have a string name" );
	my %args = @_;
	
	Zydeco::Lite::class( $name, %args, $definition );
	
	my $class_spec = $Zydeco::Lite::THIS{APP_SPEC}{"class:$name"};
	$class_spec->{'-IS_COMMAND'} = 1;
	
	push @{ $THIS{MY_SPEC}{"-COMMANDS"} ||= [] }, $name;
	
	return;
} #/ sub command

sub run (&) {
	unshift @_, 'execute';
	goto \&Zydeco::Lite::method;
}

Zydeco::Lite::app( 'Zydeco::Lite::App' => sub {
	
	role 'Trait::Application'
	=> sub {
	
		requires qw( commands );
		
		method '_proto'
		=> sub {
			my ( $proto ) = ( shift );
			ref( $proto ) ? $proto : bless( {}, $proto );
		};
		
		method 'stdio'
		=> sub {
			my ( $app, $in, $out, $err ) = ( shift->_proto, @_ );
			$app->{stdin}  = $in  if $in;
			$app->{stdout} = $out if $out;
			$app->{stderr} = $err if $err;
			$app;
		};
		
		method 'config_file'
		=> sub {
			return;
		};
		
		method 'find_config'
		=> sub {
			my ( $app ) = ( shift->_proto );
			my @files = $app->config_file or return;
			require Perl::OSType;
			my @dirs  = ( path( "." ) );
			if ( Perl::OSType::is_os_type( 'Unix' ) ) {
				push @dirs, path( $ENV{XDG_CONFIG_HOME} || '~/.config' );
				push @dirs, path( '/etc' );
			}
			elsif ( Perl::OSType::is_os_type( 'Windows' ) ) {
				push @dirs,
					map path( $ENV{$_} ),
					grep $ENV{$_},
					qw( LOCALAPPDATA APPDATA PROGRAMDATA );
			}
			my @found;
			for my $dir ( @dirs ) {
				for my $file ( @files ) {
					my $found = $dir->child( "$file" );
					push @found, $found if $found->is_file;
				}
			}
			@found;
		};
			
		method read_config
		=> sub {
			my ( $app ) = ( shift->_proto );
			my @files = @_ ? map( path( $_ ), @_ ) : $app->find_config;
			my %config;
			
			for my $file ( reverse @files ) {
				next unless $file->is_file;
				
				my $this_config = $app->read_single_config($file);				
				while ( my ( $section, $sconfig ) = each %$this_config ) {
					$config{$section} = +{
						%{ $config{$section} or {} },
						%{ $sconfig or {} },
					};
				}
			} #/ for my $file ( reverse ...)
			
			return \%config;
		};
		
		method 'read_single_config'
		=> [ File ]
		=> sub {
			my ( $app, $file ) = ( shift->_proto, @_ );
			
			if ( $file =~ /\.json$/i ) {
				my $decode =
					eval { require JSON::MaybeXS }
					? \&JSON::MaybeXS::decode_json
					: do { require JSON::PP; \&JSON::PP::decode_json };
				return $decode->( $file->slurp_utf8 );
			}
			elsif ( $file =~ /\.ya?ml/i ) {
				my $decode =
					eval { require YAML::XS }
					? \&YAML::XS::LoadFile
					: do { require YAML::PP; \&YAML::PP::LoadFile };
				return $decode->( $file->slurp_utf8 );
			}
			elsif ( $file =~ /\.ini/i ) {
				require Config::Tiny;
				my $cfg = 'Config::Tiny'->read( "$file", 'utf8' );
				$cfg->{'globals'} ||= delete $cfg->{'_'};
				return +{%$cfg};
			}
			else {
				require TOML::Parser;
				my $parser = 'TOML::Parser'->new;
				return $parser->parse_fh( $file->openr_utf8 );
			}			
		};
		
		method 'kingpin'
		=> sub {
			my ( $app ) = ( shift->_proto );
			my $kingpin  = 'Getopt::Kingpin'->new;
			my $config   = $app->read_config;
			my @commands = $app->commands;
			for my $cmd ( @commands ) {
				my $class        = $app->get_class( $cmd ) or next;
				my $cmdname      = $class->command_name    or next;
				my $cmdconfig    = $config->{$cmdname}  || {} or next;
				my $globalconfig = $config->{'globals'} || {} or next;
				$class->kingpin( $kingpin, { %$globalconfig, %$cmdconfig } );
			}
			$kingpin->terminate( sub { $app->exit( $_[1] or 0 ) } );
			return $kingpin;
		};
			
		method 'execute_no_subcommand'
		=> sub {
			my ( $app, @args ) = ( shift->_proto, @_ );
			$app->execute( '--help' );
		};
		
		run {
			my ( $app, @args ) = ( shift->_proto, @_ );
			my $kingpin = $app->kingpin();
			# Shortcut for the case of there only being one real command
			if ( $kingpin->commands->count == 2 ) {
				my @commands = grep $_->name ne 'help', $kingpin->commands->get_all;
				my @realargs = grep !/^-/, @args; # naive, but should be okay
				unless ( @realargs and $realargs[0] eq $commands[0]->name ) {
					unshift @args, $commands[0]->name;
				}
			}
			my $cmd       = $kingpin->parse( @args );
			my $cmd_class = $cmd->{'zylite_app_class'};
			if ( not $cmd_class ) {
				$app->execute_no_subcommand( @args );
			}
			my %flags;
			for my $name ( $cmd->flags->keys ) {
				my $flag = $cmd->flags->get( $name );
				$flag->{'_defined'} or next;
				$flags{$name} = $flag->value;
			}
			my $cmd_object = $cmd_class->new( %flags, _app => $app );
			my @coerced    = do {
				my @values = map $_->value, $cmd->args->get_all;
				my @args   = map @{ $_ or {} }, $cmd_object->_args_spec;
				my @return;
				while ( @values ) {
					my $value = shift @values;
					my $spec  = shift @args;
					if ( $spec->{type} ) {
						$value =
							$spec->{type}->has_coercion
							? $spec->{type}->assert_coerce( $value )
							: $spec->{type}->assert_return( $value );
					}
					push @return, $value;
				} #/ while ( @values )
				@return;
			};
			my $return = $cmd_object->execute( @coerced );
			$app->exit( $return );
		};
		
		method 'exit'
		=> [ Int ]
		=> sub {
			my ( $self, $code ) = ( shift, @_ );
			return CORE::exit( $code );
		};
			
		method 'stdin'
		=> sub {
			my $self = shift;
			ref( $self ) && exists( $self->{stdin} ) ? $self->{stdin} : \*STDIN;
		};
			
		method 'stdout'
		=> sub {
			my $self = shift;
			ref( $self ) && exists( $self->{stdout} ) ? $self->{stdout} : \*STDOUT;
		};
			
		method 'stderr'
		=> sub {
			my $self = shift;
			ref( $self ) && exists( $self->{stderr} ) ? $self->{stderr} : \*STDERR;
		};
			
		method 'readline'
		=> sub {
			my $in   = shift->stdin;
			my $line = <$in>;
			chomp $line;
			return $line;
		};
			
		method 'print'
		=> sub {
			my $self = shift;
			$self->stdout->print( "$_\n" ) for @_;
			return;
		};
		
		method 'debug_mode'
		=> sub {
			return 0;
		};
		
		method 'debug'
		=> sub {
			my $self = shift->_proto;
			return unless $self->debug_mode;
			$self->stderr->print( "$_\n" ) for @_;
			return;
		};
			
		method 'usage'
		=> sub {
			my $self = shift;
			$self->stderr->print( "$_\n" ) for @_;
			$self->exit( 1 );
		};
			
		my %colours = (
			info    => 'bright_blue',
			warn    => 'bold bright_yellow',
			error   => 'bold bright_red',
			fatal   => 'bold bright_red',
			success => 'bold bright_green',
		);
		
		for my $key ( keys %colours ) {
			my $level  = $key;
			my $colour = $colours{$key};
			
			method $level
			=> sub {
				require Term::ANSIColor;
				my $self = shift;
				$self->stderr->print( Term::ANSIColor::colored( "$_\n", $colour ) ) for @_;
				$self->exit( 254 ) if $level eq 'fatal';
				return;
			};
		} #/ for my $key ( keys %colours)
	};
		
	role 'Trait::Command'
	=> sub {
	
		requires qw( _flags_spec _args_spec execute command_name );
			
		has 'app' => (
			is      => 'lazy',
			isa     => ClassName | Object,
			default => sub { shift->FACTORY },
			handles => { map +( $_ => $_ ), qw(
				print debug info warn error fatal usage readline success
			) },
			init_arg => '_app',
		);
		
		has 'config' => (
			is      => 'lazy',
			type    => HashRef,
			builder => sub {
				my $self   = shift;
				my $config = $self->app->read_config;
				my %config = ( %{ $config->{'globals'} or {} },
					%{ $config->{ $self->command_name } or {} } );
				\%config;
			}
		);
		
		method 'documentation'
		=> sub {
			return 'No description available.'
		};
			
		method 'kingpin'
		=> sub {
			my ( $class, $kingpin, $defaults ) = ( shift, @_ );
			
			my $cmd = $kingpin->command( $class->command_name, $class->documentation );
			$cmd->{'zylite_app_class'} = $class;
			
			my %specs = map %{ $_ or {} }, $class->_flags_spec;
			for my $s ( sort keys %specs ) {
				my $spec = $specs{$s};
				my $flag = $spec->{'kingpin'}( $cmd );
				if ( exists $defaults->{ $flag->name } ) {
					$flag->default( $defaults->{ $flag->name } );
				}
			}
			
			my @args = map @{ $_ or {} }, $class->_args_spec;
			for my $spec ( @args ) {
				$spec->{'kingpin'}( $cmd );
			}
			
			return $cmd;
		};
	};
} );

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Zydeco::Lite::App - use Zydeco::Lite to quickly develop command-line apps

=head1 SYNOPSIS

In C<< consumer.pl >>:

  #! perl
  
  use strict;
  use warnings;
  use Zydeco::Lite::App;
  use Types::Standard -types;
  
  app 'MyApp' => sub {
    
    command 'Eat' => sub {
      
      constant documentation => 'Consume some food.';
      
      arg 'foods' => (
        type          => ArrayRef[Str],
        documentation => 'A list of foods.',
      );
      
      run {
        my ( $self, $foods ) = ( shift, @_ );
        $self->info( "Eating $_." ) for @$foods;
        return 0;
      };
    };
    
    command 'Drink' => sub {
      
      constant documentation => 'Consume some drinks.';
      
      arg 'drinks' => (
        type          => ArrayRef[Str],
        documentation => 'A list of drinks.',
      );
      
      run {
        my ( $self, $drinks ) = ( shift, @_ );
        $self->info( "Drinking $_." ) for @$drinks;
        return 0;
      };
    };
  };
  
  'MyApp'->execute( @ARGV );

At the command line:

  $ ./consumer.pl help eat
  usage: consumer.pl eat [<foods>...]
  
  Consume some food.
  
  Flags:
    --help  Show context-sensitive help.
  
  Args:
    [<foods>]  A list of foods.

  $ ./consumer.pl eat pizza chocolate
  Eating pizza.
  Eating chocolate.

=head1 DESCRIPTION

Zydeco::Lite::App extends L<Zydeco::Lite> to redefine the C<app> keyword to
build command-line apps, and add C<command>, C<arg>, C<flag>, and C<run>
keywords.

It assumes your command-line app will have a single level of subcommands, like
many version control and package management tools often do. (You type
C<< git add filename.pl >>, not C<< git filename.pl >>. The C<add> part is
the subcommand.)

It will handle C<< @ARGV >> processing, loading config files, and IO for you.

=head2 C<< app >>

The C<app> keyword exported by Zydeco::Lite::App is a wrapper for the
C<app> keyword provided by L<Zydeco::Lite> which performs additional
processing for the C<command> keyword to associate commands with applications,
and adds the Zydeco::Lite::App::Trait::Application role (a.k.a. the App trait)
to the package it defines.

  # Named application:
  
  app "Local::MyApp", sub {
    ...;   # definition of app
  }
  
  "Local::MyApp"->execute( @ARGV );

  # Anonymous application:
  
  my $app = app sub {
    ...;   # definition of app
  };
  
  $app->execute( @ARGV );

An anonymous application will actually have a package name, but it will be an
automatically generated string of numbers, letters, and punctuation which you
shouldn't rely on being the same from one run to another.

Within the coderef passed to C<app>, you can define roles, classes, and
commands.

The package defined by C<app> will do the App trait.

=head3 The App Trait

=over

=item C<< commands >>

The C<commands> method lists the app's subcommands. Subcommands will each
be a package, typically with a package name that uses the app's package name as
a prefix. So your "add" subcommand might have a package name
"Local::MyApp::Add" and your "add-recursive" subcommand might be called
"Local::MyApp::Add::Recursive".

The C<commands> method will return these packages minus the prefix, so
calling C<< 'Local::MyApp'->commands >> would return a list of strings
including "Add" and "Add::Recursive".

The App trait requires your app package to implement this method, but the
C<app> keyword will provide this method for you, so you don't typially need
to worry about implementing it yourself.

=item C<< execute >>

The C<execute> method is the powerhouse of your app. It takes a list of
command-line parameters, processes them, loads any config files, figures out
which subcommand to run, dispatches to that, and exits.

The App trait implements this method for you and you should probably not
override it.

=item C<< execute_no_subcommand >>

In the case where C<execute> cannot figure out what subcommand to dispatch to,
C<execute_no_subcommand> is called.

The App trait implements this method for you. The default behaviour is to
call C<execute> again, passing it "--help". You can override this behaviour
though, if some other behaviour would be more useful. 

=item C<< stdio >>

Most of the methods in the App trait are okay to be called as either class
methods or instance methods.

  "Local::MyApp"->execute( @ARGV );
  bless( {}, "Local::MyApp" )->execute( @ARGV );

C<stdio> is for calling on an instance though, and will return an instance if
you call it as a class method. The arguments set the filehandles used by the
app for input, output, and error messages.

  my $app = "Local::MyApp"->stdio( $in_fh, $out_fh, $err_fh );
  $app->execite( @ARGV );

=item C<< stdin >>, C<< stdout >>, C<< stderr >>

Accessors which return the handles set by C<stdio>. If no filehandles have been
given, or called as a class method, return STDIN, STDOUT, and STDERR.

=item C<< readline >>

A method for reading input.

C<< $app->readline() >> is a shortcut for C<< $app->stdin->readline() >> but
also calls C<chomp> on the result.

=item C<< print >>, C<< debug >>, C<< usage >>, C<< info >>, C<< warn >>, C<< error >>, C<< fatal >>, C<< success >>

Methods for printing output.

All off them automatically append new lines.

C<print> writes lines to C<< $app->stdout >>.

C<debug> writes lines to C<< $app->stderr >> but only if C<< $app->debug_mode >>
returns true.

C<usage> writes lines to C<< $app->stderr >> and then exits with exit code 1.

C<info> writes lines in blue text to C<< $app->stderr >>.

C<warn> writes lines in yellow text to C<< $app->stderr >>.

C<error> writes lines in red text to C<< $app->stderr >>.

C<fatal> writes lines in red text to C<< $app->stderr >> and then exits with
exit code 254.

C<success> writes lines in green text to C<< $app->stderr >>.

Any of these methods can be overridden in your app if you prefer different
colours or different behaviour.

=item C<< debug_mode >>

This method returns false by default.

You can override it to return true, or do something like this:

  app "Local::MyApp" => sub {
    ...;
    
    method "debug_mode" => sub {
      return $ENV{MYAPP_DEBUG} || 0;
    };
  };

=item C<< config_file >>

Returns the empty list by default.

If you override it to return a list of filenames (not full path names, just
simple filenames like "myapp.json"), your app will use these filenames to
find configuration settings.

=item C<< find_config >>

If C<config_file> returns a non-empty list, this method will check the current
working directory, a user-specific config directory (C<< ~/.config/ >> on
Linux/Unix, another operating systems will vary), and a system-wide config
directory (C<< /etc/ >> on Linux/Unix), and return a list of config files found
in those directories as L<Path::Tiny> objects.

=item C<< read_config >>

If given a list of Path::Tiny objects, will read each file as a config file
and attempt to merge the results into a single hashref, which it will return.

If an empty list is given, will call C<find_config> to get a list of Path::Tiny
objects.

This allows your system-wide config in C<< /etc/myapp.json >> to be overridden
by user-specific C<< ~/.config/myapp.json >> and a local C<< ./myapp.json >>.

You should rarely need to call this manually. (The C<execute> method will call
it as needed and pass any relevant configuration to the subcommand that it
dispatches to.) It may sometimes be useful to override it if you need to
support a different way of merging configuration data from multiple files,
or if you need to be able to read configuration data from a non-file source.

=item C<< read_single_config >>

Helper method called by C<read_config>.

Determines config file type by the last part of the filename. Understands
JSON, INI, YAML, and TOML, and will assume TOML if the file type cannot be
determined from its name.

Config::Tiny and YAML::XS or YAML::PP are required for reading those file
types, but are not included in Zydeco::Lite::App's list of dependencies.
TOML is the generally recommended file format for apps created with this
module.

This method may be useful to override if you need to be able to handle other
file types.

=item C<< kingpin >>

Returns a L<Getopt::Kingpin> object populated with everything necessary to
perform command-line processing for this app.

You will rarely need to call this manually or override it.

=item C<< exit >>

Passed an integer, exits with that exit code.

You may want to override this if you wish to perform some cleanup on exit.

=back

=head2 C<< command >>

The C<command> keyword is used to define a subcommand for your app. An app
should have one or more subcommands. It is a wrapper for the C<class> keyword
exported by L<Zydeco::Lite>.

The C<command> keyword adds the Zydeco::Lite::App::Trait::Command role
(a.k.a. the Command trait) to the class it defines.

Commands may have zero or more args and flags. Args are (roughly speaking)
positional parameters, passed to the command's C<execute> method, while flags
are named arguments passed the the command's constructor.

=head3 The Command Trait

=over

=item C<< command_name >>

The Command trait requires your class to implement the C<command_name> method.
However, the C<command> keyword will provide a default implementation for you
if you have not. The default implementation uses the class name of the command
(minus its app prefix), lowercases it, and replaces "::" with "-".

So given the example:

  app "MyApp::Local", sub {
    command "Add::Recursive", sub {
      run { ... };
    };
  };

The package name of the command will be "MyApp::Local::Add::Recursive", and
the command name will be "add-recursive".

=item C<< documentation >>

This method is called to get a brief one-line description of the command.

  app "MyApp::Local", sub {
    command "Add::Recursive", sub {
      
      method "documentation" => sub {
        return "Adds a directory recursively.";
      };
      
      run { ... };
    };
  };

You may prefer to use C<constant> to define this method in your command class. 

  app "MyApp::Local", sub {
    command "Add::Recursive", sub {
      
      constant "documentation" => "Adds a directory recursively.";
      
      run { ... };
    };
  };

See L<Zydeco::Lite> for more information on the C<method> and C<constant>
keywords.

=item C<< execute >>

Each subcommand is required to implement an C<execute> method.

  app "MyApp::Local", sub {
    command "Add::Recursive", sub {
      
      method "execute" => sub {
        ...;
      };
    };
  };

The subcommand's C<execute> method is called by the app's C<execute> method.
It is passed the subcommand object (C<< $self >>) followed by any command-line
arguments that were given, which may have been coerced. (See L</arg>.)

It should return the application's exit code; usually 0 for a successful
execution, and an integer from 1 to 255 if unsuccessful.

The C<run> keyword provides a helpful shortcut for defining the C<execute>
method. (See L</run>.)

=item C<< app >>

Returns the app as an object or package name.

  app "MyApp::Local", sub {
    command "Add::Recursive", sub {
      
      method "execute" => sub {
        my ( $self, @args ) = ( shift, @_ );
        ...;
        $self->app->success( "Done!" );
        $self->app->exit( 0 );
      };
    };
  };

The C<print>, C<debug>, C<info>, C<warn>, C<error>, C<fatal>, C<usage>,
C<success>, and C<readline> methods are delegated to C<app>, so
C<< $self->app->success(...) >> can just be written as
C<< $self->success(...) >>.

=item C<< config >>

Returns the config section as a hashref for this subcommand only.

So for example, if myapp.json had:

  {
    "globals": { "foo": 1, "bar": 2 },
    "bumpf": { "bar": 3, "bat": 999 },
    "quuux": { "bar": 4, "baz": 5 }
  }

Then the Quuux command would see the following config:

  {
    "foo" => 1,
    "bar" => 4,
    "baz" => 5,
  }

The C<globals> section in a config is special and gets copied to all commands.

=item C<< kingpin >>

Utility method used by the app's C<kingpin> method to add a
L<Getopt::Kingpin::Command> object for processing this subcommand's arguments.
You are unlikely to need to override this method or call it directly.

=back

=head2 C<< arg >>

Defines a command-line argument for a subcommand.

  use Zydeco::Lite::App;
  use Types::Path::Tiny -types;
  
  app "Local::MyApp" => sub {
    command "Add" => sub {
      
      arg 'filename' => ( type => File, required => 1 );
      
      run {
        my ( $self, $file ) = ( shift, @_ );
        ...;
      };
    };
  };

Arguments are ordered and are passed on the command line like follows:

  $ ./myapp.pl add myfile.txt

The C<arg> keyword acts a lot like L<Zydeco::Lite>'s C<has> keyword.

It supports the following options for an argument:

=over

=item C<< type >>

The type constraint for the argument. The following types (from
L<Types::Standard> and L<Types::Path::Tiny>) are supported:
B<Int>, B<Num>, B<Str>, B<File>, B<Dir>, B<Path>, 
B<< ArrayRef[Int] >>, B<< ArrayRef[Num] >>, B<< ArrayRef[Str] >>,
B<< ArrayRef[File] >>, B<< ArrayRef[Dir] >>, B<< ArrayRef[Path] >>,
B<< HashRef[Int] >>, B<< HashRef[Num] >>, B<< HashRef[Str] >>,
B<< HashRef[File] >>, B<< HashRef[Dir] >>, B<< HashRef[Path] >>,
as well as any custom type constraint which can be coerced from strings.

HashRef types are passed on the command line like:

  ./myapp.pl somecommand key1=value1 key2=value2

=item C<< kingpin_type >>

In cases where C<type> is a custom type constraint and Zydeco::Lite::App
cannot figure out what to do with it, you can set C<kingpin_type> to be
one of the above supported types to act as a hint about how to process it.

=item C<< required >>

A boolean indicating whether the argument is required. (Optional otherwise.)
Optional arguments may be better as a L</flag>.

=item C<< documentation >>

A one-line description of the argument.

=item C<< placeholder >>

A string to use as a placeholder value for the argument in help text.

=item C<< default >>

A non-reference default value for the argument, or a coderef that when called
will generate a default value (which may be a reference).

=item C<< env >>

An environment variable which will override the default value if it is given.

=back

Arguments don't need to be defined directly within a command. It is possible
for a command to "inherit" arguments from a role or parent class, but this is
usually undesirable as it may lead to their order being hard to predict.

=head2 C<< flag >>

Flags are command-line options which are passed as C<< --someopt >> on the
command line.

  use Zydeco::Lite::App;
  use Types::Path::Tiny -types;

  app "Local::MyApp" => sub {
    command "Add" => sub {
    
      arg 'filename' => ( type => File, required => 1 );
      
      flag 'logfile' => (
        init_arg => 'log',
        type     => File,
        handles  => { 'append_log' => 'append' },
        default  => sub { Path::Tiny::path('log.txt') },
      );
      
      run {
        my ( $self, $file ) = ( shift, @_ );
        $self->append_log( "Starting work...\n" );
        ...;
      };
    };
  };

This would be called as:

  ./myapp.pl add --log=log2.txt filename.txt

The C<flag> keyword is a wrapper around the C<has> keyword, so supports all
the options supported by C<has> such as C<predicate>, C<handles>, etc.
It also supports all the options described for L</arg> such as C<env> and
C<placeholder>. Additionally there is a C<short> option, allowing for short,
single-letter flag aliases:

  flag 'logfile' => (
    init_arg => 'log',
    type     => File,
    short    => 'L',
  );

Instead of being initialized using command-line arguments, flags can also be
initialized in the application's config file. Flags given on the command line
override flags in the config files; flags given in config files override those
given by environment variables; environment variables override defaults.

Like args, flags can be defined in a parent class or a role. It can be helpful
to define common flags in a role.

=head2 C<< run >>

The C<run> keyword just defines a method called "execute". The following are
equivalent:

  run { ... };
  method 'execute' => sub { ... };

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Zydeco-Lite-App>.

=head1 SEE ALSO

This module extends L<Zydeco::Lite> to add support for rapid development of
command-line apps.

L<Z::App> is a shortcut for importing this module plus a collection of others
that might be useful to you, including type constraint libraries, L<strict>,
L<warnings>, etc.

L<Getopt::Kingpin> is used for processing command-line arguments.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
