
use v5.14;
use warnings;

use Syntax::Construct qw (package-block package-version);

package Test::YAFT::Attributes v1.0.3 {
	use Attribute::Handlers;

	require Ref::Util;
	require Sub::Util;

	my %attributes = (
		Assumption  => { EXPORT    => [qw [all assumptions  asserts  ]] },
		Expectation => { EXPORT    => [qw [all expectations          ]] },
		Foundation  => { EXPORT_OK => [qw [all foundations  plumbings]] },
		Util        => { EXPORT    => [qw [all utils        helpers  ]] },
	);

	sub import {
		my $caller = scalar caller;
		my $target = __PACKAGE__;

		for my $attribute (keys %attributes) {
			eval qq (
				sub ${caller}::${attribute} : ATTR(CODE,BEGIN) {
					goto &${target}::${attribute}
				}
			);

			die qq (cannot install ${target} attribute ${attribute} into ${caller}: $@)
				if $@
				;
		}
	}

	sub _push_unique_string (\@;@);

	sub _build_coderef {
		my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;

		return
			unless $data
			;

		my ($builder, @arguments) = @$data;

		if (Ref::Util::is_coderef ($builder)) {
			return sub { $builder->(@arguments, @_) }
				if @arguments
				|| _is_distinct_prototype ($referent, $builder)
				;

			return $builder;
		}

		my $file = qq ($builder.pm);
		$file =~ s (::) (/)g;

		return sub {
			local ($@, $!, $^E);
			require $file;

			$builder->new (@arguments, @_);
		};

	}

	sub _register_expectation {
		my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;

		my $name    = &_symbol_name;
		my $coderef = &_symbol_code;
		my $wrapper = sub {
			my $expectation = $coderef->(@_);

			Test::YAFT::Dumper->register_ref_builder ($expectation, $name, @_);

			return $expectation;
		};

		no warnings q (redefine);
		*{$symbol} = _sync_prototype ($coderef => $wrapper);
	}

	sub _exported {
		my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;

		my $name = &_symbol_name;
		my $config = $attributes{$attr};

		my ($where, $tags) = %$config;

		no strict q (refs);
		_push_unique_string @{qq (${package}::${where})}, $name;
		_push_unique_string @{qq (${package}::EXPORT_OK)}, $name;

		_push_unique_string @{ ${qq (${package}::EXPORT_TAGS)}{$_} //= [] }, $name
			for @{ $tags // [] }
			;
	}

	sub _install_coderef {
		my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;

		return
			unless my $coderef = &_build_coderef
			;

		*{$symbol} = _sync_prototype ($referent => $coderef);
	}

	sub _is_distinct_prototype {
		my ($target, $source) = @_;

		my $lhs = Sub::Util::prototype ($target);
		my $rhs = Sub::Util::prototype ($source);

		return 0
			|| (defined $lhs xor defined $rhs)
			|| (defined $lhs && $lhs ne $rhs)
			;
	}

	sub _push_unique_string (\@;@) {
		my $push_into = shift;

		my %exists;
		@exists{@$push_into} = ();

		push @$push_into, grep { ! exists $exists{$_} } @_;
	}

	sub _symbol_code {
		my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;

		*{$symbol}{CODE};
	}

	sub _symbol_name {
		my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;

		*{$symbol}{NAME};
	}

	sub _sync_prototype {
		my ($referent, $coderef) = @_;

		if (defined (my $prototype = Sub::Util::prototype ($referent))) {
			Sub::Util::set_prototype $prototype => $coderef;
		}

		return $coderef;
	}

	sub Assumption {
		&_exported;
		&_install_coderef;
	}

	sub Expectation {
		&_exported;
		&_install_coderef;
		&_register_expectation;
	}

	sub Foundation {
		&_exported;
		&_install_coderef;
	}

	sub Util {
		&_exported;
		&_install_coderef;
	}

	sub From {
		my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;

		&_install_coderef;
	}

	sub Cmp_Builder {
		my ($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;

		&_install_coderef;
	}

	1;
}
