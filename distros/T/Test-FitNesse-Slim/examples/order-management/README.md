# Order management acceptance example

This suite shows a small business-readable FitNesse interface over a pure Perl
order-management application. The domain modules and fixture adapters are
packaged with this example, but the runner extracts them as an external
application and runs them with an independently installed `Test::FitNesse::Slim`.

Run the pinned FitNesse v20251025 suite from the repository root:

```sh
bin/test-example-order-management
```

The command builds and installs the distribution in a temporary prefix,
extracts the example application outside the checkout's Perl library paths,
starts an isolated FitNesse instance, and runs the example suite through the
installed Perl child over SLiM v0.5 pipes. Set `FITNESSE_JAR` to select another
local JAR; the tested default is `/opt/fitnesse/fitnesse.jar`. Use
`--transport tcp` to exercise the installed loopback TCP listener instead.

See [business rules](BUSINESS-RULES.md), [test-author guide](TEST-AUTHORS.md),
[developer guide](DEVELOPERS.md), and the
[adversarial usability audit](USABILITY-AUDIT.md).

The suite contains nine test pages and 82 passing assertions. It demonstrates
decision tables, script tables, unordered and ordered query tables, reusable
scenarios, generated symbols, positive business outcomes, and explicit
rejection messages. Its data is reset in each fixture instance; pages do not
depend on execution order.
