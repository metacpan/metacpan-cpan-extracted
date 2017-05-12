
use strict;
use warnings;

use ExtUtils::MakeMaker qw(WriteMakefile prompt);

require 't/_test_util_config.pl';

mkdir 'blib' unless -d 'blib';

print <<EOT;

==
== Live testing requires that you enter your
== cloud.scorm.com AppId and SecretKey.
==
EOT

my $answer = prompt('== Do you want to run the live tests?', 'no');
if ($answer =~ /^y/i)
{
    createTestConfigInfo(skip_live_tests => 0);
}
else
{
    print "Live tests will be skipped.\n";
    createTestConfigInfo(skip_live_tests => 1);
}

sub license
{
    my $license = shift;
    local $^W = 0;    # silence warning about non-numeric version
    return unless $ExtUtils::MakeMaker::VERSION >= 6.3002;
    return (LICENSE => $license);
}

WriteMakefile(
         NAME          => 'WebService::ScormCloud',
         AUTHOR        => q{Larry Leszczynski <larryl@cpan.org>},
         VERSION_FROM  => 'lib/WebService/ScormCloud.pm',
         ABSTRACT_FROM => 'lib/WebService/ScormCloud.pm',
         license('perl'),
         PL_FILES  => {},
         PREREQ_PM => {
                       'Carp'                         => 0,
                       'Data::Dump'                   => 0,
                       'Digest::MD5'                  => 0,
                       'File::Spec'                   => 0,
                       'HTTP::Request::Common'        => 0,
                       'LWP::UserAgent'               => 0,
                       'Moose::Role'                  => 0,
                       'Moose::Util::TypeConstraints' => 0,
                       'Moose'                        => 0,
                       'POSIX'                        => 0,
                       'Readonly'                     => 0,
                       'Test::Exception'              => 0,
                       'Test::More'                   => 0,
                       'Time::Local'                  => 0,
                       'Try::Tiny'                    => 0,
                       'URI'                          => 0,
                       'XML::Simple'                  => 0,
                      },
         dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
         clean => {FILES    => 'ScormCloud-*'},
);
