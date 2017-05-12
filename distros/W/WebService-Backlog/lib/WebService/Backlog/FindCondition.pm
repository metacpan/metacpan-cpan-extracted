package WebService::Backlog::FindCondition;

# $Id$

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use RPC::XML::Client;

my @PARAMS_COUNT = qw/
  issueTypeId componentId versionId milestoneId
  statusId priorityId assignerId createdUserId resolutionId
  created_on_min created_on_max updated_on_min updated_on_max
  start_date_min start_date_max due_date_min due_date_max
  query
  /;
my @PARAMS_FIND = ( @PARAMS_COUNT, qw/sort order offset limit/ );

__PACKAGE__->mk_accessors( ( 'projectId', @PARAMS_FIND ) );

sub toCountCond {
    my $self = shift;
    return $self->_toCond( \@PARAMS_COUNT );
}

sub toFindCond {
    my $self = shift;
    return $self->_toCond( \@PARAMS_FIND );
}

sub _toCond {
    my $self   = shift;
    my $params = shift;
    my $cond   = {};
    $cond->{projectId} = $self->projectId;
    for my $p ( @{$params} ) {
        if ( defined $self->$p ) {
            if ( $p ne 'order' ) {
                $cond->{$p} = $self->$p;
            }
            else {
                $cond->{order} = RPC::XML::boolean->new( $self->$p );
            }
        }
    }
    return $cond;
}

1;
__END__
