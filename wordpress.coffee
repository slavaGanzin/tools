#!/usr/bin/env coffee
R = require 'ramda'
wrench = require 'wrench'
fs = require 'fs'
async = require 'async'
path = require 'path'
request = require 'request'
mkdirp = require 'mkdirp'
exec = require('child_process').exec


domain = process.argv[2] || R.last process.cwd() .split '/'
prefixes = (process.argv[3..] if process.argv[3..].length) ||
 ['wp-content','wp-includes', 'static']

onlyHtmlAndCss = R.filter (e) -> /htm|css/.test e
onlyCss = R.filter (e) -> /css/.test e
filterCache = R.filter (e) -> e && ! /wp-content\/cache/.test e
prependWithDomain = R.map (e) -> 'http://' + domain + '/' + e.replace /(^https?:\/\/.*?\/|^\/)/, ''
replaceBackslashes = R.map (e) -> e.replace /\\/g, ''
cutQuotes = R.map (e) -> e.replace(/^['"]/, '').replace /['"]$/, ''
processCssUrls = (dir) -> R.map ((e) -> dir+'/'+e.replace /.*\(['"]?(.*?)['"]?\).*/, '$1')

processFile = (f, done) ->
  notQuote = '[^"\']*'
  quote = '["\']'
  content = fs.readFileSync './'+f, 'utf8'
  htmlLinks = (for prefix in prefixes
    links = quote + notQuote + prefix + notQuote + quote
    content.match RegExp( links, 'gim'))
  cssUrlLinks = processCssUrls(path.dirname f) (content.match /url\(.*?\)/gim) || []
  console.log cssUrlLinks
  done null, R.concat cssUrlLinks, htmlLinks

async.map (onlyCss wrench.readdirSyncRecursive '.'), processFile, (e, r) ->
  files = prependWithDomain replaceBackslashes cutQuotes filterCache R.uniq R.flatten r
  download = (url, c) ->
    filename = url.replace(/.*\/\/[^/]+\/(.*)/, '$1').replace(/\?.*$/, '').replace(/^\//,'')
    fs.stat filename, (e, stats) ->
      mkdirp.sync path.dirname filename
      console.log "wget -O #{filename} #{url}"
      exec "wget -O #{filename} #{url}", (e, stdout, stderr) ->
        console.log stdout, stderr
        c null, [url, filename]

  async.map files, download, console.log
