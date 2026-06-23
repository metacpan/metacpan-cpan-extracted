
use v5.14;
use warnings;

package Test::Load::Helper v1.0.0 {

	use Carp qw (croak);
	use Path::Tiny qw ();

	our $DEFAULT_FILENAME = q (test-helper.pl);

	sub eval_helper {
		my ($class, %args) = @_;

		my $key = $class->inc_key (%args);

		return 1
			if exists $INC{$key}
			;

		my $file = $args{file};
		my $code = $file->slurp_utf8;

		{
			no strict q (refs);
			eval <<"END_OF_EVAL";
package $args{into};
use strict;
use warnings;
#line 1 "$file"
$code;
1;
END_OF_EVAL
		}

		croak qq (Test::Load::Helper: Error compiling '$file': $@)
			if $@
			;

		$INC{$key} = "$file";
		return 1;
	}

	sub identify_caller_file {
		my ($class, %args) = @_;

		my $level = 0;
		while (my @info = caller ($level++)) {
			my $file = $info[1];
			next if $file eq __FILE__;
			return Path::Tiny::->new ($file)
				if -f $file
				;
		}

		return path ('.');
	}

	sub identify_caller_package {
		my ($class, %args) = @_;

		return $args{into}
			if exists $args{into}
			;

		my $level = 0;
		while (my @info = caller ($level++)) {
			my $package = $info[0];
			next if $package eq __PACKAGE__;
			return $package;
		}

		return q (main);
	}

	sub identify_helper_file {
		my ($class, %args) = @_;
		my $file = $args{file} // $DEFAULT_FILENAME;

		my $caller_file = exists $args{caller_file}
			? Path::Tiny::->new ($args{caller_file})
			: $class->identify_caller_file (%args)
			;

		my $caller_dir  = $caller_file->parent->absolute;

		my $root = $ENV{TEST_LOAD_ROOT}
			? Path::Tiny::->new ($ENV{TEST_LOAD_ROOT})->absolute
			: Path::Tiny::->new (q (/))
			;

		while (1) {
			my $candidate = $caller_dir->child ($file);

			return $candidate
				if $candidate ne $caller_file
				&& $candidate->exists
				;

			last
				if $caller_dir eq $root
				;

			my $parent = $caller_dir->parent;

			last
				if $parent eq $caller_dir
				;

			$caller_dir = $parent;
		}

		return;
	}

	sub import {
		my ($class, %args) = @_;

		return
			unless my $caller_package = $class->identify_caller_package (%args)
			;

		return 1
			unless my $helper_file = $class->identify_helper_file (%args)
			;

		$class->eval_helper (
			into => $caller_package,
			file => $helper_file,
		);
	}

	sub inc_key {
		my ($class, %args) = @_;

		my $into = $args{into};
		my $file = $args{file};

		# File can be loaded into multiple target packages
		qq (${file}{${into}});
	}

	1;
}

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Load::Helper - automatically load test helpers by walking the directory tree

=head1 SYNOPSIS

    # finds and loads the nearest test-helper.pl, searching upward from the calling file
    use Test::Load::Helper;

    # load a specialised helper instead of the default
    use Test::Load::Helper file => q (test-helper-schema.pl);

    # load helper into a specific package rather than the caller's own namespace
    use Test::Load::Helper into => q (My::Fixtures);

    # load a helper at an explicit relative path; its own hierarchy is honoured
    use Test::Load::Helper file => q (./contracts/test-helper.pl);

=head1 DESCRIPTION

Inspired by the C<test_helper> convention from RSpec, this module locates and
loads a Perl test helper file by walking up the directory tree from the calling
file. It removes the need for hardcoded relative paths such as
C<require q (../../test-helper.pl)>.

When a test file does C<use Test::Load::Helper>, the module determines the
target package and the starting directory, then searches upward for a helper
file. The file is evaluated inside the target package with C<use strict> and
C<use warnings> in effect.

If no helper file is found the module does nothing silently — this is not an
error.

=head2 Hierarchical helpers

A C<test-helper.pl> may itself C<use Test::Load::Helper> to chain to its
parent:

    # t/contracts/test-helper.pl
    use Test::Load::Helper;            # loads t/test-helper.pl
    use constant CONTRACT_HELPER => 1;

When a test case in C<t/contracts/> loads its local helper, both the local and
the ancestor helper are evaluated, building up a chain of shared fixtures.

=head2 Deduplication

The same helper file is never evaluated into the same package twice. If two
specialised helpers both chain to a common base, the base is evaluated only
once. Because the internal key encodes both file path and target package, the
same file B<can> be loaded into different packages independently.

=head2 Bounding traversal

Set C<$ENV{TEST_LOAD_ROOT}> to an absolute path to stop traversal at a given
directory. This is useful in monorepos where helpers from a sibling project
should not be picked up.

=head1 IMPORTING

The following named arguments are recognised by C<import>:

=over

=item file

Name or relative path of the helper file to search for. Defaults to
C<test-helper.pl>. A path such as C<./subdir/test-helper.pl> is resolved
relative to the caller's directory; the hierarchy from that file's own
directory is then honoured.

=item into

Package into which the helper is evaluated. Defaults to the caller's own
package. Useful when loading shared fixtures into a dedicated namespace:

    package My::Fixtures { use Test::Load::Helper }

    # or equivalently:
    use Test::Load::Helper into => q (My::Fixtures);

=back

=head1 ENVIRONMENT

=over

=item TEST_LOAD_ROOT

Absolute path at which upward traversal stops (inclusive). When unset,
traversal continues to the filesystem root.

=back

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

L<Test::Load::Helper> distribution is distributed under the Artistic License 2.0.

=cut

