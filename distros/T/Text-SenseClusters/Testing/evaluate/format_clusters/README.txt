*******************************************************************************

                     README.txt FOR format_clusters.pl Testing

                               Version 0.01
                         Copyright (C) 2002-2004
                       Ted Pedersen, tpederse@d.umn.edu
                    Anagha Kulkarni, kulka020@d.umn.edu
                       University of Minnesota, Duluth


*******************************************************************************

Introduction:
----------------
The scripts provided here test the behaviour of format_clusters.pl program under
various normal and error conditions.

Tests:
-------
The test scripts are written in the files test*.sh

Normal Cases
------------
test1.sh tests format_clusters.pl without any option.
test2.sh tests format_clusters.pl with --context option.
test3.sh tests format_clusters.pl with --senseval2 option.

Error Cases
----------------
test4.sh tests format_clusters.pl with both the options (--context --senseval2).
test5.sh tests format_clusters.pl without cluster_solution file.
test6.sh tests format_clusters.pl without rlabel file.
test7.sh tests format_clusters.pl without cluster_solution and rlabel files.

Conclusions:
---------------
We have tested the format_clusters.pl program enough and say that it behaves
according to our expectations. The test scripts could also be used to check the
backward compatibility when the program is enhanced in future.
