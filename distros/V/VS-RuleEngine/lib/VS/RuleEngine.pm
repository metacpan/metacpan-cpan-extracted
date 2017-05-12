package VS::RuleEngine;

use strict;
use warnings;

our $VERSION = "0.09";

1;
__END__

=head1 NAME

VS::RuleEngine - Generic rule based processing engine

=head1 SYNOPSIS

A simple example which just randomizes a number 10 times and outputs it to screen if it was under 500.

  use VS::RuleEngine::Constants;
  use VS::RuleEngine::Declare;
  
  my $i = 0;
  
  my $engine = engine {
      prehook "check_i" => does {
          $i++;
          
          return KV_ABORT if $i == 10;
          return KV_CONTINUE;
      };
      
      input "random" => does {
          return int(rand(1000));
      };
      
      rule "under_500" => does {
          my $input = $_[KV_INPUT];
          return KV_MATCH if $input->get("random") < 500;
          return KV_NO_MATCH;
      };
      
      action "mark_under_500" => does {
          my ($input, $local) = @_[KV_INPUT, KV_LOCAL];
          $local->set("output" => $input->get("random") . " was under 500");
      };

      run "mark_under_500" => when "under_500";
      
      output "print" => does {
          my $local = $_[KV_LOCAL];
          my $output = $local->get("output");
          print $output, "\n" if defined $output;
      };
  }

A fictional spam filter

  use VS::RuleEngine::Constants;
  use VS::RuleEngine::Declare;
  
  my $engine = engine {
      prehook "has_more_email" => instanceof "MyApp::HasMoreEmails";
      
      # Returns an Email::Simple instance
      input "email" => instanceof "MyApp::GetEmail";
      
      input "from" => does {
            my $input = $_[KV_INPUT];
            return $input->get("email")->header("From");
      };
      
      rule "is_spam" => instanceof "MyApp::SpamDetector";
      
      rule "is_from_boss" => does {
          my $input = $_[KV_INPUT];
          
          if ($input->get("from") =~ /theboss@company\.com/) {
              return KV_MATCH;
          }
          
          return KV_NO_MATCH;
      };
      
      action "mark_for_deletion" => does {
          my $local = $_[KV_LOCAL];
          $local->set("delete-email" => 1);
      };
      
      run "mark_for_deletion" => when qw(is_spam is_from_boss);
      
      posthook "process_mail" => does {
          my ($input, $local) = @_[KV_INPUT, KV_LOCAL];
          
          if ($local->get("delete-mail") == 1) {
              MyApp::EmailHandler->delete($input->get("email"));
          }
          
          return KV_CONTINUE;
      };
  };
  
  $engine->run();

=head1 DESCRIPTION

VS::RuleEngine is a generic rule based processing engine. Processing is done while neither any pre nor post iteration hook 
aborts processing. Each engine supports multiple pre- and posthooks, inputs, output, actions and rules. An action is 
attached to one or several rules and is executed if any of the rules matches. Input is processed when needed and only 
once per iteration.

Multiple engines can be run in parallel in a runloop. Runloops can be ran until no more data is available for processing 
or by a single step at a time. This way multiple runloops may be executed simultaneously.

=head1 USAGE

VS::RuleEngine has a declarative interface via L<VS::RuleEngine::Declare> which is the simplest way to define engines. The synopsis shows 
an exmaple that could be implemented (with reservations for syntax errors).

=head2 Declarative interface

L<VS::RuleEngine::Declare>

=head2 Loading engines from other sources

Currently creation of engines are only possible using either the declarative interface or by 
creating C<VS::RuleEngine::Engine>-objects directly. Future releases will allow loading of engine declarations 
via XML and other formats.

=head2 Runloops

Runloops transforms engines into something executable and runs them.

L<VS::RuleEngine::Runloop>

=head2 Inputs, Outputs, Rules, Hooks, Actions

The components that makes up an engine.

L<VS::RuleEngine::Input>, L<VS::RuleEngine::Output>, L<VS::RuleEngine::Rule>, L<VS::RuleEngine::Hook>, L<VS::RuleEngine::Action>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-vs-ruleengine@rt.cpan.org>, 
or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Claes Jakobsson C<< <claesjac@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Versed Solutions C<< <info@versed.se> >>. All rights reserved.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
