use Test::More;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 12;

pod_coverage_ok('XHTML::Instrumented', 'XHTML::Instrumented is covered');
pod_coverage_ok('XHTML::Instrumented::Context', 'Context is covered');
pod_coverage_ok('XHTML::Instrumented::Control', 'Control is covered');
pod_coverage_ok('XHTML::Instrumented::Entry', 'Entry is covered');
pod_coverage_ok('XHTML::Instrumented::Form', 'Form is covered');
pod_coverage_ok('XHTML::Instrumented::Form::Option', 'Form:Option is covered');
pod_coverage_ok('XHTML::Instrumented::Form::Hidden', 'Form::Hidden is covered');
pod_coverage_ok('XHTML::Instrumented::Form::Checkbox', 'Form::Checkbox is covered');
pod_coverage_ok('XHTML::Instrumented::Form::Select', 'Form::Select is covered');
pod_coverage_ok('XHTML::Instrumented::Form::Element', 'Form::Element is covered');
pod_coverage_ok('XHTML::Instrumented::Form::ElementControl', 'Form::ElementControl is covered');
pod_coverage_ok('XHTML::Instrumented::Loop', 'Loop is covered');

TODO: {
    local $TODO = 'no pod';
}

