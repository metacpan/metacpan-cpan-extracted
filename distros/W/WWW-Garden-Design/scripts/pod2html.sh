#!/bin/bash

INFIX=WWW/Garden
DEST=$DR/Perl-modules/html/$INFIX

pod2html.pl -i lib/$INFIX/Design.pm									-o $DEST/Design.html
pod2html.pl -i lib/$INFIX/Design/Controller/AutoComplete.pm			-o $DEST/Design/Controller/AutoComplete.html
pod2html.pl -i lib/$INFIX/Design/Controller/Flower.pm				-o $DEST/Design/Controller/Flower.html
pod2html.pl -i lib/$INFIX/Design/Controller/GetAttributeTypes.pm	-o $DEST/Design/Controller/GetAttributeTypes.html
pod2html.pl -i lib/$INFIX/Design/Controller/GetDetails.pm			-o $DEST/Design/Controller/GetDetails.html
pod2html.pl -i lib/$INFIX/Design/Controller/Initialize.pm			-o $DEST/Design/Controller/Initialize.html
pod2html.pl -i lib/$INFIX/Design/Controller/Object.pm				-o $DEST/Design/Controller/Object.html
pod2html.pl -i lib/$INFIX/Design/Controller/Search.pm				-o $DEST/Design/Controller/Search.html
pod2html.pl -i lib/$INFIX/Design/Database/Base.pm					-o $DEST/Design/Database/Base.html
pod2html.pl -i lib/$INFIX/Design/Util/Config.pm						-o $DEST/Design/Util/Config.html
pod2html.pl -i lib/$INFIX/Design/Util/Create.pm						-o $DEST/Design/Util/Create.html
pod2html.pl -i lib/$INFIX/Design/Util/Export.pm						-o $DEST/Design/Util/Export.html
pod2html.pl -i lib/$INFIX/Design/Util/Import.pm						-o $DEST/Design/Util/Import.html
pod2html.pl -i lib/$INFIX/Design/Database.pm						-o $DEST/Design/Database.html
