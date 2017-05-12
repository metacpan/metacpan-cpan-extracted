# $Id: vpopmail.pm,v 1.12 2001/12/14 03:24:06 sps Exp $
package vpopmail;

use strict; no strict 'subs';
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use FileHandle;
use File::stat;

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     
	     USE_APOP
	     QMAILDIR
	     USE_POP
	     adddomain
	     vdeldomain
	     vadduser
	     vdeluser
	     vpasswd
	     vsetuserquota
	     vauth_user
	     vauth_getpw
	     vauth_setpw
	     vlistusers
	     vlistdomains
	     vaddalias
	     vaddforward
	     vgetdomaindir
	     dotqmail2u	     
);

$VERSION = '0.08';

sub AUTOLOAD {
  # This AUTOLOAD is used to 'autoload' constants from the constant()
  # XS function.  If a constant is not found then control is passed
  # to the AUTOLOAD in AutoLoader.

  my $constname;
  ($constname = $AUTOLOAD) =~ s/.*:://;
  my $val = constant($constname, @_ ? $_[0] : 0);
  if ($! != 0) {
    if ($! =~ /Invalid/) {
      $AutoLoader::AUTOLOAD = $AUTOLOAD;
      goto &AutoLoader::AUTOLOAD;
    }
    else {
      croak "Your vendor has not defined vpopmail macro $constname";
    }
  }
  eval "sub $AUTOLOAD { $val }";
  goto &$AUTOLOAD;
}

bootstrap vpopmail $VERSION;

# Preloaded methods go here.

sub adddomain {

  my ($domain, $dir, $uid, $gid) = @_;

  if (scalar(@_) < 4 ) {

    return vadddomain($domain, VPOPMAILDIR(), VPOPMAILUID(), VPOPMAILGID());

  } else {

    vadddomain(@_);

  }

}


sub vlistusers {

  my $domain = shift();

  my @users = ();

  my $tmpU = vauth_getall($domain, 1, 1);

  push(@users, $tmpU);

  while ($tmpU = vauth_getall($domain, 0, 1) ) {
    push(@users, $tmpU);
  }

  return @users;
}

sub vlistdomains {

  my $assignFile = sprintf("%s/users/assign", QMAILDIR());

  my $fh = new FileHandle $assignFile;

  die("can't open: $assignFile for reading\n") if ! $fh;
  
  my @list = ();
  
  while (defined(my $line = $fh->getline() ) ) {
    
    chomp($line);
    
    last if $line =~ /^\.$/ || ! $line;
    
    my ($domain, $uid, $gid, $dir) = (split(/:/, $line))[1,2,3,4];
    
    if ( $uid == VPOPMAILUID() && $gid == VPOPMAILGID() ) {
      
      push( @list, $domain );
      
    }

  }

  return @list;
  
}


sub vgetdomaindir {

  my $domain = shift();

  return -1 if ! $domain;

  my $assignFile = sprintf("%s/users/assign", QMAILDIR());

  my $fh = new FileHandle $assignFile;

  die("can't open: $assignFile for reading\n") if ! $fh;

  my @list = ();

  while (defined(my $line = $fh->getline() ) ) {

    chomp($line);

    last if $line =~ /^\.$/ || ! $line;

    my ($d, $dir) = (split(/:/, $line))[1,4];

    if ( $domain eq $d ) {

      $fh->close();

      return $dir;

    }

  }

  $fh->close();

}

sub vaddalias {

  my ($user, $domain, $alias) = @_;

  if ($user =~ /[^A-Z_a-z0-9.-]/ ) {

    warn("vaddalias() username contains invalid characters\n");

    return undef;

  }

  if ($alias =~ /[^A-Z_a-z0-9.-]/ ) {

    warn("vaddalias() username contains invalid characters\n");

    return undef;

  }

  $alias =~ s/\./:/g; # translate '.' to ':'

  my $ddir = vgetdomaindir($domain);

  return undef if ! -d $ddir;

  my $pwd = vauth_getpw($user, $domain);

  return undef if ! $pwd;

  my $fname = sprintf("%s/.qmail-%s", $ddir, $alias);

  umask(077);

  my $fh = new FileHandle $fname, O_CREAT|O_WRONLY;

  if (! $fh ) {

    warn "couldn't open: $fname ($!)\n";

    return undef;

  }

  $fh->print("$pwd->{pw_dir}/\n");

  $fh->close();

  undef($fh);

  my $fp = stat($fname);

  if ( $fp->uid() != VPOPMAILUID() || 
       $fp->gid() != VPOPMAILGID() ) {

    chown(VPOPMAILUID(), VPOPMAILGID(), $fname);

  }

}

sub vaddforward {

  my ($user, $domain, $forward) = @_;

  if ( $user =~ /[^A-Z_a-z0-9.-]/ ) {

    warn("vaddforward() username contains invalid characters\n");

    return undef;

  }

  if ($forward !~ /\@/ || $forward =~ /[^A-Z_a-z0-9.-\@]/ ) {

    warn("vaddforward() forward addr contains invalid characters\n");

    return undef;

  }

  $user =~ s/\./:/g; # translate '.' to ':'

  my $ddir = vgetdomaindir($domain);

  my $pwd = vauth_getpw($user, $domain);

  return undef if $pwd; # return if user already exists

  my $fname = sprintf("%s/.qmail-%s", $ddir, $user);

  umask(077);

  my $fh = new FileHandle $fname, O_CREAT|O_WRONLY;

  if (! $fh ) {

    warn "couldn't open: $fname ($!)\n";

    return undef;

  }

  $fh->print("\&$forward");

  $fh->close();

  undef($fh);

  my $fp = stat($fname);

  if ( $fp->uid() != VPOPMAILUID() || 
       $fp->gid() != VPOPMAILGID() ) {

    chown(VPOPMAILUID(), VPOPMAILGID(), $fname);

  }

  return 1;

}


sub getatchars {
  return split(//,vgetatchars());
}

sub dotqmail2u($) {

  my $user = (split(/qmail\-/, shift()))[1];
  print "user: $user\n";
  $user =~ s/\:/./g;

  return $user;

}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for this module.

=head1 NAME

vpopmail - Perl extension for the vpopmail package 

=head1 SYNOPSIS

	use vpopmail;

	print "running vpopmail V", vpopmail::vgetversion(), "\n";

	adddomain('vpopmail.com');

	vadduser('postmaster', 'vpopmail.com', 'p0stmAst3r', 'Postmaster Account', 0 );

	vadduser('username', 'vpopmail.com', 'p@ssw0rd', 'Test User', 0 );

	vdeluser('username', 'vpopmail.com');

	vaddalias('username', 'vpopmail.com', 'alias_address');

	vaddforward('local_addr', 'vpopmail.com', 'some@otherdomain.com');

	if ( vauth_user('username', 'vpopmail.com', 'p@ssw0rd', undef) ) {
		print 'auth ok';
	}

	vsetuserquota('username', 'vpopmail.com', '5M');

	vdeluser('username', 'vpopmail.com') );

	vdeldomain('vpopmail.com');

	foreach my $domain (vlistdomains()) {

		print "$domain:\n";

		foreach my $user (vlistusers($domain)) {

			print "\t$user->{pw_name} ($user->{pw_gecos})\n";
		}
	print "\n\n";
	}


=head1 DESCRIPTION

Perl extension for the vpopmail package
 [ http://www.inter7.com/vpopmail ]


=head1 AUTHOR

Sean P. Scanlon <sscanlon@cpan.org>

=head1 SEE ALSO

perl(1), [ http://www.inter7.com/vpopmail ].

=cut
