fx_version 'cerulean'
game 'gta5'

description 'ESX Vehicle Rental Script'
author 'Amadeusz'

shared_script 'config.lua'

client_script 'client.lua'
server_script 'server.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'ox_target',
    'es_extended'
}
