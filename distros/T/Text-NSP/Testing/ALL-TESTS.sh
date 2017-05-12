#!/bin/csh

# This is the driver program for all the tests in the Testing
# directory. There are sometimes problems with the *.sh files
# not being executable, which is why I'm explicitly calling 
# them with csh, so that they run regardless of file permissions

foreach dir (combig count dice leftFisher \
             ll ll3 odds phi pmi rank rightFisher statistic tmi tmi3 \
             tscore x2 huge-count huge-merge huge-sort huge-split count2huge) 

	cd $dir
	csh ./normal-op.sh 
	csh ./error-handling.sh
	cd ..
end

foreach dir (kocos)

      cd $dir

        foreach subdir (unit integration)

	    cd $subdir

     	    csh ./normal-op.sh 
 	    csh ./error-handling.sh

     	    cd ..
        end

      cd ..
end

