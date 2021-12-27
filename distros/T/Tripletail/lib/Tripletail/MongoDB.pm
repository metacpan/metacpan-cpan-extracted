package Tripletail::MongoDB;
use strict;
use warnings;
use Tripletail;
use Scalar::Util qw(blessed);
use Time::HiRes ();

sub _INIT_REQUEST_HOOK_PRIORITY() { -1_001_000 } # Any order.
sub _TERM_HOOK_PRIORITY()         { -1_001_000 } # After Tripletail::Session

=encoding utf-8

=head1 NAME

Tripletail::MongoDB - MongoDB との接続


=head1 SYNOPSIS

=head2 CODE

  $TL->startCgi(
      -MongoDB => 'MongoDB',
      -main    => \&main,
  );

  sub main {
      $TL->getMongoDB->do(sub {
          my $client = shift;
          my $coll   = $client->get_collection('test.collection.foo');
          my $doc    = $coll->find_one({a => 999});
          $TL->print($doc->{b});
      });
  }


=head2 INI

  [MongoDB]
  host_uri = mongodb://db1.example.com,db2.example.com,db3.example.com/?replicaSet=foo


=head1 DESCRIPTION

L<Tripletail::DB> と同様の目的を持つモジュールだが、こちらは MongoDB
(L<https://www.mongodb.com/>) を対象とする。


=head2 METHODS

=over 4

=item C<< $TL->getMongoDB >>

  my $DB = $TL->getMongoDB;
  my $DB = $TL->getMongoDB($inigroup);

C<Tripletail::MongoDB> オブジェクトを取得する。
引数には Ini で設定したグループ名を渡す。
引数省略時は C<MongoDB> グループが使用される。

L<< $TL->startCgi|Tripletail/"startCgi" >> /
L<< $TL->trapError|Tripletail/"trapError" >> の C<main>
関数内で MongoDB オブジェクトを取得する場合に使用する。

=cut

my %INSTANCES; # group => Tripletail::MongoDB

sub _getInstance {
    my $class = shift;
    my $group = shift;

    if (!defined $group) {
        $group = 'MongoDB';
    }

    if (my $obj = $class->_lookupInstance($group)) {
        return $obj;
    }
    else {
        die "TL#getMongoDB: MongoDB group [$group] was not passed to the startCgi() / trapError(). " .
          "(startCgi/trapErrorのMongoDBに指定されていないグループ[${group}]が指定されました)\n";
    }
}

sub _lookupInstance {
    my $class = shift;
    my $group = shift;

    if (!defined $group) {
        $group = 'MongoDB';
    }
    elsif (ref $group) {
        die "TL#getMongoDB: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }

    if (exists $INSTANCES{$group}) {
        return $INSTANCES{$group};
    }
    else {
        return;
    }
}


=item C<< $TL->newMongoDB >>

  my $DB = $TL->newMongoDB;
  my $DB = $TL->newMongoDB($inigroup);

新しく Tripletail::MongoDB オブジェクトを作成する。
引数には Ini で設定したグループ名を渡す。
引数省略時は C<MongoDB> グループが使用される。

動的にコネクションを作成したい場合などに使用する。
この方法で Tripletail::MongoDB オブジェクトを取得した場合、L<"connect"> /
L<"disconnect"> を呼び出し、接続の制御を行う必要がある。

=cut

use fields qw(group client max_retries retry_interval_at);
sub _new {
    my Tripletail::MongoDB $this = shift;
    my $group = shift;

    if (!ref $this) {
        $this = fields::new($this);
    }

    $this->{group } = $group;
    $this->{client} = undef; # MongoDB::MongoClient

    # Retry interval curve y = ax^2 + bx + c where y is the interval
    # for x-th retry.
    $this->{max_retries      } = $TL->INI->get($group => max_retries => 10);
    $this->{retry_interval_at} = __gen_retry_interval_curve(
        $this->{max_retries},
        $TL->INI->get($group => min_retry_interval =>  100) / 1000,  # s
        $TL->INI->get($group => max_retry_interval => 1000) / 1000); # s

    # Load the MongoDB module here. We can't do anything without it.
    do {
        local $SIG{__DIE__} = 'DEFAULT';
        eval qq{
            use MongoDB;
        };
        if ($@) {
            die $@;
        }
    };

    return $this;
}

sub __gen_retry_interval_curve {
    my $max_retries        = shift;
    my $min_retry_interval = shift;
    my $max_retry_interval = shift;

    # Our curve has the form of y = a(x-p)^2 + q and we already know
    # what (p, q) should be: p = 0, q = $min_retry_interval. Calculate
    # the coefficient a. We assume that x moves from 0 to
    # $max_x = ($max_retries-1)/$max_retries.
    #
    #   y = ax^2 + $min_retry_interval
    #   $max_retry_interval = a * $max_x^2 + $min_retry_interval
    #     (because x = $max_x, y = $max_retry_interval), therefore
    #   a * $max_x^2 = $max_retry_interval - $min_retry_interval
    #   a = ($max_retry_interval - $min_retry_interval) / $max_x^2

    my $max_x = ($max_retries-1)/$max_retries;
    my $a     = ($max_retry_interval - $min_retry_interval) / ($max_x ** 2);
    my $f = sub {
        my $x = shift;
        return $a * ($x ** 2) + $min_retry_interval;
    };

    return $f;
}


=item C<< connect >>

  $DB->connect;

MongoDB に接続する。

L<< $TL->startCgi|Tripletail/"startCgi" >> /
L<< $TL->trapError|Tripletail/"trapError" >> の関数内で MongoDB
オブジェクトを取得する場合には自動的に接続が管理されるため、このメソッドを呼び出してはならない。

L<< $TL->MongoDB|"$TL->newMongoDB" >> で作成した Tripletail::MongoDB
オブジェクトに関しては、このメソッドを呼び出し、MongoDB へ接続する必要がある。

L<MongoDB::MongoClient> の L<< dt_type|MongoDB::MongoClient/"dt_type
(DEPRECATED AND READ-ONLY)" >> は L<Time::Moment> に設定される。これは
L<DateTime> モジュールの動作があまりに遅い為である。

=cut

sub _reconnectSilentlyAll {
    # Called on child context after forking.
    foreach my Tripletail::MongoDB $db (values %INSTANCES) {
        $db->_reconnectSilently;
    }

    return;
}

sub _reconnectSilently {
    my Tripletail::MongoDB $this = shift;

    if (my $client = $this->{client}) {
        $client->reconnect;
    }

    return $this;
}

sub _connect {
    my $class  = shift;
    my $groups = shift;

    foreach my $group (@$groups) {
        if (!defined $group) {
            die "TL#startCgi: -MongoDB has an undefined value. (MongoDB指定にundefが含まれます)\n";
        }
        elsif (ref $group) {
            die "TL#startCgi: -MongoDB has a reference. (MongoDB指定にリファレンスが含まれます)\n";
        }

        $INSTANCES{$group} = __PACKAGE__->_new($group)->connect;
    }

    $TL->setHook(
        'initRequest',
        _INIT_REQUEST_HOOK_PRIORITY,
        \&__initRequest);

    $TL->setHook(
        'term',
        _TERM_HOOK_PRIORITY,
        \&__term);

    return;
}

sub __initRequest {
    foreach my Tripletail::MongoDB $db (values %INSTANCES) {
        $db->connect;
    }
}

sub __term {
    foreach my Tripletail::MongoDB $db (values %INSTANCES) {
        $db->disconnect;
    }
    %INSTANCES = ();
}

sub connect {
    my Tripletail::MongoDB $this = shift;

    if (my $client = $this->{client}) {
        $client->connect;
    }
    else {
        my $group = $this->{group};
        my $URI   = $TL->INI->get($group => 'host_uri');

        require Time::Moment;
        $this->{client} = MongoDB->connect($URI, {dt_type => 'Time::Moment'});
    }

    return $this;
}


=item C<< disconnect >>

  $DB->disconnect;

MongoDB から切断する。

L<< $TL->startCgi|Tripletail/"startCgi" >> /
L<< $TL->trapError|Tripletail/"trapError" >> の関数内で MongoDB
オブジェクトを取得する場合には自動的に接続が管理されるため、このメソッドを呼び出してはならない。

L<< $TL->MongoDB|"$TL->newMongoDB" >> で作成した Tripletail::MongoDB
オブジェクトに関しては、このメソッドを呼び出し、MongoDB への接続を切断する必要がある。

=cut

sub disconnect {
    my Tripletail::MongoDB $this = shift;

    if (my $client = $this->{client}) {
        $client->disconnect;
    }

    return $this;
}


=item C<< getClient >>

  my $client = $DB->getClient;

L<MongoDB::MongoClient> オブジェクトを返す。このメソッドは後述の
L</"do"> を使わない場合にのみ必要となる。

=cut

sub getClient {
    my Tripletail::MongoDB $this = shift;

    if (my $client = $this->{client}) {
        return $client;
    }
    else {
        my $group = $this->{group};
        die __PACKAGE__."#getClient: We haven't connected to the database group [$group] yet." .
          " (DB グループ [$group] にはまだ接続されていません)\n";
    }
}


=item C<< do >>

  my $ret = $DB->do(sub {
      my $client = shift;
      # ...
  });

与えられた関数に L<MongoDB::MongoClient> オブジェクトを渡して実行する。
実行中に特定の種類の例外が発生した場合には、少しの時間を置いてから既定の回数まで自動的に再試行する。

再試行回数の上限は L</"max_retries">
で指定され、もしこの回数に達しても依然として例外が発生したならば、最後に発生した例外が再送される。
再試行時の遅延時間の最小と最大は L</"min_retry_interval"> と L</"max_retry_interval">
で指定されるが、実際の遅延時間は線型ではなく二次関数的に増加する。

現在のところ、再試行の対象となる例外は次の通りである。これ以外の例外が発生した際には再試行せずに即座にその例外を再送する:

=over 4

=item L<MongoDB::NetworkError|MongoDB::Error/"MongoDB::NetworkError">

=item L<MongoDB::NotMasterError|MongoDB::Error/"MongoDB::NotMasterError">

=item L<MongoDB::WriteConcernError|MongoDB::Error/"MongoDB::WriteConcernError">

=item L<MongoDB::SelectionError|MongoDB::Error/"MongoDB::SelectionError">

=item L<MongoDB::TimeoutError|MongoDB::Error/"MongoDB::TimeoutError">

=back

=cut

sub do {
    my Tripletail::MongoDB $this = shift;
    my $sub = shift;

    my $client = $this->getClient;
    my $trial  = 0;
    while (1) {
        my @ret;
        do {
            local $SIG{__DIE__} = 'DEFAULT';
            if (wantarray) {
                @ret    = eval { $sub->($client) };
            }
            else {
                $ret[0] = eval { $sub->($client) };
            }
        };

        if (my $e = $@) {
            if ($trial >= $this->{max_retries}) {
                # Too many retries attempted. Bail out by rethrowing
                # the exception.
                die $e;
            }
            elsif (blessed($e) &&
                     ( $e->isa('MongoDB::NetworkError'     ) ||
                       $e->isa('MongoDB::NotMasterError'   ) ||
                       $e->isa('MongoDB::WriteConcernError') ||
                       $e->isa('MongoDB::SelectionError'   ) ||
                       $e->isa('MongoDB::TimeoutError'     ) )) {
                # These errors are considered to be temporary. We
                # attempt to retry the operation later.
                Time::HiRes::sleep(
                    $this->{retry_interval_at}($trial / $this->{max_retries}));
                $trial++;
            }
            else {
                # A seemingly unrecoverable error has occured.
                die $e;
            }
        }
        else {
            if (wantarray) {
                return @ret;
            }
            else {
                return $ret[0];
            }
        }
    }
}

=back

=head2 Ini パラメータ

=over 4

=item C<< host_uri >>

  host_uri = mongodb://db1.example.com,db2.example.com,db3.example.com/?replicaSet=foo

接続先サーバーまたはレプリカセットの URI を設定する。詳細は
L<MongoDB::MongoClient/"CONNECTION STRING URI"> を参照のこと。

=item C<< max_retries >>

  max_retries = 10

L</"do"> の最大再試行回数を設定する。デフォルトは 10.

=item C<< min_retry_interval >>

  min_retry_interval = 100

L</"do"> の最小再試行遅延時間をミリ秒単位で設定する。デフォルトは 100.

=item C<< max_retry_interval >>

  max_retry_interval = 1000

L</"do"> の最大再試行遅延時間をミリ秒単位で設定する。デフォルトは 1000.

=back

=cut

1;
