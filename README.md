# cs_switch

cs_switch helps you generating SQL queries required to change the domain of CloudStack compute offerings.

## Dependencies

  * Ruby
  * bundler gem

## Getting started

Make sure you have a working [cloudstack-cli](https://github.com/niwo/cloudstack-cli) configuration file in your home directory.

Usually this is found under `~/.cloudstack-cli.yml`

Install gem dependencies:

```sh
$ bundle install
```

Run the CLI to generate SQL update statements (example):

```sh
$ bin/cs_switch sql --source-domain Testdomain --limit 1cpu_1gb
```
