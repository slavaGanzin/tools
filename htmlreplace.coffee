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
  a[k] = {}
  a[k].default = v
  if d and d[k]
    a[k].default = d[k]
  a

prompt.override = opt

options = do ->
  try _default = JSON.parse(fs.readFileSync file.toString()) catch e
  o = o _default

  properties: R.mergeAll [
    o 'dir', '.'
    o 'replacement', '<!--# include virtual="/wp/content" wait="yes" -->'
    o 'selector', '.seo_text'
    o 'filter', '\.html?'
    o 'method', 'html'
  ]

opt = prompt.get options, (e, opt) ->
  replace = (c) -> (e, w) ->
    w.$(opt.selector).each -> w.$(this)[opt.method] opt.replacement
    c w.document.documentElement.outerHTML
    w.close()

  processFile = (file, c) ->
    return c if fs.statSync(file).isDirectory()
    jquery = fs.readFileSync __dirname+"/jquery.js", "utf-8"
    jsdom.env
      file: file
      src: [jquery]
      done: replace (data) -> fs.writeFile file, data, c

  files = wrench.readdirSyncRecursive opt.dir

  prependDir = R.map (e) -> opt.dir + '/' + e
  filter = R.filter (a) -> (new RegExp opt.filter).test a
  async.each (prependDir filter files), processFile, (e)->
    fs.writeFileSync file.toString(), JSON.stringify opt, null, 2
