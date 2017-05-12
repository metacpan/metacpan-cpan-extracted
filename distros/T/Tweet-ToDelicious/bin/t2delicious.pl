#!perl
use v5.14;
use warnings;
use Config::Any;
use File::Spec::Functions qw(catfile);
use File::Basename qw(dirname);
use Tweet::ToDelicious;

my $filename = 'config.yaml';
my $cfg      = Config::Any->load_files(
    {   files   => [ catfile( dirname(__FILE__) ), $filename ],
        use_ext => 1
    }
);

Tweet::ToDelicious->new( $cfg->[0]->{$filename} )->run;

__END__

=head1 NAME

t2delicious.pl - Links in your tweet to delicious.

=head1 SYNOPSIS

  carton exec -- perl ./bin/t2delicious.pl

=head1 CONFIG

Copy config.yaml.sample to config.yaml. And write your config.

=head2 config.yaml.sample

    twitter:
      consumer_key: your_consumer_key
      consumer_secret: your_consumer_secret
      token: your_token
      token_secret: your_token_secret
    delicious:
      user: your_delicious_username
      pswd: your_password
      debug: 0
    t2delicious:
      twitter_screen_name: your_twitter_name

=head1 DESCRIPTION

t2delicious.pl post your links in tweet and your favorite with tags.
You should run this script using daemontools or supervisord or something else.

=head1 AUTHOR

Yoshihiro Sasaki, E<lt>ysasaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Yoshihiro Sasaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
