#! perl -I. -w
use t::Test::abeltje;

use Cwd 'abs_path';
use File::Spec::Functions;

require_ok('V');

{
    my $version;
    my $warning = warning {
        $version = V::get_version("GH::Issue1");
    };

    is($version, '1.3', "Find specific version");

    if ($] < 5.012) {
        is_deeply(
            $warning,
            [
              qq{Your perl doesn't understand the version declaration of Foo\n},
              qq{Your perl doesn't understand the version declaration of GH::Issue1\n},
            ],
            "Found warning for perl $]"
        ) or diag(explain($warning));
    }
    else {
        is_deeply($warning, [], "No warnings for perl $]")
            or diag(explain($warning));
    }
}

{
    my ($stdout, $warning);
    {
        no warnings 'once';
        local *STDOUT;
        open(*STDOUT, '>>', \$stdout);
        local $V::NO_EXIT = 1;
        local @INC = 't/lib';
        $warning = warning { V->import('GH::Issue1') };
    }

    is($stdout, <<"EOT", "All packages in output") or diag("STDOUT: $stdout");
GH::Issue1
\t@{[canonpath(catfile(abs_path('.'), qw<t lib GH Issue1.pm>))]}:
\t    main: 1.1
\t    Foo: 1.2
\t    GH::Issue1: 1.3
EOT

    if ($] < 5.012) {
        is_deeply(
            $warning,
            [
              qq{Your perl doesn't understand the version declaration of Foo\n},
              qq{Your perl doesn't understand the version declaration of GH::Issue1\n},
            ],
            "Found warning for perl $]"
        ) or diag(explain($warning));
    }
    else {
        is_deeply($warning, [], "No warnings for perl $]")
            or diag(explain($warning));
    }
}

abeltje_done_testing();
