#! perl -I. -w
use t::Test::abeltje;

{
    require_ok('V');

    my $version;
    my $warning = warning {
        $version = V::get_version("GH::ClassIssue1");
    };

    is($version, '0.42', "Class also works");

    if ($] < 5.012) {
        like(
            $warning,
            qr{^Your perl .+ GH::ClassIssue1},
            "Found warning for perl $]"
        );
    }
    else {
        is_deeply($warning, [], "No warnings for perl $]")
            or diag(explain($warning));
    }
}

abeltje_done_testing();
