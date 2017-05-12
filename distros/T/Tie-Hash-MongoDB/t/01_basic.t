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

plan tests => 11;
$need_clean = 1;

use_ok('Tie::Hash::MongoDB');

# TIEHASH
ok(tie %hash,'Tie::Hash::MongoDB','Tie a new document');
ok($hash{_id},'Check if id is set');
$id = $hash{_id};
# STORE
ok($hash{foo} = 'bar','STORE');
# EXISTS
ok(exists($hash{foo}),'EXISTS');
# FETCH
is($hash{foo},'bar','FETCH');
# FIRSTKEY/NEXTKEY
my @keylist = sort {$a cmp $b} (keys(%hash));
is($#keylist,1,'key count');
is($keylist[0],'_id','_id key');
is($keylist[1],'foo','foo key');
# DELETE
delete $hash{foo};
ok(!exists($hash{foo}),'deleted');
# UNTIE
ok(untie %hash,'UNTIE');

END {
	return unless $need_clean;
	# Clean up
	my $collection = MongoDB::Connection->new->default->default;
	eval { $collection->remove({_id => $id}); };
	eval { $collection->remove({_id => MongoDB::OID->new( value => $id)}); };
}
