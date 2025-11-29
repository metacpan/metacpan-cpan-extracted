package Test::Which;

use strict;
use warnings;

use parent 'Exporter';
our @ISA = qw(Exporter);

use File::Which qw(which);
use IPC::Run3 qw(run3);
use version ();	# provide version->parse
use Test::Builder;

our @EXPORT_OK = qw(which_ok);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my $TEST = Test::Builder->new();

=head1 NAME

Test::Which - Skip tests if external programs are missing from PATH (with version checks)

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Test::Which 'ffmpeg' => '>=6.0', 'convert' => '>=7.1';

  # At runtime in a subtest or test body
  use Test::Which qw(which_ok);

  subtest 'needs ffmpeg' => sub {
	  which_ok 'ffmpeg' => '>=6.0' or return;
	  ... # tests that use ffmpeg
  };

=head1 DESCRIPTION

C<Test::Which> mirrors L<Test::Needs> but checks for executables in PATH.
It can also check simple version constraints using a built-in heuristic (tries --version, -version, -v, -V and extracts a dotted-number).
If a version is requested but cannot be determined, the requirement fails.

=head2 EXAMPLES

  # String constraints
  which_ok 'perl' => '>=5.10';
  which_ok 'ffmpeg' => '>=4.0', 'convert' => '7.1';

  # Regex constraints
  which_ok 'perl', { version => qr/5\.\d+/ };

  # Mixed
  which_ok 'perl' => '>=5.10', 'ffmpeg', { version => qr/^[4-6]\./ };

  # Just program names
  which_ok 'perl', 'ffmpeg', 'convert';

  # String in hashref (for consistency)
  which_ok 'perl', { version => '>=5.10' };

=head1 FUNCTIONS

=head2 which_ok @programs_or_pairs

Checks the named programs (with optional version constraints).
If any requirement is not met the current test or subtest is skipped via L<Test::Builder>.

=cut

# runtime function, returns true if all present & satisfy versions, otherwise calls skip
sub which_ok {
	my (@args) = @_;

	my $res = _check_requirements(@args);
	my @missing = @{ $res->{missing} };
	my @bad = @{ $res->{bad_version} };

	if (@missing || @bad) {
		my @msgs;
		push @msgs, map { "Missing required program '$_'" } @missing;
		push @msgs, map { "Version issue for $_->{name}: $_->{reason}" } @bad;
		my $msg = join('; ', @msgs);
		$TEST->skip($msg);
		return 0;
	}

	# Actually run a passing test
	$TEST->ok(1, 'Required programs available: ' . join(', ', map { $_->{name} } @{ $res->{checked} || [] }));
	return 1;
}

# Helper: run a program with one of the version flags and capture output
sub _capture_version_output {
	my $path = $_[0];

	for my $flag (qw(--version -version -v -V)) {
		my $out;
		my $err;

		eval {
			local $SIG{ALRM} = sub { die 'timeout' };
			alarm(2);  # 2 second timeout

			run3([$path, $flag], \undef, \$out, \$err);

			alarm(0);	# Cancel alarm
		};

		if ($@) {
			alarm(0);	# Ensure alarm is cancelled
			next if $@ =~ /timeout/;
			warn "Error running $path $flag: $@";
			next;
		}

		my $output = defined $out ? $out : '';
		$output .= defined $err ? $err : '';

		next if $output eq '';
		return $output;
	}
	return undef;
}

# Extract the first version-like token from output
sub _extract_version {
	my $output = $_[0];

	return undef unless defined $output;

	# Look for version near the word "version"
	# Handles: "ffmpeg version 4.2.7", "Version: 2.1.0", "ImageMagick 7.1.0-4"
	if ($output =~ /version[:\s]+v?(\d+(?:\.\d+)+)/i) {
		return $1;
	}

	# Look at first line (common pattern)
	my ($first_line) = split /\n/, $output;
	if ($first_line =~ /\b(\d+\.\d+(?:\.\d+)*)\b/) {
		return $1;
	}

	# Any dotted version number
	if ($output =~ /\b(\d+\.\d+(?:\.\d+)*)\b/) {
		return $1;
	}

	# Single number near "version"
	if ($output =~ /version[:\s]+v?(\d+)\b/i) {
		return $1;
	}

	# Just a standalone number (least reliable)
	if ($output =~ /\b(\d+)\b/) {
		return $1;
	}

	return undef;
}

# Compare two versions given an operator
sub _version_satisfies {
	my ($found, $op, $required) = @_;

	return 0 unless defined $found;

	# Parse both versions, checking each separately
	my $vf = eval { version->parse($found) };
	if ($@) {
		warn "Failed to parse found version '$found': $@";
		return 0;
	}

	my $vr = eval { version->parse($required) };
	if ($@) {
		warn "Failed to parse required version '$required': $@";
		return 0;
	}

	# Now do comparisons
	if    ($op eq '>=') { return $vf >= $vr }
	elsif ($op eq '>')  { return $vf >  $vr }
	elsif ($op eq '<=') { return $vf <= $vr }
	elsif ($op eq '<')  { return $vf <  $vr }
	elsif ($op eq '==') { return $vf == $vr }
	elsif ($op eq '!=') { return $vf != $vr }

	warn "Unknown operator '$op'";
	return 0;
}

# Parse a constraint like ">=1.2.3" into (op, ver)
sub _parse_constraint {
	my $spec = $_[0];

	return unless defined $spec;

	if ($spec =~ /^\s*(>=|<=|==|!=|>|<)\s*(\S+)\s*$/) {
		return ($1, $2);
	}
	# allow bare version (implies ==)
	if ($spec =~ /^\s*(\d+(?:\.\d+)*)\s*$/) {
		return ('==', $1);
	}

	# If we get here, it's invalid
	# Return empty list, but caller should provide an helpful error
	return;
}

# Core check routine. Accepts a list of program => maybe_constraint pairs,
# or simple program names in the list form.
sub _check_requirements {
	my (@args) = @_;

	# Normalize into array of hashrefs: { name => ..., constraint => undef or '>=1' or {version => ...} }
	my @reqs;
	my $i = 0;

	while ($i < @args) {
		my $name = $args[$i];

		# Validate program name
		unless (defined $name) {
			warn "Undefined program name at position $i, skipping";
			$i++;
			next;
		}

		if (ref $name) {
			warn "Program name at position $i cannot be a reference, skipping";
			$i++;
			next;
		}

		$i++;

		# Check if next argument is a constraint
		my $constraint = undef;
		if ($i < @args) {
			my $next = $args[$i];

			if (defined $next) {
				# String constraint: >=1.2.3, >1.0, or bare version 1.2.3
				if (!ref($next)) {
					if ($next =~ /^(?:>=|<=|==|!=|>|<)/ || $next =~ /^\d+(?:\.\d+)*$/) {
						$constraint = $next;
						$i++;
					}
					# Otherwise it's probably the next program name, don't consume it
				} elsif (ref($next) eq 'HASH') {
					# Hashref constraint: { version => qr/.../ } or similar
					$constraint = $next;
					$i++;
				}
			# Other refs (ARRAY, CODE, etc.) - treat as next program name, don't consume
			}
		}

		push @reqs, { name => $name, constraint => $constraint };
	}

	my @missing;
	my @bad_version;

	for my $r (@reqs) {
		my $name = $r->{name};
		my $want = $r->{constraint};

		my $path = which($name);
		unless ($path) {
			push @missing, $name;
			next;
		}

		# No version constraint - program exists, we're done
		next unless defined $want;

		# Handle hashref constraints
		if (ref($want) eq 'HASH') {
			# Currently only support { version => qr/.../ }
			if (exists $want->{version}) {
				my $version_spec = $want->{version};
				my $out = _capture_version_output($path);
				my $found = _extract_version($out);

			unless (defined $found) {
				push @bad_version, {
					name => $name,
					reason => 'no version detected for hashref constraint'
				};
				next;
			}

			# Regex constraint
			if (ref($version_spec) eq 'Regexp') {
				unless ($found =~ $version_spec) {
					push @bad_version, {
						name => $name,
						reason => "found version $found but doesn't match pattern $version_spec"
					};
					next;
				}
			} elsif (!ref($version_spec)) {
				# String constraint within hashref (treat like normal string constraint)
				my ($op, $ver) = _parse_constraint($version_spec);
				unless (defined $op) {
					push @bad_version, {
						name => $name,
						reason => "invalid constraint in hashref '$version_spec' (expected format: '>=1.2.3', '>2.0', '==1.5', or '1.5')"
					};
					next;
				}
				unless (_version_satisfies($found, $op, $ver)) {
					push @bad_version, {
						name => $name,
						reason => "found $found but need $op$ver"
					};
					next;
				}
			} else {
				# Unsupported type in hashref
				push @bad_version, {
					name => $name,
					reason => "unsupported version spec type in hashref: " . ref($version_spec)
				};
				next;
			}
		} else {
			# Hashref without 'version' key
			push @bad_version, {
				name => $name,
				reason => "hashref constraint must contain 'version' key"
			};
			next;
		}
	} elsif (!ref($want)) {
		# Handle string constraints
		my ($op, $ver) = _parse_constraint($want);
		unless (defined $op) {
			push @bad_version, {
				name => $name,
				reason => "invalid constraint '$want' (expected format: '>=1.2.3', '>2.0', '==1.5', or '1.5')"
			};
			next;
		}

		my $out = _capture_version_output($path);
		my $found = _extract_version($out);

		unless (defined $found) {
			push @bad_version, {
				name => $name,
				reason => 'no version detected'
			};
			next;
		}

		unless (_version_satisfies($found, $op, $ver)) {
			push @bad_version, {
				name => $name,
				reason => "found $found but need $op$ver"
			};
			next;
		}
	} else {
		# Unsupported constraint type
		push @bad_version, {
			name => $name,
			reason => "unsupported constraint type: " . ref($want)
			};
		next;
		}
	}

	return {
		missing => \@missing,
		bad_version => \@bad_version,
	};
}

# import: allow compile-time checks like `use Test::Which 'prog' => '>=1.2';`
sub import {
	my $class = shift;
	$class->export_to_level(1, $class, @EXPORT_OK);

	# Only run requirement checks if any args remain
	my @reqs = grep { $_ ne 'which_ok' } @_;

	return unless @reqs;

	my $res = _check_requirements(@reqs);
	my @missing = @{ $res->{missing} };
	my @bad = @{ $res->{bad_version} };

	if (@missing || @bad) {
		my @msgs;
		push @msgs, map { "Missing required program '$_'" } @missing;
		push @msgs, map { "Version issue for $_->{name}: $_->{reason}" } @bad;
		my $msg = join('; ', @msgs);
		$TEST->plan(skip_all => "Test::Which requirements not met: $msg");
	}
}

1;

__END__

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut
