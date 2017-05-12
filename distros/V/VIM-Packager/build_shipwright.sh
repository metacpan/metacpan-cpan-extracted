REQUIRES=(App::CLI DateTime::Format::DateParse Exporter::Lite File::Basename File::Copy File::Find File::Path File::Spec Getopt::Long LWP::UserAgent YAML)
TODAY=`date +%Y-%m-%d`
REPO=/tmp/vim-packager-$TODAY
shipwright create -r git:file://$REPO

export SHIPWRIGHT_REPOSITORY="git:file://$REPO"

echo "importing dependencies"
for req in ${REQUIRES[*]} ; do 
    echo $req
    shipwright import cpan:$req
done
