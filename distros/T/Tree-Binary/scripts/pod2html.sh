#!/bin/bash

DEST=$DR/Perl-modules/html/Tree

pod2html.pl -i lib/Tree/Binary.pm                               -o $DEST/Binary.html
pod2html.pl -i lib/Tree/Binary/Search.pm                        -o $DEST/Binary/Search.html
pod2html.pl -i lib/Tree/Binary/VisitorFactory.pm                -o $DEST/Binary/VisitorFactory.html
pod2html.pl -i lib/Tree/Binary/Search/Node.pm                   -o $DEST/Binary/Search/Node.html
pod2html.pl -i lib/Tree/Binary/Visitor/Base.pm                  -o $DEST/Binary/Visitor/Base.html
pod2html.pl -i lib/Tree/Binary/Visitor/BreadthFirstTraversal.pm -o $DEST/Binary/Visitor/BreadthFirstTraversal.html
pod2html.pl -i lib/Tree/Binary/Visitor/InOrderTraversal.pm      -o $DEST/Binary/Visitor/InOrderTraversal.html
pod2html.pl -i lib/Tree/Binary/Visitor/PostOrderTraversal.pm    -o $DEST/Binary/Visitor/PostOrderTraversal.html
pod2html.pl -i lib/Tree/Binary/Visitor/PreOrderTraversal.pm     -o $DEST/Binary/Visitor/PreOrderTraversal.html
