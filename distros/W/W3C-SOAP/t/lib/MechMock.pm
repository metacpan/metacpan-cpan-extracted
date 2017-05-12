package MechMock;

use strict;
use warnings;
use parent qw/LWP::UserAgent/;

our $VERSION = 0.14;

my $content;
sub content {
    my ($self, $text) = @_;
    $content = $text if @_ > 1;
    return $content;
}

sub post {
    return MechResponse->new($content);
}

package MechResponse;

use strict;
use warnings;
use parent qw/HTTP::Response/;

our $VERSION = 0.14;

sub new {
    my ($class, $content) = @_;
    return bless { content => $content }, $class;
}

sub content { shift->{content} };
sub decoded_content { shift->{content} };

1;
