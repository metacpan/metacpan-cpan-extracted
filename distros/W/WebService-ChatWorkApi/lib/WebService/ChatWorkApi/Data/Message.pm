use strict;
use warnings;
package WebService::ChatWorkApi::Data::Message;
use parent "WebService::ChatWorkApi::Data";
use Mouse;

has message_id => ( is => "ro", isa => "Int" );

has account     => ( is => "ro", isa => "HashRef" );
has body        => ( is => "ro", isa => "Str" );
has send_time   => ( is => "ro", isa => "Int" );
has update_time => ( is => "ro", isa => "Int" );

1;
