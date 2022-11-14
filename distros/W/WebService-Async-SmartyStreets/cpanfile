requires 'mro', 0;
requires 'indirect', 0;
requires 'parent', 0;
requires 'Net::Async::HTTP', '>= 0.44';
requires 'IO::Async::SSL', 0;
requires 'Future::AsyncAwait', '>= 0.21';
requires 'JSON::MaybeUTF8', 0;
requires 'Syntax::Keyword::Try', 0;

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
};

on test => sub {
    requires 'Test::More';
    requires 'Test::Fatal';
    requires 'Test::Warnings';
};
