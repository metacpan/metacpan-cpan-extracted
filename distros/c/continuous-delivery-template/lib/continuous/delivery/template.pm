use strict;
use warnings;
package continuous::delivery::template;

our $VERSION = 0.01;

=head1 NAME

continuous-delivery-template - continuous delivery workflow dockerhub, gitlab, and cpan

=head1 DESCRIPTION

Perl template application configured to use Gitlab CI/CD service
as continuous delivery workflow.

On the Perl side, this application template uses Dist::Zilla as building,
testing and releasing framework.

   hack on application code
   git commit ...
   git push

This will trigger building, testing and publishing the docker image
with :ci tag to dockerhub.

If all tests pass and you are going to release a new version should
use Dist::Zila as follows:

   dzil release

Dist::Zilla will create a new git tag based on version number on
lib/continuous/delivery/template.pm file and push the tag to github.

Dist::Zilla will publish the release on CPAN, the CPAN will run
tests under a variety of platforns and environments throught CPANTESTERS.

Before you can upload Perl modules to CPAN you need to create an
account on The [Perl programming] Authors Upload Server:

=over

=item *

L<https://pause.perl.org>

=back

You need create an account on Docker Hub Container Regitry and configure
the following secret variables on Gitlab CI / CD settings:

=over

=item $DOCKER_USER

Your username on hub.docker.com.

=item $DOCKER_PASSWORD

Your password on hub.docker.com.

=back

=head2 continuous-delivery-template links

=over

=item Git Repository:

L<https://gitlab.com/joenio/continuous-delivery-template>

=item Docker Container Registry:

L<https://hub.docker.com/r/joenio/continuous-delivery-template>

=item CPAN:

L<https://metacpan.org/release/continuous::delivery::template>

=back

=head2 USEFULL DOCUMENTS

=over

=item *

L<GitLab CI/CD Examples|https://gitlab.com/help/ci/examples/README.md>

=item *

L<Building Docker images with GitLab CI/CD|https://docs.gitlab.com/ee/ci/docker/using_docker_build.html>

=back

=cut

sub hello {
  return join(' ', "Hello! I'm", __PACKAGE__, "version $VERSION.");
}

1;
