requires 'indirect', 0;

requires 'URI', 0;
requires 'URI::QueryParam', 0;
requires 'URI::Template', 0;
requires 'URI::Escape', 0;

requires 'Net::Async::HTTP', 0;
requires 'JSON::MaybeUTF8', 0;
requires 'IO::Async::SSL', 0;

requires 'Syntax::Keyword::Try', 0;
requires 'Path::Tiny', 0;

requires 'Log::Any', 0;
requires 'Log::Any::Adapter', 0;

requires 'Time::Moment', 0;

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
};

on test => sub {
    requires 'Test::More', '>= 0.98';
    requires 'Test::MockObject', 0,
    requires 'Test::MockModule', 0;
    requires 'Test::NoWarnings', 0;
    requires 'Path::Tiny', 0;
    requires 'URI', 0;
    requires 'Test::Fatal', 0;
    requires 'Clone', 0;
    requires 'Time::Moment', 0;
    requires 'Data::UUID', 0;
};

