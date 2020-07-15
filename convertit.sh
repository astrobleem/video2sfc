#!/bin/bash
#purpose: #converts a video source file to msu format
if [ -z "$1" ]; then
echo avi2sfc 0.1
echo 
echo "Usage: $0 infile.avi "
echo "Purpose: converts a video file to the msu format"
exit 1
fi

#does the file exist?
let fps=0
if [ -f "$1" ]; then
    echo "$1 exists."
echo "determine frames per second"
fps=$(ffmpeg -i $1 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p")
echo $fps
#read -rsn1 -p"Press any key to continue";echo

else
echo "Are you trying to pull a fast one? That file did not exist!"
exit 1
fi

rm outputaudio.msu
rm outputvideo.msu


echo "creating working directory:"
mkdir img_seq
cp msu1conv img_seq/

echo "video to wav!"
rm ffout.wav
ffmpeg -i $1 -ac 2 -ar 44100 ffout.wav
sox --norm ffout.wav soxout.wav
echo "wav to msu!"
./audio2msu -o outputaudio.msu soxout.wav

#convert to single images
ffmpeg -i $1 -s 224x144 -f image2 -c:v targa %08d.tga
echo "dither $f"
ls -1 img_seq/ | wc -l
let i=0
mv *.tga img_seq 
cd img_seq
parallel --progress -j 20 mogrify -dither -type Palette  ::: *.tga
#parallel --progress -j 20 mogrify-im6 -dither FloydSteinberg -type Palette -limit thread 2020 ::: *.tga
#mogrify-im6 -path img_seq/ -dither FloydSteinberg -limit thread 24 -type Palette

# for f in img_seq/*.tga; do
#let i=i+1
#convert-im6 $f -dither FloydSteinberg -limit thread 24 -type Palette img_seq/img_seq_c_red/$f 
#printf "\b."
#printf "!"
#if [ $i = 10 ]; then
#printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
#let i=0
#fi


echo "creating msu-video"
./msu1conv

#change headers 0x02 - 0x04
#
#29.97fps -> 02 02 01 (2:2 pulldown)
#23.976fps -> 02 03 01 (3:2 pulldown)
#14.985fps -> 04 04 01
#11.988fps -> 04 06 01

echo "fps is $fps -- modifying header"

if [ "$fps" = "29" ]; then
(head --bytes=2 out.msu ; printf '\x02\x02\x01'; tail --bytes=+4 out.msu)> $1-comb.msu
fi

if [ "$fps" == "24" ]; then
(head --bytes=2 out.msu ; printf '\x02\x03\x01'; tail --bytes=+4 out.msu)> $1-comb.msu
echo "(head --bytes=2 $1.msu ; printf '\x02\x03\x01'; tail --bytes=+4 $1.msu)> $1-comb.msu"
fi

if [ "$fps" = "15" ]; then
(head --bytes=2 out.msu ; printf '\x04\x04\x01'; tail --bytes=+4 out.msu)> $1-comb.msu
fi

if [ "$fps" = "12" ]; then
(head --bytes=2 out.msu ; printf '\x04\x06\x01'; tail --bytes=+4 out.msu)> $1-comb.msu
fi


mv $1-comb.msu ../outputvideo.msu

echo "cleanup working directory:"
cd ..
rm ffout.wav
rm soxout.wav
rm out-mp.wav

rm -rf img_seq
rm -rf img_seq_c_red
mv outputaudio.msu  $1-0.pcm
mv outputvideo.msu $1.msu
cp cart.sfc $1.sfc

zip -g $1.zip $1-0.pcm
zip -g $1.zip $1.msu
zip -g $1.zip $1.sfc
outfilename=${1%.avi}
mv $1.zip $outfilename.zip

rm $1-0.pcm
rm $1.msu
rm $1.sfc
