package WWW::FCM::HTTP::Response::ResultSet;

use strict;
use warnings;
use WWW::FCM::HTTP::Response::Result;

sub new {
    my ($class, $results, $sent_reg_ids) = @_;

    bless {
        results      => $results,
        sent_reg_ids => $sent_reg_ids,
    }, $class;
}

sub next {
    my $self = shift;
    my $result      = shift @{ $self->{results} } || return;
    my $sent_reg_id = shift @{ $self->{sent_reg_ids} };
    $result->{_sent_reg_id} = $sent_reg_id;
    WWW::FCM::HTTP::Response::Result->new($result);
}

1;
