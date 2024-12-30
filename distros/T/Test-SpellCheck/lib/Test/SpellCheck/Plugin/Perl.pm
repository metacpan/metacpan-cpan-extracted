package Test::SpellCheck::Plugin::Perl;

use strict;
use warnings;
use 5.026;
use Module::Load qw( load );
use Test::SpellCheck::Plugin::PerlPOD;
use Test::SpellCheck::Plugin::PerlWords;
use base qw( Test::SpellCheck::Plugin::Combo );
use Carp qw( croak );
use PerlX::Maybe;
use Ref::Util qw( is_plain_arrayref );
use experimental qw( signatures );

our @CARP_NOT = qw( Test::SpellCheck );

# ABSTRACT: Test::SpellCheck plugin for checking spelling in Perl source
our $VERSION = '0.02'; # VERSION


sub new ($class, %args)
{
  my $lang_class;
  my @lang_args;

  if(defined $args{lang})
  {
    if(is_plain_arrayref $args{lang})
    {
      $lang_class = 'Test::SpellCheck::Plugin::PrimaryDictionary';
      my($affix, $dic) = $args{lang}->@*;
      @lang_args = (affix => $affix, dictionary => $dic);
    }
    elsif($args{lang} =~ /^([a-z]{2})-([a-z]{2})$/i)
    {
      $lang_class = join '::', 'Test::SpellCheck::Plugin::Lang', uc $1, uc $2;
    }
    else
    {
      croak "bad language: $args{lang}";
    }
  }
  else
  {
    $lang_class = 'Test::SpellCheck::Plugin::Lang::EN::US';
  }

  load $lang_class;

  my @plugins = (
    $lang_class->new(@lang_args),
    Test::SpellCheck::Plugin::PerlWords->new,
    Test::SpellCheck::Plugin::PerlPOD->new(
      maybe skip_sections => $args{skip_sections},
    ),
  );

  if($args{check_comments} // 1)
  {
    require Test::SpellCheck::Plugin::PerlComment;
    push @plugins, Test::SpellCheck::Plugin::PerlComment->new;
  }

  $class->SUPER::new(@plugins);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::SpellCheck::Plugin::Perl - Test::SpellCheck plugin for checking spelling in Perl source

=head1 VERSION

version 0.02

=head1 SYNOPSIS

In Perl:

 # these are the default values for all options.
 spell_check ['Perl',
   lang           => 'en-us',
   skip_sections  => ['contributors', 'author', 'copyright and license'],
   check_comments => 1,
 ];

In L<spellcheck.ini>:

 [Perl]
 lang           = en-us
 skip_sections  = contributors
 skip_sections  = author
 skip_sections  = copyright and license
 check_comments = 1

=head1 DESCRIPTION

This plugin is a L<Combo|Test::SpellCheck::Plugin::Combo> plugin that provides reasonable
defaults for checking spelling of most Perl distributions.  It is also the default plugin used
when you do not otherwise provide one.  It roughly combines these plugins:

=over 4

=item L<Lang::EN::US|Test::SpellCheck::Plugin::Lang::EN::US>

Although a different primary dictionary can  be specified with the C<lang> option.

=item L<PerlWords|Test::SpellCheck::Plugin::PerlWords>

Add Perl jargon like "autovivify" and C<gethostbyaddr>.

=item L<PerlPOD|Test::SpellCheck::Plugin::PerlPOD>

For checking POD for spelling errors.

=item L<PerlPOD|Test::SpellCheck::Plugin::PerlComments>

For checking Perl comments for spelling errors.  The use of this plugin can be turned off
with the C<check_comments> option below.

=back

=head1 OPTIONS

=head2 skip_sections

This is a list of POD sections that you do not want to check for spelling errors.
Note that the section I<titles> will still be checked, just not the content.  This
is most useful for skipping "author" and "copyright and license" sections which
frequently are and contain a lot of names.

=head2 lang

This allows using a different human language dictionary for your test.  It can be
either a string of the form C<xx-yy> where C<xx> and C<yy> are respectively the
language and country code.  This only works if there is already a plugin that
provides that dictionary, like L<Test::SpellCheck::Plugin::Lang::EN::US>.

 spell_check ['Perl', lang => ['/foo/bar/baz.aff', '/foo/bar/baz.dic']];

Or in C<spellcheck.ini>:

 [Perl]
 lang = /foo/bar/baz.aff
 lang = /foo/bar/baz.dic

You can also specify a pair of files to use, if there is no plugin, or you prefer to
specify the path to the dictionary files.

=head2 check_comments

By default non-POD comments are checked for spelling errors.  If you prefer not to
check comments you can set this to a false value.

=head1 CONSTRUCTOR

=head2 new

 my $plugin = Test::SpellCheck::Plugin::Perl->new(%options);

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
