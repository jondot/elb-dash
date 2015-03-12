React = require('react')
Sparkline = require 'react-sparkline'
Baobab = require 'baobab'
EventEmitter = require 'wolfy87-eventemitter'
Style = require 'css-layout'
config = require './config'
request = require 'superagent'
_ = require 'lodash'
ee = new EventEmitter()

tree =  {
          elbs: [
            {
                name: 'elb1'
                hosts: [{ status: 'good'}, { status: 'bad' } ]
                metrics:
                  latency_avg: [ 1, 2, 0 ]
                  req_2xx_persec: []
                  req_err_persec: []
              },
              {
                name: 'elb2'
                hosts: [{ status: 'good'}, { status: 'bad' } ]
                metrics:
                  latency_avg: [ 1, 2, 1 ]
                  req_2xx_persec: []
                  req_err_persec: []
              },
              {
                name: 'elb3'
                hosts: [{ status: 'good'}, { status: 'bad' } ]
                metrics:
                  latency_avg: [ 1, 0, 0 ]
                  req_2xx_persec: []
                  req_err_persec: []
              }
            ]
         }


request.get config.proxy_url, (res)=>
  tree.elbs = _.filter( _.map(res.body, (el)=> { name: el.name, hosts:[], metrics:{}}),
                        (elb)=> config.whitelist.length == 0 || _.contains(config.whitelist, elb.name) )
  React.render(<Dash elbs={tree.elbs}/>, document.getElementById("content"))

  tree.elbs.map (elb) =>
    refresh_data = ()->
      request.get "#{config.proxy_url}/#{elb.name}/metrics", (res)=>
        elb['metrics'] = res.body
        ee.emitEvent('metrics', [{ key: elb.name, content: elb }] )

        request.get "#{config.proxy_url}/#{elb.name}/hosts", (res)=>
          elb['hosts'] = res.body
          ee.emitEvent('hosts', [{ key: elb.name, content: elb }] )

    refresh_data()
    setInterval refresh_data,config.refresh_interval_sec*1000


Dash = React.createClass
  render: ->
    <div>
    {@props.elbs.map((elb)-> <ElbTile elb={elb} />)}
    </div>

ElbTile = React.createClass
  values: (arr)->
    _.map arr, (p)-> p[1]

  getInitialState: ->
    @props.elb

  formatMs: (n)->
    d3.round(n*100,0)

  formatReq: (n)->
    d3.round(n,0)

  updateMetrics: (msg)->
    console.log('update (metrics)', msg)
    if msg.key == @props.elb.name
      @setState(msg.content)

  updateHosts: (msg)->
    console.log('update (hosts)', msg)
    if msg.key == @props.elb.name
      @setState(msg.content)

  componentDidMount: ->
    ee.addListener 'metrics', @updateMetrics
    ee.addListener 'hosts', @updateHosts
    console.log("mounted", @props.elb)

  componentWillUnmount: ->
    ee.removeListener 'metrics', @updateHandler
    ee.removeListener 'hosts', @updateHandler

  render: ->
    <div className="elb-tile">
      <div className="name">{@state.name}</div>
      <div className="metrics">
        <div class="requests">
          <span className="metrics-numeric-label">{@formatReq _.last(@values(@state.metrics.req_2xx_persec))}</span>
          req/s
          <Sparkline strokeColor="rgba(255,255,255,0.7)" strokeWidth="2px" width=140 key={@state.name+"req_2xx"} data={@values(@state.metrics.req_2xx_persec)} />
        </div>
        <div class="latency">
          <span className="metrics-numeric-label">{@formatMs _.last(@values(@state.metrics.latency_avg))}</span>
          ms
          <Sparkline strokeColor="rgba(255,255,255,0.7)" strokeWidth="2px" width=140 key={@state.name+"latency"} data={@values(@state.metrics.latency_avg)} />
        </div>
        <div className="metrics-graph">
          <Sparkline strokeColor="red" strokeWidth="2px" width=140 key={@state.name+"req_err"} data={@values(@state.metrics.req_err_persec)} />
        </div>
      </div>
      <div className="hosts">
        {_.map(_.keys(@state.hosts), (host_key)=> <div className={ 'host host-'+@state.hosts[host_key].status}></div>)}
      </div>
    </div>



