use inc::Module::Install;
name 'Web-JenkinsNotification';
all_from 'lib/Web/JenkinsNotification.pm';

requires 'Plack';
requires 'Net::Jenkins' => 0.04;
requires 'Jenkins::NotificationListener' => 0.04;

readme_from_pod 'lib/Web/JenkinsNotification.pm';
readme_markdown_from_pod 'lib/Web/JenkinsNotification.pm';

tests 't/*.t';
# author_tests 'xt';
test_requires qw(Test::More File::Read HTTP::Request::Common);
# auto_set_repository;
auto_include;
WriteAll;
