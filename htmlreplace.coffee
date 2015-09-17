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
o = do ->
  (k, v) ->
    a = {}
    a.k = v
    if file and file[k]
      a.k = file[k]
    a

prompt.override = opt

options = do ->
  try file = JSON.parse(fs.readFileSync file) catch e
  r = properties:[]
  o 'dir', '.'
  replacement: default: '<!--# include virtual="/wp/content" wait="yes" -->'
  selector: default: '.seo_text'
  filter: default: '\.html?'
  method: default: 'html'

prompt.start()

e = (f) -> (e, r) ->
  if e
    console.log e
    throw e
  f r

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
