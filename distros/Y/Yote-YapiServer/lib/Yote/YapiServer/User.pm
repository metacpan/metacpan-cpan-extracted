package Yote::YapiServer::User;

use strict;
use warnings;
use base 'Yote::YapiServer::BaseObj';

use Digest::MD5;

# Database column definitions
our %cols = (
    handle       => 'VARCHAR(125)',
    email        => 'VARCHAR(125)',
    enc_password => 'VARCHAR(256)',
    created      => 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
    last_login   => 'TIMESTAMP',
    status       => 'INT DEFAULT 0',
    is_admin     => 'TINYINT DEFAULT 0',
    avatar       => '*Yote::YapiServer::File',
    details      => '*HASH<125>_Text',   # User-specific key-value data
    refs         => '*HASH<125>_*',      # User relationships to other objects
);

# Field visibility rules for client serialization
our %FIELD_ACCESS = (
    handle       => { public => 1 },
    email        => { owner_only => 1 },
    avatar       => { public => 1 },
    enc_password => { never => 1 },
    created      => { public => 1 },
    last_login   => { owner_only => 1 },
    status       => { admin_only => 1 },
    is_admin     => { public => 1 },
    details      => { owner_only => 1 },
    refs         => { never => 1 },
);

# Methods callable from client
our %METHODS = (
    getProfile    => { auth => 1 },
    updateProfile => { auth => 1, owner_only => 1, files => 1 },
);

#----------------------------------------------------------------------
# Override to_client_hash — User is its own owner
#----------------------------------------------------------------------

sub to_client_hash {
    my ($self, $session, $viewer) = @_;
    my %result;

    my $field_access = $self->field_access;
    my $is_owner = $viewer && $viewer->id eq $self->id;
    my $is_admin = $viewer && $viewer->get_is_admin;

    my $cols = $self->cols;

    for my $field (keys %$field_access) {
        my $rule = $field_access->{$field};

        next if $rule->{never};
        next if $rule->{owner_only} && !$is_owner && !$is_admin;
        next if $rule->{admin_only} && !$is_admin;

        # Use get() directly — AUTOLOAD-generated getters aren't seen by can()
        next unless exists $cols->{$field};
        $result{$field} = $self->get($field);
    }

    return \%result;
}

#----------------------------------------------------------------------
# Client-callable methods
#----------------------------------------------------------------------

sub getProfile {
    my ($self, $args, $session) = @_;
    return 1, $self;
}

sub updateProfile {
    my ($self, $args, $session) = @_;

    my %allowed = map { $_ => 1 } qw(email avatar);

    for my $field (keys %$args) {
        if ($allowed{$field}) {
            my $setter = "set_$field";
            $self->$setter($args->{$field});
        }
    }

    return 1, $self;
}

#----------------------------------------------------------------------
# Server-side utility methods
#----------------------------------------------------------------------

sub verify_password {
    my ($self, $password) = @_;
    my $handle = $self->get_handle;
    my $email = $self->get_email // '';
    my $enc = crypt($password, length($password) . Digest::MD5::md5_hex("$handle.$email"));
    return $enc eq $self->get_enc_password;
}

sub set_password {
    my ($self, $password) = @_;
    my $handle = $self->get_handle;
    my $email = $self->get_email // '';
    my $enc = crypt($password, length($password) . Digest::MD5::md5_hex("$handle.$email"));
    $self->set_enc_password($enc);
}

1;

__END__

=head1 NAME

Yote::YapiServer::User - User account model

=head1 DESCRIPTION

Represents a user account with authentication and profile data.
Inherits from Yote::YapiServer::BaseObj for persistence and serialization.

=cut
