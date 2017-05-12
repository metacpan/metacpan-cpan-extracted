package WebService::Buxfer::Utils;

use warnings;
use strict;
use base qw/Exporter/;

our $VERSION = '0.01';
our @EXPORT = qw/inject_accountName make_transactions/;

my $_max_transactions_per_submit = 1000;
sub max_transactions_per_submit {
    my $val = shift;
    $val && !ref($val) and $_max_transactions_per_submit = shift;
    return $_max_transactions_per_submit;
}

sub inject_accountName {
    my ($accounts, $results) = @_;

    return unless ref $results eq 'ARRAY';
    foreach my $r ( @$results ) {
        next unless defined $r->{accountId};
        $r->{accountName} = $accounts->{$r->{accountId}}->{name};
    }
}

sub make_transactions {
    my ($items) = @_;
    my @txns = ();
    my @return = ();

    ref($items) ne 'ARRAY' and $items = [$items];

    map { push @txns, &_to_string($_) } @$items;

    while ( scalar @txns ) {
        push @return,
            join "\n", splice(@txns, 0, &max_transactions_per_submit());
    }

    return wantarray ? @return : \@return;
}

sub _to_string {
    my ($item) = @_;

    # Return pre-stringified items unmolested.
    !ref($item) and return $item;

    my %i = %$item;
    my $str = '';

    $str .= $i{description} . " ";

    $i{amount} !~ /^-/ and $i{amount} = "+".$i{amount};
    $i{amount} =~ s/^-//;
    $str .= $i{amount} . " ";

    $i{payer} and $str .= $i{payer} . " ";

    if ( my $tags = $i{tags} ) {
        $str .= "tags:";

        !ref($tags) and $tags = [$tags];

        foreach my $tag ( @$tags ) {
            $tag =~ /\s/ && $tag !~ /^'.*'$/ and $tag = "'$tag'";
            $str .= $tag.",";
        }
        $str =~ s/,$/ /;
    }

    $i{account} and $str .= 'acct:' . $i{account} . " ";
    $i{date} and $str .= 'date:' . $i{date} . " ";
    $i{status} and $str .= 'status:' . $i{status} . " ";

    if ( my $parts = $i{participants} ) {
        $str .= "@@ ";
        foreach my $part ( @$parts ) {
            !ref($part) and $str .= $part . " ", next;
            $str .= (join ' ', @$part) . " ";
        }
    }

    # `return ($str = $str) =~ s/ $/;/;` doesn't work.
    $str =~ s/ $/;/;
    return $str;
}

1;

__END__

=head1 NAME

WebService::Buxfer::Utils

=head1 DESCRIPTION

Utility methods included with and used by the WebService::Buxfer package.

=head1 ACCESSORS

=head2 max_transactions_per_submit

Maximum number of transactions to include in a single C<add_transaction> call.

Note: The Buxfer API documentation does not indicate a maximum number
of transactions that can be submitted at once. I was able to
sucessfully submit 1000 simple transactions in a single call, hence the
default.

=head1 METHODS

=head2 inject_accountName(\%accounts, \@results)

See the inject_account_name option in the WebService::Buxfer doco.

=head2 make_transactions(\@items)

Given an array of transaction objects (hashrefs) stringifies each object
into Buxfer's SMS format and groups them into batches based on the
max_transactions_per_submit value.

Transaction objects that are already strings are left untouched.

Returns an array of strings suitable for submitting to the Buxfer API.

See the C<add_transactions> method in WebService::Buxfer for an example.

=head1 AUTHORS

Nathaniel Heinrichs E<lt>nheinric@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2009 Nathaniel Heinrichs.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=cut
