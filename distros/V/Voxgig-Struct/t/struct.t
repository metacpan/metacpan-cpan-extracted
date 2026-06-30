#!perl
# Corpus test runner: loads ../build/test/test.json and runs the test sets
# the canonical TS test suite drives. Each subtest mirrors one runset name.

use 5.018;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Voxgig::Struct qw();

my $corpus_path = "$FindBin::Bin/../../build/test/test.json";

unless (-e $corpus_path) {
    plan skip_all => "Corpus file not found: $corpus_path";
}

# Use the in-tree insertion-ordered parser so map key order matches canonical.
my $text = do {
    open my $fh, '<:raw', $corpus_path or die "Cannot open $corpus_path: $!";
    local $/;
    <$fh>;
};

my $spec = Voxgig::Struct::parse_json($text);
my $struct_spec = $spec->{struct};

sub canon {
    my ($v) = @_;
    # Map keys aren't significant for equality — sort them so the
    # comparison ignores insertion order (matches node's deepStrictEqual).
    return Voxgig::Struct::_stringify_inner($v, 1);
}

# Run a single set with a "subject" callback that takes `in` and returns the
# computed result. The canonical out lives at entry->{out}.
sub runset {
    my ($label, $entries, $subject) = @_;
    return unless $entries;
    return unless Voxgig::Struct::islist($entries);
    my $idx = 0;
    my $pass = 0;
    my $fail = 0;
    for my $entry (@$entries) {
        next unless Voxgig::Struct::ismap($entry);
        my $in_val = $entry->{in};
        my $expected = exists $entry->{out} ? $entry->{out} : undef;
        my $err_field = $entry->{err};
        my $got = eval { $subject->($in_val, $entry) };
        my $err = $@;
        if (defined $err_field) {
            # An error is expected: the subject must throw, and (unless err is
            # literally `true`) the thrown message must contain the expected
            # substring or match the /regex/.
            my $this = $idx;
            $idx++;
            if (!$err) {
                $fail++;
                diag("[$label#$this] expected error but none thrown (err=" . canon($err_field) . ")");
                next;
            }
            my $msg = "$err";
            my $ok;
            if (Voxgig::Struct::is_jbool($err_field)) {
                $ok = ${$err_field} ? 1 : 0;   # err: true → any error
            }
            elsif (!ref $err_field) {
                if ($err_field =~ m{^/(.+)/$}s) {
                    my $re = $1;
                    $ok = ($msg =~ /$re/) ? 1 : 0;
                }
                else {
                    $ok = (index(lc $msg, lc $err_field) >= 0) ? 1 : 0;
                }
            }
            else {
                $ok = 1;
            }
            if ($ok) { $pass++ }
            else {
                $fail++;
                diag("[$label#$this] err mismatch: expected=" . canon($err_field) . " got=[$msg]");
            }
            next;
        }
        my $got_j = canon($got);
        my $exp_j = canon($expected);
        if ($got_j eq $exp_j) {
            $pass++;
        }
        else {
            $fail++;
            diag("[$label#$idx] expected=$exp_j got=$got_j");
        }
        $idx++;
    }
    ok($fail == 0, "$label: $pass/" . ($pass + $fail));
}

# Minor subtests.
my $minor = $struct_spec->{minor};
if (Voxgig::Struct::ismap($minor)) {
    runset('minor.isnode',    $minor->{isnode}{set},
           sub { Voxgig::Struct::isnode($_[0]) ? Voxgig::Struct::JTRUE() : Voxgig::Struct::JFALSE() });
    runset('minor.ismap',     $minor->{ismap}{set},
           sub { Voxgig::Struct::ismap($_[0]) ? Voxgig::Struct::JTRUE() : Voxgig::Struct::JFALSE() });
    runset('minor.islist',    $minor->{islist}{set},
           sub { Voxgig::Struct::islist($_[0]) ? Voxgig::Struct::JTRUE() : Voxgig::Struct::JFALSE() });
    runset('minor.iskey',     $minor->{iskey}{set},
           sub { Voxgig::Struct::iskey($_[0]) ? Voxgig::Struct::JTRUE() : Voxgig::Struct::JFALSE() });
    runset('minor.isempty',   $minor->{isempty}{set},
           sub { Voxgig::Struct::isempty($_[0]) ? Voxgig::Struct::JTRUE() : Voxgig::Struct::JFALSE() });
    runset('minor.size',      $minor->{size}{set},
           sub { Voxgig::Struct::size($_[0]) });
    runset('minor.keysof',    $minor->{keysof}{set},
           sub { Voxgig::Struct::keysof($_[0]) });
    runset('minor.haskey',    $minor->{haskey}{set},
           sub {
               my $in = $_[0];
               Voxgig::Struct::haskey($in->{src}, $in->{key}) ? Voxgig::Struct::JTRUE() : Voxgig::Struct::JFALSE();
           });
    runset('minor.getprop',   $minor->{getprop}{set},
           sub {
               my $in = $_[0];
               my $r = Voxgig::Struct::getprop($in->{val}, $in->{key}, $in->{alt});
               Voxgig::Struct::is_none($r) ? undef : $r;
           });
    runset('minor.clone',     $minor->{clone}{set},
           sub { Voxgig::Struct::clone($_[0]) });
    runset('minor.escre',     $minor->{escre}{set},
           sub { Voxgig::Struct::escre($_[0]) });
    runset('minor.escurl',    $minor->{escurl}{set},
           sub { Voxgig::Struct::escurl($_[0]) });
    runset('minor.stringify', $minor->{stringify}{set},
           sub {
               my $in = $_[0];
               if (Voxgig::Struct::ismap($in)) {
                   return Voxgig::Struct::stringify($in->{val}, $in->{max});
               }
               return Voxgig::Struct::stringify($in);
           });
    runset('minor.slice',     $minor->{slice}{set},
           sub {
               my $in = $_[0];
               return Voxgig::Struct::slice($in->{val}, $in->{start}, $in->{end});
           });
    # filter checks are named in the corpus; map them to predicates over [k,v].
    my %filter_checks = (
        gt3 => sub { $_[0][1] > 3 },
        lt3 => sub { $_[0][1] < 3 },
    );
    runset('minor.filter',    $minor->{filter}{set},
           sub {
               my $in = $_[0];
               return Voxgig::Struct::filter($in->{val}, $filter_checks{$in->{check}});
           });
    runset('minor.isfunc',    $minor->{isfunc}{set},
           sub { Voxgig::Struct::isfunc($_[0]) ? Voxgig::Struct::JTRUE() : Voxgig::Struct::JFALSE() });
    runset('minor.getelem',   $minor->{getelem}{set},
           sub {
               my $in = $_[0];
               my $r = Voxgig::Struct::getelem($in->{val}, $in->{key}, $in->{alt});
               Voxgig::Struct::is_none($r) ? undef : $r;
           });
    runset('minor.items',     $minor->{items}{set},
           sub { Voxgig::Struct::items($_[0]) });
    runset('minor.flatten',   $minor->{flatten}{set},
           sub { my $in = $_[0]; Voxgig::Struct::flatten($in->{val}, $in->{depth}) });
    runset('minor.typename',  $minor->{typename}{set},
           sub { Voxgig::Struct::typename($_[0]) });
    runset('minor.typify',    $minor->{typify}{set},
           sub { Voxgig::Struct::typify($_[0]) });
    runset('minor.join',      $minor->{join}{set},
           sub { my $in = $_[0]; Voxgig::Struct::join($in->{val}, $in->{sep}, $in->{url}) });
    runset('minor.jsonify',   $minor->{jsonify}{set},
           sub { my $in = $_[0]; Voxgig::Struct::jsonify($in->{val}, $in->{flags}) });
    runset('minor.pad',       $minor->{pad}{set},
           sub { my $in = $_[0]; Voxgig::Struct::pad($in->{val}, $in->{pad}, $in->{char}) });
    runset('minor.setprop',   $minor->{setprop}{set},
           sub { my $in = $_[0]; Voxgig::Struct::setprop(Voxgig::Struct::clone($in->{parent}), $in->{key}, $in->{val}) });
    runset('minor.delprop',   $minor->{delprop}{set},
           sub { my $in = $_[0]; Voxgig::Struct::delprop(Voxgig::Struct::clone($in->{parent}), $in->{key}) });
    # setpath returns the leaf key's PARENT node (canonical). The entry's
    # `match.args.0.store` records the store AFTER in-place mutation; verify it
    # here since runset only compares the return value to `out`.
    runset('minor.setpath',   $minor->{setpath}{set},
           sub {
               my ($in, $entry) = @_;
               my $store = $in->{store};
               my $r = Voxgig::Struct::setpath($store, $in->{path}, $in->{val});
               my $want_store = eval { $entry->{match}{args}{'0'}{store} };
               if (defined $want_store) {
                   my $got = canon($store);
                   my $exp = canon($want_store);
                   if ($got ne $exp) {
                       diag("[minor.setpath store-mutation] expected=$exp got=$got");
                       die "minor.setpath store mutation mismatch\n";
                   }
               }
               Voxgig::Struct::is_none($r) ? undef : $r;
           });
    runset('minor.strkey',    $minor->{strkey}{set},
           sub { Voxgig::Struct::strkey($_[0]) });
    runset('minor.pathify',   $minor->{pathify}{set},
           sub { my $in = $_[0]; Voxgig::Struct::pathify($in->{path}, $in->{from}) });
}

# Walk. Canonical test uses walkpath callback (appends `~path`).
if (Voxgig::Struct::ismap($struct_spec->{walk})) {
    my $walkpath = sub {
        my ($key, $val, $parent, $path) = @_;
        return $val if !defined $val || ref $val;
        return $val if Voxgig::Struct::is_jbool($val) || Voxgig::Struct::is_jnull($val);
        # Numbers don't participate; only strings annotated.
        my $is_str = !Scalar::Util::looks_like_number($val) || "$val" =~ /[^0-9eE.+\-]/;
        return $val unless $is_str;
        return $val . '~' . CORE::join('.', @$path);
    };
    runset('walk.basic', $struct_spec->{walk}{basic}{set},
           sub {
               my $in = Voxgig::Struct::clone($_[0]);
               return Voxgig::Struct::walk($in, $walkpath);
           });
}

# Merge.
if (Voxgig::Struct::ismap($struct_spec->{merge})) {
    runset('merge.basic', $struct_spec->{merge}{basic}{set},
           sub {
               my $in = $_[0];
               return Voxgig::Struct::merge($in);
           });
}

# Getpath.
if (Voxgig::Struct::ismap($struct_spec->{getpath})) {
    my $gp = $struct_spec->{getpath};
    runset('getpath.basic', $gp->{basic}{set},
           sub {
               my $in = $_[0];
               return Voxgig::Struct::getpath($in->{store}, $in->{path});
           });
    runset('getpath.relative', $gp->{relative}{set},
           sub {
               my $in = $_[0];
               my $dp = $in->{dpath};
               return Voxgig::Struct::getpath($in->{store}, $in->{path}, {
                   dparent => $in->{dparent},
                   (defined $dp ? (dpath => [ split /\./, $dp ]) : ()),
               });
           });
    runset('getpath.special', $gp->{special}{set},
           sub {
               my $in = $_[0];
               return Voxgig::Struct::getpath($in->{store}, $in->{path}, $in->{inj});
           });
    runset('getpath.handler', $gp->{handler}{set},
           sub {
               my $in = $_[0];
               return Voxgig::Struct::getpath(
                   { '$TOP' => $in->{store}, '$FOO' => sub { 'foo' } },
                   $in->{path},
                   { handler => sub { my ($inj, $val, $cur, $ref) = @_; $val->() } },
               );
           });
}

# Sentinels — null / undefined unification across the readers.
if (Voxgig::Struct::ismap($struct_spec->{sentinels})) {
    my $sn = $struct_spec->{sentinels};
    runset('sentinels.getprop_unify', $sn->{getprop_unify}{set},
           sub {
               my $in = $_[0];
               my $r = Voxgig::Struct::getprop($in->{val}, $in->{key}, $in->{alt});
               Voxgig::Struct::is_none($r) ? undef : $r;
           });
    runset('sentinels.getelem_absent', $sn->{getelem_absent}{set},
           sub {
               my $in = $_[0];
               my $r = Voxgig::Struct::getelem($in->{val}, $in->{key}, $in->{alt});
               Voxgig::Struct::is_none($r) ? undef : $r;
           });
    runset('sentinels.haskey_unify', $sn->{haskey_unify}{set},
           sub {
               my $in = $_[0];
               Voxgig::Struct::haskey($in->{val}, $in->{key})
                   ? Voxgig::Struct::JTRUE() : Voxgig::Struct::JFALSE();
           });
    runset('sentinels.isempty_unify', $sn->{isempty_unify}{set},
           sub { Voxgig::Struct::isempty($_[0]) ? Voxgig::Struct::JTRUE() : Voxgig::Struct::JFALSE() });
    runset('sentinels.isnode_unify', $sn->{isnode_unify}{set},
           sub { Voxgig::Struct::isnode($_[0]) ? Voxgig::Struct::JTRUE() : Voxgig::Struct::JFALSE() });
    runset('sentinels.stringify_null', $sn->{stringify_null}{set},
           sub { Voxgig::Struct::stringify($_[0]) });
}

# NULLMARK fixup — the canonical test runner replaces JSON nulls with
# "__NULL__" before running, and tests pass a `nullModifier` callback that
# swaps any string containing "__NULL__" back to "null". This lets the
# corpus encode "value is JSON null" without losing the distinction from
# "value is absent" via the cross-port `fixJSON` round-trip.
my $NULLMARK = '__NULL__';
my $fix_null;
$fix_null = sub {
    my ($v) = @_;
    if (Voxgig::Struct::is_jnull($v)) { return $NULLMARK }
    if (Voxgig::Struct::ismap($v)) {
        my $out = Voxgig::Struct::jm();
        for my $k (Voxgig::Struct::_map_keys($v)) {
            $out->{$k} = $fix_null->($v->{$k});
        }
        return $out;
    }
    if (Voxgig::Struct::islist($v)) {
        return [ map { $fix_null->($_) } @$v ];
    }
    return $v;
};
my $null_modifier = sub {
    my ($val, $key, $parent) = @_;
    return unless defined $parent && ref $parent;
    if (defined $val && !ref($val) && $val eq $NULLMARK) {
        if (Voxgig::Struct::ismap($parent)) { $parent->{$key} = Voxgig::Struct::JNULL }
        elsif (Voxgig::Struct::islist($parent)) { $parent->[$key] = Voxgig::Struct::JNULL }
    }
    elsif (defined $val && !ref($val) && index($val, $NULLMARK) >= 0) {
        my $s = $val;
        $s =~ s/\Q$NULLMARK\E/null/g;
        if (Voxgig::Struct::ismap($parent)) { $parent->{$key} = $s }
        elsif (Voxgig::Struct::islist($parent)) { $parent->[$key] = $s }
    }
};

# Inject — inject.basic is a single entry, not a set.
if (Voxgig::Struct::ismap($struct_spec->{inject})) {
    my $basic = $struct_spec->{inject}{basic};
    if (Voxgig::Struct::ismap($basic) && exists $basic->{in}) {
        my $got_b = Voxgig::Struct::inject(
            Voxgig::Struct::clone($basic->{in}{val}),
            $basic->{in}{store},
        );
        my $exp_b = $basic->{out};
        is(canon($got_b), canon($exp_b), 'inject.basic');
    }
    runset('inject.string', $struct_spec->{inject}{string}{set},
           sub {
               my $in = $_[0];
               my $val   = $fix_null->(Voxgig::Struct::clone($in->{val}));
               my $store = $fix_null->(Voxgig::Struct::clone($in->{store}));
               my $r = Voxgig::Struct::inject($val, $store, { modify => $null_modifier });
               return $r;
           });
    runset('inject.deep', $struct_spec->{inject}{deep}{set},
           sub {
               my $in = $_[0];
               return Voxgig::Struct::inject(
                   Voxgig::Struct::clone($in->{val}),
                   $in->{store});
           });
}

# Transform.
if (Voxgig::Struct::ismap($struct_spec->{transform})) {
    my $tx = $struct_spec->{transform};
    if (Voxgig::Struct::ismap($tx->{basic}) && exists $tx->{basic}{in}) {
        my $b = $tx->{basic};
        my $got = eval { Voxgig::Struct::transform(
            Voxgig::Struct::clone($b->{in}{data}),
            Voxgig::Struct::clone($b->{in}{spec}),
        ) };
        is(canon($got), canon($b->{out}), 'transform.basic');
    }
    for my $sec (qw(paths cmds each pack ref apply)) {
        runset("transform.$sec", $tx->{$sec}{set},
               sub {
                   my $in = $_[0];
                   return Voxgig::Struct::transform(
                       Voxgig::Struct::clone($in->{data}),
                       Voxgig::Struct::clone($in->{spec}),
                   );
               });
    }
    # transform.format uses { null: false } — no NULLMARK fixup applied to
    # input data, so genuine nulls flow through.
    runset('transform.format', $tx->{format}{set},
           sub {
               my $in = $_[0];
               return Voxgig::Struct::transform(
                   Voxgig::Struct::clone($in->{data}),
                   Voxgig::Struct::clone($in->{spec}),
               );
           });
    # transform.modify uses a string-prefixer modifier.
    runset('transform.modify', $tx->{modify}{set},
           sub {
               my $in = $_[0];
               return Voxgig::Struct::transform(
                   Voxgig::Struct::clone($in->{data}),
                   Voxgig::Struct::clone($in->{spec}),
                   { modify => sub {
                       my ($val, $key, $parent) = @_;
                       return unless defined $key && defined $parent && ref $parent;
                       return if ref $val;
                       return if !defined $val;
                       return if Voxgig::Struct::is_jbool($val) || Voxgig::Struct::is_jnull($val);
                       return unless Voxgig::Struct::_is_string_sv($val);
                       my $new = '@' . $val;
                       if (Voxgig::Struct::ismap($parent)) { $parent->{$key} = $new }
                       elsif (Voxgig::Struct::islist($parent)) { $parent->[$key] = $new }
                   }},
               );
           });
}

# Validate.
if (Voxgig::Struct::ismap($struct_spec->{validate})) {
    my $vd = $struct_spec->{validate};
    for my $sec (qw(basic child one exact invalid special)) {
        runset("validate.$sec", $vd->{$sec}{set},
               sub {
                   my $in = $_[0];
                   return Voxgig::Struct::validate(
                       Voxgig::Struct::clone($in->{data}),
                       Voxgig::Struct::clone($in->{spec}),
                       $in->{inj},
                   );
               });
    }
}

# Select. Apply NULLMARK fixup (the canonical runner does this by default
# with flags.null=true so a stored null encodes as "__NULL__" and exact-
# match has a string to match against rather than a "key missing" state).
# The runner ALSO fixJSONs the expected `out` for comparison.
if (Voxgig::Struct::ismap($struct_spec->{select})) {
    my $sl = $struct_spec->{select};
    for my $sec (qw(basic operators edge alts)) {
        my $entries = $sl->{$sec}{set};
        next unless Voxgig::Struct::islist($entries);
        for (my $i = 0; $i < @$entries; $i++) {
            my $entry = $entries->[$i];
            next unless Voxgig::Struct::ismap($entry);
            my $in = $entry->{in};
            my $obj   = $fix_null->(Voxgig::Struct::clone($in->{obj}));
            my $query = $fix_null->(Voxgig::Struct::clone($in->{query}));
            my $got = Voxgig::Struct::select($obj, $query);
            my $exp = $fix_null->(Voxgig::Struct::clone($entry->{out}));
            is(canon($got), canon($exp), "select.$sec#$i");
        }
    }
}

done_testing();
