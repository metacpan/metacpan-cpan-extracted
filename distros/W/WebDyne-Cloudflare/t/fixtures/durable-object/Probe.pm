package Example::Probe;

use strict;
use warnings;
use Future::AsyncAwait;
use Future::IO;
use WebDyne::Cloudflare::DurableObject;
use WebDyne::Cloudflare::DurableObject::Error;
our $STALE;
our $STARTS=0;

async sub initialize {
    my ($context_or)=@_;
    $STARTS++;
    await $context_or->batch([
        ['CREATE TABLE IF NOT EXISTS counter(id INTEGER PRIMARY KEY, value INTEGER)', undef],
        ['INSERT OR IGNORE INTO counter VALUES (1,0)', undef],
    ]);
    return;
}
async sub increment {
    my ($context_or, $amount)=@_;
    return await $context_or->selectrow_hashref('UPDATE counter SET value=value+? RETURNING value', undef, $amount);
}
async sub read {
    my ($context_or)=@_;
    my $row_hr=await $context_or->selectrow_hashref('SELECT value FROM counter', undef);
    return {%{$row_hr}, id => $context_or->id(), starts => $STARTS};
}
sub echo {
    my ($context_or, $value_ref)=@_;
    return $value_ref;
}
async sub rollback {
    my ($context_or)=@_;
    await $context_or->batch([
        ['UPDATE counter SET value=999', undef],
        ['INSERT INTO missing_table VALUES (1)', undef],
    ]);
    return;
}
sub remember { $STALE=shift(); return 1; }
async sub stale { return await $STALE->do('UPDATE counter SET value=999', undef); }
async sub cycle {
    my ($context_or, $names_ar)=@_;
    my $namespace_or=WebDyne::Cloudflare::DurableObject->new(scope => $context_or->scope(), binding => 'COUNTERS');
    my $next=shift(@{$names_ar});
    my $stub_or=await $namespace_or->get_by_name($next);
    return await $stub_or->call('cycle', $names_ar);
}
async sub delay {
    my ($context_or)=@_;
    my $before_hr=await $context_or->selectrow_hashref('SELECT value FROM counter', undef);
    await Future::IO->sleep(0.05);
    return await $context_or->selectrow_hashref('UPDATE counter SET value=? RETURNING value', undef, $before_hr->{'value'}+1);
}
sub failure {
    die WebDyne::Cloudflare::DurableObject::Error->new(name => 'PROBE', message => 'expected failure', code => 'E_PROBE');
}
1;
