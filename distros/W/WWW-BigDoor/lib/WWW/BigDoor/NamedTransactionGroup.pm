package WWW::BigDoor::NamedTransactionGroup;

use strict;
use warnings;

use Carp;
#use Smart::Comments -ENV;

use base qw(WWW::BigDoor::Resource Class::Accessor);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
    qw(id read_only end_user_cap end_user_cap_interval non_secure challenge_response_enabled urls named_transactions)
);

sub execute_transaction {
    my ( $self, $end_user_login, $payload, $client ) = @_;

    unless ( defined $self->get_id ) {
        croak 'TransactionGroup should have ID - save before execution';
    }
    my $ep = $self->_end_point;

    my $result = $client->POST( sprintf( '%s/%s/execute/%s', $ep, $self->get_id, $end_user_login ),
        {format => 'json'}, $payload );
    return $result;
}

1;
__END__

=head1 NAME

WWW::BigDoor::NamedTransactionGroup - NamedTransactionGroup Resource Object for BigDoor API

=head1 VERSION

This document describes BigDoor version 0.1.1

=head1 SYNOPSIS
    use WWW::BigDoor;
    use WWW::BigDoor::NamedTransactionGroup;
    use WWW::BigDoor::NamedTransaction;

    my $transaction_group_payload = {
        pub_title             => 'Test Transaction Group',
        pub_description       => 'test description',
        end_user_title        => 'end user title',
        end_user_description  => 'end user description',
        end_user_cap          => '-1',
        end_user_cap_interval => '-1',
    };
    my $transaction_group_obj = new WWW::BigDoor::NamedTransactionGroup( $transaction_group_payload );
    $transaction_group_obj->save( $client );

    my $named_transaction_payload = {
        pub_title            => 'Test Transaction',
        pub_description      => 'test description',
        end_user_title       => 'end user title',
        end_user_description => 'end user description',
        currency_id          => $currency_obj->get_id,
        amount               => '50',
        default_amount       => '50',
    };

    my $named_transaction_obj = new WWW::BigDoor::NamedTransaction( $named_transaction_payload );
    $named_transaction_obj->save( $client );

    $response = $transaction_group_obj->execute_transaction( $username, {verbosity => '6'}, $client );
  
=head1 DESCRIPTION

This module provides object corresponding to BigDoor API /named_transaction_group end point.
For description see online documentation L<http://publisher.bigdoor.com/docs/>

=head1 INTERFACE 

Most of methods  are provided by base WWW::BigDoor::Resource object

=head3 execute_transaction( $end_user_login, $payload, $client)

=over 4

=item $end_user_login

The string representing end user login.

=item $payload

See L<http://publisher.bigdoor.com/docs/params/specific> for possible parameters

=item $client

WWW::BigDoor object.

=back

=head1 DIAGNOSTICS

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back

=head1 CONFIGURATION AND ENVIRONMENT

WWW:BigDoor::NamedTransactionGroup requires no configuration files or environment variables.

=head1 DEPENDENCIES

WWW::BigDoor::Resource, WWW::BigDoor

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-bigdoor@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

WWW::BigDoor::Resource for base class description, WWW::BigDoor for procedural
interface for BigDoor REST API

=head1 AUTHOR

Alex L. Demidov  C<< <alexeydemidov@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

BigDoor Open License
Copyright (c) 2010 BigDoor Media, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to
do so, subject to the following conditions:

- This copyright notice and all listed conditions and disclaimers shall
be included in all copies and portions of the Software including any
redistributions in binary form.

- The Software connects with the BigDoor API (api.bigdoor.com) and
all uses, copies, modifications, derivative works, mergers, publications,
distributions, sublicenses and sales shall also connect to the BigDoor API and
shall not be used to connect with any API, software or service that competes
with BigDoor's API, software and services.

- Except as contained in this notice, this license does not grant you rights to
use BigDoor Media, Inc. or any contributors' name, logo, or trademarks.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
