use strict;
use warnings;
use Test::More;
use MyNote;

use UUID qw(uuid3 uuid5);

ok 1, 'loaded';

my $FQDN = 'www.example.com';

#
# computed via Digest::MD5, Digest::SHA1, and/or Data::UUID.
#
#use Data::UUID;
#my $ug = Data::UUID->new;
#my $str = lc $ug->create_from_name_str(NameSpace_DNS, $FQDN);
#note "DU md5 => $str";
#
my $uu_md5  = '5df41881-3aed-3515-88a7-2f4a814cf09e';
my $uu_sha1 = '2ed6657d-e927-568b-95e1-2665a8aea6a2';

is uuid3(dns => $FQDN), $uu_md5,  'md5 correct';
is uuid5(dnS => $FQDN), $uu_sha1, 'sha1 correct';

done_testing;
