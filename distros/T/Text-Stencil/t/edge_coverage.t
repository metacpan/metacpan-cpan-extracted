use strict; use warnings;
use Test::More;
use Config;
use Text::Stencil;

sub render1 { Text::Stencil->new(row => $_[0])->render($_[1]) }

# --- count / coalesce must be the first transform (compile-time error) ---
{
    ok eval { Text::Stencil->new(row => '{0:count}'); 1 },         'count as first transform ok';
    ok eval { Text::Stencil->new(row => '{0:count|pad:5}'); 1 },   'count|pad ok (count first)';
    ok eval { Text::Stencil->new(row => '{0:coalesce:a:b}'); 1 },  'coalesce as first transform ok';
    ok !eval { Text::Stencil->new(row => '{0:uc|count}'); 1 },     'count mid-chain dies';
    like $@, qr/count.*first transform/, '  with a clear message';
    ok !eval { Text::Stencil->new(row => '{0:trim|coalesce:x}'); 1 }, 'coalesce mid-chain dies';
    like $@, qr/coalesce.*first transform/, '  with a clear message';
}

# --- base64 padding across all slen % 3 residues (incl. 1-byte => "==") ---
{
    my $b = Text::Stencil->new(row => '{0:base64}');
    is $b->render([['H']]),     'SA==',     'base64 1 byte  -> 2 pad';
    is $b->render([['He']]),    'SGU=',     'base64 2 bytes -> 1 pad';
    is $b->render([['Hel']]),   'SGVs',     'base64 3 bytes -> no pad';
    is $b->render([['Hell']]),  'SGVsbA==', 'base64 4 bytes -> 2 pad';
    is $b->render([['Hello']]), 'SGVsbG8=', 'base64 5 bytes -> 1 pad';
    my $u = Text::Stencil->new(row => '{0:base64url}');
    is $u->render([['H']]),     'SA',       'base64url 1 byte (no padding)';
}

# --- error path: from_file on a missing file dies clearly ---
{
    ok !eval { Text::Stencil->from_file('/no/such/stencil/file.tpl'); 1 }, 'from_file missing dies';
    like $@, qr/can't open/, '  with a clear message';
}

# --- an unknown transform name is a compile-time error ----------------------
# It used to fall through to raw, so a typo in an escaping transform emitted
# the value unescaped with no indication anything was wrong.
{
    eval { Text::Stencil->new(row => '{0:xyzzy}') };
    like $@, qr/unknown transform 'xyzzy'/, 'unknown transform is rejected';
    eval { Text::Stencil->new(row => '{0:hmtl}') };
    like $@, qr/unknown transform 'hmtl'/,  '  ...including a typo for an escaping one';
    ok eval { Text::Stencil->new(row => '{0:raw}'); 1 }, 'raw itself still compiles';

    # a stray literal brace lands in the same code path; the mixed-mode
    # diagnosis is the useful one there, so it must still win
    eval { Text::Stencil->new(row => '.cls { color: red } {0:raw}') };
    like $@, qr/literal delimiter/, 'a stray literal brace still gets the better message';
}

# --- formatting edge cases (happy paths the suite did not cover) ---
{
    is render1('{0:plural:item:items}', [[-1]]),     '-1 items',      'plural negative keeps sign + plural form';
    is render1('{0:plural:item:items}', [[1]]),      '1 item',        'plural one is singular';
    SKIP: {
        # these literals exceed 2**53, so a 32-bit-IV perl stores them as NVs and
        # rounds; the transform is fine, the oracle just cannot be written there
        skip 'needs 64-bit IVs', 6 if $Config{ivsize} < 8;
        is render1('{0:int_comma}', [[1700000000000000]]),     '1,700,000,000,000,000',      'int_comma 16-digit (microsecond ts) no overflow';
        is render1('{0:int_comma}', [[-1234567890123456789]]), '-1,234,567,890,123,456,789', 'int_comma 19-digit negative no overflow';
        # These pass on any perl whose IV is a C long, so they cannot fail here;
        # they pin the contract for the platforms where it is not (Win64, and
        # ILP32 with 64-bit ints), where a C long holds half of an IV.
        is render1('{0:int}',          [['3000000000']]),          '3000000000',          'int past 2**31';
        is render1('{0:int_comma}',    [['3000000000']]),          '3,000,000,000',       'int_comma past 2**31';
        is render1('{0:sprintf:%d}',   [['3000000000']]),          '3000000000',          'sprintf %d past 2**31';
        is render1('{0:sprintf:%d}',   [['9223372036854775807']]), '9223372036854775807', 'sprintf %d at IV_MAX';
    }
    is render1('{0:number_si}', [[-1500]]),         '-1.5K',         'number_si negative';
    is render1('{0:bytes_si}',  [[1099511627776]]), '1.0 TB',        'bytes_si TB range';
    is render1('{0:elapsed}',   [[90061]]),         '1d 1h 1m 1s',   'elapsed days+h+m+s';
    my $ago = Text::Stencil->new(row => '{0:ago}')->render([[ time() + 7200 ]]);
    like $ago, qr/future/, 'ago future timestamp';
}

# --- render_sorted descending in hash mode (only ascending was covered) ---
{
    my $s = Text::Stencil->new(row => '{name},');
    my $asc  = $s->render_sorted([{name=>'b'},{name=>'a'},{name=>'c'}], 'name');
    my $desc = $s->render_sorted([{name=>'b'},{name=>'a'},{name=>'c'}], 'name', {descending=>1});
    is $asc,  'a,b,c,', 'render_sorted hash ascending';
    is $desc, 'c,b,a,', 'render_sorted hash descending';
}

done_testing;
