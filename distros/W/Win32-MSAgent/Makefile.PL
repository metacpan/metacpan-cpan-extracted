use ExtUtils::MakeMaker;

die "Win32::MSAgent can only be installed on Microsoft Windows Platforms\n Makefile not written\n\n" unless $^O eq 'MSWin32';
die "I can't load the MS Agent 2.0 control. Please see the README to find out the required components.\nMakefile not written\n\n" unless tryobject();

sub tryobject
{
    my $object;
    eval {  require Win32::OLE;
            Win32::OLE->Option( Warn => 0 );
            $object = Win32::OLE->new('Agent.Control.2')
         };
    return $object;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Win32::MSAgent',
    VERSION_FROM => 'lib/Win32/MSAgent.pm', # finds $VERSION
    AUTHOR       => 'Jouke Visser <jouke@cpan.org>',
    ABSTRACT_FROM=> 'lib/Win32/MSAgent.pm',
    PREREQ_PM    => {   'Win32::OLE'            => 0,
                        'Win32::SAPI4'          => 0.03,
                        'File::Find::Rule'      => 0,
                        'File::Basename'        => 0
                        }
);
