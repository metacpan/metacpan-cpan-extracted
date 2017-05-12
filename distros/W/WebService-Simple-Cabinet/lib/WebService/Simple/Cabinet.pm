package WebService::Simple::Cabinet;

use strict;
use warnings;
our $VERSION = '0.01';

use Carp;
use UNIVERSAL::require;

sub new {
    my($class, $config, %args) = @_;

    croak "usage: ${class}->new(\$config[, args...])" unless $config;
    unless (ref $config eq 'HASH') {
        # XXX ただの文字列だったら、どっかからYAMLかDSL定義を読み込んでconfigデータを作る
    }

    $config->{global} ||= { params => {} };
    $config->{method} ||= [];

    croak 'package is required.' unless $config->{global}->{package};
    my $api_pkg  = sprintf '%s::Api::%s',$class, $config->{global}->{package};
    my $base_pkg = "$class\::Api";
    $base_pkg->require or die $@;

    no strict 'refs';
    unless (@{"$api_pkg\::ISA"}) {
        push @{"$api_pkg\::ISA"}, "$class\::Api";
        use strict;

        for my $data (@{ $config->{method} }) {
            my %default_params = ();
            my @input_args     = ();
            for my $param (keys %{ $data->{params} }) {
                if (my $value = $data->{params}->{$param}) {
                    $default_params{$param} = $value;
                } else {
                    push @input_args, $param;
                }
            }

            my $method = $data->{name};
            no strict 'refs';
            *{"$api_pkg\::$method"} = sub {
                use strict;
                my($self, %args) = @_;
                my $params = { %default_params };
                for my $key (@input_args) {
                    $params->{$key} = $args{$key};
                }
                $self->{response} = $self->{api}->get($params, $data->{options});
                $self->{response}->parse_xml($data->{parse_xml_opts});
            };
        }
    }
    use strict;

    my $params = {};
    for my $key (keys %{ $config->{global}->{params} }) {
        $params->{$key} = $args{$key} || $config->{global}->{params}->{$key};
    }

    my $simple_opts = {
        base_url => $config->{global}->{base_url},
        param    => $params,
    };
    $simple_opts->{cache} = $args{cache} if exists $args{cache};
    $api_pkg->new(
        config      => $config,
        simple_opts => $simple_opts,
    );
}


1;
__END__

=encoding utf8

=head1 NAME

WebService::Simple::Cabinet - WSDL/WADL-like interface make for WebService::Simple.

=head1 SYNOPSIS

  use WebService::Simple::Cabinet;
  my $flickr = WebService::Simple::Cabinet->new(
      {
          global => {
              name     => 'flickr',
              package  => 'Flickr',
              base_url => 'http://api.flickr.com/services/rest/',
              params   => {
                  api_key => undef,
              },
          },
          method => [
              {
                  name   => 'echo',
                  params => {
                      method => 'flickr.test.echo',
                      name   => undef,
                  },
                  options => {},
              },
          ],
      },
      api_key => 'your_api_key',
  );
  my $res_xml = $flickr->echo( name => 'echo data' );
  print $res_xml->{name};


unmaking syntax (TODO)

  use WebService::Simple::Cabinet;
  my $flickr = WebService::Simple::Cabinet->new(
      'flickr',
      api_key => 'your_api_key',
  );
  my $res_xml = $flickr->echo( name => 'echo data' );
  print $res_xml->{name};

=head1 DESCRIPTION

WebService::Simple::Cabinet is make to easily Perl API interface some web services.

=head1 TODO

It is possible to use it easily by preparing the definition corresponding to some Web Service. 

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>
mattn

=head1 SEE ALSO

L<WebService::Simple>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/WebService-Simple-Cabinet/trunk WebService-Simple-Cabinet

WebService::Simple::Cabinet is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
