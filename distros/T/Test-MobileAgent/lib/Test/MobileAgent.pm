package Test::MobileAgent;

use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.06';

our @EXPORT    = qw/test_mobile_agent/;
our @EXPORT_OK = qw/test_mobile_agent_env
                    test_mobile_agent_headers
                    test_mobile_agent_list/;
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

sub test_mobile_agent {
  my %env = test_mobile_agent_env(@_);

  $ENV{$_} = $env{$_} for keys %env;

  return %env if defined wantarray;
}

sub test_mobile_agent_env {
  my ($agent, %extra_headers) = @_;

  my ($vendor, $type) = _find_vendor($agent);
  my $class = _load_class($vendor);
  return $class->env($type, %extra_headers);
}

sub test_mobile_agent_headers {
  my %env = test_mobile_agent_env(@_);

  require HTTP::Headers::Fast;
  my $headers = HTTP::Headers::Fast->new;
  foreach my $name (keys %env) {
    (my $short_name = $name) =~ s/^HTTP[-_]//;
    $headers->header($short_name => $env{$name});
  }
  $headers;
}

sub test_mobile_agent_list {
  my ($vendor, $type) = _find_vendor(@_);
  my $class = _load_class($vendor);
  return $class->list($type);
}

sub _find_vendor {
  my $agent = shift;

  if ($agent =~ /^[a-z]+$/) {
    if ($agent =~ /^ip(?:hone|[oa]d)$/) {
      $agent =~ tr/p/P/;
      return ("Smartphone", "($agent;");
    }
    elsif ($agent eq 'android') {
      return ("Smartphone", 'Android');
    }
    return (ucfirst($agent), '');
  }
  elsif ($agent =~ /^[a-z]+\./) {
    my ($vendor, $type) = split /\./, $agent;
    if ($vendor =~ /^(ip(?:hone|[oa]d)|android)$/) {
      $type = "$vendor.+$type";
      return ("Smartphone", qr/$type/);
    }
    if ($type =~ /^iP(?:hone|[oa]d)$/i) {
      $type = "($type;";
    }
    return (ucfirst $vendor, $type);
  }
  else {
    # do some guesswork
    my $vendor;
    if ($agent =~ /^DoCoMo/i) {
      return ('Docomo', $agent);
    }
    elsif ($agent =~ /^J\-PHONE/i) {
      return ('Jphone', $agent);
    }
    elsif ($agent =~ /^KDDI\-/i) {
      return ('Ezweb', $agent);
    }
    elsif ($agent =~ /^UP\.Browser/i) {
      return ('Ezweb', $agent);
    }
    elsif ($agent =~ /DDIPOCKET/i) {
      return ('Airh', $agent);
    }
    elsif ($agent =~ /WILLCOM/i) {
      return ('Airh', $agent);
    }
    elsif ($agent =~ /^Vodafone/i) {
      return ('Vodafone', $agent);
    }
    elsif ($agent =~ /^MOT/i) {
      return ('Vodafone', $agent);
    }
    elsif ($agent =~ /^Nokia/i) {
      return ('Vodafone', $agent);
    }
    elsif ($agent =~ /^SoftBank/i) {
      return ('Softbank', $agent);
    }
    elsif ($agent =~ /\(iP(?:hone|[ao]d);/) {
      return ('Smartphone', $agent);
    }
    elsif ($agent =~ /Android/) {
      return ('Smartphone', $agent);
    }
    else {
      return ('Nonmobile', $agent);
    }
  }
}

sub _load_class {
  my $vendor = shift;
  my $class = "Test::MobileAgent::$vendor";
  eval "require $class";
  if ($@) {
    $class = 'Test::MobileAgent::Nonmobile';
    require Test::MobileAgent::Nonmobile;
  }
  return $class;
}

1;

__END__

=head1 NAME

Test::MobileAgent - set environmental variables to mock HTTP::MobileAgent

=head1 SYNOPSIS

    use Test::More;
    use Test::MobileAgent ':all';
    use HTTP::MobileAgent;

    # Case 1: you can simply pass a vendor name in lower case.
    {
      local %ENV;
      test_mobile_agent('docomo');

      my $ua = HTTP::MobileAgent->new;
      ok $ua->is_docomo;
    }

    # Case 2: also with some hint to be more specific.
    {
      local %ENV;
      test_mobile_agent('docomo.N503');

      my $ua = HTTP::MobileAgent->new;
      ok $ua->is_docomo;
    }

    # Case 3: you can pass a full name of an agent.
    {
      local %ENV;
      test_mobile_agent('DoCoMo/3.0/N503');

      my $ua = HTTP::MobileAgent->new;
      ok $ua->is_docomo;
    }

    # Case 4: you can also pass extra headers.
    {
      local %ENV;
      test_mobile_agent('DoCoMo/3.0/N503',
        x_dcmguid => 'STFUWSC',
      );

      my $ua = HTTP::MobileAgent->new;
      ok $ua->is_docomo;
      ok $ua->user_id;   # STFUWSC
    }

    # Case 5: you need an HTTP::Headers compatible object?
    my $headers = test_mobile_agent_headers('docomo.N503');
    my $ua = HTTP::MobileAgent->new($headers);

    # Case 6: or just a hash of environmental variables?
    my %env = test_mobile_agent_env('docomo.N503');
    my $req = Plack::Request->new({ %plack_env, %env });


    # Smartphone support (see HTTP::MobileAgent::Plugin::SmartPhone)

    use HTTP::MobileAgent::Plugin::SmartPhone;
    {
      local %ENV;
      test_mobile_agent('smartphone');

      my $ua = HTTP::MobileAgent->new;
      ok $ua->is_smartphone;
    }
    {
      local %ENV;
      test_mobile_agent('iphone'); # or ipod/ipad/android

      my $ua = HTTP::MobileAgent->new;
      ok $ua->is_smartphone;
      ok $ua->is_iphone;
    }

=head1 DESCRIPTION

This module helps to test applications that use L<HTTP::MobileAgent>. See the SYNOPSIS for usage.

=head1 METHODS

=head2 test_mobile_agent

takes an agent name and an optional hash, and sets appropriate environmental variables like HTTP_USER_AGENT. This function is exported by default.

Agent name should be 'docomo', 'ezweb', 'softbank', 'airh', "docomo.$model", "ezweb.$model", "softbank.$model", 'airh.$model' and just user agent string. As of 0.06, you can also specify 'smartphone', 'iphone', 'ipod', 'ipad', and 'android' for L<HTTP::MobileAgent::Plugin::SmartPhone>.

If the optional hash has C<_user_id>, C<_serial_number>, or C<_card_id> as its keys, this function tries to set corresponding L<HTTP::MobileAgent> attributes if applicable.

=head2 test_mobile_agent_env

takes the same arguments as C<test_mobile_agent()> and returns a hash that can be used to update %ENV.

=head2 test_mobile_agent_headers

takes the same arguments as C<test_mobile_agent()> and returns a L<HTTP::Headers> compatible object.

=head2 test_mobile_agent_list

takes a carrier name, and returns a list of known agent names.

=head1 TO DO

This can be a bit more powerful if you can pass something like an asset file of L<Moxy> to configure.

=head1 SEE ALSO

L<HTTP::MobileAgent>, L<HTTP::MobileAgent::Plugin::SmartPhone>, L<Moxy>

=head1 REPOSITORY

I am not a heavy user of mobile phones nor HTTP::MobileAgent. Patches are always welcome :)

L<http://github.com/charsbar/test-mobileagent>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
