requires 'perl', '5.014001';
requires 'Carp';
requires 'Exporter';
requires 'File::Share';
requires 'JSON::XS';
requires 'List::Util';
requires 'List::UtilsBy';
requires 'Net::IDN::Encode';
requires 'Path::Tiny';
requires 'Unicode::Normalize';
requires 'YAML::PP';

on 'develop' => sub {
    requires 'Devel::Cover';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test2::Plugin::GitHub::Actions::AnnotateFailedTest';
    requires 'Test2::V0';
    requires 'Unicode::GCString';
};

