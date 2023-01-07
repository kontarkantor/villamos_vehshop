fx_version 'adamant'
game 'gta5'

description 'esx vehicleshop by 6osvillamos#9280'
version '1.0.0'

ui_page('html/index.html') 

files({
  'html/index.html',
  'html/index.js',
  'html/style.css'
})

shared_script '@es_extended/imports.lua'

client_scripts {
  'config.lua',
  'client.lua'
}

server_scripts {
  '@mysql-async/lib/MySQL.lua',
  'config.lua',
  'server.lua'
}

dependencies {
  'es_extended'
}

export 'GeneratePlate'
