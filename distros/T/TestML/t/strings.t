use TestML;
TestML->new(
    testml => join('', <DATA>),
)->run;

__DATA__
%TestML 0.1.0

Plan = 6

Throw(*error).bogus().Catch() == *error
*error.Throw().bogus().Catch() == *error
Throw('My error message').Catch() == *error

*empty == "".Str
*empty == ""

Label = 'Simple string comparison'
"foo" == "foo"

=== Throw/Catch
--- error: My error message

=== Empty Point
--- empty


