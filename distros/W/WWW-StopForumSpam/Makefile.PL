use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WWW::StopForumSpam',
    VERSION_FROM      => 'lib/WWW/StopForumSpam.pm',
    LICENSE           => 'perl_5',
    PREREQ_PM         => {
        'Carp' => 0,
        'URI::Escape' => 0,
        'Digest::MD5' => 0,
        'Socket' => 0,
        'WWW::Curl::Easy' => 0,
        'JSON' => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WWW/StopForumSpam.pm',
       AUTHOR         => 'Günter Grodotzki <guenter@perlhipster.com>',
      ) : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.46 ?
      (META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources => {
          license => 'http://dev.perl.org/licenses/',
          homepage => 'http://www.perlhipster.com/p5-stopforumspam',
          bugtracker => {
            web    => 'https://github.com/lifeofguenter/p5-stopforumspam/issues',
            mailto => 'bugs@perlhipster.com',
          },
          repository => {
            type => 'git',
            url  => 'git://github.com/lifeofguenter/p5-stopforumspam.git', 
            web  => 'https://github.com/lifeofguenter/p5-stopforumspam'
          },
        }
      }) : ()),
);