
=head1 NAME

Test::Dir::Base - support functions for Test::Dir and Test::Folder

=head1 DESCRIPTION

This module is not meant to be human-readable.
Use Test::Dir or Test::Folder.

=head1 AUTHOR

Martin 'Kingpin' Thurn, C<mthurn at cpan.org>, L<http://tinyurl.com/nn67z>.

=cut

package Test::Dir::Base;

our
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

use Test::Builder;

my $Test = new Test::Builder;
our $directory = q{directory};
our $dir = q{dir};
our $Directory = q{Directory};
our $Dir = q{Dir};

# All functions start with underscore so that Test::Pod::Coverage does
# not complain about lack of pod.

sub _declare
  {
  my $iOK = shift || 0;
  my $sName = shift || q{};
  my $sDiag = shift || q{};
  if ($iOK)
    {
    $Test->ok(1, $sName);
    }
  else
    {
    $Test->diag($sDiag);
    $Test->ok(0, $sName);
    }
  } # _declare

sub _dir_exists_ok
  {
  my $sDir = shift;
  my $sName = shift || "$dir $sDir exists";
  my $iOK = -d $sDir;
  _declare($iOK, $sName, qq{$directory [$sDir] does not exist});
  } # _dir_exists_ok

sub _dir_not_exists_ok
  {
  my $sDir = shift;
  my $sName = shift || "$dir $sDir does not exist";
  my $iOK = ! -d $sDir;
  _declare($iOK, $sName, qq{$directory [$sDir] does not exist});
  } # _dir_not_exists_ok

sub _dir_empty_ok
  {
  my $sDir = shift;
  my $sName = shift || "$dir $sDir is empty";
  my $iOK = -d $sDir && _dir_is_empty($sDir);
  _declare($iOK, $sName, qq{$directory [$sDir] is not empty});
  } # _dir_empty_ok

sub _dir_not_empty_ok
  {
  my $sDir = shift;
  my $sName = shift || "$dir $sDir is not empty";
  my $iOK = -d $sDir && ! _dir_is_empty($sDir);
  _declare($iOK, $sName, qq{$directory [$sDir] is empty});
  } # _dir_empty_ok

sub _dir_is_empty
  {
  my $path = shift || return;
  my $iRet = 1;
  opendir DIR, $path or die;
 READDIR:
  while (my $entry = readdir DIR)
    {
    next READDIR if ($entry =~ m/\A\.\.?\z/);
    $iRet = 0;
    last READDIR;
    } # while
  closedir DIR;
  return $iRet;
  } # _dir_is_empty

sub _dir_readable_ok
  {
  my $sDir = shift;
  my $sName = shift || "$dir $sDir is readable";
  my $iOK = -d $sDir && -r $sDir;
  _declare($iOK, $sName, qq{$directory [$sDir] is not readable});
  } # _dir_readable_ok

sub _dir_not_readable_ok
  {
  my $sDir = shift;
  my $sName = shift || "$dir $sDir is not readable";
  my $iOK = -d $sDir && ! -r $sDir;
  _declare($iOK, $sName, qq{$directory [$sDir] is readable});
  } # _dir_not_readable_ok

sub _dir_writable_ok
  {
  my $sDir = shift;
  my $sName = shift || "$dir $sDir is writable";
  my $iOK = -d $sDir && -w $sDir;
  _declare($iOK, $sName, qq{$directory [$sDir] is not writable});
  } # _dir_writable_ok

sub _dir_not_writable_ok
  {
  my $sDir = shift;
  my $sName = shift || "$dir $sDir is not writable";
  my $iOK = -d $sDir && ! -w $sDir;
  _declare($iOK, $sName, qq{$directory [$sDir] is writable});
  } # _dir_not_writable_ok

sub _dir_executable_ok
  {
  my $sDir = shift;
  my $sName = shift || "$dir $sDir is executable";
  my $iOK = -d $sDir && -x $sDir;
  _declare($iOK, $sName, qq{$directory [$sDir] is not executable});
  } # _dir_executable_ok

sub _dir_not_executable_ok
  {
  my $sDir = shift;
  my $sName = shift || "$dir $sDir is not executable";
  my $iOK = -d $sDir && ! -x $sDir;
  _declare($iOK, $sName, qq{$directory [$sDir] is executable});
  } # _dir_not_executable_ok

1;

__END__
