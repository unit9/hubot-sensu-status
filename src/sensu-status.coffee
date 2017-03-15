# Description
#   A hubot script that does the things
#
# Configuration:
#   HUBOT_SENSU_USER
#   HUBOT_SENSU_PASSWORD
#
# Commands:
#   hubot hello - <what the respond trigger does>
#   orly - <what the hear trigger does>
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Krzysztof Skoracki <krzysztof.skoracki@unit9.com>

iconForStatus = (status) ->
  if status == 0
    return ":green_heart:"
  if status == 1
    return ":yellow_heart:"
  else if status == 2
    return ":heart:"
  else
    return ":grey_heart:"

module.exports = (robot) ->
  robot.respond /sensu status/, (res) ->
    auth = "#{process.env.HUBOT_SENSU_USER}:#{process.env.HUBOT_SENSU_PASSWORD}"

    robot.http("https://sensu-api.unit9.net/events", {auth: auth})
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

        res.send("Sensu status: #{statusIcon}\n" + response)
