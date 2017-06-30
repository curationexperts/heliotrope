# heliotrope
[![Build Status](https://travis-ci.org/mlibrary/heliotrope.svg?branch=master)](https://travis-ci.org/mlibrary/heliotrope)
[![Coverage Status](https://coveralls.io/repos/github/mlibrary/heliotrope/badge.svg?branch=master)](https://coveralls.io/github/mlibrary/heliotrope?branch=master)
[![Stories in Ready](https://badge.waffle.io/mlibrary/heliotrope.png?label=ready&title=Ready)](https://waffle.io/mlibrary/heliotrope)

Samvera-based digital publishing platform built by the University of Michigan Library

## Development

### Initial setup

  * clone the repository
  * run `bundle install`
  * run `bundle exec bin/setup`
  * Install MySQL [OS X El Capitan](https://gist.github.com/nrollr/a8d156206fa1e53c6cd6)
  * [install redis](https://github.com/mlibrary/heliotrope/wiki/Background-Jobs#how-to-install-redis)
  * [build public](https://github.com/mlibrary/heliotrope/wiki/Static-Pages-and-Blog)

#### Create an admin user

There is a rake task you can use to create a superadmin user.  It will prompt you for an email address and password, and then create a user with the correct role.

`bundle exec rake admin`

If you need to run this when the app has been deployed, run:

`RAILS_ENV=production bundle exec rake admin`

### Run the application

Run this command to start Fedora, Solr and Rails servers:

`rake hydra:server`

Or, if you prefer to start each server individually:
*(you must use this alternate option if running on a VM)*

```
  $ redis-server /usr/local/etc/redis.conf
  $ bundle exec fcrepo_wrapper -p 8984 --no-jms
  $ bundle exec solr_wrapper -p 8983 -d solr/config/ --collection_name hydra-development
  $ bundle exec bin/rails s
```

Note, there are also config files available for running the wrappers (which save you from having to remember ports, collection names etc). Their settings attempt to persist your Solr index as you move between dev and test. Use like so:
```
fcrepo_wrapper --config .wrap_conf/fcrepo_dev
solr_wrapper --config .wrap_conf/solr_dev
```

### Explain Partials

Set the EXPLAIN_PARTIALS environment variable to show partials being rendered in source html of your views
(view this info using your browser's inspect element mode)

```
$ EXPLAIN_PARTIALS=true bundle exec bin/rails s
```

*NOTE:* Because this feature can add a fair bit of overhead, it is restricted
to only run in development mode.

### Testing

Make sure you have seeded your test DB with `RAILS_ENV=test bundle exec rake db:seed`

run `rake ci`

Alternatively, you can start up each server individually.  This may be preferable because `rake ci` starts up and tears down Fedora and Solr before/after the test suite is run.

1. Start up FCrepo

   `fcrepo_wrapper -p 8986 --no-jms` OR `fcrepo_wrapper --config .wrap_conf/fcrepo_test`
1. Start up Solr

   `solr_wrapper -p 8985 -d solr/config/ --collection_name hydra-test` OR `solr_wrapper --config .wrap_conf/solr_test`
1. Run tests

   `rspec`

*NOTE:* As of June 20, 2017 we have a test which requires the static pages to be built in order for the routing to happen correctly (See the Wiki for more details), which means running this:
`bundle exec rake jekyll:build`

### Wiki

For additional details and helpful hints [read the wiki.](https://github.com/mlibrary/heliotrope/wiki)

### Contact

Contact the [Fulcrum Developers List](mailto:fulcrum-dev@umich.edu) with any question about the project.
