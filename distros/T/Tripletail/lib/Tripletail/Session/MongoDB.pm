package Tripletail::Session::MongoDB;
use strict;
use warnings;
use Tripletail;
use base 'Tripletail::Session';

use fields qw(dbgroup session_ns);
sub __new {
    my Tripletail::Session::MongoDB $this = shift;

    if (!ref $this) {
        $this = fields::new($this);
        $this->SUPER::__new(@_);
    }

    $this->{dbgroup   } = $TL->INI->get($this->{group} => 'dbgroup');
    $this->{session_ns} = $TL->INI->get($this->{group} => 'session_ns');

    return $this;
}

sub _createSessionTable {
    my Tripletail::Session::MongoDB $this = shift;

    $TL->getMongoDB($this->{dbgroup})->do(sub {
        my $client = shift;
        my $ns     = $client->get_namespace($this->{session_ns});

        # Our collection would look like this:
        # {
        #     _id: <objectid>, # sid
        #     v:   <integer>,  # checkval
        #     s:   <integer>,  # checkvalssl
        #     d:   <objectid>, # data
        #     u:   <datetime>  # updatetime
        # }

        # We don't need to create a collection explicitly. Only need
        # to create indices.
        $ns->database->run_command([
            createIndexes => $ns->name,
            indexes       => [
                {
                    key  => {u => 1},
                    name => 'u_1',
                },
               ],
           ]);
    });

    return $this;
}

sub _insertSid {
    my Tripletail::Session::MongoDB $this = shift;
    my $checkval    = shift;
    my $checkvalssl = shift;
    my $data        = shift;

    return $TL->getMongoDB($this->{dbgroup})->do(sub {
        my $client = shift;
        my $ns     = $client->get_namespace($this->{session_ns});
        my $result = $ns->insert_one({
            v => $checkval,
            s => $checkvalssl,
            d => defined $data ? MongoDB::OID->new($data) : undef,
            u => Time::Moment->now
           });
        return $result->inserted_id->to_string;
    });
}

sub _updateSession {
    my Tripletail::Session::MongoDB $this = shift;

    if (!defined $this->{updatetime}) {
        # No sessions has been created yet?
        return $this;
    }

    if (time - $this->{updatetime} < $this->{updateinterval_period}) {
        # Too early to update it.
        return $this;
    }

    $TL->getMongoDB($this->{dbgroup})->do(sub {
        my $client = shift;
        my $ns     = $client->get_namespace($this->{session_ns});

        $ns->update_one(
            { _id    => MongoDB::OID->new($this->{sid}) },
            { '$set' => {
                d => defined $this->{data} ? MongoDB::OID->new($this->{data}) : undef,
                u => Time::Moment->now
              }
            });
    });

    my $datalog = (defined($this->{data}) ? $this->{data} : '(undef)');
    if ($TL->INI->get($this->{group} => 'logging', '0')) {
        $TL->log(__PACKAGE__, "The session got updated: sid [$this->{sid}] data [$datalog]");
    }

    return $this;
}

sub _loadSession {
    my Tripletail::Session::MongoDB $this = shift;
    my $sid      = shift;
    my $checkval = shift;
    my %opts     = @_;

    my $doc = $TL->getMongoDB($this->{dbgroup})->do(sub {
        my $client = shift;
        my $ns     = $client->get_namespace($this->{session_ns});

        # NOTE: We really don't want to load stale sessions from
        # secondary servers but it's an user's choice we have no
        # control, i.e. MongoDB::ReadPreference
        $ns->find_one({
            _id                         => MongoDB::OID->new($sid),
            ($opts{secure} ? 's' : 'v') => $checkval,
        });
    });

    if (!defined $doc) {
        if ($TL->INI->get($this->{group} => 'logging', '0')) {
            $TL->log(__PACKAGE__, "The session is invalid: its session ID may not exist, or the checkval is invalid for the session: sid [$sid] checkval [$checkval]");
        }
    }
    elsif (time - $doc->{u}->epoch > $this->{timeout_period}) {
        if ($TL->INI->get($this->{group} => 'logging', '0')) {
            $TL->log(__PACKAGE__, "The session is invalid: it has been expired: sid [$sid] checkval [$checkval] updatetime [$doc->{u}]");
        }
    }
    else {
        $this->{sid        } = $sid;
        $this->{data       } = defined $doc->{d} ? $doc->{d}->to_string : undef;
        $this->{updatetime } = $doc->{u}->epoch;
        $this->{checkval   } = $doc->{v};
        $this->{checkvalssl} = $doc->{s};
    }

    if (defined $this->{sid}) {
        my $datalog = (defined($this->{data}) ? $this->{data} : '(undef)');
        if ($TL->INI->get($this->{group} => 'logging', '0')) {
            $TL->log(__PACKAGE__, "Succeeded to read a valid session data. secure [$opts{secure}] sid [$this->{sid}] checkval [$this->{checkval}] checkvalssl [$this->{checkvalssl}] data [$datalog] updatetime [$this->{updatetime}]");
        }
    }
    else {
        if ($TL->INI->get($this->{group} => 'logging', '0')) {
            $TL->log(__PACKAGE__, "Failed to read a valid session data. secure [$opts{secure}] sid [$sid] checkval [$checkval]");
        }
    }

    return $this;
}

sub _deleteSid {
    my Tripletail::Session::MongoDB $this = shift;
    my $sid  = shift;

    $TL->getMongoDB($this->{dbgroup})->do(sub {
        my $client = shift;
        my $ns     = $client->get_namespace($this->{session_ns});

        $ns->delete_one({_id => MongoDB::OID->new($sid)});
    });

    return $this;
}

1;

__END__

=encoding utf-8

=head1 NAME

Tripletail::Session::MongoDB - 内部用

=head1 SEE ALSO

L<Tripletail::Session>

=head1 AUTHOR INFORMATION

=over 4

Copyright 2017 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
