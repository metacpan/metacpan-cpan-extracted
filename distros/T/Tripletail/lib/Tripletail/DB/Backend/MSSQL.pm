package Tripletail::DB::Backend::MSSQL::Dbh;
use strict;
use warnings;
use Tripletail;
our @ISA = qw(Tripletail::DB::Dbh);

sub connect {
    my $this = shift;

    my $nl = $Tripletail::_CHKNONLAZY || 0;
    my $dl = $Tripletail::_CHKDYNALDR || 0;
    my $opts = {
        map{ $_ => $TL->INI->get($this->{inigroup} => $_ => undef) }
          qw(dbname host port tdsname odbcdsn odbcdriver),
        qw(bindconvert fetchconvert)
       };
    if (!defined $opts->{dbname}) {
        die __PACKAGE__."#connect: dbname is not set. (dbnameが指定されていません)\n";
    }

    # build data source string.
    my $dsn;
    if ($opts->{odbcdsn}) {
        my $odbcdsn = $opts->{odbcdsn} || '';
        if ($odbcdsn =~ m/^(\w+)$/) {
            $dsn = "dbi:ODBC:DSN=$odbcdsn";
        }
        elsif ($odbcdsn =~ /^Driver=|^DSN=/i) {
            $dsn = "dbi:ODBC:$odbcdsn";
        }
        elsif ($odbcdsn =~ /^dbi:/) {
            $dsn = $odbcdsn;
        }
        else {
            die __PACKAGE__."#connect: unknown odbcdsn. (対応していないodbcdsnが指定されました)\n";
        }
    }
    # odbc driver.
    if (!$dsn || $dsn !~ /[:;]Driver=/i || $opts->{odbcdriver}) {
        my $driver = $opts->{odbcdriver};
        $driver ||= $^O eq 'MSWin32' ? 'SQL Server' : 'freetdsdriver';
        if (!$dsn) {
            $dsn = "dbi:ODBC:DRIVER={$driver}";
        }
        else {
            $dsn .= ";DRIVER={$driver}";
        }
    }
    $opts->{tdsname} and $dsn .= ";Servername=$opts->{tdsname}";
    $opts->{host   } and $dsn .= ";Server=$opts->{host}";
    $opts->{port   } and $dsn .= ";Port=$opts->{port}";
    $opts->{dbname } and $dsn .= ";Database=$opts->{dbname}";

    # bindconvert/fetchconvert from driver.
    my $odbc_driver = $dsn =~ /[:;]DRIVER=\{(.*?)\}/i ? lc($1) : '';
    if ( $odbc_driver eq 'freetdsdriver' ) {
        $opts->{bindconvert} ||= 'freetds';
    }
    elsif ( $odbc_driver eq 'sql server' ) {
        local($SIG{__DIE__},$@) = 'DEFAULT';
        my $codepage = eval{
            require Win32::API;
            my $get_acp   = Win32::API->new("kernel32", "GetACP",   "", "N");
            $get_acp && $get_acp->Call();
        } || 0;
        if ( !$codepage || $codepage==932 ) {
            $opts->{bindconvert}  ||= 'mssql_cp932';
            $opts->{fetchconvert} ||= 'mssql_cp932';
            #$dsn .= ';AutoTranslate=No';
        }
    }
    foreach my $key (qw(bindconvert fetchconvert)) {
        $opts->{$key} or next;
        $opts->{$key} eq 'no' and next;
        my $sub = $this->can("_${key}_$opts->{$key}");
        $sub or die __PACKAGE__."#connect: no such $key: $opts->{$key} (${key}が指定されていません)";
        $this->{$key} = $sub;
    }

    my $conn = sub{
        $this->{type} = 'mssql';
        $this->{dbh } = DBI->connect(
            $dsn,
            $TL->INI->get($this->{inigroup} => 'user' => undef),
            $TL->INI->get($this->{inigroup} => 'password' => undef),
            {
                AutoCommit => 1,
                PrintError => 0,
                RaiseError => 1,
            }
           );

        if (!$this->{dbh}) {
            die __PACKAGE__."#connect: DBI->connect failed. (DBI->connectに失敗しました)\n";
        }
    };
    if ((!$dl && $nl) || $^O eq 'MSWin32') {
        $conn->();
    }
    else {
        eval{ $conn->(); };
        if ( $@ ) {
            my $err = $@;
            chomp $err;
            $err .= " (perhaps you forgot to set env PERL_DL_NONLAZY=1?)";
            $err .= " ...propagated";
            die $err;
        }
    }
    if ($this->{fetchconvert}) {
        my $sub = $this->{fetchconvert};
        $this->$sub(undef, connect => undef);
    }

    return $this;
}

sub _bindconvert_freetds
{
	my $this = shift;
	my $ref_sql = shift;
	my $params  = shift;
	my $i = -1;
	foreach my $elm (@$params)
	{
		++$i;
		ref($elm) or next;
		if( ${$elm->[1]} eq 'SQL_WVARCHAR' )
		{
			my $u = $TL->charconv($elm->[0], 'utf8', 'ucs2');
			$elm->[0] = pack("v*",unpack("n*",$u));
			$elm->[1] = \'SQL_BINARY';
			
			my $l = length($u)/2;
			my $j = 0;
			my $repl = "CAST(? AS NVARCHAR($l))";
			$$ref_sql =~ s{\?}{$j++==$i?$repl:'?'}ge;
		}
	}
}

sub _bindconvert_mssql_cp932
{
	my $this = shift;
	my $ref_sql = shift;
	my $params  = shift;
	$$ref_sql = $TL->charconv($$ref_sql, 'utf8' => 'sjis');
	my $i = -1;
	foreach my $elm (@$params)
	{
		++$i;
		if( !ref($elm) )
		{
			$elm = $TL->charconv($elm, 'utf8', 'sjis');
		}elsif( ${$elm->[1]} =~ /^SQL_W(?:(?:LONG)?VAR)?CHAR$/ )
		{
			my $u = $TL->charconv($elm->[0], 'utf8', 'ucs2');
			$elm->[0] = pack("v*",unpack("n*",$u));
			$elm->[1] = \'SQL_BINARY';
			
			my $l = length($u)/2;
			my $j = 0;
			my $repl = "CAST(? AS NVARCHAR($l))";
			$$ref_sql =~ s{\?}{$j++==$i?$repl:'?'}ge;
		}elsif( ${$elm->[1]} =~ /^SQL_(?:(?:LONG)?VAR)?CHAR$/ )
		{
			$elm = $TL->charconv($elm, 'utf8', 'sjis');
		}
	}
}
sub _fetchconvert
{
	my $this = shift;
	if( $this->{fetchconvert} )
	{
		my $sub = $this->{fetchconvert};
		$this->$sub(@_);
	}
}
sub _fetchconvert_mssql_cp932
{
	my $this = shift;
	my $sth  = shift;
	my $mode = shift;
	my $obj  = shift;
	
	if( $mode eq 'new' )
	{
		# obj is [\$sql, \@params];
		
		# なんだか先に一回やっとかないとおかしくなる?
		$this->{dbh}->type_info(1);
		
		my $types = $sth->{sth}{TYPE};
		my $dbh = $sth->{dbh}{dbh};
		my @types = map{ $dbh->type_info($_)->{TYPE_NAME} } @$types;
		$sth->{_types} = \@types;
		$sth->{_name_hash} = {%{$sth->{sth}{NAME_hash}||{}}}; # raw encoded.
		my @names;
		while(my($k,$v)=each%{$sth->{_name_hash}})
		{
			$names[$v] = $TL->charconv($k, "sjis" => "utf8");
		}
		$sth->{_name_arraymap} = \@names;
		$sth->{_decode_cols} = [];
	}elsif( $mode eq 'nameArray' )
	{
		# obj is arrayref.;
		@$obj = @{$sth->{sth}{NAME}||[]};
		foreach my $elm (@$obj)
		{
			$elm = lc $TL->charconv($elm, 'cp932' => 'utf8');
		}
	}elsif( $mode eq 'nameHash' )
	{
		# obj is hashref.
		foreach my $key (keys %$obj)
		{
			my $ukey = lc $TL->charconv($key, 'cp932' => 'utf8');
			$obj->{$ukey} = delete $obj->{$key};
		}
	}elsif( $mode eq 'fetchArray' )
	{
		# obj is arrayref.
		my $i = -1;
		foreach my $val (@$obj)
		{
			++$i;
			defined($val) or next;
			my $type = (defined($i) && $sth->{_types}[$i]) || '';
			if( $type =~ /^n?((long)?var)?char$/ )
			{
				if( defined($val) && $val =~ /[^\0-\x7f]/ )
				{
					$val = $TL->charconv($val, 'cp932' => 'utf8');
				}
			}
			my $ukey = $sth->{_name_arraymap}[$i] || "\0";
			if( grep{$_ eq $i || $_ eq $ukey} @{$sth->{_decode_cols}} )
			{
				my $bin = pack("v*",unpack("n*",$val));
				$val = $TL->charconv($bin,"ucs2","utf8");
			}
		}
	}elsif( $mode eq 'fetchHash' )
	{
		# obj is hashref.
		foreach my $key (keys %$obj)
		{
			my $ukey = $TL->charconv($key, 'cp932' => 'utf8');
			my $i = $sth->{_name_hash}{$key}; # raw encoded.
			my $type = (defined($i) && $sth->{_types}[$i]) || '*';
			my $val = delete $obj->{$key};
			if( $type =~ /^n?((long)?var)?char$/ )
			{
				if( defined($val) && $val =~ /[^\0-\x7f]/ )
				{
					$val = $TL->charconv($val, 'cp932' => 'utf8');
				}
			}
			if( grep{$_ eq $i || $_ eq $ukey} @{$sth->{_decode_cols}} )
			{
				my $bin = pack("v*",unpack("n*",$val));
				$val = $TL->charconv($bin,"ucs2","utf8");
			}
			$obj->{$ukey} = $val;
		}
	}
}

sub getLastInsertId {
    my $this = shift;
    my $obj  = shift;

    my ($curval) = $this->{dbh}->selectrow_array(
                       q{SELECT @@IDENTITY});
    return $curval;
}

1;

__END__

=encoding utf-8

=head1 NAME

Tripletail::DB::Backend::MSSQL - 内部用

=head1 SEE ALSO

L<Tripletail::DB>

=head1 AUTHOR INFORMATION

=over 4

Copyright 2011 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
