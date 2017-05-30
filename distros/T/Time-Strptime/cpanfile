requires 'DateTime::Locale';
requires 'DateTime::TimeZone';
requires 'Encode';
requires 'List::MoreUtils';
requires 'Scalar::Util';
requires 'Time::Local';
requires 'parent';
requires 'perl', '5.008005';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More';
};

on develop => sub {
    requires 'DateTime::Format::Strptime';
    requires 'Getopt::Long';
    requires 'POSIX::strptime';
    requires 'Time::Moment';
    requires 'Time::Piece';
    requires 'Time::TZOffset';
    requires 'feature';
};
