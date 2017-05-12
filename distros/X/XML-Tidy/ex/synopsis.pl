use XML::Tidy;

# create new   XML::Tidy object from         MainFile.xml
my $tidy_obj = XML::Tidy->new('filename' => 'MainFile.xml');

# Tidy up the indenting
   $tidy_obj->tidy();

# Write out changes back to MainFile.xml
   $tidy_obj->write();

