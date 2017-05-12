package WebService::CaptchasDotNet;

use 5.006;

use strict;
use warnings FATAL => qw(all);

use Digest::MD5 qw(md5 md5_hex);
use File::Spec ();
use File::Path qw(mkpath);
use File::Find qw(find);
use IO::File ();
use IO::Dir ();

our $VERSION = 0.06;

our $DEBUG = 0;

#---------------------------------------------------------------------
# precompute some static variables to help persistent environments
# like mod_perl :)
#---------------------------------------------------------------------

my @letters = 'a'..'z';

my @characters;

foreach my $char (33 .. 126) {
  push @characters, chr $char;
}


#---------------------------------------------------------------------
# constructor
#---------------------------------------------------------------------
sub new {

  my $class = shift;

  my %args = @_;

  my $self = { _secret => $args{secret},
               _uid    => $args{username},
               _expire => $args{expire} || 3600,
             };

  bless $self, $class;

  $self->_init;

  return $self;
}


#---------------------------------------------------------------------
# expire accessor
#---------------------------------------------------------------------
sub expire {

  my $self = shift;

  $self->{_expire} = shift if @_;

  return $self->{_expire};
}


#---------------------------------------------------------------------
# verify routine
# make sure user input matches the captcha
#---------------------------------------------------------------------
sub verify {

  my $self = shift;

  my ($input, $random) = @_;

  my $secret = $self->{_secret};

  # basic sanity checking

  unless ($secret && $random && $input && $input =~ m/^[a-z]{6}$/ ) {
    print STDERR join ' ', 'WebService::CaptchasDotNet - ',
                           "insufficient data for verify()\n"
      if $DEBUG;

    return;
  }

  # make sure that the random string is sane
  my $file = $self->_verify_random_string($random);

  return unless $file;

  # now for the computation - this is what
  # the captcha image should really be
  my $decode = substr(md5(join '', $secret, $random), 0, 6);

  my $captcha = '';

  foreach my $byte (split //, $decode) {
    $captcha .= $letters[ord($byte) % 26];
  }

  if ($input eq $captcha) {

    # a random string can only be used once - cleanup
    unlink $file;

    return 1;
  }

  return;
}


#---------------------------------------------------------------------
# random string generator
#---------------------------------------------------------------------
sub random {

  my $self = shift;

  my $string = join '', @characters[rand 64, rand 64, rand 64, rand 64,
                                    rand 64, rand 64, rand 64, rand 64,
                                    rand 64, rand 64, rand 64, rand 64,
                                    rand 64, rand 64, rand 64, rand 64,
                                    rand 64, rand 64, rand 64, rand 64,
                                    rand 64, rand 64, rand 64, rand 64,
                                    rand 64, rand 64, rand 64, rand 64,
                                    rand 64, rand 64, rand 64, rand 64,
                                    rand 64, rand 64, rand 64, rand 64,
                                    rand 64, rand 64, rand 64, rand 64,
                                   ];

  # hmph, I can't seem to localize md5_hex() in my tests...
  my $random = Digest::MD5->new->add($string)->hexdigest;

  my $tempdir = $self->{_tempdir};

  my $file = File::Spec->catfile($tempdir, $random);

  if (-e $file) {
    print STDERR join ' ', 'WebService::CaptchasDotNet - ',
                           "collision found for '$random'\n"
      if $DEBUG;

    return;
  }

  my $fh = IO::File->new(">$file");

  unless ($fh) {
    print STDERR join ' ', 'WebService::CaptchasDotNet - ',
                           "could not create '$file': $!\n"
      if $DEBUG;

    return;
  }

  undef $fh;

  return $random;
}


#---------------------------------------------------------------------
# present a suitable url for html pages
#---------------------------------------------------------------------
sub url {

  my $self = shift;

  my $random = shift;

  my $user = $self->{_uid};

  return "http://image.captchas.net/?client=$user&amp;random=$random";
}


#---------------------------------------------------------------------
# private initialization routine
#---------------------------------------------------------------------
sub _init {

  my $self = shift;

  # create a temporary filesystem to store used random strings

  my $tmp = File::Spec->catfile(File::Spec->tmpdir,
                                'CaptchasDotNet');

  mkpath $tmp unless -d $tmp;

  $self->{_tempdir} = $tmp;

  $self->_cleanup;
}


#---------------------------------------------------------------------
# check to make sure the random string passed to verify()
# is one we recently generated
#---------------------------------------------------------------------
sub _verify_random_string {

  my $self = shift;

  my $random = shift;

  # untaint
  ($random) = $random =~ m!^([0-9a-z-A-Z]{32})$!
    if $random;

  unless ($random) {

    print STDERR join ' ', 'WebService::CaptchasDotNet - ',
                           "unable to verify invalid random string\n"
      if $DEBUG;

    return;
  }

  my $file = File::Spec->catfile($self->{_tempdir}, $random);

  unless (-e $file) {

    print STDERR join ' ', 'WebService::CaptchasDotNet - ',
                           "sanity file $file not found\n"
      if $DEBUG;

    return;
  }

  if ($self->_time_to_cleanup($file)) {

    print STDERR join ' ', 'WebService::CaptchasDotNet - ',
                           "sanity file $file too old\n"
      if $DEBUG;

    unlink $file;

    return;
  }

  return $file;
}

sub _cleanup {

  my $self = shift;

  my $dir = $self->{_tempdir};

  my $dh = IO::Dir->new($dir);

  if ($dh) {
    print STDERR join ' ', 'WebService::CaptchasDotNet - ',
                           "cleaning up stale entries in $dir\n"
      if $DEBUG;

    foreach my $entry ($dh->read) {

      # untaint
      ($entry) = $entry =~ m!^([0-9a-z-A-Z]{32})$!;

      next unless $entry;

      my $file = File::Spec->catfile($dir, $entry);

      unlink $file if $self->_time_to_cleanup($file); 
    } 

    return 1;
  }

  print STDERR join ' ', 'WebService::CaptchasDotNet - ',
                         "cannot open cache directory $dir - $!\n"
    if $DEBUG;

  return;
}

sub _time_to_cleanup {

  my $self = shift;

  my $file = shift;

  my $mtime = (stat $file)[9];

  if ($mtime && $mtime + $self->{_expire} < time) {

    print STDERR join ' ', 'WebService::CaptchasDotNet - ',
                           "$file created at $mtime ready for cleanup\n"
      if $DEBUG;

    return 1;
  }

  return;
}

1;

__END__

=head1 NAME 

WebService::CaptchasDotNet - routines for captchas.net free captcha service

=head1 SYNOPSIS

  # create the object
  my $o = WebService::CaptchasDotNet->new(secret   => 'secret',
                                          username => 'demo');

  # generate a random string for this image url
  # note you _must_ use $o->random() and cannot supply
  # your own random string!
  my $random = $o->random;

  # generate an image url
  my $url = $o->url($random);

  # verify that the typed captcha and image are a match
  my $ok = $o->verify($user_input, $random);

=head1 DESCRIPTION

WebService::CaptchasDotNet contains several useful routines for using the
free captcha service at http://captchas.net.

to use these routines you will need to visit http://captchas.net and
register with them.  they will provide you with a username and a
shared secret key that you will need for these routines to work.

=head1 CONSTRUCTOR

=over 4

=item new()

instantiate a new WebService::CaptchasDotNet object.

  my $o = WebService::CaptchasDotNet->new(secret   => 'secret',
                                          username => 'demo',
                                          expire   => 1800);

the constructor arguments are as follows

=over 4

=item secret

the secret key assigned to you when you registered with the
captchas.net service.  this argument is required.

=item username

the username assigned to you when you registered with the
captchas.net service.  this argument is required

=item expire

the time, in seconds, after which a cached random strings should
be invalidated.  see the random() documentation below for more
details.  this argument is optional and defaults to 3600 seconds.

=back

if the required arguments are not given you will get still get
a valid object back but verify() will always fail.

to minimize overhead in persistent environments like mod_perl you
can construct a single object at the package level and hold on to
it for the rest of your processing.

=back

=head1 METHODS

=over 4

=item verify()

this is the heart of the interface, the verification routine.
basically it takes the captcha phrase that the user entered and
checks whether it matches the image presented by captchas.net.

  my $ok = $o->verify($user_input, $random);

here '$user_input' is what the user keyed in, and '$random'
is the random string you attached to the captchas.net URL.  for
example, if the URL you presented on the webpage was

  http://image.captchas.net?client=demo&random=RandomZufall

then the call would look like

  my $ok = $o->verify($user_input, 'RandomZufall');

so basically you need to keep track of the random string
yourself between calls in some stateful manner.  personally,
I use hidden form fields, but YMMV.

keep in mind that the verify() and random() methods are
tightly linked - you must pass verify() a random string
generated with the random() method and cannot just use
any random random string.  see the random() documentation
below for the details.

verify() returns true if the user correctly identified the
captcha image string and false otherwise.

=item random()

random() is a utility method that will generate random strings for
you.  

  my $random = $o->random;

the random() and verify() methods are linked such that only 
random strings generated with random() will cause verify() to
return true.  here's why...

suppose a would be hacker was presented with your captcha image
and recorded the image url, complete with the random string.  the
hacker could then use the same random string to programatically fake
subsequent requests, mucking with your system.  therefore the random
string needs to be verified by you once and only once to make certain
there is a human on the other end.  for the really paranoid the
random string should be received within a set time limit after it 
was been generated.  the union of random() and verify() takes care of
both of these needs.

when random() is called it stores the random string in a cache on
the filesystem.  verify() then checks for the existence of the file,
makes sure it isn't stale, and removes it if the user input was good.
only if the file exists and is recent will verify() succeed,
regardless of whether the user input passes the captchas.net
algorithm.  if the user input was bad (such as a genuinely mis-typed
response) the file will remain on the filesystem so the user can
try again without completely refreshing the page.  at least until the
file is deemed stale.

the random() cache lives in $TMPDIR/CaptchasDotNet/ by default,
where $TMPDIR is defined via File::Spec->tmpdir().

the caveat to this random() implementation is that it is filesystem
based so if you are in a clustered environment with no shared mount
points there is the strong possibility the box that serves the random
string will not be the one to verify it later, causing legitimate
matches to fail.  in this case you might want to subclass
WebService::CaptchasDotNet, override _init(), and choose a different
path for your cache files.

=item url()

generate a suitable captchas.net URL for embedding within a webpage.

  my $url = $o->url($random);

the returned URL will have both the passed random string and the
username provided with the class constructor embedded within it.
for example

  my $o = WebService::CaptchasDotNet->new(secret   => 'secret',
                                          username => 'demo');

  my $random = 'RandomZufall';

  # http://image.captchas.net?client=demo&amp;random=RandomZufall
  my $url = $o->url($random);

it is important to note that the returned URL is encoded for
proper display on a webpage, meaning the ampersand itself is
encoded.  this makes sure your generated pages remain valid xhtml :)

=item expire()

set the time (in seconds) after which a random string should expire
from the cache:

  $o->expire(1800);

the expire time defaults to 3600 seconds, which would give a user
60 minutes to validate themselves.

=back

=head1 DEBUGGING

if you are interested in verbose error messages when something 
doesn't go according to plan you can enable debugging as follows:

  use WebService::CaptchasDotNet;
  $WebService::CaptchasDotNet::DEBUG = 1;

=head1 SEE ALSO

http://captchas.net/

=head1 AUTHOR

Geoffrey Young <geoff@modperlcookbook.org>

=head1 COPYRIGHT

Copyright (c) 2005, Geoffrey Young
All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
