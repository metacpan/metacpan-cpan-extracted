#!/usr/bin/perl -l
# This will test through a standard workflow / use-case
# * connect/associate
# * read an entry from KeePass
# * write a new entry into KeePass
#
use 5.012; # strict, //
use warnings;
use MIME::Base64;
use Data::Dumper;

use WWW::KeePassHttp;

# NOTE: this key is used for testing (it was the key used in the example at https://github.com/pfn/keepasshttp/)
#   it is NOT the value you should use for your key in the real application
#   In a real application, you must generate a 256-bit cryptographically secure key,
#   using something like Math::Random::Secure or Crypt::Random,
#   or use `openssl enc -aes-256-cbc -k secret -P -md sha256 -pbkdf2 -iter 100000`
#       and convert the 64 hex nibbles to a key using pack 'H*', $sixtyfournibbles
my $key = decode_base64('CRyXRbH9vBkdPrkdm52S3bTG2rGtnYuyJttk/mlJ15g=');

# start by intializing the kph object with your key
my $kph = WWW::KeePassHttp->new(Key => $key);

# Check if your app has been associated, and if not, associate it
$kph->associate() unless $kph->test_associate();

# attempt to grab an entry:
my $entries = $kph->get_logins('WWW-KeePassHttp');
print "get_logins => ", Dumper $entries;

# count the number of matching entries
my $count = $kph->get_logins_count('WWW-KeePassHttp');
print "count => ", $count;

# try to create a new entry
$kph->set_login(
        Login => 'workflow.pl.username',
        Url => 'workflow.pl.url',
        Password => 'workflow.pl.password',
    );
