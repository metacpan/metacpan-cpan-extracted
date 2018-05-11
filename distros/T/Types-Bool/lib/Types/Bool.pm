
BEGIN {

    # For historical reasons, alias *Types::Bool with JSON::PP::Boolean
    *Types::Bool:: = *JSON::PP::Boolean::;

    # JSON/PP/Boolean.pm is redundant
    $INC{'JSON/PP/Boolean.pm'} ||= __FILE__
      unless $ENV{TYPES_BOOL_LOUD};
}

package Types::Bool;

# ABSTRACT: Booleans as objects for Perl

use 5.005;

BEGIN {
    require overload;
    overload->import(
        '0+' => sub { ${ $_[0] } },
        '++' => sub { $_[0] = ${ $_[0] } + 1 },
        '--' => sub { $_[0] = ${ $_[0] } - 1 },
        fallback => 1,
    ) unless overload::Method( Types::Bool, '0+' );

    require constant;
    constant->import( true => do { bless \( my $dummy = 1 ), 'Types::Bool' } )
      unless Types::Bool->can('true');
    constant->import( false => do { bless \( my $dummy = 0 ), 'Types::Bool' } )
      unless Types::Bool->can('false');

    unless ( Types::Bool->can('is_bool') ) {
        require Scalar::Util;
        *is_bool = sub ($) { Scalar::Util::blessed( $_[0] ) and $_[0]->isa('Types::Bool') };
    }

    $Types::Bool::VERSION = '2.98009'
      unless $Types::Bool::VERSION;

    $Types::Bool::ALT_VERSION = '2.98009';
}

sub to_bool ($) { $_[0] ? true : false }

@Types::Bool::EXPORT_OK = qw(true false is_bool to_bool);

sub import {    # Load Exporter only if needed
    return unless @_ > 1;

    require Exporter;
    my $EXPORTER_VERSION = Exporter->VERSION;
    $EXPORTER_VERSION =~ tr/_//d;
    push @ISA, qw(Exporter) if $EXPORTER_VERSION < 5.57;

    no warnings 'redefine';
    *import = sub {
        return unless @_ > 1;
        goto &Exporter::import;
    };
    goto &Exporter::import;
}

1;
