package WWW::Selenium::Utils::CGI;
use 5.006;
use strict;
use warnings;
use Carp;
use File::Find;
use CGI qw(:standard);
use Config;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(run cat state);

sub run {
    my $q = shift or croak("CGI query object is mandatory!");

    my $cmd = $q->param('cmd');
    return error("cmd is a mandatory parameter!") unless $cmd;

    my $results = qx($cmd) || $!;
    $results =~ s/</&lt;/g;
    return header . start_html("Output of \"$cmd\"") 
           . "<div id='cmd'>" . h1("Output of \"$cmd\":") . "</div>"
           . "<div id='output'>" . pre($results) . "</div>"
           . end_html;
}


sub cat {
    my $q = shift or croak("CGI query object is mandatory!");
    my %opts = @_;
    my $basedir = $opts{basedir} || $Config{prefix};

    my $file = $q->param('file');
    my $raw  = $q->param('raw');

    return error("file is a mandatory parameter!") unless $file;

    $file = "$basedir/$file" unless $file =~ m#^/#;
    return error("Sorry, $file doesn't exist!") unless -e $file;

    my $contents;
    open(my $fh, $file) or return error("Can't open $file: $!");
    { 
        local $/ = undef;
        $contents = <$fh>;
    }
    close $fh or return error("Can't close $file: $!");

    return header . $contents if $raw;

    $contents =~ s/</&lt;/g;
    $contents = pre($contents);
    return header . start_html("Contents of $file") . $contents . end_html;
}

sub state {
    my $q = shift or croak("CGI query object is mandatory!");

    if ($q->param('clear_state')) {
        _clear_state();
        return header . start_html . h1("State cleared");
    }

    my $key = $q->param('key');
    my $value = $q->param('value');
    return error('key is a mandatory parameter!') unless $key;
    unless ($value) {
        my $val = _read_state($key);
        return error("'$key' is not a valid key!") unless defined $val;
        return header . start_html . h1("State for $key")
               . "'$key' is '$val'";
    }
    eval {
        _store_state( $key => $value );
    };
    if ($@) {
        return header . start_html . h1("State for $key")
               . "Error saving key $key: $@";
    }
    return header . start_html . h1("State for $key")
           . "Stored '$value' in '$key'";
}

my $statefile = "/tmp/selenium-utils-state";

sub _read_state {
    my $key = shift;
    my $content = '';
    if (-e $statefile) {
        local $/;
        open(my $fh, $statefile) or die "Can't open $statefile: $!";
        $content = <$fh>;
        close $fh or die "Can't close $statefile: $!";
    }

    my $state;
    eval $content;
    $state ||= {};
    return $key ? $state->{$key} : $state;
}

sub _store_state {
    my ($key, $val) = @_;
    my $state = _read_state;
    $state->{$key} = $val;
    my $tmpstate = "$statefile.$$";
    my $textstate = Data::Dumper->Dump([$state], ["state"]);
    open(my $fh, ">$tmpstate") or die "Can't open $tmpstate: $!";
    print $fh $textstate;
    close $fh or die "Can't write $tmpstate: $!";
    rename $tmpstate, $statefile or 
        die "Can't rename $tmpstate, $statefile: $!";
}

sub _clear_state {
    unlink $statefile;
}

sub error {
    my $msg = shift;
    return header . start_html . h1("Error!") . $msg . end_html;
}

1;
__END__

=head1 NAME

WWW::Selenium::Utils::CGI - helper functions Selenium CGIs

=head1 SYNOPSIS

  # simple CGI script
  use WWW::Selenium::Utils::CGI qw(run);
  use CGI;
  print run( CGI->new() );

=head1 DESCRIPTION

This package contains useful functions for creating test scaffolding
CGI scripts that Selenium can use.  Users of this module will need
to create their own cgi or mod_perl handlers that call these functions.

=head1 SUBROUTINES

These subs should be called by CGI or mod_perl wrappers.  I feel
this will provide the most generic interface that can be customized
to any application.  Sample CGI scripts are in scripts/ of this 
distribution.  Indeed I use both CGI and mod_perl for various test 
projects.

=head2 run

C<run()> will run an command passed in from as a CGI variable.

Note that this is NOT SAFE for general websites, as it allows 
ARBITRARY COMMANDS to be run.  For testing purposes however, it 
is quite useful.

HTTP GET Parameters:

=over 4

=item cmd

The command to execute.  Note that you will need to properly encode
commands in your selenium test cases, like this:

  /open /selenium/run.cgi?cmd=ls%20-l

=back

=head2 cat

C<cat()> will output the contents of a file.

Arguments:

=over 4

=item basedir

The base directory when a relative path is used.  Defaults to
perl's install prefix.

=back

HTTP GET Parameters:

=over 4

=item file

The file to read.  If the file does not begin with a '/', then the file
will be relative to $Config{prefix} (where your perl is installed to).

=item raw

If this is false (the default), then the contents of the file will be
surrownded in a pre block, to make the output look nicer in the browser.

=back

=head2 state

Keeps any kind of key/value state.  This can allow selenium to signal
other processes or stare information.  State is stored in a flat file
in /tmp.

HTTP GET Parameters:

=over 4

=item key (Mandatory)

A key to set or get.

=item value

If present, will be stored for the given key.

=back

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

Uses CGI.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problums to Luke Closs (cpan@5thplane.com).
Patches are welcome.

=head1 AUTHOR

Luke Closs (cpan@5thplane.com)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005 Luke Closs (cpan@5thplane.com).  All rights reserved.

This module is free software; you can redstribute it and/or
modify it under the same terms as Perl itself.  See L<perlartistic>.

This program is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

