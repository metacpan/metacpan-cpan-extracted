package Vim::Helper::Test;
use strict;
use warnings;

use Vim::Helper::Plugin (
    from_mod => {
        default => sub { \&default_from_mod }
    },
    from_test => {
        default => sub { \&default_from_test }
    },
    test_key => {default => '<Leader>gt'},
    imp_key  => {default => '<Leader>gi'},
);

sub args {
    {
        file_test => {
            handler     => \&file_to_test,
            description => "Get test filename from module",
            help        => "Usage: $0 file_test FILENAME",
        },
        test_imp => {
            handler     => \&test_to_imp,
            description => "Get the implementation filename from the test file",
            help        => "Usage: $0 test_imp FILENAME",
        },
    };
}

sub vimrc {
    my $self = shift;
    my ( $helper, $opts ) = @_;

    my $cmd = $helper->command($opts);

    my $tk = $self->test_key;
    my $ik = $self->imp_key;

    return <<"    EOT";
function! GoToPerlTest()
    exe ":e `$cmd file_test %`"
endfunction

function! GoToPerlImp()
    exe ":e `$cmd test_imp %`"
endfunction

:map  $tk :call GoToPerlTest()<cr>
:imap $tk :call GoToPerlTest()<cr>

:map  $ik :call GoToPerlImp()<cr>
:imap $ik :call GoToPerlImp()<cr>
    EOT
}

sub file_to_test {
    my $helper = shift;
    my $self   = $helper->plugin('Test');
    my ( $name, $opts, $filename ) = @_;

    my $package = $self->package_from_file($filename);

    return {
        code   => 1,
        stderr => "Could not find package declaration in '$filename'\n",
    } unless $package;

    my $file = $self->from_mod->( $filename, $package, split '::' => $package );

    return {
        code   => 0,
        stdout => "$file\n",
    } if $file;

    return {
        code   => 1,
        stderr => "Could not determine test file name.\n",
    };
}

sub test_to_imp {
    my $helper = shift;
    my ( $name, $opts, $filename ) = @_;

    my $self = $helper->plugin('Test');
    my $loader = $helper->plugin('LoadMod') || do {
        require Vim::Helper::LoadMod;
        return Vim::Helper::LoadMod->new;
    };

    my $package = $self->package_from_file($filename);

    my $file = $self->from_test->(
        $filename,
        $package,
        $package ? ( split '::' => $package ) : ()
    );

    my $path = $loader->find_file($file);

    return {
        code   => 0,
        stdout => "$path\n",
    } if $path;

    return {
        code   => 1,
        stderr => "Could not determine module file name.\n",
    };
}

sub package_from_file {
    my $self = shift;
    my ($filename) = @_;
    open( my $fh, "<", $filename ) || return undef;
    while ( my $line = <$fh> ) {
        next unless $line =~ m/^.*package\s+([^\s;]+)/;
        close($fh);
        return $1;
    }
    close($fh);
    return undef;
}

sub default_from_mod {
    my ( $filename, $modname, @modparts ) = @_;
    return 't/' . join( "-" => @modparts ) . ".t";
}

sub default_from_test {
    my ( $filename, $modname, @modparts ) = @_;
    $filename =~ s{^t/}{};
    $filename =~ s{^.*/t/}{};
    $filename =~ s{\.t$}{};
    my (@parts) = split '-', $filename;
    return join( '/' => @parts ) . '.pm';
}

1;

__END__

=pod

=head1 NAME

Vim::Helper::Test - Plugin for switching between test and implementation files.

=head1 DESCRIPTION

Provides keybindings that take you between test files and module files.

=head1 SYNOPSIS

In your config file:

    use Vim::Helper qw/
        Test
    /;

    Test {
        from_mod => sub {
            my ( $filename, $modname, @modparts ) = @_;
            return 't/' . join( "-" => @modparts ) . ".t";
        },
        from_test => sub {
            my ( $filename, $modname, @modparts ) = @_;
            $filename =~ s{^t/}{};
            $filename =~ s{^.*/t/}{};
            $filename =~ s{\.t$}{};
            my ( @parts ) = split '-', $filename;
            return join( '/' => @parts ) . '.pm';
        },
    };

=head1 ARGS

=over 4

=item file_test MOD_FILENAME

Takes the module filename and returns the test file name.

=item test_imp TEST_FILENAME

Takes the test filename and returns the module file name.
 
=back

=head1 OPTS

None

=head1 CONFIGURATION OPTIONS

=over 4

=item from_mod  => sub { ... }

How to get the test filename from a module file. Default is to take the package
name, change the '::' to '-', and append '.t', it then looks for the
file in 't/'. So Foo::Bar should be 't/Foo-Bar.t'.

A custom function would look like this:

sub {
    my ( $filename, $modname, @modparts ) = @_;
    ...
    return $new_filename;
}

$filename will always be the files name. $modname is read from the top of the
file, and @modparts contains each section of the module name split on '::'. If
the file cannot be read an error is thrown, so it must be valid and contain a
package declaration.

=item from_test => sub { ... }

How to get the module filename from a test file. Default is to take the test
filename, change '-' to '/', and strip off the directory and '.t'. The search
path for the module is whatever is provided to LoadMod, or @INC if none LoadMod
was not confgiured.

A custom function would look like this:

sub {
    my ( $filename, $modname, @modparts ) = @_;
    ...
    return $new_filename;
}

$filename will always be the files name. $modname is read from the top of the
file, and @modparts contains each section of the module name split on '::'.
Unlike the from_mod function, $modname may be undefined, and no declaration is
required in the test files.

=item test_key  => '<Leader>gt'

Key binding for moving from module to test.

=item imp_key   => '<Leader>gi'

Key binding for moving from test to module.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2012 Chad Granum

Vim-Helper is free software; Standard perl licence.

Vim-Helper is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.

=cut

