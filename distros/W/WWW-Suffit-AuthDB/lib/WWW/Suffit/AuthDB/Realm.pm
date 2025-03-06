package WWW::Suffit::AuthDB::Realm;
use strict;
use utf8;

=encoding utf8

=head1 NAME

WWW::Suffit::AuthDB::Realm - WWW::Suffit::AuthDB realm class

=head1 SYNOPSIS

    use WWW::Suffit::AuthDB::Realm;

=head1 DESCRIPTION

This module provides AuthDB realm methods

=head1 ATTRIBUTES

This class implements the following attributes

=head2 cached

    $realm = $realm->cached( 12345.123456789 );
    my $cached = $realm->cached;

Sets or returns time of caching realm data

Default: 0

=head2 cachekey

    $realm = $realm->cachekey( 'abcdef1234567890' );
    my $cachekey = $realm->cachekey;

Sets or returns the cache key string

=head2 description

    $realm->description('Root page');
    my $description = $realm->description;

Sets and returns description of the realm

=head2 error

    $realm = $realm->error( 'Oops' );
    my $error = $realm->error;

Sets or returns error string

=head2 expires

    $realm = $realm->expires( 300 );
    my $expires = $realm->expires;

Sets or returns cache/object expiration time in seconds

Default: 300 (5 min)

=head2 id

    $realm = $realm->id( 2 );
    my $id = $realm->id;

Sets or returns id of realm

Default: 0

=head2 is_cached

This attribute returns true if the realm data was cached

Default: false

=head2 realm

    $realm->realm('string');
    my $real_string = $realm->realm;

Sets and returns realm string of the realm object

=head2 realmname

    $realm->realmname('root');
    my $realmname = $realm->realmname;

Sets and returns realmname of the realm object

=head2 requirements

    $realm->requirements(['@alice', '%wheel']);
    my $requirements = $relam->requirements; # ['@alice', '%wheel']

Sets and returns groups and users of realm (array of users and groups)

B<Note!> Usernames should be prefixed with "B<@>", group names should be prefixed with "B<%>"

=head2 requires_users

    my $reqs = $relam->requires; # [ {user => 'alice'}, { group => 'wheel'} ]

Returns list of requiremets (as array ref) that allows access to specified realm

=head2 satisfy

    $realm->satisfy('Any');
    my $satisfy = $realm->satisfy;

Sets and returns the satisfy policy (All, Any) of the realm object

=head1 METHODS

This class inherits all methods from L<Mojo::Base> and implements the following new ones

=head2 is_valid

    $realm->is_valid or die "Incorrect realm";

Returns boolean status of realm's data

=head2 mark

Marks object as cached

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<WWW::Suffit::AuthDB>, L<Mojolicious>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use Mojo::Base -base;

use Mojo::Util qw/steady_time/;

use WWW::Suffit::RefUtil qw/is_integer/;

use Net::IP qw//;

use Socket qw/inet_aton AF_INET/;

has description => '';
has error       => '';
has expires     => 0;
has id          => 0;
has realm       => undef;
has realmname   => undef;
has satisfy     => undef;
has requirements=> sub { return {} }; # Segregated requirements
has is_cached   => 0;
has cached      => 0; # steady_time() of cached
has cachekey    => '';

sub is_valid {
    my $self = shift;

    # No id found? -- is ok too
    return 1 unless $self->id;

    unless (defined($self->realmname) && length($self->realmname)) {
        $self->error("E1317: Incorrect realmname");
        return 0;
    }
    if ($self->expires && $self->expires < time) {
        $self->error("E1318: The realm data is expired");
        return 0;
    }

    return 1;
}
sub mark {
    my $self = shift;
    return $self->is_cached(1)->cached(shift || steady_time);
}

sub _check_by_default {
    my $self = shift;
    my $reqs = $self->requirements->{'Default'} // [];
    my $status = 0; # false by default
    foreach my $r (@$reqs) {
        my $ent = lc($r->{entity});
        if ($ent eq 'allow') {
            $status++;
        } elsif ($ent eq 'deny') {
            $status--;
        }
    }

    return ($status > 0) ? 1 : 0;
}
sub _check_by_usergroup {
    my $self = shift;
    my $username = shift;
    my $groupnames = shift // []; # Is array of groups
       $groupnames = [$groupnames] unless ref($groupnames);
    my $reqs = $self->requirements->{'User/Group'} // [];
    my $vu = 0; # false by default
    my $status = 0; # false by default
    return -1 unless scalar(@$reqs); # Skip if no requirements exists
    foreach my $r (@$reqs) {
        my $ent = lc($r->{entity});
        if ($ent eq 'user') {
            $status++ if _op('str', $username, $r->{op}, $r->{value});
        } elsif ($ent eq 'group') {
            foreach my $g (@$groupnames) {
                $status++ if _op('str', $g, $r->{op}, $r->{value});
            }
        } elsif ($ent eq 'valid-user') {
            $vu = 1;
        }
    }
    return $status ? 1 : $vu;
}
sub _check_by_host {
    my $self = shift;
    my $ip = shift // '';
    my $reqs = $self->requirements->{'Host'} // [];
    my $status = 0; # false by default
    return -1 unless scalar(@$reqs); # Skip if no requirements exists
    return 0 unless length($ip); # No ip specified
    foreach my $r (@$reqs) {
        my $ent = lc($r->{entity});
        if ($ent eq 'ip') {
            $status++ if _op('ip', $ip, $r->{op}, $r->{value});
        } elsif ($ent eq 'host') {
            my $host = gethostbyaddr(inet_aton($ip), AF_INET) // '';
            next unless length($host);
            $status++ if _op('str', $host, $r->{op}, $r->{value});
        }
    }

    return $status;
}
sub _check_by_env {
    my $self = shift;
    my $reqs = $self->requirements->{'Env'} // [];
    my $status = 0; # false by default
    return -1 unless scalar(@$reqs); # Skip if no requirements exists
    foreach my $r (@$reqs) {
        my $varname = uc($r->{entity});
        next unless length($varname);
        my $varval  = exists($ENV{$varname}) && defined($ENV{$varname}) ? $ENV{$varname} : '';
        $status++ if _op(is_integer($varval) ? 'int' : 'str', $varval, $r->{op}, $r->{value});
    }

    return $status;
}
sub _check_by_header {
    my $self = shift;
    my $cb = shift // sub { undef };
    return 0 unless ref($cb) && ref($cb) eq 'CODE';
    my $reqs = $self->requirements->{'Header'} // [];
    my $status = 0; # false by default
    return -1 unless scalar(@$reqs); # Skip if no requirements exists
    foreach my $r (@$reqs) {
        my $hkey = $r->{entity};
        next unless length($hkey);
        my $hval = $cb->($hkey) // '';
        $status++ if _op(is_integer($hval) ? 'int' : 'str', $hval, $r->{op}, $r->{value});
    }

    return $status;
}

sub _op { # rule, test (from user), op, value (from db, requirements)
    my $rule = shift || 'str'; # str, int, ip
    my $tst = shift; # from user
    my $op = shift || 'eq';
    my $val = shift; # from db, requirements

    # IP
    my ($subnet, $ip);
    if ($rule eq 'ip') {
        $subnet = Net::IP->new($val) or warn(sprintf("Incorrect Network/CIDR: %s", Net::IP::Error()));
        $ip     = Net::IP->new($tst) or warn(sprintf("Incorrect client IP: %s", Net::IP::Error()));
        return 0 unless defined($subnet) && defined($ip);
    }

    # Op
    if ($op eq 'eq') { # operator => '==', title => 'equal to'
        if ($rule eq 'str') {
            return defined($tst) && defined($val) && $tst eq $val;
        } elsif ($rule eq 'int') {
            return is_integer($tst) && is_integer($val) && $tst == $val;
        } elsif ($rule eq 'ip') {
            return $subnet->overlaps($ip) ? 1 : 0;
        }
    } elsif ($op eq 'ne') { # operator => '!=', title => 'not equal'
        if ($rule eq 'str') {
            return defined($tst) && defined($val) && $tst ne $val;
        } elsif ($rule eq 'int') {
            return is_integer($tst) && is_integer($val) && $tst != $val;
        } elsif ($rule eq 'ip') {
            return $subnet->overlaps($ip) ? 0 : 1;
        }
    } elsif ($op eq 'gt') { # operator => '>',  title => 'greater than'
        if ($rule eq 'str') {
            return defined($tst) && defined($val) && $tst gt $val;
        } elsif ($rule eq 'int') {
            return is_integer($tst) && is_integer($val) && $tst > $val;
        } elsif ($rule eq 'ip') {
            return $subnet->bincomp($op, $ip) ? 1 : 0;
        }
    } elsif ($op eq 'lt') { # operator => '<',  title => 'less than'
        if ($rule eq 'str') {
            return defined($tst) && defined($val) && $tst lt $val;
        } elsif ($rule eq 'int') {
            return is_integer($tst) && is_integer($val) && $tst < $val;
        } elsif ($rule eq 'ip') {
            return $subnet->bincomp($op, $ip) ? 1 : 0;
        }
    } elsif ($op eq 'ge') { # operator => '>=', title => 'greater than or equal to'
        if ($rule eq 'str') {
            return defined($tst) && defined($val) && $tst ge $val;
        } elsif ($rule eq 'int') {
            return is_integer($tst) && is_integer($val) && $tst >= $val;
        } elsif ($rule eq 'ip') {
            return $subnet->bincomp($op, $ip) ? 1 : 0;
        }
    } elsif ($op eq 'le') { # operator => '<=', title => 'less than or equal to'
        if ($rule eq 'str') {
            return defined($tst) && defined($val) && $tst le $val;
        } elsif ($rule eq 'int') {
            return is_integer($tst) && is_integer($val) && $tst <= $val;
        } elsif ($rule eq 'ip') {
            return $subnet->bincomp($op, $ip) ? 1 : 0;
        }
    } elsif ($op eq 're') { # operator => '=~', title => 'regexp match'
        return 0 unless defined($tst) && length($tst);
        return 0 unless defined($val) && length($val);
        my $vre = qr/$val/;
        if ($rule eq 'str') {
            return $tst =~ $vre;
        } elsif ($rule eq 'int') {
            return $tst =~ $vre;
        } elsif ($rule eq 'ip') {
            return $tst =~ $vre;
        }
    } elsif ($op eq 'rn') { # operator => '!~', title => 'regexp not match'
        return 0 unless defined($tst) && length($tst);
        return 0 unless defined($val) && length($val);
        my $vre = qr/$val/;
        if ($rule eq 'str') {
            return $tst !~ $vre;
        } elsif ($rule eq 'int') {
            return $tst !~ $vre;
        } elsif ($rule eq 'ip') {
            return $tst =~ $vre;
        }
    }

    return 0; # False by default
}

1;

__END__
