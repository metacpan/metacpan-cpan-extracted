use strict;
use Test::More tests => 11;
use YAML::Syck;
use Tie::Hash;

# Blessed (not tied) hash - should carry class tag
{
    my %h;
    my $rh = \%h;
    %h = ( a => 1, b => '2', c => 3.1415, d => 4 );
    bless $rh => 'Tie::StdHash';

    is( Dump($rh),   "--- !!perl/hash:Tie::StdHash\na: 1\nb: 2\nc: '3.1415'\nd: 4\n", "blessed hash ref dumps with class tag" );
    is( Dump( \%h ), "--- !!perl/hash:Tie::StdHash\na: 1\nb: 2\nc: '3.1415'\nd: 4\n", "blessed hash deref dumps with class tag" );
}

# Tied hash - tie object ($th) is blessed, so it gets a class tag
{
    my %h;
    my $th = tie %h, 'Tie::StdHash';
    %h = ( a => 1, b => '2', c => 3.1415, d => 4 );

  SKIP: {
        skip "Perl 5.8 sometimes coerces ints into strings (Perl bug, not ours)", 1
            unless ( $] > '5.009888' || $] < '5.007' );
        is( Dump($th), "--- !!perl/hash:Tie::StdHash\na: 1\nb: 2\nc: '3.1415'\nd: 4\n", "tie object dumps with class tag" );
    }

    # Tied hash reference dumps content (no class tag since \%h is not blessed)
  SKIP: {
        skip "Perl 5.8 tied hash iteration loses some values", 1 if $] < '5.010';
        is( Dump( \%h ), "---\na: 1\nb: 2\nc: '3.1415'\nd: 4\n", "tied hash ref dumps content" );
    }
}

# Tied hash with individual key assignment
{
    my %h;
    my $th = tie %h, 'Tie::StdHash';
    $h{a} = 1;
    $h{b} = '2';
    $h{c} = 3.1415;
    $h{d} = 4;

    is( Dump($th), "--- !!perl/hash:Tie::StdHash\na: 1\nb: 2\nc: '3.1415'\nd: 4\n", "tie object with individual assigns dumps correctly" );
    is( Dump( \%h ), "---\na: 1\nb: 2\nc: '3.1415'\nd: 4\n", "tied hash ref with individual assigns dumps content" );
}

# Empty tied hash
{
    tie my %h, 'Tie::StdHash';
    like( Dump( \%h ), qr/^--- \{\}\s*$/, "empty tied hash dumps as empty map" );
}

# Tied hash with nested structures
{
    tie my %h, 'Tie::StdHash';
    $h{list} = [1, 2, 3];
    $h{nested} = { x => 10 };

    my $yaml = Dump(\%h);
    like( $yaml, qr/list:/, "tied hash with nested list contains key" );
    like( $yaml, qr/nested:/, "tied hash with nested hash contains key" );
}

# Roundtrip: load the dump of a tied hash
{
    tie my %h, 'Tie::StdHash';
    $h{foo} = "bar";
    $h{num} = 42;

    my $yaml = Dump(\%h);
    my $loaded = Load($yaml);
    is_deeply( $loaded, { foo => "bar", num => 42 }, "tied hash roundtrips through dump/load" );
}

# JSON::Syck with tied hash
SKIP: {
    eval { require JSON::Syck };
    skip "JSON::Syck not available", 1 if $@;

    tie my %h, 'Tie::StdHash';
    $h{hello} = 1;
    $h{world} = 2;

    my $json = JSON::Syck::Dump(\%h);
    like( $json, qr/"hello":1/, "JSON::Syck dumps tied hash keys" );
}
