package Example::Counter;

use strict;
use warnings;
use Future::AsyncAwait;

async sub initialize {
    my ($context_or)=@_;
    await $context_or->storage()->batch([
        ['CREATE TABLE IF NOT EXISTS counter (id INTEGER PRIMARY KEY, value INTEGER NOT NULL)', undef],
        ['INSERT OR IGNORE INTO counter VALUES (1, 0)', undef],
    ]);
    return;
}

async sub increment {
    my ($context_or, $amount)=@_;
    die "amount must be an integer\n" unless (defined($amount)&&!ref($amount)&&($amount=~/\A-?\d+\z/));
    return await $context_or->storage()->selectrow_hashref(
        'UPDATE counter SET value=value+? WHERE id=1 RETURNING value', undef, 0+$amount,
    );
}

async sub read {
    my ($context_or)=@_;
    return await $context_or->storage()->selectrow_hashref('SELECT value FROM counter WHERE id=1', undef);
}

1;
