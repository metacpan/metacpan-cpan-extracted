use ExtUtils::MakeMaker;

$module = 'Chump.pm';

%depends = (    'Text::DelimMatch' => 0,
                'URI::Find'        => 0,
		'Tie::IxHash'      => 0,
		'Test::More'	   => 0,
              );

# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Text::Chump',
    'VERSION_FROM'	=> 'Chump.pm', # finds $VERSION
    'PREREQ_PM'		=> \%depends,
    'AUTHOR'            => 'Simon Wistow <simon@thegestalt.org>',
) if $0 =~ m/makefile.pl/i;

sub MY::postamble {
    return <<EOF
README: $module Changes ../makereadme
\t../makereadme $module \$(NAME) \$(VERSION) > README

dist: README

EOF
}

1;
