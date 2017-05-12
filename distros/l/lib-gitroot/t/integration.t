#!/usr/bin/env perl

use Modern::Perl;

use lib::gitroot (); # we don't need it here. but we need to locate genuine lib::root in %INC

use File::Temp qw/tempdir/;
use File::Path;
use Test::More;
use File::Spec;
use Capture::Tiny qw/capture_merged/;

plan tests => 90;

my $tmp_dir = tempdir("XXXXXXXX", TMPDIR => 1, CLEANUP => 1);

my $libroot_dir = do {
    my $libroot_module = 'lib/gitroot.pm';
    my $libroot_dir = $INC{$libroot_module};
    $libroot_dir =~ s/\Q$libroot_module\E$//;
    $libroot_dir;
};


sub run_code
{
    my ($script_root, $inc_dir, $filename, $code, $symlink, %allcode) = @_;

    mkpath $script_root;

    $allcode{$filename} = $code;

    for (keys %allcode) {
        my $fname = $_ =~ m{^/} ? $_ : "$script_root/$_";
        open my $f, ">", $fname or die $fname, $!;
        print $f $allcode{$_};
        close $f;
    }

    my $actual_filename = "$script_root/$filename";
    if ($symlink) {
        symlink $actual_filename, $symlink or die;
        $actual_filename = $symlink;
    }

    my ($res, $status) = capture_merged {
        system $^X, '-I', $libroot_dir, '-I', $inc_dir, $actual_filename;
        $?;
    };
    unlink keys %allcode;
    ($res, $status);
}

sub regexp_for_lib
{
    my ($tmp_dir, $git_dir, $lib_dir) = @_;
    qr{^\Q$tmp_dir/$git_dir/$lib_dir\E$}m;
}

sub regexp_for_anydir
{
    my ($tmp_dir, $git_dir, $lib_dir) = @_;
    qr{^\Q$tmp_dir/$git_dir\E$}m;
}

sub test_case {
    my ($script_dir, $script_file, $git_dir) = @_;

    ok $script_dir =~ /^\Q$git_dir\E/;

    my $full_script_dir = "$tmp_dir/$script_dir";
    mkpath my $inc_dir = "$tmp_dir/$script_dir/inc";
    mkpath my $full_git_dir = "$tmp_dir/$git_dir/.git";

    my ($res, $status);

    ($res, $status) = run_code($full_script_dir, '.', $script_file, q{
        use lib::gitroot qw/:lib/;
        print join("\n", @INC);
    });
    is $status, 0;
    like $res, regexp_for_lib($tmp_dir, $git_dir, 'lib'), "should set lib";

    ($res, $status) = run_code($full_script_dir, '.', $script_file, q{
        use lib::gitroot lib => 'somelib';
        print join("\n", @INC);
    });
    is $status, 0;
    like $res, regexp_for_lib($tmp_dir, $git_dir, 'somelib'), "should set custom lib";

    ($res, $status) = run_code($full_script_dir, '.', $script_file, q{
        use lib::gitroot;
        print join("\n", @INC);
    });
    is $status, 0;
    unlike $res, regexp_for_anydir($tmp_dir, $git_dir), "should not set lib without lib tag";
    ($res, $status) = run_code($full_script_dir, '.', $script_file, q{
        use lib::gitroot qw/:set_root/;
        print join("\n", @INC);
    });
    is $status, 0;
    unlike $res, regexp_for_anydir($tmp_dir, $git_dir), "should not set lib with :set_root";

    ($res, $status) = run_code($full_script_dir, $inc_dir,
        'file.pl' => q{
            use mymod;
            use lib::gitroot qw/:set_root/;
            print join("\n", @INC);
        },
        undef,
        'inc/mymod.pm' => q{
            use lib::gitroot qw/:set_root/;
            1;
        }
    );

    isnt $status, 0;
    like $res, qr/Git Root already set/, "should not set root twice";

    ($res, $status) = run_code($full_script_dir, $inc_dir,
        'file.pl' => q{
            use mymod;
            use lib::gitroot qw/:lib/;
            print join("\n", @INC);
        },
        undef,
        'inc/mymod.pm' => q{
            use lib::gitroot qw/:lib/;
            print join("\n", @INC);
        }
    );

    isnt $status, 0;
    like $res, qr/Git Root already set/, "should not set root twice with lib tag";

    ($res, $status) = run_code($full_script_dir, $inc_dir,
        'file.pl' => q{
            use mymod;
            use lib::gitroot qw/:lib/;
            print join("\n", @INC);
        },
        undef,
        'inc/mymod.pm' => q{
            use lib::gitroot qw/:set_root/;
            print join("\n", @INC);
        }
    );

    isnt $status, 0;
    like $res, qr/Git Root already set/, "should not set root twice with lib and set_root";

    ($res, $status) = run_code($full_script_dir, $inc_dir,
        'file.pl' => q{
            use mymod1;
            use mymod2;
        },
        undef,
        'inc/mymod1.pm' => q{
            use lib::gitroot qw/:lib/;
            1;
        },
        'inc/mymod2.pm' => q{
            use lib::gitroot qw/:lib/;
            1;
        }
    );

    isnt $status, 0;
    like $res, qr/Git Root already set/, "should not set root twice when used from different modules";

    ($res, $status) = run_code($full_script_dir, $inc_dir,
        'file.pl' => q{
            use mymod1;
            use mymod2;
            print join("\n", @INC);
        },
        undef,
        'inc/commonmod.pm' => q{
            package commonmod;
            use lib::gitroot qw/:lib/;
            1;
        },
        'inc/mymod1.pm' => q{
            package mymod1;
            use commonmod;
            1;
        },
        'inc/mymod2.pm' => q{
            package mymod2;
            use commonmod;
            1;
        }
    );

    is $status, 0;
    unlike $res, qr/Git Root already set/, "should work fine when used from different modules indirectly";
    like $res, regexp_for_lib($tmp_dir, $git_dir, 'lib'), "should set custom lib";
}


test_case ('project', 'file.pl', 'project');
test_case ('project/scripts', 'file.pl', 'project');
test_case ('project/A/B', 'file.pl', 'project');
test_case ('project/A/B/C', 'file.pl', 'project');

mkpath "$tmp_dir/mainproject/scripts";
mkpath "$tmp_dir/mainproject/.git";
mkpath "$tmp_dir/symlinks";
mkpath "$tmp_dir/library";

my ($res, $status) = run_code("$tmp_dir/mainproject", "$tmp_dir/library",
    'script.pl' => q{
        use CommonMod;
        print join("\n", @INC);
    },
    undef,
    "$tmp_dir/library/CommonMod.pm" => q{
        package CommonMod;
        use lib::gitroot ();
        sub import {
            my ($module, $file) = caller();
            lib::gitroot->import(':lib', use_base_dir => $file)
        }
        1;
    }
);
is $status, 0;
like $res, qr{mainproject/lib};

($res, $status) = run_code("$tmp_dir/mainproject", "$tmp_dir/library",
    'script.pl' => q{
        use CommonMod;
        use SomeMod;
        print join("\n", @INC);
    },
    undef,
    "$tmp_dir/library/SomeMod.pm" => q{
        package SomeMod;
        use CommonMod;
        1;
    },
    "$tmp_dir/library/CommonMod.pm" => q{
        package CommonMod;
        use lib::gitroot ();
        sub import {
            my ($module, $file) = caller();
            lib::gitroot->import(':lib', use_base_dir => $file, ':once')
        }
        1;
    }
);
is $status, 0;
like $res, qr{mainproject/lib};


#
# find_git_dir
#

($res, $status) = run_code("$tmp_dir/mainproject", "$tmp_dir/library",
    'script.pl' => q{
        use lib::gitroot ();
        print lib::gitroot::find_git_dir();
    },
);
is $status, 0;
like $res, qr{mainproject}, "find_git_dir should work";

($res, $status) = run_code("$tmp_dir/mainproject", "$tmp_dir/library",
    'script.pl' => q{
        use lib::gitroot ();
        print lib::gitroot::find_git_dir(undef, resolve_symlink => 1);
    },
);
is $status, 0;
like $res, qr{mainproject}, "should work with resolve_symlink even if there is no symlink";

($res, $status) = run_code("$tmp_dir/mainproject", "$tmp_dir/library",
    'script.pl' => q{
        use lib::gitroot ();
        print lib::gitroot::find_git_dir(undef, resolve_symlink => 1);
    },
    "$tmp_dir/symlinks/myscript.pl"
);
is $status, 0;
like $res, qr{mainproject}, "should work with resolve_symlink if there is symlink";


1;
