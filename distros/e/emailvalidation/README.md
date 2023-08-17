<p align="center">
<img src="https://app.emailvalidation.io/img/logo/emailvalidation.png" width="300"/>
</p>

# emailvalidation-perl - Email Validation & Verification API

This package is the official Perl wrapper for [emailvalidation.io](https://emailvalidation.io) that aims to make the usage of the API as easy as possible in your project and enables you to verify & validate any email address.

## Getting started

Developer experience matters to us! For this reason, we allow you to make 100 free requests per month, with our free plan. 
You can register your free plan, here: [emailvalidation.io/register](https://app.emailvalidation.io/register). Alternatively, you can
see our paid premium plans here: [emailvalidation.io/pricing](https://emailvalidation.io/pricing)

You can install the package `Emailvalidation` via `cpanm`:

```bash
$ cpanm Emailvalidation
```

Next, you can add the following line to your application code: 

```perl
use Emailvalidation;
```

If you'd like to install from source (not necessary for use in your application), download the source and run the following commands

```bash
perl Build.pl
perl Build
perl Build test
perl Build install
```

## Example

The following example is also included in this folder, named `example.pl`:

```perl
use Emailvalidation;

my $api = Emailvalidation->new(apikey => 'YOUR-APIKEY');
my $data = $api->info('john@doe.com');
print $data;
```

Learn more about endpoints, parameters and response data structure in the [docs](https://emailvalidation.io/docs).

[docs]: https://emailvalidation.io/docs
[emailvalidation.com]: https://emailvalidation.io

## License

The MIT License (MIT). Please see [License File](LICENSE.md) for more information.
