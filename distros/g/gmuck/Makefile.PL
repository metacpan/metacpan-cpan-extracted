# $Id: Makefile.PL,v 1.10 2004/08/07 23:40:22 scop Exp $

require 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME              => 'gmuck',
              VERSION_FROM      => 'bin/gmuck',
              PREREQ_PM         => { 'Getopt::Long' => 0,
                                     'Carp'         => 0,
                                   },
              EXE_FILES         => ['bin/gmuck'],
              MAN1PODS          => { 'bin/gmuck.pod' =>
                                     '$(INST_MAN1DIR)/gmuck.$(MAN1EXT)',
                                   },
              PL_FILES          => {}, # avoid installing *.PL
              ABSTRACT_FROM     => 'bin/gmuck.pod',
              AUTHOR            => 'Ville Skyttä <ville.skytta at iki.fi>',
              dist              => { TARFLAGS => '--owner=0 --group=0 -cvf' },
             );

# Stuff below happily stolen from libwww-perl :)

package MY;

# Pass gmuck version to pod2man
sub manifypods
{
  my $self = shift;
  my $ver = $self->{VERSION} || "";
  local($_) = $self->SUPER::manifypods(@_);
  s/pod2man\s*$/pod2man --release gmuck-$ver/m;
  $_;
}
