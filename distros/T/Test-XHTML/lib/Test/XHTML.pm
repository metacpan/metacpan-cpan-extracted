package Test::XHTML;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.13';

#----------------------------------------------------------------------------

=head1 NAME

Test::XHTML - Test web page code validation.

=head1 SYNOPSIS

    use Test::XHTML;

    my $tests = "t/102-internal-level7.csv";
    Test::XHTML::runtests($tests);

=head1 DESCRIPTION

Test the validation of a list of URLs. This includes DTD Validation, WAI WCAG
v2.0 compliance and basic Best Practices.

=cut

# -------------------------------------
# Library Modules

use IO::File;
use Data::Dumper;
use Test::Builder;
use Test::XHTML::Valid;
use Test::XHTML::WAI;
use Test::XHTML::Critic;
use WWW::Mechanize;

# -------------------------------------
# Singletons

my $mech    = WWW::Mechanize->new();
my $txv     = Test::XHTML::Valid->new(mech => $mech);
my $txw     = Test::XHTML::WAI->new();
my $txc     = Test::XHTML::Critic->new();
my $Test    = Test::Builder->new();

sub import {
    my $self    = shift;
    my $caller  = caller;
    no strict 'refs';
    *{$caller.'::runtests'} = \&runtests;
    *{$caller.'::setlog'}   = \&setlog;

    my @args = @_;

    $Test->exported_to($caller);
    $Test->plan(@args)  if(@args);
}

# -------------------------------------
# Public Methods

sub runtests {
    my $tests = shift;
    my ($link,$type,$content,%config,@all);

    my $fh = IO::File->new($tests,'r') or die "Cannot open file [$tests]: $!\n";
    while(<$fh>) {
        s/\s*$//;
        s/^[#,].*$//;
        next    if(/^\s*$/);

        my ($cmd,$text,$label) = split(',',$_,3);
        #$cmd =~ s/\s*$//;
        #$Test->diag("cmd=[$cmd], text=[$text], label=[$label]");

        if($cmd eq 'config') {
            my ($key,$value) = split('=',$text,2);
            $config{lc $key} = $value;
            $txw->level($value) if($key =~ /wai/i);
        } elsif($cmd eq 'all body') {
            push @all, {type => 'like', text => $text, label => $label};
        } elsif($cmd eq 'all body not') {
            push @all, {type => 'unlike', text => $text, label => $label};
        } elsif($cmd eq 'except') {
            push @{ $all[-1]->{except} }, $text;

        } elsif($cmd eq 'body') {
            $label ||= ".. embedded text ('$text') found for '$link'";
            $Test->like($content,qr!$text!s, $label);
            $Test->diag($content)  if($content !~ m!$text!s && $config{'dump'});

        } elsif($cmd eq 'body not') {
            $label ||= ".. embedded text ('$text') not found for '$link'";
            $Test->unlike($content,qr!$text!s, $label);
            $Test->diag($content)  if($content =~ m!$text!s && $config{'dump'});

        } elsif($cmd eq 'form' && $type eq 'url') {
            my ($fname,$ftype) = split('=',$text,2);
            $ftype = undef  unless($ftype =~ /^(num|name|id)$/);
            my $ok = 0;
            my $rs;

            if($fname =~ /^\d+$/ && (!$ftype || $ftype eq 'num')) {
                eval { $rs = $mech->form_number($fname) };
                #$Test->diag("form_number: rs=$rs, [$@]");
                if(!$@ && $rs) { $ok = 1; }
            }
            if(!$ok && (!$ftype || $ftype eq 'name')) {
                eval { $rs = $mech->form_name($fname) };
                #$Test->diag("form_name: rs=$rs, [$@]");
                if(!$@ && $rs) { $ok = 1; }
            }
            if(!$ok && (!$ftype || $ftype eq 'id')) {
                eval { $rs = $mech->form_id($fname) };
                #$Test->diag("form_id: rs=$rs, [$@]");
                if(!$@ && $rs) { $ok = 1; }
            }

            $Test->ok($ok,".. form '$fname' found");

        } elsif($cmd eq 'input' && $type eq 'url') {
            my ($key,$value) = split('=',$text,2);
            if($text eq 'submit' || $key eq 'submit') {
                $mech->submit();
                if($mech->success()) {
                    $content = $mech->content();
                    $link = $mech->base();

                    if(my $result = _check_xhtml(\%config,'xml',$content)) {
                        $Test->is_num($result->{PASS},1,"XHTML validity check for '$link'");
                        if($result->{PASS} != 1) {
                            $Test->diag($txv->errstr());
                            $Test->diag(Dumper($txv->errors())) if($config{ 'dump'});
                            $Test->diag(Dumper($result))        if($config{ 'dump'});
                        }
                    }

                    if(my $result = _check_wai(\%config,$content)) {
                        $Test->is_num($result->{PASS},1,"Content passes basic WAI compliance checks for '$link'");
                        if($result->{PASS} != 1) {
                            $Test->diag($txw->errstr());
                            $Test->diag(Dumper($txw->errors()))     if($config{ 'dump'});
                            $Test->diag(Dumper($result))            if($config{ 'dump'});
                            $Test->diag(Dumper($content))           if($config{ 'dump'} && $config{ 'dump'} == 2);
                        }
                    }

                    if(my $result = _check_critic(\%config,$content)) {
                        $Test->is_num($result->{PASS},1,"Content passes basic page critique checks for '$link'");
                        if($result->{PASS} != 1) {
                            $Test->diag($txc->errstr());
                            $Test->diag(Dumper($txc->errors()))     if($config{ 'dump'});
                            $Test->diag(Dumper($result))            if($config{ 'dump'});
                            $Test->diag(Dumper($content))           if($config{ 'dump'} && $config{ 'dump'} == 2);
                        }
                    }

                } else {
                    $content = '';
                }
            } else {
                $mech->field($key,$value);
            }

        } elsif($cmd eq 'file') {
            $type = $cmd;
            $link = $text;

            if(my $result = _check_xhtml(\%config,$type,$link)) {
                $Test->is_num($result->{PASS},1,"XHTML validity check for '$link'");
                if($result->{PASS} != 1) {
                    $Test->diag($txv->errstr());
                    $Test->diag(Dumper($txv->errors())) if($config{ 'dump'});
                    $Test->diag(Dumper($result))        if($config{ 'dump'});
                }
            }


            $content = $txv->content();
            $label ||= "Got FILE '$link'";
            $Test->ok($content,$label);

            if(my $result = _check_wai(\%config,$content)) {
                $Test->is_num($result->{PASS},1,"Content passes basic WAI compliance checks for '$link'");
                if($result->{PASS} != 1) {
                    $Test->diag($txw->errstr());
                    $Test->diag(Dumper($txw->errors()))     if($config{ 'dump'});
                    $Test->diag(Dumper($result))            if($config{ 'dump'});
                    $Test->diag(Dumper($content))           if($config{ 'dump'} && $config{ 'dump'} == 2);
                }
            }

            if(my $result = _check_critic(\%config,$content)) {
                $Test->is_num($result->{PASS},1,"Content passes basic page critique checks for '$link'");
                if($result->{PASS} != 1) {
                    $Test->diag($txc->errstr());
                    $Test->diag(Dumper($txc->errors()))     if($config{ 'dump'});
                    $Test->diag(Dumper($result))            if($config{ 'dump'});
                    $Test->diag(Dumper($content))           if($config{ 'dump'} && $config{ 'dump'} == 2);
                }
            }

            for my $all (@all) {
                my $ignore = 0;
                for my $except (@{ $all->{except} }) {
                    next    unless($link =~ /$except/);
                    $ignore = 1;
                }

                if($all->{type} eq 'like') {
                    $label = $all->{label} || ".. embedded text ('$all->{text}') found for '$link'";
                    next    if($ignore);
                    $Test->like($content,qr!$all->{text}!, $label);
                    $Test->diag($content)  if($content !~ m!$all->{text}! && $config{'dump'});
                } else {
                    $label = $all->{label} || ".. embedded text ('$all->{text}') not found for '$link'";
                    next    if($ignore);
                    $Test->unlike($content,qr!$all->{text}!, $label);
                    $Test->diag($content)  if($content =~ m!$all->{text}! && $config{'dump'});
                }
           }

        } elsif($cmd eq 'url') {
            $type = $cmd;
            $link = $text;

            if(my $result = _check_xhtml(\%config,$type,$link)) {
                $Test->is_num($result->{PASS},1,"XHTML validity check for '$link'");
                if($result->{PASS} != 1) {
                    $Test->diag($txv->errstr());
                    $Test->diag(Dumper($txv->errors())) if($config{ 'dump'});
                    $Test->diag(Dumper($result))        if($config{ 'dump'});
                }
            }

            $content = $txv->content();
            $label ||= "Got URL '$link'";
            $Test->ok($content,$label);

            if(my $result = _check_wai(\%config,$content)) {
                $Test->is_num($result->{PASS},1,"Content passes basic WAI compliance checks for '$link'");
                if($result->{PASS} != 1) {
                    $Test->diag($txw->errstr());
                    $Test->diag(Dumper($txw->errors()))     if($config{ 'dump'});
                    $Test->diag(Dumper($result))            if($config{ 'dump'});
                    $Test->diag(Dumper($content))           if($config{ 'dump'} && $config{ 'dump'} == 2);
                }
            }

            if(my $result = _check_critic(\%config,$content)) {
                $Test->is_num($result->{PASS},1,"Content passes basic page critique checks for '$link'");
                if($result->{PASS} != 1) {
                    $Test->diag($txc->errstr());
                    $Test->diag(Dumper($txc->errors()))     if($config{ 'dump'});
                    $Test->diag(Dumper($result))            if($config{ 'dump'});
                    $Test->diag(Dumper($content))           if($config{ 'dump'} && $config{ 'dump'} == 2);
                }
            }

            for my $all (@all) {
                my $ignore = 0;
                for my $except (@{ $all->{except} }) {
                    next    unless($link =~ /$except/);
                    $ignore = 1;
                }

                if($all->{type} eq 'like') {
                    $label = $all->{label} || ".. embedded text ('$all->{text}') found for '$link'";
                    next    if($ignore);
                    $Test->like($content,qr!$all->{text}!, $label);
                    $Test->diag($content)  if($content !~ m!$all->{text}! && $config{'dump'});
                } else {
                    $label = $all->{label} || ".. embedded text ('$all->{text}') not found for '$link'";
                    next    if($ignore);
                    $Test->unlike($content,qr!$all->{text}!, $label);
                    $Test->diag($content)  if($content =~ m!$all->{text}! && $config{'dump'});
                }
           }

        }
    }
    $fh->close;
}

sub _check_xhtml {
    my ($config,$type,$link) = @_;

    if($config->{xhtml}) {
        $txv->clear();

           if($type eq 'file')  { $txv->process_file($link); }
        elsif($type eq 'url')   { $txv->process_link($link); }
        elsif($type eq 'xml')   { $txv->process_xml($link); }

        return $txv->process_results();

    } else {
           if($type eq 'file')  { $txv->retrieve_file($link); }
        elsif($type eq 'url')   { $txv->retrieve_url($link); }
    }

    return;
}

sub _check_wai {
    my ($config,$content) = @_;

    return  unless($config->{wai});

    $txw->clear();
    $txw->validate($content);
    return $txw->results();
}

sub _check_critic {
    my ($config,$content) = @_;

    return  unless($config->{critic});

    $txc->clear();
    $txc->validate($content);
    return $txc->results();
}

sub setlog {
    my %hash = @_;

    $txv->logfile($hash{logfile})    if($hash{logfile});
    $txv->logclean($hash{logclean})  if(defined $hash{logclean});

    $txw->logfile($hash{logfile})    if($hash{logfile});
    $txw->logclean($hash{logclean})  if(defined $hash{logclean});
}

1;

__END__

=head1 FUNCTIONS

=head2 runtests(FILE)

Runs the tests contained within FILE. The entries in FILE define how the tests
are performed, and on what.

A simple file might look like:

    #,# Configuration,
    config,xhtml=1,
    
    url,http://mysite/index.html,Test My Page

Where each field on the comma separated line represent 'cmd', 'text' and 
'label'. Valid 'cmd' values are:

  #             - comment line, ignores the line
  config        - set configuration value (see below)
  all body      - test that 'text' exists in body content of all urls.
  all body not  - test that 'text' does not exist in body content of all urls.
  url           - test single url
  body          - test that 'text' exists in body content of the previous url.
  body not      - test that 'text' does not exist in body content of the 
                  previous url.
  form          - name and type of form to use with subsequent input commands,
                  when more than one form exists in the page.
  input         - form fill, use as 'fieldname=xxx', with 'submit' as the last
                  input to submit the form.

The 'label' is used with the tests, and if left blank will be automatically 
generated.

=head2 setlog(HASH)

If required will record a test run to a log file. If you do not wish to record
multiple runs, set 'logclean => 1' and log file will be recreated each time.
Otherwise all results are appended to the named log file.

  Test::XHTML::setlog( logfile => './test.log', logclean => 1 );

=head1 CONFIGURATION

=head2 Options

There are currently 4 configuration options available, which can be listed in
your test file as follows:

    #,# Configuration,
    config,xhtml=1,
    config,wai=1,
    config,critic=1,
    config,dump=1,

=head2 XHTML tests

Enable DTD valiadtion tests.

=head2 WAI WCAG v2.0 tests

Enable WAI WCAG v2.0 tests. Values can be set to represent the level of
compliance required.

    config,wai=1,   # Level A compliance
    config,wai=2,   # Level AA compliance
    config,wai=3,   # Level AAA compliance (not currently available)

=head2 Critique tests

Enable tests for some recommended Best Practices.

=head2 Dumping content

Where errors occur, it may be useful to obtain the page content to diagnose 
problems. Enabling this option will produce the content as disanostics.

=head1 NOTES

=head2 Test::XHTML::Valid & xhtml-valid

The underlying package that provides the DTD validation framework, is only used
sparingly by Test::XHTML. Many more methods to test websites (both remote and 
local) are supported, and can be accessed via the xhtml-valid script that 
accompanies this distribution.

See script documentation and L<Test::XHTML::Valid> for further details.

=head2 Internet Access

In some instances XML::LibXML may require internet access to obtain all the 
necessary W3C and DTD specifications as denoted in the web pages you are 
attempting to validate. However, for some more common specifications, for 
HTML4 and XHTML1, this distribution pre-loads the XML Catalog to avoid making
calls across the internet.

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to barbie@cpan.org.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 SEE ALSO

L<XML::LibXML>,
L<Test::XHTML::Valid>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008-2015 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
