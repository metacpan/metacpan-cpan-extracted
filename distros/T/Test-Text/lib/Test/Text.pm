package Test::Text;

use warnings;
use strict;
use utf8; # Files and dictionaries might use utf8
use Encode;

use Carp;
use File::Slurp::Tiny 'read_file';
use Text::Hunspell;
use Test::Text::Sentence qw(split_sentences);
use v5.22;

use version; our $VERSION = qv('0.6.1'); # Works with UTF8 and includes Text::Sentence

use base 'Test::Builder::Module'; # Included in Test::Simple

my $CLASS = __PACKAGE__;
our @EXPORT= 'just_check';

BEGIN {
  binmode *STDOUT, ":encoding(utf8)";
  binmode *STDERR, ":encoding(utf8)";
}

# Module implementation here
sub new {
  my $class = shift;
  my $dir = shift || croak "Need a single directory with text" ;
  my $data_dir = shift || croak "No default spelling data directory\n";
  my $language = shift || "en_US"; # Defaults to English
  my @files = @_ ; # Use all appropriate files in dir by default
  if (!@files ) {
    @files = glob("$dir/*.md $dir/*.tex $dir/*.txt $dir/*.markdown)");
  } else {
    @files = map( "$dir/$_", @files );
  }
  my $self = { 
	      _dir => $dir,
	      _data_dir => $data_dir,
	      _files => \@files
  };
  bless  $self, $class;

  # Speller declaration
  my $speller = Text::Hunspell->new(
				  "$data_dir/$language.aff",    # Hunspell or other affix file
				  "$data_dir/$language.dic"     # Hunspell or other dictionary file
				   );
  croak "Couldn't create speller: $1" if !$speller;
  $self->{'_speller'} = $speller;
  $speller->add_dic("$dir/words.dic"); #word.dic should be in the text directory
  return $self;
}

sub dir {
    my $self = shift;
    return $self->{'_dir'};
}

sub files {
  my $self = shift;
  return $self->{'_files'};
}

sub check {
  my $self = shift;
  my $tb= $CLASS->builder;
  my $speller = $self->{'_speller'};
  my %vocabulary;
  my @sentences;
  for my $f ( @{$self->files}) {
    my $file_content= read_file($f, binmode => ':utf8');
    if ( $f =~ /(\.md|\.markdown)/ ) {
      $file_content = _strip_urls( $file_content);
      $file_content = _strip_code( $file_content);
    }
    push @sentences, split_sentences( $file_content );
    $tb->cmp_ok( scalar @sentences, ">=", 1, "We have " . ($#sentences + 1) . " sentences");
    my @words = ($file_content =~ m{\b(\p{L}+)\b}g);
    for my $w (@words) {
      next if !$w;
      $vocabulary{lc($w)}++;
      $tb->ok( $speller->check( $w),  "$f >> '". encode_utf8($w) . "'");
    }
    my $different_words = scalar keys %vocabulary;
    $tb->cmp_ok(  $different_words, ">", 1, "We have $different_words different words");
  }
}

sub _strip_urls {
  my $text = shift || carp "No text";
  $text =~ s/\[(.+?)\]\(\S+\)/$1/g;
  return $text;
}

sub _strip_code {
  my $text = shift || carp "No text in _strip_code";
  $text =~ s/~~~[\w\W]*?~~~//g;
  $text =~ s/```[\w\W]+?```//g;
  $text =~ s/`[^`]+?`//g;
  return $text;
}


sub just_check {
    my $dir = shift || croak "Need a directory with text" ;
    my $data_dir = shift || croak "No default spelling data directory\n";
    my $language = shift || "en_US"; # Defaults to English
    my $tesxt = Test::Text->new($dir, $data_dir, $language, @_);
    $tesxt->check();
    $tesxt->done_testing;
}

sub done_testing {
  my $tb= $CLASS->builder;
  $tb->done_testing;
}

"All over, all out, all over and out"; # Magic circus phrase said at the end of the show

__END__

=head1 NAME

Test::Text - A module for testing text files for spelling and (maybe) more. 

=head1 VERSION

This document describes Test::Text version 0.5.0

=head1 SYNOPSIS

    use Test::Text;

    my $dir = "path/to/text_dir"; 
    my $data = "path/to/data_dir"; 

    my $tesxt = Test::Text->new($text_dir, $dict_dir); # Defaults to English: en_US and all files

    $tesxt = Test::Text->new($text_dir, $dict_dir, "en_US", $this_file, $that_file); # Tests only those files

    $tesxt = Test::Text->new($text_dir, $dict_dir, "es_ES"); # Uses alternate language

    $testxt->check(); # spell-checks plain or markdown text in that dir or just passed

    $testxt->done_testing(); # all over and out

    #Alternative procedural/single-function interface
    just_check( $dir, $data ); # Includes done_testing


=head1 DESCRIPTION

This started as a spell and quality check for my novel, "Manuel the
Magnificent Mechanical Man". Eventually, it can be used for checking
any kind of markdown-formatted text, be it fiction or non-fiction. The first version included
as documentation, the novel itself (check it out at L<Text::Hoborg::Manuel> and also in the test
directory the markdown source. 

This module is a more general text-tester (that's a C<tesxter>) which
can be used on any external set of texts.  This all came from the idea
that L<writing is like software
development|https://medium.com/i-m-h-o/6d154a43719c>, which I'm using
throughout.

You will need to install Hunspell and any dictionary you will be
    using. By default, Hunspell install quite a few and you can also
    use the dictionaries from C<myspell>. Problem is
    L<Text::Hunspell>, which is the module used for spelling, does not
    work correctly with dictionaries using Latin1 codification, which
    are the ones supplied by default with Hunspell. For Spanish, for
    instance, you will have to obtain your own dictionary with UTF8
    codification, with the ones supplied with L<Sublime
    Text|https://github.com/SublimeText/Dictionaries/> being a very
    good option. The Spanish files obtained there are included in this module for testing purposes.

=head1 INTERFACE

=head2 new $text_dir, $data_dir [, $language = 'en_US'] [,  @files]

Creates an object with link to text and markdown files identified by
    extension.  There is no default for
    the dir since it is supposed to be external. If an array of files
    is given, only those are used and not all the files inside the
    directory; these files will be prepended the C<$text_dir> to get
    the whole path. 

=head2 files

Returns the files it will be checking.

=head2 dir

Returns the dir the source files are in. Since this is managed from the
object, it is useful for other functions.

=head2 check

Check files. This is the only function you will have to call from from your test script.

=head2 _strip_urls( text )

Strips URLs in Markdown format 

=head2 _strip_code( text )

Strips URLs in Markdown format 

Strips some code marks in Markdown format


=head2 just_check $text_dir, $data_dir [, $language = 'en_US'] [,  @files]

Everything you need in a single function. The first directory will
    include text and auxiliary directory files, the second main
    dictionary and suffix files. By default all C<*.md> files will be
    checked. Basically equivalent to the creation of an object followed by C<$ob->check()>  

=head2 done_testing

Called after all tests have been performed.

=head1 DEPENDENCIES

Test::Text requires L<Text::Hunspell> and the 
C<en_US> dictionnary for C<hunspell>, which you can install with
C<sudo apt-get install hunspell-en-us>, but since I found no way of expressing this
dependency within Makefile.PL, I have added it to the C<data> dir,
mainly. Latest version requires L<Test::Builder>. It also includes the
    C<es> dictionnary in the latest version, also included. If you
    need any other file, check previously that it's in the
    C</usr/share/hunspell> dir, but since this module is mainly
    intended to be used for CI, I had rather include these files in
    the distro. 

If you use any language with heavy dependencies on UTF8 like Spanish,
    the supplied dictionaries will be no use. Check the UTF
    dictionaries available from SublimeText; even so, the Spanish
    affix file yields warnings so you might want to use the version I
    patched, available at the GitHub repo. 

=head1 Development and bugs

Development of this module is hosted at
    L<GitHub|http://github.com/JJ/Test-Text>. Use it for forking, bug
    reports, checking it out, giving stars, whatever. Use also the
    CPAN interface if you want.

=head1 SEE ALSO

L<Manuel, the Marvelous Mechanical
    Man|https://www.amazon.com/Manuel-Magnificent-Mechanical-Logical-Natural-History-ebook/dp/B00ED084BK/ref=as_li_ss_til?tag=perltutobyjjmere&linkCode=w01&linkId=4PA3TNKRGGBZKHOE&creativeASIN=B00ED084BK>,
    the novel that spawned all this, or the other way around.  Check
    out also L<Text::Hunspell>, an excellent interface to the
    C<hunspell> spelling program.

=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>

Gabor Szabo C<< <szabgab@cpan.org> >> has contributed many patches. And encouragement. 

Regexes for markdown code taken from node-markdown https://github.com/JJ/node-markdown-spellcheck by Luke Page https://github.com/lukeapage

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, 2017, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
