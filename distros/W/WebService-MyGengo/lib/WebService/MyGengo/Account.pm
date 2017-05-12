package WebService::MyGengo::Account;

use Moose;
use namespace::autoclean;

BEGIN { extends 'WebService::MyGengo::Base' };

=head1 NAME

WebService::MyGengo::Account - An Account in the myGengo system.

=head1 SYNOPSIS

    my $client = WebService::MyGengo::Client->new( $params );
    my $acct = $client->get_account();

    printf "You have %d credits to spend\n", $acct->credits;

=head1 ATTRIBUTES

=head2 credits_spent (Num)

A decimal figure representing the number of myGengo credits this account has
spent.

=cut
has 'credits_spent' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::Num'
    , required  => 1
    , coerce    => 1
    );

=head2 user_since (DateTime)

The date at which this Account was registered with myGengo.

=cut
has 'user_since' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::DateTime'
    , coerce    => 1
    , required  => 1
    );

=head2 credits (Num)

A decimal figure representing the number of credits remaining to be used by
the Account.

=cut
has 'credits' => (
    is          => 'ro'
    , isa       => 'WebService::MyGengo::Num'
    , required  => 1
    , coerce    => 1
    );


__PACKAGE__->meta->make_immutable();
1;

=head2 SEE ALSO

L<http://mygengo.com/api/developer-docs/methods/account-balance-get/>

L<http://mygengo.com/api/developer-docs/methods/account-stats-get/>

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
