#!/usr/bin/env coffee
R = require 'ramda'
wrench = require 'wrench'
fs = require 'fs'
async = require 'async'
path = require 'path'
request = require 'request'
mkdirp = require 'mkdirp'


domain = process.argv[2] || R.last process.cwd() .split '/'
prefixes = (process.argv[3..] if process.argv[3..].length) ||
 ['wp-content','wp-includes', 'static']

onlyHtml = R.filter (e) -> /htm/.test e
filterCache = R.filter (e) -> e && ! /wp-content\/cache/.test e
prependWithDomain = R.map (e) -> if /^\//.test e then 'http://'+domain+e else e
replaceBackslashes = R.map (e) -> e.replace /\\/g, ''
cutQuotes = R.map (e) -> e.replace(/^['"]/, '').replace /['"]$/, ''

processFile = (f, done) ->
  notQuote = '[^"\']*'
  quote = '["\']'
  content = fs.readFileSync './'+f, 'utf8'
  done null, (for prefix in prefixes
    links = quote + notQuote + prefix + notQuote + quote
    content.match RegExp( links, 'gim'))

async.map (onlyHtml wrench.readdirSyncRecursive '.'), processFile, (e, r) ->
  files = replaceBackslashes prependWithDomain cutQuotes filterCache R.uniq R.flatten r
  console.log files
  return
  download = (url, c) ->
    filename = url.replace /.*\/\/[^/]+\/(.*)/, '$1'
    fs.stat filename, (e, stats) ->
      return c null, [filename, 'skipped'] unless e
      mkdirp.sync path.dirname filename
      request.get url
        .on 'error', console.error
      .pipe fs.createWriteStream(filename).on 'close', () ->
        c null, url

  async.map files, download, console.log
