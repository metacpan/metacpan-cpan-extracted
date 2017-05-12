use strict;
use warnings;
use Test::More;
use WebService::Hatena::Bookmark::Lite;

my $username = '';
my $password = '';
eval{
    use Config::Pit;
    my $config = Config::Pit::pit_get("http://www.hatena.ne.jp");
    $username = $config->{username};
    $password = $config->{password};
};

if ($username && $password) {
    plan tests => 8 ;
}
else {
    plan skip_all => q{ Please set config . perl -MConfig::Pit -e'Config::Pit::set("http://www.hatena.ne.jp",}.
           q/ data=>{ username => "foobar", password => "barbaz" })' /;
}

my $url1  = 'http://www.google.co.jp';
my $url2  = 'http://www.yahoo.co.jp';
my @tag   = ( qw/ hoge moge /);
my $com   = 'tetetetetst';
my $bookmark = '';
my $edit_ep1 = '';
my $edit_ep2 = '';

# new
{
    $bookmark = WebService::Hatena::Bookmark::Lite->new(
        username => $username,
        password => $password,
    );
    isa_ok( $bookmark , 'WebService::Hatena::Bookmark::Lite' , 'WebService::Hatena::Bookmark::Lite Object new OK');
}

### Add
{
    $edit_ep1 = $bookmark->add(
        url      => $url1 ,
        tag      => \@tag ,
        comment  => $com  ,
    );

    $edit_ep2 = $bookmark->add(
        url      => $url2 ,
        tag      => \@tag ,
        comment  => $com  ,
    );

    like( $edit_ep1 , qr{^atom/edit/[0-9]+$} , 'entry1 add OK' );
    like( $edit_ep2 , qr{^atom/edit/[0-9]+$} , 'entry2 add OK' );
}

### edit
{
    @tag = ( qw/ kaka tete /);
    $com = 'edit comment';

    my $edit_ret = $bookmark->edit(
        edit_ep  => $edit_ep1,
        tag      => \@tag ,
        comment  => $com  ,
    );
    is( $edit_ret , 1 , 'entry1 edit OK');
}

### getEntry
{
    my $entry = $bookmark->getEntry( edit_ep  => $edit_ep1 );
    isa_ok( $entry , 'XML::Atom::Entry' , 'getEntry return XML::Atom::Entry Object OK');
}

### delete
{
    my $del_ret = $bookmark->delete(
       edit_ep  => $edit_ep2,    
    );
    is( $del_ret , 1 , 'entry2 delete OK');
}

### getFeed , entry2edit_ep
{
    my $feed = $bookmark->getFeed();
    isa_ok( $feed , 'XML::Atom::Feed' , 'getFeed return XML::Atom::Feed Object OK');

    my @entries = $feed->entries;
    my $entry = shift @entries;
    my $edit_ep = $bookmark->entry2edit_ep( $entry );
    like( $edit_ep , qr{^atom/edit/[0-9]+$} , 'entry2edit_ep convert OK' );
}

### after test 
{
    $bookmark->delete(edit_ep  => $edit_ep1);
}

