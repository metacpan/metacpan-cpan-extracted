package WSST::Schema;

use strict;
use Storable qw(dclone);

use WSST::Schema::Data;

our $VERSION = '0.1.1';

sub new {
    my $class = shift;
    my $data = shift || {};
    my $self = {
        lang => $ENV{WSST_LANG},
        data => WSST::Schema::Data->new($data),
    };
    bless($self, $class);
    $self->_update_lang() if $self->{lang};
    return $self;
}

sub clone_data {
    my $self = shift;
    return dclone($self->data);
}

sub data {
    my $self = shift;
    return $self->{data};
}

sub lang {
    my $self = shift;
    if (@_) {
        $self->{lang} = shift;
        $self->_update_lang();
    }
    return $self->{lang};
}

sub _update_lang {
    my $self = shift;
    
    my $lang = $self->{lang} || "default";
    my $hash_list = [$self->{data}];
    
    while (my $hash = shift(@$hash_list)) {
        foreach my $key (keys %$hash) {
            next if $key =~ /_m17n$/;
            my $key_m17n = $key . "_m17n";
            if ($hash->{$key_m17n} && ref($hash->{$key_m17n}) eq 'HASH') {
                $hash->{$key_m17n}->{default} = $hash->{$key}
                    unless exists $hash->{$key_m17n}->{default};
                $hash->{$key} = $hash->{$key_m17n}->{$lang};
                next;
            }
            if (ref($hash->{$key}) eq 'HASH') {
                push(@$hash_list, $hash->{$key});
                next;
            }
            if (ref($hash->{$key}) eq 'ARRAY') {
                foreach my $val (@{$hash->{$key}}) {
                    push(@$hash_list, $val)
                        if ref($val) eq 'HASH';
                }
            }
        }
    }
}

=head1 NAME

WSST::Schema - Schema class of WSST

=head1 DESCRIPTION

Schema is container class of parsed schema data.

=head1 METHODS

=head2 new

Constructor.

=head2 clone_data

Returns schema data which copied deeply.

=head2 data

Returns schema data.

=head2 lang

Accessor method for lang value.

=head1 SEE ALSO

http://code.google.com/p/wsst/

=head1 AUTHORS

Mitsuhisa Oshikawa <mitsuhisa [at] gmail.com>
Yusuke Kawasaki <u-suke [at] kawa.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 WSS Project Team

=cut
1;
