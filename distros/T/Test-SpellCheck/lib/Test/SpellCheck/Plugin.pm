package Test::SpellCheck::Plugin;

use strict;
use warnings;
use 5.026;

# ABSTRACT: Plugin documentation for Test::SpellCheck
our $VERSION = '0.02'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::SpellCheck::Plugin - Plugin documentation for Test::SpellCheck

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 perldoc Test::SpellCheck::Plugin

=head1 DESCRIPTION

This is documents commonly available plugins for L<Test::SpellCheck>.  A number
of useful recipes in in that documentation.  This provides an index of commonly
available plugins, as well as documentation for writing your own plugins.

=head1 AVAILABLE PLUGINS

=over 4

=item L<Test::SpellCheck::Plugin::Combo>

The Combo plugin combines one or more other plugins into one.  Because C<spell_check>
only takes one plugin, this is the usual way to combine functionality from multiple
plugins.

=item L<Test::SpellCheck::Plugin::Dictionary>

The Dictionary plugin adds additional (non-primary) dictionaries.  This is frequently
what you want when you have a distribution-level dictionary for local jargon.

=item L<Test::SpellCheck::Plugin::Lang::EN::US>

The C<Lang::EN::US> plugin provides the default dictionary for US English.

=item L<Test::SpellCheck::Plugin::Perl>

The C<Perl> plugin combines a number of Perl related plugins that produce reasonable
defaults for most distributions.

=item L<Test::SpellCheck::Plugin::PerlPOD>

The C<PerlPOD> plugin checks for spelling errors in POD.

=item L<Test::SpellCheck::Plugin::PerlComment>

The C<PerlComment> plugin checks for spelling errors in Perl comments.

=item L<Test::SpellCheck::Plugin::PerlWords>

The C<PerlWords> plugin provides an additional dictionary with common Perl jargon,
like "autovivify" and C<gethostbyaddr>.

=item L<Test::SpellCheck::Plugin::PrimaryDictionary>

The C<PrimaryDictionary> provides a primary affix and dictionary pair.  This is useful
if you want to use a primary dictionary that isn't provided by one of the existing
plugins.

=item L<Test::SpellCheck::Plugin::Stopwords>

The C<Stopwords> plugin adds global stopwords that will cover all files in your test.

=back

=head1 PLUGIN AUTHORS

So you want to write a spell check plugin?  A spell check plugin is just a class.
The only requirement is that there be a C<new> constructor that can optionally take
arguments.  That's it.  All of the other methods documented below are optional.
If you do not implement them then L<Test::SpellCheck> won't use them.

=head2 new (constructor)

 sub new ($class, @args)
 {
   my $self = bless {
     ...
   }, $class;
 }

The constructor should just create a class.  The internal representation is entirely up to
you.  It does have to return an instance.  You may not return a class name and implement
the methods as class methods, even if you do not have any data to store in your class.

=head2 primary_dictionary

 sub primary_dictionary ($self)
 {
   ...
   return ($affix, $dic);
 }

This method returns the path to the primary dictionary and affix files to be used in the
test.  These files should be readable by L<Text::Hunspell::FFI>.  Only one plugin at a
time my define a primary dictionary, so if you are combining several plugins, make sure
that only one implements this method.

=head2 dictionary

 sub dictionary ($self)
 {
   ...
   return @dic;
 }

This method returns a list of one or more additional dictionaries.  These are useful
for jargon which doesn't belong in the main human language dictionary.

=head2 stopwords

 sub stopwords ($self)
 {
   ...
   return @words;
 }

The stopwords method returns a list of words that should not be considered misspelled,
usually because they are valid jargon within the domain of your distribution.  This
is different from maintaining an additional dictionary and using the C<dictionary>
method above because stopwords will never be offered as suggestions.  The stopwords
provided by this method are also different from the C<stopword> event below in the
C<stream> method because they apply to all files, rather than just the current one.

=head2 splitter

 sub splitter ($self)
 {
   ...
   return @cpu;
 }

This is called to allow the plugin to add computer a computer word specification pairs,
which allows L<Test::SpellCheck> to identify computer words and pass them to the
appropriate plugins rather than to Hunspell.  The list C<@cpu> is passed into the
constructor of L<Text::HumanComputerWords>.  The only allowed types are:
C<url_link>, C<module>, C<skip>.  Note that as of now C<path_name> is NOT allowed,
so if you are using the C<default_perl> method then C<path_name> needs to be converted
to a C<skip>.  (other types may be added in the future; including possibly C<path_name>).

=head2 stream

 sub stream ($self, $filename, $splitter, $callback)
 {
   ...
   $callback->( $type, $event_filename, $line_number, $item);
   ...
 }

The stream method parses the input file C<$filename> to find events.  The L<$cplitter>
is an instance of L<Text::HumanCompuer::Words>, or something that implements a C<split>
method exactly like it does.  For each event, it calls the C<$callback> with exactly
four values.  The C<$type> is one of the event types listed below.  The C<$event_filename>
is the filename the event was found in.  This will often be the same as C<$filename>,
but it could be other file if the source file that you are reading supports including
other source files.  The C<$line_number> is the line that event was found at.  The
C<$item> depends on the C<$type>.

=over 4

=item word

Regular human language word that should be checked for spelling C<$item> is the word.
If one or more words from this event type are misspelled then the L<Test::SpellCheck>
test will fail.

=item stopword

Word that should not be considered misspelled for the current C<$filename>.  This is often
for technical jargon which is spelled correctly but not in the regular human language
dictionary.

=item name

The name of the current document.  For Perl this would be determined by something
like L<PPIx::DocumentName> which looks for a C<package> statement or a comment to
indicate the name.  This event should normally only appear once per file.

=item module

a module.  For Perl this will be of the form C<Foo::Bar>.  These are "words" that another
plugin might check, but they would do so against a module registry like CPAN or among
the locally installed modules.

=item url_link

A regular internet URL link.  Another plugin may check to make sure this does not
C<500> or C<404>.

=item pod_link

 my($pod_name, $section) = @$item;

A link to a module.  For Perl this will be of the form C<Foo::Bar> or C<perldelta>.  Another
plugin may check to make sure this is a valid module.  The C<$pod_name> is the name of
the POD to link to, which can be C<undef> for links inside the current document.
The C<$section> is the section to link to or C<undef> for links to the document as a whole.

=item man_link

 my($man_name, $section) = @$item;

A link to a man page.  The C<$man_name> is the name of the man page to link to.  The C<$section>
is an optional section, which will be C<undef> if linking the document as a whole.

=item section

The title of a section in the current document.

=item error

An error happened while parsing the source file.  The error message will be in C<$item>.
If L<Test::SpellCheck> sees this event then it will fail the file.

=back

=head1 SEE ALSO

=over 4

=item L<Text::SpellCheck>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
