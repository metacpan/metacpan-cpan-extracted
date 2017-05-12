use 5.008008;
use ExtUtils::MakeMaker "6.46";
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Webqq::Encryption',
    VERSION_FROM      => 'lib/Webqq/Encryption.pm', # finds $VERSION
    DISTNAME            => 'Webqq-Encryption',
    LICENSE             => "perl",
    PREREQ_PM         => {
        #"JE"                    => 0,
        "Crypt::RSA"            => 0,
        #"Crypt::OpenSSL::RSA"   => 0,
        #"Crypt::OpenSSL::Bignum"=> 0,
        "Digest::MD5"           => 0,
    }, # e.g., Module::Name => 1.1
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Webqq-Encryption-* MANIFEST' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {     
            repository=>{
                type    => 'git',
                url     => 'git://github.com/sjdy521/Webqq-Encryption.git',
                web     =>  'https://github.com/sjdy521/Webqq-Encryption',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       ABSTRACT       => 'Webqq Login Encryption Library',
       AUTHOR         => 'sjdy521 <sjdy521@163.com>') : ()),
);
