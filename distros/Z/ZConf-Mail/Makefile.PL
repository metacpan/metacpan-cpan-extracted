use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ZConf::Mail',
    AUTHOR              => 'Zane C. Bowers <vvelox@vvelox.net>',
    VERSION_FROM        => 'lib/ZConf/Mail.pm',
    ABSTRACT_FROM       => 'lib/ZConf/Mail.pm',
    INST_SCRIPT => 'bin',
    PL_FILES            => {},
    PREREQ_PM => {
				  'Test::More' => 0,
				  'Config::Tiny'=>0,
				  'Email::Simple'=>0,
				  'Email::Simple::Creator'=>0,
				  'Mail::IMAPTalk'=>0,
				  'Mail::POP3Client'=>0,
				  'Net::SMTP_auth'=>0,
				  'Net::SMTP::TLS'=>0,
				  'Mail::Box::Manager'=>0,
				  'IO::MultiPipe'=>0,
				  'ZConf'=>0,
				  'Email::Abstract'=>0,
				  'File::MimeInfo::Magic'=>0,
				  'Email::Date'=>0,
				  'MIME::Lite'=>0,
				  'String::ShellQuote'=>0,
				  'Sys::Hostname'=>0,
				  'MIME::QuotedPrint'=>0,
				  'Text::Autoformat'=>0,
				  },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ZConf-Mail-*' },
);
