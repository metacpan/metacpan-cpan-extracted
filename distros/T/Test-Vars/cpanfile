requires 'B';
requires 'parent';
requires 'perl', '5.010';
requires 'List::Util', '1.33';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.59';
};

on test => sub {
    requires 'Test::More', '0.88';
    requires 'Test::Tester';
    requires 'Test::Output';
};

on develop => sub {
   requires 'Moose::Role';
   requires 'Pod::Spelling';
   requires 'Test::Pod', '1.14';
   requires 'Test::Pod::Coverage', '1.04';
   requires 'Test::Spelling', '0.12';
   requires 'Test::Synopsis';
};
