package WebService::Mattermost::Helper::Alias;

use strict;
use warnings;

use Readonly;

require Exporter;

use vars qw(@ISA @EXPORT_OK);

@ISA       = 'Exporter';
@EXPORT_OK = qw(util v4 view);

Readonly::Scalar my $util_base => 'WebService::Mattermost::Util::';
Readonly::Scalar my $v4_base   => 'WebService::Mattermost::V4::API::Resource::';
Readonly::Scalar my $view_base => 'WebService::Mattermost::V4::API::Object::';

################################################################################

sub util {
    my $name = shift;

    return sprintf('%s%s', $util_base, $name);
}

sub v4 {
    my $name = shift;

    return sprintf('%s%s', $v4_base, $name);
}

sub view {
    my $name = shift;

    return sprintf('%s%s', $view_base, $name);
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::Helper::Alias

=head1 DESCRIPTION

Static helpers used in the library.

=head2 METHODS

=over 4

=item C<v4()>

Format the name of an endpoint for the version 4 API.

    use WebService::Mattermost::Helper::Alias 'v4';

    print v4   'Teams';     # prints WebService::Mattermost::API::v4::Resource::Teams
    print util 'UserAgent'; # prints WebService::Mattermost::Util::UserAgent

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

