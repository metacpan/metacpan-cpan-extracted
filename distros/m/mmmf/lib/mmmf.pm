package mmmf;

use vars qw($VERSION);
$VERSION = '0.03';

use strict;
use warnings;


1;

__END__

=head1 NAME

mmmf - multi-master mysql failover

=head1 SYNOPSIS

  # failover mysql cluster (as configured in /etc/mmmf.conf)
  # to the new master SLAVE_ID
  #
  mmmf --cfg /etc/mmmf.conf --failover-to <SLAVE_ID> [--debug]

=head1 DESCRIPTION

B<mmmf> is a proof of concept tool implementing mmmf algorithm
described here: http://www.nigilist.ru/nit/mmmf/

Please note that currently the tool is a proof of concept only
and should not be used in production environment as it does not
implement a lot of error and random conditions checking.

If you need in-depth explanation of the algorithm,
please check out this video recorded specially for
Mysql & friends devroom of FOSDEM 2011:

http://www.youtube.com/watch?v=Qzht1B7p0yQ

=head1 CONFIGURATION

Find below sample configuration file, you can copy and adjust it
according to your configuration. It should list all of your databases
(master and slaves). The file is sourced into mmmf, so you have
to respect perl syntax in it.

If the database is local 'sock' option is required,
otherwise it can be left empty.

  #!/usr/bin/perl

  {
    package mmmf;

    $LOG = "/tmp/mmmf.log";

    $db = {
        'test1' => {
          'host' => "localhost",
          'port' => 33001,
          'user' => "root",
          'pass' => "",
          'sock' => "/var/lib/mysql1/mysqld.sock",
          'encoding' => "utf8",
          },
        'test2' => {
          'host' => "localhost",
          'port' => 33002,
          'user' => "root",
          'pass' => "",
          'sock' => "/var/lib/mysql2/mysqld.sock",
          'encoding' => "utf8",
          },
        'test3' => {
          'host' => "localhost",
          'port' => 33003,
          'user' => "root",
          'pass' => "",
          'sock' => "/var/lib/mysql3/mysqld.sock",
          'encoding' => "utf8",
          },
      };
  }

  1;

=head1 CREDITS

Thanks to the whole Yandex team and personally to the following people (in alphabetic order):

  Andrey Grunau
  Dmitry Parfenov
  Pavel Pushkarev
  Alexey Simakov

for their ideas and support.

=head1 AUTHORS

Petya Kohts E<lt>petya@kohts.ruE<gt>

=head1 COPYRIGHT

Copyright 2011 Petya Kohts.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
