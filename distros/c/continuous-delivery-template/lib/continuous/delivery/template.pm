use strict;
use warnings;
package continuous::delivery::template;

our $VERSION = 0.02;

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

When a new git tag is created on gitlab repository, the pipeline will
build the stages: build -> test -> deploy. The deploy stage is executed
only when a new tag is pushed to repository.

The deploy job will upload a stable image to dockerhub Container Registry.

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

=head2 PROJECT LINKS

=over

=item Gitlab Repository:

L<https://gitlab.com/joenio/continuous-delivery-template>

=item Docker Hub Container Registry:

L<https://hub.docker.com/r/joenio/continuous-delivery-template>

=item CPAN:

L<https://metacpan.org/release/continuous::delivery::template>

=item CPANTESTERS:

L<http://matrix.cpantesters.org/?dist=continuous-delivery-template>

=back

=head2 PROJECT LAYOUT

=over

=item C<.gitlab-ci.yml>

L<https://gitlab.com/joenio/continuous-delivery-template/blob/master/.gitlab-ci.yml>.

This file configures Gitlab CI/CD pipeline for build, test and deploy.

Gitlab CI/CD stages: build -> test -> deploy

=item C<Dockerfile>

L<https://gitlab.com/joenio/continuous-delivery-template/blob/master/Dockerfile>.

Docker container file, use C<debian:stretch> as base image.

=item C<dist.ini>

L<https://gitlab.com/joenio/continuous-delivery-template/blob/master/dist.ini>.

L<Dist::Zilla> settings for build, test and release this project.

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
