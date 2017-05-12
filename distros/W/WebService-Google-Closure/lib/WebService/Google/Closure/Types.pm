package WebService::Google::Closure::Types;

use MooseX::Types
    -declare => [
        qw(
              Stats
              Warning
              Error
              ArrayRefOfWarnings
              ArrayRefOfErrors
              ArrayRefOfStrings
              CompilationLevel
      )
    ];

use MooseX::Types::Moose qw( ArrayRef HashRef Str Int Undef );
use Perl6::Junction qw( any );
use JSON;

use WebService::Google::Closure::Type::Warning;
use WebService::Google::Closure::Type::Error;
use WebService::Google::Closure::Type::Stats;

subtype ArrayRefOfStrings,
    as ArrayRef[Str];

coerce ArrayRefOfStrings,
    from Str,
    via { [ $_ ] };

my $level = {
    NOOP                   => 0,
    WHITESPACE_ONLY        => 1,
    SIMPLE_OPTIMIZATIONS   => 2,
    ADVANCED_OPTIMIZATIONS => 3,
};

subtype CompilationLevel,
    as Str,
    where { any( keys(%$level) ) eq $_ },
    message { "Illegal compilation level" };

coerce CompilationLevel,
    from Int,
    via { my $in = $_; [ grep { $in == $level->{ $_ } } keys( %$level ) ]->[0] };

coerce CompilationLevel,
    from Str,
    via { uc $_ };

coerce CompilationLevel,
    from Undef,
    via { 'SIMPLE_OPTIMIZATIONS' };

class_type Warning,
    { class => 'WebService::Google::Closure::Type::Warning' };

coerce Warning,
    from HashRef,
    via { WebService::Google::Closure::Type::Warning->new( $_ ) };

class_type Error,
    { class => 'WebService::Google::Closure::Type::Error' };

coerce Error,
    from HashRef,
    via { WebService::Google::Closure::Type::Error->new( $_ ) };

subtype ArrayRefOfWarnings,
    as ArrayRef[Warning];

coerce ArrayRefOfWarnings,
    from ArrayRef[HashRef],
    via { [ map { to_Warning( $_ ) } @$_ ] };

subtype ArrayRefOfErrors,
    as ArrayRef[Error];

coerce ArrayRefOfErrors,
    from ArrayRef[HashRef],
    via { [ map { to_Error( $_ ) } @$_ ] };

class_type Stats,
    { class => 'WebService::Google::Closure::Type::Stats' };

coerce Stats,
    from HashRef,
    via { WebService::Google::Closure::Type::Stats->new( $_ ) };

1;
