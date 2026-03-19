requires 'perl', '5.040';

# Core dependencies
requires 'Moo', '2.005';
requires 'namespace::clean', '0.27';
requires 'Log::Any', '1.710';
requires 'JSON::MaybeXS', '1.004';
requires 'URI';
requires 'IO::Socket::UNIX';
requires 'Time::HiRes';
requires 'IO::Socket::INET';
requires 'Carp';
requires 'Exporter';

# Optional but recommended
recommends 'HTTP::Tiny', '0.076';

# Test dependencies
on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception', '0.43';
    requires 'Path::Tiny', '0.100';
};

# Development dependencies
on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Dist::Zilla::Plugin::MetaProvides::Package';
};
