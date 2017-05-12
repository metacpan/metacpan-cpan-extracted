use strict;
use warnings;
use Test::More tests => 23;
use Capture::Tiny qw( capture_stdout );
use Yars::Command::yars_generate_diskmap;
use YAML::XS qw( Load );
use File::Temp qw( tempdir );

do {

  my $tmp = tempdir( CLEANUP => 1 );

  my $yml = capture_stdout {
    open my $fh, '>', "$tmp/map.txt";
    print $fh "host01 /disk01\nhost01 /disk02\nhost02 /disk03\nhost02 /disk04\n";
    close $fh;
    eval { Yars::Command::yars_generate_diskmap->main(2, "$tmp/map.txt") };
    is $@, '', 'yars_generate_diskmap did not crash';
  };

  my $config = eval { Load($yml) };
  is $@, '', 'valid yaml';

  is $config->{servers}->[0]->{url}, 'http://host01:9001', 'servers.0.url = http://host01:9001';
  is $config->{servers}->[1]->{url}, 'http://host02:9001', 'servers.0.url = http://host02:9001';

  my @actual = sort map { @{ $config->{servers}->[$_->[0]]->{disks}->[$_->[1]]->{buckets} } } ([0,0],[1,0],[0,1],[1,1]);
  my @expected = map { sprintf "%02x", $_ } 0..255;

  is_deeply \@actual, \@expected, 'all prefixes covered';
  
};

do {

  my $tmp = tempdir( CLEANUP => 1 );

  my $yml = capture_stdout {
    open my $fh, '>', "$tmp/map.txt";
    print $fh "host01 /disk01\nhost01 /disk02\nhost02 /disk03\nhost02 /disk04\n";
    close $fh;
    eval { Yars::Command::yars_generate_diskmap->main('--port' => 3001, 2, "$tmp/map.txt") };
    is $@, '', 'yars_generate_diskmap did not crash';
  };

  my $config = eval { Load($yml) };
  is $@, '', 'valid yaml';

  is $config->{servers}->[0]->{url}, 'http://host01:3001', 'servers.0.url = http://host01:3001';
  is $config->{servers}->[1]->{url}, 'http://host02:3001', 'servers.0.url = http://host02:3001';

  my @actual = sort map { @{ $config->{servers}->[$_->[0]]->{disks}->[$_->[1]]->{buckets} } } ([0,0],[1,0],[0,1],[1,1]);
  my @expected = map { sprintf "%02x", $_ } 0..255;

  is_deeply \@actual, \@expected, 'all prefixes covered';
  
};

do {

  my $tmp = tempdir( CLEANUP => 1 );

  my $yml = capture_stdout {
    open my $fh, '>', "$tmp/map.txt";
    print $fh "host01 /disk01\nhost01 /disk02\nhost02 /disk03\nhost02 /disk04\n";
    close $fh;
    eval { Yars::Command::yars_generate_diskmap->main('--protocol' => 'https', 2, "$tmp/map.txt") };
    is $@, '', 'yars_generate_diskmap did not crash';
  };

  my $config = eval { Load($yml) };
  is $@, '', 'valid yaml';

  is $config->{servers}->[0]->{url}, 'https://host01:9001', 'servers.0.url = https://host01:9001';
  is $config->{servers}->[1]->{url}, 'https://host02:9001', 'servers.0.url = https://host02:9001';

  my @actual = sort map { @{ $config->{servers}->[$_->[0]]->{disks}->[$_->[1]]->{buckets} } } ([0,0],[1,0],[0,1],[1,1]);
  my @expected = map { sprintf "%02x", $_ } 0..255;

  is_deeply \@actual, \@expected, 'all prefixes covered';
  
};

do {

  my $tmp = tempdir( CLEANUP => 1 );

  my $yml = capture_stdout {
    open my $fh, '>', "$tmp/map.txt";
    print $fh "host-name01 /disk01\n";
    close $fh;
    eval { Yars::Command::yars_generate_diskmap->main(2, "$tmp/map.txt") };
    is $@, '', 'yars_generate_diskmap did not crash';
  };

  my $config = eval { Load($yml) };
  is $@, '', 'valid yaml';

  is $config->{servers}->[0]->{url}, 'http://host-name01:9001', 'servers.0.url = http://host-name01:9001';

  my @actual = sort map { @{ $config->{servers}->[$_->[0]]->{disks}->[$_->[1]]->{buckets} } } ([0,0]);
  my @expected = map { sprintf "%02x", $_ } 0..255;

  is_deeply \@actual, \@expected, 'all prefixes covered';
  
};


do {

  my $tmp = tempdir( CLEANUP => 1 );

  my $yml = capture_stdout {
    open my $fh, '>', "$tmp/map.txt";
    print $fh "host01:1234 /disk01\n";
    close $fh;
    eval { Yars::Command::yars_generate_diskmap->main(1, "$tmp/map.txt") };
    is $@, '', 'yars_generate_diskmap did not crash';
  };

  my $config = eval { Load($yml) };
  is $@, '', 'valid yaml';

  is $config->{servers}->[0]->{url}, 'http://host01:1234', 'servers.0.url = http://host01:1234';

  my @actual = sort map { @{ $config->{servers}->[$_->[0]]->{disks}->[$_->[1]]->{buckets} } } ([0,0]);
  my @expected = map { sprintf "%1x", $_ } 0..15;

  is_deeply \@actual, \@expected, 'all prefixes covered';
  
};


