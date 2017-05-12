#
# Syntax highlighting with own sub :
#    1) generated output
#
# Here, the example is very simple
# and fulfils its need.
# Let's imagine that the file "account.hst"
# is a generated one (by calculation on
# other files) :
# the lines are sure (apart from the bugs)
# to be correctly formatted
#
# To execute it ... press F5, again !
#

use strict;
use lib 'lib';

use Text::Editor::Easy;

# Start from a distant path
use File::Basename;
my ($file_name, $file_path ) = fileparse($0);

Text::Editor::Easy->new(
    {
        'file'      => "${file_path}account.hst",
        'highlight' => { 'sub' => 'highlight', },
        'font_size' => 10,
        'width' => 600,
        'height' => 400,
    }
);

Text::Editor::Easy->manage_event();

sub highlight {
    my ($text) = @_;

    if ( $text =~ /^(#|$)/ ) {
        return [ $text, "comment" ];
    }
    if ( length($text) < 57 ) {
        print "Incorrect : $text\n";
        return [ $text, "black" ];
    }

    # The interface with module "Abstract.pm" will be completely modified
    # This is only a demo
    #
    return (
        [ substr( $text, 0,  3 ),  "dark purple" ],    # jour
        [ substr( $text, 3,  3 ),  "dark green" ],     # mois
        [ substr( $text, 6,  5 ),  "dark red" ],
        [ substr( $text, 11, 11 ), "black" ],
        [ substr( $text, 22, 11 ), "red" ],
        [ substr( $text, 33, 12 ), "dark blue" ],
        [ substr( $text, 45, 12 ), "dark green" ],     # jj mm ssaa
        [ substr( $text, 57 ), "comment" ],
    );
}