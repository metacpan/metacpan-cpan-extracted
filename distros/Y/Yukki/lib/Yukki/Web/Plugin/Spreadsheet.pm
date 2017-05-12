package Yukki::Web::Plugin::Spreadsheet;
{
  $Yukki::Web::Plugin::Spreadsheet::VERSION = '0.140290';
}
use 5.12.1;
use Moose;

extends 'Yukki::Web::Plugin';

# ABSTRACT: add spreadsheet functionality to wiki pages

use Scalar::Util qw( blessed );
use Try::Tiny;
use Yukki::Error qw( http_throw );


has format_helpers => (
    is          => 'ro',
    isa         => 'HashRef[Str]',
    required    => 1,
    default     => sub { +{
        '=' => 'spreadsheet_eval',
    } },
);

with 'Yukki::Web::Plugin::Role::FormatHelper';


sub initialize_context {
    my ($self, $ctx) = @_;

    $ctx->stash->{'Spreadsheet.sheet'}   //= Spreadsheet::Engine->new;
    $ctx->stash->{'Spreadsheet.map'}     //= {};
    $ctx->stash->{'Spreadsheet.rowmap'}  //= {};
    $ctx->stash->{'Spreadsheet.nextrow'} //= 'A';
    $ctx->stash->{'Spreadsheet.nextcol'} //= {};

    return $ctx->stash->{'Spreadsheet.sheet'};
}


sub setup_spreadsheet {
    my ($self, $params) = @_;
    
    my $ctx  = $params->{context};
    my $file = $params->{file};
    my $arg  = $params->{arg};

    my $sheet = $ctx->stash->{'Spreadsheet.sheet'};
    my $row   = $self->row($ctx, $file);

    my ($name, $formula) = $arg =~ /^(?:([\w -]+):)?(.*)/;

    my $new_cell = $row . ($sheet->raw->{sheetattribs}{lastrow} + 1);

    $self->cell($ctx, $file, $name, $new_cell) if $name;

    return ($new_cell, $name, $formula);
}


sub row {
    my ($self, $ctx, $file) = @_;

    my $rowmap = $ctx->stash->{'Spreadsheet.rowmap'};

    my $row   = $rowmap->{ $file->repository_name }{ $file->full_path }
             // $ctx->stash->{'Spreadsheet.nextrow'}++;

    return $rowmap->{ $file->repository_name }{ $file->full_path } = $row;
}


sub cell {
    my ($self, $ctx, $file, $name, $new_cell) = @_;
    my $map = $ctx->stash->{'Spreadsheet.map'};
    $map->{ $file->repository_name }{ $file->full_path }{ $name } = $new_cell
        if defined $new_cell;
    return $map->{ $file->repository_name }{ $file->full_path }{ $name }; 
}


sub lookup_name {
    my ($self, $params) = @_;

    my $ctx  = $params->{context};
    my $file = $params->{file};
    my $name = $params->{name};

    if ($name =~ /!/) {
        my ($path, $name) = split /!/, $name, 2;

        my $repository_name;
        if ($path =~ /^(\w+):/) {
            ($repository_name, $path) = split /:/, $path, 2;
        }
        else {
            $repository_name = $file->repository_name;
        }

        $path = $self->app->munge_label($path);

        my $other_repo = $self->model('Repository', { 
            name => $repository_name,
        });

        my $other_file = $other_repo->file({
            full_path => $path,
        });

        $self->load_spreadsheet($ctx, $other_file)
            unless $other_file->repository_name eq $file->repository_name
               and $other_file->full_path       eq $file->full_path;;

        return $self->cell($ctx, $other_file, $name);
    }

    my $cell = $self->cell($ctx, $file, $name);

    http_throw('unknown name') if not defined $cell;

    return $cell;
}


sub spreadsheet_eval {
    my ($self, $params) = @_;

    my $ctx         = $params->{context};
    my $plugin_name = $params->{plugin_name};
    my $file        = $params->{file};
    my $arg         = $params->{arg};

    my $sheet = $self->initialize_context($ctx);
   
    my ($new_cell, $name, $formula) = $self->setup_spreadsheet($params);

    my $error = 0;

    try {
        $formula =~ s/ \[ ([^\]]+) \] /
            $self->lookup_name({
                %$params, 
                name => $1,
            })
        /gex;
    }

    catch {
        $error++;
        if (blessed $_ and $_->isa('Yukki::Error')) {
            my $msg = $_->message;
            $sheet->execute("set $new_cell constant e#NAME?  $msg");
        }
        else {
            die $_;
        }
    };

    $sheet->execute("set $new_cell formula $formula") unless $error;
    $sheet->recalc;

    my $raw = $sheet->raw;
    my $attrs = defined $name ? qq[ id="spreadsheet-$name"] : '';
    my $value;
    if ($raw->{cellerrors}{ $new_cell }) {
        $attrs .= qq[ title="$arg (ERROR: $raw->{formulas}{ $new_cell })"]
                .  qq[ class="spreadsheet-cell error" ];
        $value  = $raw->{cellerrors}{ $new_cell };
    }
    else {
        $attrs .= qq[ title="$arg" class="spreadsheet-cell error" ];
        $value = $raw->{datavalues}{ $new_cell };
    }

    return qq[<span$attrs>$value</span>];
}


sub load_spreadsheet {
    my ($self, $ctx, $file) = @_;
    http_throw('no such spreadsheet exists') unless $file->exists;
    $file->fetch_formatted($ctx);
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::Plugin::Spreadsheet - add spreadsheet functionality to wiki pages

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  {{=:a:5}
  {{=:b:4}}
  {{=:SUM([a],[b],[main:Other Page!c])}}

=head1 DESCRIPTION

Provides a quick format helper to give you spreadsheet variables in your page. This is based upon L<Spreadsheet::Engine>, so all the features and functions there are available here.

In addition, this provides a variable mapping. The variables are mapped using square brackets. You can link between variables on different pages using an exclamation mark ("!") as a separated between page name and variable name.

=head1 ATTRIBUTES

=head2 format_helpers

This sets up the "=" format helper mapped to the L</spreadsheet_eval> method.

=head1 METHODS

=head2 initialize_context

Used to setup the spreadsheet information for the current context. Do not use.

=head2 setup_spreadsheet

Sets up spreadsheet for the current request context. Do not use.

=head2 row

Used to lookup the current row letter for a file. Do not use.

=head2 cell

Used to lookup the cell for a variable. Do not use.

=head2 lookup_name

Used to convert the square bracket names to cell names. Do not use.

=head2 spreadsheet_eval

This is used to format the double-curly brace C< {{=:...}} >. Do not use.

=head2 load_spreadsheet

Used to load spreadsheet variables from an externally referenced wiki page. Do not use.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
