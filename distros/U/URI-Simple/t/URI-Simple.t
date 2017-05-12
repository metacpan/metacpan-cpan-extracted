use Test::More;
BEGIN { use_ok('URI::Simple') };

###first tests
my $url = 'urn:example:animal:ferret:nose';
my $uri = URI::Simple->new($url);

is($uri->scheme,'urn','Scheme Match');
is($uri->path,'example:animal:ferret:nose','Strict Path');
############

my $url2 = 'foo://username:password@example.com:8042/over/there/index.dtb?type=animal&name=narwhal&name=narwhal2#nose';
my $uri2 = URI::Simple->new($url2);

###test for query with the same key name
### must return an array ref of all data
my $q = sub {
    my $query = shift;
    my $name = $query->{name};
    return ref $name eq 'ARRAY' ? 1 : 0;
};

ok($q->($uri2->query), 'Same Query Keys');
is($uri2->query->{type}, 'animal' , 'Query key vaue');

##authority
is($uri2->authority, 'username:password@example.com:8042' , 'Authority');

##user & password
is($uri2->user, 'username' , 'User');
is($uri2->password, 'password' , 'Password');
is($uri2->userInfo,'username:password','User Info');

##host and path
is($uri2->host, 'example.com' , 'host name');
is($uri2->port,8042,'Port');
is($uri2->fragment,'nose','Fragment');
is($uri2->path,'/over/there/index.dtb','uri2 Path');
is($uri2->file,'index.dtb','uri2 File');

###stict testing - split URIs according to RFC 3986
my $url3 = 'mailto:username@example.com?subject=Topic';
my $uri3 = URI::Simple->new($url3);

is($uri3->path,'username@example.com','URI3 Strict Path');
is($uri3->querystring,'subject=Topic','URI3 Query String');
is($uri3->scheme,'mailto','URI3 Scheme');



###simple uri
my $simpleURL = 'http://google.com/some/path/index.html?x1=yy&x2=pp#anchor';
my $simpleURI = URI::Simple->new($simpleURL);

is($simpleURI->file,'index.html','simpleURI File');
is($simpleURI->anchor,'anchor','simpleURI Anchor');
is($simpleURI->directory,'/some/path/','simpleURI Directory');

done_testing();



