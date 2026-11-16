use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# The rules that matter most in a dump, by hand, as roadmap 2026-0001's
# D3 says: generic-api-key, passwords in DSNs and URLs, and AWS's,
# GitHub's and private keys. Each case is what gitleaks v8.30.1 finds in
# the same text, checked against its binary when it was written, but for
# a password in a URL's user information, which gitleaks has no rule
# for, and which the module's own url-userinfo-password finds (D12).
#
# Every secret here is made up. Each is built from pieces, as CLAUDE.md's
# Tests say, so that no line holds one for gitleaks or push protection to
# find. Those generic-api-key is to find look random: it passes over a
# value with a word such as "fake", "example" or "password" in it.

use Text::Redact::Secrets qw(find redact);

my $password = join '', 'Zq8',        'vR2mXk',     'P4wL9nT';
my $aws_id   = join '', 'AKIA',       'MADEUP',     'FORTESTS',   'ZZ';
my $aws_key  = join '', 'Hq7Zx2Lm9P', 'v4Rt8Ks3Wd', '6Yb1Nf5Gc0', 'Jt+Qa/Ue2Xo';
my $classic  = join '', 'ghp_', 'NotARealToken', 'JustForTests',  'abcdefghijk';
my $fine     = join '', 'github_pat_', 'NotARealFine', 'GrainedToken',
    'JustForTests', '_',
    'Kq3Zr8Vx1Lm6Pw4T', 'n9Hy2Bc7Fd5Gj0Sk', '8Ua3Ex6Wo1Qr9';
my $oauth   = join '', 'gho_', 'NotARealOAuthTok',   'enJustForTests', 'abcdef';
my $private = join '', '-----BEGIN ', 'RSA PRIVATE', ' KEY-----',      "\n",
    ("MadeUpKeyBodyForTestsOnlyNotARealKey0123456789abcdef\n") x 3,
    '-----END ', 'RSA PRIVATE', ' KEY-----';

# Check what find finds in a text: each by its rule, and where.
sub finds ($text, $name, @expected) {
    is [find($text)],
        [
            map { {
                rule => $_->[0], secret => $_->[1], offset => index($text, $_->[1]),
            } } @expected
        ],
        $name;
    return;
}

subtest 'generic-api-key' => sub {
    finds(
        qq(api_key = "$password"\n), 'an api_key assigned',
        ['generic-api-key', $password],
    );
    finds(
        qq(\$VAR1 = {\n  'user' => 'app',\n  'password' => '$password'\n};\n),
        'a password in a dumped hash', ['generic-api-key', $password],
    );
    finds(
        qq(password = 'aaaaaaaaaaaaaaaa'\n),
        'but not one with too little entropy',
    );
    finds(qq(password = "\${DB_PASSWORD}"\n), 'nor a placeholder');
    finds(qq(password = 'hunter2'\n),         'nor one too short');
};

subtest 'Passwords in DSNs and URLs' => sub {
    finds(
        qq(dbi:Pg:dbname=app;host=db;password=$password\n),
        'in a DBI DSN, by generic-api-key', ['generic-api-key', $password],
    );
    finds(
        qq(jdbc:mysql://db/app?user=app&password=$password\n),
        'in a JDBC URL\'s query', ['generic-api-key', $password],
    );
    finds(
        qq(postgres://app:$password\@db.example.com/app\n),
        'in a URL\'s user information, by our own rule, as gitleaks has none',
        ['url-userinfo-password', $password],
    );
    finds(
        qq(https://app:hunter2\@example.com/\n),
        'whatever its scheme, and however short',
        ['url-userinfo-password', 'hunter2'],
    );
    finds(
        qq(redis://:$password\@cache:6379/0\n), 'with no user',
        ['url-userinfo-password', $password],
    );
    finds(
        qq(postgres://app:\${DB_PASSWORD}\@db/app\n),
        'but not a placeholder, which gitleaks\' global allowlist passes over',
    );
    finds(qq(mysql://root:\@localhost/db\n),   'nor an empty password');
    finds(qq(http://example.com:8080/a?b=c\n), 'nor a port');
    finds(qq(https://example.com/u\@x\n),      'nor an @ in the path');
    finds(qq(git\@github.com:org/repo.git\n),  'nor git\'s user@host:path');
};

subtest 'AWS' => sub {
    finds(
        qq(aws_access_key_id = $aws_id\n), 'an access key id',
        ['aws-access-token', $aws_id],
    );
    finds(
        qq(aws_secret_access_key = $aws_key\n),
        'a secret access key, by generic-api-key', ['generic-api-key', $aws_key],
    );
};

subtest 'GitHub' => sub {
    finds(
        qq(token: $classic\n), 'a classic personal access token',
        ['github-pat', $classic],
    );
    finds(
        qq(GITHUB_TOKEN=$fine\n), 'a fine-grained one',
        ['github-fine-grained-pat', $fine],
    );
    finds(qq(oauth = '$oauth'\n), 'an OAuth token', ['github-oauth', $oauth]);
};

subtest 'Private keys' => sub {
    finds(
        qq($private\n), 'the whole key, from BEGIN to END',
        ['private-key', $private],
    );
};

subtest 'redact, on a dump' => sub {
    my $dump = <<"END";
\$VAR1 = {
  'dsn' => 'dbi:Pg:dbname=app;host=db',
  'url' => 'postgres://app:$password\@db/app',
  'user' => 'app',
  'password' => '$password',
  'aws_access_key_id' => '$aws_id',
  'github_token' => '$classic'
};
END
    is redact($dump), <<'END', 'each secret replaced, and nothing else';
$VAR1 = {
  'dsn' => 'dbi:Pg:dbname=app;host=db',
  'url' => 'postgres://app:*REDACTED*@db/app',
  'user' => 'app',
  'password' => '*REDACTED*',
  'aws_access_key_id' => '*REDACTED*',
  'github_token' => '*REDACTED*'
};
END
};

done_testing;
