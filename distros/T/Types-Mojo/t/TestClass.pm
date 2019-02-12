package  # private package - do not index
    TestClass;

use Moo;
use Types::Mojo qw(:all);

has file => ( is => 'rw', isa => MojoFile, coerce => 1 );
has coll => ( is => 'rw', isa => MojoCollection, coerce => 1 );
has fl   => ( is => 'rw', isa => MojoFileList, coerce => 1 );
has ints => ( is => 'rw', isa => MojoCollection["Int"], coerce => 1 );
has ua   => ( is => 'rw', isa => MojoUserAgent );
has url  => ( is => 'rw', isa => MojoURL, coerce => 1 );

has http_url => ( is => 'rw', isa => MojoURL["https?"], coerce => 1 );
has ftp_url  => ( is => 'rw', isa => MojoURL["ftp"], coerce => 1 );

1;

