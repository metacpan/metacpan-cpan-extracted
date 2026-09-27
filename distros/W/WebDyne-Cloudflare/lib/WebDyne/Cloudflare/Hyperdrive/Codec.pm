package WebDyne::Cloudflare::Hyperdrive::Codec;

use 5.020;
use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(blessed);
use WebDyne::Cloudflare ();
use WebDyne::Cloudflare::Hyperdrive::Blob;

our $VERSION='0.001';

sub parameters {
    my (@param)=@_;
    return [map {
        my $value=$_;
        if (!defined($value)) { ['null'] }
        elsif (JSON::PP::is_bool($value)) { ['bool', $value] }
        elsif (blessed($value)&&$value->isa('WebDyne::Cloudflare::Hyperdrive::Blob')) {
            ['bytes', unpack('H*', $value->bytes())];
        }
        elsif (!ref($value)) {
            my $text="$value";
            $text=WebDyne::Cloudflare::json_value($text);
            die "Hyperdrive text cannot contain NUL\n" if index($text, "\0")>=0;
            ['text', $text];
        }
        else { die "Hyperdrive parameters must be scalars, booleans or blobs\n" }
    } @param];
}


sub cell {
    my ($cell_ar)=@_;
    die "Invalid Hyperdrive cell\n" unless ref($cell_ar) eq 'ARRAY';
    my ($type, $value)=@{$cell_ar};
    die "Invalid Hyperdrive cell type\n" unless defined($type)&&!ref($type);
    return undef if ($type eq 'null')&&(@{$cell_ar}==1);
    die "Invalid Hyperdrive cell length\n" unless @{$cell_ar}==2;
    return $value if ($type eq 'bool')&&JSON::PP::is_bool($value);
    if (defined($value)&&!ref($value)) {
        return $value if $type eq 'text';
        return 0+$value if ($type eq 'number')&&($value=~/\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\z/);
        return $value if ($type eq 'special')&&($value=~/\A(?:NaN|-?Infinity)\z/);
        return pack('H*', $value) if ($type eq 'bytes')&&($value=~/\A(?:[0-9a-f]{2})*\z/);
    }
    die "Invalid Hyperdrive cell value\n";
}


sub result {
    my ($result_hr)=@_;
    die "Invalid Hyperdrive result\n" unless ref($result_hr) eq 'HASH';
    return $result_hr unless exists($result_hr->{'rows'});
    my ($columns_ar, $rows_ar)=@{$result_hr}{qw(columns rows)};
    die "Invalid Hyperdrive columns or rows\n"
        unless (ref($columns_ar) eq 'ARRAY')&&(ref($rows_ar) eq 'ARRAY');
    foreach my $column_hr (@{$columns_ar}) {
        die "Invalid Hyperdrive column\n" unless (ref($column_hr) eq 'HASH')
            &&defined($column_hr->{'name'})&&!ref($column_hr->{'name'})
            &&((defined($column_hr->{'oid'})&&!ref($column_hr->{'oid'})
            &&($column_hr->{'oid'}=~/\A[0-9]+\z/))
            ||(defined($column_hr->{'driver'})&&($column_hr->{'driver'} eq 'mysql')
            &&defined($column_hr->{'type'})&&!ref($column_hr->{'type'})
            &&($column_hr->{'type'}=~/\A[0-9]+\z/)));
    }
    my @rows;
    foreach my $row_ar (@{$rows_ar}) {
        die "Invalid Hyperdrive row\n" unless (ref($row_ar) eq 'ARRAY')&&(@{$row_ar}==@{$columns_ar});
        push(@rows, [map { cell($_) } @{$row_ar}]);
    }
    return { %{$result_hr}, rows => \@rows };
}

1;
