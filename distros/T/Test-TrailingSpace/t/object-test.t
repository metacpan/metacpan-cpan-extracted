#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';

use Test::Builder::Tester tests => 10;

use File::Path qw( rmtree );

use File::Find::Object::TreeCreate ();
use Test::TrailingSpace            ();

{
    my $test_id  = "no-trailing-space-1";
    my $test_dir = "t/sample-data/$test_id";
    my $tree     = {
        'name' => "$test_id/",
        'subs' => [
            {
                'name' => "a/",
                subs   => [
                    {
                        'name'     => "b.pm",
                        'contents' => "This file was spotted in the wild.",
                    },
                ],
            },
            {
                'name' => "foo/",
                'subs' => [
                    {
                        'name'     => "t.door.txt",
                        'contents' => "A T Door",
                    },
                    {
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree( "./t/sample-data/", $tree );

    my $finder = Test::TrailingSpace->new(
        {
            find_tabs      => 1,
            root           => $t->get_path("./$test_dir"),
            filename_regex => qr/\.(?:pm|txt)\z/,
        }
    );

    test_out("ok 1 - no trailing space FOO");
    $finder->no_trailing_space("no trailing space FOO");
    test_test("no trailing space was reported");
    rmtree( $t->get_path("./$test_dir") )
}

{
    my $test_id  = "with-trailing-space-1";
    my $test_dir = "t/sample-data/$test_id";
    my $tree     = {
        'name' => "$test_id/",
        'subs' => [
            {
                'name' => "a/",
                subs   => [
                    {
                        'name'     => "b.pm",
                        'contents' => "This file.    \nI don't like it.",
                    },
                ],
            },
            {
                'name' => "foo/",
                'subs' => [
                    {
                        'name'     => "t.door.txt",
                        'contents' => "A T Door",
                    },
                    {
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree( "./t/sample-data/", $tree );

    my $finder = Test::TrailingSpace->new(
        {
            root           => $t->get_path("./$test_dir"),
            filename_regex => qr/\.(?:pm|txt)\z/,
        }
    );

    test_out("not ok 1 - with trailing space CLAM");
    test_fail(+1);
    $finder->no_trailing_space("with trailing space CLAM");
    test_test( title => "with trailing space was reported", skip_err => 1, );
    rmtree( $t->get_path("./$test_dir") )
}

{
    my $test_id  = "no-trailing-space-2";
    my $test_dir = "t/sample-data/$test_id";
    my $tree     = {
        'name' => "$test_id/",
        'subs' => [
            {
                'name' => "a/",
                subs   => [
                    {
                        'name'     => "b.pm",
                        'contents' => "This file was spotted in the wild.",
                    },
                ],
            },
            {
                'name' => "foo/",
                'subs' => [
                    {
                        'name'     => "t.door.txt",
                        'contents' => "A T Door",
                    },
                    {
                        'name' => "yet/",
                    },
                ],
            },
            {
                'name' => "lib/",
                subs   => [
                    {
                        'name'     => "foo.pm",
                        'contents' => "File with trailing space     \nhello\n",
                    }
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree( "./t/sample-data/", $tree );

    my $finder = Test::TrailingSpace->new(
        {
            root              => $t->get_path("./$test_dir"),
            filename_regex    => qr/\.(?:pm|txt)\z/,
            abs_path_prune_re => qr#\blib\b#ms,
        }
    );

    test_out("ok 1 - no trailing space BAR");
    $finder->no_trailing_space("no trailing space BAR");
    test_test("no trailing space was reported");
    rmtree( $t->get_path("./$test_dir") )
}

{
    my $test_id  = "no-trailing-space-in-hg";
    my $test_dir = "t/sample-data/$test_id";
    my $tree     = {
        'name' => "$test_id/",
        'subs' => [
            {
                'name' => "a/",
                subs   => [
                    {
                        'name'     => "b.pm",
                        'contents' => "This file was spotted in the wild.",
                    },
                ],
            },
            {
                'name' => "foo/",
                'subs' => [
                    {
                        'name'     => "t.door.txt",
                        'contents' => "A T Door",
                    },
                    {
                        'name' => "yet/",
                    },
                ],
            },
            {
                'name' => ".hg/",
                subs   => [
                    {
                        'name'     => "foo.pm",
                        'contents' => "File with trailing space     \nhello\n",
                    }
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree( "./t/sample-data/", $tree );

    my $finder = Test::TrailingSpace->new(
        {
            root           => $t->get_path("./$test_dir"),
            filename_regex => qr/\.(?:pm|txt)\z/,
        }
    );

    test_out("ok 1 - trailing space in .hg is ignored.");
    $finder->no_trailing_space("trailing space in .hg is ignored.");
    test_test("no trailing space was reported");
    rmtree( $t->get_path("./$test_dir") )
}

{
    my $test_id  = "no-trailing-space-in-hg-with-abs-path-re";
    my $test_dir = "t/sample-data/$test_id";
    my $tree     = {
        'name' => "$test_id/",
        'subs' => [
            {
                'name' => "a/",
                subs   => [
                    {
                        'name'     => "b.pm",
                        'contents' => "This file was spotted in the wild.",
                    },
                ],
            },

            {
                'name' => "foo/",
                'subs' => [
                    {
                        'name'     => "t.door.txt",
                        'contents' => "A T Door",
                    },
                    {
                        'name' => "yet/",
                    },
                ],
            },
            {
                'name' => ".hg/",
                subs   => [
                    {
                        'name'     => "foo.pm",
                        'contents' => "File with trailing space     \nhello\n",
                    }
                ],
            },
            {
                'name' => "lib/",
                subs   => [
                    {
                        'name'     => "MyFileWithSpace.pm",
                        'contents' => "Trailing space===    \nFoo\n",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree( "./t/sample-data/", $tree );

    my $finder = Test::TrailingSpace->new(
        {
            root              => $t->get_path("./$test_dir"),
            filename_regex    => qr/\.(?:pm|txt)\z/,
            abs_path_prune_re => qr#\blib\b#ms,
        }
    );

    test_out("ok 1 - trailing space.");
    $finder->no_trailing_space("trailing space.");
    test_test("no trailing space was reported with abs_path_prune_re and .hg");
    rmtree( $t->get_path("./$test_dir") )
}

{
    my $test_id  = "with-trailing-space-prune-hg";
    my $test_dir = "t/sample-data/$test_id";
    my $tree     = {
        'name' => "$test_id/",
        'subs' => [
            {
                'name' => "a/",
                subs   => [
                    {
                        'name'     => "WithTrailingSpace.pm",
                        'contents' => "Trail space here =     \nGamp\n",
                    },
                ],
            },

            {
                'name' => "foo/",
                'subs' => [
                    {
                        'name'     => "t.door.txt",
                        'contents' => "A T Door",
                    },
                    {
                        'name' => "yet/",
                    },
                ],
            },
            {
                'name' => ".hg/",
                subs   => [
                    {
                        'name'     => "foo.pm",
                        'contents' => "File with trailing space     \nhello\n",
                    }
                ],
            },
            {
                'name' => "lib/",
                subs   => [
                    {
                        'name'     => "MyFileWithSpace.pm",
                        'contents' => "Trailing space===    \nFoo\n",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree( "./t/sample-data/", $tree );

    my $finder = Test::TrailingSpace->new(
        {
            root              => $t->get_path("./$test_dir"),
            filename_regex    => qr/\.(?:pm|txt)\z/,
            abs_path_prune_re => qr#\blib\b#ms,
        }
    );

    test_out("not ok 1 - with trailing space OGLO");
    test_fail(+1);
    $finder->no_trailing_space("with trailing space OGLO");
    test_test(
        title    => "with trailing space was reported for abs_path_prune_re",
        skip_err => 1,
    );
    rmtree( $t->get_path("./$test_dir") )
}

{
    my $test_id  = "no-trailing-space-with-unrecognized-filename";
    my $test_dir = "t/sample-data/$test_id";
    my $tree     = {
        'name' => "$test_id/",
        'subs' => [
            {
                'name' => "a/",
                subs   => [
                    {
                        'name'     => "b.pm",
                        'contents' => "This file was spotted in the wild.",
                    },
                ],
            },

            {
                'name' => "foo/",
                'subs' => [
                    {
                        'name'     => "t.door.txt",
                        'contents' => "A T Door",
                    },
                    {
                        'name' => "yet/",
                    },
                ],
            },
            {
                'name' => ".hg/",
                subs   => [
                    {
                        'name'     => "foo.pm",
                        'contents' => "File with trailing space     \nhello\n",
                    }
                ],
            },
            {
                'name' => "eclim/",
                subs   => [
                    {
                        'name'     => "MyFileWithSpace.tar.gz",
                        'contents' => "Trailing space===    \nFoo\n",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree( "./t/sample-data/", $tree );

    my $finder = Test::TrailingSpace->new(
        {
            root              => $t->get_path("./$test_dir"),
            filename_regex    => qr/\.(?:pm|txt)\z/,
            abs_path_prune_re => qr#\blib\b#ms,
        }
    );

    test_out("ok 1 - trailing space.");
    $finder->no_trailing_space("trailing space.");
    test_test("no trailing space was with unrecognized filename.");
    rmtree( $t->get_path("./$test_dir") )
}

{
    my $test_id  = "prune-files";
    my $test_dir = "t/sample-data/$test_id";
    my $tree     = {
        'name' => "$test_id/",
        'subs' => [
            {
                'name' => "a/",
                subs   => [
                    {
                        'name'     => "b.pm",
                        'contents' => "This file was spotted in the wild.",
                    },
                    {
                        'name'     => "mypatch.patch",
                        'contents' => "+foo\n \n-Lambda\n",
                    },
                ],
            },
            {
                'name' => "foo/",
                'subs' => [
                    {
                        'name'     => "t.door.txt",
                        'contents' => "A T Door",
                    },
                    {
                        'name' => "yet/",
                    },
                ],
            },
            {
                'name' => ".hg/",
                subs   => [
                    {
                        'name'     => "foo.pm",
                        'contents' => "File with trailing space     \nhello\n",
                    }
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree( "./t/sample-data/", $tree );

    my $finder = Test::TrailingSpace->new(
        {
            root => $t->get_path("./$test_dir"),

            # Match all.
            filename_regex    => qr/./,
            abs_path_prune_re => qr#(?:\blib\b)|(?:\.patch\z)#ms,
        }
    );

    test_out("ok 1 - trailing space.");
    $finder->no_trailing_space("trailing space.");
    test_test("no trailing space was with unrecognized filename.");
    rmtree( $t->get_path("./$test_dir") )
}

{
    my $test_id  = "test-tabs";
    my $test_dir = "t/sample-data/$test_id";
    my $tree     = {
        'name' => "$test_id/",
        'subs' => [
            {
                'name' => "a/",
                subs   => [
                    {
                        'name'     => "WithTab.pm",
                        'contents' => "\tfoo\n",
                    },
                ],
            },

            {
                'name' => "foo/",
                'subs' => [
                    {
                        'name'     => "t.door.txt",
                        'contents' => "A T Door",
                    },
                    {
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree( "./t/sample-data/", $tree );

    my $finder = Test::TrailingSpace->new(
        {
            find_tabs         => 1,
            root              => $t->get_path("./$test_dir"),
            filename_regex    => qr/\.(?:pm|txt)\z/,
            abs_path_prune_re => qr#\blib\b#ms,
        }
    );

    test_out("not ok 1 - with tabs YKL");
    test_fail(+1);
    $finder->no_trailing_space("with tabs YKL");
    test_test(
        title    => "found tabs",
        skip_err => 1,
    );
    rmtree( $t->get_path("./$test_dir") )
}

{
    my $test_id  = "test-CR-lines";
    my $test_dir = "t/sample-data/$test_id";
    my $tree     = {
        'name' => "$test_id/",
        'subs' => [
            {
                'name' => "a/",
                subs   => [
                    {
                        'name'     => "WithCR.pm",
                        'contents' => "foo\r\nhello\r\n",
                    },
                ],
            },

            {
                'name' => "foo/",
                'subs' => [
                    {
                        'name'     => "t.door.txt",
                        'contents' => "A T Door",
                    },
                    {
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree( "./t/sample-data/", $tree );

    my $finder = Test::TrailingSpace->new(
        {
            find_cr           => 1,
            root              => $t->get_path("./$test_dir"),
            filename_regex    => qr/\.(?:pm|txt)\z/,
            abs_path_prune_re => qr#\blib\b#ms,
        }
    );

    test_out("not ok 1 - with CRs CREDOT");
    test_fail(+1);
    $finder->no_trailing_space("with CRs CREDOT");
    test_test(
        title    => "found CRs",
        skip_err => 1,
    );
    rmtree( $t->get_path("./$test_dir") )
}
