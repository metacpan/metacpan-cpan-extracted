package Zuzu::Module::Eval;

use utf8;

our $VERSION = '0.002000';

use Zuzu::Error;
use Zuzu::Util::NativeHelpers qw( native_function zuzu_bool );

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $eval_fn = native_function(
		name => 'eval',
		accepts_named => 1,
		native => sub {
			my ( $source, $named ) = @_;
			my $type = $runtime->_type_name( $source );
			if ( $type ne 'String' ) {
				die Zuzu::Error->new_runtime(
					message => "TypeException: eval expects String, got $type",
					file => '<std/eval>',
					line => 0,
				);
			}

			$named //= {};
			my %allowed = map { $_ => 1 } qw(
				deny_fs
				deny_net
				deny_perl
				deny_js
				deny_proc
				deny_db
				deny_clib
				deny_gui
				deny_worker
			);
			for my $key ( CORE::keys %{$named} ) {
				next if $allowed{$key};
				die Zuzu::Error->new_runtime(
					message => "Unknown named argument '$key' for eval",
					file => '<std/eval>',
					line => 0,
				);
			}

			my @extra_denials;
			push @extra_denials, 'fs' if zuzu_bool( $named->{deny_fs}, 0 );
			push @extra_denials, 'net' if zuzu_bool( $named->{deny_net}, 0 );
			push @extra_denials, 'perl' if zuzu_bool( $named->{deny_perl}, 0 );
			push @extra_denials, 'js' if zuzu_bool( $named->{deny_js}, 0 );
			push @extra_denials, 'proc' if zuzu_bool( $named->{deny_proc}, 0 );
			push @extra_denials, 'db' if zuzu_bool( $named->{deny_db}, 0 );
			push @extra_denials, 'clib' if zuzu_bool( $named->{deny_clib}, 0 );
			push @extra_denials, 'gui' if zuzu_bool( $named->{deny_gui}, 0 );
			push @extra_denials, 'worker' if zuzu_bool( $named->{deny_worker}, 0 );

			return $runtime->eval_with_current_scope_denials(
				$source,
				'<std/eval>',
				\@extra_denials,
			);
		},
	);

	return {
		eval => $eval_fn,
	};
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Eval >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
