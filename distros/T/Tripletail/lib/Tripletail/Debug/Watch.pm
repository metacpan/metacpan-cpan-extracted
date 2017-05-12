
package Tripletail::Debug::Watch;
use strict;
use warnings;
use Tripletail;

1;


sub watch {
  Tripletail::Debug::Watch::_watch(1, @_);
}

sub _watch {
  my $dieflag = shift;
  my $name = shift;
  my $data = shift;
  my $level = shift || 0;

  if(ref($data) eq 'SCALAR')
    {
      if(tied($$data))
	{
	  die "TL#watch: arg[1]: already tied. (既にtieされています)\n" if($dieflag);
	}
      tie $$data, 'Tripletail::Debug::Watch::Scalar', $data, $name, $level;
    }
  elsif(ref($data) eq 'ARRAY')
    {
      if(tied(@$data))
	{
	  die "TL#watch: arg[1]: already tied. (既にtieされています)\n" if($dieflag);
	}
      tie @$data, 'Tripletail::Debug::Watch::Array', $data, $name, $level;
    }
  elsif(ref($data) eq 'HASH')
    {
      if(tied(%$data))
	{
	  die "TL#watch: arg[1]: already tied. (既にtieされています)\n" if($dieflag);
	}
      tie %$data, 'Tripletail::Debug::Watch::Hash', $data, $name, $level;
    }
  else
    {
      die "TL#watch: arg[1]: unsupported type. TL#watch only accepts SCALAR/ARRAY/HASH Ref.".
      	" (サポートされていないタイプです。SCALAR/ARRAY/HASHのみサポートしています)\n"
      		if($dieflag);
    }

  $data;
}

sub _calledLocation {
  my $class = shift;
  
  # スタックを辿り、最初に現れたTL以外のパッケージが作ったフレームを見て、
  # ファイル名と行番号を得る。
  for (my $i = 0;; $i++) {
    my ($pkg, $fname, $lineno) = caller $i;
    if ($pkg !~ m/^TL/) {
      $fname =~ m!([^/]+)$!;
      $fname = $1;
      
      return sprintf('[%s:%d]', $fname, $lineno);
    }
  }

  return '[unknown]';
}

package Tripletail::Debug::Watch::Scalar;
use strict;
use warnings;
use Tripletail;


sub TIESCALAR {
  my $pkg = shift;
  my $data = shift;
  my $name = shift;
  my $level = shift;
  my $this = [ $$data, $name, $level];
  use Data::Dumper;
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "start watch \$$name = " . Data::Dumper->new([$$data])->Indent(0)->Terse(1)->Dump . "\n"
	  );
  bless $this, $pkg;
}

sub FETCH {
  $_[0]->[0];
}

sub STORE {
  use Data::Dumper;
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "\$${_[0]->[1]} = " . Data::Dumper->new([$_[1]])->Indent(0)->Terse(1)->Dump . "\n"
	  );
  if($_[0]->[2]) {
    Tripletail::Debug::Watch::_watch(0, $_[0]->[1] . '.$', $_[1], $_[0]->[2] - 1);
  }
  $_[0]->[0] = $_[1];
}

sub DESTROY {
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "destroy \$${_[0]->[1]}\n"
	  );
}

sub UNTIE {
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "end watch \$${_[0]->[1]}\n"
	  );
}

package Tripletail::Debug::Watch::Array;
use strict;
use warnings;
use Tripletail;

sub TIEARRAY {
  my $pkg = shift;
  my $data = shift;
  my $name = shift;
  my $level = shift;
  my $this = [[ @$data ], $name, $level];
  use Data::Dumper;
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "start watch \@$name = " . Data::Dumper->new([$data])->Indent(0)->Terse(1)->Dump . "\n"
	  );
  bless $this, $pkg;
}

sub FETCH {
  $_[0]->[0][$_[1]];
}

sub STORE {
  use Data::Dumper;
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "store \$${_[0]->[1]}[$_[1]] = " . Data::Dumper->new([$_[2]])->Indent(0)->Terse(1)->Dump . "\n"
	  );
  if($_[0]->[2]) {
    Tripletail::Debug::Watch::_watch(0, $_[0]->[1] . ".[]", $_[2], $_[0]->[2] - 1);
  }
  $_[0]->[0][$_[1]] = $_[2];
}

sub FETCHSIZE {
  scalar @{$_[0]->[0]};
}

sub STORESIZE {
  $#{$_[0]->[0]} = $_[1]-1;
}

sub CLEAR {
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "claer \@${_[0]->[1]}\n"
	  );
  @{$_[0]->[0]} = ();
}

sub PUSH {
  my $this = shift;
  use Data::Dumper;
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "push \@$this->[1], " . Data::Dumper->new([\@_])->Indent(0)->Terse(1)->Dump . "\n"
	  );
  if($this->[2]) {
    foreach my $data (@_) {
      Tripletail::Debug::Watch::_watch(0, $this->[1] . ".[]", $data, $this->[2] - 1);
    }
  }
  push(@{$this->[0]}, @_);
}

sub POP {
  pop(@{$_[0]->[0]});
}

sub SHIFT {
  shift(@{$_[0]->[0]});
}

sub UNSHIFT {
  my $this = shift;
  use Data::Dumper;
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "unshift \@$this->[1], " . Data::Dumper->new([\@_])->Indent(0)->Terse(1)->Dump . "\n"
	  );
  if($this->[2]) {
    foreach my $data (@_) {
      Tripletail::Debug::Watch::_watch(0, $this->[1] . ".[]", $data, $this->[2] - 1);
    }
  }
  unshift(@{$this->[0]}, @_);
}

sub EXISTS {
  exists $_[0]->[0][$_[1]];
}

sub DELETE {
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "delete \$${_[0]->[1]}[$_[1]]\n"
	  );
  delete $_[0]->[0][$_[1]];
}

sub SPLICE {
  my $this = shift;
  my $size = $this->FETCHSIZE;
  my $offset = @_ ? shift : 0;
  $offset += $size if $offset < 0;
  my $length = @_ ? shift : $size - $offset;
  use Data::Dumper;
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "splice \@$this->[1], $offset, $length, " . Data::Dumper->new([\@_])->Indent(0)->Terse(1)->Dump . "\n"
	  );
  if($this->[2]) {
    foreach my $data (@_) {
      Tripletail::Debug::Watch::_watch(0, $this->[1] . ".[]", $data, $this->[2] - 1);
    }
  }
  splice(@{$this->[0]}, $offset, $length, @_);
}

sub EXTEND {
}

sub DESTROY {
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "destroy \@${_[0]->[1]}\n"
	  );
}

sub UNTIE {
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "end watch \@${_[0]->[1]}\n"
	  );
}


package Tripletail::Debug::Watch::Hash;
use strict;
use warnings;
use Tripletail;

sub TIEHASH {
  my $pkg = shift;
  my $data = shift;
  my $name = shift;
  my $level = shift;
  my $this = [{ %$data }, $name, $level];
  use Data::Dumper;
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "start watch \%$name = " . Data::Dumper->new([$data])->Indent(0)->Terse(1)->Dump . "\n"
	  );
  bless $this, $pkg;
}

sub FETCH {
  $_[0]->[0]{$_[1]};
}

sub STORE {
  use Data::Dumper;
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "\$${_[0]->[1]}{$_[1]} = " . Data::Dumper->new([$_[2]])->Indent(0)->Terse(1)->Dump . "\n"
	  );
  if($_[0]->[2]) {
    Tripletail::Debug::Watch::_watch(0, $_[0]->[1] . ".{$_[1]}", $_[2], $_[0]->[2] - 1);
  }
  $_[0]->[0]{$_[1]} = $_[2];
}

sub DELETE {
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "delete \$${_[0]->[1]}{$_[1]}\n"
	  );
  delete $_[0]->[0]{$_[1]};
}

sub CLEAR {
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "clear \%${_[0]->[1]}\n"
	  );
  %{$_[0]->[0]} = ();
}

sub EXISTS {
  exists $_[0]->[0]{$_[1]};
}

sub FIRSTKEY {
  my $key = scalar keys %{$_[0]->[0]};
  each %{$_[0]->[0]};
}

sub NEXTKEY {
  each %{$_[0]->[0]};
}

sub SCALAR {
  scalar %{$_[0]->[0]};
}

sub DESTROY {
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "destroy \%${_[0]->[1]}\n"
	  );
}

sub UNTIE {
  $TL->log(__PACKAGE__,
	   Tripletail::Debug::Watch::_calledLocation . ' ' .
	   "end watch \%${_[0]->[1]}\n"
	  );
}




__END__

=encoding utf-8

=for stopwords
	YMIRLINK

=head1 NAME

Tripletail::Debug::Watch - $TL->watch用内部クラス

=head2 METHODS

=over 4

=item watch

内部メソッド

=back

=head1 SEE ALSO

L<Tripletail>

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut




