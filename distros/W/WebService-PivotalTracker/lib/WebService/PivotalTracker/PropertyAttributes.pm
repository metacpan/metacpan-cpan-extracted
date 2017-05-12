package WebService::PivotalTracker::PropertyAttributes;

use strict;
use warnings;

our $VERSION = '0.07';

use Scalar::Util qw( blessed );
use Sub::Quote qw( quote_sub );

use Exporter qw( import );

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = 'props_to_attributes';

sub props_to_attributes {
    my %props = @_;

    my $caller = caller();
    return map { [ $_ => _attr_for( $caller, $_, $props{$_} ) ] } keys %props;
}

sub _attr_for {
    my $caller = shift;
    my $name   = shift;
    my $prop   = shift;

    $prop = { type => $prop }
        if blessed $prop;

    my $default = q{};
    my %env;
    if ( $prop->{may_require_refresh} ) {
        $default .= sprintf( <<'EOF', $name );
$_[0]->_refresh_raw_content unless exists $_[0]->raw_content->{%s};
EOF
    }

    if ( $prop->{default} ) {
        $env{'$default'} = \$prop->{default};
        $default .= sprintf( <<'EOF', $name, $name );
my $val = exists $_[0]->raw_content->{%s} ? $_[0]->raw_content->{%s} : $default->();
EOF
    }
    else {
        $default .= sprintf( <<'EOF', $name );
my $val = $_[0]->raw_content->{%s};
EOF
    }

    if ( $prop->{inflator} ) {
        $default .= sprintf( <<'EOF', $prop->{inflator} );
return unless defined $val;
return $_[0]->%s( $val );
EOF
    }
    else {
        $default .= 'return $val;';
    }

    my $subname = join '::', $caller, '_build_' . $name;
    return (
        is       => 'ro',
        isa      => $prop->{type},
        init_arg => undef,
        lazy     => 1,
        default  => quote_sub( $subname, $default, \%env ),
        clearer  => '_clear_' . $name,
    );
}

1;
