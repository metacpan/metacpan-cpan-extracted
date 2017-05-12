use inc::Module::Install;

# Define metadata
name            'WWW-Spinn3r',
all_from        'lib/WWW/Spinn3r.pm';
        
# Specific dependencies
requires        'XML::Twig';
requires        'DateTime';
requires        'Class::Accessor'; 
requires        'LWP::UserAgent';
requires        'Time::HiRes';
requires        'Test::Memory::Cycle';

license         'perl';
        
auto_install;
WriteAll;

