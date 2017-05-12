##
# name:      YamlTime::Git
# abstract:  Git Support for YamlTime
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011
# see:
# - YamlTime

use 5.008003;
use YamlTime 0.08 ();

package YamlTime::Extension::Git;

our $VERSION = '0.01';

package YamlTime::Command::commit;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];
use constant abstract => "'git commit' your YamlTime changes";

sub execute {
    my ($self, $opt, $args) = @_;
    my @args = @$args || ('-m', 'YamlTime!');
    $self->run('git add .') and
    $self->run("git commit @args");
}

package YamlTime::Command::push;
use Mouse;
YamlTime->import( -command );
extends qw[YamlTime::Command];
use constant abstract => "'git push' your YamlTime repository";

sub execute {
    my ($self, $opt, $args) = @_;
    my @args = @$args || qw(origin master);
    $self->run("git push @args");
}

1;
