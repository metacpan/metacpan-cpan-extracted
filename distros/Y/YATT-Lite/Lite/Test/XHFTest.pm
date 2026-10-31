package YATT::Lite::Test::XHFTest;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use parent qw(YATT::Lite::Object);
use YATT::Lite::MFields qw/_tests _numtests _yatt _global _file_list _file_dict
	      filename ext parser encoding
	      _prev_item _builder/;
use Exporter 'import';
sub MY () {__PACKAGE__}
use YATT::Lite::Util qw(default dict_sort);
sub default_ext {'yatt'}
our @EXPORT_OK = qw(Item);

use Encode;

{
  sub Item () {'YATT::Lite::Test::XHFTest::Item'}
  package YATT::Lite::Test::XHFTest::Item;
  use parent qw(YATT::Lite::Object);
  use YATT::Lite::Util qw(lexpand);
  use YATT::Lite::MFields qw/global
		parser

		_num
		_realfile

		FILE
		TITLE
		BREAK
		SKIP
		TODO
		PERL_MINVER

		WIDGET
		RANDOM
		IN
		PARAM
		OUT
		ERROR
                ERROR_BODY

		REQUIRE

		TAG
                CON_CLASS
	      /;

  sub is_runnable { shift->ntests }
  sub ntests {
    my __PACKAGE__ $item = shift;
    if ($item->{OUT}) {
      2;
    } elsif ($item->{ERROR}) {
      1;
    } else {
      0;
    }
  }
  sub test_require {
    my ($self, $reqlist) = @_;
    grep {not eval qq{require $_}} lexpand($reqlist);
  }

}

require YATT::Lite::XHF;
sub Parser () {'YATT::Lite::XHF'}

sub list_files {
  my $pack = shift;
  map {
    ! -d $_ ? $_ : dict_sort <$_/*.xhf>;
  } @_;
}

sub after_new {
  my MY $self = shift;
  $self->{_numtests} = 0;
  $self->{_tests} = [];
  $self->{ext} //= $self->default_ext;
  $self;
}
sub load {
  my $pack = shift;
  my Parser $parser = $pack->Parser->new(@_);
  my MY $self = $pack->new($parser->cf_delegate(qw(filename))
			   , parser => $parser);
  if (my @global = $parser->read(skip_comment => 0)) {
    $self->configure(@global);
    $parser->configure($self->cf_delegate_defined(qw(encoding)));
  }
  while (my @config = $parser->read) {
    $self->add_item($self->Item->new(@config));
  }
  $self;
}

sub convert_enc_array {
  my ($self, $enc, $array) = @_;
  foreach (@$array) {
    unless (ref $_) {
      $_ = decode($enc, $_)
    } elsif (ref $_ eq 'ARRAY') {
      $_ = $self->convert_enc_array($enc, $_);
    } else {
      # nop.
    }
  }
  $array;
}

sub ntests {
  my MY $self = shift; $self->{_numtests}
}
sub add_item {
  (my MY $self, my Item $item) = @_;
  if ($item->{global}) {
    $self->{_global} = $item->{global};
    next;
  }
  push @{$self->{_tests}}, $self->fixup_item($item);
  $self->{_numtests} += $item->ntests;
}

sub fixup_item {
  (my MY $self, my Item $test) = @_;
  my Item $prev = $self->{_prev_item};
  $test->{FILE} ||= do {
    if ($prev && $prev->{FILE} =~ m{%d}) {
      $prev->{FILE}
    } else {
      "f%d.$self->{ext}"
    }
  };

  $test->{_realfile} = do {
    if ($test->{IN}) {
      no if $] >= 5.021002, warnings => qw/redundant/;
      sprintf($test->{FILE}, 1+@{$self->{_file_list} //= []})
    } else {
      $prev->{_realfile}
    }
  };

  $test->{WIDGET} ||= do {
    my $widget = $test->{_realfile};
    $widget =~ s{\.\w+$}{};
    $widget =~ s{/}{:}g;
    $widget;
  };

  if ($test->{IN}) {
    if (my $conflict = $self->{_file_dict}{$test->{_realfile}}) {
      die "FILE name confliction in test $test";
    }
    $self->{_file_dict}{$test->{_realfile}} = $test;
    push @{$self->{_file_list}}, $test->{_realfile};
  }

  if ($test->{OUT} || $test->{ERROR}) {
    $test->{WIDGET} ||= $prev && $prev->{WIDGET};
    if (not $test->{TITLE} and $prev) {
      $test->{_num} = default($prev->{_num}, 0) + 1;
      $test->{TITLE} = $prev->{TITLE};
    }
    $self->{_prev_item} = $test;
  }

  $test;
}

sub as_vfs_data {
  my MY $self = shift;
  my (%result);
  # 記述の順番どおりに作成
  foreach my $fn (@{$self->{_file_list}}) {
    my Item $item = $self->{_file_dict}{$fn};
    my @path = split m|/|, $fn;
    my $path_cursor = path_cursor(\%result, \@path);
    $path[0] =~ s|\.(\w+)$||
      or die "Can't handle filename as vfs key: $fn";
    my $ext = $1;
    if (my $sub = $self->can("convert_$ext")) {
      $sub->($self, $path_cursor, $item)
    } else {
      # XXX: 既に配列になってると困るよね。 rc 系を後回しにすれば大丈夫?
      unless (defined $item->{IN}) {
	die "undef IN"
      }
      $path_cursor->[0]{$path[0]} = $item->{IN};
    }
  }
  \%result;
}

sub path_cursor {
  my ($top, $path) = @_;
  # path を一個残して、vivify する。
  # そこにいたる経路を cursor として返す。
  my $cursor = [$top];
  while (@$path > 1) {
    my $nm = shift @$path;
    $cursor = [$cursor->[0]{$nm} ||= {}, $cursor];
  }
  $cursor;
}

1;
