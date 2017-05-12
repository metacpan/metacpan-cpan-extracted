requires 'Cache::RedisDB', '0.07';
requires 'Path::Tiny', '0.061';
requires 'YAML::XS', '0.59';

on configure => sub {
    requires 'ExtUtils::MakeMaker';
};

on build => sub {
    requires 'ExtUtils::MakeMaker';
};

on test => sub {
    requires 'File::Temp', '0.22';
    requires 'Test::Most', '0.34';
    recommends 'Test::RedisServer', '0.14';
};

