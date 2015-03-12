express = require('express')
async = require('async')
_ = require('lodash')

awssdk = require('aws-sdk')
memoize = require('memoizee')

config = require('./config')


AGG_PERIOD = config.aggregate_over_min*60
HOURS_BACK = config.aggregate_hours_back_hour
MAX_AGE = config.refresh_interval_sec*1000 # 30sec
ACCESS_KEY = process.env['AWS_ACCESS_KEY']
SECRET_KEY = process.env['AWS_SECRET_KEY']
REGION = process.env['AWS_REGION']

elb = new awssdk.ELB(accessKeyId: ACCESS_KEY, secretAccessKey: SECRET_KEY, region: REGION)
cw = new awssdk.CloudWatch(accessKeyId: ACCESS_KEY, secretAccessKey: SECRET_KEY, region: REGION)


app = express()

app.use (req, res, next)->
  res.header("Access-Control-Allow-Origin", "*")
  next()

requireName = (req, res, next)->
  name = req.params.name
  if !name || name == ""
    return res.status(406).end()
  next()

hours_back = (date, num)->
  new Date(date - num*60*60*1000)

elb_timeseries = (cw, elb_name, metric, period, start, end, cb)->
  label = metric[0]
  handle_result = (result)->
    data = {}
    console.log("ELB: #{elb_name} fetched metric: #{metric}")
    data[label] = _.map result.Datapoints, (dp)->
      divisor = 1.0
      if metric[2] == 'Sum'
        divisor = period # normalize to per sec
      [dp['Timestamp']/1000, parseFloat(dp[metric[2]]) / divisor]
    data[label] = _.sortBy data[label], (d)-> d[0]
    data

  cw.getMetricStatistics
                            Namespace: 'AWS/ELB',
                            MetricName: metric[1],
                            Statistics: [metric[2]],
                            Unit: metric[3],
                            Period: period,
                            StartTime: start.toISOString(),
                            EndTime: end.toISOString(),
                            Dimensions: [
                              Name: "LoadBalancerName",
                              Value: elb_name
                            ]
                            ,
                            (err, res)=>
                              if err
                                return cb(err, null)
                              return cb(null, handle_result(res))

memo_elb_timeseries = memoize(elb_timeseries, maxage: MAX_AGE)



app.get '/elbs', (req,res)->
  elb.describeLoadBalancers {}, (err, data)->
    if err
      console.log("error", err)
      return res.status(500).end()

    lbs = _.map data.LoadBalancerDescriptions, (lb)->
      {
        name: lb["LoadBalancerName"]
      }
    res.json(lbs)


app.get '/elbs/:name/hosts', requireName, (req,res)->
  name = req.params.name
  elb.describeInstanceHealth LoadBalancerName: name, (err, data)->
    if err
      console.log("error", err)
      return res.status(500).end()

    console.log("ELB: ##{name} fetched hosts")
    hosts = {}
    _.each data.InstanceStates, (instance)->
      hosts[instance["InstanceId"]] = { status: if(instance.State=="InService") then "up" else "down" }

    res.json(hosts)


app.get '/elbs/:name/metrics', requireName, (req,res)->
  name = req.params.name

  period = AGG_PERIOD
  end = new Date()
  start = hours_back(new Date(), HOURS_BACK)
  iter = (metric, cb)-> memo_elb_timeseries(cw, name, metric, period, start, end, cb)

  async.map [
              ["latency_avg", "Latency", "Average", "Seconds"],
              ["req_2xx_persec", "RequestCount", "Sum", "Count", 0],
              ["req_err_persec", "HTTPCode_ELB_5XX", "Sum", "Count", 0],
            ],
            iter,
            (err, result)->
              if err
                console.log("error", err)
                return res.status(500).end()

              metrics = _.merge {}, result...
              res.json(metrics)

port = 8080 || process.env['PORT']
app.listen port, ()->
  console.log("elb-dash server listening on port #{port}")


