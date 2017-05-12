package Test::YAML::Valid;

use warnings;
use strict;
use Test::Builder;
use base 'Exporter';
use Carp qw(confess);

our @EXPORT_OK = qw(yaml_string_ok yaml_file_ok yaml_files_ok);
our @EXPORT = @EXPORT_OK;

sub import {
    my @_import = @_;

    # sort the import list into attempts to load alternate YAML
    # parsers ("requests"), and the actual import list to pass to
    # Exporter.
    my @requests;
    my @import;
    for my $elt (@_import){
        if( $elt =~ /^-([A-Za-z::]+)$/ ){
            push @requests, $1;
        }
        else {
            push @import, $elt;
        }
    }

    confess 'You can only specify one YAML module to use; you specified '. scalar @requests
      if @requests > 1;

    my $request_ok = 0;
    my $request = $requests[0];
    if($request){
        eval {
            eval "use YAML::$request qw(Load LoadFile); 1" or die;
            $request_ok = 1;
        };
    }

    if(!$request_ok){
	require YAML;
	eval "use YAML qw(Load LoadFile)";
	Test::Builder->new->diag("Falling back to YAML from YAML::$request")
	    if $request;
    }

    __PACKAGE__->export_to_level(1, @import);
}

=head1 NAME

Test::YAML::Valid - Test for valid YAML

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

This module lets you easily test the validity of YAML:

    use Test::More tests => 3;
    use Test::YAML::Valid;

    yaml_string_ok(YAML::Dump({foo => 'bar'}), 'YAML generates good YAML?');
    yaml_string_ok('this is not YAML, is it?', 'This one will fail');
    yaml_file_ok('/path/to/some/YAML', '/path/to/some/YAML is YAML');
    yaml_files_ok('/path/to/YAML/files/*', 'all YAML files are valid');

You can also test with L<YAML::Syck|YAML::Syck> instead of
L<YAML|YAML> by passing C<-Syck> in the import list:

    use Test::YAML::Valid qw(-Syck);
    yaml_string_ok(...); # uses YAML::Syck::Load instead of YAML::Load

It's up to you to make sure you have YAML::Syck if you specify the
C<-Syck> option, since it's an optional prerequisite to this module.
If it's requested but not found, a warning will be issued and YAML
will be used instead.

As of version 0.04, you can use any module you want in the same way;
C<-Tiny> for YAML::Tiny and C<-XS> for YAML::XS.

=head1 EXPORT

=over 4

=item * yaml_string_ok

=item * yaml_file_ok

=item * yaml_files_ok

=back

=head1 FUNCTIONS

=head2 yaml_string_ok($yaml, [$message])

Test will pass if C<$yaml> contains valid YAML (according to YAML.pm)
and fail otherwise.  Returns the result of loading the YAML.

=cut

# workaround for YAML::Syck -- it doesn't parse report errors!!!!!
sub _is_undef_yaml($){
    my $yaml = shift;
    return if !defined $yaml;
    return 1 if $yaml =~ /^(?:---(?:\s+~?)?\s+)+$/m;
    # XXX: ... should be OK:
    #/^(?:---)?(?: ~)?\n+(?:[.][.][.]\n+)?$/;

    return 0;
}

sub _is_yaml($$){
    return (defined $_[0] || _is_undef_yaml($_[1]));
}

sub yaml_string_ok($;$) {
    my $yaml = shift;
    my $msg  = shift;
    my $result;

    eval {
	$result = Load($yaml);
    };

    my $test = Test::Builder->new();
    $test->ok(!$@ && _is_yaml($result,$yaml), $msg);
    return $result;
}

=head2 yaml_file_ok($filename, [$message])

Test will pass if C<$filename> is a valid YAML file (according to
YAML.pm) and fail otherwise.  Returns the result of loading the YAML.

=cut

sub yaml_file_ok($;$) {
    my $file = shift;
    my $msg  = shift;
    my $result;
    my $yaml;
    eval {
	$result = LoadFile($file);
	if(!defined $result){ # special case for YAML::Syck
	    open my $fh, '<', $file or die "Can't open $file: $!";
	    $yaml = do {local $/; <$fh> };
	    close $fh;
	}
    };

    my $test = Test::Builder->new();
    $msg = "$file contains valid YAML" unless $msg;
    $test->ok(!$@ && _is_yaml($result,$yaml), $msg);
    return $result;
}

=head2 yaml_files_ok($file_glob_string, [$message])

Test will pass if all files matching the glob C<$file_glob_string>
contain valid YAML.  If a file is not valid, the test will fail and no
further files will be examined.

Returns a list of all loaded YAML;

=cut

sub yaml_files_ok($;$) {
    my $file_glob = shift;
    my $msg       = shift;
    my @results;
    my $result;

    my $test = Test::Builder->new();
    $msg = "$file_glob contains valid YAML files" unless $msg;
    foreach my $file (glob($file_glob)) {
	my $yaml = "";
	next if -d $file; # skip directories
        eval {
	    $result = LoadFile($file);
	    if(!defined $result){ # special case for YAML::Syck
		open my $fh, '<', $file or die "Can't open $file: $!";
		$yaml = do {local $/; <$fh> };
		close $fh;
	    }
            push @results, $result;
        };
        if ($@ || !_is_yaml($result,$yaml)) {
            $test->ok(0, $msg);
            $test->diag("  Could not load file: $file.");
            return;
        }
    }

    $test->ok(1, $msg);
    return \@results;
}


=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-yaml-valid at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-YAML-Valid>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::YAML::Valid

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-YAML-Valid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-YAML-Valid>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-YAML-Valid>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-YAML-Valid>

=back

=head1 ACKNOWLEDGEMENTS

Stevan Little C<< <stevan.little@iinteractive.com> >> contributed
C<yaml_files_ok> and some more tests.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Test::YAML::Valid
