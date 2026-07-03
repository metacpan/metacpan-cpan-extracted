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
my $inc = File::Spec->catfile($tmp, 'inc.adoc');

write_file($inc, join("\n",
  'tag::overview[]',
  '== Overview',
  'end::overview[]',
  'tag::details[]',
  '== Details',
  'line a',
  'line b',
  'end::details[]',
  '== Tail',
  '',
));

my $converter = Text::AsciidocDown->new();

write_file($main, "= Doc\n\ninclude::inc.adoc[tag=overview]\n");
my $in = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
my $out = $converter->convert($in, {
  source_path => $main,
  include => { enabled => 1 },
});
like($out, qr/^# Doc\n\n## Overview\z/, 'tag selector includes selected region');

write_file($main, "= Doc\n\ninclude::inc.adoc[tags=overview;details]\n");
$in = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
$out = $converter->convert($in, {
  source_path => $main,
  include => { enabled => 1 },
});
like($out, qr/## Overview/, 'tags selector includes first tag');
like($out, qr/## Details/, 'tags selector includes second tag');

write_file($main, "= Doc\n\ninclude::inc.adoc[lines=2..3]\n");
$in = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
$out = $converter->convert($in, {
  source_path => $main,
  include => { enabled => 1 },
});
like($out, qr/## Overview/, 'lines selector bounded range works');

write_file($main, "= Doc\n\ninclude::inc.adoc[lines=..2]\n");
$in = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
$out = $converter->convert($in, {
  source_path => $main,
  include => { enabled => 1 },
});
like($out, qr/## Overview/, 'lines selector open start works');

write_file($main, "= Doc\n\ninclude::inc.adoc[lines=5..-1]\n");
$in = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
$out = $converter->convert($in, {
  source_path => $main,
  include => { enabled => 1 },
});
like($out, qr/## Details|Tail/, 'lines selector open end works');

write_file($main, "= Doc\n\ninclude::inc.adoc[tag=missing]\n");
$in = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
my $ok = eval {
  $converter->convert($in, {
    source_path => $main,
    include => { enabled => 1, on_missing_tag => 'error' },
  });
  1;
};
ok(!$ok, 'missing tag with error policy throws');

$out = $converter->convert($in, {
  source_path => $main,
  include => { enabled => 1, on_missing_tag => 'keep' },
});
$out = Text::AsciidocDown::Include::expand_includes($in, {
  source_path => $main,
  include => { enabled => 1, on_missing_tag => 'keep' },
});
like($out, qr/include::inc\.adoc\[tag=missing\]/, 'missing tag keep policy preserves directive at include stage');

$out = Text::AsciidocDown::Include::expand_includes($in, {
  source_path => $main,
  include => { enabled => 1, on_missing_tag => 'drop' },
});
unlike($out, qr/include::inc\.adoc\[tag=missing\]/, 'missing tag drop policy removes directive at include stage');

write_file($main, "= Doc\n\ninclude::inc.adoc[lines=bad]\n");
$in = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
$ok = eval {
  $converter->convert($in, {
    source_path => $main,
    include => { enabled => 1, on_bad_selector => 'error' },
  });
  1;
};
ok(!$ok, 'invalid selector with error policy throws');

$out = Text::AsciidocDown::Include::expand_includes($in, {
  source_path => $main,
  include => { enabled => 1, on_bad_selector => 'keep' },
});
like($out, qr/include::inc\.adoc\[lines=bad\]/, 'invalid selector keep policy preserves directive at include stage');

write_file($main, "= Doc\n\ninclude::inc.adoc[tag=details,lines=1..1]\n");
$in = do { local $/; open my $fh, '<:encoding(UTF-8)', $main or die $!; <$fh> };
$out = $converter->convert($in, {
  source_path => $main,
  include => { enabled => 1 },
});
like($out, qr/^# Doc\n\n## Details\z/m, 'tag then lines selector order is deterministic');

done_testing;
