package Text::MeCab::Dict;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Encode;
use Text::MeCab;
use File::Spec;
use Cwd ();

our $MAKE = 'make';

__PACKAGE__->mk_accessors($_) for qw(entries config dict_source libexecdir input_encoding output_encoding);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $libexecdir;
    my $config = $args{mecab_config} || &Text::MeCab::MECAB_CONFIG;
    my $dict_source = $args{dict_source};

    # XXX - the way we're rebuilding the index is by combining the new
    # words with words that are already provided by mecab-ipadic distro.
    # So when later when we call mecab-dict-index, all of these words are
    # compiled together.
    # Naturally, the encoding parameter must match with the other words.
    # As of this writing, mecab-ipadic's original dictionary is in euc-jp,
    # and there fore that's what we shall use for default.
    my $ie     = $args{ie} || $args{input_encoding} || 'euc-jp';
    my $oe     = $args{oe} || $args{output_encoding} || &Text::MeCab::ENCODING;

    if (! $config) {
        $libexecdir = $args{libexecdir};
    } else {
        $libexecdir = `$config --libexecdir`;
        chomp $libexecdir;
    }

    if (! $dict_source || ! $libexecdir) {
        die "You must specify dict_source and libexecdir";
    }

    my $self  = bless {
        config          => $config,
        entries         => [],
        dict_source     => $dict_source,
        libexecdir      => $libexecdir,
        input_encoding  => $ie,
        output_encoding => $oe,
    }, $class;
}

sub add
{
    my $self = shift;

    my $entry;
    if (scalar @_ == 1) {
        $entry = shift @_;
    } else {
        my %args = @_;
        $entry = Text::MeCab::Dict::Entry->new(%args);
    }
    push @{ $self->entries }, $entry;
}

sub write
{
    my $self = shift;
    my $file = shift;

    my @output;
    my $entries = $self->entries;

    my @columns = qw(
        surface left_id right_id cost pos category1 category2 category3 
        inflect inflect_type original yomi pronounce 
    );
    foreach my $entry (@$entries) {
        my @values = map { 
            defined $entry->$_ ? $entry->$_ : '*'
        } @columns;

        if (my $extra = $entry->extra) {
            push @values, @$extra;
        }

        # We don't use Text::CSV_XS, because the csv format that mecab-dict-index
        # expects is a bit off (in terms of CSV-stricture)
        push @output, join(",", @values);
    }

    if (! File::Spec->file_name_is_absolute( $file )) {
        $file = File::Spec->catfile( $self->dict_source, $file );
    }

    my $fh;
    open( $fh, '>>', $file ) or
        die "Could not open file $file for append writing: $!";
    print $fh encode($self->input_encoding, join("\n", @output, ""));
    close $fh;

    $self->entries([]);
}

sub rebuild
{
    my $self = shift;

    my $dict_source = $self->dict_source;
    my $dict_index = File::Spec->catfile($self->libexecdir, 'mecab-dict-index');

    my $curdir = Cwd::cwd();
    eval {
        chdir $dict_source;

        my @cmds = (
            [ $dict_index, '-f', $self->input_encoding, '-t', $self->output_encoding ],
            [ $MAKE, "install" ]
        );

        foreach my $cmd (@cmds) {
            if (system(@$cmd) != 0) {
                die "Failed to execute '@$cmd': $!";
            }
        }
        chdir $curdir;
    };
    if (my $e = $@) {
        chdir $curdir;
        die $e;
    }
}

package Text::MeCab::Dict::Entry;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(
    surface left_id right_id cost pos category1 category2 category3 
    inflect inflect_type original yomi pronounce extra
);

sub new
{
    my $class = shift;
    $class->SUPER::new({ 
        left_id  => -1,
        right_id => -1,
        cost     => 0,
        @_
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Text::MeCab::Dict - Utility To Work With MeCab Dictionary

=head1 SYNOPSIS

  use Text::MeCab::Dict;

  my $dict = Text::MeCab::Dict->new(
    dict_source => "/path/to/mecab-ipadic-source"
  );
  $dict->add(
    surface      => $surface,        # 表層形
    left_id      => $left_id,        # 左文脈ID
    right_id     => $right_id,       # 右文脈ID
    cost         => $cost,           # コスト
    pos          => $part_of_speech, # 品詞
    category1    => $category1,      # 品詞細分類1
    category2    => $category2,      # 品詞細分類2
    category3    => $category3,      # 品詞細分類3

    # XXX this below two parameter names need blessing from a knowing
    # expert, and is subject to change
    inflect      => $inflect,        # 活用形
    inflect_type => $inflect_type,   # 活用型

    original     => $original,       # 原形
    yomi         => $yomi,           # 読み
    pronounce    => $pronounce,      # 発音
    extra        => \@extras,        # ユーザー設定
  );
  $dict->write('foo.csv');
  $dict->rebuild();

=head1 METHODS

=head2 new

Creates a new instance of Text::MeCab::Dict. 

The path to the source of mecab-ipadic is required:

  my $dict = Text::MeCab::Dict->new(
    dict_source => "/path/to/mecab-ipadic-source"
  );

If you are in an environment where mecab-config is NOT available, you must
also specify libexecdir, which is where mecab-dict-index is installed:

  my $dict = Text::MeCab::Dict->new(
    dict_source => "/path/to/mecab-ipadic-source",
    libexecdir  => "/path/to/mecab/libexec/",
  );

=head2 add

Adds a new entry to be appended to the dictionary. Please see SYNOPSIS for
arguments.

=head2 write

Writes out the entries that were added via add() to the specified file
location. If the file name does not look like an absolute path, the name
will be treated relatively from dict_source

=head2 rebuild

Rebuilds the index. This usually requires that you are have root privileges

=head1 SEE ALSO

http://mecab.sourceforge.net/dic.html

=cut
