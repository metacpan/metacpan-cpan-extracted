package UUID::Object;

use strict;
use warnings;
use 5.006;

our $VERSION = '0.81';

use Exporter;
*import = \&Exporter::import;

our @EXPORT = qw(
    uuid_nil
    uuid_ns_dns
    uuid_ns_url
    uuid_ns_oid
    uuid_ns_x500
);

use POSIX qw( floor );
use MIME::Base64;
use Carp;

use overload (
    q{""}  => sub { $_[0]->as_string },
    q{<=>} => \&_compare,
    q{cmp} => \&_compare,
    fallback => 1,
);

sub _compare {
    my ($a, $b) = @_;
    local $@;

    if (eval { $b->isa(__PACKAGE__) }) {
        return $$a cmp $$b;
    }

    # compare with bare string
    if (! ref $b) {
        eval {
            $b = __PACKAGE__->create_from_string($b);
        };
        if (! $@) {
            return $$a cmp $$b;
        }
    }

    return -1;
}

sub clone {
    my $self = shift;

    my $data = $$self;
    my $result = \$data;
    return bless $result, ref $self;
}

sub create_nil {
    my ($class) = @_;
    $class = ref $class if ref $class;

    my $data = chr(0) x 16;
    my $self = \$data;

    return bless $self, $class;
}

sub create {
    my $class = shift;
    my $self = $class->create_nil();
    $self->assign(@_);
    return $self;
}
*new = *create;

sub create_from_binary {
    my ($class, $arg) = @_;
    my $self = \$arg;
    return bless $self, $class;
}

sub create_from_binary_np {
    my $class = shift;
    my $self = $class->create_nil();
    $self->assign_with_binary_np(@_);
    return $self;
}

sub create_from_hex {
    my $class = shift;
    my $self = $class->create_nil();
    $self->assign_with_hex(@_);
    return $self;
}

sub create_from_string {
    my $class = shift;
    my $self = $class->create_nil();
    $self->assign_with_string(@_);
    return $self;
}

sub create_from_base64 {
    my $class = shift;
    my $self = $class->create_nil();
    $self->assign_with_base64(@_);
    return $self;
}

sub create_from_base64_np {
    my $class = shift;
    my $self = $class->create_nil();
    $self->assign_with_base64_np(@_);
    return $self;
}

sub create_from_hash {
    my $class = shift;
    my $self = $class->create_nil();
    $self->assign_with_hash(@_);
    return $self;
}

sub assign {
    my $self = shift;
    my $arg  = shift;

    if (! defined $arg) {
        $self->assign_with_object($self->create_nil);
    }
    elsif (eval { $arg->isa(ref $self) }) {
        $self->assign_with_object($arg);
    }
    elsif (! ref $arg && ! @_) {
        if (length $arg == 16) {
            $self->assign_with_binary($arg);
        }
        elsif ($arg =~ m{ \A [0-9a-f]{32} \z }ixmso) {
            $self->assign_with_hex($arg);
        }
        elsif ($arg =~ m{ \A [0-9a-f]{8} (?: - [0-9a-f]{4} ){3}
                                             - [0-9a-f]{12} \z }ixmso) {
            $self->assign_with_string($arg);
        }
        elsif ($arg =~ m{ \A [+/0-9A-Za-z]{22} == \z }xmso) {
            $self->assign_with_base64($arg);
        }
        else {
            croak "invalid format";
        }
    }
    else {
        unshift @_, $arg;
        $self->assign_with_hash(@_);
    }

    return $self;
}

sub assign_with_object {
    my ($self, $arg) = @_;

    if (! eval { $arg->isa(ref $self) }) {
        croak "argument must be UUID::Object";
    }

    $$self = $$arg;

    return $self;
}

sub assign_with_binary {
    my ($self, $arg) = @_;

    $$self = q{} . $arg;

    return $self;
}

sub assign_with_binary_np {
    my ($self, $arg) = @_;

    substr $arg, 0, 4,
           pack('N', unpack('I', substr($arg, 0, 4)));

    substr $arg, 4, 2,
           pack('n', unpack('S', substr($arg, 4, 2)));

    substr $arg, 6, 2,
           pack('n', unpack('S', substr($arg, 6, 2)));

    $$self = q{} . $arg;

    return $self;
}

sub assign_with_hex {
    my ($self, $arg) = @_;

    if ($arg !~ m{ \A [0-9a-f]{32} \z }ixmso) {
        croak "invalid format";
    }

    return $self->assign_with_binary(pack 'H*', $arg);
}

sub assign_with_string {
    my ($self, $arg) = @_;

    $arg =~ tr{-}{}d;

    return $self->assign_with_hex($arg);
}

sub assign_with_base64 {
    my ($self, $arg) = @_;

    if ($arg !~ m{ \A [+/0-9A-Za-z]{22} == \z }xmso) {
        croak "invalid format";
    }

    return $self->assign_with_binary(decode_base64($arg));
}

sub assign_with_base64_np {
    my ($self, $arg) = @_;

    if ($arg !~ m{ \A [+/0-9A-Za-z]{22} == \z }xmso) {
        croak "invalid format";
    }

    return $self->assign_with_binary_np(decode_base64($arg));
}

sub assign_with_hash {
    my $self = shift;
    my $arg  = @_ && ref $_[0] eq 'HASH' ? shift : { @_ };

    if (my $variant = delete $arg->{variant}) {
        $self->variant($variant);
    }

    foreach my $key (qw( version
                         time time_low time_mid time_hi
                         clk_seq node              )) {
        if (exists $arg->{$key}) {
            $self->$key($arg->{$key});
        }
    }

    return $self;
}

sub as_binary {
    return ${$_[0]};
}

sub as_binary_np {
    my $self = shift;

    my $r = $self->as_binary;

    substr $r, 0, 4,
           pack('I', unpack('N', substr($r, 0, 4)));

    substr $r, 4, 2,
           pack('S', unpack('n', substr($r, 4, 2)));

    substr $r, 6, 2,
           pack('S', unpack('n', substr($r, 6, 2)));

    return $r;
}

sub as_hex {
    return scalar unpack 'H*', ${$_[0]};
}

sub as_string {
    my $u = $_[0]->as_binary;
    return join q{-}, map { unpack 'H*', $_ }
                      map { substr $u, 0, $_, q{} }
                          ( 4, 2, 2, 2, 6 );
}

sub as_base64 {
    my $r = encode_base64(${$_[0]});

    $r =~ s{\s+}{}gxmso;

    return $r;
}

sub as_base64_np {
    my $data = ${$_[0]};

    substr $data, 0, 4,
           pack('I', unpack('N', substr($data, 0, 4)));

    substr $data, 4, 2,
           pack('S', unpack('n', substr($data, 4, 2)));

    substr $data, 6, 2,
           pack('S', unpack('n', substr($data, 6, 2)));

    my $r = encode_base64($data);
    $r =~ s{\s+}{}gxmso;

    return $r;
}

sub as_hash {
    my $self = shift;

    my $r = {};
    foreach my $key (qw( variant version
                         time_low time_mid time_hi
                         clk_seq node              )) {
        $r->{$key} = $self->$key();
    }

    return $r;
}

sub as_urn {
    my $self = shift;

    return 'urn:uuid:' . $self->as_string;
}

sub variant {
    my $self = shift;

    if (@_) {
        my $var = shift;

        if ($var !~ m{^\d+$}o || ! grep { $var == $_ } qw( 0 2 6 7  4 )) {
            croak "invalid parameter";
        }
        $var = 2  if $var == 4;

        if ($var == 0) {
            substr $$self, 8, 1,
                   chr(ord(substr $$self, 8, 1) & 0x7f);
        }
        elsif ($var < 3) {
            substr $$self, 8, 1,
                   chr(ord(substr $$self, 8, 1) & 0x3f | $var << 6);
        }
        else {
            substr $$self, 8, 1,
                   chr(ord(substr $$self, 8, 1) & 0x1f | $var << 5);
        }

        return $var;
    }

    my $var = (ord(substr $$self, 8, 1) & 0xe0) >> 5;

    my %varmap = ( 1 => 0, 2 => 0, 3 => 0, 4 => 2, 5 => 2, );
    if (exists $varmap{$var}) {
        $var = $varmap{$var};
    }

    return $var;
}

sub version {
    my $self = shift;

    if (@_) {
        my $ver = shift;

        if ($ver !~ m{^\d+$}o || $ver < 0 || $ver > 15) {
            croak "invalid parameter";
        }

        substr $$self, 6, 1,
               chr(ord(substr($$self, 6, 1)) & 0x0f | $ver << 4);

        return $ver;
    }

    return (ord(substr($$self, 6, 1)) & 0xf0) >> 4;
}

sub time_low {
    my $self = shift;

    if (@_) {
        my $arg = shift;

        substr $$self, 0, 4, pack('N', $arg);

        return $arg;
    }

    return unpack 'N', substr($$self, 0, 4);
}

sub time_mid {
    my $self = shift;

    if (@_) {
        my $arg = shift;

        substr $$self, 4, 2, pack('n', $arg);

        return $arg;
    }

    return unpack 'n', substr($$self, 4, 2);
}

sub time_hi {
    my $self = shift;

    if (@_) {
        my $arg = shift;

        if ($arg >= 0x1000) {
            croak "invalid parameter";
        }

        substr $$self, 6, 2,
               pack('n', unpack('n', substr($$self, 6, 2)) & 0xf000
                         | $arg);

        return $arg;
    }

    return unpack('n', substr($$self, 6, 2)) & 0x0fff;
}

sub clk_seq {
    my $self = shift;

    my $r = unpack 'n', substr($$self, 8, 2);

    my $v = $r >> 13;
    my $w = ($v >= 6) ? 3   # 11x
          : ($v >= 4) ? 2   # 10-
          :             1;  # 0--

    $w = 16 - $w;

    if (@_) {
        my $arg = shift;

        if ($arg < 0) {
            croak "invalid parameter";
        }

        $arg &= ((1 << $w) - 1);

        substr $$self, 8, 2,
               pack('n', $r & (0xffff - ((1 << $w) - 1)) | $arg);

        return $arg;
    }

    return $r & ((1 << $w) - 1);
}

sub node {
    my $self = shift;

    if (@_) {
        my $arg = shift;

        if (length $arg == 6) {
        }
        elsif (length $arg == 12) {
            $arg = pack 'H*', $arg;
        }
        elsif (length $arg == 17) {
            if ($arg !~ m{ \A (?: [0-9A-F]{2} ) ([-:]) [0-9A-F]{2}
                                             (?:  \1   [0-9A-F]{2} ){4}
                           \z }ixmso) {
                croak "invalid parameter";
            }

            $arg =~ tr{-:}{}d;
            $arg = pack 'H*', $arg;
        }
        else {
            croak "invalid parameter";
        }

        substr $$self, 10, 6, $arg;
    }

    return join q{:}, map { uc unpack 'H*', $_ }
                          split q{}, substr $$self, 10, 6;
}

sub _set_time {
    my ($self, $arg) = @_;

    # hi = time mod (1000000 / 0x100000000)
    my $hi = floor($arg / 65536.0 / 512 * 78125);
    $arg -= $hi * 512.0 * 65536 / 78125;
    
    my $low = floor($arg * 10000000.0 + 0.5);

    # MAGIC offset: 01B2-1DD2-13814000
    if ($low < 0xec7ec000) {
        $low += 0x13814000;
    }
    else {
        $low -= 0xec7ec000;
        $hi ++;
    }

    if ($hi < 0x0e4de22e) {
        $hi += 0x01b21dd2;
    }
    else {
        $hi -= 0x0e4de22e;  # wrap around
    }

    $self->time_low($low);
    $self->time_mid($hi & 0xffff);
    $self->time_hi(($hi >> 16) & 0x0fff);

    return $self;
}

sub time {
    my $self = shift;

    if (@_) {
        $self->_set_time(@_);
    }

    my $low = $self->time_low;
    my $hi  = $self->time_mid | ($self->time_hi << 16);

    # MAGIC offset: 01B2-1DD2-13814000
    if ($low >= 0x13814000) {
        $low -= 0x13814000;
    }
    else {
        $low += 0xec7ec000;
        $hi --;
    }

    if ($hi >= 0x01b21dd2) {
        $hi -= 0x01b21dd2;
    }
    else {
        $hi += 0x0e4de22e;  # wrap around
    }

    $low /= 10000000.0;
    $hi  /= 78125.0 / 512 / 65536;  # / 1000000 * 0x100000000

    return $hi + $low;
}

sub is_v1 {
    my $self = shift;
    return $self->variant == 2 && $self->version == 1;
}

sub is_v2 {
    my $self = shift;
    return $self->variant == 2 && $self->version == 2;
}

sub is_v3 {
    my $self = shift;
    return $self->variant == 2 && $self->version == 3;
}

sub is_v4 {
    my $self = shift;
    return $self->variant == 2 && $self->version == 4;
}

sub is_v5 {
    my $self = shift;
    return $self->variant == 2 && $self->version == 5;
}

{
    my %uuid_const;

    my %uuid_const_map = (
        uuid_nil     => '00000000-0000-0000-0000-000000000000',
        uuid_ns_dns  => '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
        uuid_ns_url  => '6ba7b811-9dad-11d1-80b4-00c04fd430c8',
        uuid_ns_oid  => '6ba7b812-9dad-11d1-80b4-00c04fd430c8',
        uuid_ns_x500 => '6ba7b814-9dad-11d1-80b4-00c04fd430c8',
    );

    while (my ($id, $uuid) = each %uuid_const_map) {
        my $sub
            = sub {
                if (! defined $uuid_const{$id}) {
                    $uuid_const{$id}
                        = __PACKAGE__->create_from_string($uuid);
                }

                return $uuid_const{$id}->clone();
            };

        no strict 'refs';
        *{__PACKAGE__ . '::' . $id} = $sub;
    }
}

1;
__END__

=head1 NAME

UUID::Object - Universally Unique IDentifier (UUID) Object Class

=head1 DESCRIPTION

This module is going to be marked as *DEPRECATED*.

Do not use this module in your applications / modules.

Currently, this implementation is still functional.
If you want to know API, please refer to PODs in version 0.04.

=head1 FUTURE PLAN

=over 2

=item (1) will be renewed module that behaves like a Mix-in module to L<Data::GUID>

=item (2) will be compatibility layer to that module, and be marked as DEPRECATED

=item (3) will be withdrawn from CPAN after a while

=back

=head1 AUTHOR

ITO Nobuaki E<lt>banb@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::GUID>.

version 0.04: L<http://search.cpan.org/~banb/UUID-Object-0.04/>.

=cut
