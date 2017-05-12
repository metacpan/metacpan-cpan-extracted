requires 'perl', '5.008000';

# requires 'Some::Module', 'VERSION';

requires 'Unicode::Normalize', '0';

on test => sub {
    requires 'Test::More', '0.88';
    requires 'Test::Deep', '0';
};

on 'develop' => sub {
  requires 'Test::Spelling';
  requires 'Test::MinimumVersion';
  requires 'Test::Pod::Coverage';
  requires 'Test::PureASCII';
};