use Test::More tests => 3;

BEGIN { use_ok('WWW::CheckHTML') }

SKIP: {
    skip 'no sendmail.yaml present', 2 unless -e 'sendmail.yaml';
    ok(checkPage('http://www.google.com', '<title>', 'sillymoos@cpan.org', 'sendmail.yaml'), 'checkPage google.com');
    ok(checkPage('http://www.google.com', '<title>', 'sillymoos@cpan.org'), 'checkPage google.com');
}

