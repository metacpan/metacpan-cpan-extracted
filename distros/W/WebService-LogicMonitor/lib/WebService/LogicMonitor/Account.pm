package WebService::LogicMonitor::Account;

# ABSTRACT: A LogicMonitor user account

use v5.16.3;
use WebService::LogicMonitor::Account::Role;
use Moo;

with 'WebService::LogicMonitor::Object';

sub BUILDARGS {
    my ($class, $args) = @_;

    my %transform = (
        contactMethod       => 'contact_method',
        firstName           => 'first_name',
        lastName            => 'last_name',
        forcePasswordChange => 'force_password_change',
        smsEmailFormat      => 'smsemail_format',
        lastLoginOn         => 'last_login_on',
        viewMessageOn       => 'view_message_on',
        createBy            => 'createBy',

    );

    for my $key (keys %transform) {
        $args->{$transform{$key}} = delete $args->{$key} if $args->{$key};
    }

    # don't keep empty strings
    for my $k (qw/note phone smsemail/) {
        if (exists $args->{$k} && !$args->{$k}) {
            delete $args->{$k};
        }
    }

    if ($args->{roles}) {
        my @roles;
        my %cache
          ;    # cache roles so we can use references instread of duplicating

        for my $role (@{$args->{roles}}) {
            if (exists $cache{$role->{id}}) {
                push @roles, $cache{$role->{id}};
            } else {
                my $r = WebService::LogicMonitor::Account::Role->new($role);
                push @roles, $r;
                $cache{$role->{id}} = $r;
            }

        }
        $args->{roles} = \@roles;
    }

    return $args;
}

has id => (is => 'ro');    # int

has [qw/first_name last_name username/] => (is => 'rw');    # str

has contact_method => (is => 'rw');                         # enum

has [qw/email smsemail/] => (is => 'rw');                   # str email

has force_password_change => (is => 'rw');                  # bool

has note => (is => 'rw');                                   # str

has status => (is => 'rw');    # enum active|suspended

has smsemail_format => (is => 'rw');    # enum sms|fulltext

has phone => (is => 'rw');              # Str - phone number

has create_by => (is => 'rw');          # Str

has [qw/view_message_on last_login_on/] => (is => 'rw');    # date iso8601-ish

has roles => (is => 'rw');

#     password              "$2a$10$JtUctKVsWI1DdFzlMQV4peZsh38nkg2nYU1NuXltjypyoSiWLHYeG",
#     priv                  "readwrite",
#     roles                 [
#         [0] {
#             description   "Administrator can do everything",
#             id            1,
#             name          "administrator",
#             privileges    []
#         }
#     ],
#     viewPermission        {
#         Alerts       true,
#         Dashboards   true,
#         Hosts        true,
#         NewUI        true,
#         Reports      true,
#         Services     true,
#         Settings     true
#     }
# },

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::Account - A LogicMonitor user account

=head1 VERSION

version 0.153170

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
