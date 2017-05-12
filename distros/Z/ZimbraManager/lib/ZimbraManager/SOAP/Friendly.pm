package ZimbraManager::SOAP::Friendly;

use Mojo::Base 'ZimbraManager::SOAP';
use Mojo::Util qw(dumper);


my $MAP = {
    auth => {
        args => [ qw(password accountName)],
        out  => sub {
            my ($password, $accountName) = @_;
            return {    persistAuthTokenCookie => 1,
                        password => $password,
                        account =>  {
                            by => 'name',
                            _ => $accountName}
            };
        },
        in  => sub {
            my $ret = shift;
            return $ret;
        },
    },
    getAccountInfo => {
        args => [ qw(accountName)],
        out  => sub {
            my ($accountName) = @_;
            return {   account => {
                            by => 'name',
                            _  => $accountName}
            };
        },
        in  => sub {
            my $ret = shift;
            my $a   = $ret->{a};
            my $parsed = {};
            for my $elem (@$a) {
                $parsed->{$elem->{n}} = $elem->{'_'};
            }
            return $parsed;
        },
    },
    getAccount => {
        args => [ qw(accountName attribute?) ],
        out  => sub {
            my ($accountName, $attribute) = @_;
            my $argHash;
            if (defined $attribute) { # optional; get just this element
                $argHash = { account => {
                                         by => 'name',
                                         _  => $accountName},
                             attrs   => $attribute,
                           };
            }
            else {
                $argHash = { account => {
                                         by => 'name',
                                         _  => $accountName}
                           };
            }
            return $argHash;
        },
        in  => sub {
            my $ret = shift;
            # $ret->{account} is a hash with
            # keys 'a' (all account settings), 'id' (UUID), 'name' (email)
            my $a = $ret->{account}->{a};
            my $parsed = {};
            for my $elem (@$a) {
                $parsed->{$elem->{n}} = $elem->{'_'};
            }
            return $parsed;
        },
    },
    getAllAccounts => {
        args => [ qw(serverName domainName)],
        out  => sub {
            my ($serverName, $domainName) = @_;
            return {    server => {
                            by => 'name',
                            _  => $serverName },
                        domain => {
                            by => 'name',
                            _  => $domainName }
            };
        },
        in  => sub {
            my $ret = shift;
            return $ret;
        },
    },
    modifyAccount => {
        args => [ qw(zimbraUUID modifyKey modifyValue)],
        out  => sub {
            my ($zimbraUUID, $modifyKey, $modifyValue ) = @_;
            return {    id => $zimbraUUID,
                        a => {
                            n => $modifyKey,
                            _ => $modifyValue
                        }
            };
        },
        in  => sub {
            my $ret = shift;
            # $ret->{account} is a hash with
            # keys 'a' (all account settings), 'id' (UUID), 'name' (email)
            my $a = $ret->{account}{a};
            my $parsed = {};
            for my $elem (@$a) {
                $parsed->{$elem->{n}} = $elem->{'_'};
            }
            return $parsed;
        },
    },
    getAllDomains => {
        args => [ ],
        out  => sub {
            return {};
        },
        in  => sub {
            my $ret = shift;
            return $ret;
        },
    },
    getDomainInfo => {
        args => [ qw(domainName)],
        out  => sub {
            my ($domainName) = @_;
            return {    domain => {
                            by => 'name',
                            _  => $domainName }
            };
        },
        in  => sub {
            my $ret = shift;
            my $domain = $ret->{domain};
            if ($domain->{id} eq 'globalconfig-dummy-id') {
                return {
                    id => undef
                };
            }
            else {
                return $domain;
            }
        },
    },
    createAccount => {
        args => [ qw(uid defaultEmailDomain plainPassword givenName surName country displayName localeLang cosId) ],
        out  => sub {
            my ($uid, $defaultEmailDomain, $plainPassword, $givenName, $surName, $country, $displayName, $localeLang, $cosId) = @_;
            return {
                name     => $uid . '@' . $defaultEmailDomain,
                password => $plainPassword,
                a => [
                        {
                            n => 'givenName',
                            _ => $givenName,
                        },
                        {
                            n => 'sn',
                            _ => $surName,
                        },
                        {
                            n => 'c',
                            _ => $country,
                        },
                        {
                            n => 'displayName',
                            _ => $displayName,
                        },
                        {
                            n => 'zimbraPrefLocale',
                            _ => $localeLang,
                        },
                        {
                            n => 'zimbraPasswordMustChange',
                            _ => 'FALSE',
                        },
                        {
                            n => 'zimbraCOSid',
                            _ => $cosId,
                        },
                ],
            };
        },
        in  => sub {
            my $ret = shift;
            # $ret->{account} is a hash with
            # keys 'a' (all account settings), 'id' (UUID), 'name' (email)
            my $a = $ret->{account}{a};
            my $parsed = {};
            for my $elem (@$a) {
                $parsed->{$elem->{n}} = $elem->{'_'};
            }
            return $parsed;
        },
    },
    addAccountAlias => {
        args => [ qw(zimbraUUID emailAlias) ],
        out  => sub {
            my ($zimbraUUID, $emailAlias) = @_;
            return {
                id    => $zimbraUUID,
                alias => $emailAlias
            };
        },
        in  => sub {
            my $ret = shift;
            return $ret;
        },
    },
    removeAccountAlias => {
        args => [ qw(zimbraUUID emailAlias) ],
        out  => sub {
            my ($zimbraUUID, $emailAlias) = @_;
            return {
                id    => $zimbraUUID,
                alias => $emailAlias
            };
        },
        in  => sub {
            my $ret = shift;
            return $ret;
        },
    },
    deleteAccount => {
        args => [ qw(zimbraUUID) ],
        out  => sub {
            my ($zimbraUUID) = @_;
            return {
                id => $zimbraUUID
            };
        },
        in  => sub {
            my $ret = shift;
            return $ret;
        },
    },
    getCos => {
        args => [ qw(cosName) ],
        out  => sub {
            my ($cosName) = @_;
            return {    cos => {
                            by => 'name',
                            _  => $cosName }
            };
        },
        in  => sub {
            my $ret = shift;
            # $ret->{cos} is a hash with
            # 'id' (UUID), 'name' (email)
            return $ret->{cos};
        }
    },
};


my $helperHashingAllAccounts = sub {
    my $ret = shift;
    my $accounts;
    for my $za ( @{ $ret->{account} } ) {
        my $name = $za->{name};
        my $id = $za->{id};
        my %kv = map { $_->{'n'} => $_->{'_'} } @{$za->{a}};
        $accounts->{$name} = {
            'name' => $name,
            'id' => $id,
            'kv' => \%kv,
        };
    }
    return $accounts;
};


sub callFriendlyLegacy {
    my $self      = shift;
    my $authToken = shift;
    my $action    = shift;
    my $args      = shift;
    my $namedParameters = {
        action    => $action,
        args      => $args,
        authToken => $authToken,
    };
    return $self->callFriendly($namedParameters);
}

sub callFriendly {
    my $self            = shift;
    my $namedParameters = shift;
    if (ref $namedParmeters ne 'HASH') {
        $namedParameters = { @_ };
    }
    my $action          = $namedParameters->{action};
    my $args            = $namedParameters->{args};
    my $authToken       = $namedParameters->{authToken};

    # check input
    if (not exists $MAP->{$action}) {
        die "no valid function ($action) given";
    }
    if ($action ne 'auth' and not defined $authToken) {
        die 'parameter authToken missing';
    }

    my $soapArgsBuild = {};
    if (scalar @{$MAP->{$action}{args}}) {
        if ((not defined $args) or (ref $args ne 'HASH')) {
            die 'parameter args is not a HASH';
        }
        for my $key (@{$MAP->{$action}->{args}}) {
            next if $key =~ m/\?$/; # optional argument
            if (not exists $args->{$key}) {
                die "function $action: mandatory key/value (key: $key) not given";
            }
        }

        # build argument list
        my @orderedArgs;
        for my $key (@{$MAP->{$action}->{args}}) {
            my $localKey = $key;
            $localKey =~ s/\?$//; # remove optional flag but keep key
            push @orderedArgs, $args->{$localKey};
        }

        # build SOAP arguments
        $soapArgsBuild = $MAP->{$action}->{out}->(@orderedArgs);
    }

    # build SOAP action name
    my $actionRequest = $action . 'Request';

    $self->log->debug(dumper({
        _function => 'ZimbraManager::Soap::callFriendly',
        action    =>$action,
        args      =>$args,
        authToken =>$authToken
    }));

    my ($ret, $err) = $self->call({
        action    =>$actionRequest,
        args      =>$soapArgsBuild,
        authToken =>$authToken,
    });

    # parse SOAP answer
    my $parsedAnswer = $MAP->{$action}->{in}->($ret);
    return ($parsedAnswer, $err);
}

1;

=pod

=encoding UTF-8

=head1 NAME

ZimbraManager::SOAP::Friendly

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use ZimbraManager::SOAP::Friendly;

    my $authToken = 'VERY_LONG_TOKEN_LINE_FROM_SESSION';
    my $action = 'createAccount';
    my $args = {
        uid                => 'rplessl',
        defaultEmailDomain => 'oetiker.ch',
        givenName          => 'Roman',
        surName            => 'Plessl',
        country            => 'CH',
        displayName        => 'Roman Plessl',
        localeLang         => 'de',
        cosId              => 'ABCD-EFGH-1234',
    };
    my $namedParameters = {
        action    => $action,
        args      => $args,
        authToken => $authToken,
    };
    my ($ret, $err) = $self->soap->callFriendly($namedParameters);

also

    $self->soap->callFriendly(
        authToken => $authToken,
        action    => $action,
        args      => { },
    );

is valid

=head1 DESCRIPTION

Helper class for Zimbra adminstration with a user friendly interface

=head1 NAME

ZimbraManager::SOAP::Friendly - class to manage Zimbra with perl and SOAP

=head1 ATTRIBUTES

=head2 $MAP

This hash defines arguments and out-going (to Zimbra) and in-coming
(from Zimbra) mapping subroutines for SOAP actions called with the
callFriendly() method below.

=head1 METHODS

All the methods of L<Mojo::Base> plus:

=head2 Private functions

Private functions used in the startup function

=head3 helperHashingAllAccounts

Helper function for processing AllAccounts SOAP call

=head2 Public methods

=head3 callFriendly

Calls Zimbra with the given argument and returns the SOAP response as perl hash.

=head1 COPYRIGHT

Copyright (c) 2014 by Roman Plessl. All rights reserved.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

S<Roman Plessl E<lt>roman@plessl.infoE<gt>>

=head1 HISTORY

 2014-04-29 rp Initial Version

=head1 AUTHOR

Roman Plessl <rplessl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Roman Plessl.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__


# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
