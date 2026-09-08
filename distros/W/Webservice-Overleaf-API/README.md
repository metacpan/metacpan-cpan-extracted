# Webservice::Overleaf::API

A Perl client for Overleaf integration surfaces.

The distribution deliberately separates:

* **Official/supported interfaces** — Overleaf's **Open in Overleaf** import interface and Git bridge.
* **Experimental interfaces** — browser-session project listing, project ZIP download, remote compilation, PDF download, and compile artifacts. These use undocumented Overleaf web-application endpoints and require `experimental => 1`.

```perl
use Webservice::Overleaf::API;

my $ol = Webservice::Overleaf::API->new;

my $url = $ol->open_uri(
    uri           => 'https://example.org/paper.zip',
    engine        => 'lualatex',
    main_document => 'main.tex',
);

say $ol->git_url('PROJECT_ID');
```

Experimental use:

```perl
my $ol = Webservice::Overleaf::API->new(
    experimental => 1,
    session      => $ENV{OVERLEAF_SESSION},
);

for my $project ($ol->projects->all) {
    say $project->name;
}

my $compile = $ol->compile('PROJECT_ID');
$ol->download_pdf('PROJECT_ID', compile => $compile, to => 'paper.pdf');
$ol->download_output($compile, 'output.log', to => 'output.log');
```

`OVERLEAF_SESSION` is a browser authentication credential. Treat it like a password: do not commit it, print it, or put it in command-line arguments.


## Command-line client

The distribution includes the `overleaf` modulino in `bin/overleaf`.

```sh
overleaf --help
overleaf --version

overleaf project-url PROJECT_ID
overleaf git-url PROJECT_ID
overleaf clone PROJECT_ID paper
overleaf open-uri --engine lualatex --main-document main.tex https://example.org/paper.zip

export OVERLEAF_SESSION='...'
overleaf --experimental projects
overleaf --experimental --resource-path main.tex compile PROJECT_ID
overleaf --experimental --resource-path main.tex --output paper.pdf pdf PROJECT_ID
overleaf --experimental --output output.log output PROJECT_ID output.log
```

The CLI uses `Util::H2O::More::Getopt2h2o` for options and `Dispatch::Fu`
for command dispatch. Its `--help` output is rendered directly from the embedded POD with `Pod::Text`. Git authentication remains with Git's credential
handling. Experimental web-application operations use `OVERLEAF_SESSION`,
`--session-file`, or `--session`.

## Development

```sh
cpanm Dist::Zilla
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest
dzil test
dzil build
```

All tests use injected mock transports/runners and make no live Overleaf requests.

## License

Same terms as Perl itself.

## Testing and CI

The test suite is network-hermetic: Overleaf HTTP traffic and Git operations are
mocked where external access would otherwise be required. GitHub Actions tests
Perl 5.10, 5.20, 5.30, 5.40, and 5.44. Dist::Zilla remains part of the local
development/release workflow but is not used by CI.
