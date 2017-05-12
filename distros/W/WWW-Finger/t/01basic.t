use Test::More tests => 3;
BEGIN { use_ok('WWW::Finger') };

WWW::Finger->import('+CPAN');

my $finger = WWW::Finger->new('tobyink@cpan.org');
ok(defined $finger, "CPAN finger worked");
is($finger->name, "Toby Inkster", "CPAN finger returned correct name");
