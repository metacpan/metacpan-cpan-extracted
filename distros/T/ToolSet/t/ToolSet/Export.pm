package t::ToolSet::Export;
use base 'ToolSet';

ToolSet->export(
    'Carp'                      => undef,
    'Getopt::Std'               => '',
    'Text::Wrap'                => [],
    'File::Basename'            => 'basename',
    'File::Spec::Functions'     => 'devnull catdir',
    'Cwd'                       => [qw( cwd fastcwd )],
    'File::Path'                => '!mkpath',
    'autouse'                   => [ 'File::Copy' => 'copy' ],
    'autouse'                   => [ 'File::Find' => 'find' ],
    't::Sample::StoreArguments' => \'a => "String with spaces", b => 1',
);

1; # return true
