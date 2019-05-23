use strict;
use warnings;
use Test::More;
use Test::NiceDump 'nice_dump';

# generic empty constructor
sub newobj { my ($class,$content) = @_; return bless $content||{}, $class }
# fake modules we'll use to test
{ package DateTime; sub format_cldr { 'datetime-cldr' } }
{ package Overloaded; use overload q{""} => sub { 'overloaded' } }
{ package AsString; sub as_string { 'as_string' } }
{ package To_String; sub to_string { 'to_string' } }
{ package ToString; sub toString { 'toString' } }
{ package TO_JSON; sub TO_JSON { 'TO_JSON' } }
{ package DBIx::Class::Schema; sub foo {} }
{ package Schema; our @ISA = ('DBIx::Class::Schema') }
{ package Columns; sub get_inflated_columns { dt => ::newobj('DateTime') } }
{ package Test::Deep::Thing; use overload q{""} => sub { 'overloaded' } }

subtest 'built-in filters' => sub {
    my $dumped_string = nice_dump +[
        newobj('Overloaded'),
        {
            as_string => newobj('AsString'),
            to_string => newobj('To_String'),
            tostring => newobj('ToString'),
            to_json => newobj('TO_JSON'),
        },
        newobj('Schema'),
        newobj('Columns'),
        newobj('Test::Deep::Thing', { val => [1,2,3] }),
        newobj('Test::Deep::Methods', { val => [1,2,3], methods => [qw(a b c)] }),
        { normal => 'data' },
    ];

    like(
        $dumped_string,
        qr{\A\s*
\[\s*

\#\s+Overloaded \s+ "overloaded"\s*,\s*

\{\s*

as_string \s*=>\s* \#\s+AsString \s+ "as_string"\s*,\s*
to_json \s*=>\s* \#\s+TO_JSON \s+ "TO_JSON"\s*,\s*
to_string \s*=>\s* \#\s+To_String \s+ "to_string"\s*,\s*
tostring \s*=>\s* \#\s+ToString \s+ "toString" (?:\s*,)+\s*

\}\s*,\s*

\#\s+Schema \s+ "DBIx::Class::Schema\ object"\s*,\s*

\#\s+Columns \s+
\{\s*

dt \s*=>\s* \#\s+DateTime \s+ "datetime-cldr" (?:\s*,)?\s*

\}\s*,\s*

\#\s+Test::Deep::Thing \s+
\[\s* 1, \s* 2, \s* 3 \s* \]\s*,\s*

\#\s+Test::Deep::Methods \s+
\[\s* "a", \s* "b", \s* "c" \s* \]\s*,\s*

\{\s* normal \s*=>\s* "data" (?:\s*,)?\s*\}\s*,\s*

\s*\]
      \s*\z}smx,
        'the data structure should be dumped as expected',
    );
};

subtest 'extra filters' => sub {
    my $unique_reference = \(do { my $x });

    my $builtin_dump = nice_dump($unique_reference);
    is(
        $builtin_dump,
        '\undef',
        'ref to undef should be dumped as such, with only built-in behaviour',
    );

    Test::NiceDump::add_filter(
        my_unique => sub {
            if ($_[0] == $unique_reference) { return 'unique' }
            return;
        },
    );

    Test::NiceDump::add_filter(
        other_filter => sub {
            if ($_[0] == 1) { return 'ONE' }
            return;
        },
    );

    my $custom_dump = nice_dump($unique_reference);

    isnt($custom_dump,$builtin_dump, 'custom filters should affect the dump');

    like($custom_dump,qr{\bunique\b}, 'the filter should be called');
};

done_testing;
