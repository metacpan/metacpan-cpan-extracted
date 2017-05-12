package ZooKeeper::XT::Role::CheckAll;
use Test::Class::Moose::Role;
use namespace::clean;

with qw(
    ZooKeeper::XT::Role::CheckACLs
    ZooKeeper::XT::Role::CheckCreate
    ZooKeeper::XT::Role::CheckForking
    ZooKeeper::XT::Role::CheckSessionEvents
    ZooKeeper::XT::Role::CheckSet
    ZooKeeper::XT::Role::CheckTransactions
);

1;
