package WebService::Backlog::UpdateIssue;

# $Id$

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

my @PARAMS = qw/
  key summary description due_date
  issueTypeId priorityId componentId resolutionId versionId milestoneId
  assignerId comment
  /;

__PACKAGE__->mk_accessors(@PARAMS);

sub hash {
    my $self = shift;
    my $hash = {};
    for my $p (@PARAMS) {
        $hash->{$p} = $self->$p if (defined $self->$p);
    }
    return $hash;
}

1;
__END__
