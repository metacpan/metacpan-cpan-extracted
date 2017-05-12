###########################################################################
#
# Win32::ASP::Extras - a extension to Win32::ASP that provides more methods
#
# Author: Toby Everett
# Revision: 1.01
# Last Change: Placed all the code in Win32::ASP::Extras, added load time
#              code to patch into the Win32::ASP namespace
###########################################################################
# Copyright 1999, 2000 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
##########################################################################
use Data::Dumper;

use strict;

package Win32::ASP::Extras;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

BEGIN {
  require Exporter;
  require AutoLoader;

  use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

  @ISA = qw(Exporter AutoLoader);
  @EXPORT   = qw( );
  %EXPORT_TAGS = ( );
  @EXPORT_OK = qw ( );
  Exporter::export_ok_tags( ); # Add all strict vars to @EXPORT_OK

  {
    no strict;
    foreach my $i (qw(Set Get FormatURL _FormatURL QueryStringList Redirect MyURL
                      CreatePassURLPair GetPassURL PassURLPair StampPage)) {
      *{"Win32::ASP::$i"} = *{$i};
    }
  }
}

$VERSION='1.01';

#Get and Set have to be preloaded because they use a shared, lexically scoped hash for
#memoization

{

my %memo;

sub Set {
  my($name, $thing) = @_;

  $main::Session->{$name} = Data::Dumper->Dump([$thing], ['thing']);
  exists $memo{$name} and delete $memo{$name};
}

sub Get {
  my($name) = @_;

  unless (exists $memo{$name}) {
    my $string = $main::Session->{$name} or return;
    my $thing;
    eval($string);
    $@ and return;
    $memo{$name} = $thing;
  }
  return $memo{$name};
}

}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Win32::ASP::Extras - a extension to Win32::ASP that provides more methods

=head1 SYNOPSIS

  use Win32::ASP::Extras;

  Win32::ASP::Set('my_hash',
      { fullname => 'Toby Everett',
        username => 'EverettT',
        role => 'Editor'
      } );

  Win32::ASP::Redirect('userinfo.asp', reason => "I just feel like redirecting.");

  exit;



  use Win32::ASP::Extras;

  my $userinfo = Win32::ASP::Get('my_hash');

  foreach my $i (sort keys %{$userinfo}) {
    $main::Response->Write("$i $userinfo->{$i}<P>\n");
  }

  exit;

=head1 DESCRIPTION

=head2 Installation instructions

This installs with MakeMaker.

To install via MakeMaker, it's the usual procedure - download from CPAN,
extract, type "perl Makefile.PL", "nmake" then "nmake install". Don't
do an "nmake test" because the ASP objects won't be available and so won't
work properly.

=head1 Function Reference

=head2 use Win32::ASP::Extras;

This imports the following methods into the Win32::ASP namespace.  There is no need to C<use
Win32::ASP;> in order to C<use Win32::ASP::Extras;>.  The modules are independent of each other
and only share a namespace.

To be more precise, C<use Win32::ASP::Extras'> loads everything into C<Win32::ASP::Extras> and
then aliases the symbol table entries over into C<Win32::ASP>.  This is to avoid any weirdness
with respect to AutoLoader.

=head2 FormatURL Url [, HASH]

This is designed to take a base URL and a hash of parameters and return the properly assembled URL.
It does, however, have some weird behavior.

If the first character of the URL B<is not> a forward slash and C<$main::WEBROOT> is defined, the
function will automatically prepend C<$main::WEBROOT/> to the URL.  This has the side effect of
making 95% of URLs B<absolute> relative to C<$main::WEBROOT>, if it is defined.  This makes it
easier to move Webs around just by changing C<$main::WEBROOT>.

If the first character of the URL B<is> a forward slash, the URL is left unchanged.

If the first characters are "C<./>", the "C<./>" is stripped off and the URL left unchanged.  This
allows one to specify relative URLs - just put a "C<./>" in front of it.

The parameters are URLEncoded, but the keys for them are not.  The resultant parameter list is
HTML encoded so that C<&timestamp> doesn't become C<xtamp> (C<&times;> encodes a multiplication
symbol).

=cut

sub FormatURL {
  my ($url, @params) = @_;

  return $main::Server->HTMLEncode(_FormatURL($url, @params));
}

sub _FormatURL {
  my ($url, @params) = @_;

  ($url !~ /^[\/\.]/ && $main::WEBROOT) and $url = "$main::WEBROOT/$url";
  $url =~ s/^\.\///;

  if (@params) {
    my(@pairs);
    foreach my $i (0..scalar($#params)/2) {
      push(@pairs, $params[$i*2].'='.$main::Server->URLEncode($params[$i*2+1]));
    }
    $url .= '?'.join('&', @pairs);
  }

  return $url;
}

=head2 QueryStringList

This returns a list of QueryString keys and values.  It does B<not> deal with multi-valued
parameters.

=cut

sub QueryStringList {
  my @retval;

  foreach my $key (Win32::OLE::in($main::Request->QueryString)) {
    my $count = $main::Request->QueryString($key)->{Count};
    foreach my $i (1..$count) {
      push(@retval, $key, $main::Request->QueryString($key)->Item($i));
    }
  }
  return (@retval);
}

=head2 Redirect Url [, HASH]

A safe redirect that redirects and then absolutely and positively terminates your program.  If you
thought C<$Response->Redirect> behaved liked die and were disappointed to discover it didn't,
mourn no longer.

It takes a base URL and a hash of parameters.  The URL will be built using C<FormatURL>.

=cut

sub Redirect {
  my ($url, @params) = @_;

  $url = _FormatURL($url, @params);

  $main::Response->Clear;
  $main::Response->Redirect($url);
  $main::Response->Flush;
  $main::Response->End;
  die;
}

=head2 MyURL

This return the URL used to access the current page, including its QueryString.  Because it uses
QueryStringList, it doesn't properly deal with multi-valued parameters.

=cut

sub MyURL {
  my $url = $main::Request->ServerVariables('URL')->item;
  $url = FormatURL($url, QueryStringList());
  return $url;
}

=head2 CreatePassURLPair

The function returns both C<passurl> and the result from calling C<MyURL>.  The return values are
suitable for inclusion in a hash for passing to C<FormatURL>.  The PassURL functions are generally
used for dealing with expired sessions.  If the session expires, the C<Redirect> is passed
C<CreatePassURLPair> for the parameters.  That page then explains to the user what is going on and
has a link back to the login page along with C<PassURLPair>.  The login page can then use
C<GetPassURL> to extract the URL from the QueryString and redirect to that URL.

=cut

sub CreatePassURLPair {
  my $url = $main::Request->ServerVariables('URL')->item;
  $url = _FormatURL($url, QueryStringList());
  return ('passurl', $url);
}

=head2 GetPassURL

This extracts the C<passurl> value from the QueryString.

=cut

sub GetPassURL {
  return $main::Request->QueryString('passurl')->item;
}

=head2 PassURLPair

This returns C<passurl> along with the result from calling C<GetPassURL>.  The return values are
suitable for inclusion in a hash for passing to C<FormatURL>.

=cut

sub PassURLPair {
  return ('passurl', GetPassURL());
}

=head2 StampPage

This returns HTML that says:

  Refresh this page.

The text C<this page> is a link to the results of C<MyURL>.

=cut

sub StampPage {
  my $url = MyURL();
  return "Refresh <A HREF=\"$url\">this page</A>.";
}

=head2 Set

C<Set> and C<Get> can be used to store arbitrary Perl objects in C<$Session>.  It uses
C<Data::Dumper> to store things and C<eval> to retrieve them.  Notice that this is safe B<only>
because B<we> are the only ones who can store stuff in C<$Session>.

<LECTURE_MODE>

Do B<NOT>, I repeat, do B<NOT> use C<Data::Dumper> to serialize a Perl object and then stuff it in
a user's cookie, presuming that you can then use C<eval> to extract it when they pass it back to
you. If you do, you deserve to have someone stuff C<system("del /s *.*")> or some such funny Perl
code in that cookie and then visit your web site.  Never, ever, ever use C<eval> on code that
comes from an untrusted source.  If you need to do so for some strange reason, take a look at the
Safe module, but be careful.

</LECTURE_MODE>

Oh, the call takes two parameters, the name to store it under and the thing to store (can be a
reference to a hash or some other neat goodie).  Keep in mind that references to C<CODE> objects
(i.e. anonymous subroutines) or C<Win32::OLE> objects or anything like that will not make it.

=cut

=head2 Get

Takes a parameter and returns the thing.  Both C<Set> and C<Get> use the same memoization cache to
improve performance.  Take care if you modify the thing you get back from C<Get> - future calls to
C<Get> will return the modified thing (even though it hasn't been changed in C<$Session>).  Calls
to C<Set> empty the memoization cache so that the next call to C<Get> will reload it from
C<$Session> and add it to the cache.

=cut

1;
