use 5.006002;

use strict;
use warnings;

use lib qw{ inc };

use Config;
use ExtUtils::MakeMaker;
use My::Module::Meta;

( my $mmv = ExtUtils::MakeMaker->VERSION() ) =~ s/_//g;

my $meta = My::Module::Meta->new();

$meta->os_check();

my %args = (
    NAME => 'Win32API::File::Time',
    VERSION_FROM => 'lib/Win32API/File/Time.pm',
    PREREQ_PM => $meta->requires(),
    PL_FILES => {},	# Prevent old MakeMaker from running Build.PL
    'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    AUTHOR => 'Tom Wyant (Thomas.R.Wyant-III@usa.dupont.com)',
    ABSTRACT => 'Get and set file times in Windows - including open files',
    realclean	=> { FILES => 'cover_db' },
);

$mmv >= 6.31 and $args{LICENSE} = 'perl';

$mmv >= 6.4501
    and $args{META_MERGE} = $meta->meta_merge();

$mmv >= 6.4701
    and $args{MIN_PERL_VERSION} = $meta->requires_perl;

if ( $mmv >= 6.5501 ) {
    $args{BUILD_REQUIRES} = $meta->build_requires();
} elsif ( $mmv >= 6.4501 ) {
    $args{META_MERGE}{build_requires} = $meta->build_requires();
} else {
    my $build_requires = $meta->build_requires();
    @{ $args{PREREQ_PM} }{ keys %{ $build_requires } } =
	values %{ $build_requires };
}

WriteMakefile(%args);

sub MY::postamble {
    my ( $self, @args ) = @_;

    my $authortest = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(AUTHORTEST_FILES)' );
    $authortest =~ s/ \s+ \z //smx;
    $authortest =~ s/ \A \s+ //smx;
    chomp $authortest;

    return <<"EOD";

AUTHORTEST_FILES = t/*.t xt/author/*.t

authortest :: pure_all
	AUTHOR_TESTING=1 $authortest

testcover :: pure_all
	cover -test -ignore_re=inc/
EOD
}

# ex: set textwidth=72 :
