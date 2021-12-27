package Tripletail::Ini::Group::Annotation;
use strict;
use warnings;
use overload '""' => \&toStr;
use List::MoreUtils qw(any);

# NOTE: Importing Tripletail here leads to a circular dependency so we
# have to break it.
my $TL = $Tripletail::TL;

my %ENABLED_TAGS; # {tag => 1}
my @LOCAL_ADDRS;  # (ipv4addr | ipv6addr)

1;

=encoding utf-8

=head1 NAME

Tripletail::Ini::Group::Annotation - 内部用


=head1 DESCRIPTION

L<Tripletail> によって内部的に使用される。


=head2 METHODS

=over 4

=item C<< Tripletail::Ini::Group::Annotation->setEnabledTags(@tags) >>

=cut

sub setEnabledTags {
    my $class = shift;
    my @tags  = @_;

    %ENABLED_TAGS = map {$_ => 1} @tags;

    return;
}


=item C<< Tripletail::Ini::Group::Annotation->getLocalAddrs() >>

=cut

# The host addresses of the localhost don't change often so they
# should be cached.
sub getLocalAddrs {
    my $class = shift;

    if (!scalar @LOCAL_ADDRS) {
        # THINKME: This is terrible. No OSes other than Linux provide
        # hostname(1) that has the feature we are using here. We
        # should do something equivalent to `hostname -I` not
        # `hostname -i`, but -I is even less portable than -i.
        @LOCAL_ADDRS = $TL->_readcmd("hostname -i 2>&1");
    }
    return @LOCAL_ADDRS;
}


=item C<< new >>

=cut

use fields qw(tag local remote);
sub new {
    my Tripletail::Ini::Group::Annotation $this = shift;
    my $tag                                     = shift;
    my $local                                   = shift;
    my $remote                                  = shift;

    if (!ref $this) {
        $this = fields::new($this);
    }

    $this->{tag   } = $tag;
    $this->{local } = $local;
    $this->{remote} = $remote;

    return $this;
}


=item C<< isEmpty >>

    my $bool = $anno->isEmpty();

Return true iff the annotation object is empty.

=cut

sub isEmpty {
    my Tripletail::Ini::Group::Annotation $this = shift;

    return if defined $this->{tag   };
    return if defined $this->{local };
    return if defined $this->{remote};

    return 1;
}


=item C<< matches >>

=cut

sub matches {
    my Tripletail::Ini::Group::Annotation $this  = shift;
    my Tripletail::Ini::Group             $hosts = shift;

    return if !$this->_matchesTags;
    return if !$this->_matchesLocalAddrs($hosts);
    return if !$this->_matchesRemoteAddr($hosts);

    return 1;
}

sub _matchesTags {
    my Tripletail::Ini::Group::Annotation $this = shift;

    if (defined $this->{tag}) {
        if (!exists $ENABLED_TAGS{ $this->{tag} }) {
            return;
        }
    }

    return 1;
}

sub _matchesLocalAddrs {
    my Tripletail::Ini::Group::Annotation $this  = shift;
    my Tripletail::Ini::Group             $hosts = shift;

    if (defined $this->{local}) {
        my $anno
          = Tripletail::Ini::Group::Annotation->new();
        my $netmask
          = defined $hosts ? $hosts->getVariant($anno)->get($this->{local})
                           : undef;

        if (!defined $netmask) {
            return;
        }

        my @hostaddrs = do {
            if (exists $ENV{SERVER_ADDR}) {
                $ENV{SERVER_ADDR};
            }
            else {
                __PACKAGE__->getLocalAddrs();
            }
        };
        # THINKME: Use NetAddr::IP instead of our re-invented wheel.
        if (!any {$TL->newValue($_)->isIpAddress($netmask)} @hostaddrs) {
            return;
        }
    }

    return 1;
}

sub _matchesRemoteAddr {
    my Tripletail::Ini::Group::Annotation $this  = shift;
    my Tripletail::Ini::Group             $hosts = shift;

    if (defined $this->{remote}) {
        my $anno
          = Tripletail::Ini::Group::Annotation->new();
        my $netmask
          = defined $hosts ? $hosts->getVariant($anno)->get($this->{remote})
                           : undef;

        if (!defined $netmask) {
            return;
        }
        elsif (!exists $ENV{REMOTE_ADDR}) {
            return;
        }
        elsif (!$TL->newValue($ENV{REMOTE_ADDR})->isIpAddress($netmask)) {
            return;
        }
    }

    return 1;
}


=item C<< toStr >>

=cut

sub toStr {
    my Tripletail::Ini::Group::Annotation $this = shift;

    my @parts;
    push @parts,        ':'.$this->{tag   } if defined $this->{tag   };
    push @parts, '@server:'.$this->{local } if defined $this->{local };
    push @parts, '@remote:'.$this->{remote} if defined $this->{remote};

    return join('', @parts);
}


=back


=head1 SEE ALSO

L<Tripletail>


=head1 AUTHOR INFORMATION

Copyright 2006-2013 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

Web site : http://tripletail.jp/

=cut
