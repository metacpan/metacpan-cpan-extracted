requires 'Carp';
requires 'File::Spec';
requires 'JSON';
requires 'List::MoreUtils';
requires 'Math::Business::BlackScholes::Binaries';
requires 'Math::Business::BlackScholes::Binaries::Greeks::Delta';
requires 'Math::CDF';
requires 'POSIX';
requires 'base';
requires 'perl', '5.006';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'Test::Exception';
    requires 'Test::MockModule';
    requires 'Test::MockTime';
    requires 'Test::More';
    requires 'Test::NoWarnings';
    requires 'Test::Perl::Critic';
};
