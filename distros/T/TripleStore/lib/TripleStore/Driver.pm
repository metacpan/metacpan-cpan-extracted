# -------------------------------------------------------------------------------------
# TripleStore::Driver
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: Driver.pm,v 1.1.1.1 2003/01/13 18:20:39 jhiver Exp $
#
#    Description:
#
#      Abstract class which defines the set of operations which
#      needs to be implemented by a driver.
#
# -------------------------------------------------------------------------------------
package TripleStore::Driver;
use strict;
use warnings;
use Carp;
use base qw /TripleStore::Mixin::Class
	     TripleStore::Mixin::Unimplemented/;


##
# $self->tx_start();
# ------------------
# Starts a transaction.
# Returns - nothing.
##
sub tx_start { shift->class()->_unimplemented() }


##
# $self->tx_stop();
# -----------------
# Stops a transaction.
# Returns - nothing.
##
sub tx_stop { shift->class()->_unimplemented() }


##
# $self->tx_abort();
# ------------------
# Cancels a transaction.
# Returns - nothing.
##
sub tx_abort { shift->class()->_unimplemented() }


##
# $self->insert ($subject, $predicate, $object);
# ----------------------------------------------
# $subject   - a SCALAR subject
# $predicate - a SCALAR predicate
# $object    - a SCALAR object
##
sub insert { shift->class()->_unimplemented() }


##
# $self->delete (Storage::Triple::Query::Clause $clause);
# -------------------------------------------------------
# $clause - a Storage::Triple::Query::Clause object.
# Returns - Nothing.
##
sub delete { shift->class()->_unimplemented() }


##
# $self->update ($set, $clause);
# ------------------------------
# $set    - a Storage::Triple::Update object.
# $clause - a Storage::Triple::Query::Clause object.
# Returns - Nothing.
##
sub update { shift->class()->_unimplemented() }


##
# $self->select (@variables, $query);
# -----------------------------------
# @variables - an array of variables to retrieve
# $query     - a Storage::Triple::Query object
# Returns    - a Storage::Triple::ResultSet object
##
sub select { shift->class()->_unimplemented() }


1;
