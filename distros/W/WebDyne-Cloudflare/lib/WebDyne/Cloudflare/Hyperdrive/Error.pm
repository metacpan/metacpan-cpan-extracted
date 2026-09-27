package WebDyne::Cloudflare::Hyperdrive::Error;

use 5.020;
use strict;
use warnings;
use overload '""' => 'as_string', fallback => 1;

our $VERSION='0.001';

sub new {
    my ($class, %opt)=@_;
    return bless({ %opt }, $class);
}


sub code { return shift()->{'code'}; }
sub sqlstate { return shift()->{'sqlstate'}; }
sub errno { return shift()->{'errno'}; }
sub message { return shift()->{'message'}; }
sub name { return shift()->{'name'}; }
sub outcome_unknown { return shift()->{'outcomeUnknown'}||0; }
sub details { return { %{$_[0]} }; }
sub cause { return shift()->{'cause'}; }
sub cleanup_errors { return [@{$_[0]->{'cleanup_errors'}||[]}]; }


sub with_cleanup {
    my ($class, $primary_ref, $cleanup_ref)=@_;
    require Scalar::Util;
    my $error_or=(Scalar::Util::blessed($primary_ref)&&$primary_ref->isa($class))
        ? $primary_ref : $class->new(name => 'TRANSACTION_ERROR', code => 'CALLBACK_FAILED',
            message => "$primary_ref", cause => $primary_ref);
    push(@{$error_or->{'cleanup_errors'}}, $cleanup_ref);
    return $error_or;
}


sub as_string {
    my ($self)=@_;
    return ($self->{'name'}||'HYPERDRIVE_ERROR') . ' [' .
        ($self->{'code'}||'UNKNOWN') . ']: ' . ($self->{'message'}||'Request failed');
}

1;
