use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use Text::AsciidocDown;
use Text::AsciidocDown::Include;

sub write_file {
  my ($path, $text) = @_;
  open my $fh, '>:encoding(UTF-8)', $path or die $!;
  print {$fh} $text;
  close $fh;
}

my $tmp = tempdir(CLEANUP => 1);

my $main = File::Spec->catfile($tmp, 'main.adoc');
my $part = File::Spec->catfile($tmp, 'part.adoc');
write_file($part, "== Part\n\nBody\n");
write_file($main, "= Doc\n\ninclude::part.adoc[]\n");

my $converter = Text::AsciidocDown->new();
my $input = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };

my $out = $converter->convert($input, {
  source_path => $main,
  include => { enabled => 1 },
});
like($out, qr/^# Doc\n\n## Part\n\nBody\z/, 'simple local include merged before conversion');

my $nested = File::Spec->catfile($tmp, 'nested.adoc');
write_file($nested, "include::part.adoc[]\n");
write_file($main, "= Doc\n\ninclude::nested.adoc[]\n");
$input = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
$out = $converter->convert($input, {
  source_path => $main,
  include => { enabled => 1 },
});
like($out, qr/## Part/, 'nested include expansion works');

write_file($main, "= Doc\n:partialsdir: .\n\ninclude::{partialsdir}/part.adoc[]\n");
$input = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
$out = $converter->convert($input, {
  source_path => $main,
  include => { enabled => 1 },
});
like($out, qr/## Part/, 'attribute reference in include target resolves');

write_file($main, "= Doc\n\ninclude::nope.adoc[]\n");
$input = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };

my $ok = eval {
  $converter->convert($input, { source_path => $main, include => { enabled => 1, on_missing => 'error' } });
  1;
};
ok(!$ok, 'missing include with error policy throws');

$out = Text::AsciidocDown::Include::expand_includes($input, {
  source_path => $main,
  include => { enabled => 1, on_missing => 'keep' },
});
like($out, qr/include::nope\.adoc\[\]/, 'missing include keep policy preserves line');

$out = Text::AsciidocDown::Include::expand_includes($input, {
  source_path => $main,
  include => { enabled => 1, on_missing => 'drop' },
});
unlike($out, qr/include::nope\.adoc\[\]/, 'missing include drop policy removes line');

my $a = File::Spec->catfile($tmp, 'a.adoc');
my $b = File::Spec->catfile($tmp, 'b.adoc');
write_file($a, "include::b.adoc[]\n");
write_file($b, "include::a.adoc[]\n");
$input = do { local $/; open my $fh, '<:encoding(UTF-8)', $a or die $!; <$fh> };
$ok = eval {
  $converter->convert($input, { source_path => $a, include => { enabled => 1, on_cycle => 'error' } });
  1;
};
ok(!$ok, 'include cycle with error policy throws');

$ok = eval {
  $converter->convert($input, { source_path => $a, include => { enabled => 1, max_depth => 0 } });
  1;
};
ok(!$ok, 'recursion depth limit enforced');

write_file($main, "= Doc\n\n\\include::part.adoc[]\n");
$input = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
$out = $converter->convert($input, { source_path => $main, include => { enabled => 1 } });
like($out, qr/include::part\.adoc\[\]/, 'escaped include remains literal');

write_file($main, "= Doc\n\ninclude::part.adoc[]\n");
$input = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
$out = $converter->convert($input, { source_path => $main });
unlike($out, qr/## Part/, 'include disabled preserves baseline (directive dropped)');

done_testing;
