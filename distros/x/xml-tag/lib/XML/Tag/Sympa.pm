package XML::Tag::Sympa;
use Exporter 'import';
use XML::Tag;

BEGIN {
    our @EXPORT = qw< 

    description
    email
    env
    gecos
    host
    language
    list
    listname
    moderator
    name
    owner
    owner_include
    port
    pwd
    query
    shared_edit
    shared_read
    source
    sql
    status
    subject
    topic
    type
    user

>;
    ns '' => @EXPORT;
};

1;
