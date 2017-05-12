=head1 NAME

Test::Presenter::DbXml - A submodule for Test::Presenter
    This module provides access to a DBXml perl object for the storage and
    querying of test results data.  The DBXml perl object is populated with one
    or more TRPI-like XML files.

=head1 SYNOPSIS

    $report->open_db("/path/to/database", "database.dbxml");
    $report->add_doc("/path/to/logfile", "log.trpi");
    $report->remove_doc("log.trpi");


=head1 DESCRIPTION

Test::Presenter::DbXml is a helper module to give Test::Presenter the
    ability to access DBXml Containers.  All Queries for generating
    reports are done through DBXml with the help of the
    Test::Presenter::Query module.

=head1 FUNCTIONS

=cut
use strict;
use warnings;
use Data::Dumper;
use IO::File;

use Sleepycat::DbXml 'simple';


# _new_manager()
#
# Purpose: Provide a "fall back" method to provide a usable Manager
#          for all DBXml work, if one does not exist.
# Input: NA
# Output: 1
sub _new_manager {
    my $self = shift;

    my $pathname = "";

    # The following 3 lines were taken from a Sleepycat document somewhere,
    # but I have no idea where.
    my $env = new DbEnv(0);
    $env->set_cachesize(0, 64 * 1024, 1);
    $env->open($pathname, Db::DB_INIT_MPOOL|Db::DB_CREATE|Db::DB_INIT_LOCK|Db::DB_INIT_LOG|Db::DB_INIT_TXN);

    $self->{'manager'} = new XmlManager($env);

    return 1;
}


=head2 open_db()

    Purpose: Open a Database if it exists, otherwise create it.
    Input: Database Path, Database Filename
    Output: 1

=cut
sub open_db {
    my $self = shift;
    my $pathname = shift or warn("No pathname passed to 'open_db'\n") and return undef;
    my $container_name = shift or warn("No container name passed to 'open_db'\n") and return undef;;

    if ( !defined($self->{'manager'}) ) {
        # We don't have a manager yet.
        warn "Call _new_manager() inside of open_db()\n" if $self->{_debug}>0;
        $self->_new_manager();
    }

    $self->{'container_name'} = $pathname . "/" . $container_name;

    if ( ! -e $self->{'container_name'} ) {
        # Create the container
        warn "Creating Container inside of open_db()\n" if $self->{_debug}>0;
        $self->{'container'} = $self->{'manager'}->createContainer($self->{'container_name'});
    }
    else {
        # Open the old container...
        warn "Opening Container inside of open_db()\n" if $self->{_debug}>0;
        $self->{'container'} = $self->{'manager'}->openContainer($self->{'container_name'});
    }
    warn "open_db: Number of Documents in DB: " . $self->{'container'}->getNumDocuments() . "\n" if $self->{_debug}>0;
    $self->{'container'}->sync();

    return 1;
}


=head2 add_doc()

    Purpose: Add a Document to an already open Database.
    Input: Document Path, Document Filename
    Output: 1

=cut
sub add_doc {
    my $self = shift;
    my $pathname = shift or warn("add_doc() missing pathname\n") and return undef;
    my $filename = shift or warn("add_doc() missing filename\n") and return undef;
    my $docname = shift or warn("add_doc() missing docname\n") and return undef;

    warn "add_doc() pathname= " . $pathname . "\n" if $self->{_debug}>1;
    warn "add_doc() filename= " . $filename . "\n" if $self->{_debug}>1;

    if ( defined($docname) ) {
        warn "add_doc() docname=  " . $docname . "\n" if $self->{_debug}>1;
    }
    else {
        $docname = $filename;
    }


    eval {
        my $tempDoc = $self->{'container'}->getDocument("$docname");
    };

    if (my $e = catch std::exception) {
        # FIXME: eventhough we throw an exception, it might be the wrong one...  check to make sure it's the correct one
        warn "add_doc() " . $e->what() . "\n" if $self->{_debug}>0;
        # This means the document wasn't found, so we can insert it.
        my $xmlString = "";

        if ( -z "$pathname/$filename" ){
            die "The file [ $filename ] is empty\n";
        }
        # Open the file and store the whole thing in a string
        my $inFile = new IO::File "$pathname/$filename"
                 or die "Cannot open $filename: $!\n" ;

        while (<$inFile>) {
            $xmlString .= $_ ;
        }

        # Kill the xmlns="blah blah" tag so that queries work :)
        $xmlString =~ s/ xmlns=\".*\"//g;

        # This puts the Document file into the DB... it still needs to be parsed, though
        my $uc = $self->{'manager'}->createUpdateContext();
        eval {
            my $temp = $self->{'container'}->putDocument("$docname", $xmlString, $uc);
        };
        if (my $e = catch std::exception) {
            warn "add_doc putDocument: " . $e->what() . "\n" if $self->{_debug}>0;
        }
        else {
            warn "add_doc() $filename being inserted as $docname into the $self->{'container_name'} DB...\n" if $self->{_debug}>0;
        }
    }
    elsif ($@) {
        warn "I don't know why we'd ever get here!" if $self->{_debug}>0;
        warn $@;
        exit( -1 );
    }
    else {
        warn "The document $docname already exists in this database.\n" if $self->{_debug}>0;
    }
    $self->{'container'}->sync();
    warn "add_doc() Number of Documents in DB: " . $self->{'container'}->getNumDocuments() . "\n" if $self->{_debug}>1;

    return 1;
}


=head2 remove_doc()

    Purpose: Remove a Document from the open Database.
    Input: Name of Document to remove
    Output: 1

=cut
sub remove_doc {
    my $self = shift;
    my $docname = shift or warn("remove_doc missing docname\n") and return undef;;

    warn "remove_doc: Number of Documents in DB: " . $self->{'container'}->getNumDocuments() . "\n" if $self->{_debug}>1;

    $self->{'container'}->sync();

    eval {
        my $tempDoc = $self->{'container'}->deleteDocument($docname);
    };

    if (my $e = catch std::exception) {
        # FIXME: eventhough we throw an exception, it might be the wrong one...  check to make sure it's the correct one
        warn $e->what() . "\n";
    }
    elsif ($@) {
        warn "I don't know why we'd ever get here!";
        warn $@;
        exit( -1 );
    }
    else {
        warn "The document $docname was removed from the database.\n" if $self->{_debug}>0;
    }
    $self->{'container'}->sync();
    warn "remove_doc: Number of Documents in DB: " . $self->{'container'}->getNumDocuments() . "\n" if $self->{_debug}>1;

    return 1;
}

1;
