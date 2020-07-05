use Test::Most;

BEGIN {
    use_ok('OpenTracing::Implementation::Test');
    use_ok('OpenTracing::Implementation::Test::Scope');
    use_ok('OpenTracing::Implementation::Test::ScopeManager');
    use_ok('OpenTracing::Implementation::Test::Span');
    use_ok('OpenTracing::Implementation::Test::SpanContext');
    use_ok('OpenTracing::Implementation::Test::Tracer');
    use_ok('Test::OpenTracing::Integration');
};

done_testing;
