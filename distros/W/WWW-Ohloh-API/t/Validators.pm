#package WWW::Ohloh::API::Validators;

use strict;
use warnings;

#use Exporter;
#use base qw/ Exporter /;

#our @EXPORT = qw/ validate_stack /;

sub validate_stack {
    my $stack = shift;

    isa_ok $stack, 'WWW::Ohloh::API::Stack';

    like $stack->id,            qr/^\d+$/;
    isa_ok $stack->updated_at,  'Time::Piece';
    like $stack->project_count, qr/^\d+$/;
    like $stack->account_id,    qr/^\d+$/;

    if ( my $account = $stack->account(0) ) {
        isa_ok $account, 'WWW::Ohloh::API::Account';
    }

    validate_stack_entry($_) for $stack->stack_entries;
}

sub validate_stack_entry {
    my $entry = shift;

    isa_ok $entry, 'WWW::Ohloh::API::StackEntry';

    like $entry->id,         qr/^\d+$/;
    like $entry->created_at, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;
    like $entry->stack_id,   qr/^\d+$/;
    like $entry->project_id, qr/^\d+$/;

    if ( my $project = $entry->project(0) ) {
        validate_project($project);
    }

    like $entry->as_xml, qr#<stack_entry>.*</stack_entry>#, 'as_xml()';

}

'end of WWW::Ohloh::API::Validators';
