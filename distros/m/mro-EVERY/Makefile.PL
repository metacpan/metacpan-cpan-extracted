# even the old version is guaranteed not to work
# with anything earlier than 5.008.

use 5.024;

use ExtUtils::MakeMaker;

WriteMakefile
(
    qw
    (
        NAME            mro::EVERY
        LICENSE         perl
    ) 
  , VERSION_FROM	=> 'lib/mro/EVERY.pm'
  , ABSTRACT_FROM	=> 'lib/mro/EVERY.pm'
  , AUTHOR          => 'Steven Lembark <lembark@wrkhors.com>'
  , PREREQ_PM       =>
    {
        # standard distro, particular versions
        # are unlikely to cause pain.

        qw
        (

			mro			0
            Carp        0
            List::Util  1.45
            Symbol      0
        )
    }
);

__END__
