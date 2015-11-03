#!/usr/bin/env coffee
wrench = require 'wrench'
fs = require 'fs'
R = require 'ramda'
prompt = require 'prompt'
argv = process.argv.slice 2
prompt.override = from: argv[0], to: argv[1]

options = properties: from: {}, to: {}

opt = prompt.get options, (e, opt) ->
  [fileFilter, from] = (new RegExp r, 'gi' for r in [opt.fileFilter, opt.from])

  process = (dir) ->
    for file in wrench.readdirSyncRecursive dir
      file = dir+'/'+file
      return process file if fs.statSync(file).isDirectory()
      content = fs.readFileSync file, encoding:'utf-8'
      content = content.replace from, opt.to
      fs.writeFileSync file, content

  process '.'
