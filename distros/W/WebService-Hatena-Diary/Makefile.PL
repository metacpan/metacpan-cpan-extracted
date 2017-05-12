use inc::Module::Install;
name 'WebService-Hatena-Diary';
all_from 'lib/WebService/Hatena/Diary.pm';

requires $_ for (qw(
    XML::Atom 
    HTTP::Request
    DateTime 
    DateTime::Format::W3CDTF 
    DateTime::Format::Strptime
));

build_requires (qw(Test::More));

auto_include;
WriteAll;
