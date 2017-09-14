# WebService-Jandi-WebHook #

Perl interface to Jandi Service Incoming Webhook

``` perl
my $jandi = WebService::Jandi::WebHook->new('https://wh.jandi.com/connect-api/webhook/md5sum');
my $res   = $jandi->request('Hello, world');
```
