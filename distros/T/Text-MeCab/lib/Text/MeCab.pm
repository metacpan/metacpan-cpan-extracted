package Text::MeCab;
use strict;
use warnings;
use 5.006;
use Exporter 'import';
our ($VERSION, @ISA, %EXPORT_TAGS, @EXPORT_OK);
BEGIN
{
    $VERSION = '0.20016';
    if ($] > 5.006) {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
    } else {
        require DynaLoader;
        @ISA = qw(DynaLoader);
        __PACKAGE__->bootstrap;
    }

    %EXPORT_TAGS = (all => [ qw(
        MECAB_NOR_NODE
        MECAB_UNK_NODE
        MECAB_BOS_NODE
        MECAB_EOS_NODE
        MECAB_EON_NODE
        MECAB_SYS_DIC
        MECAB_USR_DIC
        MECAB_UNK_DIC
        MECAB_ONE_BEST
        MECAB_NBEST
        MECAB_PARTIAL
        MECAB_MARGINAL_PROB
        MECAB_ALTERNATIVE
        MECAB_ALL_MORPHS
        MECAB_ALLOCATE_SENTENCE
    ) ]);
    @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;
}

my %BOOLEAN_OPTIONS = (
    map { ($_, 'bool') } qw(
        --all-morphs --partial --allocate-sentence --version --help
    )
);

sub new
{
    my $class = shift;

    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    $args{'allocate-sentence'} = 1;

    my @args = ('perl-TextMeCab');
    while (my($key, $value) = each %args) {
        $key =~ s/_/-/g;
        $key =~ s/^/--/;

        if (exists $BOOLEAN_OPTIONS{$key}) {
            push @args, $key;
        } else {
            push @args, join('=', $key, $value);
        }
    }

    $class->_xs_create(\@args);
}

1;

__END__

=head1 NAME

Text::MeCab - Alternate Interface To libmecab

=head1 SYNOPSIS

  use Text::MeCab;
  my $mecab = Text::MeCab->new({
    rcfile             => $rcfile,
    dicdir             => $dicdir,
    userdic            => $userdic,
    lattice_level      => $lattice_level,
    all_morphs         => $all_morphs,
    output_format_type => $output_format_type,
    partial            => $partial,
    node_format        => $node_format,
    unk_format         => $unk_format,
    bos_format         => $bos_format,
    eos_format         => $eos_format,
    input_buffer_size  => $input_buffer_size,
    allocate_sentence  => $allocate_sentence,
    nbest              => $nbest,
    theta              => $theta,
  });

  for (my $node = $mecab->parse($text); $node; $node = $node->next) {
     # See perdoc for Text::MeCab::Node for list of methods
     print $node->surface, "\n";
  }

  # use constants
  use Text::MeCab qw(:all);
  use Text::MeCab qw(MECAB_NOR_NODE);

  # check what mecab version we compiled against?
  print "Compiled with ", &Text::MeCab::MECAB_VERSION, "\n";

=head1 DESCRIPTION

libmecab (http://mecab.sourceforge.ne.jp) already has a perl interface built 
with it, so why a new module? I just feel that while a subtle difference,
making the perl interface through a tied hash is just... weird.

So Text::MeCab gives you a more natural, Perl-ish way to access libmecab!

WARNING: Version 0.20015 has only been tested against libmecab 0.99.

=head1 INSTALLATION

You need to have mecab already installed. You also need a dictionary,
such as ipadic.

Because we want to work with UTF-8 internally, we need to know what your
dictionary's charset is. You need to tell our probe script (which gets invoked by Makefile.PL) interactively asks you this. If you want to specify it from elsewhere, you need to specify via environment variable:

    PERL_TEXT_MECAB_ENCODING=utf-8 perl Makefile.PL
    # or, say, you're using cpanm
    PERL_TEXT_MECAB_ENCODING=utf-8 cpanm Text::MeCab

If you want to build Text::MeCab with debugging info, specify it on the
comamnd line to Makefile.PL:

    perl Makefile.PL --debugging

=head1 Text::MeCab AND FORMATS

mecab allows users to specify an output format, via --*-format options.
These are respected ONLY if you use the format() method:

  my $mecab = Text::MeCab->new({
    output_format_type => "user",
    node_format => "%m %pn"
  });

  for(my $node = $mecab->parse($text); $node; $node = $node->next) {
    print $node->format($mecab);
  }

Note that you also need to set the output_format_type parameter as well.

=head1 Text::MeCab AND SCOPING

[NOTE: The memory management issue has been changed since 0.09]

libmecab's default behavior is such that when you analyze a text and get a
node back, that node is tied to the mecab "tagger" object that performed the
analysis. Therefore, when that tagger is destroyed via mecab_destroy(),
all nodes that are associated to it are freed as well.

Text::MeCab defaults to the same behavior, so the following won't work:

  sub get_mecab_node {
     my $mecab = Text::MeCab->new;
     my $node  = $mecab->parse($_[0]);
     return $node;
  }

  my $node = get_mecab_node($text);

By the time get_mecab_node() returns, the Text::MeCab object is DESTROY'ed, 
and so is $node (actually, the object exists, but it will complain when you
try to access the node's internals, because the C struct that was there
has already been freed).

In such cases, use the dclone() method. This will copy the *entire* node
structure and create a new Text::MeCab::Node::Cloned instance. 

  sub get_mecab_node {
     my $mecab = Text::MeCab->new;
     my $node  = $mecab->parse($_[0]);
     return $node->dclone();
  }

The returned Text::MeCab::Node::Cloned object is exactly the same as 
Text::MeCab::Node object on the surface. It just uses a different but
very similar C struct underneath. It is blessed into a different namespace
only because we need to use a different memory management strategy.

Do be aware of the memory issue. You WILL use up twice as much memory.

Also please note that if you try the first example, accessing the node 
*WILL* result in a segfault. This is *NOT* a bug: it's a feature :) 
While it is possible to control the memory management such that accessing 
a field in a node that has already expired results in a legal croak(), 
we do not go to the length to ensure this, because it will result in
a performance penalty. 

Just remember that unless you dclone() a node, then you are NOT allowed to
access it when the original tagger goes out scope:

   {
       my $mecab = Text::MeCab->new;
       $node = $mecab->parse(...);
   }

   $node->surface; # segfault!!!!

Always remember to dclone() before doing this!

=head1 PERFORMANCE

Belows is the result of running tools/benchmark.pl on my PowerBook:

  daisuke@beefcake Text-MeCab$ perl tools/benchmark.pl 
               Rate      mecab text_mecab
  mecab      5.53/s         --       -63%
  text_mecab 14.9/s       170%         --

=head1 METHODS

=head2 new HASHREF | LIST

Creates a new Text::MeCab instance.

You can either specify a hashref and use named parameters, or you can use the
exact command line arguments that the mecab command accepts.

Below is the list of accepted named options. See the man page for mecab for 
details about each option.

=over 4

=item B<rcfile>

=item B<dicdir>

=item B<lattice_level>

=item B<all_morphs>

=item B<output_format_type>

=item B<partial>
t
=item B<node_format>

=item B<unk_format>

=item B<bos_format>

=item B<eos_format>

=item B<input_buffer_size>

=item B<allocate_sentence>

=item B<nbest>

=item B<theta>

=back

=head2 $node = $tagger-E<gt>parse(SCALAR)

Parses the given text via mecab, and returns a Text::MeCab::Node object.

=head2 $version = Text::MeCab::version()

The version number, as returned by libmecab's mecab_version();

=head2 CONSTANTS

=over 4

=item ENCODING

  my $encoding = Text::MeCab::ENCODING

Returns the encoding of the underlying mecab library that was detected at
compile time.

=item MECAB_VERSION

The version number, same as Text::MeCab::version()

=item MECAB_TARGET_VERSION

The version number detected at compile time of Text::MeCab. 

=item MECAB_TARGET_MAJOR_VERSION

The version number detected at compile time of Text::MeCab. 

=item MECAB_TARGET_MINOR_VERSION

The version number detected at compile time of Text::MeCab. 

=item MECAB_CONFIG

Path to mecab-config, if available.

=item MECAB_NOR_NODE

=item MECAB_UNK_NODE

=item MECAB_BOS_NODE

=item MECAB_EOS_NODE

=item MECAB_EON_NODE

=item MECAB_SYS_DIC

=item MECAB_USR_DIC

=item MECAB_UNK_DIC

=item MECAB_ONE_BEST

=item MECAB_NBEST

=item MECAB_PARTIAL

=item MECAB_MARGINAL_PROB

=item MECAB_ALTERNATIVE

=item MECAB_ALL_MORPHS

=item MECAB_ALLOCATE_SENTENCE

=back

=head1 SEE ALSO

http://mecab.sourceforge.ne.jp

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=head1 AUTHOR

Copyright (c) 2006-2011 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>
All rights reserved.

=cut
