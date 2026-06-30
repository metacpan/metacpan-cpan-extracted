package Zuzu::CLI;

use utf8;
use strict;
use warnings;

our $VERSION = '0.007001';

use Scalar::Util qw( blessed );
use Getopt::Long qw(
	Configure
	GetOptionsFromArray
);

use Zuzu;
use Zuzu::Lexer;
use Zuzu::Parser;
use Zuzu::Parser::_Impl;
use Zuzu::Runtime;
use Zuzu::Util;
use Zuzu::Value::Array;

sub run {
	my ( @argv ) = @_;
	@argv = @ARGV if ! @argv;

	binmode(*STDOUT, ':utf8');
	binmode(*STDERR, ':utf8');

	my ( $options, $args, $usage_error ) = _parse_options( \@argv );
	if ( defined $usage_error ) {
		_print_usage($usage_error);
		return 2;
	}

	my ( $deny, $deny_module_list, $preload, $disabled_visitors, $value_error )
		= _normalize_option_lists($options);
	if ( defined $value_error ) {
		_print_usage($value_error);
		return 2;
	}
	$options->{disabled_visitors} = $disabled_visitors;

	Zuzu::Runtime->clear_persistent_ast_cache if $options->{clear_cache};

	if ( $options->{show_version} or $options->{show_version_verbose} ) {
		_print_version( $options, $deny, $deny_module_list );
		return 0;
	}

	my ( $script, $source, $script_error ) = _prepare_source(
		$options,
		$args,
		$preload,
	);
	if ( defined $script_error ) {
		_print_usage($script_error);
		return 2;
	}

	$Zuzu::Runtime::DEBUG_LEVEL = $options->{debug_level};
	$ENV{ZUZU_DEBUG_LEVEL} = $options->{debug_level};

	my $runtime = Zuzu::Runtime->new(
		lib => [ @{ $options->{include_dirs} }, @Zuzu::Runtime::DEFAULT_LIB ],
		deny => $deny,
		deny_modules => $deny_module_list,
		persistent_ast_cache => !$options->{no_cache},
		disabled_visitors => $disabled_visitors,
	);

	if ( $options->{repl_mode} ) {
		_run_repl($runtime);
		return 0;
	}

	my $parser = Zuzu::Parser->new( disabled_visitors => $disabled_visitors );
	my $ok = eval {
		my $ast = $parser->parse( $source, $script );
		$runtime->evaluate($ast);

		if ( $runtime->has_function('__main__') ) {
			my $call_args = Zuzu::Value::Array->new( items => [ @$args ] );
			if ( $runtime->function_is_async('__main__') ) {
				$runtime->call( '__main__', $call_args );
			}
			else {
				$runtime->call_unawaited( '__main__', $call_args );
			}
		}
		1;
	};
	if ( ! $ok ) {
		my $err = $@;
		if ( ref($err) eq 'HASH' and $err->{_zuzu_throw} ) {
			my $value = defined $err->{value} ? $err->{value} : '';
			my $text = _render_thrown_value( $runtime, $value );
			print STDERR "$text\n";
			$runtime->finish;
			return 255;
		}
		$runtime->finish;
		die $err;
	}

	$runtime->finish;

	return 0;
}

sub _parse_options {
	my ( $argv ) = @_;

	my $options = {
		debug_level => 0,
		include_dirs => [],
		deny_capabilities => [],
		deny_modules => [],
		inline_snippets => [],
		preload_modules => [],
		no_visitors => [],
		no_cache => 0,
		clear_cache => 0,
		repl_mode => 0,
		show_version => 0,
		show_version_verbose => 0,
	};
	my $debug_opt;

	Configure(
		'no_ignore_case',
		'bundling',
		'require_order',
	);
	my $ok = GetOptionsFromArray(
		$argv,
		'd:i' => \$debug_opt,
		'I=s@' => $options->{include_dirs},
		'deny=s@' => $options->{deny_capabilities},
		'denymodule=s@' => $options->{deny_modules},
		'no-visitor=s@' => $options->{no_visitors},
		'e=s@' => $options->{inline_snippets},
		'M=s@' => $options->{preload_modules},
		'no-cache' => \$options->{no_cache},
		'clear-cache' => \$options->{clear_cache},
		'R|repl' => \$options->{repl_mode},
		'h|help' => \$options->{show_help},
		'v' => \$options->{show_version},
		'V' => \$options->{show_version_verbose},
	);
	if ( ! $ok ) {
		return ( undef, undef, undef );
	}

	if ( $options->{show_help} ) {
		return ( undef, undef, '' );
	}

	if ( defined $debug_opt ) {
		$debug_opt = 1 if $debug_opt eq '';
		return ( undef, undef, 'Debug level must be a non-negative integer' )
			if $debug_opt !~ /\A(?:0|[1-9][0-9]*)\z/;
		$options->{debug_level} = 0 + $debug_opt;
	}

	return ( $options, $argv, undef );
}

sub _normalize_option_lists {
	my ( $options ) = @_;

	my @deny = _flatten_trimmed_csv( @{ $options->{deny_capabilities} } );
	my @deny_module_list = _flatten_trimmed_csv( @{ $options->{deny_modules} } );
	my @preload = _flatten_trimmed_csv( @{ $options->{preload_modules} } );
	my @disabled_visitors = _flatten_trimmed_csv( @{ $options->{no_visitors} } );

	for my $entry ( @deny, @deny_module_list, @preload, @disabled_visitors ) {
		if ( $entry =~ /\A\s*\z/ ) {
			return ( undef, undef, undef, undef, 'Option values may not contain whitespace only' );
		}
	}

	my @known_visitors;
	eval {
		@known_visitors = Zuzu::Parser->normalize_disabled_visitors(
			@disabled_visitors,
		);
		1;
	} or do {
		my $error = $@;
		chomp $error;
		$error =~ s/ at \S+ line \d+\.?\z//;
		return ( undef, undef, undef, undef, $error );
	};

	return ( \@deny, \@deny_module_list, \@preload, \@known_visitors, undef );
}

sub _flatten_trimmed_csv {
	my ( @raw ) = @_;

	my @values = map {
		s/^\s+//r =~ s/\s+$//r
	} grep {
		defined $_ and $_ ne ''
	} map {
		split /,/
	} @raw;

	return @values;
}

sub _prepare_source {
	my ( $options, $args, $preload ) = @_;

	if ( $options->{repl_mode} ) {
		if ( @{ $options->{inline_snippets} } ) {
			return ( undef, undef, '-R/--repl cannot be combined with -e snippets' );
		}
		if ( @$args ) {
			return ( undef, undef, '-R/--repl does not accept a script path or argv values' );
		}
		return ( undef, undef, undef );
	}

	if ( @{ $options->{inline_snippets} } ) {
		my @prelude = map {
			"from $_ import *;"
		} @$preload;
		my $source = join "\n", @prelude, @{ $options->{inline_snippets} };
		return ( '(command line)', $source, undef );
	}

	my $script = shift @$args;
	if ( ! defined $script ) {
		return ( undef, undef, '' );
	}

	open my $fh, '<:encoding(UTF-8)', $script
		or die "Could not open '$script': $!\n";
	my $source = do { local $/; <$fh> };
	close $fh;

	if ( @$preload ) {
		my @prelude = map {
			"from $_ import *;"
		} @$preload;
		$source = join "\n", @prelude, $source;
	}

	return ( $script, $source, undef );
}

sub _print_usage {
	my ( $message ) = @_;

	if ( defined $message and $message ne '' ) {
		print STDERR $message, "\n";
	}
	print STDERR "Usage: zuzu.pl [options] path/to/script.zzs [arg ...]\n";
	print STDERR "       zuzu.pl [options] -e 'code' [arg ...]\n";
	print STDERR "Options:\n";
	print STDERR "  -d[=N]                 set debug level (default: 1 if omitted)\n";
	print STDERR "  -I/path/to/lib         add module include directory\n";
	print STDERR "  --deny=CAP             deny runtime capability (repeatable)\n";
	print STDERR "  --denymodule=MODULE    deny a specific module (repeatable)\n";
	print STDERR "  --no-visitor=NAME      disable an AST visitor (repeatable)\n";
	print STDERR "  -e 'code'              evaluate inline code (repeatable)\n";
	print STDERR "  -Mmodule               preload module with wildcard import\n";
	print STDERR "  --no-cache             disable the persistent module AST cache\n";
	print STDERR "  --clear-cache          clear the persistent module AST cache before running\n";
	print STDERR "  -R, --repl             start interactive REPL shell\n";
	print STDERR "  -h, --help             show this help\n";
	print STDERR "  -v                     print version\n";
	print STDERR "  -V                     print verbose version details\n";

	return;
}

sub _print_version {
	my ( $options, $deny, $deny_module_list ) = @_;

	my $runtime = Zuzu::Runtime->new(
		lib => [ @{ $options->{include_dirs} }, @Zuzu::Runtime::DEFAULT_LIB ],
		deny => $deny,
		deny_modules => $deny_module_list,
		persistent_ast_cache => !$options->{no_cache},
		disabled_visitors => $options->{disabled_visitors} // [],
	);

	print "zuzu.pl version $Zuzu::VERSION\n";
	if ( $options->{show_version_verbose} ) {
		print "\n";
		print "lib search paths:\n";
		for my $path ( @{ $runtime->lib } ) {
			print "  $path\n";
		}
		print "\n";
		print "builtin modules:\n";
		for my $module ( sort keys %{ $runtime->builtin } ) {
			print "  $module\n";
		}
	}

	return;
}

sub _repl_print_prompt {
	my ( $continuation ) = @_;

	print STDOUT _repl_prompt_coloured($continuation);

	return;
}

sub _repl_prompt_label {
	my ( $continuation ) = @_;

	return $continuation
		? 'zuzu (...)> '
		: 'zuzu (^_^)> '
		if ! $ENV{ZUZU_EMOJI};

	return $continuation
		? 'zuzu 🦝 ⏳ > '
		: 'zuzu 🦝 💤 > ';
}

sub _repl_prompt_coloured {
	my ( $continuation ) = @_;

	my $colour = $continuation ? "\e[1;35m" : "\e[1;36m";
	return $colour . _repl_prompt_label($continuation) . "\e[0m";
}

sub _repl_print_output {
	my ( $message ) = @_;

	print STDOUT "\e[1;32m", $message, "\e[0m\n";

	return;
}

sub _repl_print_error {
	my ( $message ) = @_;

	my $colour = $message =~ /\bwarn(?:ing)?\b/i
		? "\e[1;33m"
		: "\e[1;31m";
	print STDERR $colour, $message, "\e[0m\n";

	return;
}

sub _repl_render_value {
	my ( $runtime, $value ) = @_;

	return 'Null' if ! defined $value;
	return "$value" if ! ref($value);
	if ( blessed($value) and $value->isa('Zuzu::Value::Boolean') ) {
		return "$value";
	}

	return $runtime->_type_name($value);
}

sub _is_probably_incomplete_parse_error {
	my ( $error, $source ) = @_;

	return 0 if ! blessed($error);
	return 0 if ! $error->isa('Zuzu::Error::Compile');
	return 1 if ( $error->message // '' ) =~ /\AUnterminated\b/;

	my $line_count = () = $source =~ /\n/g;
	$line_count++;
	return 0 if ! defined $error->line;
	return 0 if $error->line < $line_count;

	return 1 if ( $error->message // '' ) =~ /\AExpected\b/;

	return 0;
}

sub _try_parse_with_optional_semicolon {
	my ( $runtime, $source ) = @_;

	my $parse_ok = eval {
		_parse_repl_source( $runtime, $source );
		1;
	};
	if ( $parse_ok ) {
		return ( 1, undef, $source );
	}
	my $first_error = $@;

	my $trimmed = $source;
	$trimmed =~ s/\s+\z//;
	if (
		$trimmed !~ /[;{}]\z/
		and $trimmed =~ /\S/
	) {
		my $with_semicolon = $trimmed . ';';
		my $semicolon_ok = eval {
			_parse_repl_source( $runtime, $with_semicolon );
			1;
		};
		if ( $semicolon_ok ) {
			return ( 1, undef, $with_semicolon );
		}
	}

	return ( 0, $first_error, $source );
}

sub _repl_structural_depth {
	my ( $source ) = @_;

	my $depth = 0;
	my $in_single = 0;
	my $in_double = 0;
	my $escaped = 0;

	for my $ch ( split //, $source ) {
		if ( $escaped ) {
			$escaped = 0;
			next;
		}
		if ( $in_single ) {
			if ( $ch eq '\\' ) {
				$escaped = 1;
				next;
			}
			if ( $ch eq "'" ) {
				$in_single = 0;
			}
			next;
		}
		if ( $in_double ) {
			if ( $ch eq '\\' ) {
				$escaped = 1;
				next;
			}
			if ( $ch eq '"' ) {
				$in_double = 0;
			}
			next;
		}
		if ( $ch eq "'" ) {
			$in_single = 1;
			next;
		}
		if ( $ch eq '"' ) {
			$in_double = 1;
			next;
		}
		if ( $ch eq '{' or $ch eq '(' or $ch eq '[' ) {
			$depth++;
			next;
		}
		if ( $ch eq '}' or $ch eq ')' or $ch eq ']' ) {
			$depth--;
		}
	}

	return $depth;
}

sub _repl_prelude_for_runtime {
	my ( $runtime ) = @_;

	my @decls;
	for my $name ( sort keys %{ $runtime->{_global}{slots} // {} } ) {
		next if $runtime->{_builtin_global_names}{$name};
		next if $name =~ /\A__/;
		next if $name !~ /\A[_A-Za-z][_A-Za-z0-9]*\z/;
		next if Zuzu::Util::is_keyword($name);
		push @decls, "let $name := null;";
	}

	return @decls;
}

sub _repl_init_line_editor {
	return if ! -t STDIN;
	return if ! -t STDOUT;

	my $ok = eval {
		require Term::ReadLine;
		1;
	};
	return if ! $ok;

	my $term = Term::ReadLine->new('zuzu');
	return if ! $term;
	return $term;
}

sub _repl_read_line {
	my ( $editor, $continuation, $history_state ) = @_;

	if ($editor) {
		my $line = $editor->readline( _repl_prompt_label($continuation) );
		return undef if ! defined $line;

		if ( $line =~ /\S/ ) {
			my $last = $history_state->{last_entry};
			if ( ! defined $last or $last ne $line ) {
				$editor->addhistory($line);
				$history_state->{last_entry} = $line;
			}
		}
		return $line;
	}

	_repl_print_prompt($continuation);
	my $line = readline STDIN;
	return undef if ! defined $line;
	chomp $line;
	return $line;
}

sub _parse_repl_source {
	my ( $runtime, $source ) = @_;

	my @prelude = _repl_prelude_for_runtime($runtime);
	my $combined = @prelude
		? join( "\n", @prelude, $source )
		: $source;

	my $lexer = Zuzu::Lexer->new(
		src => $combined,
		filename => '<repl>',
	);
	my $impl = Zuzu::Parser::_Impl->new(
		lexer => $lexer,
		filename => '<repl>',
	);

	my $ast = $impl->parse_program;
	if ( @prelude ) {
		my @stmts = @{ $ast->statements };
		splice @stmts, 0, scalar @prelude;
		$ast->statements( \@stmts );
	}

	return $ast;
}

sub _run_repl {
	my ( $runtime ) = @_;

	my @buffer;
	my $expecting_more = 0;
	my $line_editor = _repl_init_line_editor();
	my %history_state;

	while ( 1 ) {
		my $line = _repl_read_line(
			$line_editor,
			$expecting_more,
			\%history_state,
		);
		last if ! defined $line;
		next if ! @buffer and $line =~ /\A\s*\z/;

		if (
			$expecting_more
			and @buffer
			and $line =~ /\A\s*;\s*\z/
		) {
			my $source = join "\n", @buffer;
			my ( $ok, $err, $effective_source )
				= _try_parse_with_optional_semicolon( $runtime, $source );
			if ( ! $ok ) {
				_repl_print_error("$err");
				@buffer = ();
				$expecting_more = 0;
				next;
			}

			eval {
				my $ast = _parse_repl_source( $runtime, $effective_source );
				my $result = $runtime->evaluate($ast);
				_repl_print_output( _repl_render_value( $runtime, $result ) );
				1;
			} or do {
				my $err_eval = $@;
				if ( ref($err_eval) eq 'HASH' and $err_eval->{_zuzu_throw} ) {
					my $value = defined $err_eval->{value} ? $err_eval->{value} : '';
					_repl_print_error( _render_thrown_value( $runtime, $value ) );
				}
				else {
					_repl_print_error("$err_eval");
				}
			};

			@buffer = ();
			$expecting_more = 0;
			next;
		}

		push @buffer, $line;
		my $source = join "\n", @buffer;
		if ( _repl_structural_depth($source) > 0 ) {
			$expecting_more = 1;
			next;
		}
		my ( $ok, $err, $effective_source )
			= _try_parse_with_optional_semicolon( $runtime, $source );
		if ( ! $ok ) {
			if ( _is_probably_incomplete_parse_error( $err, $source ) ) {
				$expecting_more = 1;
				next;
			}

			_repl_print_error("$err");
			@buffer = ();
			$expecting_more = 0;
			next;
		}

		eval {
			my $ast = _parse_repl_source( $runtime, $effective_source );
			my $result = $runtime->evaluate($ast);
			_repl_print_output( _repl_render_value( $runtime, $result ) );
			1;
		} or do {
			my $err_eval = $@;
			if ( ref($err_eval) eq 'HASH' and $err_eval->{_zuzu_throw} ) {
				my $value = defined $err_eval->{value} ? $err_eval->{value} : '';
				_repl_print_error( _render_thrown_value( $runtime, $value ) );
			}
			else {
				_repl_print_error("$err_eval");
			}
		};

		@buffer = ();
		$expecting_more = 0;
	}

	print STDOUT "\n";
	return;
}

sub _render_thrown_value {
	my ( $runtime, $value ) = @_;

	my $text = $runtime->_to_String( $value );
	return $text if not blessed($value);
	return $text if not $value->isa( 'Zuzu::Value::Object' );

	my $slots = $value->slots // {};
	my $file = $slots->{file};
	my $line = $slots->{line};
	return $text if not defined $file or not defined $line;

	return "$text at $file, line $line";
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::CLI >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
