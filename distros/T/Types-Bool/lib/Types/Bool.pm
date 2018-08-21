
use 5.005;

package Types::Bool;
$Types::Bool::VERSION = '2.98012';

# ABSTRACT: An interface to booleans as objects for Perl

BEGIN {

    # For historical reasons, alias *Types::Bool::Impl with JSON::PP::Boolean
    *Types::Bool::Impl:: = *JSON::PP::Boolean::;

    # JSON/PP/Boolean.pm is redundant
    $INC{'JSON/PP/Boolean.pm'} ||= __FILE__
      unless $ENV{TYPES_BOOL_NICE};
}

package    #
  Types::Bool::Impl;

BEGIN {
    require overload;
    if ( $ENV{TYPES_BOOL_LOUD} ) {
        my @o = grep __PACKAGE__->overload::Method($_), qw(0+ ++ --);
        my @s = grep __PACKAGE__->can($_), qw(new);
        push @s, '$VERSION' if $Types::Bool::VERSION;
        if ( @o || @s ) {
            my $p = ref do { bless \( my $dummy ), __PACKAGE__ };
            my @f;
            push @f, join( ', ', @s ) if @s;
            push @f, 'overloads on ' . join( ', ', @o ) if @o;
            warn join( ' and ', @f ), qq{ defined for $p elsewhere};
        }
    }

    overload->import(
        '0+' => sub { ${ $_[0] } },
        '++' => sub { $_[0] = ${ $_[0] } + 1 },
        '--' => sub { $_[0] = ${ $_[0] } - 1 },
        fallback => 1,
    ) unless __PACKAGE__->overload::Method('0+');

    *new = sub { bless \( my $dummy = $_[1] ? 1 : 0 ), $_[0] }
      unless __PACKAGE__->can('new');

    $Types::Bool::Impl::VERSION = '2.98012'
      unless $Types::Bool::Impl::VERSION;
}

package Types::Bool;

use Scalar::Util ();

use constant true  => Types::Bool::Impl->new(1);
use constant false => Types::Bool::Impl->new(0);

use constant BOOL_PACKAGE => ref true;

sub is_bool ($) { Scalar::Util::blessed( $_[0] ) and $_[0]->isa(BOOL_PACKAGE) }

sub to_bool ($) { $_[0] ? true : false }

@Types::Bool::EXPORT_OK = qw(true false is_bool to_bool BOOL_PACKAGE);

BEGIN {
    if ( "$]" < 5.008003 ) {    # Inherit from Exporter (if needed)
        require Exporter;
        my $EXPORTER_VERSION = Exporter->VERSION;
        $EXPORTER_VERSION =~ tr/_//d;
        push @Types::Bool::ISA, qw(Exporter) if $EXPORTER_VERSION < 5.57;
    }
}

sub import {                    # Load Exporter only if needed
    return unless @_ > 1;

    require Exporter;

    no warnings 'redefine';
    *import = sub {
        return unless @_ > 1;
        goto &Exporter::import;
    };
    goto &Exporter::import;
}

1;
