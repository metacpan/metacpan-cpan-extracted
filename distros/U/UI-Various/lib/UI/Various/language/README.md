Supporting new languages is easy:

1. Copy builder/language-XX.pm into a new language file XX.pm here,
   replacing the XX in the new file-name with the appropriate ISO-639-1
   language code.
2. Change the 4 FIXMEs in the new file.  (Replace the first with the
   ISO-639-1 language code and the other three with the full name of the
   language.)
3. Read the comment in front of the text hash %T and keep it in mind!
4. Run "builder/update-language.pl XX" with XX again being the ISO-639-1
   language code to add all keys and English reference texts to the new
   file.
5. Add the missing texts in the new languages corresponding to the
   English reference texts in the TODO comments.  If the English
   sequence of the sprintf arguments does not match a good text the new
   language, remember that you can change the sequence using '<index>$',
   e.g. '%2$s %s'.  (Note that you have to escape the '$' in strings
   with double quotes '"': "%2\$s %s".)

If new text are missing (or other texts are no longer needed) after an
update of the package, simple go through the steps 4 and 5 again.
