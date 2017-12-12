package WebService::Google::Closure;

use Moose;
use MooseX::Types::Moose qw( ArrayRef Str Int );
use LWP::UserAgent;
use Carp qw( croak );
use File::Slurp qw( slurp );

use WebService::Google::Closure::Types qw( ArrayRefOfStrings CompilationLevel );
use WebService::Google::Closure::Response;

our $VERSION = '0.13';
$VERSION = eval $VERSION;

has js_code => (
    is         => 'rw',
    isa        => Str,
);

has file => (
    is         => 'ro',
    isa        => ArrayRefOfStrings,
    trigger    => \&_set_file,
    coerce     => 1,
);

has code_url => (
    is         => 'ro',
    isa        => ArrayRefOfStrings,
    init_arg   => 'url',
    coerce     => 1,
);

has compilation_level => (
    is         => 'ro',
    isa        => CompilationLevel,
    coerce     => 1,
);

has timeout => (
    is         => 'ro',
    isa        => Int,
    default    => 10,
);

has post_url => (
    is         => 'ro',
    isa        => Str,
    default    => 'https://closure-compiler.appspot.com/compile',
    init_arg   => undef,
);

has output_format => (
    is         => 'ro',
    isa        => Str,
    default    => 'json',
    init_arg   => undef,
);

has output_info => (
    is         => 'ro',
    isa        => ArrayRef[Str],
    init_arg   => undef,
    lazy_build => 1,
);

has ua => (
    is         => 'ro',
    init_arg   => undef,
    lazy_build => 1,
);

sub _set_file {
    my $self = shift;
    my $content = '';
    foreach my $f ( @{ $self->file } ) {
        $content .= slurp( $f );
    }
    $self->js_code( $content );
}

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $ua->timeout( $self->timeout );
    $ua->env_proxy;
    $ua->agent( __PACKAGE__ . '/' . $VERSION );
    return $ua;
}

sub _build_output_info {
    return [ qw( compiled_code statistics warnings errors ) ];
}

sub compile {
    my $self = shift;

    if ( $self->compilation_level && $self->compilation_level eq 'NOOP' ) {
        # Don't bother the compiler
        return WebService::Google::Closure::Response->new(
            format  => $self->output_format,
            code    => $self->js_code,
        );
    }

    my $post_args = {};
    foreach my $arg (qw( js_code code_url compilation_level output_format output_info )) {
        next unless $self->$arg;
        $post_args->{ $arg } = $self->$arg;
    }

    my $res = $self->ua->post(
        $self->post_url, $post_args
    );
    unless ( $res->is_success ) {
        croak "Error posting request to Google - " . $res->status_line;
    }

    return WebService::Google::Closure::Response->new(
        format  => $self->output_format,
        content => $res->content,
    );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__


=head1 NAME

WebService::Google::Closure - Perl interface to the Google Closure Javascript compiler service

=head1 SYNOPSIS

This module will take given Javascript code and compile it into compact, high-performance code
using the Google Closure compiler.

    use WebService::Google::Closure;

    my $js_code = "
      function hello(name) {
          alert('Hello, ' + name);
      }
      hello('New user');
    ";

    my $res = WebService::Google::Closure->new(
      js_code => $js_code,
    )->compile;

    print $res->code;
    # prints;
    # function hello(a){alert("Hello, "+a)}hello("New user");


    # Now tell Closure to be more aggressive
    my $res2 = WebService::Google::Closure->new(
      compilation_level => "ADVANCED_OPTIMIZATIONS",
      js_code => $js_code,
    )->compile;

    print $res2->code;
    # prints;
    # alert("Hello, New user");

    print "Original size   = " . $res2->stats->original_size . "\n";
    print "Compressed size = " . $res2->stats->compressed_size . "\n";


For more information on the Google Closure compiler, visit its website at L<http://code.google.com/closure/>


=head1 METHODS

=head2 new

Possible options;

=over 4

=item compilation_level

Specifying how aggressive the compiler should be. There are currently three options.

=over 8

=item "WHITESPACE_ONLY" or 1

Just removes whitespace and comments from your JavaScript.

=item "SIMPLE_OPTIMIZATIONS" or 2 (default)

Performs compression and optimization that does not interfere with the interaction between the compiled JavaScript and other JavaScript. This level renames only local variables.

=item "ADVANCED_OPTIMIZATIONS" or 3

Achieves the highest level of compression by renaming symbols in your JavaScript. When using ADVANCED_OPTIMIZATIONS compilation you must perform extra steps to preserve references to external symbols.

=back

=item js_code

A string containing Javascript code.

=item file

One or more filenames of the files you want compiled

Example:

    use WebService::Google::Closure;

    my $cl1 = WebService::Google::Closure->new(
       file => "/var/www/js/base.js",
    );

    my $cl2 = WebService::Google::Closure->new(
       file => [qw( /var/www/js/base.js /var/www/js/classes.js )],
     );

=item url

One or more urls to the files you want compiled

Example:

    use WebService::Google::Closure;

    my $res = WebService::Google::Closure->new(
       url => "http://code.jquery.com/jquery-1.4.2.js",
       compilation_level => 3,
    )->compile;

    print "Orig Size = " . $res->stats->original_size . "\n";
    print "Comp Size = " . $res->stats->compressed_size . "\n";

    # prints;
    # Orig Size = 163855
    # Comp Size = 65523

=back

=head2 compile

Returns a L<WebService::Google::Closure::Response> object.

Will die if unable to connect to the Google closure service.

=head1 AUTHOR

Magnus Erixzon, C<< <magnus at erixzon.com> >>

=head1 TODO

=over 4

=item externs

When using the compilation level ADVANCED_OPTIMIZATIONS, the compiler achieves extra compression by being more aggressive in the ways that it transforms code and renames symbols. However, this more aggressive approach means that you must take greater care when you use ADVANCED_OPTIMIZATIONS to ensure that the output code works the same way as the input code.

One problem is if your code uses external code that you're not submitting to the compiler - The compiler might then optimize code away, as its not aware of the externally defined functions. The solutions to this is using "externs". I'll implement this when I need it, or if someone asks for it.

See L<http://code.google.com/closure/compiler/docs/api-tutorial3.html> for more information.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-google-closure at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Google-Closure>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Google::Closure

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Google-Closure>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Google-Closure>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Google-Closure>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Google-Closure/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Magnus Erixzon.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
