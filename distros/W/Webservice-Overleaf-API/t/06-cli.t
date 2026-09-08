use strict;
use warnings;

use Test::More;
use File::Temp qw/tempfile/;

my $loaded = do './bin/overleaf';
ok $loaded, 'loaded overleaf modulino'
    or diag $@ || $!;

sub run_cli {
    my @args = @_;
    my ($stdout, $stderr, $status);

    {
        local *STDOUT;
        local *STDERR;

        open STDOUT, '>', \$stdout or die $!;
        open STDERR, '>', \$stderr or die $!;

        $status = local::bin::overleaf::main(@args);
    }

    return ($status, $stdout // q{}, $stderr // q{});
}

{
    my ($status, $out, $err) = run_cli('--version');
    is $status, 0, '--version succeeds';
    like $out, qr/^overleaf \Q$Webservice::Overleaf::API::VERSION\E\n\z/,
        '--version reports API version';
    is $err, q{}, '--version is quiet on stderr';
}

{
    my ($status, $out, $err) = run_cli('--help');
    is $status, 0, '--help succeeds';
    like $out, qr/^NAME\b/m, '--help includes NAME';
    like $out, qr/^COMMANDS\b/m, '--help includes COMMANDS';
    like $out, qr/^AUTHENTICATION\b/m, '--help includes AUTHENTICATION';
    is $err, q{}, '--help is quiet on stderr';
}

{
    my ($status, $out, $err) = run_cli('project-url', 'abc_123');
    is $status, 0, 'project-url succeeds';
    is $out, "https://www.overleaf.com/project/abc_123\n",
        'project-url output';
    is $err, q{}, 'project-url is quiet on stderr';
}

{
    my ($status, $out, $err) = run_cli('git-url', 'abc-123');
    is $status, 0, 'git-url succeeds';
    is $out, "https://git.overleaf.com/abc-123\n",
        'git-url output';
    is $err, q{}, 'git-url is quiet on stderr';
}

{
    my ($status, $out, $err) = run_cli(
        '--engine', 'lualatex',
        '--main-document', 'main.tex',
        'open-uri',
        'https://example.test/paper.zip',
    );
    is $status, 0, 'open-uri succeeds';
    like $out, qr{\Ahttps://www\.overleaf\.com/docs\?},
        'open-uri returns Overleaf docs URL';
    like $out, qr{engine=lualatex}, 'open-uri includes engine';
    like $out, qr{main_document=main\.tex}, 'open-uri includes main document';
    is $err, q{}, 'open-uri is quiet on stderr';
}

{
    my ($fh, $filename) = tempfile();
    print {$fh} "\\documentclass{article}\n\\begin{document}x\\end{document}\n";
    close $fh;

    my ($status, $out, $err) = run_cli('open-data', $filename);
    is $status, 0, 'open-data succeeds';
    like $out, qr{\Ahttps://www\.overleaf\.com/docs\?},
        'open-data returns Overleaf docs URL';
    like $out, qr{data%3Aapplication%2Fx-tex%3Bbase64%2C},
        'open-data contains encoded TeX data URI';
    is $err, q{}, 'open-data is quiet on stderr';
}

{
    my ($status, $out, $err) = run_cli('not-a-command');
    is $status, 2, 'unknown command returns usage status';
    is $out, q{}, 'unknown command has no stdout';
    like $err, qr/unknown command 'not-a-command'/,
        'unknown command diagnostic';
    like $err, qr/^Usage:/m, 'unknown command prints usage';
}

done_testing;
