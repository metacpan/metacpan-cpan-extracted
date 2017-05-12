#!/bin/bash

DEST=$DR/Perl-modules/html
NAME=WWW/Scraper/Wikipedia/ISO3166

pod2html.pl -i lib/$NAME.pm                   -o $DEST/$NAME.html
pod2html.pl -i lib/$NAME/Database.pm          -o $DEST/$NAME/Database.html
pod2html.pl -i lib/$NAME/Database/Create.pm   -o $DEST/$NAME/Database/Create.html
pod2html.pl -i lib/$NAME/Database/Download.pm -o $DEST/$NAME/Database/Download.html
pod2html.pl -i lib/$NAME/Database/Export.pm   -o $DEST/$NAME/Database/Export.html
pod2html.pl -i lib/$NAME/Database/Import.pm   -o $DEST/$NAME/Database/Import.html
