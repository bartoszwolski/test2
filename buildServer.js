var PORT = 13371;
var HOST = '127.0.0.1';

var dgram = require('dgram');
var simpleGit = require('simple-git');
var server = dgram.createSocket('udp4');
var buildInProgress = false;

server.on('listening', function () {
    var address = server.address();
    console.log('UDP Server listening on ' + address.address + ":" + address.port);
});

function sendResponseToClien(port, address, message) {
    var response = new Buffer(message);
    server.send(response, 0, response.length, port, address, function (err, bytes) {
        if (err) {
            throw err;
        }
    })
}

function checkGit(branch) {
    buildInProgress = true;
    console.log("Check git started on branch " + branch);
    simpleGit().fetch();
    // simpleGit().checkoutBranch(branch);
}

server.on('message', function (message, remote) {

    console.log(remote.address + ':' + remote.port + ' - ' + message);

    var dataTab = JSON.parse(message);
    // console.table(dataTab);
    var command = dataTab["command"];
    var branch = dataTab["branch"];

    if (typeof branch == 'undefined') {
        branch = "master";
    }
    var target = dataTab["target"];

    if (buildInProgress) {
        // blocks the possiblity of server having multiple build requests
        sendResponseToClien(remote.port, remote.address, "Server is busy building for someone else sorry :(");
        return
    }

    checkGit(branch);

    if (command == "build") {
    }
    else {
    }
    //
    // JSON.stringify(new_tweets); -- encode the table into the json

    // sendResponseToClien(remote.port, remote.address, message);
});


server.bind(PORT, HOST);