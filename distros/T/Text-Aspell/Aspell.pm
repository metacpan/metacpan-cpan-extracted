package Text::Aspell;

require DynaLoader;

use vars qw/  @ISA $VERSION /;
@ISA = 'DynaLoader';

$VERSION = '0.09';

bootstrap Text::Aspell $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Text::Aspell - Perl interface to the GNU Aspell library

=head1 SYNOPSIS

    use Text::Aspell;
    my $speller = Text::Aspell->new;

    die unless $speller;


    # Set some options
    $speller->set_option('lang','en_US');
    $speller->set_option('sug-mode','fast');


    # check a word
    print $speller->check( $word )
          ? "$word found\n"
          : "$word not found!\n";

    # lookup up words
    my @suggestions = $speller->suggest( $misspelled );


    # lookup config options
    my $language = $speller->get_option('lang');
    print $speller->errstr unless defined $language;

    # fetch a config item that is a list
    my @sgml_extensions = $speller->get_option_as_list('sgml-extension');


    # fetch the configuration keys and their default settings
    my $options = $speller->fetch_option_keys;

    # or dump config settings to STDOUT
    $speller->print_config || $speller->errstr;




    # What dictionaries are installed as simple strings
    my @dicts = $speller->list_dictionaries;

    # or as an array of hashes
    @dicts = $speller->dictionary_info;
    print Data::Dumper::Dumper( \@dicts );



Here's an example how to create and use your own word list

Create a dictionary:

    $ aspell --lang=en create master ./dictionary.local < space_separated_word_list

Then in your code:

    use Text::Aspell;
    my $speller = Text::Aspell->new;
    die unless $speller;
    $speller->set_option('master','./dictionary.local');
    # check a word
    print $speller->check( $word )
          ? "$word found\n"
          : "$word not found!\n";



=head1 DESCRIPTION

This module provides a Perl interface to the GNU Aspell library.  This module
is to meet the need of looking up many words, one at a time, in a single
session, such as spell-checking a document in memory.


The GNU C interface is described at:

    http://aspell.net/man-html/Through-the-C-API.html#Through-the-C-API

It's worth looking over the way config and speller (manager) objects are
created when using the Aspell C API as some of that is hidden in the
Text::Aspell module.

For example, with Text::Aspell you do not have to explicitly create a speller
object.  The speller (manager) object is created automatically the first time
you call suggest() or check().

Note also that once the speller object is created some (all?) config options
cannot be changed.  For example, setting configuration options such as "lang"
are what determine what dictionary Aspell will use.  Once the speller object is
created that dictionary will be used.  I.e. setting "lang" after the speller
object is created will have no effect.


=head1 DEPENDENCIES

You MUST have installed GNU Aspell library version 0.50.1 or higher on your
system before installing this Text::Aspell Perl module.  If installing Aspell
using your operating system's package management system, you may need to
install the Aspell development package (for example, on Debian libaspell-dev).

Aspell can source can be downloaded from:

    http://aspell.net


There have been a number of bug reports because people failed to install aspell
before installing this module.  This is an interface to the aspell library
installed on your system, not a replacement for aspell.

You must also have the English dictionary installed when running the module's
test suite.

Also, please see the README and Changes files.  README may have specific
information about your platform.



=head1 METHODS

The following methods are available:

=over 4

=item $speller = Text::Aspell->new;

Creates a new speller object.  New does not take any parameters (future version
may allow options set by passing in a hash reference of options and value pairs).
Returns C<undef> if the object could not be created, which is unlikely.

Internally, new() creates an object to store Aspell structures (AspellConfig,
AspellSpeller, and a space for an error string and then calls new_aspell_config();

=item $speller->set_option($option_name, $value);

Sets the configuration option C<$option_name> to the value of C<$value>.
Returns C<undef> on error, and the error message can be printed with $speller->errstr.

You should set configuration options before calling the $speller->create_speller
method.  See the GNU Aspell documentation for the available configuration settings
and how (and when) they may be used.

=item $speller->remove_option($option_name);

Removes (sets to the default value) the configuration option specified by C<$option_name>.
Returns C<undef> on error, and the error message can be printed with $speller->errstr.
You may only set configuration options before calling the $speller->create_speller
method.

=item $string = $speller->get_option($option_name);

Returns the current setting for the given configuration option.  The values are strings.
For configuration options that are lists used the C<get_option_as_list()> method.

Returns C<undef> on error, and the error message can be printed with $speller->errstr.

Note that this may return different results depending on if it's called before or after
$speller->create_speller is called.

=item  @list = $speller->get_option_as_list($option_name);

Returns an array of list items for the given option.  Use this method to fetch configuration
values that are of type I<list>.

Returns C<undef> on error, and the error message can be printed with $speller->errstr.

Note that this may return different results depending on if it's called before or after
$speller->create_speller is called.

=item $options = $speller->fetch_option_keys;

Returns a hash of hashes.  The keys are the possible configuration options
and the values is a hash with keys of:

    desc    : A short description of the option
    default : The default value for this option
    type    : The data type of option (see aspell.h)


=item $speller->print_config;

Prints the current configuration to STDOUT.  Useful for debugging.
Note that this will return different results depending on if it's called before or after
$speller->create_speller is called.

=item $speller->errstr;

Returns the error string from the last error.  Check the previous call for an C<undef> return
value before calling this method

=item $errnum = $speller->errnum;

Returns the error number from the last error.  Some errors may only set the
error string ($speller->errstr) on errors, so it's best to check use the errstr method
over this method.

This method is deprecated.


=item $found = $speller->check($word);

Checks if a word is found in the dictionary.  Returns true if the word is found
in the dictionary, false but defined if the word is not in the dictionary.
Returns C<undef> on error, and the error message can be printed with $speller->errstr.

This calls $speller->create_speller if the speller has not been created by an
explicit call to $speller->create_speller.

=item @suggestions = $speller->suggest($word)

Returns an array of word suggestions for the specified word.  The words are returned
with the best guesses at the start of the list.


=item $speller->create_speller;

This method is normally not called by your program.
It is called automatically the first time $speller->check() or
$speller->suggest() is called to create a spelling "speller".

You might want to call this when your program first starts up to make the first
access a bit faster, or if you need to read back configuration settings before
looking up words.

The creation of the speller builds a configuration
profile in the speller structure. Results from calling print_config() and get_option() will
change after calling create_speller().  In general, it's best to read config settings back
after calling create_speller() or after calling spell() or suggest().
Returns C<undef> on error, and the error message can be printed with $speller->errstr.

=item $speller->add_to_session($word)

=item $speller->add_to_personal($word)

Adds a word to the session or personal word lists.
Words added will be offered as suggestions.

=item $speller->store_replacement($word, $replacement);

This method can be used to instruct the speller which word you used as a replacement
for a misspelled word.  This allows the speller to offer up the replacement next time
the word is misspelled.  See section 6.3 of the GNU Aspell documentation for a better description.

(July 2005 note: best to ignore any return value for now)

=item $speller->save_all_word_lists;

Writes any pending word lists to disk.

=item $speller->clear_session;

Clears the current session word list.

=item @dicts = $speller->list_dictionaries;

This returns an array of installed dictionary files.  Each is a single string
formatted as:

    [name]:[code]:[jargon]:[size]:[module]

Name and code will often be the same, but
name is the complete name of the dictionary which can be used to directly
select a dictionary, and code is the language/region code only.

=item $array_ref = $speller->$speller->dictionary_info;

Like the C<list_dictionaries()> method, this method returns an array of
hash references.  For example, an entry for a dictionary might have the
following hash reference:

    {
        'module' => 'default',
        'code' => 'en_US',
        'size' => 60,
        'jargon' => 'w-accents',
        'name' => 'en_US-w-accents'
    },

Not all hash keys will be available for every dictionary
(e.g. the dictionary may not have a "jargon" key).


=back

=head1 Upgrading from Text::Pspell

Text::Aspell works with GNU Aspell and is a replacement for the
module Text::Pspell.  Text::Pspell is no longer supported.

Upgrading should be a simple process.  Only one method name has changed:
C<create_manager> is now called C<create_speller>.
Code designed to use the old Text::Pspell module may not even call the
C<create_manager> method so this may not be an issue.

The C<language_tag> configuration setting is now called C<lang>.

Diffs for code that uses Text::Pspell might look like:

    -    use Text::Pspell;
    +    use Text::Aspell;

    -    $speller = Text::Pspell->new;
    +    $speller = Text::Aspell->new;

    -    $speller->create_manager || die "Failed to create speller: " . $speller->errstr;
    +    $speller->create_speller || die "Failed to create speller: " . $speller->errstr;

If you used a custom dictionary installed in non-standard location and indexed the dictionary with
Aspell/Pspell .pwli files you will need to change how you access your dictionary (e.g.
by setting the "master" configuration setting with the path to the dictionary).
See the GNU Aspell documentation for details.


=head1 BUGS

Probably.


=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.


=head1 AUTHOR

Bill Moseley moseley@hank.org.

This module is based on a perl module written by Doru Theodor Petrescu <pdoru@kappa.ro>.

Aspell is written and maintained by Kevin Atkinson.

Please see:

    http://aspell.net

=cut
