package Zuzu::Doc::CLI;

use utf8;
use strict;
use warnings;

our $VERSION = '0.001003';

use Getopt::Long qw(
	Configure
	GetOptionsFromArray
);
use Pod::Text::Termcap;
use IO::Handle;

use Zuzu::Runtime;

sub run {
	my ( @argv ) = @_;
	@argv = @ARGV if not @argv;

	my ( $options, $args, $error ) = _parse_options( \@argv );
	if ( defined $error ) {
		_print_usage($error);
		return 2;
	}

	my ( $target, $target_error ) = _extract_target($args);
	if ( defined $target_error ) {
		_print_usage($target_error);
		return 2;
	}

	my $runtime = _build_runtime($options);
	my $doc_file = _resolve_target_path( $runtime, $target );
	if ( not defined $doc_file ) {
		print STDERR "Could not locate documentation for '$target'\n";
		return 1;
	}

	my $output = _render_pod($doc_file);
	my $pager_ok = _page_output($output);
	return $pager_ok ? 0 : 1;
}

sub _parse_options {
	my ( $argv ) = @_;

	my $options = {
		include_dirs => [],
	};

	Configure(
		'no_ignore_case',
		'bundling',
	);
	my $ok = GetOptionsFromArray(
		$argv,
		'I=s@' => $options->{include_dirs},
		'h|help' => \$options->{help},
	);
	return ( undef, undef, undef ) if not $ok;

	if ( $options->{help} ) {
		return ( undef, undef, '' );
	}

	return ( $options, $argv, undef );
}

sub _extract_target {
	my ( $args ) = @_;

	my $target = shift @{ $args };
	return ( undef, '' ) if not defined $target;
	return ( undef, 'Too many arguments' ) if @{ $args };

	return ( $target, undef );
}

sub _build_runtime {
	my ( $options ) = @_;

	return Zuzu::Runtime->new(
		lib => [ @{ $options->{include_dirs} }, @Zuzu::Runtime::DEFAULT_LIB ],
	);
}

sub _resolve_target_path {
	my ( $runtime, $target ) = @_;

	return $target if _is_existing_file($target);

	for my $candidate ( $runtime->_module_candidates( $target, undef ) ) {
		return $candidate if -f $candidate;
	}

	return undef;
}

sub _is_existing_file {
	my ( $value ) = @_;

	return 0 if not defined $value;
	return 0 if $value eq '';
	return 1 if -f $value;
	return 0;
}

sub _render_pod {
	my ( $doc_file ) = @_;

	my $formatter = Pod::Text::Termcap->new;
	my $output = '';
	open my $out_fh, '>:encoding(UTF-8)', \$output
		or die "Could not open in-memory buffer: $!\n";
	$formatter->output_fh($out_fh);
	$formatter->parse_from_file($doc_file);
	close $out_fh;

	return $output;
}

sub _page_output {
	my ( $output ) = @_;

	my $pager = $ENV{PAGER} || 'less -FRX';
	open my $pager_fh, '|-', $pager
		or die "Could not start pager '$pager': $!\n";
	$pager_fh->autoflush(1);
	print {$pager_fh} $output;

	my $closed = close $pager_fh;
	return $closed ? 1 : 0;
}

sub _print_usage {
	my ( $message ) = @_;

	if ( defined $message and $message ne '' ) {
		print STDERR $message, "\n";
	}
	print STDERR "Usage: zuzudoc.pl [-I/path/to/lib] path/to/file.zzs|module/name\n";

	return;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Doc::CLI >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
