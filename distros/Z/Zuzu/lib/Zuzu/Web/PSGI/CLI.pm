package Zuzu::Web::PSGI::CLI;

use utf8;
use strict;
use warnings;

our $VERSION = '0.001000';

use Getopt::Long qw(
	Configure
	GetOptionsFromArray
);
use Plack::Runner;
use Zuzu::Web::PSGI;

sub run {
	my ( @argv ) = @_;
	@argv = @ARGV if !@argv;

	binmode( *STDOUT, ':utf8' );
	binmode( *STDERR, ':utf8' );

	my ( $zuzu_argv, $plack_args ) = _split_args(@argv);
	my ( $options, $args, $usage_error ) = _parse_options($zuzu_argv);
	if ( defined $usage_error ) {
		_print_usage($usage_error);
		return 2;
	}

	my ( $deny, $deny_modules, $value_error ) = _normalize_option_lists($options);
	if ( defined $value_error ) {
		_print_usage($value_error);
		return 2;
	}

	if ( $options->{show_help} ) {
		_print_usage('');
		return 0;
	}

	my $script = shift @$args;
	if ( !defined $script or $script eq '' ) {
		_print_usage('Missing ZuzuScript web application path');
		return 2;
	}
	if ( @$args ) {
		_print_usage('Unexpected arguments before --');
		return 2;
	}

	my $app;
	my $ok = eval {
		$app = Zuzu::Web::PSGI->app(
			script => $script,
			lib => $options->{include_dirs},
			deny => $deny,
			deny_modules => $deny_modules,
			debug_level => $options->{debug_level},
		);
		1;
	};
	if ( !$ok ) {
		my $error = $@;
		print STDERR "$error";
		print STDERR "\n" if defined $error and $error !~ /\n\z/;
		return 1;
	}

	return 0 if $options->{check};

	_run_plack( $app, $plack_args );
	return 0;
}

sub _split_args {
	my ( @argv ) = @_;
	my @zuzu_argv;
	my @plack_args;
	my $seen_separator = 0;

	for my $arg ( @argv ) {
		if ( !$seen_separator and $arg eq '--' ) {
			$seen_separator = 1;
			next;
		}
		if ($seen_separator) {
			push @plack_args, $arg;
		}
		else {
			push @zuzu_argv, $arg;
		}
	}

	return ( \@zuzu_argv, \@plack_args );
}

sub _parse_options {
	my ( $argv ) = @_;
	@$argv = _normalize_debug_args(@$argv);

	my $options = {
		debug_level => 0,
		include_dirs => [],
		deny_capabilities => [],
		deny_modules => [],
		check => 0,
		show_help => 0,
	};
	my $debug_opt;

	Configure(
		'no_ignore_case',
		'bundling',
		'require_order',
	);
	my $ok = GetOptionsFromArray(
		$argv,
		'd:s' => \$debug_opt,
		'I=s@' => $options->{include_dirs},
		'deny=s@' => $options->{deny_capabilities},
		'denymodule=s@' => $options->{deny_modules},
		'check' => \$options->{check},
		'h|help' => \$options->{show_help},
	);
	if ( !$ok ) {
		return ( undef, undef, undef );
	}

	if ( defined $debug_opt ) {
		$debug_opt =~ s/\A=//;
		$debug_opt = 1 if $debug_opt eq '';
		return ( undef, undef, 'Debug level must be a non-negative integer' )
			if $debug_opt !~ /\A(?:0|[1-9][0-9]*)\z/;
		$options->{debug_level} = 0 + $debug_opt;
	}

	return ( $options, $argv, undef );
}

sub _normalize_debug_args {
	my ( @argv ) = @_;

	return map { $_ eq '-d' ? '-d=1' : $_ } @argv;
}

sub _normalize_option_lists {
	my ( $options ) = @_;

	my @deny = _flatten_trimmed_csv( @{ $options->{deny_capabilities} } );
	my @deny_modules = _flatten_trimmed_csv( @{ $options->{deny_modules} } );

	for my $entry ( @deny, @deny_modules ) {
		if ( $entry =~ /\A\s*\z/ ) {
			return ( undef, undef, 'Option values may not contain whitespace only' );
		}
	}

	return ( \@deny, \@deny_modules, undef );
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

sub _run_plack {
	my ( $app, $plack_args ) = @_;

	my $runner = Plack::Runner->new;
	$runner->parse_options( @$plack_args );
	$runner->run($app);

	return;
}

sub _print_usage {
	my ( $message ) = @_;

	if ( defined $message and $message ne '' ) {
		print STDERR $message, "\n";
	}
	print STDERR
		"Usage: zuzu-plackup.pl [options] path/to/app.zzs -- [plackup options]\n";
	print STDERR "Options:\n";
	print STDERR
		"  -d[=N]                 set debug level (default: 1 if omitted)\n";
	print STDERR "  -I/path/to/lib         add module include directory\n";
	print STDERR "  --deny=CAP             deny runtime capability (repeatable)\n";
	print STDERR "  --denymodule=MODULE    deny a specific module (repeatable)\n";
	print STDERR "  --check                load and validate the app, then exit\n";
	print STDERR "  -h, --help             show this help\n";

	return;
}

=pod

=head1 NAME

Zuzu::Web::PSGI::CLI - command-line runner for ZuzuScript PSGI apps

=head1 DESCRIPTION

Implements C<zuzu-plackup.pl>, a small convenience wrapper around
C<Zuzu::Web::PSGI> and C<Plack::Runner>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Web::PSGI::CLI >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
