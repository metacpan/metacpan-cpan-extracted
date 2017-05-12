package WebService::Saasu;

use Modern::Perl;
use Mouse;

# ABSTRACT: WebService::Saasu - an interface to saasu.com's RESTful accounting API using Web::API

our $VERSION = '0.5'; # VERSION

use XML::Simple;
with 'Web::API';


has 'commands' => (
    is      => 'rw',
    default => sub {
        {
            # invoices
            list_invoices => {
                path      => 'InvoiceList',
                mandatory => ['transactionType'],
            },
            get_invoice => {
                path      => 'Invoice',
                mandatory => ['uid'],
            },
            create_invoice => {
                path    => 'Tasks',
                method  => 'POST',
                wrapper => [ 'tasks', 'insertInvoice', 'invoice' ],
                mandatory =>
                    [ 'transactionType', 'date', 'layout', 'invoiceItems' ],
            },
            update_invoice => {
                path      => 'Tasks',
                method    => 'POST',
                wrapper   => [ 'tasks', 'updateInvoice', 'invoice' ],
                mandatory => [
                    'uid',              'lastUpdatedUid',
                    'transactionType', 'date',
                    'layout',          'invoiceItems'
                ],
            },
            delete_invoice => {
                path      => 'Invoice',
                method    => 'DELETE',
                mandatory => ['uid'],
            },

            # payments
            list_payments => {
                path      => 'InvoicePaymentList',
                mandatory => ['transactionType'],
            },
            get_payment => {
                path      => 'InvoicePayment',
                mandatory => ['uid'],
            },
            create_payment => {
                path   => 'Tasks',
                method => 'POST',
                wrapper =>
                    [ 'tasks', 'insertInvoicePayment', 'invoicePayment' ],
                mandatory =>
                    [ 'transactionType', 'date', 'invoicePaymentItems' ],
            },
            update_payment => {
                path   => 'Tasks',
                method => 'POST',
                wrapper =>
                    [ 'tasks', 'updateInvoicePayment', 'invoicePayment' ],
                mandatory => [
                    'uid',              'lastUpdatedUid',
                    'transactionType', 'date',
                    'invoicePaymentItems'
                ],
            },
            delete_payment => {
                path      => 'InvoicePayment',
                method    => 'DELETE',
                mandatory => ['uid'],
            },

            # contacts
            list_contacts => { path => 'ContactList' },
            get_contact   => {
                path      => 'Contact',
                mandatory => ['uid'],
            },
            create_contact => {
                path    => 'Tasks',
                method  => 'POST',
                wrapper => [ 'tasks', 'insertContact', 'contact' ],
            },
            update_contact => {
                path    => 'Tasks',
                method  => 'POST',
                wrapper => [ 'tasks', 'updateContact', 'contact' ],
                mandatory => [ 'uid', 'lastUpdatedUid' ],
            },
            delete_contact => {
                path      => 'Contact',
                method    => 'DELETE',
                mandatory => ['uid'],
            },

            # chart of accounts
            list_accounts => { path => 'TransactionCategoryList' },
            get_account   => {
                path      => 'TransactionCategory',
                mandatory => ['uid'],
            },
            create_account => {
                path    => 'Tasks',
                method  => 'POST',
                wrapper => [
                    'tasks', 'insertTransactionCategory',
                    'transactionCategory'
                ],
                mandatory => [ 'type', 'name' ],
            },
            update_account => {
                path    => 'Tasks',
                method  => 'POST',
                wrapper => [
                    'tasks', 'updateTransactionCategory',
                    'transactionCategory'
                ],
                mandatory => [ 'uid', 'lastUpdatedUid', 'type', 'name' ],
            },
            delete_account => {
                path      => 'TransactionCategory',
                method    => 'DELETE',
                mandatory => ['uid'],
            },

            # bank accounts
            list_bank_accounts => { path => 'BankAccountList' },
            get_bank_account   => {
                path      => 'BankAccount',
                mandatory => ['uid'],
            },
            create_bank_account => {
                path    => 'Tasks',
                method  => 'POST',
                wrapper => [ 'tasks', 'insertBankAccount', 'bankAccount' ],
                mandatory => [ 'type', 'displayName' ],
            },
            update_bank_account => {
                path      => 'Tasks',
                method    => 'POST',
                wrapper   => [ 'tasks', 'updateBankAccount', 'bankAccount' ],
                mandatory => [ 'uid', 'lastUpdatedUid', 'type', 'displayName' ],
            },
            delete_bank_account => {
                path      => 'BankAccount',
                method    => 'DELETE',
                mandatory => ['uid'],
            },

            # inventory items
            list_items => { path => 'FullInventoryItemList' },
            get_item   => {
                path      => 'InventoryItem',
                mandatory => ['uid'],
            },
            create_item => {
                path    => 'Tasks',
                method  => 'POST',
                wrapper => [ 'tasks', 'insertInventoryItem', 'inventoryItem' ],
                mandatory => [ 'code', 'description' ],
            },
            update_item => {
                path    => 'Tasks',
                method  => 'POST',
                wrapper => [ 'tasks', 'updateInventoryItem', 'inventoryItem' ],
                mandatory => [ 'uid', 'lastUpdatedUid', 'code', 'description' ],
            },
            delete_item => {
                path      => 'InventoryItem',
                method    => 'DELETE',
                mandatory => ['uid'],
            },

            # inventory adjustments
            list_adjustments => { path => 'InventoryAdjustmentList' },
            get_adjustment   => {
                path      => 'InventoryAdjustment',
                mandatory => ['uid'],
            },
            create_adjustment => {
                path    => 'Tasks',
                method  => 'POST',
                wrapper => [
                    'tasks', 'insertInventoryAdjustment',
                    'inventoryAdjustment'
                ],
                mandatory => ['items'],
            },
            update_adjustment => {
                path    => 'Tasks',
                method  => 'POST',
                wrapper => [
                    'tasks', 'updateInventoryAdjustment',
                    'InventoryAdjustment'
                ],
                mandatory => [ 'uid', 'lastUpdatedUid', 'items' ],
            },
            delete_adjustment => {
                path      => 'InventoryAdjustment',
                method    => 'DELETE',
                mandatory => ['uid'],
            },

            # combo items
            list_comboitems => { path => 'FullComboItemList' },
            get_comboitem   => {
                path      => 'ComboItem',
                mandatory => ['uid'],
            },
            create_comboitem => {
                path      => 'Tasks',
                method    => 'POST',
                wrapper   => [ 'tasks', 'insertComboItem', 'comboItem' ],
                mandatory => [ 'code', 'description', 'items' ],
            },
            update_comboitem => {
                path    => 'Tasks',
                method  => 'POST',
                wrapper => [ 'tasks', 'updateComboItem', 'comboItem' ],
                mandatory =>
                    [ 'uid', 'lastUpdatedUid', 'code', 'description', 'items' ],
            },
            delete_comboitem => {
                path      => 'ComboItem',
                method    => 'DELETE',
                mandatory => ['uid'],
            },

            # inventory transfers
            list_transfers => { path => 'InventoryTransferList' },
            get_transfer   => {
                path      => 'InventoryTransfer',
                mandatory => ['uid'],
            },
            create_transfer => {
                path   => 'Tasks',
                method => 'POST',
                wrapper =>
                    [ 'tasks', 'insertInventoryTransfer', 'inventoryTransfer' ],
                mandatory => ['items'],
            },
            update_transfer => {
                path   => 'Tasks',
                method => 'POST',
                wrapper =>
                    [ 'tasks', 'updateInventoryTransfer', 'inventoryTransfer' ],
                mandatory => [ 'uid', 'lastUpdatedUid', 'items' ],
            },
            delete_transfer => {
                path      => 'InventoryTransfer',
                method    => 'DELETE',
                mandatory => ['uid'],
            },

            # journal
            list_journals => { path => 'JournalList' },
            get_journal   => {
                path      => 'Journal',
                mandatory => ['uid'],
            },
            create_journal => {
                path      => 'Tasks',
                method    => 'POST',
                wrapper   => [ 'tasks', 'insertJournal', 'journal' ],
                mandatory => ['journalItems'],
            },
            update_journal => {
                path      => 'Tasks',
                method    => 'POST',
                wrapper   => [ 'tasks', 'updateJournal', 'journal' ],
                mandatory => [ 'uid', 'lastUpdatedUid', 'journalItems' ],
            },
            delete_journal => {
                path      => 'Journal',
                method    => 'DELETE',
                mandatory => ['uid'],
            },

            # activities
            list_activities => { path => 'ActivityList' },
            get_activity    => { path => 'Activity' },
            create_activity => {
                method  => 'POST',
                path    => 'Tasks',
                wrapper => [ 'tasks', 'insertActivity', 'activity' ],
                mandatory => [ 'type', 'title' ],
            },
            update_activity => {
                method    => 'POST',
                path      => 'Tasks',
                wrapper   => [ 'tasks', 'updateActivity', 'activity' ],
                mandatory => [ 'uid', 'lastUpdatedUid', 'type', 'title' ],
            },
            delete_activity => {
                path      => 'Activity',
                method    => 'DELETE',
                mandatory => ['uid'],
            },

            # reports
            contact_statement_report => {
                path      => 'contactstatementreport',
                mandatory => [ 'contactuid', 'datefrom', 'dateto' ],
            },

            # tax codes
            list_tax_codes => { path => 'TaxCodeList' },

            # tags
            list_tags => { path => 'TagList' },

            # deleted entities
            list_deleted => { path => 'DeletedEntityList' },

        };
    },
);

sub commands {
    my ($self) = @_;
    return $self->commands;
}


sub BUILD {
    my ($self) = @_;

    $self->user_agent(__PACKAGE__ . ' ' . $WebService::Saasu::VERSION);
    $self->content_type('application/xml');
    $self->base_url('https://secure.saasu.com/webservices/rest/r1');
    $self->auth_type('get_params');
    $self->mapping({
        user    => 'FileUid',
        api_key => 'wsaccesskey',
        id      => 'uid',
    });
    $self->xml(
        XML::Simple->new(
            ContentKey => '-content',
            NoAttr     => 1,
            KeepRoot   => 1,
            KeyAttr    => ['layout'],
        ),
    );
    $self->retry_http_codes([500]);

    return $self;
}


1;    # End of WebService::Saasu

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Saasu - WebService::Saasu - an interface to saasu.com's RESTful accounting API using Web::API

=head1 VERSION

version 0.5

=head1 SYNOPSIS

Please refer to the API documentation at L<http://mandrillapp.com/api/docs/index.html>

    use WebService::Saasu;

    my $foo = WebService::Saasu->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 BUILD

basic configuration for the client API happens usually in the BUILD method when using Web::API

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/nupfel/WebService-Saasu/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Saasu

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/nupfel/WebService-Saasu>

=item * MetaCPAN

L<https://metacpan.org/module/WebService::Saasu>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService::Saasu>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService::Saasu>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Lenz Gschwendtner (@norbu09), for being an awesome mentor and friend.

=back

=head1 AUTHOR

Tobias Kirschstein <lev@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Tobias Kirschstein.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
