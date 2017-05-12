#
# This file is part of Test-File-Content
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package Test::File::Content;
{
  $Test::File::Content::VERSION = '1.0.2';
}
use strict;
use warnings;
# ABSTRACT: Tests files for their content based on their file extension
use Test::More ();
use Path::Class::File;
use File::Find ();

use Exporter qw(import);
our @EXPORT = qw(content_like content_unlike);

sub _parse_args {
    my $type   = shift;
    my $filter = shift;
    if ( ref $filter eq 'HASH' ) {
        foreach my $k ( sort keys %$filter ) {
            _parse_args( $type, $k, $filter->{$k}, @_ );
        }
    } elsif ( ref $filter eq 'ARRAY' ) {
        for (@$filter) {
            _parse_args( $type, $_, @_ );
        }
    } else {
        if ( ref $filter eq 'Regexp' ) {
            my $copy = $filter;
            $filter = sub { return 1 if -d $_[0]; $_[0] =~ $copy };
        } elsif ( !ref $filter ) {
            my $copy = $filter;
            $filter = sub { return 1 if -d $_[0]; $_[0] =~ /\.\Q$copy\E/ };
        }
        my $rules = shift;
        if ( ref $rules eq 'HASH' ) {
            $rules = {
                map {
                    $_ => ( ref $rules->{$_} eq 'Regexp'
                            ? $rules->{$_}
                            : qr/\Q$rules->{$_}\E/sm )
                  } keys %$rules };
        } else {
            $rules = [$rules] unless ( ref $rules eq 'ARRAY' );
            $rules =
              { map { $_ => ( ref $_ eq 'Regexp' ? $_ : qr/\Q$_\E/sm ) }
                @$rules };
        }
        _check_files( $type, $filter, $rules, @_ );
    }
}

sub content_like {
    _parse_args( 'like', @_ );

}

sub content_unlike {
    _parse_args( 'unlike', @_ );

}

sub _check_files {
    my ( $type, $filter, $rules, @dirs ) = @_;
    @dirs = ('.') unless(@dirs);
    my @files;
    my $tree = File::Find::find( sub { push(@files, $File::Find::name) if($filter->($File::Find::name)) }, @dirs );
    @files = sort @files;
    while ( my $file = shift @files ) {
        next if -d $file;
        $file = Path::Class::File->new($file);
        my $content = $file->slurp;

        my @failures;
        while ( my ( $comment, $rule ) = each %$rules ) {
            if ( $type eq 'unlike' ) {
                while ( $content =~ /$rule/g ) {
                    my $message =
                        $comment
                      . " found in "
                      . $file
                      . ' line '
                      . _line_by_pos( $content, pos($content) );
                    push( @failures, $message );
                }
            } elsif ( $content !~ /$rule/g ) {
                push( @failures,
                      'file ' . $file . ' does not contain ' . $comment );
            }
        }

        Test::More::ok( !@failures, $file );
        Test::More::diag( join( "\n", @failures ) ) if (@failures);
    }
}

sub _line_by_pos {
    my ( $file, $pos ) = @_;
    my $i = 1;
    while ( $file =~ /\n/g ) {
        last if ( pos($file) > $pos );
        $i++;
    }
    return $i;
}

1;



=pod

=head1 NAME

Test::File::Content - Tests files for their content based on their file extension

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

 use Test::File::Content;
 use Test::More;
 
 content_like( qr/\.pm/, qr/^#\s*ABSTRACT/, 'lib' );
 
 content_like( pm => '__PACKAGE__->meta->make_immutable', 'lib/MooseClasses' );
 
 content_unlike({
     js => {
         'console.log debug statement' => 'console.log',
         'never use alert' => qr/[^\.]alert\(/,
     },
     tt => [
        qr/\[% DUMP/,
     ],
     pl => '\$foo',
 }, qw(lib root/templates jslib));
 
 done_testing;

Example output:

 not ok 1 - lib/MyLib.pm
 #   Failed test 'lib/MyLib.pm'
 # file lib/MyLib.pm does not contain (?-xism:^#\s*ABSTRACT)
 ok 2 - lib/MooseClasses/Class.pm
 not ok 3 - jslib/test.js
 #   Failed test 'jslib/test.js'
 # console.log debug statement found in jslib/test.js line 1
 # console.log debug statement found in jslib/test.js line 2
 ok 4 - root/templates/test.tt
 1..4

=head1 DESCRIPTION

When writing code, I tend to add a lot of debug statements like C<warn> or C<Data::Dumper>. 
Occasionally I name my variables C<$foo> and C<$bar> which is also quite a bad coding style.
JavaScript files may contain C<console.log()> or C<alert()> calls, which are equally bad.

This test can help to find statements like these and ensure that other statements are there.

=head1 FUNCTIONS

The following functions are exported by default:

=head2 content_like

=head2 content_unlike

B<Arguments:> \%config, @directories

B<Arguments:> $filter, $rule, @directories

C<%config> consists of key value pairs where each key is a file extension (e.g. C<.pm>) and the
value is a C<$rule>.

C<$filter> can either be a string literal (like the key of C<%config>), an arrayref of extensions, 
a regular expression or even a coderef. The coderef is passed the filename as argument and 
is expected to return a true value if the file should be looked at.

C<$rule> can be a string literal, an arrayref of rules or a regular expression.

C<@directories> contains a list of directories or files to look at.

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

