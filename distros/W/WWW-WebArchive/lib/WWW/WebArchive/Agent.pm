
#############################################################################
## $Id: WebArchive.pm 6702 2006-07-25 01:43:27Z spadkins $
#############################################################################

package WWW::WebArchive::Agent;

use vars qw($VERSION);
use strict;

$VERSION = "0.50";

use File::Spec;

sub new {
    &App::sub_entry if ($App::trace);
    my ($this, @args) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    if ($#args == 0 && ref($args[0]) eq "HASH") {
        $self = { %{$args[0]} };
    }
    elsif ($#args >= 1 && $#args % 2 == 1) { # even number of args
        $self = { @args };
    }
    bless $self, $class;
    &App::sub_exit($self) if ($App::trace);
    return($self);
}

sub restore {
    &App::sub_entry if ($App::trace);
    my ($self, $options) = @_;
    die "restore() not yet implemented for agent [$self->{name}]";
    &App::sub_exit() if ($App::trace);
}

sub check_status {
    &App::sub_entry if ($App::trace);
    my ($self, $ua) = @_;
    my $title = $ua->title() || "[no title]";
    my $response = $ua->res();
    my $code = $response->code();
    if ($response->is_success()) {
        print ">>> $title : $code Success\n" if ($self->{verbose});
    }
    else {
        my $status_line = $response->status_line();
        my $base = $response->base();
        print ">>> $title : $status_line\n" if ($self->{verbose});
        warn "$status_line on GET $base\n";
    }
    &App::sub_exit() if ($App::trace);
}

# $dir = App->mkdir($prefix, "data", "app", "Context");
sub mkdir {
    &App::sub_entry if ($App::trace);
    my ($self, @dirs) = @_;

    if ($#dirs == 0 && $dirs[0] =~ m![/\\]!) {
        @dirs = split(/[\/\\]+/, $dirs[0]);
    }

    my $dir = shift(@dirs) || "/";
    if ($dir) {
        # print "mkdir($dir)\n";
        mkdir($dir) if (! -d $dir);
        foreach my $d (@dirs) {
            $dir = File::Spec->catdir($dir, $d);
            # print "mkdir($dir)\n";
            mkdir($dir) if (! -d $dir);
        }
    }
    &App::sub_exit($dir) if ($App::trace);
    return($dir);
}

sub read_file {
    &App::sub_entry if ($App::trace);
    my ($self, $file) = @_;
    open(FILE, "< $file") || die "Unable to open $file: $!";
    local($/) = undef;
    my $data = <FILE>;
    close(FILE);
    &App::sub_exit($data) if ($App::trace);
    return($data);
}

sub write_file {
    &App::sub_entry if ($App::trace);
    my ($self, $file, $data) = @_;
    my ($dir);
    if ($file =~ m!(.*)[/\\]([^/\\]+)$!) {
        $dir = $1;
    }
    if ($dir && ! -d $dir) {
        $self->mkdir($dir);
    }
    open(FILE, "> $file") || die "Unable to open $file: $!";
    print FILE $data;
    close(FILE);
    &App::sub_exit() if ($App::trace);
}

=head1 NAME

WWW::WebArchive::Agent - A base class for all specific web archives

=head1 SYNOPSIS

    NOTE: You probably want to use this module through the WWW::WebArchive API.
    If not, it's up to you to read the code and figure it out.

=head1 DESCRIPTION

A base class for all specific web archives.

=head1 ACKNOWLEDGEMENTS

 * Author:  Stephen Adkins <spadkins@gmail.com>
 * License: This is free software. It is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::WebArchive>, L<WWW::Mechanize>

=cut

1;

