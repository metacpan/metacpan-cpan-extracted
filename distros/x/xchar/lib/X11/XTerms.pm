# $Source: /home/keck/lib/perl/X11/RCS/XTerms.pm,v $
# $Revision: 1.5 $$Date: 2007/07/04 17:00:32 $
# Contents
#   1 standard  2 new  3 localhost  4 prefs  5 notes  6 pod

# ----------------------------------------------------------------------

#1# standard

use strict;
use warnings;

package X11::XTerms;

use Carp;
use Data::Dumper;

our $VERSION = 0.2;

# ----------------------------------------------------------------------

#2# new

# X11::XTerms->new;
# X11::XTerms::new;
# X11::XTerms->new(file => 'somefile');
# X11::XTerms::new(file => 'somefile');

# perl -MData::Dumper -MX11::XTerms -e 'print Dumper (X11::XTerms->new)'

sub new {
  shift if @_ % 2;
  my $dotfile;
  { my %args = @_;
    for (keys %args) {
      croak("illegal new() argument '$_'") unless /file/;
      $dotfile = $args{$_};
    }
  }
  $dotfile = "$ENV{HOME}/.xterms" unless defined $dotfile;
  croak("no such file '$dotfile'") unless -f $dotfile;
  my $xterms = do $dotfile;
  croak("failed to read $dotfile") unless $xterms;
  bless $xterms;
}

# ----------------------------------------------------------------------

#3# localhost

require Sys::Hostname;
my $localhost;

sub localhost {
  return $localhost if defined $localhost;
  ($localhost = &Sys::Hostname::hostname) =~ s/\..*//;
  $localhost;
}

# ----------------------------------------------------------------------

#4# prefs

# perl -MData::Dumper -MX11::XTerms \
#   -e 'print Dumper (X11::XTerms->new->prefs)'

sub prefs {
  my $xterms = shift;
  my $inprefs = {};
  my $remotehost;
  for (@_) {
    if (ref) { $inprefs = $_ } else { $remotehost = $_ }
  }
  my %outprefs = %$inprefs;
  $localhost = localhost unless defined $localhost;
  if (
    defined $remotehost &&
    defined $xterms->{$localhost} &&
    defined $xterms->{$localhost}{$remotehost}
  ) {
    for my $key (keys %{$xterms->{$localhost}{$remotehost}}) {
      $outprefs{$key} = $xterms->{$localhost}{$remotehost}{$key}
        unless defined $outprefs{$key};
    }
  }
  if (
    defined $remotehost &&
    defined $xterms->{''} &&
    defined $xterms->{''}{$remotehost}
  ) {
    for my $key (keys %{$xterms->{''}{$remotehost}}) {
      $outprefs{$key} = $xterms->{''}{$remotehost}{$key}
        unless defined $outprefs{$key};
    }
  }
  if (
    defined $xterms->{$localhost} &&
    defined $xterms->{$localhost}{''}
  ) {
    for my $key (keys %{$xterms->{$localhost}{''}}) {
      $outprefs{$key} = $xterms->{$localhost}{''}{$key}
        unless defined $outprefs{$key};
    }
  }
  if (
    defined $xterms->{''} &&
    defined $xterms->{''}{''}
  ) {
    for my $key (keys %{$xterms->{''}{''}}) {
      $outprefs{$key} = $xterms->{''}{''}{$key}
        unless defined $outprefs{$key};
    }
  }
  \%outprefs;
}

# ----------------------------------------------------------------------

1;
__END__

#5# notes

# 1.1
#   started from gen/xterms 7.3

# ----------------------------------------------------------------------

#6# pod

=head1 NAME

X11::XTerms - find xterm attributes in ~/.xterms 

=head1 SYNOPSIS

 require X11::XTerms;
 $xterms = Xterms->new;
 $xterms = Xterms->new(file => 'somefile');

 $prefs = $xterms->prefs;
 $prefs = $xterms->prefs('somehost');
 $inprefs = { rcmd => 'telnet', user => 'bloggs', };
 $outprefs = $xterms->prefs($inprefs);
 $outprefs = $xterms->prefs($inprefs, 'somehost');

=head1 DESCRIPTION

=head1 AUTHOR

Brian Keck E<lt>bwkeck@gmail.comE<gt>

=head1 VERSION

 $Source: /home/keck/lib/perl/X11/RCS/XTerms.pm,v $
 $Revision: 1.5 $
 $Date: 2007/07/04 17:00:32 $
 xchar 0.2

=cut

