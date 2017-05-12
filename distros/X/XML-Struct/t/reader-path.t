use strict;
use Test::More;
use XML::Struct qw(readXML);

my ($xml, $reader);

sub init($) {
    my $path = shift;
    my $reader = XML::Struct::Reader->new( 
        attributes => 0, path => $path,
        from => XML::LibXML::Reader->new( location => 't/nested.xml' )
    );
    is $reader->path, $path, "default path = '$path'";
    return $reader;
}

for my $root (qw(* / /* /nested)) {
    $reader = init($root);
    $xml = $reader->readNext;
    is $xml->[0], 'nested', 'root';
}

for my $root (qw(x /x //x)) {
    $reader = init($root);
    is $reader->readNext, undef, 'wrong namedroot';
}

sub test_path(@) {
    my $reader;
    while (@_) {
        my $path   = shift;
        my $result = shift;
        my $msg    = shift;

        if (!$reader) {
            $reader = init($path);
            is_deeply $reader->readNext, $result, $msg;
        } else {
            my $next = $reader->readNext( $path );
            is_deeply $next, $result, $msg;
        }
    }
}

test_path 
    '/nested/items/*', [ a => ["X"] ], 'readNext (default path set)',
    undef, [ "b" ], 'readNext (reusing default path)',
    '//', [ a => ["Y"] ], 'readNext (relative)';

test_path
    '/nested/items/b', [ "b" ], 'readNext with name',
    '*', [ "a", ["Y"] ], '...';

done_testing;
