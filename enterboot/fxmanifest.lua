fx_version 'cerulean'
game 'gta5'

author 'Chip'
description 'Enter Boot/Search Boot Script'
version '1.8.2'

lua54 'yes'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}
