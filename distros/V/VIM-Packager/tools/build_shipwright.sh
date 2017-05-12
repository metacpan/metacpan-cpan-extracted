REQUIRES=(App::CLI DateTime::Format::DateParse Exporter::Lite File::Basename File::Copy File::Find File::Path File::Spec Getopt::Long LWP::UserAgent YAML)
TODAY=`date +%Y-%m-%d`
REPO=/tmp/vim-packager-$TODAY
BIN=/tmp/vim-packager-$TODAY.bin

if [[ -e $REPO ]] ; then
    echo Found previsou repository: $REPO 
    echo Cleaning up
    rm -rf $REPO
fi

echo Repository: $REPO

shipwright create -r git:file://$REPO

export SHIPWRIGHT_REPOSITORY="git:file://$REPO"

shipwright import git:/Users/c9s/mygit/vim-packager

echo "importing dependencies"
for req in ${REQUIRES[*]} ; do 
    echo $req
    shipwright import cpan:$req > /dev/null
done

CO_PATH=/tmp/vim-packager-build
if [[ -e $CO_PATH ]] ; then
    rm -rf $CO_PATH
fi

echo "checking out"
git clone $REPO $CO_PATH
cd $CO_PATH
# ./bin/shipwright-builder



echo "# one argument per line
--skip-man-pages
--skip-test
--install-base=~/vim-packager
" > __default_builder_options 
./bin/shipwright-utility --generate-tar-file $BIN

echo bin: $BIN
