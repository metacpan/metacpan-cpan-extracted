use Test::More;
use IO::Socket;
use MongoDB::Connection;
use MongoDB::OID;

IO::Socket::INET->new(
       Proto    => "tcp",
       PeerAddr => "localhost",
       PeerPort => "27017",
   )
 or plan skip_all => "no MongoDB server found";

plan tests => 5;
$need_clean = 1;

use_ok('Tie::Hash::MongoDB');

# TIEHASH
ok(tie %hash,'Tie::Hash::MongoDB','Tie a new document');
$id = $hash{_id};
ok($id,'id is defined');
ok(!ref($id),'id is no reference');
like($id,qr/^[0-9a-f]+$/i,'is is hex');

END {
	return unless $need_clean;
	# Clean up
	my $collection = MongoDB::Connection->new->default->default;
	eval { $collection->remove({_id => $id}); };
	eval { $collection->remove({_id => MongoDB::OID->new( value => $id)}); };
}
