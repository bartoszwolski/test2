key="$1"
echo $key

rand=$((1 + RANDOM % 50000))

if [ "$key" == "-i" ]
then
touch $rand.app
fi

if [ "$key" == "-g" ]
then
touch $rand.apk
fi

if [ "$key" == "-ig" ]
then
touch $rand.app
touch $rand.apk
fi

if [ "$key" == "-gi" ]
then
touch $rand.app
touch $rand.apk
fi