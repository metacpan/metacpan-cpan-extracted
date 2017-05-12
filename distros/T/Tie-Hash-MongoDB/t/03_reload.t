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

plan tests => 10;
$need_clean = 1;

use_ok('Tie::Hash::MongoDB');

ok(tie(%hash,'Tie::Hash::MongoDB'),'Tie a new document');
$id = $hash{_id};
ok($id,'id is defined');
$hash{foo} = 'bar';
is($hash{foo},'bar','set foo');

ok(tie(%hash2,'Tie::Hash::MongoDB',$id),'reload document');
ok(tied(%hash2),'new hash is tied');
is($hash2{_id},$id,'compare id');
is($hash2{foo},'bar','compare foo');
is($hash2{foo} = 'baz','baz','change foo');

is($hash{foo},'baz','check update of first hash');

END {
	return unless $need_clean;
	# Clean up
	my $collection = MongoDB::Connection->new->default->default;
	eval { $collection->remove({_id => $id}); };
	eval { $collection->remove({_id => MongoDB::OID->new( value => $id)}); };
}
