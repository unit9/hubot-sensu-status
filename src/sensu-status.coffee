# Description
#   A hubot script that does the things
#
# Configuration:
#   HUBOT_SENSU_USER
#   HUBOT_SENSU_PASSWORD
#   HUBOT_SENSU_API_URL
#
# Commands:
#   hubot sensu status - display the current events on Sensu
#   hubot sensu info - show Sensu settings
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Krzysztof Skoracki <krzysztof.skoracki@unit9.com>

cronJob = require('cron').CronJob

module.exports = (robot) ->
  auth = "#{process.env.HUBOT_SENSU_USER}:#{process.env.HUBOT_SENSU_PASSWORD}"

  getSensuStatus = (callback) ->
    robot.http("#{process.env.HUBOT_SENSU_API_URL}/events", {auth: auth})
      .get() (err, r, body) ->
        data = JSON.parse body
        response = ''
        warning = 0
        error = 0
        unknown = 0
        for event in data
          icon = iconForStatus event.check.status
          response += "#{icon} #{event.check.notification} on `#{event.client.name}`\n"
          if event.check.status == 1
            warning++
          else if event.check.status == 2
            error++
          else
            unknown++

        if error
          status = 2
        else if warning
          status = 1
        else if unknown
          status = 3
        else
          status = 0

        statusIcon = iconForStatus status

        callback("Sensu status: #{statusIcon}\n" + response)

  postSensuStatus = ->
    getSensuStatus (status) ->
        robot.messageRoom '#sysop', status

  iconForStatus = (status) ->
    if status == 0
      return ":green_heart:"
    if status == 1
      return ":yellow_heart:"
    else if status == 2
      return ":heart:"
    else
      return ":grey_heart:"

  robot.respond /sensu status/, (res) ->

    getSensuStatus (status) ->
      res.send status

  robot.respond /sensu info/, (res) ->
    robot.http("#{process.env.HUBOT_SENSU_API_URL}/info", {auth: auth})
      .get() (err, r, body) ->
        data = JSON.parse body
        res.send("API URL: #{process.env.HUBOT_SENSU_API_URL}\n" +
                 "Sensu version: #{data.sensu.version}")

  new cronJob('0 0 10 * * 1-5', postSensuStatus, null, true, "Europe/Warsaw")
