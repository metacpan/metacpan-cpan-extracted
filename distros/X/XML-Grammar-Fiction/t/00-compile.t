use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.046

use Test::More  tests => 37 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'XML/Grammar/Fiction.pm',
    'XML/Grammar/Fiction/App/FromProto.pm',
    'XML/Grammar/Fiction/App/ToDocBook.pm',
    'XML/Grammar/Fiction/App/ToHTML.pm',
    'XML/Grammar/Fiction/Err.pm',
    'XML/Grammar/Fiction/FromProto.pm',
    'XML/Grammar/Fiction/FromProto/Node.pm',
    'XML/Grammar/Fiction/FromProto/Node/Comment.pm',
    'XML/Grammar/Fiction/FromProto/Node/Description.pm',
    'XML/Grammar/Fiction/FromProto/Node/Element.pm',
    'XML/Grammar/Fiction/FromProto/Node/InnerDesc.pm',
    'XML/Grammar/Fiction/FromProto/Node/List.pm',
    'XML/Grammar/Fiction/FromProto/Node/Paragraph.pm',
    'XML/Grammar/Fiction/FromProto/Node/Saying.pm',
    'XML/Grammar/Fiction/FromProto/Node/Text.pm',
    'XML/Grammar/Fiction/FromProto/Node/WithContent.pm',
    'XML/Grammar/Fiction/FromProto/Parser.pm',
    'XML/Grammar/Fiction/FromProto/Parser/QnD.pm',
    'XML/Grammar/Fiction/Struct/Tag.pm',
    'XML/Grammar/Fiction/ToDocBook.pm',
    'XML/Grammar/Fiction/ToHTML.pm',
    'XML/Grammar/FictionBase/Event.pm',
    'XML/Grammar/FictionBase/FromProto/Parser/LineIterator.pm',
    'XML/Grammar/FictionBase/FromProto/Parser/XmlIterator.pm',
    'XML/Grammar/FictionBase/TagsTree2XML.pm',
    'XML/Grammar/FictionBase/XSLT/Converter.pm',
    'XML/Grammar/Screenplay.pm',
    'XML/Grammar/Screenplay/App/FromProto.pm',
    'XML/Grammar/Screenplay/App/ToDocBook.pm',
    'XML/Grammar/Screenplay/App/ToHTML.pm',
    'XML/Grammar/Screenplay/Base.pm',
    'XML/Grammar/Screenplay/FromProto.pm',
    'XML/Grammar/Screenplay/FromProto/Parser.pm',
    'XML/Grammar/Screenplay/FromProto/Parser/QnD.pm',
    'XML/Grammar/Screenplay/ToDocBook.pm',
    'XML/Grammar/Screenplay/ToHTML.pm',
    'XML/Grammar/Screenplay/ToTEI.pm'
);



# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') or diag 'got warnings: ', explain \@warnings if $ENV{AUTHOR_TESTING};


