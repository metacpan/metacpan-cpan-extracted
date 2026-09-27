package WebDyne::Cloudflare::Hyperdrive;

use 5.020;
use strict;
use warnings;
use Future::AsyncAwait;
use JSON::PP ();
use Scalar::Util qw(blessed);
use WebDyne::Cloudflare::Hyperdrive::Transport;
use WebDyne::Cloudflare::Hyperdrive::Statement;
use WebDyne::Cloudflare::Hyperdrive::Blob;
use WebDyne::Cloudflare::Hyperdrive::Error;

our $VERSION='0.001';

sub new {
    my ($class, %opt)=@_;
    die "Unknown Hyperdrive constructor option\n" if grep { ($_ ne 'scope')&&($_ ne 'binding') } keys(%opt);
    return bless({ transport => WebDyne::Cloudflare::Hyperdrive::Transport->new(%opt), pending => 0 }, $class);
}


sub root { return $_[0]->{'root'}||$_[0]; }


sub available {
    my ($self)=@_;
    my $root_or=$self->root();
    die "Hyperdrive connection is disconnected\n" if $root_or->{'closed'}||$root_or->{'closing'};
    die "Hyperdrive connection was cancelled or cleanup failed; disconnect it\n" if $root_or->{'cancelled'};
    die "Hyperdrive transaction handle has expired\n" if $self->{'root'}&&!$self->{'active'};
    die "Hyperdrive connection belongs to a transaction callback\n" if !$self->{'root'}&&$root_or->{'managed'};
    return 1;
}


sub attributes {
    my ($attr_hr, $slice_fg)=@_;
    return 0 unless defined($attr_hr);
    die "Hyperdrive attributes must be a hash or undef\n" unless ref($attr_hr) eq 'HASH';
    die "Unsupported Hyperdrive attribute\n" if grep { !$slice_fg||($_ ne 'Slice') } keys(%{$attr_hr});
    return 0 unless exists($attr_hr->{'Slice'});
    die "Hyperdrive Slice must be an empty hash\n" unless (ref($attr_hr->{'Slice'}) eq 'HASH')&&!keys(%{$attr_hr->{'Slice'}});
    return 1;
}


sub blob {
    shift() if (@_>1)&&defined($_[0])&&(blessed($_[0])||($_[0] eq __PACKAGE__));
    die "Hyperdrive blob requires exactly one byte string\n" unless @_==1;
    return WebDyne::Cloudflare::Hyperdrive::Blob->new($_[0]);
}


sub prepare {
    my ($self, $sql, $attr_hr)=@_;
    $self->available();
    die "Hyperdrive prepare takes SQL and optional attributes\n" if @_>3;
    attributes($attr_hr, 0);
    die "Hyperdrive SQL must be a non-empty string\n" unless defined($sql)&&!ref($sql)&&($sql=~/\S/)&&index($sql, "\0")<0;
    return WebDyne::Cloudflare::Hyperdrive::Statement->new(database => $self, sql => $sql);
}


async sub selectrow_arrayref {
    my ($self, $sql, $attr_hr, @bind)=@_;
    my $statement_or=$self->prepare($sql, $attr_hr);
    await $statement_or->execute(@bind);
    return $statement_or->fetchrow_arrayref();
}


async sub selectrow_hashref {
    my ($self, $sql, $attr_hr, @bind)=@_;
    my $statement_or=$self->prepare($sql, $attr_hr);
    await $statement_or->execute(@bind);
    return $statement_or->fetchrow_hashref();
}


async sub selectall_arrayref {
    my ($self, $sql, $attr_hr, @bind)=@_;
    my $slice_fg=attributes($attr_hr, 1);
    my $statement_or=$self->prepare($sql);
    await $statement_or->execute(@bind);
    return $statement_or->fetchall_arrayref($slice_fg ? {} : undef);
}


async sub do {
    my ($self, $sql, $attr_hr, @bind)=@_;
    return await $self->prepare($sql, $attr_hr)->execute(@bind);
}


sub request {
    my ($self, $operation, %opt)=@_;
    $self->{'pending'}++;
    my $future_or=$self->send_request($operation, %opt);
    #  Retain the operation until bookkeeping runs, including cancellation.
    #
    $future_or->on_ready(sub {
        $self->{'pending'}--;
        $self->root()->{'cancelled'}=1 if $future_or->is_cancelled();
    });
    return $future_or;
}


async sub send_request {
    my ($self, $operation, %opt)=@_;
    my $root_or=$self->root();
    if (!$root_or->{'connection'}) {
        $root_or->{'opening'}=$root_or->{'transport'}->call('open') unless $root_or->{'opening'};
        my $opened_hr=await $root_or->{'opening'}->without_cancel();
        die "Hyperdrive host omitted connection identity\n" unless defined($opened_hr->{'connection'})&&!ref($opened_hr->{'connection'})&&length($opened_hr->{'connection'});
        $root_or->{'connection'}=$opened_hr->{'connection'};
    }
    die "Hyperdrive transaction handle has expired\n" if $self->{'root'}&&!$self->{'active'};
    $opt{'owner'}=$self->{'owner'} if $self->{'root'};
    return await $root_or->{'transport'}->call($operation, connection => $root_or->{'connection'}, %opt);
}


sub control_allowed {
    my ($self)=@_;
    die "Explicit transaction control is unavailable inside a callback\n" if $self->{'root'};
    $self->available();
}


async sub begin_work {
    my ($self)=@_;
    $self->control_allowed();
    die "Hyperdrive begin_work takes no arguments\n" unless @_==1;
    await $self->request('begin', managed => JSON::PP::false());
    $self->{'transaction'}=1;
    return 1;
}


async sub commit {
    my ($self)=@_;
    $self->control_allowed();
    die "Hyperdrive commit takes no arguments\n" unless @_==1;
    await $self->request('commit');
    $self->{'transaction'}=0;
    return 1;
}


async sub rollback {
    my ($self)=@_;
    $self->control_allowed();
    die "Hyperdrive rollback takes no arguments\n" unless @_==1;
    await $self->request('rollback');
    $self->{'transaction'}=0;
    return 1;
}


sub transaction {
    my ($self, $callback_cr)=@_;
    $self->control_allowed();
    die "Hyperdrive transaction requires one callback\n" unless (@_==2)&&(ref($callback_cr) eq 'CODE');
    die "Nested Hyperdrive transactions are unsupported\n" if $self->{'transaction'};
    die "Await earlier Hyperdrive operations before starting a transaction callback\n" if $self->{'pending'};
    $self->{'managed'}=1;
    my $facade_or=bless({ root => $self, active => 1, pending => 0 }, ref($self));
    my $future_or=$self->run_transaction($callback_cr, $facade_or);
    $future_or->on_ready(sub {
        $facade_or->{'active'}=0;
        $self->{'managed'}=0;
        $self->{'cancelled'}=1 if $future_or->is_cancelled();
    });
    return $future_or;
}


async sub run_transaction {
    my ($self, $callback_cr, $facade_or)=@_;
    my $begun_hr=await $self->request('begin', managed => JSON::PP::true());
    die "Hyperdrive host omitted transaction ownership\n" unless defined($begun_hr->{'owner'})&&!ref($begun_hr->{'owner'})&&length($begun_hr->{'owner'});
    $facade_or->{'owner'}=$begun_hr->{'owner'};
    $self->{'owner'}=$begun_hr->{'owner'};
    $self->{'transaction'}=1;
    my $value_ref;
    my $ok_fg=eval {
        my $callback_or=$callback_cr->($facade_or);
        die "Hyperdrive transaction callback must return a Future\n" unless blessed($callback_or)&&$callback_or->isa('Future');
        $value_ref=await $callback_or;
        die "Hyperdrive transaction callback left unfinished operations\n" if $facade_or->{'pending'};
        1;
    };
    my $error_ref=$@;
    $facade_or->{'active'}=0;
    if ($ok_fg) {
        $ok_fg=eval { await $self->request('commit', owner => $facade_or->{'owner'}); 1 };
        $error_ref=$@;
        $self->{'transaction'}=0 if $ok_fg;
        delete($self->{'owner'}) if $ok_fg;
    }
    if (!$ok_fg) {
        unless (blessed($error_ref)&&$error_ref->isa('WebDyne::Cloudflare::Hyperdrive::Error')&&$error_ref->outcome_unknown()) {
            my $rolled_fg=eval { await $self->request('rollback', owner => $facade_or->{'owner'}); 1 };
            my $cleanup_ref=$@;
            if ($rolled_fg) { $self->{'transaction'}=0; delete($self->{'owner'}) }
            else {
                $self->{'cancelled'}=1;
                $error_ref=WebDyne::Cloudflare::Hyperdrive::Error->with_cleanup($error_ref, $cleanup_ref);
            }
        }
        $self->{'cancelled'}=1 if $self->{'transaction'};
        die $error_ref;
    }
    return $value_ref;
}


sub disconnect {
    my ($self)=@_;
    die "Disconnect is unavailable inside a transaction callback\n" if $self->{'root'}||$self->{'managed'};
    die "Hyperdrive disconnect takes no arguments\n" unless @_==1;
    return $self->{'disconnecting'} if $self->{'disconnecting'};
    $self->{'closing'}=1;
    my $future_or=$self->close_connection();
    $self->{'disconnecting'}=$future_or;
    $future_or->on_ready(sub { $self->{'closed'}=1; $self->{'transaction'}=0; });
    return $future_or;
}


async sub close_connection {
    my ($self)=@_;
    if ($self->{'connection'}||$self->{'opening'}) {
        await $self->request('disconnect', (defined($self->{'owner'}) ? (owner => $self->{'owner'}) : ()));
    }
    return 1;
}

1;
