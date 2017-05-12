use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/xml-rss-fromhtml-simple-perl',
        },
    }
};
WriteMakefile(
    NAME              => 'XML::RSS::FromHTML::Simple',
    VERSION_FROM      => 'lib/XML/RSS/FromHTML/Simple.pm',
    PREREQ_PM         => {
        LWP => 5.805,
        HTTP::Request::Common => 0,
        XML::RSS => 1.22,
        HTML::Entities => 0,
        HTML::Parser => 3.56,
        URI::URL => 0,
        HTTP::Date => 0,
        DateTime => 0,
        HTML::TreeBuilder => 0,
        Log::Log4perl => 1.0,
        Class::Accessor => 0,
        XML::Simple => 2.16,
        Encode      => 0,
        File::Temp => 0,
        Test::More => 0,
        Data::Hexdumper => 0,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/RSS/FromHTML/Simple.pm',
       AUTHOR         => 'Mike <m@perlmeister.com>') : ()),
);
