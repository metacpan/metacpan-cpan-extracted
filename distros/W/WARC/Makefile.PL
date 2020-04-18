require 5.008_001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME		=> 'WARC',
    MIN_PERL_VERSION	=> '5.8.1',
    AUTHOR		=> 'Jacob Bachmeyer <jcb@cpan.org>',
    LICENSE		=> 'perl',
    PREREQ_PM		=> { version => '0.77',
			     # actual version required is unknown for these
			     'HTTP::Message' => 0,
			     'HTTP::Request' => 0,
			     'HTTP::Response' => 0,
			     'URI' => 0,
			     # 2.024 needed to record zlib version used
			     'IO::Compress::Gzip' => 2.024,
			     'IO::Uncompress::Gunzip' => 2.021,
			     # 1.02 is oldest Changelog entry
			     'MIME::Base32' => 1.02,
			     'Scalar::Util' => 1.14,
			     'Time::Local' => 1.08,
			     # MakeMaker is actually only needed for building,
			     #  but TEST_REQUIRES was added in 6.64.
			     'ExtUtils::MakeMaker' => 6.64,
			     # core modules; all versions should work but I
			     #  want the information in test reports
			     'Carp' => 0,
			     'Cwd' => 0,
			     'Encode' => 0,
			     'Errno' => 0,
			     'Fcntl' => 0,
			     'File::Spec' => 0,
			     'File::Spec::Unix' => 0,
			     'File::Temp' => 0,
			     'Math::BigInt' => 0,
			     'Symbol' => 0,
			     'constant' => 0,
			     'overload' => 0,
			     'strict' => 0,
			     'warnings' => 0,
			   }, # E.g., Module::Name => 1.1
    TEST_REQUIRES	=> { 'Test::More' => '0.94',	# for "subtest"
			     'Digest' => 0,	# actual minimum unknown
			     'Digest::SHA' => 5.00,
			     # core modules; all versions should work but I
			     #  want the information in test reports
			     'File::Copy' => 0,
			     'File::Find' => 0,
			     'File::Spec::Functions' => 0,
			     'FindBin' => 0,
			     'Getopt::Long' => 0,
			     'Storable' => 0,
			   },
    ABSTRACT_FROM	=> 'lib/WARC.pm', # retrieve abstract from module
    VERSION_FROM	=> 'lib/WARC.pm', # finds $VERSION
);
