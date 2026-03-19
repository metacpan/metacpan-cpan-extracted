package Text::Names::Canonicalize::Rules;

use strict;
use warnings;
use Carp qw(croak);
use YAML::XS qw(LoadFile);
use File::Spec;
use File::Basename qw(dirname);

# ----------------------------------------------------------------------
# Load a YAML ruleset if available.
# YAML files live in:
#   lib/Text/Names/Canonicalize/Rules/<locale>.yaml
# ----------------------------------------------------------------------
sub _load_yaml_rules {
	my ($locale) = @_;

# __FILE__ = .../Text/Names/Canonicalize/Rules.pm
# YAML lives in .../Text/Names/Canonicalize/Rules/*.yaml

my $base = File::Spec->catdir( dirname(__FILE__), 'Rules' );
my $file = File::Spec->catfile( $base, "$locale.yaml" );

	return unless -e $file;

	my $yaml = eval { LoadFile($file) };
	croak "Failed to load YAML rules for $locale: $@" if $@;

	croak "YAML rules for $locale must be a hash" unless ref $yaml eq 'HASH';

	return $yaml;
}

# ----------------------------------------------------------------------
# Fetch a ruleset:
#   1. Try YAML
#   2. Fall back to Perl registry
# ----------------------------------------------------------------------
sub get {
	my ($class, $locale, $ruleset) = @_;
	$ruleset ||= 'default';

	# Built-in YAML (may be undef)
	my $builtin = _load_yaml_rules($locale);
	$builtin = _resolve_includes($locale, $ruleset, $builtin) if $builtin;

	# User override YAML (may be undef)
	my $user = _load_user_yaml_rules($locale);
	$user = _resolve_includes($locale, $ruleset, $user) if $user;

	# Extract rulesets
	my $builtin_rules = $builtin ? $builtin->{$ruleset} : undef;
	my $user_rules	= $user	? $user->{$ruleset}	: undef;

	croak "Ruleset '$ruleset' not found for locale '$locale'"
		unless $builtin_rules || $user_rules;

	# Merge: user overrides built-in
	my $merged = _merge_rules($builtin_rules || {}, $user_rules || {});

	return $merged;
}

sub _user_rules_dir {

	# If CONFIG_DIR is set, use:
	#   $CONFIG_DIR/text-names-canonicalize/rules
	if ($ENV{CONFIG_DIR}) {
		return File::Spec->catdir(
			$ENV{CONFIG_DIR},
			'text-names-canonicalize',
			'rules'
		);
	}

	# Otherwise use:
	#   ~/.config/text-names-canonicalize/rules
	my $home = $ENV{HOME} or return;
	return File::Spec->catdir(
		$home,
		'.config',
		'text-names-canonicalize',
		'rules'
	);
}

sub _load_user_yaml_rules {
	my ($locale) = @_;

	my $dir = _user_rules_dir() or return;
	my $file = File::Spec->catfile($dir, "$locale.yaml");

	return unless -e $file;

	my $yaml = eval { LoadFile($file) };
	croak "Failed to load user YAML rules for $locale: $@" if $@;

	return $yaml;
}

sub _merge_rules {
	my ($base, $override) = @_;
	return $base unless $override;

	my %merged = (%$base, %$override);
	return \%merged;
}

sub _resolve_includes {
    my ($locale, $ruleset, $yaml, $seen) = @_;
    return $yaml unless $yaml;

    $seen ||= {};

    my $spec = $yaml->{$ruleset}
        or return $yaml;

    my @parents;
    if (exists $spec->{include}) {
        my $inc = $spec->{include};

        @parents =
            ref $inc eq 'ARRAY' ? @$inc :
            ref $inc eq ''       ? ($inc) :
            croak "Invalid include format in $locale/$ruleset";
    }

    delete $spec->{include};

    for my $parent (@parents) {

        # CIRCULAR INCLUDE DETECTION
        croak "Circular include detected: $locale → $parent"
            if $seen->{$parent};

        $seen->{$parent} = 1;

        my $parent_yaml = _load_yaml_rules($parent)
            or croak "Included locale '$parent' not found";

        $parent_yaml = _resolve_includes($parent, $ruleset, $parent_yaml, $seen);

        my $parent_rules = $parent_yaml->{$ruleset}
            or croak "Included ruleset '$ruleset' not found in '$parent'";

        $spec = _merge_rules($parent_rules, $spec);
    }

    $yaml->{$ruleset} = $spec;
    return $yaml;
}

1;
