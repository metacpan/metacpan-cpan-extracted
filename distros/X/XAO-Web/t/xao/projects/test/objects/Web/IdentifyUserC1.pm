package XAO::DO::Web::IdentifyUserC1;
use strict;
use warnings;
use XAO::Objects;
use XAO::Utils;
use Error qw(:try);
use base XAO::Objects->load(objname => 'Web::IdentifyUser');

sub login_password_encrypt () {
    my $self=shift;
    my $args=get_args(\@_);

    my $password=$args->{'password_typed'};

    defined $password || throw $self "- no 'password_typed'";

    # Almost plain text
    #
    return '[*C1*'.$password.'*]';
}
