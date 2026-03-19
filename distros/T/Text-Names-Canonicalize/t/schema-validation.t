use strict;
use warnings;
use utf8;
use Test::Most;
use YAML::XS qw(LoadFile);
use File::Spec;
use File::Basename qw(dirname);

# Directory containing YAML rules
my $rules_dir = File::Spec->catdir(
    dirname(__FILE__), '..', 'lib', 'Text', 'Names', 'Canonicalize', 'Rules'
);

opendir my $dh, $rules_dir or die "Cannot open $rules_dir: $!";
my @yaml_files = grep { /\.yaml$/ } readdir $dh;
closedir $dh;

# Required keys for a *fully resolved* ruleset
my @required_keys = qw(
    particles
    suffixes
    strip_titles
    hyphen_policy
    surname_strategy
);

# Allowed keys in a *raw* YAML ruleset
my %allowed = map { $_ => 1 } (
    @required_keys,
    'include',      # NEW
);

foreach my $file (@yaml_files) {
    my $path = File::Spec->catfile($rules_dir, $file);

    ok(-e $path, "YAML file exists: $file");

    my $yaml = eval { LoadFile($path) };
    ok(!$@, "YAML loads cleanly: $file");

    ok(ref $yaml eq 'HASH', "YAML top-level is a hash: $file");

    foreach my $ruleset (keys %$yaml) {
        my $rules = $yaml->{$ruleset};

        ok(ref $rules eq 'HASH', "Ruleset '$ruleset' is a hash");

        # Check for unknown keys
        foreach my $key (keys %$rules) {
            ok($allowed{$key}, "$file/$ruleset key '$key' is allowed");
        }

        # If include is present, skip required-key checks
        if (exists $rules->{include}) {
            ok(1, "$file/$ruleset uses include, skipping required-key checks");
            next;
        }

        # Otherwise, enforce required keys
        foreach my $key (@required_keys) {
            ok(exists $rules->{$key}, "$file/$ruleset has key '$key'");
        }

        # Type checks (only for present keys)
        ok(!ref $rules->{hyphen_policy}, "hyphen_policy is scalar")
            if exists $rules->{hyphen_policy};

        ok(!ref $rules->{surname_strategy}, "surname_strategy is scalar")
            if exists $rules->{surname_strategy};

        ok(ref $rules->{particles} eq 'ARRAY', "particles is array")
            if exists $rules->{particles};

        ok(ref $rules->{suffixes} eq 'ARRAY', "suffixes is array")
            if exists $rules->{suffixes};

        ok(ref $rules->{strip_titles} eq 'ARRAY', "strip_titles is array")
            if exists $rules->{strip_titles};
    }
}

done_testing;
