class SlackInterfaceRequestHandler
  constructor: (auth, spotify, volume) ->
    @auth = auth
    @spotify = spotify
    @volume = volume
    @plugin_handler = require("../../lib/plugin_handler")()

    @endpoints =
      handle:
        post: (request, response) =>
          request.resume()
          request.once "end", =>
            return if !@auth.validate(request, response)

            reply_data = { ok: true }

            switch @auth.command
              when 'pause' then @spotify.pause()
              when 'stop' then @spotify.stop()
              when 'skip' then @spotify.skip()
              when 'reconnect' then @spotify.connect()
              when 'restart' then process.exit 1
              when 'mute' then @volume.set 0
              when 'unmute' then @volume.set 5
              when 'scrubs' then @spotify.play 'spotify:track:1KGi9sZVMeszgZOWivFpxs'
              when 'spaceman' then @spotify.play 'spotify:track:2Elq6GxVh8v9QFCF3ca2Xc'
              when 'uptownfunk' then @spotify.play 'spotify:track:32OlwWuMpZ6b0aN2RZOeMS'

              when 'play'
                if @auth.args[0]?
                    @spotify.play @auth.args[0]
                else
                    @spotify.play()

              when 'shuffle'
                @spotify.toggle_shuffle()
                reply_data['text'] = if @spotify.shuffle then "Mixin' it up." else "Playin' it straight."

              when 'vol'
                if @auth.args[0]?
                  switch @auth.args[0]
                    when "up" then @volume.up()
                    when "down" then @volume.down()
                    else @volume.set @auth.args[0]
                else
                  reply_data['text'] = "Current Volume: *#{@volume.current_step}*"

              when 'list'
                if @auth.args[0]?
                  switch @auth.args[0]
                    when 'add' then status = @spotify.add_playlist @auth.args[1], @auth.args[2]
                    when 'remove' then status = @spotify.remove_playlist @auth.args[1]
                    when 'rename' then status = @spotify.rename_playlist @auth.args[1], @auth.args[2]
                    else status = @spotify.set_playlist @auth.args[0]
                  if status
                    reply_data['text'] = ['Ok.', 'Sweet.', 'Chur.', 'Done like dinner.', 'Sorted.org.nz (use your mouse!)', 'Coolies.', 'No problem, brah.', 'Affirmative.', 'Gotcha.', 'Aye-aye, captain! :captain:'][Math.floor(Math.random() * 10)]
                  else
                    reply_data['text'] = "Oops, you did it again. Try `help` if you need some."
                else
                  str = 'Currently available playlists:'
                  for key of @spotify.playlists
                    str += "\n*#{key}* (#{@spotify.playlists[key]})"
                  reply_data['text'] = str

              when 'status'
                shuffleword = if @spotify.shuffle then '' else ' not'
                if @spotify.is_paused()
                  reply_data['text'] = "We are *paused* on a song called *#{@spotify.state.track.name}* by *#{@spotify.state.track.artists}*.\nWe are#{shuffleword} shuffling through the playlist *#{@spotify.state.playlist.name}*. Resume playback with `play`."
                else if !@spotify.is_playing()
                  reply_data['text'] = "Playback is currently *stopped*. You can start it again by choosing an available `list`."
                else
                  reply_data['text'] = "This banging tune is *#{@spotify.state.track.name}* by *#{@spotify.state.track.artists}*.\nWe  are#{shuffleword} shuffling through the playlist *#{@spotify.state.playlist.name}*."

              when 'help'
                reply_data['text'] = "You seem lost. Here's a list of commands that are available to you:   \n   \n*Commands*\n> `play [Spotify URI]` - Starts/resumes playback if no URI is provided. If a URI is given, immediately switches to the linked track.\n> `pause` - Pauses playback at the current time.\n> `stop` - Stops playback and resets to the beginning of the current track.\n> `skip` - Skips (or shuffles) to the next track in the playlist.\n> `shuffle` - Toggles shuffle on or off.\n> `vol [up|down|0..10]` Turns the volume either up/down one notch or directly to a step between `0` (mute) and `10` (full blast). Also goes to `11`.\n> `mute` - Same as `vol 0`.\n> `unmute` - Same as `vol 5`.\n> `status` - Shows the currently playing song, playlist and whether you're shuffling or not.\n> `help` - Shows a list of commands with a short explanation.\n   \n*Playlists*\n> `list add <name> <Spotify URI>` - Adds a list that can later be accessed under <name>.\n> `list remove <name>` - Removes the specified list.\n> `list rename <old name> <new name>` - Renames the specified list.\n> `list <name>` - Selects the specified list and starts playback."

              else
                # Fallback to external plugins.
                status = @plugin_handler.handle(@auth, @spotify, @volume)
                if status?
                  reply_data['text'] = status

            response.serveJSON reply_data
            return
          return



module.exports = (auth, spotify, volume) ->
  handler = new SlackInterfaceRequestHandler(auth, spotify, volume)
  return handler.endpoints
