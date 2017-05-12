package Trac::RPC::Tools;
{
  $Trac::RPC::Tools::VERSION = '1.0.0';
}



use strict;
use warnings;

use base qw(Trac::RPC::Base);

use File::Find;
use Carp;

# Global variables for user in File::Find sub _wanted_for_upload_all_pages
my $_self;
my $_path;



sub download_all_pages {
    my ($self, $path) = @_;

    croak "No such directory '$path'" unless -d $path;

    my $pages = $self->get_all_pages;
    foreach my $page (@$pages) {
        my $page_content = $self->get_page($page);

        if ($page =~ m{(.*)/}) {
            `mkdir -p $path/$1`;
        }

        my $WIKIFILE;
        open $WIKIFILE, ">", "$path/$page" or croak "can't open file '$path/$page'";
        binmode $WIKIFILE, ":utf8";
        print $WIKIFILE $page_content;
        close $WIKIFILE;
    }

    return '';
}


sub upload_all_pages {
    ($_self, $_path) = @_;

    find( { wanted => \&_wanted_for_upload_all_pages, no_chdir =>1 }, $_path);
    croak "No such directory '$_path'" unless -d $_path;
    return '';

}


sub _wanted_for_upload_all_pages {
    my $page = $File::Find::name;

    return if -d $page;

    $page =~ s{^$_path/}{};
    print "$page" . "\n";
    my $WIKIFILE;
    open $WIKIFILE, "<", $File::Find::name or croak "can't open file '$File::Find::name'";
    my @lines = <$WIKIFILE>;
    my $page_content = join('', @lines);
    close $WIKIFILE;

    eval {
        $_self->put_page($page, $page_content);
    };
}

1;

__END__

=pod

=head1 NAME

Trac::RPC::Tools

=head1 VERSION

version 1.0.0

=encoding UTF-8

=head1 NAME

Trac::RPC::Tools - some high level tools to work with trac

=head1 GENERAL FUNCTIONS

=head2 download_all_pages

B<Get:> 1) $self 2) $path - scalar with path to the directory to store pages

B<Return:> -

Methods gets every wiki page from trac and save them as files in the specified
directory.

Method will croak if the specified directory does not exist.

Method will create subdirectories if wiki page names contain symbol "/".
So, if there are pages "login/sql", "login/description" method will make
files:

    login/
    |-- description
    `-- sql

But there is a problem with this mapping aproach. In trac it is possible to
have pages "login", "login/sql", "login/description". But in file system
it is not possible to have a directory and a file with the same name.
Method will croak in such a situation.
I don't know good solution for this problem, if you have any ideas,
please write me.

=head2 upload_all_pages

B<Get:> 1) $self 2) scalar with path to the directory where pages are stored

B<Return:> -

Method finds every file in the specified directory and saves content of that
files as wiki pages. The method does not merge page changes it just rewrites
the content. The method does not not process wiki page deletions, if there
is not file in the directory, but there is wiki page in trac the page will
be unmodified.

=begin comment _wanted_for_upload_all_pages

This is just an additional sub to be use in upload_all_pages() because of the
design of File::Find


=end comment

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
