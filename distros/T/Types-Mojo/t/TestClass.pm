package  # private package - do not index
    TestClass;

use Moo;
use Types::Mojo qw(MojoFile MojoCollection MojoFileList);

has file => ( is => 'rw', isa => MojoFile, coerce => 1 );
has coll => ( is => 'rw', isa => MojoCollection, coerce => 1 );
has fl   => ( is => 'rw', isa => MojoFileList, coerce => 1 );
has ints => ( is => 'rw', isa => MojoCollection["Int"], coerce => 1 );

1;

