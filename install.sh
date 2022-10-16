apt update
apt install wget git -y
wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list && wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | apt-key add -
apt update
apt install box64 -y
echo "done, now you should be able to play"
echo "there are two variations with and without dfhack"
