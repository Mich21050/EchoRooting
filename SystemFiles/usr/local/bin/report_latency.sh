#!/bin/sh

# This is the tool calculate the latency in the playback chain
#
# For now it only calcuate the TTS path.

samples_per_ms=16


# get the shared memory queue name between the mixer and the audioproxyd
mixer_output_shm=`ps | grep audioproxyd | grep -o  "/Q[^\B]*.shm"`
if [ x$mixer_output_shm==x ]; then
    echo "Error: audioproxyd is not running. PLease run startAudio.sh."
    exit -1
fi

# get the buffered samples and calcuate the latency
msgs_mixer=`shmq_tool -m 5 -S $mixer_output_shm | awk '{print $3}' `
latency_mixer=$(( $msgs_mixer/$samples_per_ms ))

echo "$latency_mixer ms latency/$msgs_mixer samples in the audioproxyd input queue"

# get the shared memory queue name between the alexaspeechplayer and the mixer
tts_output_shm=`ps | grep alexaspeechplayer | grep -o  "Q[^\B]*.shm"`
if [ x$tts_output_shm==x ]; then
    echo "Error: alexaspeechplayer is not running. PLease run startAudio.sh"
    exit -1
fi


# get the buffered samples and calcuate the latency
msgs_tts=`shmq_tool -m 5 -S $tts_output_shm | awk '{print $3}' `
latency_tts=$(( $msgs_tts/$samples_per_ms ))

echo "$latency_tts ms latency/$msgs_tts samples in the alexaspeechplayer output queue"

# get the latency within the audioproxy
latency_in_audioproxy=`lipc-get-prop -s com.doppler.audio latency | awk ' {print $5}'`

echo "$latency_in_audioproxy ms latency within the audioproxyd"

#
total_latentcy=$(( $latency_in_audioproxy+$latency_mixer+$latency_tts ))

echo
echo "==Total latency for TTS $total_latentcy ms=="
