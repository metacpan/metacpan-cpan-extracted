# Webservice::Overleaf::API

`Webservice::Overleaf::API` is a Perl client for useful Overleaf integration
surfaces. The distribution also installs the `overleaf` command-line client.

The project deliberately distinguishes two kinds of integration:

* **Documented Overleaf interfaces**: Open in Overleaf and the Git bridge.
* **Experimental browser-session interfaces**: project listing, project ZIP
  download, remote compilation, PDF download, and compilation artifacts.

The experimental operations use observable Overleaf web-application behavior
rather than a documented stable public API, so they require explicit opt-in in
the Perl API (`experimental => 1`) and in the CLI (`--experimental`).

## Science Perl context

This is general-purpose Overleaf tooling, but it grew in part from practical
Git/LaTeX work used while helping authors and editors prepare material for the
**Science Perl Journal**. The author, Brett Estrade (OODLER), is a member of the
Perl Community's **Science Perl Committee** and a Co-Editor of the Journal.

The tool is not required for Journal submissions; it is simply one convenient
way to work. If you are doing scientific, engineering, or other technical work
with Perl, you are welcome to learn more about the [Science Perl
Committee](https://perlcommunity.org/science/). The [Science Perl
Journal](https://science.perlcommunity.org/spj) can be read online, and its
[submission information](https://science.perlcommunity.org/spj/about/submissions)
is available for anyone considering an article. Readers interested in printed
issues can follow the Journal's
[announcements](https://science.perlcommunity.org/spj/announcement) for current
availability.

## Installation

From CPAN:

```sh
cpanm Webservice::Overleaf::API
```

The distribution declares the SSL/TLS modules required by `HTTP::Tiny`, so a
normal CPAN/cpanm installation also pulls in the Perl-side HTTPS stack used to
communicate with Overleaf.

Check the installed client:

```sh
overleaf --version
overleaf --help
```

For development from a checkout:

```sh
cpanm Dist::Zilla
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest
dzil test
dzil build
```

Dist::Zilla is part of the local/release workflow; GitHub CI intentionally runs
the tests directly and does not invoke `dzil`.

## Perl API quick start

The documented import and Git URL helpers do not require a browser session:

```perl
use Webservice::Overleaf::API;

my $ol = Webservice::Overleaf::API->new;

my $url = $ol->open_uri(
    uri           => 'https://example.org/paper.zip',
    engine        => 'lualatex',
    main_document => 'main.tex',
);

say $ol->project_url('PROJECT_ID');
say $ol->git_url('PROJECT_ID');
```

Experimental project and compilation operations require an authenticated
browser session:

```perl
use Webservice::Overleaf::API;

my $ol = Webservice::Overleaf::API->new(
    experimental => 1,
    session      => $ENV{OVERLEAF_SESSION},
);

for my $project ($ol->projects->all) {
    say join "\t", $project->id, $project->name;
}

my $compile = $ol->compile('PROJECT_ID');

$ol->download_pdf(
    'PROJECT_ID',
    compile => $compile,
    to      => 'paper.pdf',
);

$ol->download_output(
    $compile,
    'output.log',
    to => 'output.log',
);
```

## Authentication and credential setup

Overleaf exposes the two parts of this client's workflow through **two separate
authentication systems**. They are deliberately kept separate in the CLI:

| Overleaf surface | Credential | Used for |
| --- | --- | --- |
| Web application | `overleaf_session2` browser cookie | `bootstrap`, `projects`, ZIP, compile, PDF, build outputs |
| Git bridge | Git authentication token, username `git` | clone, pull, push, source synchronization |

A normal local `overleaf --experimental compile main.tex` can use **both**: the
Git token synchronizes the committed project first, then the browser session
runs the Overleaf compile and downloads the resulting PDF.

The CLI standardizes private credentials under:

```text
~/.overleaf/session
~/.overleaf/git-token
```

Create the directory once:

```sh
mkdir -p ~/.overleaf
chmod 700 ~/.overleaf
```

### 1. Browser-session credential

Log into <https://www.overleaf.com/> normally.

**Firefox**

1. Press `F12`.
2. Open **Storage** → **Cookies** → `https://www.overleaf.com`.
3. Find the cookie named `overleaf_session2`.
4. Copy only its **Value**.

**Chrome / Edge / Chromium**

1. Press `F12`.
2. Open **Application** → **Storage** → **Cookies**.
3. Select `https://www.overleaf.com`.
4. Find `overleaf_session2` and copy only its **Value**.

Store only the cookie value—not `overleaf_session2=`:

```sh
read -rsp 'Paste overleaf_session2 value: ' OL_SESSION; printf '\n'
printf '%s\n' "$OL_SESSION" > ~/.overleaf/session
unset OL_SESSION
chmod 600 ~/.overleaf/session
```

Test this authentication path by itself:

```sh
overleaf --experimental bootstrap
overleaf --experimental projects
```

`bootstrap` should print `authenticated`.

Overleaf's current Cookie Policy documents a five-day retention period for
`overleaf_session2`. Logout, rotation, revocation, or other server-side changes
can invalidate a copied value earlier; replace `~/.overleaf/session` with the
current browser-cookie value when session authentication stops working.

### 2. Git authentication token

The Git bridge does **not** use the browser cookie and does not use your normal
Overleaf password. It uses a Git authentication token.

To create one:

1. Open Overleaf **Account Settings**: <https://www.overleaf.com/user/settings>.
2. Find **Git authentication tokens**.
3. Choose **Generate token**.
4. Copy the complete token when Overleaf displays it.

Overleaf does not reveal the complete token later. If you lose the value,
generate a new token and remove the old one if it is no longer needed.

On first use of Git for a project, Overleaf can also offer token generation from
the project: **Integrations** → **Git** → **Generate token**.

For Git authentication:

```text
username: git
password: <your Git authentication token>
```

The same personal token can be used across projects to which your account has
Git access. Overleaf currently documents a one-year token expiration. Do not
share a token with collaborators; each person should create their own.

Store only the token value:

```sh
read -rsp 'Paste Overleaf Git token: ' OL_GIT_TOKEN; printf '\n'
printf '%s\n' "$OL_GIT_TOKEN" > ~/.overleaf/git-token
unset OL_GIT_TOKEN
chmod 600 ~/.overleaf/git-token
```

Test the Git authentication path independently:

```sh
ID=0123456789abcdef
overleaf clone "$ID" my-paper
```

When the token file is present, the client supplies username `git` and the token
through a temporary `GIT_ASKPASS` helper; it does not place the token in the
remote URL, `.git/config`, shell history, or Git process arguments.

Overleaf's current token instructions are here:
<https://docs.overleaf.com/integrations-and-add-ons/git-integration-and-github-synchronization/git-integration/git-integration-authentication-tokens>

### Credential precedence

Browser session:

```text
--session
--session-file
OVERLEAF_SESSION
~/.overleaf/session
```

Git token:

```text
--git-token-file
OVERLEAF_GIT_TOKEN
~/.overleaf/git-token
normal Git credential handling if none is configured
```

For ephemeral automation you may therefore use:

```sh
export OVERLEAF_SESSION='...'
export OVERLEAF_GIT_TOKEN='...'
```

### File permissions and MSYS2

The intended file mode is `0600`:

```sh
chmod 600 ~/.overleaf/session ~/.overleaf/git-token
```

On normal POSIX filesystems the client verifies and requires exactly `0600`.
MSYS2 commonly uses Windows filesystems mounted with `noacl`, where `chmod 600`
may succeed while Perl `stat()` still reports synthetic `0644`-style bits. The
client detects when POSIX mode changes are not enforceable and does not reject a
credential solely because of those synthetic mode bits. The files must still
live under `~/.overleaf/` and should remain private to the owning Windows
account/ACL.

### Combined authentication workflow

Once both standard files exist, ordinary commands need no credential flags:

```sh
ID=0123456789abcdef

# Git token only
overleaf clone "$ID" my-paper
cd my-paper

$EDITOR main.tex
git add .
git commit -m 'revise paper'

# Git token: push committed project
# Browser session: compile remotely and retrieve PDF
overleaf --experimental compile main.tex

# Windows / MSYS2
start main.pdf

# Linux
xdg-open main.pdf >/dev/null 2>&1 &
```

A read-only test of the remote compiler skips Git synchronization and therefore
needs only the browser session:

```sh
overleaf --experimental --no-push compile main.tex
```

If `clone`, `pull`, or the push phase fails with a Git `403` or token error,
check the **Git token**. If `bootstrap`, `projects`, ZIP, compile, or PDF/output
retrieval reports a web-session authentication failure, refresh the
**`overleaf_session2` browser cookie**. Changing one credential does not repair
the other authentication path.

## CLI: start-to-finish practical workflow

### Local Git checkout -> Overleaf -> PDF

The most useful 0.06 workflow treats the **Git checkout as the local working
copy**, the browser-session interface as the **remote compiler/output
interface**, and the ZIP as an **exported snapshot**.

After cloning an Overleaf project through the Git bridge:

```sh
overleaf clone "$ID" my-paper
cd my-paper
```

edit and commit the project normally:

```sh
$EDITOR main.tex
git add .
git commit -m 'revise paper'
```

Then one command can synchronize the committed project, compile it on
Overleaf, and download the PDF:

```sh
overleaf --experimental \
  compile main.tex
```

Typical concise output is:

```text
project  0123456789abcdef
remote   origin
branch   main
root     main.tex
source   committed HEAD
push     ok
status   success
saved    main.pdf
```

The command discovers the project ID and branch from the Overleaf Git checkout
and pushes **the complete committed project** as `HEAD:<remote-branch>`. It does
not guess whether only `.tex`, `.bib`, images, styles, classes, or some other
file type is needed. A TeX project is the compilation unit.

The branch is discovered from the current branch's upstream or the selected
remote's recorded `HEAD`; the client does not assume `master` or `main`. Use
`--remote-branch NAME` when local Git metadata is insufficient.

A dirty work tree is rejected. The client will not silently `git add`, create a
commit, or leave files out of the build. Commit or stash your changes first.
The selected root document must also be tracked by Git. If Overleaf has newer
web-editor changes and the push is rejected as non-fast-forward, pull and
reconcile those changes normally; the client deliberately does not modify your
local history for you.

If you deliberately want to compile the project state already on Overleaf:

```sh
overleaf --experimental \
  --no-push \
  compile main.tex
```

Omit the root filename to use the document configured on Overleaf:

```sh
overleaf --experimental \
  compile
```

Use `--output` to choose the PDF name:

```sh
overleaf --experimental \
  --output reviewed-draft.pdf \
  compile main.tex
```

View the downloaded PDF on Linux:

```sh
xdg-open main.pdf >/dev/null 2>&1 &
```

or from MSYS2/Git Bash on Windows:

```sh
start main.pdf
```

The lower-level form remains available when you want to compile whatever is
already on Overleaf without using a local Git checkout:

```sh
overleaf --experimental \
  compile "$ID"
```

That form prints the compile status, PDF URL, and build-artifact list; use the
`pdf` command to download its PDF separately.

The following sequence is intended to be usable as a real working session.

### 1. Configure credentials

Follow [Credential setup](#credential-setup) above. Once
`~/.overleaf/session` and `~/.overleaf/git-token` are present with mode `0600`,
the client discovers them automatically.

### 2. Validate authentication

```sh
overleaf --experimental \
  bootstrap
```

Expected:

```text
authenticated
```

### 3. List projects

```sh
overleaf --experimental \
  projects
```

Output is tab-separated:

```text
PROJECT_ID    PROJECT NAME    LAST_UPDATED
```

Choose one:

```sh
ID=0123456789abcdef
```

Useful non-session URL helpers:

```sh
overleaf project-url "$ID"
overleaf git-url "$ID"
```

### 4. Download and inspect the project source

Download the project ZIP:

```sh
overleaf --experimental \
  --output project.zip \
  zip "$ID"
```

Inspect everything:

```sh
unzip -l project.zip
```

Find TeX source files:

```sh
unzip -l project.zip | grep -Ei '\.tex$'
```

Extract the full tree:

```sh
mkdir project-src
cd project-src
unzip ../project.zip
find . -type f -name '*.tex' -print
cd ..
```

This is an important distinction:

* `zip` retrieves the **project/source tree**.
* `compile` reports **generated build artifacts**.

If `compile | grep tex` only shows names such as `output.chktex`,
`output.fdb_latexmk`, or `output.synctex.gz`, that is expected; those are build
products, not source `.tex` files.

### 5. Compile on Overleaf

Compile using the root document currently configured by Overleaf:

```sh
overleaf --experimental \
  compile "$ID"
```

Typical beginning of the output:

```text
status  success
pdf     https://www.overleaf.com/project/.../output/output.pdf?...
```

It then lists generated files such as:

```text
output  output.aux       aux       ...
output  output.bbl       bbl       ...
output  output.chktex    chktex    ...
output  output.log       log       ...
output  output.pdf       pdf       ...
output  output.stderr    stderr    ...
output  output.stdout    stdout    ...
```

A project using `minted` may produce many `_minted-output/*.pygtex` and
`*.pygstyle` entries. That is normal.

### 6. Find the root TeX document

Retrieve the compilation log:

```sh
overleaf --experimental \
  --output output.log \
  output "$ID" output.log
```

The log normally begins with a line like:

```text
**user_guide.tex
```

Extract just that first root-document line:

```sh
grep -m1 '^\*\*[^*]' output.log
```

Set the filename:

```sh
ROOT_TEX=user_guide.tex
```

### 7. Compile an explicit root

```sh
overleaf --experimental \
  --resource-path "$ROOT_TEX" \
  compile "$ID"
```

This is especially useful for projects containing more than one compilable TeX
document.

### 8. Download and view the PDF

```sh
overleaf --experimental \
  --resource-path "$ROOT_TEX" \
  --output document.pdf \
  pdf "$ID"
```

Check the result:

```sh
file document.pdf
ls -lh document.pdf
```

On Linux:

```sh
xdg-open document.pdf >/dev/null 2>&1 &
```

On Windows from MSYS2 or Git Bash:

```sh
start document.pdf
```

If an explicit Windows path is needed:

```sh
cmd.exe /c start "" "$(cygpath -w document.pdf)"
```

### 9. Retrieve useful build artifacts

The `output` command performs a compile and downloads one reported artifact:

```sh
overleaf --experimental \
  --output document.log \
  output "$ID" output.log

overleaf --experimental \
  --output document.bbl \
  output "$ID" output.bbl

overleaf --experimental \
  --output document.chktex \
  output "$ID" output.chktex
```

Then ordinary shell tools work well:

```sh
tail -100 document.log
cat document.bbl
cat document.chktex
```

Only artifacts returned by the Overleaf compile can be downloaded this way.


A repeated local compile does not reject the untracked PDF that the client itself downloaded on the previous run. Only that expected output path is ignored; other untracked files and any tracked modifications still block a push.

## Git integration

The Git bridge is separate from the browser-session interface. It does not use
`~/.overleaf/session`.

Overleaf's Git integration uses token-based Git authentication and is currently
a premium feature on Overleaf Cloud. Let Git handle and store the credential
rather than embedding it in URLs.

Print the Git URL:

```sh
overleaf git-url "$ID"
```

Clone:

```sh
overleaf clone "$ID" my-paper
```

Inspect:

```sh
cd my-paper
git status
git remote -v
git log --oneline -10
cd ..
```

Pull edits made through the Overleaf web editor:

```sh
overleaf pull my-paper
```

After making and committing local changes:

```sh
cd my-paper
git add .
git commit -m 'update paper'
cd ..
```

For a clone whose current branch tracks the Overleaf remote:

```sh
overleaf push my-paper
```

`push` changes the Overleaf project, so inspect `git status` and your commits
first.

### Add an Overleaf remote to an existing repository

```sh
cd existing-paper
overleaf remote-add . "$ID" overleaf
git remote -v
```

Overleaf's Git bridge is not a full general-purpose Git server. It presents one
linear project history. Branch names seen in repositories and documentation may
differ, so the high-level `compile` workflow follows the branch actually
tracked/advertised by the selected remote rather than assuming `master` or
`main`.

Inspect an existing remote with:

```sh
git remote show overleaf
```

If branch discovery is unavailable locally, specify it explicitly:

```sh
overleaf --remote-branch main --experimental compile main.tex
```

For an unrelated existing repository, reconcile histories according to
Overleaf's current Git integration instructions before the first push.

The Git bridge creates commits as needed when Git fetch/pull/push operations
translate between Overleaf's internal History system and Git.

## Open in Overleaf

Generate an Open in Overleaf URL from a remotely hosted TeX or ZIP file:

```sh
overleaf open-uri \
  --engine lualatex \
  --main-document main.tex \
  https://example.org/project.zip
```

Generate an import URL from a local TeX file:

```sh
overleaf open-data paper.tex
```

Generate a complete HTML POST form containing a TeX snippet:

```sh
overleaf snippet-form paper.tex
```

## Authentication summary

There are two credentials, used for two different integration surfaces:

| Operation | Credential |
| --- | --- |
| `projects`, `bootstrap`, `zip`, `compile`, `pdf`, `output` | `overleaf_session2` browser session |
| `clone`, `pull`, `push`, Git remote access | Overleaf Git authentication token |
| `project-url`, `git-url`, `open-uri`, `open-data`, `snippet-form` | none required by the client |

The browser cookie is a credential: do not commit it, print it in logs, include
it in bug reports, or put it directly on a command line when a session file or
environment variable will do.

## Testing and CI

The test suite is network-hermetic. HTTP traffic and Git operations are mocked
where external access would otherwise be required.

GitHub Actions currently tests Perl 5.10, 5.20, 5.30, 5.40, and 5.44.

## Documentation

Full module documentation:

```sh
perldoc Webservice::Overleaf::API
```

Full CLI documentation:

```sh
overleaf --help
```

## License

Same terms as Perl itself.
