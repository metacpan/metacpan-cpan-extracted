use 5.010;
use strict;
use warnings;
use File::Basename qw(dirname);
use File::Spec;
use lib File::Spec->catdir(dirname(__FILE__), '..', 'lib');
use Test::More;
use FFI::CheckLib qw(find_lib_or_die);
use IPC::Open3;
use Symbol qw(gensym);
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use Text::Bidi qw(log2vis fribidi_version_num unicode_version);
use Text::Bidi::Constants;

# Runtime prerequisites can include an older Text::Bidi installation. Test this
# distribution even under plain prove or a release runner with a different @INC.
my $source_lib = File::Spec->catdir(dirname(__FILE__), '..', 'lib');
for my $module (qw(Text/Bidi.pm Text/Bidi/private.pm)) {
    my $expected = abs_path(File::Spec->catfile($source_lib, split m{/}, $module));
    my $loaded = abs_path($INC{$module});
    BAIL_OUT("$module was preloaded from $loaded; expected $expected. "
        . 'Run tests without preloading another Text::Bidi installation.')
        unless defined($loaded) && defined($expected) && $loaded eq $expected;
}

like fribidi_version_num(), qr/^\d+\.\d+\.\d+$/, 'runtime library version';
like unicode_version(), qr/^\d+\.\d+\.\d+$/, 'runtime Unicode version';

for my $name (qw(FRIBIDI_TYPE_LTR FRIBIDI_PAR_RTL FRIBIDI_FLAGS_DEFAULT
                 FRIBIDI_BRACKET_OPEN_MASK FRIBIDI_JOINING_TYPE_D_VAL
                 version_info unicode_version)) {
    no strict 'refs';
    my $before = ${"Text::Bidi::private::$name"};
    my $ok = eval { ${"Text::Bidi::private::$name"} = 0; 1 };
    ok !$ok, "$name is read-only";
    is ${"Text::Bidi::private::$name"}, $before, "$name remains unchanged";
}
ok !eval { $Text::Bidi::Par::RTL = 0; 1 }, 'public constant aliases remain read-only';

my $bidi = Text::Bidi->new;
my $chars = $bidi->utf8_to_internal("\x{5d0}\x{5d1}");
my $types = $bidi->get_bidi_types($chars);
my ($max, $dir, $levels) = Text::Bidi::private::get_par_embedding_levels(
    $$types, $Text::Bidi::Par::ON);
is $max, 2, 'legacy embedding function returns maximum level plus one';
is $dir, $Text::Bidi::Par::RTL, 'legacy embedding function resolves direction';
is_deeply $levels, [1, 1], 'legacy embedding levels';
is_deeply scalar Text::Bidi::private::get_par_embedding_levels(
    $$types, $Text::Bidi::Par::ON), [1, 1], 'scalar context returns final output';
is_deeply [Text::Bidi::private::log2vis_get_embedding_levels(
    $$types, $Text::Bidi::Par::ON)], [$max, $dir, $levels],
    'deprecated embedding entry point retains its calling convention';
for my $lookup (\&Text::Bidi::private::get_type,
                \&Text::Bidi::private::get_type_internal) {
    is $lookup->(0x5d0), $types->[0], 'deprecated character type lookup';
}

my $types_snapshot = [@$types];
$bidi->get_bidi_types($bidi->utf8_to_internal('abc'));
is_deeply [@$types], $types_snapshot, 'native output survives subsequent calls';

my $ltr_types = $bidi->get_bidi_types($bidi->utf8_to_internal('a'));
my (undef, $sentinel_map) = $bidi->reorder_map(
    $ltr_types, 0, 1, $Text::Bidi::Par::LTR, [-1]);
is_deeply $sentinel_map, [~0], 'map sentinel retains unsigned Perl representation';

my (undef, $packed) = Text::Bidi::private::utf8_to_internal("a\0b");
my ($bytes, $text) = Text::Bidi::private::internal_to_utf8($packed);
is $bytes, 3, 'conversion returns byte count including embedded NUL';
is $text, "a\0b", 'conversion does not stop at NUL';
is Text::Bidi::private::get_par_direction(''), $Text::Bidi::Par::ON,
    'empty direction lookup';
is_deeply Text::Bidi::private::get_joining_types(''), [], 'empty joining lookup';
is_deeply Text::Bidi::private::get_bracket_types('', ''), [], 'empty bracket lookup';
is Text::Bidi::private::shape_mirroring('', ''), '', 'empty mirroring';
is_deeply Text::Bidi::private::join_arabic('', '', ''), [], 'empty Arabic joining';
is_deeply [Text::Bidi::private::shape_arabic(0, '', '', '')], [[], ''],
    'empty Arabic shaping';

# Exercise library selection in a fresh interpreter: the parent already has
# its library loaded. Keep stderr separate so loader failures are observable.
sub load_with_library {
    my ($library) = @_;
    local $ENV{TEXT_BIDI_FRIBIDI_LIB} = $library;
    # @INC may have changed since the parent loaded Text::Bidi. Require those
    # exact files, and register their usual names before dependent modules load.
    # Neither an installed frontend nor an installed backend may replace them.
    my @sources = map {
        abs_path($INC{$_}) or die "Cannot locate loaded module $_\n"
    } qw(Text/Bidi/private.pm Text/Bidi.pm);
    my @inc = grep { !ref } @INC;
    local $ENV{PERL5LIB} = '';
    local $ENV{PERL5OPT} = '';
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $^X, '-e', q{
        BEGIN {
            my ($backend, $frontend) = splice @ARGV, 0, 2;
            @INC = @ARGV;
            @ARGV = ();
            require $backend;
            $INC{'Text/Bidi/private.pm'} = $backend;
            require $frontend;
            $INC{'Text/Bidi.pm'} = $frontend;
        }
        print scalar Text::Bidi::log2vis("abc");
    }, '--', @sources, @inc);
    close $in;
    local $/;
    my $stdout = <$out>;
    my $stderr = <$err>;
    waitpid $pid, 0;
    return ($?, $stdout, $stderr);
}

my $library = $ENV{TEXT_BIDI_FRIBIDI_LIB} || find_lib_or_die(lib => 'fribidi');
my ($status, $stdout, $stderr) = load_with_library($library);
is $status, 0, 'explicit shared-library path loads successfully' or diag $stderr;
is $stdout, 'abc', 'public API works with explicit library path';
($status, $stdout, $stderr) = load_with_library($library . '.does-not-exist');
ok $status != 0, 'missing explicitly selected library fails to load';
like $stderr, qr/FriBidi|fribidi/, 'missing-library diagnostic identifies FriBidi';

# An older installed copy can handle ASCII without loading the FFI backend.
# Startup include paths must not let that copy replace the module under test.
my $installed = tempdir(CLEANUP => 1);
mkdir "$installed/Text" or die "Cannot create fixture directory: $!";
open my $old, '>', "$installed/Text/Bidi.pm" or die "Cannot write fixture: $!";
print {$old} "package Text::Bidi; sub log2vis { return 'abc' } 1;\n";
close $old or die "Cannot close fixture: $!";
mkdir "$installed/Text/Bidi" or die "Cannot create backend fixture directory: $!";
open my $old_backend, '>', "$installed/Text/Bidi/private.pm"
    or die "Cannot write backend fixture: $!";
print {$old_backend} "die qq(Unrelated installed private backend loaded\\n);\n";
close $old_backend or die "Cannot close backend fixture: $!";
{
    local $ENV{PERL5OPT} = "-I$installed";
    ($status, $stdout, $stderr) = load_with_library($library);
    is $status, 0, 'valid library loads despite a conflicting startup include path'
        or diag $stderr;
    is $stdout, 'abc', 'public API works despite a conflicting startup include path';
    ($status, $stdout, $stderr) = load_with_library($library . '.does-not-exist');
    ok $status != 0, 'missing library still fails with a conflicting startup include path';
    like $stderr, qr/FriBidi|fribidi/,
        'conflicting startup include path does not bypass the FriBidi loader';
}

# A module can already be loaded when a harness or dependency changes @INC.
# Copying that later search order does not identify the loaded module files.
{
    local @INC = ($installed, @INC);
    ($status, $stdout, $stderr) = load_with_library($library);
    is $status, 0, 'valid library loads after the parent search path changes'
        or diag $stderr;
    is $stdout, 'abc', 'loaded public API survives a later search path change';
    ($status, $stdout, $stderr) = load_with_library($library . '.does-not-exist');
    ok $status != 0, 'missing library still fails after the parent search path changes';
    like $stderr, qr/FriBidi|fribidi/,
        'a later search path change does not bypass the loaded FriBidi backend';
}

done_testing;
