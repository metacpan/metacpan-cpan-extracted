package Test::WWW::Jasmine;

use strict;
use warnings;
no  warnings 'uninitialized';

use Carp;
use File::Temp;

use Test::More;
use WWW::Selenium;

### VERSION ###

our $VERSION = '0.02';

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Instantiate new Test::WWW::Jasmine object
#

sub new {
    my ($class, %params) = @_;

    my $self = bless {}, $class;

    $self->{spec_file}   = delete $params{spec_file};
    $self->{spec_script} = delete $params{spec_script};
    $self->{jasmine_url} = delete $params{jasmine_url};
    $self->{browser_url} = delete $params{browser_url};
    $self->{html_dir}    = delete $params{html_dir};

    # If we got passed a ready Selenium object, just use it
    $self->{selenium} = delete $params{selenium};

    if ( defined $self->{selenium} ) {
        $self->{external_selenium} = 1;
    }
    else {
        $self->{selenium} = $self->_start_selenium(%params);
    };

    $self->_init_scripts;

    return $self;
}

### PUBLIC INSTANCE METHOD ###
#
# Run tests in Selenium browser window
#

sub run {
    my ($self) = @_;

    # Build HTML test file
    my $test_url = $self->_build_html;

    # Open it in browser...
    $self->selenium->open($test_url);

    # Now wait for the actual tests to run and process results
    eval { $self->_process_results };

    my $error = $@;

    # Finally, clean up
    $self->_cleanup;

    die $error if $error;
}

### PUBLIC INSTANCE METHODS ###
#
# Read only getters
#

sub spec_file   { shift->{spec_file}    }
sub spec_script { shift->{spec_script}  }
sub jasmine_url { shift->{jasmine_url}  }
sub selenium    { shift->{selenium}     }
sub html_dir    { shift->{html_dir}     }
sub css         { @{ shift->{css} }     }
sub scripts     { @{ shift->{scripts} } }

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Clean up temporary files and Selenium connection
#

sub _cleanup {
    my ($self) = @_;

    # If Selenium object was passed on us, leave it intact
    $self->_stop_selenium unless $self->{external_selenium};

    unlink $self->{file_path} if $self->{file_path};
}

### PRIVATE INSTANCE METHOD ###
#
# Init Selenium object
#

sub _start_selenium {
    my ($self, %params) = @_;

    # Set some (reasonable) defaults
    $params{host}    = 'localhost' unless defined $params{host};
    $params{port}    = 4444        unless defined $params{port};
    $params{browser} = '*firefox'  unless defined $params{browser};

    # This one is fixed
    $params{browser_url} ||= 'http://127.0.0.1/index.html';

    my $sel = WWW::Selenium->new(%params);

    $sel->start;
    $sel->set_timeout( $params{timeout} || 10000 );

    return $sel;
}

### PRIVATE INSTANCE METHOD ###
#
# Stop Selenium browsers
#

sub _stop_selenium {
    my ($self) = @_;

    $self->selenium->stop() if $self->selenium;
}

### PRIVATE INSTANCE METHOD ###
#
# Initialize CSS and JavaScript
#

sub _init_scripts {
    my ($self) = @_;

    # Default CSS list is empty
    $self->{css} = [];

    # Default script list only includes Jasmine runner
    $self->{scripts} = [ $self->jasmine_url ];

    # Parse the spec
    $self->_parse_spec;
}

### PRIVATE INSTANCE METHOD ###
#
# Build HTML test file and save it to HTTP accessible directory
#

sub _build_html {
    my ($self) = @_;

    my $html = $self->_get_test_html;

    my $html_file = $self->_get_html_file_name;
    my $html_dir  = $self->html_dir;

    $html_dir =~ s{/+$}{};

    my $file_path = $html_dir . '/' . $html_file;

    {
        open my $fh, '>:utf8', $file_path or
            croak "Can't open $html_file: $!";
        print $fh $html;
        close $fh;
    }

    $self->{file_path} = $file_path;

    my $browser_url = $self->{browser_url};
    $browser_url =~ s{/+$}{};

    my $url = $browser_url . '/' . $html_file;

    return $url;
}

### PRIVATE INSTANCE METHOD ###
#
# Wait for well known DOM nodes to appear and process them
#

sub _process_results {
    my ($self) = @_;

    my $sel = $self->selenium;

    $sel->wait_for_element_present('__SimpleReporterNumTests');
    my $num_tests = $sel->get_text('__SimpleReporterNumTests');

    if ( $num_tests == 0 ) {
        plan skip_all => 'Jasmine runner said it has no tests';

        return;
    };

    plan tests => $num_tests;

    for my $i ( 0 .. $num_tests - 1 ) {
        my $element = "__SimpleReporterTest$i";

        $sel->wait_for_element_present($element);

        my ($result, $desc)
            = $sel->get_text($element) =~ /^(skip|pass|fail) (.*)/;

        my $num_subtests = $sel->get_text("${element}NumSubtests") || 0;

        # When a spec has more than one expect() we pretend
        # that they're subtests
        if ( $num_subtests > 1 ) {
            subtest $desc => sub {
                for my $j ( 0 .. $num_subtests - 1 ) {
                    my $subelement = "${element}Subtest${j}";

                    $sel->wait_for_element_present("$subelement");
                    my $subresult = $sel->get_text("$subelement");

                    if ( $subresult eq 'pass' ) {
                        pass sprintf 'expectation %d', $j + 1;
                    }
                    else {
                        fail sprintf 'expectation %d', $j + 1;

                        $sel->wait_for_element_present("${subelement}Diag");
                        my $message = $sel->get_text("${subelement}Diag");

                        if ( $message ) {
                            $message =~ s{<br/>}{\n}g;
                            diag "Jasmine diagnostics:\n$message";
                        };
                    };
                };
            };
        }

        # When there's just one expect, we pretend that
        # it's the whole test
        else {
            if ( $result eq 'skip' ) {
                SKIP: { skip 'Skipped in Jasmine', 1; pass $desc }
            }
            elsif ( $result eq 'pass' ) {
                pass $desc;
            }
            elsif ( $result eq 'fail' ) {
                fail $desc;
            };
        };
    };

    $sel->wait_for_element_present('__SimpleReporterFinished');

    done_testing $num_tests;
}

### PRIVATE INSTANCE METHOD ###
#
# Parse spec file looking for keywords
#

sub _parse_spec {
    my ($self) = @_;

    my $spec_script = $self->spec_script;

    if ( not defined $spec_script ) {
        my $spec_file = $self->spec_file;

        $spec_script = do {
            open my $fh, '<:utf8', $spec_file or
                croak "Can't open $spec_file: $!";
            local $/;
            <$fh>;
        };
    };

    my @css     = $spec_script =~ m{^\W*\@css\s+([\S]+)$}mg;
    my @scripts = $spec_script =~ m{^\W*\@script\s+([\S]+)$}mg;

    push @{ $self->{css}     }, @css;
    push @{ $self->{scripts} }, @scripts;

    $self->{spec_script} = $spec_script;
}

### PRIVATE INSTANCE METHOD ###
#
# Generate a name for temporary test HTML file and stash it
#

sub _get_html_file_name {
    my ($self) = @_;

    my $name = File::Temp::mktemp('jasmine_test_XXXXXXXXXX').'.html';

    return $self->{html_file} = $name;
}

### PRIVATE INSTANCE METHOD ###
#
# Compile HTML page that contains all elements necessary to run tests
#

sub _get_test_html {
    my ($self) = @_;

    my $html = "<html>\n<head>\n";

    $html .= qq|<link rel="stylesheet" type="text/css" href="$_" />\n|
        for $self->css;

    $html .= qq|<script type="text/javascript" src="$_"></script>\n|
        for $self->scripts;

    $html .= "</head>\n<body>\n";

    $html .= qq|<script type="text/javascript">\n|.
             $self->_get_reporter_script . "\n" .
             qq|</script>\n|;

    $html .= qq|<script type="text/javascript">\n|.
             $self->spec_script . "\n" .
             qq|</script>\n|;

    $html .= qq|<script type="text/javascript">\n|.
             $self->_get_main_script . "\n" .
             qq|</script>\n|;

    $html .= "</body>\n</html>\n";

    return $html;
}

### PRIVATE INSTANCE METHOD ###
#
# Return SimpleReporter script
#

sub _get_reporter_script {
    return <<END_REPORTER;

// Global scope here
var jasmine = jasmine || {};

jasmine.SimpleReporter = function(doc) {
    var me = this;
    
    me.document = doc || document;
    me.counter  = 0;
};

jasmine.SimpleReporter.prototype.createNode = function(attributes) {
    var me = this,
        type, attrs, el;
    
    attrs = attributes || {};
    type  = attrs.type || 'div';
    
    el = me.document.createElement(type);
    
    for ( var attr in attrs ) {
        if ( attr == 'type' ) {
            continue;
        }
        else if ( attr == "className" ) {
            el[attr] = attrs[attr];
        }
        else if ( attr == "html" ) {
            el.innerHTML = attrs[attr];
        }
        else {
            el.setAttribute(attr, attrs[attr]);
        };
    };

    me.document.body.appendChild(el);
    
    return el;
};

jasmine.SimpleReporter.prototype.reportRunnerStarting = function(runner) {
    var me = this,
        specs, div;
    
    specs = runner.specs();
    
    me.createNode({
        id:   '__SimpleReporterNumTests',
        html: specs.length
    });
};

jasmine.SimpleReporter.prototype.reportRunnerResults = function(runner) {
    var me = this,
        div;

    me.createNode({
        id:   '__SimpleReporterFinished',
        html: 'finished'
    });
};

jasmine.SimpleReporter.prototype.reportSuiteResults = function(suite) {};

jasmine.SimpleReporter.prototype.reportSpecStarting = function(spec) {};

jasmine.SimpleReporter.prototype.reportSpecResults = function(spec) {
    var me = this,
        results, specNo, msg, div;

    specNo = me.counter++;
    
    results = spec.results();

    me.createNode({
        id:   '__SimpleReporterTest' + specNo + 'NumSubtests',
        html: results.totalCount
    });

    var items = results.getItems();
    for ( var i = 0, l = items.length; i < l; i++ ) {
        var result = items[i];

        msg = result.passed() ? 'pass' : 'fail';

        me.createNode({
            id:   '__SimpleReporterTest' + specNo + 'Subtest' + i,
            html: msg
        });

        if ( msg == 'fail' ) {
            var diag = result.message;

            /*
            try {
                diag += "\\n" + result.trace.stack.replace(/\\n/, '<br/>');
            } catch (e) {};
            */

            me.createNode({
                id:   '__SimpleReporterTest'+specNo+'Subtest'+i+'Diag',
                html: diag
            });
        };
    };
    
    msg = results.skipped  ? 'skip ' + spec.description
        : results.passed() ? 'pass ' + spec.description
        :                    'fail ' + spec.description
        ;

    me.createNode({
        id:   '__SimpleReporterTest' + specNo,
        html: msg
    });
};
END_REPORTER
}

### PRIVATE INSTANCE METHOD ###
#
# Return main Jasmine invocation script
#

sub _get_main_script {
    return <<END_SCRIPT;
(function() {
    var jasmineEnv = jasmine.getEnv();
    jasmineEnv.updateInterval = 1000;

    var simpleReporter = new jasmine.SimpleReporter();

    jasmineEnv.addReporter(simpleReporter);
    jasmineEnv.specFilter = function() { return true; };

    var currentWindowOnload = window.onload;

    window.onload = function() {
        if (currentWindowOnload) {
            currentWindowOnload();
        };
        
        jasmineEnv.execute();
    };
})();
END_SCRIPT
}

1;

__END__

=pod

=head1 NAME

Test::WWW::Jasmine - Run Jasmine test specs for JavaScript from Perl

=head1 SYNOPSIS

Write Jasmine test spec:

 /*
  * @css /path/to/stylesheet.css
  * @script /path/to/script.js
  */
 
 describe('test suite', function() {
     it('should run tests', function() {
         expect(true).toBeTruthy();
         expect(false).toBeFalsy();
     });
 });

Run Test::WWW::Jasmine:

 use Test::WWW::Jasmine;
 
 my $jasmine = Test::WWW::Jasmine->new(
     spec_file   => '/filesystem/path/to/test/spec.js',
     jasmine_url => 'http://myserver/jasmine/jasmine.js',
     html_dir    => '/filesystem/path/to/htdocs/test',
     browser_url => 'http://myserver/test',
     selenium    => $custom_selenium_object,
 );
 
 $jasmine->run();

=head1 DESCRIPTION

This module implements Perl test runner for JavaScript test specs that use
Jasmine BDD framework. Test::WWW::Jasmine uses WWW::Selenium to run tests
in a browser, thus making possible to test complex JavaScript applications
that rely heavily on DOM availability.

Test spec output is collected and converted to TAP format; from Perl
perspective Jasmine test specs look just like ordinary Perl tests.

=head1 METHODS

=over 4

=item new(%params)

Creates a new instance of Jasmine runner. Accepts the following arguments:

=over 8

=item spec_file

Filesystem path to Jasmine spec file.

=item spec_script

Jasmine spec script; this option is mutually exclusive with spec_file.

=item jasmine_url

URL to Jasmine library, jasmine.js.

=item html_dir

Filesystem path to directory that is within www root and is writeable to
Jasmine runner. For each test script, an HTML file is generated and placed
to this directory; the file URL is then fed to Selenium to run in browser.

Example: /var/www/htdocs/test

=item browser_url

URL that points to the html_dir via HTTP server. This URL will be used to
run HTML with test spec in browser.

Example: http://localhost/test

=item selenium

If you don't want Test::WWW::Selenium to instantiate a new WWW::Selenium
object, pass it as constructor argument. It is especially useful when you
want to control Selenium options, or use remote testing provider like
Sauce Labs, etc.

=back

=item run

This method reads test spec, generates HTML with embedded spec and runner
JavaScript, stores it to html_dir and runs it through browser.

=back

=head1 TEST SPEC FORMAT

Jasmine test specs are ordinary JavaScript, but Test::WWW::Jasmine adds
two keywords that can be used to include CSS stylesheets and other scripts:

=over 4

=item @css

Use this keyword as C<@css /path/to/stylesheet.css> to include stylesheets.
For each @css sheet, a <link> tag will be added to HTML head.

=item @script

Use this keyword as C<@script /path/to/script.js> to include additional
JavaScript. Each script will be downloaded by test runner (in browser) and
eval'ed.

=back

Place these keywords in comment section near the top of the spec. Any
whitespace and usual decorations like '*' before @css/@script will be
ignored.

Note that @script keywords are processed synchronously; each script
is downloaded and eval'ed at the time @script keyword is encountered.
This matches usual browser behavior; it also means that the test spec
JavaScript itself will be evaluated *after* all C<@script>s are processed.

You can place any word character (x by convention) before keyword to
disable it temporarily.

=head1 DEPENDENCIES

Test::WWW::Jasmine depends on the following modules:
L<Test::WWW::Selenium>.

=head1 SEE ALSO

For more information on Jasmine and JavaScript testing, see
L<https://github.com/pivotal/jasmine/wiki>.

=head1 CAVEATS

Perl interpreter running Test::WWW::Jasmine should have access to
a directory that is accessible via http. This implies an HTTP server
already installed and configured, which shouldn't be a big problem
by the time when you start writing JavaScript tests. :)

=head1 BUGS AND LIMITATIONS

There are undoubtedly lots of bugs in this module. Use github tracker
to report them (the best way) or just drop me an e-mail. Patches are welcome.

=head1 AUTHOR

Alexander Tokarev E<lt>tokarev@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

I would like to thank IntelliSurvey, Inc for sponsoring my work
on this module.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012 Alexander Tokarev.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

=cut

