##
# identities.pl - code to manage multiple identities in flail
#
# Time-stamp: <2007-06-11 13:24:28 snl@cluefactory.com>
# $Id: identities.pl,v 1.2 2006/06/29 22:13:31 attila Exp $
#
# Copyright (C) 2006 by Sean Levy <snl@cluefactory.com>.
# All Rights Reserved.
# This file is released under a BSD license.  See the LICENSE
# file that should've come with the flail distribution.
##
# This code provides rudimentary support for multiple identities.
# The main entrypoint is the cmd_be sub, which is hooked to
# the "be" command in dot.flailrc with the line
#
#    flail_defcmd1("be",\&cmd_be,"switch identities, or list available");
#
# This allows you to just say
#
#    flail> be
#
# to get a list of identities (with the current one marked), or
# you can say
#
#    flail> be evil
#
# to select the identity labeled 'evil' in the %IDENTITIES hash.
# See the identities_config.pl example, too, for how to set up
# the data.
##
use vars qw(%ID_SMTP %IDENTITIES $CurrentIdentity);

$CurrentIdentity = undef;

sub is_me {
  my $is_me = 0;
  my @recips;
#  print "is_me raw @_";
  foreach my $recip (@_) {
    my @tmp = split(/,/, $recip);
    foreach my $x (@tmp) {
      $x = addresschomp($x);
#      print "is_me split $x";
      push(@recips, $x);
    }
  }
  foreach my $recip (@recips) {
    foreach my $id (values %IDENTITIES) {
      if (addresses_match($recip, $id)) {
        $is_me = 1;
        last;
      }
    }
    last if $is_me;
  }
  return $is_me;
}

sub list_identities {
  my($regexp) = @_;
  $regexp ||= '.*';
  my @ids = (sort { $a cmp $b } grep { /$regexp/ } keys %IDENTITIES);
  if (!@ids && defined($regexp)) {
    print STDERR qq{no identities match /$regexp/\n};
    return;
  } elsif (!@ids) {
    print STDERR "no identities configured!?\n";
  } else {
    foreach my $id (@ids) {
      my($email,$smtp) = ($IDENTITIES{$id},$ID_SMTP{$id});
      $smtp ||= $ID_SMTP{' default'};
      my $me = (defined($CurrentIdentity) && ($CurrentIdentity eq $id)) ? '* ': '  ';
      print "$me$id: $email => $smtp\n";
    }
  }
}

sub become {
  my($id) = @_;
  unless (exists($IDENTITIES{$id})) {
    foreach my $k (keys %IDENTITIES) {
      if (addresses_match($IDENTITIES{$k},$id)) {
        $id = $k;
        last;
      }
    }
  }
  if (!exists($IDENTITIES{$id})) {
    print qq{become: identity "$id" is not valid\n} unless $Quiet;
    return undef;
  }
  $CurrentIdentity = $id;
  $FromAddress = $IDENTITIES{$id};
  if (exists($ID_SMTP{$id})) {
    my $str = $ID_SMTP{$id};
    if ($str =~ /^!(.*)$/) {
      $SMTPCommand = $1;
      print "$id: using command: $SMTPCommand\n";
    } else {
      $SMTPCommand = '';
      ($SMTPHost,$SMTPPort) = split(/:/,$ID_SMTP{$id});
      $SMTPPort ||= 25;
      print "$id: $FromAddress => $SMTPHost:$SMTPPort\n" unless $Quiet;
    }
  } else {
    ($SMTPHost,$SMTPPort) = split(/:/,$ID_SMTP{' default'});
    $SMTPPort ||= 25;
    print "$id (default): $FromAddress => $SMTPHost:$SMTPPort\n" unless $Quiet;
  }
  return $id;
}

sub cmd_be {
  if (!@_) {
    list_identities();
  } else {
    my($id) = @_;
    become($id) or list_identities();
  }
}

flail_emit(" [Id]") unless $Quiet;

1;

__END__

# Local variables:
# mode: perl
# indent-tabs-mode: nil
# tab-width: 4
# perl-indent-level: 4
# End:
