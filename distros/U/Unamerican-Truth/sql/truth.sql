drop table if exists Truth;
create table Truth (
    truth_id    int(4) not null auto_increment,
    data        text,
    primary key (truth_id)
);

drop table if exists Comment;
create table Comment (
    comment_id  int(4) not null auto_increment,
    truth_id    int(4) not null,
    author      char(64) not null,
    url         char(128),
    posted_on   datetime,
    data        text not null,
    primary key (comment_id)
);

