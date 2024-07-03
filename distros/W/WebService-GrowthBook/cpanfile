requires 'indirect',    '>= 0.37';
requires 'Object::Pad', '>= 0.805';
requires 'JSON::MaybeUTF8';
requires 'Scalar::Util';
requires 'HTTP::Tiny';
requires 'Log::Any';
requires 'Syntax::Keyword::Try';
requires 'Digest::MD5';


on test => sub {
    requires 'Test::More', '>= 0.98';
    requires 'Test::Exception';
    requires 'Test::MockModule';
    requires 'Path::Tiny';
    requires 'FindBin';
};

on develop => sub {
    requires 'Devel::Cover', '>= 1.23';
    requires 'Devel::Cover::Report::Codecov', '>= 0.14';
};
