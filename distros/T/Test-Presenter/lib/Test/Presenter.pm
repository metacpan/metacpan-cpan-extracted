=head1 NAME

Test::Presenter - A module for results Presentation.

=head1 SYNOPSIS

    my $report = new Test::Presenter;
    
    $report->close();
    $report->output()
    $report->dump();
    $report->set_debug(0);
    my $dbg = $report->get_debug();


=head1 DESCRIPTION

Test::Presenter is is used to create the initial Test::Presenter object for use
in processing various test results.  Test::Presenter operates around the DBXml
database from Sleepycat Software.  DBXml was used due to it's support for both
XQuery and XPath, as well as it's ease of use and implementation with Perl.

Test::Presenter receives as input a TRPI-formatted XML file.  These files can
be generated with Test::Parser, or any other tool that supports the TRPI format
as output.  The TRPI format was chosen because it is robust enough to handle
results from many different kinds of tests.  This wide usability comes with a
drawback, however, in that TRPI files can sometimes become overly large.

TRPI files are really used as an intermediate data format between raw test
results and an intelligible easy to read set of test results.  This set of test
results can be fed into various tools for final presentation and further human
analysis.

=head1 FUNCTIONS

=cut
package Test::Presenter;

use strict;
use warnings;
use Data::Dumper;
use IO::File;

use Test::Presenter::Query;
use Test::Presenter::DbXml;
use Test::Presenter::QueryTemplate;
use Test::Presenter::Present;

use Sleepycat::DbXml 'simple';

use fields qw(
              _debug
              
              manager
              container
              container_name
              component

              template
              config
              queries
              plaintext
              item_count
              report_type
              );

use vars qw( %FIELDS $VERSION );
our $VERSION = '0.5';


=head2 new()

    Purpose: Create a new Test::Presenter object.
    Input: NA
    Output: Test::Presenter perl object

=cut
sub new {

# _debug
# Sets the debugging level to be used throughout the module
# Note: this value can be changed

# manager
# This is the highest-level object of DBXml

# container
# This is an actual container (the .dbxml file) that queries are
# run against

# container_name
# A global variable so we don't accidently all the container by
# the wrong name

# component
# This is where the results data ends up

# template
# Holds the text of the template file

# config
# Holds the text of the configuration file

# queries
# Holds either A: the merged template and config data, or
# B: the query loaded from file

# plaitext
# Keeps the plaintext configurations until they are merged into
# the 'component' field

# item_count
# Keeps track of how many columns we'll have

    my $this = shift;
    my $class = ref($this) || $this;
    my $self = bless [\%FIELDS], $class;

    $self->{'_debug'} = 0;

    my $pathname = "";

    my $env = new DbEnv(0);
    $env->set_cachesize(0, 64 * 1024, 1);
    $env->open($pathname, Db::DB_INIT_MPOOL|Db::DB_CREATE|Db::DB_INIT_LOCK|Db::DB_INIT_LOG|Db::DB_INIT_TXN);

    # This is needed to eventually access
    $self->{'manager'} = new XmlManager($env);

    $self->{'component'} = {};

    $self->{'template'} = ();
    $self->{'config'} = ();
    $self->{'queries'} = ();
    $self->{'plaintext'} = "";

    $self->{'item_count'} = 0;
    
    return $self;
}


=head2 close()

    Purpose: Close the DBXml file safely (to prevent data corruption,
        etc)
    Input: NA
    Output: 1

=cut
sub close {
    my $self = shift;
    $self->{'container'}->sync();
    
# The following are commented out due to the following errors:    
# XmlContainer::close is not a valid DbXml macro
#    $self->{'container'}->close();

# Can't locate object method "close" via package "XmlManager"
#    $self->{'manager'}->close();

# Maybe these aren't supported in perl? They are documented as being Java
# and C++ API's?

    return 1;
}


=head2 output()

    Purpose: Eventually use the Template::Toolkit module to output the
        results in a nice, easy to read format
    Input: NA
    Output: 1

=cut
sub output {
    my $self = shift;
#    use Template::Toolkit;
#    my $TT = Template::Toolkit->new();
#    print $TT->process('my_template.tmpl', $self->{'component'});
    return 1;
}


=head2 dump()

    Purpose: Used to dump the 'component' object to STDERR
    Input: NA
    Output: 1

=cut
sub dump {
    my $self = shift;
    warn Dumper($self->{'component'});
    return 1;
}


=head2 set_debug()

    Purpose: Turn on (or off) debugging statements.
    Input: Integer (O to disable, 1-4 for debugging statements)
    Output: debug level

=cut
sub set_debug {
    my $self = shift;

    if (@_) {
        $self->{_debug} = pop(@_);
    }

    return $self->{_debug};
}


=head2 get_debug()

    Purpose: Return the debugging level that is currently set.
    Input: None
    Output: Integer (debug level)

=cut
sub get_debug {
    # I don't know if this is ever used in code.  $self->{_debug}>? works for
    # most people. :)
    my $self = shift;

    return $self->{_debug};
}


=head1 AUTHOR

John Daiker <daikerjohn@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 John Daiker.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut




1;
