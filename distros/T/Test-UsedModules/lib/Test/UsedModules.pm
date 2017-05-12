package Test::UsedModules;
use 5.008005;
use strict;
use warnings;
use utf8;
use parent qw/Test::Builder::Module/;
use ExtUtils::Manifest qw/maniread/;
use Test::UsedModules::PPIDocument;

our $VERSION = "0.03";
our @EXPORT  = qw/all_used_modules_ok used_modules_ok/;

sub all_used_modules_ok {
    my $builder   = __PACKAGE__->builder;
    my @lib_files = _list_up_modules_from_manifest($builder);

    $builder->plan( tests => scalar @lib_files );

    my $fail = 0;
    for my $file (@lib_files) {
        _used_modules_ok( $builder, $file ) or $fail++;
    }

    return $fail == 0;
}

sub used_modules_ok {
    my ($lib_file) = @_;
    return _used_modules_ok( __PACKAGE__->builder, $lib_file );
}

sub _used_modules_ok {
    my ( $builder, $file ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $pid = fork;
    if ( defined $pid ) {
        if ( $pid != 0 ) {
            # Parent process
            wait;
            return $builder->ok( $? == 0, $file );
        }
        # Child processes
        exit _check_used_modules( $builder, $file );
    }

    die "fail forking: $!";
}

sub _check_used_modules {
    my ( $builder, $file ) = @_;

    my ($ppi_document, $load_removed) = Test::UsedModules::PPIDocument::generate($file);
    my ($ppi_document_without_symbol) = Test::UsedModules::PPIDocument::generate($file, 'Symbol');

    my @used_modules = Test::UsedModules::PPIDocument::fetch_modules_in_module($file);

    my $fail = 0;
    CHECK: for my $used_module (@used_modules) {
        next if $used_module->{name} eq 'Exporter';
        next if $used_module->{name} eq 'Module::Load' && $load_removed;
        next if $ppi_document =~ /$used_module->{name}/;

        my @imported_subs = _fetch_imported_subs($used_module);
        for my $sub (@imported_subs) {
            next CHECK if $ppi_document_without_symbol =~ /$sub/;
        }

        $builder->diag( "Test::UsedModules failed: '$used_module->{name}' is not used.");
        $fail++;
    }

    return $fail;
}

sub _fetch_imported_subs {
    my ($used_module) = @_;
    my $importer = "$used_module->{type} $used_module->{name}";

    if ( my $extend = $used_module->{extend} ) {
        $extend =~ s/\( \.\.\. \)/()/;
        $importer .= " $extend";
    }

    my %imported_refs;
    no strict 'refs';
    %{'Test::UsedModules::Sandbox::'} = ();
    use strict;

    eval <<EOC; ## no critic
package Test::UsedModules::Sandbox;
$importer;
no strict 'refs';
%imported_refs = %{'Test::UsedModules::Sandbox::'};
EOC

    delete $imported_refs{BEGIN};
    return keys %imported_refs;
}

sub _list_up_modules_from_manifest {
    my ($builder) = @_;

    my $manifest = $ExtUtils::Manifest::MANIFEST;
    if ( not -f $manifest ) {
        $builder->plan( skip_all => "$manifest doesn't exist" );
    }
    return grep { m!\Alib/.*\.pm\Z! } keys %{ maniread() };
}
1;
__END__

=encoding utf-8

=head1 NAME

Test::UsedModules - Detects needless modules which are being used in your module


=head1 VERSION

This document describes Test::UsedModules version 0.03


=head1 SYNOPSIS

    # check all of modules that are listed in MANIFEST
    use Test::More;
    use Test::UsedModules;
    all_used_modules_ok();
    done_testing;

    # you can also specify individual file
    use Test::More;
    use Test::UsedModules;
    used_modules_ok('/path/to/your/module_or_script');
    done_testing;


=head1 DESCRIPTION

Test::UsedModules finds needless modules which are being used in your module to clean up the source code.
Used modules (it means modules are used by 'use', 'require' or 'load (from Module::Load)' in target) will be checked by this module.


=head1 METHODS

=over 4

=item * all_used_modules_ok

This is a test function which finds needless used modules from modules that are listed in MANIFEST file.

=item * used_modules_ok

This is a test function which finds needless used modules from specified source code.
This function requires an argument which is the path to source file.

=back

=head1 DEPENDENCIES

=over 4

=item * PPI (version 1.215 or later)

=item * Test::Builder::Module (version 0.98 or later)

=back

=head1 KNOWN PROBLEMS

=over 4

=item * Cannot detects rightly when target module applies monkey patch.

e.g. L<HTTP::Message::PSGI>

It applies monkey patch to L<HTTP::Request> and L<HTTP::Response>.

=item * Cannot detects when target module is used by `Module::Load::load` and module name is substituted in variable.

e.g.

    use Module::Load;
    my $module = 'Foo::Bar';
    load $module;

in this case, Test::UsedModules will not notify even if Foo::Bar has never been used.

=back

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut
