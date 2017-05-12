package WWW::Mechanize::Script;

use strict;
use warnings;

use File::Basename qw(fileparse);
use File::Path qw(make_path);
use Hash::Merge ();
use IO::File;
use Module::Pluggable::Object ();
use Params::Util qw(_HASH);
use Template              ();
use WWW::Mechanize        ();
use WWW::Mechanize::Timed ();

# ABSTRACT: fetch websites and executes tests on the results


our $VERSION = '0.100';


sub new
{
    my ( $class, $cfg ) = @_;

    my $self = bless( { cfg => { %{$cfg} } }, $class );

    return $self;
}


sub _gen_code_compute
{
    my $check_cfg = $_[0];
    my $compute_code;

    if ( defined( $check_cfg->{code_func} ) )
    {
        my $compute_str = "sub { " . $check_cfg->{code_func} . " };";
        $compute_code = eval $compute_str;
        $@ and die $@;
    }

    if ( !defined($compute_code) and defined( $check_cfg->{code_cmp} ) )
    {
        my $compute_str =
            "sub { my (\$cur,\$new) = \@_; \$cur "
          . $check_cfg->{code_cmp}
          . " \$new ? \$cur : \$new; };";
        $compute_code = eval $compute_str;
        $@ and die $@;
    }

    if ( !defined($compute_code) )
    {
        my $compute_str = "sub { my (\$cur,\$new) = \@_; \$cur > \$new ? \$cur : \$new; };";
        $compute_code = eval $compute_str;
        $@ and die $@;
    }

    return $compute_code;
}


sub test_plugins
{
    my ( $self, $test ) = @_;

    unless ( defined( $self->{all_plugins} ) )
    {
        my $plugin_base = join( "::", __PACKAGE__, "Plugin" );
        my $finder =
          Module::Pluggable::Object->new(
                                          require     => 1,
                                          search_path => [$plugin_base],
                                          except      => [$plugin_base],
                                          inner       => 0,
                                          only        => qr/^${plugin_base}::\p{Word}+$/,
                                        );

        # filter out things that don't look like our plugins
        my @ap =
          map  { $_->new( $self->{cfg}->{defaults} ) }
          grep { $_->isa($plugin_base) } $finder->plugins();
        $self->{all_plugins} = \@ap;
    }

    my @tp = grep { $_->can_check($test) } @{ $self->{all_plugins} };
    return @tp;
}


sub get_request_value
{
    my ( $self, $request, $value_name ) = @_;

    $value_name or return;

    return $request->{$value_name} // $self->{cfg}->{default}->{request}->{$value_name};
}

sub _get_target
{
    my $def = shift;

    my $target = $def->{target};
    $target //= "-";

    if ( $target ne "-" and $def->{append} )
    {
        my ( $name, $path, $suffix ) = fileparse($target);
        -d $path or make_path($path);
        my $fh = IO::File->new( $target, ">>" );
        $fh->seek( 0, SEEK_END );
        $target = $fh;
    }

    return $target;
}


sub summarize
{
    my ( $self, $code, @msgs ) = @_;

    my %vars = (
                 %{ _HASH( $self->{cfg}->{templating}->{vars} ) // {} },
                 %{ _HASH( $self->{cfg}->{report}->{vars} )     // {} },
                 CODE     => $code,
                 MESSAGES => [@msgs]
               );

    my $input    = $self->{cfg}->{summary}->{source} // \$self->{cfg}->{summary}->{template};
    my $output   = _get_target( $self->{cfg}->{summary} );
    my $template = Template->new();
    $template->process( $input, \%vars, $output )
      or die $template->error();

    return;
}


sub gen_report
{
    my ( $self, $full_test, $mech, $code, @msgs ) = @_;
    my $response = $mech->response();
    my %vars = (
                 %{ _HASH( $self->{cfg}->{templating}->{vars} ) // {} },
                 %{ _HASH( $self->{cfg}->{report}->{vars} )     // {} },
                 CODE     => $code,
                 MESSAGES => [@msgs],
                 RESPONSE => {
                               CODE    => $response->code(),
                               CONTENT => $response->content(),
                               BASE    => $response->base(),
                               HEADER  => {
                                           map { $_ => $response->headers()->header($_) }
                                             $response->headers()->header_field_names()
                                         },
                             }
               );

    my $input    = $self->{cfg}->{report}->{source} // \$self->{cfg}->{report}->{template};
    my $output   = _get_target( $self->{cfg}->{report} );
    my $template = Template->new();
    $template->process( $input, \%vars, $output )
      or die $template->error();

    return;
}


sub run_script
{
    my ( $self, @script ) = @_;
    my $code = 0;    # XXX
    my @msgs;
    my $compute_code = _gen_code_compute( $self->{cfg}->{defaults}->{check} );

    foreach my $test (@script)
    {
        my ( $test_code, @test_msgs ) = $self->run_test($test);
        $code = &{$compute_code}( $code, $test_code );
        push( @msgs, @test_msgs );
    }

    if ( $self->{cfg}->{summary} )
    {
        my $summary = $self->summarize( $code, @msgs );
    }

    return ( $code, @msgs );
}


sub run_test
{
    my ( $self, $test ) = @_;

    my $merger = Hash::Merge->new('LEFT_PRECEDENT');
    my $full_test = $merger->merge( $test, $self->{cfg}->{defaults} );

    my $mech = WWW::Mechanize::Timed->new();
    foreach my $akey ( keys %{ $full_test->{request}->{agent} } )
    {
        # XXX clone and delete array args before
        $mech->$akey( $full_test->{request}->{agent}->{$akey} );
    }

    my $method = $full_test->{request}->{method};
    defined( $test->{request}->{http_headers} )
      ? $mech->$method( $full_test->{request}->{uri}, %{ $full_test->{request}->{http_headers} } )
      : $mech->$method( $full_test->{request}->{uri} );

    $full_test->{compute_code} = _gen_code_compute( $full_test->{check} );

    my $code = 0;
    my @msgs;
    foreach my $tp ( $self->test_plugins($full_test) )
    {
        my ( $plug_code, @plug_msgs ) = $tp->check_response( $full_test, $mech );
        $code = &{ $full_test->{compute_code} }( $code, $plug_code );
        push( @msgs, @plug_msgs );
    }

    if ( $self->{cfg}->{report} )
    {
        $self->gen_report( $full_test, $mech, $code, @msgs );
    }

    return ( $code, @msgs );
}

1;

__END__

=pod

=head1 NAME

WWW::Mechanize::Script - fetch websites and executes tests on the results

=head1 VERSION

version 0.101

=head1 SYNOPSIS

  use WWW::Mechanize::Script;

  my $wms = WWW::Mechanize::Script->new();
  $wms->run_script(@script);

  foreach my $test (@script) {
    $wms->run_test(%{$test});
  }

=head1 METHODS

=head2 new(\%cfg)

Instantiates new WWW::Mechanize::Script object.

Configuration hash looks like:

    defaults => {
	check => { # check defaults
	    "code_cmp" : ">",
	    "XXX_code" : 2,
	    "ignore_case" : true,
	},
	request => { # request defaults
	    agent => { # LWP::UserAgent defaults
		agent => "Agent Adderly",
		accept_cookies => 'yes',    # check LWP::UA param
		show_cookie    => 'yes',    # check LWP::UA param
		show_headers   => 'yes',    # check LWP::UA param
		send_cookie    => 'yes',    # check LWP::UA param
	    },
	},
    },
    script_dirs => [qw(/old/wtscripts /new/json_scripts)],
    summary => {
        template => "[% CODE_NAME; IF MESSAGES.size > 0 %] - [% MESSAGES.join(', '); END %]\n",
        target => "-"
    },
    report => {
        template => "[% USE Dumper; Dumper.dump(RESPONSE) %]",
        target => "/tmp/@OPTS_FILE@.log",
        append => true
    }

=head2 _gen_code_compute

Interpretes one of following config hash parameters

    defaults => {
	check => { # check defaults
	    code_cmp => ">",
	    code_func => 'my ($cur,$new) = @_; return $cur > $new ? $cur : $new;'
	}
    }

When none of them are there, the sample in defaults->check->code_func is used.

=head2 test_plugins( )

The C<plugins()> classmethod returns the names of configuration loading plugins as 
found by L<Module::Pluggable::Object|Module::Pluggable::Object>.

=head2 get_request_value($request,$value_name)

Returns the value for creating the request - either from current script
or from defaults (C<< defaults->request->$value_name >>).

=head2 summarize($code,@msgs)

Generates the summary passing the template in the configuration of
C<< config->summary >> into L<Template::Toolkit>.

Following variables are provided for the template processing:

=over 4

=item CODE

The accumulated return code of all executed checks computed via
L</_gen_code_compute>.

=item MESSAGES

Collected messages returned of all executed checks.

=back

Plus all constants named in the C<< config->templating->vars >> hash and
those in C<< config->summary->vars >> hash.

The output target is guessed from C<< config->summary->target >> whereby
the special target I<-> is interpreted as C<stdout>.

=head2 gen_report($full_test, $mech, $code, @msgs)

Generates a report for a test within a script by passing the template
in the configuration of C<< config->report >> into L<Template::Toolkit>.

Following variables are provided for the template processing:

=over 4

=item CODE

The accumulated return code of all executed checks computed via
L</_gen_code_compute>.

=item MESSAGES

Collected messages returned of all executed checks.

=item RESPONSE

Hash containing the following L<HTTP::Response|response> items:

=over 8

=item CODE

HTTP response code 

=item CONTENT

Content of the response

=item BASE

The base URI for this response

=item HEADER

Header keys/values as perl hash

=back

=back

Plus all constants named in the C<< config->templating->vars >> hash and
those in C<< config->report->vars >> hash.

The output target is guessed from C<< config->summary->target >> whereby
the special target I<-> is interpreted as C<stdout>.

When the C<< config->summary->append >> flag is set and contains a true
value, the output is appended to an existing target.

=head2 run_script(@script)

Runs a script consisting of at least one test and generates a summary if
configured. The code to accumulate the return codes from each test is taken
from C<< config->defaults->check >> as described in L</_gen_code_compute>.

Returns the accumulated return codes from all tests in the given script.

=head2 run_test(\%test)

Runs one test and generates a report if configured (C<< config->report >>).

The request is constructed from C<< test->request >> whereby the part
below C<< test->request->agent >> is used to parametrize a new instance
of L<WWW::Mechanize::Timed>.

All keys defined below C<< test->request->agent >> are taken as
setter of WWW::Mechanize::Timed or a inherited class.

If there is a hash defined at C<< test->request->http_headers >>, those
headers are passed along with the URI specified at C<< test->request->uri >>
to GET/POST or whatever you want to do (C<< test->request->method >>).

Which checks are executed is defined below C<< test->check >>. Each valid
plugin below the I<WWW::Mechanize::Script::Plugin> namespace is approved
for relevance for the test (see L<WWW::Mechanize::Script::Plugin/can_check>).

The test specification is enriched by the configuration in
C<< config->defaults >> using L<Hash::Merge> with the I<LEFT_PRECEDENT>
ruleset. Please care about the ruleset especially when merging arrays
is to expect.

The code to accumulate the return codes from each test is taken
from C<< test->check >> as described in L</_gen_code_compute>.

Returns the accumulated return codes from all checks in the given tests.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Script or by email
to bug-www-mechanize-script@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Jens Rehsack <rehsack@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jens Rehsack.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
