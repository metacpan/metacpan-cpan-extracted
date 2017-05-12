package ZooKeeper::XS;
use strict; use warnings;
use XSLoader;
use ZooKeeper::Error;

=head1 NAME

ZooKeeper::XS

=head1 DESCRIPTION

A perl package for loading ZooKeeper XS code

=cut

XSLoader::load('ZooKeeper');

1;
