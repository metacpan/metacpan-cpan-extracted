use ExtUtils::MakeMaker;
my %options = %{
{
  'TYPEMAPS' => [
    '/usr/share/perl/5.8/ExtUtils/typemap'
  ],
  'NAME' => 'Unicode::CheckUTF8',
  'VERSION_FROM' => 'CheckUTF8.pm'
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
