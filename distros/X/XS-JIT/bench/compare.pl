#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(time);
use File::Path qw(remove_tree);

# Clean up before starting
remove_tree('_Inline') if -d '_Inline';
remove_tree('_CACHED_XS_bench') if -d '_CACHED_XS_bench';

print "=" x 60, "\n";
print "XS::JIT vs Inline::C Benchmark\n";
print "=" x 60, "\n\n";

# Test code - a simple class with constructor and accessor
my $c_code = <<'C_CODE';
SV* bench_new(SV* class_sv, ...) {
    dTHX;
    dXSARGS;
    const char* classname = SvPV_nolen(class_sv);
    HV* self_hv = newHV();

    /* Default value */
    hv_store(self_hv, "value", 5, newSViv(0), 0);

    /* Parse key-value args */
    int i;
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            STRLEN klen;
            const char* key = SvPV(ST(i), klen);
            SV* val = ST(i + 1);
            hv_store(self_hv, key, klen, newSVsv(val), 0);
        }
    }
    return sv_bless(newRV_noinc((SV*)self_hv), gv_stashpv(classname, GV_ADD));
}

SV* bench_get(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** val = hv_fetch(hv, "value", 5, 0);
    return val ? newSVsv(*val) : &PL_sv_undef;
}

SV* bench_set(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) return &PL_sv_undef;
    HV* hv = (HV*)SvRV(self);
    hv_store(hv, "value", 5, newSVsv(ST(1)), 0);
    return newSVsv(ST(1));
}

SV* bench_add(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) return newSViv(0);
    HV* hv = (HV*)SvRV(self);
    SV** val = hv_fetch(hv, "value", 5, 0);
    IV current = val ? SvIV(*val) : 0;
    IV add = SvIV(ST(1));
    IV result = current + add;
    hv_store(hv, "value", 5, newSViv(result), 0);
    return newSViv(result);
}
C_CODE

# ============================================
# Benchmark XS::JIT
# ============================================
print "Testing XS::JIT...\n";
print "-" x 40, "\n";

require XS::JIT;

my $jit_compile_start = time();
my $jit_ok = XS::JIT->compile(
    code      => $c_code,
    name      => 'BenchJIT::JIT_0',
    functions => {
        'BenchJIT::new'   => 'bench_new',
        'BenchJIT::get'   => 'bench_get',
        'BenchJIT::set'   => 'bench_set',
        'BenchJIT::add'   => 'bench_add',
    },
    cache_dir => '_CACHED_XS_bench',
);
my $jit_compile_time = time() - $jit_compile_start;

die "XS::JIT compile failed" unless $jit_ok;
printf "  First compile:  %.4f seconds\n", $jit_compile_time;

# Second compile (from cache / already loaded)
my $jit_cache_start = time();
XS::JIT->compile(
    code      => $c_code,
    name      => 'BenchJIT::JIT_0',
    functions => {
        'BenchJIT::new'   => 'bench_new',
        'BenchJIT::get'   => 'bench_get',
        'BenchJIT::set'   => 'bench_set',
        'BenchJIT::add'   => 'bench_add',
    },
    cache_dir => '_CACHED_XS_bench',
);
my $jit_cache_time = time() - $jit_cache_start;
printf "  Already loaded: %.6f seconds\n", $jit_cache_time;

# Runtime benchmark
my $jit_runtime_start = time();
for (1..10000) {
    my $obj = BenchJIT->new(value => 100);
    $obj->set(50);
    $obj->add(25);
    my $v = $obj->get();
}
my $jit_runtime = time() - $jit_runtime_start;
printf "  Runtime (10k iterations): %.4f seconds\n", $jit_runtime;

print "\n";

# ============================================
# Benchmark Inline::C
# ============================================
print "Testing Inline::C...\n";
print "-" x 40, "\n";

# Check if Inline::C is available
eval { require Inline };
if ($@) {
    print "  Inline::C not installed, skipping\n\n";
} else {
    my $inline_compile_start = time();

    eval q{
        package BenchInline;
        use Inline C => <<'END_C';

SV* inline_new(SV* class_sv, ...) {
    dTHX;
    dXSARGS;
    const char* classname = SvPV_nolen(class_sv);
    HV* self_hv = newHV();

    hv_store(self_hv, "value", 5, newSViv(0), 0);

    int i;
    for (i = 1; i < items; i += 2) {
        if (i + 1 < items) {
            STRLEN klen;
            const char* key = SvPV(ST(i), klen);
            SV* val = ST(i + 1);
            hv_store(self_hv, key, klen, newSVsv(val), 0);
        }
    }
    return sv_bless(newRV_noinc((SV*)self_hv), gv_stashpv(classname, GV_ADD));
}

SV* inline_get(SV* self, ...) {
    dTHX;
    HV* hv = (HV*)SvRV(self);
    SV** val = hv_fetch(hv, "value", 5, 0);
    return val ? newSVsv(*val) : &PL_sv_undef;
}

SV* inline_set(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) return &PL_sv_undef;
    HV* hv = (HV*)SvRV(self);
    hv_store(hv, "value", 5, newSVsv(ST(1)), 0);
    return newSVsv(ST(1));
}

SV* inline_add(SV* self, ...) {
    dTHX;
    dXSARGS;
    if (items < 2) return newSViv(0);
    HV* hv = (HV*)SvRV(self);
    SV** val = hv_fetch(hv, "value", 5, 0);
    IV current = val ? SvIV(*val) : 0;
    IV add = SvIV(ST(1));
    IV result = current + add;
    hv_store(hv, "value", 5, newSViv(result), 0);
    return newSViv(result);
}

END_C

        sub new {
            my $class = shift;
            return inline_new($class, @_);
        }
        sub get { inline_get($_[0]) }
        sub set { inline_set(@_) }
        sub add { inline_add(@_) }
    };

    my $inline_compile_time = time() - $inline_compile_start;

    if ($@) {
        print "  Inline::C compile failed: $@\n";
    } else {
        printf "  First compile:  %.4f seconds\n", $inline_compile_time;

        # Runtime benchmark
        my $inline_runtime_start = time();
        for (1..10000) {
            my $obj = BenchInline->new(value => 100);
            $obj->set(50);
            $obj->add(25);
            my $v = $obj->get();
        }
        my $inline_runtime = time() - $inline_runtime_start;
        printf "  Runtime (10k iterations): %.4f seconds\n", $inline_runtime;

        print "\n";
        print "=" x 60, "\n";
        print "Summary\n";
        print "=" x 60, "\n";
        printf "First compile speedup: %.1fx faster\n", $inline_compile_time / $jit_compile_time;
        printf "Runtime performance:   %.2fx %s\n",
            $inline_runtime > $jit_runtime
                ? ($inline_runtime / $jit_runtime, "faster (XS::JIT)")
                : ($jit_runtime / $inline_runtime, "faster (Inline::C)");
    }
}

# Clean up
remove_tree('_CACHED_XS_bench') if -d '_CACHED_XS_bench';

print "\nDone.\n";
