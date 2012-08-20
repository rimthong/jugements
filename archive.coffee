fs = require('fs')
{ Server, Db } = require "mongodb"
server = new Server "localhost", 27017, {auto_reconnect:true}
db = new Db "jugements", server

links = []
jugements = []
years = [2010]
months = [1..2]
baseurl = "http://jugements.qc.ca/"
tribunal = 16
searchurl ="#{baseurl}index.php?type=listec&recher=#{tribunal}"
searchurls = []
documents = []

leftpad = (value)->
  if value < 10
    return "0#{value}"
  else
    value

genurl = (year, month) ->
  url : "#{searchurl}_#{year}#{leftpad month}_date"
  year : year
  month : month

genurls = (year)->
  genurl(year, month) for month in months

searchurls = searchurls.concat( [].concat.apply([], genurls(year) for year in years))

getDecisionLinks = ->
  #Scrape all links, keep those with decision.php
  links = document.querySelectorAll "a"
  linktext = (link.getAttribute("href") for link in links when /decision\.php/.test(link.getAttribute("href")))
  linktext

grabData = ->
  title = document.getElementById("decision_ti").innerHTML
  title

casperOpen = (link, month, year) ->
  casper.thenOpen link, ->
    @echo "Parsing second level #{link}\n"
    doc = @evaluate grabData
    jugement = {}
    jugement.tribunal = ""
    jugement.integral = doc
    jugement.url = link
    jugement.month = month
    jugement.year = year
    jugements.push jugement
    @echo "inserted jugement: date #{jugement.year} - #{jugement.month}"

casperParse = (link)->
  casper.thenOpen link.url, ->
    @echo "Parsing first level #{link.url} #{link.year} #{link.month}\n"
    links = @evaluate getDecisionLinks
    casperOpen("http://jugements.qc.ca#{url}", link.month, link.year) for url in links

casper = require('casper').create()

casper.start "http://jugements.qc.ca", ->
  @echo "Begin Parsing"
  #Parse all urls for dates
  casperParse url for url in searchurls

casper.run ->
  #Need to write out jugements
  fs.write("jugements.txt", JSON.stringify(jugements), 'w')
  @echo("\nexecution terminated\n").exit()
