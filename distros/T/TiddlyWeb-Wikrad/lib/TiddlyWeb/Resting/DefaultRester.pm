package TiddlyWeb::Resting::DefaultRester;
use strict;
use warnings;
use TiddlyWeb::Resting;
use Sys::Hostname qw/hostname/;

=head1 NAME

TiddlyWeb::Resting::DefaultRester - load a rester from a config file.

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Load server, workspace and username from a file, so you don't need to
specify that for every program using TiddlyWeb::Resting.

    use TiddlyWeb::Resting::DefaultRester;

    my $rester = TiddlyWeb::Resting::DefaultRester->new;
    print $rester->get_page('Foo');

=head1 FUNCTIONS

=head2 new

Create a new Default Rester by using values from ~/.wikeditrc.

=head3 Options:

=over 4

=item rester-config

File to use as the config file.  Defaults to $ENV{HOME}/.wikeditrc.

=item class

Specifies the rester class to use.  Defaults to L<TiddlyWeb::Resting>.

=item *

All other args are passed through to the rester class's new().

=back

=head3 Rester Config File

The config file is expected to be in the following format:

  server = your-server
  workspace = some-workspace
  username = your-user
  password = your-password

Your password will become crypted the first time it is loaded if Crypt::CBC
is installed.

Alternately, you can use this format:

  server = your-server
  workspace = some-workspace
  user_cookie = an-NLW-user-cookie

=cut

my $home = $ENV{HOME} || "~";
our $CONFIG_FILE = "$home/.wikeditrc";

sub new {
    my $class = shift;
    my %args = (@_);
    for my $k (keys %args) {
        delete $args{$k} unless defined $args{$k};
    }

    my $config_file = delete $args{'rester-config'} || $CONFIG_FILE;
    my %opts = (
        _load_config($config_file),
        %args,
    );
    my $rest_class = delete $opts{class} || 'TiddlyWeb::Resting';
    eval "require $rest_class";
    die if $@;
    return $rest_class->new(%opts);
}

sub _load_config {
    my $file       = shift;
    my $second_try = shift;

    unless (-e $file) {
        open(my $fh, ">$file") or die "Can't open $file: $!";
        print $fh <<EOT;
server = http://tiddlyweb.peermore.com/wiki
workspace = docs
username = 
password = 
EOT
        close $fh or die "Couldn't write basic config to $file: $!";
        warn "Created an initial wiki config file in $file.\n";
    }

    my %opts;
    open(my $fh, $file) or die "Can't open $file: $!";
    while(<$fh>) {
        if (/^(\w+)\s*=\s*(\S+)\s*$/) {
            my ($key, $val) = (lc($1), $2);
            $val =~ s#/$## if $key eq 'server';
            $opts{$key} = $val;
        }
    }

    my $pw = $opts{password};
    if (!$second_try and -w $file and $pw and $pw !~ /^CRYPTED_/) {
        _change_password($file, $opts{password})
            or return _load_config($file, 'i already tried once');
    }

    if ($opts{password} and $opts{password} =~ m/^CRYPTED_(.+)/) {
        eval 'require Crypt::CBC';
        if ($@) {
            delete $opts{password};
        }
        else {
            my $new_pw = _decrypt($1);
            $opts{password} = $new_pw;
        }
    }
    return %opts;
}

sub _change_password {
    my $file = shift;
    eval 'require Crypt::CBC';
    return 0 if $@;

    my $old_pw = shift;

    my $new_pw = 'CRYPTED_' . _encrypt($old_pw);

    local $/ = undef;
    open(my $fh, $file) or die "Can't open $file: $!";
    my $contents = <$fh>;
    $contents =~ s/password\s*=\s*\Q$old_pw\E/password = $new_pw/m;
    close $fh;
    open(my $wfh, ">$file") or die "Can't open $file for writing: $!";
    print $wfh $contents;
    close $wfh or die "Can't write $file: $!";
    return 1;
}

sub _encrypt {
    my $from = shift;
    my $crypt = Crypt::CBC->new(
        -key => hostname(),
        -salt => 1,
        -header => 'salt',
    );
    return $crypt->encrypt_hex($from);
}

sub _decrypt {
    my $from = shift;
    my $crypt = Crypt::CBC->new(
        -key => hostname(),
        -salt => 1,
        -header => 'salt',
    );
    return $crypt->decrypt_hex($from);
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-socialtext-default-rester at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Socialtext-Resting-Utils>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Socialtext::Resting::DefaultRester

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Socialtext-Resting-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Socialtext-Resting-Utils>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Socialtext-Resting-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Socialtext-Resting-Utils>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
