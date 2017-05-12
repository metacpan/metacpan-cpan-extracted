package Test::SSH::Patch::URI::ssh;

use strict;
use warnings;
no warnings 'redefine';
require URI::Escape;

require URI::ssh;
unless (URI::ssh->can('c_params')) {
    package
        URI::ssh; # don't index me PAUSE!

    *sshinfo = sub {
        my $self = shift;
        my $old = $self->authority;

        if (@_) {
            my $new = $old;
            $new = "" unless defined $new;
            $new =~ s/.*@//;  # remove old stuff
            my $si = shift;
            if (defined $si) {
                $si =~ s/@/%40/g;   # protect @
                $new = "$si\@$new";
            }
            $self->authority($new);
        }
        return undef if !defined($old) || $old !~ /(.*)@/;
        return $1;
    };

    *userinfo = sub {
        my $self = shift;
        my $old = $self->sshinfo;

        if (@_) {
            my $new = $old;
            $new = "" unless defined $new;
            $new =~ s/^[^;]*//;  # remove old stuff
            my $ui = shift;
            if (defined $ui) {
                $ui =~ s/;/%3B/g;   # protect ;
                $new = "$ui$new";
            }
            else {
                $new = undef unless length $new;
            }
            $self->sshinfo($new);
        }
        return undef if !defined($old) || $old !~ /^([^;]+)/;
        return $1;
    };

    *c_params = sub {
        my $self = shift;
        my $old = $self->sshinfo;
        if (@_) {
            my $new = $old;
            $new = "" unless defined $new;
            $new =~ s/;.*//; # remove old stuff
            my $cp = shift;
            $cp = [] unless defined $cp;
            $cp = [$cp] unless ref $cp;
            if (@$cp) {
                my @cp = @$cp;
                for (@cp) {
                    s/%/%25/g;
                    s/,/%2C/g;
                    s/;/%3B/g;
                }
                $new .= ';' . join(',', @cp);
            }
            else {
                $new = undef unless length $new;
            }
            $self->sshinfo($new);
        }
        return undef if !defined($old) || $old !~ /;(.+)/;
        [map URI::Escape::uri_unescape($_), split /,/, $1];
    }
};

1;
