use strict;
use warnings;
package WebService::ChatWorkApi::DataSet::Me;
use parent "WebService::ChatWorkApi::DataSet";
use Smart::Args;
use Mouse;
use WebService::ChatWorkApi::Data::Me;

has data => ( is => "ro", isa => "Str", default => sub { "WebService::ChatWorkApi::Data::Me" } );

sub retrieve {
    args my $self;
    my $res = $self->dh->me;
    return $self->bless( $res->data );
}

1;
