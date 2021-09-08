use File::Temp qw(tempfile);
use Module::Path::More qw(module_path);
use Test::More 0.98;

sub _test_lib {
    my $which = shift;
    my %args = @_;

    my $name = $args{name} || "args: " . join(" ", @{$args{args}});
    subtest $name => sub {
        for my $ent (
            (map {+{module=>$_, ok=>1}} @{$args{require_ok} || []}),
            (map {+{module=>$_, ok=>0}} @{$args{require_nok} || []}),
        ) {
            my @system_args = (
                $^X,
                (map {"-I$_"} @{ $args{extra_libs} || []}),
                "-Mlib::$which". (@{$args{args}} ? "=".
                                      join(",",@{$args{args}}):""),
                "-e",
                "use $ent->{module}",
            );
            note "system: " . join(" ", @system_args);
            system(@system_args);
            my $child_err = $?;
            if ($ent->{ok}) {
                unless (ok(!$child_err, "require $ent->{module} ok")) {
                    local @INC = (
                        @{ $args{extra_lib} || [] },
                        @main::ORIG_INC,
                    );
                    my $path = module_path(module => $ent->{module});
                    diag "Path for module $ent->{module}: " .
                        ($path // "(not found)");
                }
            } else {
                ok( $child_err, "require $ent->{module} nok");
            }
        }
    };
}

sub test_lib_filter {
    _test_lib('filter', @_);
}

sub test_lib_allow {
    _test_lib('allow', @_);
}

sub test_lib_disallow {
    _test_lib('disallow', @_);
}

1;
