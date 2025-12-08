local audio = {}

audio.fx = {}
audio.music = {}

local playing_fx = {}

function audio.init()
	sound.play('/music#music', { gain = 0.3 })
end

function audio.play_fx(fx, gain)
	gain = gain and gain or 1
	sound.play(audio.fx[fx], { gain = gain })
	table.insert(playing_fx, fx)
end

function audio.stop_fx(fx)
	sound.stop(audio.fx[fx])
end

function audio.stop_all_fx()
	for _, fx in pairs(playing_fx) do
		audio.stop_fx(fx)
	end
end

return audio
