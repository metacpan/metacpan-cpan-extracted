use 5.006;

use ExtUtils::MakeMaker;

my $version = '0.97';

#
# The following is needed, because User::Identity does gracefully handle
# a missing Geography::Countries, but is incompatible with older releases.
#

my %prereq;

my ($gc, $gc_version) = (Geography::Countries => 1.4);
eval "require $gc";

if($@ =~ m/^Can't locate/)
{   # Not installed, but it is optional...
}
elsif($@)
{   # Other error message
    warn "Found problems compiling $gc:\n$@";
    $prereq{$gc} = $gc_version;
}
elsif($gc->VERSION < $gc_version)
{   warn "$gc is too old (",$gc->VERSION,"), and needs to be reinstalled\n";
    $prereq{$gc} = $gc_version;
}

WriteMakefile
  ( NAME       => 'User::Identity'
  , VERSION    => $version
  , PREREQ_PM  => \%prereq
  , ABSTRACT   => 'Collect information about a user'
  , AUTHOR     => 'Mark Overmeer <perl@overmeer.net>'
  , LICENSE    => 'perl'
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/userid/raw
DISTDIR         = ../public_html/userid/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2003
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/userid/
PODTAIL         = ../MailBox-shared-podtail

__POSTAMBLE
