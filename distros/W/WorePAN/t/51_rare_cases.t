use strict;
use warnings;
use Test::More;
use WorePAN;

plan skip_all => "set WOREPAN_NETWORK_TEST to test" unless $ENV{WOREPAN_NETWORK_TEST};

my @authors_with_hyphen = (
  'C/CH/CHANG-LIU/XML-Node-0.11.tar.gz',
  'N/NI/NI-S/Regexp-0.001.tar.gz',
);

my @two_letter_authors = (
  'I/IX/IX/Data-Properties-0.02.tar.gz',
  'J/JV/JV/Acme-Nada-0.1.tar.gz',
  'R/RA/RA/Apache-PrettyPerl-1.00.tar.gz',
);

my @second_char_is_num = (
# 'P5P',
);

for my $file (@authors_with_hyphen, @two_letter_authors) {
  my $worepan = eval {
    WorePAN->new(
      files => [$file],
      no_network => 0,
      use_backpan => 1,
      cleanup => 1,
    );
  };

  ok !$@ && $worepan, "no eval errors";
  ok $worepan && $worepan->file($file)->exists, "downloaded $file successfully";
}

# short form
for my $file (@authors_with_hyphen, @two_letter_authors) {
  (my $short_file = $file) =~ s|^[^/]+/[^/]+/||;
  my $worepan = eval {
    WorePAN->new(
      files => [$short_file],
      no_network => 0,
      use_backpan => 1,
      cleanup => 1,
    );
  };

  ok !$@ && $worepan, "no eval errors";
  ok $worepan && $worepan->file($file)->exists, "downloaded $file successfully";
}

done_testing;
