package Zuzu;

use utf8;
use strict;
use warnings;

our $VERSION = '0.001002';

use Exporter qw( import );
our @EXPORT_OK = qw(
	zuzu_eval
	zuzu_evalfile
);

use Zuzu::Parser;
use Zuzu::Runtime;

sub zuzu_eval {
	my ( $script, $runtime_options ) = @_;
	$runtime_options ||= {};

	my $runtime = Zuzu::Runtime->new( %{ $runtime_options } );
	my $parser = Zuzu::Parser->new(
		disabled_visitors => $runtime->disabled_visitors,
	);
	my $ast = $parser->parse( $script, '<eval>' );
	my $result = $runtime->evaluate($ast);

	return $result;
}

sub zuzu_evalfile {
	my ( $filename, $runtime_options ) = @_;
	$runtime_options ||= {};

	open my $fh, '<:encoding(UTF-8)', $filename
		or die "Could not open '$filename': $!\n";
	local $/;
	my $source = <$fh>;
	close $fh;

	my $runtime = Zuzu::Runtime->new( %{ $runtime_options } );
	my $parser = Zuzu::Parser->new(
		disabled_visitors => $runtime->disabled_visitors,
	);
	my $ast = $parser->parse( $source, $filename );
	my $result = $runtime->evaluate($ast);

	return $result;
}

1;

=pod

=head1 NAME

Zuzu - API helpers for evaluating ZuzuScript

=head1 SYNOPSIS

  use Zuzu qw( zuzu_eval zuzu_evalfile );

  my $runtime = zuzu_eval(
    'function hi() { return "hello"; }',
    { deny_modules => [ 'std/io' ] },
  );

  my $runtime2 = zuzu_evalfile(
    'example.zzs',
    { lib => [ './modules' ] },
  );

=head1 DESCRIPTION

Provides helper functions for one-shot parsing and evaluation.

=head1 FUNCTIONS

=head2 zuzu_eval( $script, \%runtime_options )

Parses and evaluates a ZuzuScript source string and returns the
result of evaluation.

=head2 zuzu_evalfile( $filename, \%runtime_options )

Loads a UTF-8 script file, parses and evaluates it, and returns
the result of evaluation.

=head1 SEE ALSO

L<https://zuzulang.org/>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
