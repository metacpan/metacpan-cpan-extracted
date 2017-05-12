use strict;
use warnings;
use utf8;
use lib 't/lib';
use Test::More;
use Test::Exception;
use Test::Win32::Unicode::Util;

use File::Spec::Functions;

use Win32::Unicode::Dir;
use Win32::Unicode::File;

use constant DIR_NAME => "I \x{2665} perl";

my $unicode = "\x{68ee}\x{9dd7}\x{5916}";

sub create_tree {
    my $dirname = DIR_NAME;
    my %args = @_;

    mkdirW $dirname or die $!;
    mkdirW "$dirname/$unicode" or die $!;
    touchW "$dirname/$unicode/$dirname.txt" or die $!;
    touchW "$dirname/$unicode/0" or die $!;

    my $wanted_files;
    if ($args{no_chdir}) {
        $wanted_files = {
            +catfile("$dirname/$unicode")              => 1,
            +catfile("$dirname/$unicode/$dirname.txt") => 1,
            +catfile("$dirname/$unicode/0")            => 1,
        };

    }
    else {
        $wanted_files = {
            $unicode       => 1,
            "$dirname.txt" => 1,
            '0'            => 1,
        };
    }

    my ($names, $dirs);
    if ($args{bydepth}) {
        $names = ["$dirname/$unicode/0", "$dirname/$unicode/$dirname.txt", "$dirname/$unicode"],
        $dirs  = ["$dirname/$unicode", "$dirname/$unicode", "$dirname"],
    }
    else {
        $names = ["$dirname/$unicode", "$dirname/$unicode/0", "$dirname/$unicode/$dirname.txt"],
        $dirs  = ["$dirname", "$dirname/$unicode", "$dirname/$unicode"],
    }

    return $dirname, $wanted_files, $names, $dirs;
}

sub __CLEANUP__ {
    my $dirname = DIR_NAME;
    unlinkW "$dirname/$unicode/0" or die $!;
    unlinkW "$dirname/$unicode/$dirname.txt" or die $!;
    rmdirW "$dirname/$unicode" or die $!;
    rmdirW $dirname or die $!;
}

sub wanted {
    my ($wanted_files, $names, $dirs) = @_;

    return sub {
        my $file = $_;
        my $args = shift;
        my $name = shift @$names;
        my $dir  = shift @$dirs;

        ok $wanted_files->{$_}++, 'file wanted';
        ok file_type(e => $file), 'file exists';
        is catfile($Win32::Unicode::Dir::name), catfile($name), '$Win32::Unicode::Dir::name is ok';
        is catfile($Win32::Unicode::Dir::dir), catfile($dir), '$Win32::Unicode::Dir is ok';
        is $file, $args->{file}, '$_ is $_[0]->{file}';
        is $Win32::Unicode::Dir::name, $args->{path}, '$name is $_[0]->{path}';
        is $Win32::Unicode::Dir::name, $args->{name}, '$name is $_[0]->{name}';
        is $Win32::Unicode::Dir::cwd, $args->{cwd}, '$cwd is $_[0]->{cwd}';
        is $Win32::Unicode::Dir::dir, $args->{dir}, '$dir is $_[0]->{dir}';
    };
}

subtest 'findW coderef' => sub {
    safe_dir {
        my ($dirname, $wanted_files, $names, $dirs) = create_tree;

        my $expects = +{ map { $_ => $wanted_files->{$_} + 1 } keys %$wanted_files };
        my $wanted  = wanted($wanted_files, $names, $dirs);

        lives_ok {
            findW $wanted, $dirname;
        } 'findW will be success';

        is_deeply $wanted_files, $expects, 'found all';

        __CLEANUP__;
    };
};

subtest 'findW hashref' => sub {
    safe_dir {
        my ($dirname, $wanted_files, $names, $dirs) = create_tree;

        my $expects = +{ map { $_ => $wanted_files->{$_} + 1 } keys %$wanted_files };
        my $wanted  = wanted($wanted_files, $names, $dirs);

        lives_ok {
            findW +{ wanted => $wanted }, $dirname;
        } 'findW will be success';

        is_deeply $wanted_files, $expects, 'found all';

        __CLEANUP__;
    };
};

subtest 'findW hashref - no_chdir' => sub {
    safe_dir {
        my ($dirname, $wanted_files, $names, $dirs) = create_tree(no_chdir => 1);

        my $expects = +{ map { $_ => $wanted_files->{$_} + 1 } keys %$wanted_files };
        my $wanted  = wanted($wanted_files, $names, $dirs);

        lives_ok {
            findW +{
                wanted   => $wanted,
                no_chdir => 1,
            }, $dirname;
        } 'findW will be success';

        is_deeply $wanted_files, $expects, 'found all';

        __CLEANUP__;
    };
};

subtest 'findW hashref - preprocess' => sub {
    safe_dir {
        my ($dirname) = create_tree(no_chdir => 1);

        my $wanted_files = { $unicode => 1 };
        my $expects = { map { $_ => $wanted_files->{$_} + 1 } keys %$wanted_files };
        my $wanted  = wanted($wanted_files, ["$dirname/$unicode"], [$dirname]);

        lives_ok {
            findW +{
                wanted     => $wanted,
                preprocess => sub {
                    grep { file_type d => $_ } @_
                },
            }, $dirname;
        } 'findW will be success';

        is_deeply $wanted_files, $expects, 'found all';

        __CLEANUP__;
    };
};

subtest 'findW hashref - postporcess' => sub {
    safe_dir {
        my ($dirname, $wanted_files, $names, $dirs) = create_tree;

        my $expects = { map { $_ => $wanted_files->{$_} + 1 } keys %$wanted_files };
        my $wanted  = wanted($wanted_files, $names, $dirs);
        my $post_process_dirs = ["$dirname/$unicode", $dirname];

        lives_ok {
            findW +{
                wanted      => $wanted,
                postprocess => sub {
                    my $cwd = shift @$post_process_dirs;
                    is catfile($cwd), catfile($Win32::Unicode::Dir::dir), 'post process directory';
                },
            }, $dirname;
        } 'findW will be success';

        is_deeply $wanted_files, $expects, 'found all';
        is_deeply $post_process_dirs, [], 'all dirs path';

        __CLEANUP__;
    };
};

subtest 'findW hashref - bydepth' => sub {
    safe_dir {
        my ($dirname, $wanted_files, $names, $dirs) = create_tree(bydepth => 1);

        my $expects = +{ map { $_ => $wanted_files->{$_} + 1 } keys %$wanted_files };
        my $wanted  = wanted($wanted_files, $names, $dirs);

        lives_ok {
            findW +{
                wanted  => $wanted,
                bydepth => 1,
            }, $dirname;
        } 'findW will be success';

        is_deeply $wanted_files, $expects, 'found all';

        __CLEANUP__;
    };
};

subtest 'finddepthW' => sub {
    safe_dir {
        my ($dirname, $wanted_files, $names, $dirs) = create_tree(bydepth => 1);

        my $expects = +{ map { $_ => $wanted_files->{$_} + 1 } keys %$wanted_files };
        my $wanted  = wanted($wanted_files, $names, $dirs);

        lives_ok {
            finddepthW $wanted, $dirname
        } 'finddepthW will be success';

        is_deeply $wanted_files, $expects, 'found all';

        __CLEANUP__;
    };
};

subtest 'rmtreeW' => sub {
    safe_dir {
        my ($dirname, undef, $names) = create_tree;
        ok rmtreeW $dirname, 'rmtreeW will be success';

        for my $name (@$names) {
            ok !file_type(e => $name), 'file not exists';
        }
    };
};

subtest 'mkpathW' => sub {
    safe_dir {
        my $dirname = DIR_NAME;
        my $nested_dirname = "$dirname/$unicode";
        my $names = [$dirname, "$dirname/$unicode"];

        for (@$names) {
            ok !file_type(d => $_), 'directory not found';
        }

        ok mkpathW($nested_dirname), 'mkpathW will be success';

        for (@$names) {
            ok file_type(d => $_), 'directory exists';
        }

        rmtreeW $_ for @$names;
    };
};

subtest 'cptreeW - whole copy' => sub {
    safe_dir {
        my ($dirname, undef, $names) = create_tree;
        my $target = "\x{2603}";
        mkdirW $target;

        ok cptreeW($dirname, $target), 'cptreeW will be success';

        dump_tree '.';

        for (@$names) {
            ok file_type(e => catfile $target, $_), 'file exists';
        }

        rmtreeW $_ for dir_list '.';
    };
};

subtest 'cptreeW - content copy' => sub {
    safe_dir {
        my ($dirname, undef, $names) = create_tree;
        my $target = "\x{2603}";
        mkdirW $target;

        ok cptreeW("$dirname/", $target), 'cptreeW will be success';

        dump_tree '.';

        for (@$names) {
            s|$dirname[/\\]||;
            ok file_type(e => catfile $target, $_), 'file exists';
        }

        rmtreeW $_ for dir_list '.';
    };
};

subtest 'cptreeW - force copy' => sub {
    safe_dir {
        my ($dirname, undef, $names) = create_tree;
        my $target = "\x{2603}";
        mkdirW $target;

        ok cptreeW($dirname, $target), 'cptreeW will be success';
        dump_tree '.';

        is dir_size($target), 0, 'dir_size ok';

        touchW "$dirname/$unicode.txt";
        push @$names, "$dirname/$unicode.txt";

        my $count;
        my $write_length = 10;
        findW sub {
            return unless file_type f => $_;
            Win32::Unicode::File->new(w => $_)->write('0' x $write_length);
            $count++;
        }, $dirname;

        ok cptreeW($dirname, $target, 1), 'force coping tree';

        dump_tree '.';

        for (@$names) {
            ok file_type(e => catfile $target, $_), 'file exists';
        }

        is dir_size($target), $write_length * $count, 'dir_size ok';

        rmtreeW $_ for dir_list '.';
    };
};

subtest 'mvtreeW - whole move' => sub {
    safe_dir {
        my ($dirname, undef, $names) = create_tree;
        my $target = "\x{2603}";
        mkdirW $target;

        ok mvtreeW($dirname, $target), 'mvtreeW will be success';

        for my $name (@$names) {
            ok !file_type(e => $name), 'original file not exists';
            ok file_type(e => catfile $target, $name), 'target file exists';
        }

        ok !file_type(e => $dirname), 'from dir not exists';

        rmtreeW $_ for dir_list '.';
    };
};

subtest 'mvtreeW - content move' => sub {
    safe_dir {
        my ($dirname, undef, $names) = create_tree;
        my $target = "\x{2603}";

        ok mvtreeW("$dirname/", $target), 'mvtreeW will be success';

        dump_tree '.';

        for my $name (@$names) {
            ok !file_type(e => $name), 'orginal file not exists';
            $name =~ s|$dirname[/\\]||;
            ok file_type(e => catfile $target, $name), 'target file exists';
        }

        ok file_type(e => $dirname), 'from dir exists';

        rmtreeW $_ for dir_list '.';
    };
};

subtest 'mvtreeW - force move' => sub {
    safe_dir {
        my ($dirname, undef, $names) = create_tree;
        my $target = "\x{2603}";
        mkdirW $target;

        ok mvtreeW($dirname, $target), 'mvtreeW will be success';

        is dir_size($target), 0, 'dir_size ok';

        mkdirW $dirname;
        touchW "$dirname/$unicode.txt";
        push @$names, "$dirname/$unicode.txt";

        my $count;
        my $write_length = 10;
        findW sub {
            return unless file_type f => $_;
            my $fh = Win32::Unicode::File->new(w => $_);
            $fh->write('0' x $write_length);
            $fh->close;
            $count++;
        }, $dirname;

        ok mvtreeW($dirname, $target, 1), 'force moving tree';

        dump_tree $target;

        for my $name (@$names) {
            ok !file_type(e => $name), 'file not exists';
            ok file_type(e => catfile $target, $name), 'file exists';
        }
        ok !file_type(e => $dirname), 'from dir exists';

        is dir_size($target), $write_length * $count, 'dir_size ok';

        rmtreeW $_ for dir_list '.';
    };
};

subtest 'dir_size' => sub {
    safe_dir {
        my $tmpdir = 'test';
        mkdirW $tmpdir;

        for my $i (1..10) {
            my $fh = Win32::Unicode::File->new(w => "$tmpdir/\x{2665}_$i");
            $fh->write('0123456789');
            $fh->close;
        }

        is dir_size($tmpdir), 100, 'dir_size calc ok';

        for my $i (1..10) {
            unlinkW "$tmpdir/\x{2665}_$i";
        }
    };
};

subtest 'exceptions' => sub {
    open STDERR, '>', File::Spec->devnull or die $!;

    safe_dir {
        dies_ok { rmtreeW } 'rmtreeW must be directory specified';
        dies_ok { mkpathW } 'mkpathW must be directory specified';;
        dies_ok { cptreeW } 'cptreeW must be from, to specifiled';
        dies_ok { cptreeW('from') } 'cptreeW from not exists';
        dies_ok { cptreeW('.', 'foo/bar') } 'no such directory (foo)';
        dies_ok { mvtreeW } 'mvtreeW must be from, to specifiled';
        dies_ok { mvtreeW('from') } 'mvtreeW from not exists';
        dies_ok { mvtreeW('.', 'foo/bar') } 'no such directory (foo)';
        dies_ok { dir_size } 'dir_size must be directory specified';
    };
};

done_testing;
