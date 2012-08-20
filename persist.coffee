fs = require('fs')
{ Server, Db } = require "mongodb"
server = new Server "localhost", 27017, {auto_reconnect:true}
db = new Db "jugements", server

fileText = fileText = fs.readFileSync('jugements.txt').toString()

jugements = JSON.parse fileText
db.open (err, db) ->
    if err then throw err
    db.collection "original", {safe:true}, (err, collection) ->
        if err then throw err
        collection.insert jugements, {safe:true}, (err, result) ->
            if err then throw err
            db.close()
