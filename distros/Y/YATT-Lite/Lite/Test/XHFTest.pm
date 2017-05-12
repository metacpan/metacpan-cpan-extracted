package YATT::Lite::Test::XHFTest;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use parent qw(YATT::Lite::Object);
use YATT::Lite::MFields qw/tests numtests yatt global file_list file_dict
	      cf_filename cf_ext cf_parser cf_encoding
	      prev_item builder/;
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
  use YATT::Lite::MFields qw/cf_global
		cf_parser

		num
		realfile

		cf_FILE
		cf_TITLE
		cf_BREAK
		cf_SKIP
		cf_TODO
		cf_PERL_MINVER

		cf_WIDGET
		cf_RANDOM
		cf_IN
		cf_PARAM
		cf_OUT
		cf_ERROR

		cf_REQUIRE

		cf_TAG
	      /;

  sub is_runnable { shift->ntests }
  sub ntests {
    my __PACKAGE__ $item = shift;
    if ($item->{cf_OUT}) {
      2;
    } elsif ($item->{cf_ERROR}) {
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
  $self->{numtests} = 0;
  $self->{tests} = [];
  $self->{cf_ext} //= $self->default_ext;
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
  my MY $self = shift; $self->{numtests}
}
sub add_item {
  (my MY $self, my Item $item) = @_;
  if ($item->{cf_global}) {
    $self->{global} = $item->{cf_global};
    next;
  }
  push @{$self->{tests}}, $self->fixup_item($item);
  $self->{numtests} += $item->ntests;
}

sub fixup_item {
  (my MY $self, my Item $test) = @_;
  my Item $prev = $self->{prev_item};
  $test->{cf_FILE} ||= do {
    if ($prev && $prev->{cf_FILE} =~ m{%d}) {
      $prev->{cf_FILE}
    } else {
      "f%d.$self->{cf_ext}"
    }
  };

  $test->{realfile} = do {
    if ($test->{cf_IN}) {
      no if $] >= 5.021002, warnings => qw/redundant/;
      sprintf($test->{cf_FILE}, 1+@{$self->{file_list} //= []})
    } else {
      $prev->{realfile}
    }
  };

  $test->{cf_WIDGET} ||= do {
    my $widget = $test->{realfile};
    $widget =~ s{\.\w+$}{};
    $widget =~ s{/}{:}g;
    $widget;
  };

  if ($test->{cf_IN}) {
    if (my $conflict = $self->{file_dict}{$test->{realfile}}) {
      die "FILE name confliction in test $test";
    }
    $self->{file_dict}{$test->{realfile}} = $test;
    push @{$self->{file_list}}, $test->{realfile};
  }

  if ($test->{cf_OUT} || $test->{cf_ERROR}) {
    $test->{cf_WIDGET} ||= $prev && $prev->{cf_WIDGET};
    if (not $test->{cf_TITLE} and $prev) {
      $test->{num} = default($prev->{num}, 0) + 1;
      $test->{cf_TITLE} = $prev->{cf_TITLE};
    }
    $self->{prev_item} = $test;
  }

  $test;
}

sub as_vfs_data {
  my MY $self = shift;
  my (%result);
  # 記述の順番どおりに作成
  foreach my $fn (@{$self->{file_list}}) {
    my Item $item = $self->{file_dict}{$fn};
    my @path = split m|/|, $fn;
    my $path_cursor = path_cursor(\%result, \@path);
    $path[0] =~ s|\.(\w+)$||
      or die "Can't handle filename as vfs key: $fn";
    my $ext = $1;
    if (my $sub = $self->can("convert_$ext")) {
      $sub->($self, $path_cursor, $item)
    } else {
      # XXX: 既に配列になってると困るよね。 rc 系を後回しにすれば大丈夫?
      unless (defined $item->{cf_IN}) {
	die "undef IN"
      }
      $path_cursor->[0]{$path[0]} = $item->{cf_IN};
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
