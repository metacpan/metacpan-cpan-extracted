package WebDyne::Cloudflare::Hyperdrive::Statement;

use 5.020;
use strict;
use warnings;
use Future::AsyncAwait;
use JSON::PP ();
use Scalar::Util qw(blessed);
use WebDyne::Cloudflare::Hyperdrive::Codec;
use WebDyne::Cloudflare::Hyperdrive::Blob;

our $VERSION='0.001';

sub new {
    my ($class, %opt)=@_;
    return bless({ database => $opt{'database'}, sql => $opt{'sql'}, bindings => {}, hints => {}, position => 0 }, $class);
}


sub available {
    my ($self)=@_;
    $self->{'database'}->available();
    die "Hyperdrive statement execution is in progress\n" if $self->{'busy'};
}


sub parameter {
    my ($value_ref, $type)=@_;
    if (defined($type)) {
        die "Unsupported Hyperdrive parameter type\n" if ref($type)||($type!~/\A(?:text|boolean|bytea)\z/);
        if (defined($value_ref)) {
            if ($type eq 'bytea') {
                $value_ref=WebDyne::Cloudflare::Hyperdrive::Blob->new($value_ref)
                    unless blessed($value_ref)&&$value_ref->isa('WebDyne::Cloudflare::Hyperdrive::Blob');
            }
            elsif ($type eq 'boolean') {
                die "Hyperdrive boolean requires 0, 1 or a JSON boolean\n"
                    unless JSON::PP::is_bool($value_ref)||(!ref($value_ref)&&($value_ref=~/\A[01]\z/));
                $value_ref=$value_ref ? JSON::PP::true() : JSON::PP::false();
            }
            else { die "Hyperdrive text requires a scalar\n" if ref($value_ref) }
        }
    }
    return WebDyne::Cloudflare::Hyperdrive::Codec::parameters($value_ref)->[0];
}


sub bind_param {
    my ($self, $position, $value_ref, $type)=@_;
    $self->available();
    die "Hyperdrive bind_param requires position, value and optional type\n" unless (@_==3)||(@_==4);
    die "Hyperdrive parameter positions are integers from 1 to 65535\n"
        unless defined($position)&&!ref($position)&&($position=~/\A[1-9][0-9]*\z/)&&($position<=65535);
    my $hint=defined($type) ? $type : $self->{'hints'}{$position};
    $self->{'bindings'}{$position}=parameter($value_ref, $hint);
    $self->{'hints'}{$position}=$hint;
    return 1;
}


sub execute {
    my ($self, @bind)=@_;
    $self->available();
    delete($self->{'result'});
    $self->{'position'}=0;
    if (@bind) {
        die "Hyperdrive accepts at most 65535 parameters\n" if @bind>65535;
        my %bindings;
        foreach my $index (0..$#bind) { $bindings{$index+1}=parameter($bind[$index], $self->{'hints'}{$index+1}) }
        $self->{'bindings'}=\%bindings;
    }
    my @positions=sort { $a<=>$b } keys(%{$self->{'bindings'}});
    die "Hyperdrive bound parameter positions must be contiguous\n" if @positions&&($positions[-1]!=@positions);
    my $params_ar=[map { $self->{'bindings'}{$_} } @positions];
    $self->{'busy'}=1;
    my $future_or=$self->run($params_ar);
    $future_or->on_ready(sub {
        $self->{'busy'}=0;
        delete($self->{'result'}) unless $future_or->is_done();
    });
    return $future_or;
}


async sub run {
    my ($self, $params_ar)=@_;
    my $result_hr=await $self->{'database'}->request('query', sql => $self->{'sql'}, params => $params_ar);
    die "Hyperdrive query omitted row metadata\n" unless (ref($result_hr->{'rows'}) eq 'ARRAY')&&(ref($result_hr->{'columns'}) eq 'ARRAY');
    $self->{'result'}=$result_hr;
    return count_value($result_hr->{'count'});
}


sub rows {
    my ($self)=@_;
    die "Hyperdrive rows takes no arguments\n" unless @_==1;
    $self->available();
    return count_value($self->{'result'} ? $self->{'result'}{'count'} : undef);
}


sub count_value {
    my ($count)=@_;
    return -1 unless defined($count);
    die "Invalid Hyperdrive affected row count\n" if ref($count)||($count!~/\A[0-9]+\z/);
    return $count ? 0+$count : '0E0';
}


sub fetchrow_arrayref {
    my ($self)=@_;
    die "Hyperdrive fetchrow_arrayref takes no arguments\n" unless @_==1;
    $self->available();
    return undef unless $self->{'result'};
    my $row_ar=$self->{'result'}{'rows'}[$self->{'position'}];
    return undef unless defined($row_ar);
    $self->{'position'}++;
    return [@{$row_ar}];
}


sub fetchrow_hashref {
    my ($self)=@_;
    die "Hyperdrive fetchrow_hashref takes no arguments\n" unless @_==1;
    my $row_ar=$self->fetchrow_arrayref();
    return undef unless defined($row_ar);
    my %row;
    my $columns_ar=$self->{'result'}{'columns'};
    foreach my $index (0..$#{$columns_ar}) { $row{$columns_ar->[$index]{'name'}}=$row_ar->[$index] }
    return \%row;
}


sub fetchall_arrayref {
    my ($self, $slice_hr)=@_;
    $self->available();
    die "Hyperdrive fetchall_arrayref accepts only undef or an empty hash\n"
        if (@_>2)||(defined($slice_hr)&&((ref($slice_hr) ne 'HASH')||keys(%{$slice_hr})));
    my @rows;
    while (defined(my $row_ref=defined($slice_hr) ? $self->fetchrow_hashref() : $self->fetchrow_arrayref())) { push(@rows, $row_ref) }
    return \@rows;
}


sub columns {
    my ($self)=@_;
    die "Hyperdrive columns takes no arguments\n" unless @_==1;
    $self->available();
    return [] unless $self->{'result'};
    return [map { { %{$_} } } @{$self->{'result'}{'columns'}}];
}


sub command {
    my ($self)=@_;
    die "Hyperdrive command takes no arguments\n" unless @_==1;
    $self->available();
    return $self->{'result'} ? $self->{'result'}{'command'} : undef;
}


sub insert_id {
    my ($self)=@_;
    die "Hyperdrive insert_id takes no arguments\n" unless @_==1;
    $self->available();
    return $self->{'result'} ? $self->{'result'}{'insert_id'} : undef;
}


sub affected_rows {
    my ($self)=@_;
    die "Hyperdrive affected_rows takes no arguments\n" unless @_==1;
    $self->available();
    return $self->{'result'} ? $self->{'result'}{'affected_rows'} : undef;
}


sub warning_count {
    my ($self)=@_;
    die "Hyperdrive warning_count takes no arguments\n" unless @_==1;
    $self->available();
    return $self->{'result'} ? $self->{'result'}{'warning_count'} : undef;
}


sub finish {
    my ($self)=@_;
    die "Hyperdrive finish takes no arguments\n" unless @_==1;
    $self->available();
    delete($self->{'result'});
    $self->{'position'}=0;
    return 1;
}

1;
