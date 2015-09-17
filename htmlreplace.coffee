#!/usr/bin/env coffee
fs = require 'fs'
R = require 'ramda'
prompt = require 'prompt'
async = require 'async'
jsdom = require 'jsdom'
minimist = require 'minimist'
wrench = require 'wrench'

opt = minimist process.argv.slice 2
file = opt._[0]
o = (d) -> (k, v) ->
  a = {}
  a[k] = v
  if d and d[k]
    a[k] = d[k]
  a

e = (f) -> (e, r) ->
  if e
    console.log e
    throw e
  f r

prompt.override = opt

options = do ->
  try file = JSON.parse(fs.readFileSync file) catch e
  o = o file
  R.mergeAll [
    o 'dir', '.'
    o 'replacement', '<!--# include virtual="/wp/content" wait="yes" -->'
    o 'selector', '.seo_text'
    o 'filter', '\.html?'
    o 'method', 'html'
  ]

prompt.start()

opt = prompt.get options, e (opt) ->
  replace = (c) -> e (w) ->
    w.$(opt.selector).each -> w.$(this)[opt.method] opt.replacement
    c w.document.documentElement.outerHTML
    w.close()

  processFile = (file, c) ->
    return c if fs.statSync(file).isDirectory()
    console.log file
    jquery = fs.readFileSync __dirname+"/jquery.js", "utf-8"
    jsdom.env
      file: file
      src: [jquery]
      done: replace R.curry(fs.writeFile) file, R._, c

  files = wrench.readdirSyncRecursive opt.dir

  prependDir = R.map (e) -> opt.dir + '/' + e
  filter = R.filter (a) -> (new RegExp opt.filter).test a
  async.each (prependDir filter files), processFile, (e)->
    fs.writeFileSync file, JSON.stringify opt
