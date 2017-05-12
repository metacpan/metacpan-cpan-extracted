#!/bin/bash

pod2html.pl -i lib/Tree/Persist.pm                    -o /dev/shm/html/Perl-modules/html/Tree/Persist.html
pod2html.pl -i lib/Tree/Persist/Base.pm               -o /dev/shm/html/Perl-modules/html/Tree/Persist/Base.html
pod2html.pl -i lib/Tree/Persist/DB.pm                 -o /dev/shm/html/Perl-modules/html/Tree/Persist/DB.html
pod2html.pl -i lib/Tree/Persist/File.pm               -o /dev/shm/html/Perl-modules/html/Tree/Persist/File.html
pod2html.pl -i lib/Tree/Persist/DB/SelfReferential.pm -o /dev/shm/html/Perl-modules/html/Tree/Persist/DB/SelfReferential.html
pod2html.pl -i lib/Tree/Persist/File/XML.pm           -o /dev/shm/html/Perl-modules/html/Tree/Persist/File/XML.html
