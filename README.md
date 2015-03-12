# elb-dash

A self-updating ELB status board / dashboard built with React, Coffeescript and Node.js.

![](https://raw.github.com/jondot/elb-dash/master/elb-dash.png)

# Quickstart

Take a look at `config.js` and mind the defaults.

Prepare a standard node.js environment, and Run these on a terminal:

```
$ npm install
$ ./dash.sh
$ AWS_REGION=your-region AWS_ACCESS_KEY=your-key AWS_SECRET_KEY=your-secret ./server.sh
```

You should have a local AWS proxy on port `8080` and your dashboard
ready at [http://localhost:3000](http://localhost:3000). Enjoy!


## How it works

This project is divided to a self updating web client, and a proxy
backend.


### Web client

The web client is built with a rapid-development stack using
`watchify`, `browserify` and `babel`.

Running `./dash.sh` will start a development server that watches and
refreshes your browser as you work.

In any case the built files are in `/dist` so you can run production
with these assets.

You can configure the backend url with `proxy_url` in the
`config.js` file.

Configuration

* `proxy_url` - if you ever changed the port or address, change this.
* `whitelist` - an array of names of ELBs, if you want to cherry-pick
  what you want displayed. Leave an empty array if you want everything.
* `refresh_interval_sec` - interval in seconds for updating the dash.

### Backend

We realize that in real-life, due to security concerns, companies don't really like calling AWS API
directly, or don't like going through 3rd party for that.

This is why you get a smart AWS proxy that you can run within your own
cloud or server farm, and everything stays secure.

The web client will connect to this proxy to get its own federated data.

Configuration:

* `PORT` - bind to a port. Environment variable.
* `AWS_ACCESS_KEY` - your AWS access key. Environment variable.
* `AWS_SECRET_KEY` - your AWS secret key. Environment variable.
* `REGION` - your AWS ELB region.
* `config.js:refresh_interval_sec` - number of seconds to cache data for.
* `config.js:aggregate_over_min` - aggregate over X minutes of data.
* `config.js:aggregate_hours_back_hour` - hold a window of X hours for
  the time series.





# Contributing

Fork, implement, add tests, pull request, get my everlasting thanks and a respectable place here :).


# Copyright

Copyright (c) 2015 [Dotan Nahum](http://gplus.to/dotan) [@jondot](http://twitter.com/jondot). See MIT-LICENSE for further details.


