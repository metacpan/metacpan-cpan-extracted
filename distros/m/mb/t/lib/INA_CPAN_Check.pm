package INA_CPAN_Check;
######################################################################
#
# INA_CPAN_Check.pm - Shared helpers for ina@CPAN pre-release checks
#
# This module provides:
#   - Minimal TAP harness (ok, diag, plan_tests, plan_skip)
#   - File utilities (_slurp, _slurp_lines, _find_pm)
#   - MANIFEST helpers (_manifest_files, _manifest_pm_and_t)
#   - Version / META parsers (_pm_version, _yaml_str, _json_str, etc.)
#   - Code scanner (_scan_code)
#   - Check implementations: check_A through check_K
#     (check_J and check_K accept distribution-specific overrides)
#
# Compatible: Perl 5.005_03 and later
# No non-core dependencies.
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;

use File::Spec ();
use vars qw($VERSION @ISA @EXPORT_OK);
$VERSION = '1.00';
$VERSION = $VERSION;

# Simple exporter (no Exporter.pm required -- works on 5.005_03)
# All public and private subroutines exported by default
my @_EXPORT = qw(
    plan_tests plan_skip ok diag end_testing
    _slurp _slurp_lines _find_pm
    _manifest_files _manifest_pm_and_t
    _pm_version _yaml_str _json_str
    _provides_versions_yml _provides_versions_json
    _scan_code
    check_A count_A  check_B count_B  check_C count_C
    check_D count_D  check_E count_E  check_F count_F
    check_G count_G  check_H count_H  check_I count_I
    check_J count_J  check_K count_K
);

sub import {
    my $pkg    = shift;
    my $caller = caller;
    my @names  = @_ ? @_ : @_EXPORT;
    no strict 'refs';
    for my $name (@names) {
        *{"${caller}::${name}"} = \&{"${pkg}::${name}"};
    }
}

######################################################################
# TAP harness
######################################################################

my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);

sub plan_tests {
    $T_PLAN = $_[0];
    print "1..$T_PLAN\n";
}

sub plan_skip {
    print "1..0 # SKIP $_[0]\n";
    exit 0;
}

sub ok {
    my ($ok, $name) = @_;
    $T_RUN++;
    $T_FAIL++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $T_RUN"
        . ($name ? " - $name" : '') . "\n";
    return $ok;
}

sub diag {
    for my $line (@_) {
        print "# $line\n";
    }
}

sub end_testing {
    exit 1 if $T_PLAN && $T_FAIL;
    exit 0;
}

######################################################################
# File utilities
######################################################################

sub _slurp {
    my ($path) = @_;
    local *FH;
    open FH, "< $path" or return '';
    local $/;
    my $c = <FH>;
    close FH;
    $c =~ s/\r//g if defined $c;
    return $c;
}

sub _slurp_lines {
    my ($path) = @_;
    local *FH;
    open FH, "< $path" or return ();
    my @lines = <FH>;
    close FH;
    for my $line (@lines) { $line =~ s/\r//g }
    return @lines;
}

sub _find_pm {
    my ($dir, $out) = @_;
    local *DH;
    opendir DH, $dir or return;
    for my $e (readdir DH) {
        next if $e eq '.' || $e eq '..';
        my $full = "$dir/$e";
        if (-d $full) {
            _find_pm($full, $out);
        }
        elsif ($e =~ /\.pm$/) {
            push @$out, $full;
        }
    }
    closedir DH;
}

######################################################################
# MANIFEST helpers
######################################################################

sub _manifest_files {
    my ($root) = @_;
    local *MFH;
    open MFH, "< $root/MANIFEST" or return ();
    my @lines = <MFH>;
    close MFH;
    my @files;
    for my $l (@lines) {
        $l =~ s/\r?\n$//;
        $l =~ s/#.*$//;
        $l =~ s/^\s+|\s+$//g;
        push @files, $l if length $l;
    }
    return @files;
}

sub _manifest_pm_and_t {
    my ($root) = @_;
    my @all   = _manifest_files($root);
    my @found = grep {
        ((/\.pm$/ && m{^lib/}) || /\.t$/ || m{^eg/.*\.pl$}) && -f "$root/$_"
    } @all;
    return @found if @found;
    # Fallback
    my @fb;
    for my $dir ('lib', 't', 'eg') {
        _find_pm("$root/$dir", [ @fb ]) if -d "$root/$dir";
    }
    for my $p (@fb) {
        $p =~ s{^\Q$root\E/}{};
    }
    return @fb;
}

######################################################################
# Version / META parsers
######################################################################

sub _pm_version {
    my ($path) = @_;
    my $text = _slurp($path);
    return undef unless $text;
    if ($text =~ /\$VERSION\s*=\s*['"]([^'"]+)['"]/) {
        return $1;
    }
    if ($text =~ /\$VERSION\s*=\s*([\d._]+)/) {
        return $1;
    }
    return undef;
}

sub _yaml_str {
    my ($text, $key) = @_;
    return undef unless $text;
    if ($text =~ /^${key}:\s*['"]?([^'"\n]+)['"]?\s*$/m) {
        return $1;
    }
    return undef;
}

sub _json_str {
    my ($text, $key) = @_;
    return undef unless $text;
    if ($text =~ /"${key}"\s*:\s*"([^"]+)"/) {
        return $1;
    }
    return undef;
}

sub _provides_versions_yml {
    my ($text) = @_;
    my %h;
    return { %h } unless $text;
    my $in = 0;
    for my $line (split /\n/, $text) {
        if ($line =~ /^provides:/) { $in = 1; next }
        last if $in && $line =~ /^\S/ && $line !~ /^\s/;
        if ($in && $line =~ /^\s+version:\s*['"]?([\d._]+)/) {
            my $v = $1;
            my $pkg = 'unknown';
            $h{$pkg} = $v;
        }
        if ($in && $line =~ /^\s+(\S+):/) { $h{$1} = '' }
    }
    # Simpler: just scan all version: lines under provides
    %h = ();
    if ($text =~ /^provides:(.*?)(?=^\S)/ms) {
        my $block = $1;
        while ($block =~ /^(\s+\S.*?):\s*\n(.*?)(?=^\s+\S|\z)/msg) {
            my $pkg = $1; $pkg =~ s/^\s+//;
            my $sub = defined $2 ? $2 : '';
            if ($sub =~ /version:\s*['"]?([\d._]+)/) {
                $h{$pkg} = $1;
            }
        }
    }
    return { %h };
}

sub _provides_versions_json {
    my ($text) = @_;
    my %h;
    return { %h } unless $text;
    while ($text =~ /"([\w:]+)"\s*:\s*\{[^}]*"version"\s*:\s*"([^"]+)"/g) {
        $h{$1} = $2;
    }
    return { %h };
}

######################################################################
# Code scanner
######################################################################

sub _scan_code {
    my ($path, $pattern) = @_;
    my $text = _slurp($path);
    return () unless $text;
    # Strip __END__
    $text =~ s/\n__END__\b.*\z//s;
    # Strip POD
    $text =~ s/^=[a-zA-Z].*?^=cut[ \t]*$//msg;
    my @hits;
    my $lineno = 0;
    for my $line (split /\n/, $text) {
        $lineno++;
        next if $line =~ /^\s*#/;
        my $clean = $line;
        $clean =~ s/'(?:[^'\\]|\\.)*'/''/g;
        $clean =~ s/"(?:[^"\\]|\\.)*"/""/g;
        $clean =~ s{(?:s|m|qr)/[^/]*/[^/]*/[gimsex]*}{}g;
        $clean =~ s{/[^/]+/[gimsex]*}{}g;
        $clean =~ s/#.*$//;
        if ($clean =~ $pattern) {
            push @hits, { line => $lineno, text => $line };
        }
    }
    return @hits;
}

######################################################################
# Category A: File Structure (MANIFEST)
######################################################################

sub check_A {
    my ($root) = @_;
    my @required = qw(
        Changes Makefile.PL MANIFEST META.yml META.json
        README LICENSE
    );
    plan_skip('MANIFEST not found') unless -f "$root/MANIFEST";
    my @manifest = _manifest_files($root);
    plan_skip('MANIFEST is empty') unless @manifest;

    for my $f (@manifest) {
        ok(-e "$root/$f", "A - MANIFEST file exists: $f");
    }
    for my $req (@required) {
        my $found = grep { $_ eq $req } @manifest;
        ok($found, "A - required file in MANIFEST: $req");
    }
    ok((grep { /\.pm$/ } @manifest) > 0, 'A - at least one .pm in MANIFEST');
}

sub count_A {
    my ($root) = @_;
    my @manifest  = _manifest_files($root);
    my @required  = qw(Changes Makefile.PL MANIFEST META.yml META.json README LICENSE);
    return scalar(@manifest) + scalar(@required) + 1;
}

######################################################################
# Category B: Version Consistency
######################################################################

sub check_B {
    my ($root) = @_;
    my @manifest  = _manifest_files($root);
    my @pm_files  = sort grep { /^lib\/.*\.pm$/ && -f "$root/$_" } @manifest;
    my $meta_yml  = _slurp("$root/META.yml");
    my $meta_json = _slurp("$root/META.json");
    my $mkf_text  = _slurp("$root/Makefile.PL");
    my $chg_text  = _slurp("$root/Changes");

    for my $pm (@pm_files) {
        my $ver = _pm_version("$root/$pm");
        ok(defined $ver, "B - \$VERSION defined in $pm");
        $ver = '(undef)' unless defined $ver;

        my $yml_ver = _yaml_str($meta_yml, 'version');
        ok(defined $yml_ver && $yml_ver eq $ver,
           "B - META.yml version (" . ($yml_ver||'undef') . ") eq \$VERSION ($ver)");

        my $json_ver = _json_str($meta_json, 'version');
        ok(defined $json_ver && $json_ver eq $ver,
           "B - META.json version (" . ($json_ver||'undef') . ") eq \$VERSION ($ver)");

        my $mk_ver;
        $mk_ver = $1 if $mkf_text =~ /'VERSION'\s*=>\s*q\{([^}]+)\}/;
        $mk_ver = $1 if !defined $mk_ver &&
                        $mkf_text =~ /'VERSION'\s*=>\s*['"]([^'"]+)['"]/;
        ok(defined $mk_ver && $mk_ver eq $ver,
           "B - Makefile.PL VERSION (" . ($mk_ver||'undef') . ") eq \$VERSION ($ver)");

        my $chg_ver;
        for my $line (split /\n/, $chg_text) {
            if ($line =~ /^(\d+\.\d+[\w.]*)/) { $chg_ver = $1; last }
        }
        ok(defined $chg_ver && $chg_ver eq $ver,
           "B - Changes top version (" . ($chg_ver||'undef') . ") eq \$VERSION ($ver)");

        my $prov_yml = _provides_versions_yml($meta_yml);
        my @yml_mm;
        for my $pkg (sort keys %$prov_yml) {
            push @yml_mm, "$pkg=$prov_yml->{$pkg}" if $prov_yml->{$pkg} ne $ver;
        }
        ok(!@yml_mm && %$prov_yml,
           "B - META.yml provides versions all eq \$VERSION ($ver) in $pm");
    }

    my $pm_version = _pm_version("$root/$pm_files[0]") if @pm_files;
    my $prov_json  = _provides_versions_json($meta_json);
    my @json_mm;
    for my $pkg (sort keys %$prov_json) {
        push @json_mm, "$pkg=$prov_json->{$pkg}"
            if defined $pm_version && $prov_json->{$pkg} ne $pm_version;
    }
    ok(!@json_mm && %$prov_json,
       "B - META.json provides versions all eq \$VERSION (" .
       ($pm_version||'undef') . ")");
}

sub count_B {
    my ($root) = @_;
    my @manifest = _manifest_files($root);
    my @pm_files = grep { /^lib\/.*\.pm$/ && -f "$root/$_" } @manifest;
    return scalar(@pm_files) * 6 + 1;
}

######################################################################
# Category C: Encoding Hygiene
######################################################################

sub check_C {
    my ($root) = @_;
    my @manifest = _manifest_files($root);
    my @pm_and_t = _manifest_pm_and_t($root);

    for my $f (@manifest) {
        my $abs = "$root/$f";
        if ($f =~ m{^doc/}) {
            ok(1, "C - US-ASCII: $f (documents may contain UTF-8 encoding)");
            next;
        }
        unless (-f $abs) {
            ok(0, "C - US-ASCII: $f (file missing)");
            next;
        }
        local *FH;
        open FH, "< $abs" or do { ok(0, "C - US-ASCII: $f (cannot open)"); next };
        binmode FH;
        my $bad = 0;
        while (<FH>) { if (/[^\x00-\x7F]/) { $bad = 1; last } }
        close FH;
        ok(!$bad, "C - US-ASCII only: $f");
    }

    for my $f (@pm_and_t) {
        my $abs = "$root/$f";
        next unless -f $abs;
        my @lines = _slurp_lines($abs);
        my @bad;
        my $n = 0;
        for my $line (@lines) {
            $n++;
            push @bad, $n if $line =~ /[ \t]+\r?$/;
        }
        ok(!@bad, "C - no trailing whitespace: $f");
    }

    for my $f (@pm_and_t) {
        my $abs = "$root/$f";
        next unless -f $abs;
        my $content = _slurp($abs);
        if (length $content) {
            ok(substr($content, -1) eq "\n", "C - ends with newline: $f");
        }
        else {
            ok(1, "C - ends with newline: $f (empty file, skipped)");
        }
    }
}

sub count_C {
    my ($root) = @_;
    my @manifest = _manifest_files($root);
    my @pm_and_t = _manifest_pm_and_t($root);
    return scalar(@manifest) + 2 * scalar(@pm_and_t);
}

######################################################################
# Category D: Perl 5.005_03 Compat (summary checks on .pm only)
######################################################################

sub check_D {
    my ($root) = @_;
    my @manifest = _manifest_files($root);
    my @pm_files = sort grep { /^lib\/.*\.pm$/ && -f "$root/$_" } @manifest;

    for my $pm (@pm_files) {
        my $text = _slurp("$root/$pm");
        my @lines = split /\n/, $text;
        my $code  = $text;
        $code =~ s/\n__END__\b.*\z//s;
        $code =~ s/^=[a-zA-Z].*?^=cut[ \t]*$//msg;

        my $d1 = $code =~
            /\$INC\{'warnings\.pm'\}\s*=.*?eval\s*['"]package warnings;\s*sub import/s;
        ok($d1, "D - warnings stub includes import() sub: $pm");

        my @our_hits = _scan_code("$root/$pm", qr/\bour\b/);
        ok(!@our_hits, "D - no 'our' keyword in code: $pm");

        my @syn = _scan_code("$root/$pm", qr/\b(?:say|given|state)\s*[\(\{]/);
        ok(!@syn, "D - no 5.6+ syntax (say/given/state): $pm");

        my @und = _scan_code("$root/$pm", qr/\bmy\s*\(\s*undef/);
        ok(!@und, "D - no 'my (undef, ...)' (5.10+ only): $pm");

        my $d5 = ($text =~ /\$VERSION\s*=\s*\$VERSION/);
        ok($d5, "D - \$VERSION self-assignment present: $pm");

        my $d6 = $code =~ /BEGIN\s*\{[^}]*pop\s+@INC[^}]*\}/s
              || $code =~ /pop @INC if \$INC\[-1\] eq '\.'/ ;
        ok($d6, "D - CVE-2016-1238 mitigation (pop \@INC): $pm");
    }
}

sub count_D {
    my ($root) = @_;
    my @manifest = _manifest_files($root);
    my @pm_files = grep { /^lib\/.*\.pm$/ && -f "$root/$_" } @manifest;
    return scalar(@pm_files) * 6;
}

######################################################################
# Category E: ina@CPAN Code Style
######################################################################

sub check_E {
    my ($root) = @_;
    my @pm_and_t = _manifest_pm_and_t($root);
    for my $f (@pm_and_t) {
        next unless -f "$root/$f";
        my @hits = _scan_code("$root/$f", qr/^\s*\}\s*els(?:e|if)\b/);
        ok(!@hits, "E - no '} else/elsif' on same line: $f");
        for my $h (@hits) { diag("  line $h->{line}: $h->{text}") }
    }
}

sub count_E {
    my ($root) = @_;
    my @pm_and_t = _manifest_pm_and_t($root);
    return scalar(@pm_and_t);
}

######################################################################
# Category F: META File Integrity
######################################################################

sub check_F {
    my ($root) = @_;
    my $meta_yml  = _slurp("$root/META.yml");
    my $meta_json = _slurp("$root/META.json");

    my $f1 = defined _yaml_str($meta_yml, 'name')
          && defined _yaml_str($meta_yml, 'version')
          && $meta_yml =~ /^license:/m;
    ok($f1, 'F - META.yml contains name/version/license keys');

    my $f2 = $meta_json =~ /^\s*\{/ && $meta_json =~ /"version"/;
    ok($f2, 'F - META.json appears to be valid JSON');

    my $min_perl = _yaml_str($meta_yml, 'minimum_perl_version');
    ok(defined $min_perl && $min_perl eq '5.00503',
       "F - META.yml minimum_perl_version is 5.00503 (got: " .
       ($min_perl||'undef') . ")");

    my $author = _yaml_str($meta_yml, 'author');
    $author = '' unless defined $author;
    if ($meta_yml =~ /^author:\s*\n(\s+-[^\n]+)/m) { $author = $1 }
    ok($author =~ /ina\@cpan\.org/i,
       'F - META.yml author contains ina@cpan.org');

    my $prov = _provides_versions_yml($meta_yml);
    ok(%$prov, 'F - META.yml provides section is non-empty');
}

sub count_F { return 5 }

######################################################################
# Category G: POD Completeness
######################################################################

sub check_G {
    my ($root) = @_;
    my @manifest = _manifest_files($root);
    my @pm_files = sort grep { /^lib\/.*\.pm$/ && -f "$root/$_" } @manifest;

    for my $pm (@pm_files) {
        my $text = _slurp("$root/$pm");
        ok($text =~ /^=head1\s+NAME\b/m,     "G - =head1 NAME present: $pm");
        ok($text =~ /^=head1\s+SYNOPSIS\b/m, "G - =head1 SYNOPSIS present: $pm");
        ok($text =~ /^=head1\s+DESCRIPTION\b/m,
                                             "G - =head1 DESCRIPTION present: $pm");
        my $opens  = () = $text =~ /^=[a-zA-Z]/mg;
        my $cuts   = () = $text =~ /^=cut\b/mg;
        my $g4 = $cuts >= 1 && $cuts <= $opens;
        ok($g4, "G - POD sections closed by =cut: $pm");
    }
}

sub count_G {
    my ($root) = @_;
    my @manifest = _manifest_files($root);
    my @pm_files = grep { /^lib\/.*\.pm$/ && -f "$root/$_" } @manifest;
    return scalar(@pm_files) * 4;
}

######################################################################
# Category H: Changes File Format
######################################################################

sub check_H {
    my ($root) = @_;
    my @lines = _slurp_lines("$root/Changes");
    ok(@lines, 'H - Changes file is non-empty');

    my $top_entry = '';
    for my $line (@lines) {
        $line =~ s/\r?\n$//;
        next unless $line =~ /^\d/;
        $top_entry = $line;
        last;
    }
    ok($top_entry =~ /^\d+\.\d+\S*\s+\d{4}-\d{2}-\d{2}/
    || $top_entry =~ /^\d+\.\d+\S*\s+\d{4}-\d{2}/
    || $top_entry =~ /^\d+\.\d+\S*\s+\S+/,
       "H - latest Changes entry has VERSION + DATE format: '$top_entry'");

    my $has_body = 0;
    my $in_entry = 0;
    for my $line (@lines) {
        $line =~ s/\r?\n$//;
        if ($line =~ /^\d+\.\d+/) { $in_entry = 1; next }
        if ($in_entry && $line =~ /^\s+\S/) { $has_body = 1; last }
        last if $in_entry && $line =~ /^\d+\.\d+/;
    }
    ok($has_body, 'H - latest Changes entry has indented description body');
}

sub count_H { return 3 }

######################################################################
# Category I: Makefile.PL
######################################################################

sub check_I {
    my ($root) = @_;
    my $text = _slurp("$root/Makefile.PL");
    ok($text =~ /WriteMakefile\s*\(/, 'I - Makefile.PL calls WriteMakefile()');
    ok($text =~ /'NAME'/ && $text =~ /'VERSION'/,
       'I - Makefile.PL contains NAME and VERSION keys');
    ok($text =~ /ina\@cpan\.org/, 'I - Makefile.PL AUTHOR contains ina@cpan.org');
    ok($text =~ /\$INC\{'warnings\.pm'\}.*?!defined.*?warnings::import/s
    || $text =~ /!defined.*?warnings::import.*?\$INC\{'warnings\.pm'\}/s,
       'I - Makefile.PL warnings stub guards with !defined(&warnings::import)');
    ok(_scan_code("$root/Makefile.PL", qr/open\s+my\b/) == 0,
       'I - Makefile.PL no lexical filehandle (open my)');
}

sub count_I { return 5 }

######################################################################
# Category J: Consistency
# Accepts optional overrides:
#   j2_stale => [ list of stale strings to check for ]
######################################################################

sub check_J {
    my ($root, %opt) = @_;
    my @manifest = _manifest_files($root);
    my @pm_files = sort grep { /^lib\/.*\.pm$/ && -f "$root/$_" } @manifest;
    my @t_files  = sort grep { /\.t$/  && -f "$root/$_" } @manifest;
    my $meta_yml = _slurp("$root/META.yml");

    # J1: no PREREQ_PM dep version equals module VERSION
    my $pm_ver = _pm_version("$root/$pm_files[0]") if @pm_files;
    my $j1 = 1;
    if ($meta_yml =~ /^requires:(.*?)(?=^\S)/ms) {
        my $block = $1;
        while ($block =~ /:\s*([\d._]+)/g) {
            if (defined $pm_ver && $1 eq $pm_ver) { $j1 = 0; last }
        }
    }
    ok($j1, 'J - PREREQ_PM: no core dep version equals module VERSION');

    # J2: BUGS AND LIMITATIONS has no stale entries
    my @stale = exists $opt{j2_stale} ? @{$opt{j2_stale}} : ();
    my $bugs_text = '';
    if (@pm_files) {
        my $pm_text = _slurp("$root/$pm_files[0]");
        if ($pm_text =~ /=head1 BUGS AND LIMITATIONS(.*?)^=head1/ms) {
            $bugs_text = $1;
        }
    }
    my $j2 = 1;
    for my $entry (@stale) {
        if (index($bugs_text, $entry) >= 0) { $j2 = 0; last }
    }
    ok($j2, 'J - BUGS AND LIMITATIONS: no stale removed-feature entries');

    # J3+J4: test file plan vs ok-comment count
    for my $tf (@t_files) {
        my @lines = _slurp_lines("$root/$tf");
        my @ok_comments;
        my $plan = undef;
        for my $line (@lines) {
            $line =~ s/\r?\n$//;
            push @ok_comments, $1 if $line =~ /^#\s+ok\s+(\d+)\b/;
            $plan = $1 if !defined $plan && $line =~ /^1\.\.(\d+)$/;
        }
        my %seen;
        my $unique = !grep { $seen{$_}++ } @ok_comments;
        ok($unique, "J - $tf: # ok N comments are unique");
        if (defined $plan) {
            ok(scalar(@ok_comments) <= $plan,
               "J - $tf: # ok comment count(" . scalar(@ok_comments) .
               ") does not exceed plan($plan)");
        }
        else {
            ok(1, "J - $tf: no plan line (skip/dynamic)");
        }
    }
}

sub count_J {
    my ($root) = @_;
    my @manifest = _manifest_files($root);
    my @t_files  = grep { /\.t$/ && -f "$root/$_" } @manifest;
    return 1 + 1 + 2 * scalar(@t_files);
}

######################################################################
# Category K: Coding Style
# Accepts optional overrides:
#   k3_exempt => 'regex-alternation-string'  (e.g. 'sch\b|outer_row\b')
######################################################################

sub check_K {
    my ($root, %opt) = @_;
    my @manifest = _manifest_files($root);
    my @pm_files = sort grep { /^lib\/.*\.pm$/ && -f "$root/$_" } @manifest;
    my $k3_exempt = exists $opt{k3_exempt}
        ? $opt{k3_exempt}
        : 'env\\b|opts\\b|args\\b';

    for my $pm (@pm_files) {
        my $text = _slurp("$root/$pm");
        $text =~ s/\n__END__\b.*\z//s;
        $text =~ s/^=[a-zA-Z].*?^=cut[ \t]*$//msg;
        my @lines = split /\n/, $text;
        my $n = 0;

                        # K1: comma followed by space
        my @k1_bad;
        {
            my $lineno = 0;
            for my $raw_line (split /\n/, $text) {
                $lineno++;
                my $s = $raw_line;
                $s =~ s/^\s*#.*$//; next unless $s =~ /\S/;
                $s =~ s/'(?:[^'\\]|\\.)*'/''/g;
                $s =~ s/"(?:[^"\\]|\\.)*"/""/g;
                $s =~ s{(?:s|m|qr|split\s*/)[^/]*/[^/]*/[gimsex]*}{}g;
                $s =~ s{/[^/]+/[gimsex]*}{}g;
                $s =~ s/#.*$//;
                if ($s =~ /,(?=[^\s\n\)\]\}\/])/) {
                    push @k1_bad, $lineno;
                }
            }
        }
        ok(!@k1_bad,
           "K - $pm: comma followed by space outside strings/regex"
           . (@k1_bad ? " (lines: @{[@k1_bad[0..(@k1_bad<3?$#k1_bad:2)]]})":""));

# K2: \@array should be [ @array ]
        $n = 0;
        my @k2_bad;
        for my $line (@lines) {
            $n++;
            next if $line =~ /^\s*#/;
            my $cl = $line;
            $cl =~ s/'[^']*'//g; $cl =~ s/"[^"]*"//g;
            $cl =~ s/#.*$//;
            if ($cl =~ /(?:push|unshift|return|=)\s*\\\@\w/) {
                push @k2_bad, $n;
            }
        }
        ok(!@k2_bad,
           "K - $pm: use [ \@array ] instead of \\\@array"
           . (@k2_bad ? " (lines: @{[@k2_bad[0..(@k2_bad<3?$#k2_bad:2)]]})":""));

        # K3: \%hash should be { %hash }
        $n = 0;
        my @k3_bad;
        for my $line (@lines) {
            $n++;
            next if $line =~ /^\s*#/;
            my $cl = $line;
            $cl =~ s/'[^']*'//g; $cl =~ s/"[^"]*"//g;
            $cl =~ s/#.*$//;
            if ($cl =~ /\\\%(?!$k3_exempt)\w+/) {
                push @k3_bad, $n;
            }
        }
        ok(!@k3_bad,
           "K - $pm: use { \%hash } instead of \\\%hash"
           . (@k3_bad ? " (lines: @{[@k3_bad[0..(@k3_bad<3?$#k3_bad:2)]]})":""));
    }
}

sub count_K {
    my ($root) = @_;
    my @manifest = _manifest_files($root);
    my @pm_files = grep { /^lib\/.*\.pm$/ && -f "$root/$_" } @manifest;
    return scalar(@pm_files) * 3;
}

1;
