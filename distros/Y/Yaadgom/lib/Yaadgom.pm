use strict;

package Yaadgom;
use 5.008_005;
our $VERSION = '0.07';
use Moo;
use Devel::GlobalDestruction;

use Encode qw/decode/;
use JSON::MaybeXS;
use URI;
use Carp;
use Class::Trigger;

has '_json_ed' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_json'
);

sub _build_json {
    JSON::MaybeXS->new( utf8 => 1, pretty => 1, canonical => 1 );
}

has 'slash_filename_replacement' => ( is => 'rw', default => sub { '-' } );

has '_results'  => ( is => 'rw', default => sub { +{} } );
has 'file_name' => ( is => 'rw', default => sub { $0 } );

sub process_response {
    my ( $self, %opt ) = @_;

    my $req = $opt{req};
    my $res = $opt{res};

    for my $obj (qw/res req/) {
        for my $func ( qw/as_string/, ( $obj eq 'req' ? qw/uri/ : () ) ) {
            eval { $opt{$obj}->$func };
            croak "Param{$obj}->$func() died, perhaps you forgot to pass an HTTP object: \n$@" if $@;
        }
    }

    my $rep = $self->slash_filename_replacement;

    my $file = exists $opt{file} ? $opt{file} : undef;

    if ($file) {
        $file =~ s/^\///;
        $file =~ s/\/$//;
    }
    else {
        $file = URI->new( $req->uri->path )->path;

        $file =~ s/^\///;
        $file =~ s/\/$//;
        $file =~ s/\//$rep/gio;
        $file =~ s/[0-9]+/*/go;
        $file =~ s/[^a-z$rep*]//gio;

        $self->call_trigger( 'filename_generated', { req => $req, file => $file } );
        my @results = @{ $self->last_trigger_results };
        ($file) = @{ $results[-1] } if $results[-1];
    }

    my $weight = defined $opt{weight} && $opt{weight} =~ /^[0-9]+$/ ? $opt{weight} : 1;

    push @{ $self->_results->{$file}{$weight} },
      {
        extra    => $opt{extra},
        file     => $file,
        folder   => $opt{folder} || 'default',
        markdown => $self->get_markdown(%opt)
      };

}

sub _write_title {
    my ( $self, $title ) = @_;
    "## $title\n\n";
}

sub _write_subtitle {
    my ( $self, $title ) = @_;
    "### $title\n\n";
}

sub _write_line {
    my ( $self, $title ) = @_;
    my $str = "$title\n";
}

sub _write_preformated {
    my ( $self, $str ) = @_;
    "<pre>$str\n</pre>\n";
}

sub format_body {
    my ( $self, $str ) = @_;
    my ( $header, $body ) = split /\n\n/, $str;
    if ( $header =~ /application\/json/ && $body ) {
        $body = $self->_json_ed->encode( $self->_json_ed->decode($body) );
        $body = decode( 'utf8', $body );
    }

    $self->call_trigger( 'format_body', { response_str => $body } );
    my @results = @{ $self->last_trigger_results };
    ($body) = @{ $results[-1] } if $results[-1];

    return "$header\n$body";
}

sub get_markdown {
    my ( $self, %opt ) = @_;

    my $file_name = $self->file_name;

    my $req = $opt{req};
    my $res = $opt{res};

    my $desc = join ' ', $req->method, $req->uri->path, $opt{extra}{is_fail} ? ' + expected failure' : '';

    do {
        $self->call_trigger( 'format_title', { title => $desc } );
        my @results = @{ $self->last_trigger_results };
        ($desc) = @{ $results[-1] } if $results[-1];
    };

    my $str = join '',
      $self->_write_title($desc),
      ( defined $file_name ? "<small>$file_name</small>\n" : '' ),
      ( exists $opt{extra}{name} ? ( $self->_write_line( '> ' . $opt{extra}{name} . "\n" ) ) : () ),
      $self->_write_subtitle('Request'),
      $self->_write_preformated( $self->format_body( $req->as_string ) ),
      $self->_write_subtitle('Response'),
      $self->_write_preformated( $self->format_body( $res->as_string ) );

    do {
        $self->call_trigger( 'format_before_extras', { str => $str } );
        my @results = @{ $self->last_trigger_results };
        ($str) = @{ $results[-1] } if $results[-1];
    };

    do {
        $self->call_trigger( 'process_extras', %opt );
        my @results = @{ $self->last_trigger_results };
        $str .= join '', $_ for @results;
    };

    if ( exists $opt{extra}{fields} ) {
        $str .= $self->_write_subtitle('Fields details');
        while ( my ( $key, $maybealist ) = each %{ $opt{extra}{fields} } ) {

            $str .= $self->_write_line( '#### ' . $key );
            if ( ref $maybealist eq 'ARRAY' ) {
                $str .= $self->_write_line( '* ' . $_ ) for @$maybealist;
                $str .= "\n";
            }
            else {
                $str .= $self->_write_line( '- ' . $maybealist );
                $str .= "\n";
            }
        }
    }

    do {
        $self->call_trigger( 'format_after_extras', { str => $str } );
        my @results = @{ $self->last_trigger_results };
        ($str) = @{ $results[-1] } if $results[-1];
    };

    return $str;
}

sub export_to_dir {
    my ( $self, %conf ) = @_;

    my $dir = $conf{dir};
    croak "dir ($dir) is not an directory" unless -d $dir;

    $self->map_results(
        sub {
            my (%info) = @_;

            my $str    = $info{str};
            my $folder = $info{folder};
            my $file   = $dir . '/' . $folder . '/' . $info{file} . '.md';

            mkdir $dir . '/' . $folder;

            open my $fh, '>>:utf8', $file or croak "cant open file $file $!";
            print $fh $str;
            close $fh;
        }
    );

    return 1;
}

sub map_results {
    my ( $self, $callback ) = @_;

    my $tests = $self->_results;

    foreach my $endpoint ( keys %$tests ) {

        my @in_order;
        foreach my $num ( sort { $a <=> $b } keys %{ $tests->{$endpoint} } ) {
            push @in_order, @{ $tests->{$endpoint}{$num} };
        }

        my $folders = {};

        foreach (@in_order) {
            push @{ $folders->{ $_->{folder} }{ $_->{file} } }, $_;
        }

        for my $folder ( keys %$folders ) {
            for my $file ( keys %{ $folders->{$folder} } ) {

                my $str = join "\n<hr/>\n", map { $_->{markdown} } @{ $folders->{$folder}{$file} };

                my $format_time = "\n<small>generated at " . gmtime(time) . " GMT</small>\n";
                do {
                    $self->call_trigger( 'format_generated_str', { str => $format_time } );
                    my @results = @{ $self->last_trigger_results };
                    ($format_time) = @{ $results[-1] } if $results[-1];
                };

                $str .= $format_time;

                $callback->(
                    folder => $folder,
                    file   => $file || '_index',
                    str    => $str
                );

            }
        }

    }

}

has 'on_destroy' => ( is => 'rw' );

sub DESTROY {
    my $self = shift;

    if ( ref $self->on_destroy eq 'CODE' ) {
        $self->on_destroy->($self);
    }

}

1;

__END__

=encoding utf-8

=head1 NAME

Yaadgom - Yet Another Automatic Document Generator (On Markdown)

=head1 SYNOPSIS

    use Yaadgom;

    # create an instance
    my $foo = Yaadgom->new;

    # call this method each request you want to document
    $foo->process_response(
        folder => 'test', # what 'folder' or 'category' this is
        weight => 1     , # default order
        req    => HTTP::Request->new ( GET => 'http://www.example.com/foobar' ),
        res    => HTTP::Response->new( 200, 'OK', [ 'content-type' => 'application/json' ], '{"ok":1}' ),
    );

    # iterate over processed document, for each file.
    # NOTE: This does not write to any file.
    $foo->map_results(
        sub {
            my (%info) = @_;

            is( $info{file},   'foobar', '"foobar" file' );
            is( $info{folder}, 'test',   '"test" folder' );
            ok( $info{str}, 'has str' );
        }
    );


=head1 DESCRIPTION

Yaadgom helps you document your requests (to create an API Reference or something like that).

Yaadgom output string in markdown format, so you can use those generated files on http://daux.io or github

For each time you call "process_response" it will generate a new section composed of:

    ## Title with $desc
    defined $file_name ? <small>$file_name</small>
    exists $opt{extra}{name} ? > $opt{extra}{name}
    ### Request
    <pre> &format_body( $req->as_string ) </pre>
    ### Response
    <pre> &format_body( $res->as_string ) </pre>

=head1 METHODS

=head2 new

    Yaadgom->new(
        # add file_name on the generated document fragment, if you can pass undef to disable this feature
        file_name => "$0",

        # in case you want to do something when this objects destroy, like call ->export_to_dir
        on_destroy => sub { .. },
    );

=head2 process_response

    $self->process_response(
        folder => 'General',
        weight => -150, # set as "first" thing on document
        req    => HTTP::Request->new ( GET => 'http://www.example.com/login' ),
        res    => HTTP::Response->new( 200, 'OK', [ 'content-type' => 'application/json' ], '{"has_password":1}' ),
        extra => {
             fields => { has_password => ['the user has password', 'but can came from facebook']},
             you_can_extend_using => { 'Class_Trigger' => 'to process something else' }
        }
    );

=head2 map_results

    iterate over processed document, for each file.

    $self->map_results(
        sub {
            my (%info) = @_;

        }
    );

=head2 export_to_dir

    # note that this do an append operation on files, so you may reset / truncate your directory before calling this.
    # this is done because you may want multiple tests writing to same file, in different moments.
    $self->export_to_dir(
        dir => '/tmp/
    );

=head1 Class::Trigger names

On each trigger, return is used as the new version of the input. Except for *process_extras*, where all return are concatenated.


Trigger / variables:

    $self0_01->call_trigger( 'filename_generated', { req => $req, file => $file } );
    $self0_01->call_trigger( 'format_title', { header => $desc } );
    $self0_01->call_trigger( 'format_body', { response_str => $body } );
    $self0_01->call_trigger( 'format_before_extras', { str => $str } );
    $self0_01->call_trigger( 'format_after_extras', { str => $str } );
    $self0_01->call_trigger( 'process_extras', %opt );
    $self0_01->call_trigger( 'format_generated_str', { str => $format_time } );

Updated @ Stash-REST 0.03

    $ grep  '$self_0_01->call_trigger' lib/Yaadgom.pm  | perl -ne '$_ =~ s/^\s+//; $_ =~ s/self-/self0_01-/; print' | sort | uniq

=head1 Using Stash::REST for testing and writing docs at same time


Please read first L<Stash::REST> SYNOPSIS to understand how to use it.


Then, create some package that extends Stash::REST (you can call add_trigger on the object of Stash::REST if you want too)

    package YourProject;

    use base qw(Stash::REST);
    use strict;

    YourProject->add_trigger( 'process_response' => \&on_process_response );

    use Yaadgom;

    my $dir = $ENV{DAUX_OUTPUT_DIR};

    # workarround for re-using same folder when Stash::REST call get and list of an created object.
    my $reuse_last_daux_top;
    my $reuse_count;

    my $instance = Yaadgom->new( on_destroy => \&_on_destroy );

    sub on_process_response {
        my ( $self, $opt ) = @_;

        my %conf = %{ $opt->{conf} };
        my $req  = $opt->{req};
        my $res  = $opt->{res};
        return if ( $opt->{res}->code != $conf{code} );
        $conf{folder} = $reuse_last_daux_top if $reuse_count;
        return unless $conf{folder};
        $reuse_count--;

        if ( $reuse_count <= 0 ) {
            $reuse_last_daux_top = $conf{folder};
            $reuse_count = exists $conf{list} ? 2 : $conf{code} == 201 ? 1 : 0;
        }

        $instance->process_response(
            req    => $req,
            res    => $res,
            folder => $conf{folder},

            extra => { %conf }
        );

    }

    sub _on_destroy {

        my $going_die = shift;
        $going_die->export_to_dir( dir => $dir );

    }

    1;

Now, after you run your script

    $obj = YourProject->new( ...)

    $obj->rest_post(
        '/zuzus',
        name  => 'add zuzu',
        list  => 1,
        folder => 'SomeFolder',
        params => [ name => 'foo', ]
    );

You should have on $ENV{DAUX_OUTPUT_DIR} a SomeFolder directory with zuzus.md inside.

If you copy those .md files into daux.io/docs folder, you can build something like this:

=begin HTML

<p><img src="http://i.imgur.com/N6KbTew.png" width="915" height="954" alt="Real web page generated by Yaadgom and daux.io" /></p>


=end HTML


=head1 AUTHOR

Renato CRON E<lt>rentocron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015- Renato CRON

Thanks to http://eokoe.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Shodo>

=head1 SEE OTHER

L<Stash::REST>, L<Class::Trigger>

=cut
