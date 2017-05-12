package Tripletail::DB::Sth;
use strict;
use warnings;
use Tripletail;
use Scalar::Lazy;
my $STH_ID = 0;

sub new {
	my $class = shift;
	my $db = shift;
	my $dbh = shift;
	my $sth = shift;
	my $this = bless {} => $class;

	$this->{db_center} = $db; # Tripletail::DB
	$this->{dbh} = $dbh; # Tripletail::DB::DBH
	$this->{sth} = $sth; # native sth
	$this->{ret} = undef; # last return value
	$this->{id} = $STH_ID++;

	$this;
}

sub fetchHash {
	my $this = shift;
	my $hash = $this->{sth}->fetchrow_hashref;

    if ($hash) {
        $TL->getDebug->_dbLogData(
            lazy {
                +{ group   => $this->{group},
                   set     => $this->{set}{name},
                   db      => $this->{dbh}{inigroup},
                   id      => $this->{id},
                   data    => $hash }
            });
    }
	if( $this->{dbh}{fetchconvert} )
	{
		my $sub = $this->{dbh}{fetchconvert};
		$this->{dbh}->$sub($this, fetchHash => $hash);
	}


	if(my $lim = $this->{db_center}{bufsize}) {
		my $size = 0;
		foreach(values %$hash) {
			$size += length;
		}

        if($size > $lim) {
            die __PACKAGE__."#fetchHash: buffer size exceeded: size [$size] / limit [$lim]".
              " (バッファサイズを超過しました。size [$size] / limit [$lim])\n";
        }
    }

	$hash;
}

sub fetchArray {
	my $this = shift;
	my $array = $this->{sth}->fetchrow_arrayref;

	if( $this->{dbh}{fetchconvert} )
	{
		my $sub = $this->{dbh}{fetchconvert};
		$this->{dbh}->$sub($this, fetchArray => $array);
	}
    if ($array) {
        $TL->getDebug->_dbLogData(
            lazy {
                +{ group   => $this->{group},
                   set     => $this->{set}{name},
                   db      => $this->{dbh}{inigroup},
                   id      => $this->{id},
                   data    => $array }
            });
    }

	if(my $lim = $this->{db_center}{bufsize}) {
		my $size = 0;
		foreach(@$array) {
			$size += length;
		}

        if($size > $lim) {
            die __PACKAGE__."#fetchArray: buffer size exceeded: size [$size] / limit [$lim]".
              " (バッファサイズを超過しました。size [$size] / limit [$lim])\n";
        }
	}

	$array;
}

sub ret {
	my $this = shift;
	$this->{ret};
}

sub rows {
	my $this = shift;
	$this->{sth}->rows;
}

sub finish {
	my $this = shift;
	$this->{sth}->finish;
}

sub nameArray {
	my $this = shift;
	my $name_lc = $this->{sth}{NAME_lc};
	if( $name_lc && $this->{dbh}{fetchconvert} )
	{
		$name_lc = [@{$this->{sth}{NAME}}]; # start from mixed case.
		my $sub = $this->{dbh}{fetchconvert};
		$this->{dbh}->$sub($this, nameArray => $name_lc);
	}
	$name_lc;
}

sub nameHash {
	my $this = shift;
	my $name_lc_hash = $this->{sth}{NAME_lc_hash};
	if( $name_lc_hash && $this->{dbh}{fetchconvert} )
	{
		$name_lc_hash = {%{$this->{sth}{NAME_hash}}}; # start from mixed case.
		my $sub = $this->{dbh}{fetchconvert};
		$this->{dbh}->$sub($this, nameHash => $name_lc_hash);
	}
	$name_lc_hash;
}

sub _fetchconvert
{
	my $this = shift;
	if( $this->{dbh}{fetchconvert} )
	{
		my $sub = $this->{dbh}{fetchconvert};
		$this->{dbh}->$sub($this, @_);
	}
}

1;

__END__

=encoding utf-8

=head1 NAME

Tripletail::DB::Sth - 内部用

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item C<< fetchArray >>

=item C<< fetchHash >>

=item C<< finish >>

=item C<< nameArray >>

=item C<< nameHash >>

=item C<< new >>

=item C<< ret >>

=item C<< rows >>

=back

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
