use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::Clustericious::Config;
use Test::More tests => 15;
use Mojo::ByteStream qw( b );
use Mojo::Loader;
use Data::Hexdumper qw(hexdump);

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( Yars ));
my $t = $cluster->t;
my $url = $cluster->url;

my $raw     = Mojo::Loader::data_section('main','my_bin_file');
my $content = b($raw)->b64_decode;
my $digest  = b($content)->md5_sum->to_string;

$t->put_ok("$url/file/my_bin_file", {Accept => '*/*'}, $content)
  ->status_is(201)
  ->content_is('ok');

$t->get_ok("$url/file/my_bin_file/$digest");
#  ->content_is($content)
ok($t->tx->res->body eq $content, "content matches") || do {
  my @got = split /\n/, hexdump(
    $t->tx->res->text,
    { output_format => '%4a : %C %S< %L> : %d' },
  );
  my @expected = split /\n/, hexdump(
    $content,
    { output_format => '%4a : %C %S< %L> : %d' },
  );
  
  while(scalar(@got) || scalar(@expected))
  {
    # 0x0586 : 08 0605 090A0000 : .......
    # 12345678901234567890123456789012345
    my $got      = shift(@got)      || ' ' x 35;
    my $expected = shift(@expected) || '';
    my $extra = $got eq $expected ? ' ' : '*';
    diag "$got  $extra   $expected";
  }
};
$t->status_is(200)
  ->content_type_is('application/octet-stream');

$t->delete_ok("$url/file/my_bin_file/$digest")
  ->status_is(200)
  ->content_is('ok');

$t->get_ok("$url/file/my_bin_file/$digest")
  ->status_is(404);

__DATA__

@@ my_bin_file
CsO/w5jDv8OgABBKRklGAAEBAQBIAEgAAMO/w74ADEFwcGxlTWFyawrDv8OiBShJQ0NfUFJPRklM
RQABAQAABRhhcHBsAiAAAHNjbnJSR0IgWFlaIAfDkwAHAAEAAAAAAABhY3NwQVBQTAAAAABhcHBs
AAAAAAAAAAAAAAAAAAAAAAAAw7bDlgABAAAAAMOTLWFwcGwAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAtyWFlaAAABCAAAABRnWFlaAAABHAAAABRiWFlaAAAB
MAAAABR3dHB0AAABRAAAABRjaGFkAAABWAAAACxyVFJDAAABwoQAAAAOZ1RSQwAAAcKEAAAADmJU
UkMAAAHChAAAAA5kZXNjAAABwpQAAAA9Y3BydAAABMOUAAAAQWRzY20AAAHDlAAAAsO+WFlaIAAA
AAAAAHRLAAA+HQAAA8OLWFlaIAAAAAAAAFpzAADCrMKmAAAXJlhZWiAAAAAAAAAoGAAAFVcAAMK4
M1hZWiAAAAAAAADDs1IAAQAAAAEWw49zZjMyAAAAAAABDEIAAAXDnsO/w7/DsyYAAAfCkgAAw73C
kcO/w7/Du8Kiw7/Dv8O9wqMAAAPDnAAAw4BsY3VydgAAAAAAAAABAjMAAGRlc2MAAAAAAAAAE0Nh
bWVyYSBSR0IgUHJvZmlsZQAAAAAAAAAAAAAAE0NhbWVyYSBSR0IgUHJvZmlsZQAAAABtbHVjAAAA
AAAAAA8AAAAMZW5VUwAAACQAAALCnmVzRVMAAAAsAAABTGRhREsAAAA0AAABw5pkZURFAAAALAAA
AcKYZmlGSQAAACgAAADDhGZyRlUAAAA8AAACw4JpdElUAAAALAAAAnJubE5MAAAAJAAAAg5ub05P
AAAAIAAAAXhwdEJSAAAAKAAAAkpzdlNFAAAAKgAAAMOsamFKUAAAABwAAAEWa29LUgAAABgAAAIy
emhUVwAAABoAAAEyemhDTgAAABYAAAHDhABLAGEAbQBlAHIAYQBuACAAUgBHAEIALQBwAHIAbwBm
AGkAaQBsAGkAUgBHAEIALQBwAHIAbwBmAGkAbAAgAGYAw7YAcgAgAEsAYQBtAGUAcgBhMMKrMMOh
MMOpACAAUgBHAEIAIDDDlzDDrTDDlTDCoTDCpDDDq2V4T012w7hqXwAgAFIARwBCACDCgnJfaWPD
j8KPw7AAUABlAHIAZgBpAGwAIABSAEcAQgAgAHAAYQByAGEAIABDAMOhAG0AYQByAGEAUgBHAEIA
LQBrAGEAbQBlAHIAYQBwAHIAbwBmAGkAbABSAEcAQgAtAFAAcgBvAGYAaQBsACAAZgDDvAByACAA
SwBhAG0AZQByAGEAc3bDuGc6ACAAUgBHAEIAIGPDj8KPw7BlwodOw7YAUgBHAEIALQBiAGUAcwBr
AHIAaQB2AGUAbABzAGUAIAB0AGkAbAAgAEsAYQBtAGUAcgBhAFIARwBCAC0AcAByAG8AZgBpAGUA
bAAgAEMAYQBtAGUAcgBhw450wrpUwrd8ACAAUgBHAEIAIMOVBMK4XMOTDMOHfABQAGUAcgBmAGkA
bAAgAFIARwBCACAAZABlACAAQwDDogBtAGUAcgBhAFAAcgBvAGYAaQBsAG8AIABSAEcAQgAgAEYA
bwB0AG8AYwBhAG0AZQByAGEAQwBhAG0AZQByAGEAIABSAEcAQgAgAFAAcgBvAGYAaQBsAGUAUABy
AG8AZgBpAGwAIABSAFYAQgAgAGQAZQAgAGwgGQBhAHAAcABhAHIAZQBpAGwALQBwAGgAbwB0AG8A
AHRleHQAAAAAQ29weXJpZ2h0IDIwMDMgQXBwbGUgQ29tcHV0ZXIgSW5jLiwgYWxsIHJpZ2h0cyBy
ZXNlcnZlZC4AAAAAw7/DmwBDAAEBAQEBAQEBAQEBAQECAgMCAgICAgQDAwIDBQQFBQUEBAQFBgcG
BQUHBgQEBgkGBwgICAgIBQYJCg==

@@ etc/Yars.conf
---
% use Test::Clustericious::Config;
url: <%= cluster->url %>
servers:
  - url: <%= cluster->url %>
    disks:
      - root: <%= create_directory_ok 'data' %>
        buckets: [ 0,1,2,3,4,5,6,7,8,9,'a','b','c','d','e','f' ]

state_file: <%= create_directory_ok("state") . "/state.txt" %>
