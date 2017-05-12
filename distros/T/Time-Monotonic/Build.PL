use 5.008;
use strict;
use warnings FATAL => 'all';
use Module::Build;
use Config;

if (-d ".git") { # Are we in our development tree? If so, create MANIFEST.
    my ($dir, $manifest);
    open $manifest, ">", "MANIFEST" or die "MANIFEST: $!";
    print $manifest "MANIFEST\n";
    open $dir, 'git ls-files|' or die "Couldn't run git: $!";
    while (<$dir>) { print $manifest $_ unless /^\.|^monotonic_clock/ }
    open $dir, '-|', 'cd monotonic_clock && git ls-files' or die "Couldn't run git in monotonic_clock: $!";
    while (<$dir>) { print $manifest "monotonic_clock/$_" unless /^\./ }
}

# This hacks around the fact that we are using c_source to store files, when Module::Build expects directories.
my $custom = Module::Build->subclass(
    class => 'My::Builder',
    code  => <<'CUSTOM_CODE');
sub compile_c {
  my ($self, $file, %args) = @_;
  # Adding to c_source adds to include_dirs, too. Since we're adding files, remove them.
  @{$self->include_dirs} = grep { !/\.c$/ } @{$self->include_dirs};
  $self->SUPER::compile_c($file, %args);
}
CUSTOM_CODE

# autoconf style feature tester. Can't believe someone hasn't written this yet...
use ExtUtils::CBuilder;
my $cb = ExtUtils::CBuilder->new(quiet=>1);

sub test_function_lib {
    my ($function, $lib) = @_;
    my $source = 'conf_test.c';
    open my $conf_test, '>', $source or return;
    print $conf_test <<"C_CODE";
int main() {
    int $function();
    return $function();
}
C_CODE
    close $conf_test;

    my $conf_log='conf_test.log';
    my @saved_fhs = eval {
        open(my $oldout, ">&", \*STDOUT) or return;
        open(my $olderr, ">&", \*STDERR) or return;
        open(STDOUT, '>>', $conf_log) or return;
        open(STDERR, ">>", $conf_log) or return;
        ($oldout, $olderr)
    };

    my $worked = eval {
        my $obj = $cb->compile(source=>$source);
        my @junk = $cb->link_executable(objects => $obj, extra_linker_flags=>$lib);
        unlink $_ for (@junk, $obj, $source, $conf_log);
        return 1;
    };

    if (@saved_fhs) {
        open(STDOUT, ">&", $saved_fhs[0]) or return;
        open(STDERR, ">&", $saved_fhs[1]) or return;
        close($_) for (@saved_fhs);
    }

    $worked
}

my $have_gettimeofday = test_function_lib("gettimeofday", "");

my $backend;
for (["clock_gettime", ""],
     ["clock_gettime", "-lrt"],
     ["mach_absolute_time", ""],
     #["QueryPerformanceCounter", ""], # Doesn't work: win32 seems to mangle names, even in C code.
     ["time", ""],
    ) {
    if (test_function_lib(@$_)) {
        $backend = join(' ', @$_);
        last
    }
}
die "os unsupported" unless $backend;

my $builder = $custom->new(
    module_name         => 'Time::Monotonic',
    license             => 'perl',
    dist_author         => 'David Caldwell <david@porkrind.org>',
    dist_version_from   => 'lib/Time/Monotonic.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0.3604,
    },
    build_requires => {
        'Test::More' => 0,
    },
    meta_merge => {
      resources => {
        repository  => 'https://github.com/caldwell/Time-Monotonic',
      },
    },
    extra_compiler_flags => $have_gettimeofday ? '-DHAVE_GETTIMEOFDAY' : '',
    extra_linker_flags => $backend =~ /-lrt/ ? '-lrt' : '',
    include_dirs => 'monotonic_clock/include',
    c_source     => ['monotonic_clock/src/monotonic_common.c',
                     $backend =~ /clock_gettime/      ? 'monotonic_clock/src/monotonic_clock.c' :
                     $backend =~ /mach_absolute_time/ ? 'monotonic_clock/src/monotonic_mach.c'  :
                     $^O =~ /win32/i                  ? 'monotonic_clock/src/monotonic_win32.c' :
                                                        'monotonic_clock/src/monotonic_generic.c'
                    ],
);

$builder->create_build_script();
