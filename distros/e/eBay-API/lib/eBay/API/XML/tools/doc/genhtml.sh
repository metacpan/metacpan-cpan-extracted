#! /bin/sh

################################################################################
# Location: ...................... <user defined location>/eBay/API/XML/tools/doc
# File: .......................... genhtml.sh
# Original Author: ............... Bob Bradley
# Last Modifed By: ............... 
# Last Modified: ................. 10/30/2006
#
# Description
#
# Generate HTML from POD for the generated classes.
################################################################################

BASEDIR='../../../..'

# Generate the HTML doc files
files=`find ${BASEDIR} -name "*.pm"`
for infile in ${files}
do
    basefile=`basename ${infile}`
    html=${basefile}".html"
    echo ${infile}
    pod2html --infile=${infile} --title=${basefile} --outfile=${html} 
done

# Create the index file
files=`ls ${PWD}`
echo "<html><head></head><body><h1>Index of API classes</h1><br/><br/>" > index.html
for html in ${files}
do
    pl=`echo ${html} | sed s/\.html//`
    echo ${html}
    echo "<a href=\"${html}\">${pl}</a><br/>" >> index.html
done
echo "</body></html>" >> index.html
