#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use lib 'lib';
use Text::JSContact qw(vcard_to_jscontact jscontact_to_vcard patch_vcard);

my $evil = "x\rX-INJECTED:1\r\nY\x00";

my $card = {
  '@type'  => 'Card',
  version  => '1.0',
  uid      => 'urn:uuid:inject-1',
  name     => {
    full       => "Bob$evil",
    components => [ { kind => 'given', value => "Bob$evil" } ],
  },
  emails   => { "e1$evil" => { address => 'bob@example.com', label => "work$evil" } },
  notes    => { n1 => { note => "line one\r\nline two\rX-INJECTED:1" } },
  media    => { m1 => { kind => 'photo', uri => 'https://example.com/p.png',
                        mediaType => "image/png$evil" } },
};

sub check_clean {
  my ($vcf, $what) = @_;
  # split the way a lenient parser would, on a bare CR too
  my @lines = split /\r\n?|\n/, $vcf;
  is_deeply([ grep { /[\x00-\x08\x0b-\x1f\x7f]/ } @lines ], [], "$what: no control characters in any line");
  is_deeply([ grep { /^X-INJECTED/i } @lines ], [], "$what: no injected lines");
}

my $vcf = jscontact_to_vcard($card);
check_clean($vcf, 'jscontact_to_vcard');

# newlines survive as escapes and round-trip as LF
my $back = vcard_to_jscontact($vcf);
my ($note) = values %{$back->{notes}};
is($note->{note}, "line one\nline two\nX-INJECTED:1", 'note newlines, lone CR included, round-trip as LF');
is($back->{name}{full}, "Bobx\nX-INJECTED:1\nY", 'CR in FN becomes LF, NUL dropped');

# patch_vcard regenerates changed properties the same way
my $orig = jscontact_to_vcard({ '@type' => 'Card', version => '1.0',
  uid => 'urn:uuid:inject-1', name => { full => 'Bob' } });
my $old = vcard_to_jscontact($orig);
my $new = { %$old, name => { full => "Bob$evil" } };
check_clean(patch_vcard($orig, $old, $new), 'patch_vcard');

done_testing();
