use Test::More tests => 52;

use_ok('MongoDB');

# Test using the same collection in three DBs
my @dbs = (map { 'Y_O_M_t06_'.$_; } (0..2));

my $server = MongoDB::Connection->new(host => 'localhost');

# Clean up
for my $db (@dbs) {
    eval { $server->$db->drop; };
    ok (1,'Drop database '.$db);
}

# Get database handlers
my @dbh = map { $server->$_; } @dbs;

# Get collection handlers
my @colh = map { $_->t06_collection; } @dbh;

# Create some objects
for my $i (0..$#colh) {
    for my $n (1..3) {
        ok($colh[$i]->insert({database => $dbs[$i], n => $n}),$i.' insert object');
    }
}

# Check the objects
for my $i (0..$#colh) {
    for my $n (1..3) {
        is($colh[$i]->{_database}->{name},$dbs[$i],"i$i/n$n check database name in handle");
        my $doc = $colh[$i]->find_one({n => $n});
        ok($doc,"i$i/n$n got document");
        is($doc->{n},$n,"i$i/n$n check n");
        is($doc->{database},$dbs[$i],"i$i/n$n check database");
    }
}

# Clean up
for my $db (@dbs) {
    eval { $server->$db->drop; };
    ok (1,'Drop database '.$db);
}
