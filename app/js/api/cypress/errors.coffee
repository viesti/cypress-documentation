do (Cypress, _) ->

  Cypress.extend
    cypressErr: (err) ->
      err = new Error(err)
      err.name = "CypressError"
      err

    throwErr: (err, onFail) ->
      if _.isString(err)
        err = @cypressErr(err)

      ## assume onFail is a command if
      ## onFail is present and isnt a function
      if onFail and not _.isFunction(onFail)
        command = onFail

        ## redefine onFail and automatically
        ## hook this into our command
        onFail = (err) ->
          command.error(err)

      err.onFail = onFail if onFail

      throw err

    ## submit a generic command error
    commandErr: (err) ->
      current = @prop("current")

      Cypress.command
        end: true
        snapshot: true
        error: err
        onConsole: ->
          obj = {}
          ## if type isnt parent then we know its dual or child
          ## and we can add Applied To if there is a prev command
          ## and it is a parent
          if current.type isnt "parent" and prev = current.prev
            obj["Applied To"] = prev.subject
            obj

    fail: (err) ->
      current = @prop("current")
      @log {name: "Failed: #{current.name}", args: err.message}, "danger" if current

      ## allow for our own custom onFail function
      if err.onFail
        err.onFail.call(@, err)

        ## clean up this onFail callback
        ## after its been called
        delete err.onFail
      else
        @commandErr(err)

      Cypress.trigger "fail", err
      @trigger "fail", err