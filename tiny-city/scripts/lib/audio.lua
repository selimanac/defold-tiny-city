local audio = {}

audio.fx = {}
audio.music = {}

function audio.init()
	sound.play('/music#music', { gain = 0.3 })
end

function audio.play_fx(fx, gain)
	gain = gain and gain or 1
	sound.play(audio.fx[fx], { gain = gain })
end

function audio.stop_fx(fx)
	sound.stop(audio.fx[fx])
end

return audio
