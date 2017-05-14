use inc::Module::Install 0.68;


name 'Form-Processor';
all_from 'lib/Form/Processor.pm';

requires 'Rose::Object'       => '0.015';
requires 'Scalar::Util'       => '1.18';
requires 'UNIVERSAL::require' => '0';
requires 'Locale::Maketext'   => '1.09';
requires 'Module::Find'       => '0.05';

build_requires 'Test::More' => 0;


my %recommended = (

    'DateTime'                    => '0.34',
    'Date::Manip'                 => '5.44',
    'DateTime::Format::DateManip' => '0.04',
    'Email::Valid'                => '0.179',
    'Template'                    => '2.19',
    'HTML::Tidy'                  => '1.06',
    'File::Temp'                  => '0.16',
    'Net::CIDR'                   => '0.11',
    'Digest::MD5'                 => '2.36',
);

recommends $_ => $recommended{$_} for keys %recommended;

sub MY::postamble {
    my $optional = join ',', keys %recommended;
    return <<"EOM";

test-missing:
\texport DEVEL_HIDE_VERBOSE=0; perl -MDevel::Hide=-from:children,$optional -e 'exec("make test")'

test-all:
\texport TEST_ALL_MODULES=1; make test
EOM

}


auto_install;
WriteAll;

print <<EOF;
    make test           - test normal environment ignoring recommended modules
    make test-missing:  - test case of all recommeneded modules missing
    make test-all       - require all recommended modules
EOF
