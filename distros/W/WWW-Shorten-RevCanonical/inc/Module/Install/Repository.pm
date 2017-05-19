#line 1
package Module::Install::Repository;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use base qw(Module::Install::Base);

sub auto_set_repository {
    my $self = shift;

    return unless $Module::Install::AUTHOR;

    my $repo = _find_repo();
    if ($repo) {
        $self->repository($repo);
    } else {
        warn "Cannot determine repository URL\n";
    }
}

sub _find_repo {
    if (-e ".git") {
        # TODO support remote besides 'origin'?
        if (`git remote show origin` =~ /URL: (.*)$/m) {
            # XXX Make it public clone URL, but this only works with github
            my $git_url = $1;
            $git_url =~ s![\w\-]+\@([^:]+):!git://$1/!;
            return $git_url;
        }
    } elsif (-e ".svn") {
        if (`svn info` =~ /URL: (.*)$/m) {
            return $1;
        }
    } elsif (-e "$ENV{HOME}/.svk") {
        # Is there an explicit way to check if it's an svk checkout?
        my $svk_info = `svk info` or return;
        SVK_INFO: {
            if ($svk_info =~ /Mirrored From: (.*), Rev\./) {
                return $1;
            }

            if ($svk_info =~ m!Merged From: (/mirror/.*), Rev\.!) {
                $svk_info = `svk info /$1` or return;
                redo SVK_INFO;
            }
        }

        return;
    }
}

1;
__END__

=encoding utf-8

#line 95
