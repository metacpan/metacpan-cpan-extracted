#!/usr/bin/perl -w

use lib './lib';

use XML::Malware;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use Digest::SHA qw(sha1_hex sha256_hex sha512_hex);

my $h;
$h->{'company'} = 'wes co';
$h->{'author'} = 'wes';
$h->{'comment'} = 'test';
$h->{'timestamp'} = '2009-02-23T17:34:56';
$h->{'id'} = '';

my $test_file = 'asdfasdfasdfasdfasdf';
my $md5 = md5_hex($test_file);
my $sha1 = sha1_hex($test_file);
my $sha256 = sha256_hex($test_file);
my $sha512 = sha512_hex($test_file);

push(@{$h->{'objects'}->{'file'}}, { id => $md5,  md5 => $md5, sha1 => $sha1, sha256 => $sha256, sha512 => $sha512 });
push(@{$h->{'objects'}->{'classification'}}, { id => '', companyName => 'some company', type => 'dirty', classificationName => 'className'});

my $m = XML::Malware->new($h);

warn $m->out();

my $m2 = XML::Malware->new();
$m2->in($m->out());

warn Dumper($m2->_hash());
my $x = $m2->_hash->{'objects'}->{'file'}[0]->{'id'};
