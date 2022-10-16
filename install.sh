apt update
apt install wget git -y
wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list && wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | apt-key add -
apt update
apt install box64 -y
echo "installing libs"
apt install libsdl1.2debian libgtk2.0-0 libsdl-image1.2 libglu1-mesa libsdl-ttf2.0-0 libopenal-dev libsndfile1-dev libncursesw5
clear
echo "done, now you should be able to play"
echo "there are two variations with and without dfhack"
