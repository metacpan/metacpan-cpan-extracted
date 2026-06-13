package Zuzu::Module::TUI;

use utf8;

our $VERSION = '0.004000';

use File::Spec;
use Scalar::Util qw( blessed );

use Zuzu::Error;
use Zuzu::Util::NativeHelpers qw( native_function );
use Zuzu::Value::Array;
use Zuzu::Value::Boolean;
use Zuzu::Value::Function;

my $TERM;

sub _readline_term {
	return undef if !-t STDIN;
	return $TERM if defined $TERM;
	return undef if !eval { require Term::ReadLine; 1 };
	$TERM = Term::ReadLine->new('zuzu');
	return $TERM;
}

sub _supports_ansi {
	return 0 if $ENV{NO_COLOR};
	return 0 if !-t STDOUT;

	if ( $^O eq 'MSWin32' ) {
		return 1 if $ENV{ANSICON} or $ENV{WT_SESSION} or $ENV{ConEmuANSI};
		return 1 if ( $ENV{TERM_PROGRAM} // '' ) ne '';
		return 0;
	}

	my $term = $ENV{TERM} // '';
	return 0 if $term eq '' or $term eq 'dumb';
	return 1;
}

sub _bool {
	my ( $value ) = @_;
	return Zuzu::Value::Boolean->new( value => $value ? 1 : 0 );
}

sub _ansi_code {
	my ( $colour ) = @_;
	return {
		black   => 30,
		red     => 31,
		green   => 32,
		yellow  => 33,
		blue    => 34,
		magenta => 35,
		cyan    => 36,
		white   => 37,
	}->{ lc( defined $colour ? "$colour" : '' ) };
}

sub _colour_text {
	my ( $runtime, $text, $colour ) = @_;
	$text = '' if !defined $text;
	$text = $runtime->_to_String($text) if ref($text);
	my $code = _ansi_code($colour);
	return "$text" if !$code or !_supports_ansi();
	return "\e[${code}m$text\e[0m";
}

sub _readline_supports_completion {
	my $term = _readline_term() or return 0;
	return 0 if ref($term) eq 'Term::ReadLine::Stub';
	return 1 if ref($term) eq 'Term::ReadLine::Perl';
	my $attribs = eval { $term->Attribs };
	return $attribs ? 1 : 0;
}

sub _path_completions {
	my ( $text, $directory_only ) = @_;
	$text = '' if !defined $text;
	my ( $dir, $base ) = $text =~ m{\A(.*[/\\])([^/\\]*)\z}
		? ( $1, $2 )
		: ( '', $text );
	my $search_dir = length($dir) ? $dir : '.';
	opendir my $dh, $search_dir or return [];
	my @out;
	while ( defined( my $entry = readdir($dh) ) ) {
		next if $entry eq '.' or $entry eq '..';
		next if index( $entry, $base ) != 0;
		my $candidate = $dir . $entry;
		my $path = length($dir) ? $candidate : File::Spec->catfile( '.', $entry );
		my $is_dir = -d $path ? 1 : 0;
		next if $directory_only and !$is_dir;
		push @out, $candidate . ( $is_dir ? '/' : '' );
	}
	closedir $dh;
	return [ sort @out ];
}

sub _callback_completions {
	my ( $runtime, $callback, $text ) = @_;
	return [] if !blessed($callback) or !$callback->isa('Zuzu::Value::Function');
	my $value = $runtime->_call_function(
		$callback,
		[ $text ],
		{},
		[],
		'<std/tui>',
		0,
	);
	return [] if !blessed($value) or !$value->isa('Zuzu::Value::Array');
	return [ map { $runtime->_to_String($_) } @{ $value->items } ];
}

sub _install_perl_readline_completion_key {
	my $installed = eval {
		no strict 'refs';
		*{'readline::F_ZuzuComplete'} = sub {
			readline::complete_internal("\t") or return;
			readline::complete_internal('?') if @readline::matches > 1;
			return 1;
		};
		readline::rl_bind( 'Tab', 'ZuzuComplete' );
		1;
	};
	return $installed ? 1 : 0;
}

sub _restore_perl_readline_completion_key {
	eval {
		readline::rl_bind( 'Tab', 'Complete' );
		1;
	};
	return;
}

sub _readline {
	my ( $runtime, $prompt, $default, $completion_callback ) = @_;
	$prompt = '' if !defined $prompt;
	$prompt = $runtime->_to_String($prompt) if ref($prompt);
	$default = '' if !defined $default;
	$default = $runtime->_to_String($default) if ref($default);
	if (
		defined $completion_callback
		and !blessed($completion_callback)
		and "$completion_callback" ne ''
	) {
		die Zuzu::Error->new_runtime(
			message => 'readline completion must be Function or null',
			file => '<std/tui>',
			line => 0,
		);
	}

	my $line;
	if ( my $term = _readline_term() ) {
		my $attribs = eval { $term->Attribs };
		my $old_completion;
		my $old_completion_function;
		my $state = 0;
		my $matches = [];
		if ( $attribs and blessed($completion_callback) ) {
			if ( ref($term) eq 'Term::ReadLine::Perl' ) {
				$old_completion_function = $attribs->{completion_function};
				$attribs->{completion_function} = sub {
					my ( $text, $line, $start ) = @_;
					my $so_far = substr( $line, 0, $start ) . $text;
					my $matches = _callback_completions(
						$runtime,
						$completion_callback,
						$so_far,
					);
					if ( @$matches == 1 and $matches->[0] =~ m{[/\\]\z} ) {
						$readline::rl_completer_terminator_character = '';
					}
					return @$matches;
				};
				_install_perl_readline_completion_key();
			}
			else {
				$old_completion = $attribs->{completion_entry_function};
				$attribs->{completion_entry_function} = sub {
					my ( $text, $state_arg ) = @_;
					if ( !$state_arg ) {
						$matches = _callback_completions(
							$runtime,
							$completion_callback,
							$text,
						);
						$state = 0;
					}
					return $matches->[ $state++ ];
				};
			}
		}
		$line = $term->readline($prompt);
		$attribs->{completion_entry_function} = $old_completion
			if $attribs and defined $old_completion;
		$attribs->{completion_function} = $old_completion_function
			if $attribs and defined $old_completion_function;
		_restore_perl_readline_completion_key()
			if ref($term) eq 'Term::ReadLine::Perl';
	}
	else {
		CORE::print $prompt;
		$line = <STDIN>;
	}

	return "$default" if !defined $line;
	chomp $line;
	return length($line) ? $line : "$default";
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $ansi_esc = native_function(
		name => 'ansi_esc',
		native => sub { return chr 27 },
	);

	my $supports_ansi = native_function(
		name => 'supports_ansi',
		native => sub { return _bool( _supports_ansi() ) },
	);

	my $colour_text = native_function(
		name => 'colour_text',
		native => sub {
			my ( $text, $colour ) = @_;
			return _colour_text( $runtime, $text, $colour );
		},
	);

	my $write = native_function(
		name => 'write',
		native => sub {
			my ( $text, $colour ) = @_;
			CORE::print _colour_text( $runtime, $text, $colour );
			return undef;
		},
	);

	my $write_line = native_function(
		name => 'write_line',
		native => sub {
			my ( $text, $colour ) = @_;
			CORE::print _colour_text( $runtime, $text, $colour ), "\n";
			return undef;
		},
	);

	my $readline = native_function(
		name => 'readline',
		native => sub {
			my ( $prompt, $default, $completion ) = @_;
			return _readline( $runtime, $prompt, $default, $completion );
		},
	);

	my $readline_supports_completion = native_function(
		name => 'readline_supports_completion',
		native => sub { return _bool( _readline_supports_completion() ) },
	);

	my $filename_completions = native_function(
		name => 'filename_completions',
		native => sub {
			my ( $text ) = @_;
			return Zuzu::Value::Array->new( items => [] )
				if $runtime->is_denied('fs');
			return Zuzu::Value::Array->new(
				items => _path_completions( $text, 0 ),
			);
		},
	);

	my $directory_completions = native_function(
		name => 'directory_completions',
		native => sub {
			my ( $text ) = @_;
			return Zuzu::Value::Array->new( items => [] )
				if $runtime->is_denied('fs');
			return Zuzu::Value::Array->new(
				items => _path_completions( $text, 1 ),
			);
		},
	);

	return {
		ansi_esc => $ansi_esc,
		supports_ansi => $supports_ansi,
		colour_text => $colour_text,
		write => $write,
		write_line => $write_line,
		readline => $readline,
		readline_supports_completion => $readline_supports_completion,
		filename_completions => $filename_completions,
		directory_completions => $directory_completions,
	};
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::TUI >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
