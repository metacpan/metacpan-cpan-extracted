package Test::SpellCheck::Plugin::StopWords;

use strict;
use warnings;
use 5.026;
use experimental qw( signatures );
use Path::Tiny qw( path );
use Ref::Util qw( is_plain_arrayref );

# ABSTRACT: Test::SpellCheck plugin that adds arbitrary jargon words
our $VERSION = '0.02'; # VERSION


sub new ($class, %args)
{
  my %stopwords;

  if($args{file})
  {
    my @words = path($args{file})->lines_utf8;
    chomp @words;
    $stopwords{$_} = 1 for @words;
  }

  if(defined $args{word})
  {
    if(is_plain_arrayref $args{word})
    {
      $stopwords{$_} = 1 for $args{word}->@*;
    }
    else
    {
      $stopwords{$args{word}} = 1;
    }
  }

  bless {
    stopwords => [sort keys %stopwords],
  }, $class;
}


sub stopwords ($self)
{
  return $self->{stopwords}->@*;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::SpellCheck::Plugin::StopWords - Test::SpellCheck plugin that adds arbitrary jargon words

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 spell_check ['StopWords', word => ['foo','bar','baz']];
 spell_check ['StopWords', file => 'mywords.txt']];

Or from C<spellcheck.ini>:

 [StopWords]
 word = foo
 word = bar
 word = baz
 
 [StopWords]
 file = mywords.txt

=head1 DESCRIPTION

This plugin adds global stopwords that will not be considered as misspelling.
You can use a dictionary for a similar purpose, but unlike using a dictionary,
stopwords will never be offered up as suggestions for misspelled words.

You can specify words in-line as a string or array reference, or you can
specify a filename.  The file should contain stopwords in UTF-8 format,
one per line.  You can specify both in-line words and a file.

=head1 OPTIONS

=head2 word

List of stopwords.

=head2 file

File path containing the stopwords.

=head1 CONSTRUCTOR

=head2 new

 my $plugin = Test::SpellCheck::Plugin::StopWords->new(%options);

This creates a new instance of the plugin.  Any of the options documented above
can be passed into the constructor.

=head1 SEE ALSO

=over 4

=item L<Test::SpellCheck>

=item L<Test::SpellCheck::Plugin>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
